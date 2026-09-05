from __future__ import annotations

import json
import re
from typing import Any
from urllib import error, request

from flask import current_app

from ..models.appointment import Appointment
from ..models.consultation_draft import ConsultationDraft
from ..models.patient import Patient
from ..models.patient_report import PatientReport
from ..models.patient_vitals import PatientVitals
from ..models.prescription import Prescription
from ..services.doctor_service import DoctorService


SAFETY_NOTICE = (
    "AI output is a draft clinical support note. A licensed clinician must review, "
    "verify, and edit it before it is used for diagnosis, treatment, prescription, "
    "triage, referral, or patient communication."
)


CLINICAL_AI_SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "properties": {
        "summary": {"type": "string"},
        "symptoms_draft": {"type": "string"},
        "diagnosis_draft": {"type": "string"},
        "notes_draft": {"type": "string"},
        "patient_friendly_explanation": {"type": "string"},
        "red_flags": {"type": "array", "items": {"type": "string"}},
        "suggested_questions": {"type": "array", "items": {"type": "string"}},
        "extracted_entities": {
            "type": "object",
            "additionalProperties": False,
            "properties": {
                "conditions": {"type": "array", "items": {"type": "string"}},
                "medicines": {"type": "array", "items": {"type": "string"}},
                "dosages": {"type": "array", "items": {"type": "string"}},
                "symptoms": {"type": "array", "items": {"type": "string"}},
                "procedures": {"type": "array", "items": {"type": "string"}},
                "body_parts": {"type": "array", "items": {"type": "string"}},
                "lab_tests": {"type": "array", "items": {"type": "string"}},
            },
            "required": [
                "conditions",
                "medicines",
                "dosages",
                "symptoms",
                "procedures",
                "body_parts",
                "lab_tests",
            ],
        },
        "follow_up_guidance": {"type": "string"},
    },
    "required": [
        "summary",
        "symptoms_draft",
        "diagnosis_draft",
        "notes_draft",
        "patient_friendly_explanation",
        "red_flags",
        "suggested_questions",
        "extracted_entities",
        "follow_up_guidance",
    ],
}


class ClinicalAIService:
    @staticmethod
    def status() -> dict[str, Any]:
        provider = current_app.config.get("CLINICAL_AI_PROVIDER", "openai")
        has_key = bool(current_app.config.get("OPENAI_API_KEY"))
        return {
            "enabled": provider == "local" or has_key,
            "provider": provider if has_key or provider == "local" else "local_fallback",
            "model": current_app.config.get("CLINICAL_AI_MODEL"),
            "features": [
                "patient_history_summary",
                "consultation_draft",
                "medical_entity_extraction",
                "patient_friendly_explanation",
                "educational_disease_risk_prediction",
            ],
            "safety_notice": SAFETY_NOTICE,
        }

    @staticmethod
    def patient_summary(clinic_id: int, doctor_id: int, patient_id: int) -> dict[str, Any]:
        profile = DoctorService.patient_profile(clinic_id, doctor_id, patient_id)
        prompt = (
            "Create a concise clinician-facing patient history summary from the supplied clinic data. "
            "Highlight recurring diagnoses, current/recent medicines, abnormal vitals, reports, follow-ups, "
            "and questions the doctor should consider. Do not invent facts."
        )
        return ClinicalAIService._complete(prompt, ClinicalAIService._profile_context(profile))

    @staticmethod
    def consultation_assist(
        clinic_id: int,
        doctor_id: int,
        *,
        appointment_id: int,
        patient_id: int,
        data: dict[str, Any],
    ) -> dict[str, Any]:
        appt = Appointment.query.filter_by(
            clinic_id=clinic_id,
            doctor_id=doctor_id,
            id=appointment_id,
            patient_id=patient_id,
        ).first()
        if not appt:
            raise ValueError("Appointment not found.")

        profile = DoctorService.patient_profile(clinic_id, doctor_id, patient_id)
        draft = ConsultationDraft.query.filter_by(clinic_id=clinic_id, appointment_id=appointment_id).first()

        working_note = {
            "current_symptoms": data.get("symptoms") or (draft.symptoms_draft if draft else None),
            "current_diagnosis": data.get("diagnosis"),
            "current_notes": data.get("notes") or (draft.notes if draft else None),
            "assistant_vitals_summary": data.get("vitals_summary") or (draft.vitals_summary if draft else None),
            "appointment_notes": appt.notes,
        }

        prompt = (
            "Assist the doctor during an active consultation. Use only the provided clinical record and "
            "working note. Draft editable symptoms, diagnosis, and notes fields; extract medical entities; "
            "flag urgent red flags as possibilities to check, not conclusions; and write a short patient-friendly "
            "explanation. If evidence is insufficient, say what is missing instead of guessing."
        )
        context = {
            "appointment": appt.to_dict(),
            "working_note": working_note,
            "patient_profile": ClinicalAIService._profile_context(profile),
        }
        return ClinicalAIService._complete(prompt, context)

    @staticmethod
    def extract_medical_text(text: str) -> dict[str, Any]:
        cleaned = (text or "").strip()
        if not cleaned:
            raise ValueError("text is required.")
        prompt = (
            "Extract medical entities and produce a short clinical summary from this text. "
            "Return only facts present in the source text. Do not diagnose."
        )
        return ClinicalAIService._complete(prompt, {"text": cleaned})

    @staticmethod
    def _complete(task: str, context: dict[str, Any]) -> dict[str, Any]:
        provider = current_app.config.get("CLINICAL_AI_PROVIDER", "openai")
        if provider == "openai" and current_app.config.get("OPENAI_API_KEY"):
            try:
                result = ClinicalAIService._openai_complete(task, context)
                result["provider"] = "openai"
                result["safety_notice"] = SAFETY_NOTICE
                return result
            except RuntimeError as exc:
                fallback = ClinicalAIService._local_complete(context)
                fallback["provider"] = "local_fallback"
                fallback["provider_error"] = str(exc)
                fallback["safety_notice"] = SAFETY_NOTICE
                return fallback

        result = ClinicalAIService._local_complete(context)
        result["provider"] = "local_fallback"
        result["safety_notice"] = SAFETY_NOTICE
        return result

    @staticmethod
    def _openai_complete(task: str, context: dict[str, Any]) -> dict[str, Any]:
        payload = {
            "model": current_app.config.get("CLINICAL_AI_MODEL", "gpt-5.2"),
            "input": [
                {
                    "role": "system",
                    "content": [
                        {
                            "type": "input_text",
                            "text": (
                                "You are a clinical documentation assistant embedded in a clinic management system. "
                                "You support licensed clinicians with drafts and summaries only. Do not present "
                                "unverified diagnoses as final, do not prescribe, and do not recommend emergency "
                                "or treatment decisions without telling the clinician to verify clinically."
                            ),
                        }
                    ],
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "input_text",
                            "text": json.dumps({"task": task, "context": context}, default=str),
                        }
                    ],
                },
            ],
            "text": {
                "format": {
                    "type": "json_schema",
                    "name": "clinical_ai_response",
                    "schema": CLINICAL_AI_SCHEMA,
                    "strict": True,
                }
            },
        }
        body = json.dumps(payload).encode("utf-8")
        req = request.Request(
            "https://api.openai.com/v1/responses",
            data=body,
            method="POST",
            headers={
                "Authorization": f"Bearer {current_app.config['OPENAI_API_KEY']}",
                "Content-Type": "application/json",
            },
        )
        timeout = current_app.config.get("CLINICAL_AI_TIMEOUT_SECONDS", 45)
        try:
            with request.urlopen(req, timeout=timeout) as res:
                raw = json.loads(res.read().decode("utf-8"))
        except error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"OpenAI request failed ({exc.code}): {detail[:300]}") from exc
        except Exception as exc:
            raise RuntimeError(f"OpenAI request failed: {exc}") from exc

        output_text = raw.get("output_text") or ClinicalAIService._extract_output_text(raw)
        if not output_text:
            raise RuntimeError("OpenAI response did not include output text.")
        try:
            return json.loads(output_text)
        except json.JSONDecodeError as exc:
            raise RuntimeError("OpenAI response was not valid JSON.") from exc

    @staticmethod
    def _extract_output_text(raw: dict[str, Any]) -> str | None:
        chunks: list[str] = []
        for item in raw.get("output") or []:
            for content in item.get("content") or []:
                if content.get("type") == "output_text" and content.get("text"):
                    chunks.append(content["text"])
        return "\n".join(chunks) if chunks else None

    @staticmethod
    def _profile_context(profile: dict[str, Any]) -> dict[str, Any]:
        patient = profile.get("patient") or {}
        vitals = (profile.get("vitals") or [])[:8]
        prescriptions = (profile.get("prescriptions") or [])[:8]
        reports = (profile.get("reports") or [])[:8]
        appointments = (profile.get("appointments") or [])[:8]
        return {
            "patient": {
                "patient_code": patient.get("patient_code"),
                "age": patient.get("age"),
                "gender": patient.get("gender"),
                "blood_group": patient.get("blood_group"),
            },
            "recent_vitals": vitals,
            "recent_prescriptions": prescriptions,
            "recent_reports": reports,
            "recent_appointments": appointments,
            "upcoming_followups": profile.get("upcoming_followups") or [],
        }

    @staticmethod
    def _local_complete(context: dict[str, Any]) -> dict[str, Any]:
        text = json.dumps(context, default=str)
        entities = ClinicalAIService._rule_based_entities(text)
        summary_bits = []

        profile = context.get("patient_profile") or context
        patient = (profile.get("patient") or {}) if isinstance(profile, dict) else {}
        if patient:
            details = [str(patient.get(k)) for k in ("age", "gender", "blood_group") if patient.get(k)]
            if details:
                summary_bits.append("Patient context: " + ", ".join(details) + ".")

        vitals = profile.get("recent_vitals") or []
        if vitals:
            latest = vitals[0]
            summary_bits.append(
                "Latest vitals: "
                + ", ".join(
                    f"{k} {v}"
                    for k, v in latest.items()
                    if k in ("temperature", "blood_pressure", "pulse", "oxygen_level", "weight") and v is not None
                )
                + "."
            )

        prescriptions = profile.get("recent_prescriptions") or []
        if prescriptions:
            diagnoses = [p.get("diagnosis") for p in prescriptions if p.get("diagnosis")]
            if diagnoses:
                summary_bits.append("Recent diagnoses: " + "; ".join(diagnoses[:3]) + ".")

        working = context.get("working_note") or {}
        symptoms = working.get("current_symptoms") or "; ".join(entities["symptoms"])
        diagnosis = working.get("current_diagnosis") or ""
        notes = working.get("current_notes") or working.get("assistant_vitals_summary") or ""

        return {
            "summary": " ".join(summary_bits) or "No previous structured clinical history was found in the available record.",
            "symptoms_draft": symptoms or "",
            "diagnosis_draft": diagnosis or "",
            "notes_draft": notes or "Review AI-extracted entities and complete the clinical assessment.",
            "patient_friendly_explanation": "Your doctor will review your symptoms, history, and any test results before confirming the assessment and plan.",
            "red_flags": ClinicalAIService._detect_red_flags(text),
            "suggested_questions": [
                "When did the symptoms start and are they worsening?",
                "Any allergies, pregnancy, chronic disease, or current medicines?",
                "Any recent hospital visit, surgery, travel, or infectious exposure?",
            ],
            "extracted_entities": entities,
            "follow_up_guidance": "Set follow-up based on clinician assessment, symptom severity, and investigation results.",
        }

    @staticmethod
    def _rule_based_entities(text: str) -> dict[str, list[str]]:
        lowered = text.lower()
        symptom_terms = [
            "fever",
            "cough",
            "pain",
            "headache",
            "vomiting",
            "nausea",
            "dizziness",
            "shortness of breath",
            "chest pain",
            "rash",
            "diarrhea",
        ]
        condition_terms = [
            "diabetes",
            "hypertension",
            "asthma",
            "infection",
            "anemia",
            "pneumonia",
            "migraine",
        ]
        procedure_terms = ["x-ray", "ct", "mri", "ultrasound", "ecg", "surgery"]
        body_terms = ["chest", "abdomen", "head", "throat", "ear", "eye", "back", "knee", "skin"]
        lab_terms = ["cbc", "hba1c", "glucose", "lipid", "creatinine", "lft", "urine", "x-ray"]

        meds = sorted(set(re.findall(r"\b(?:tab|tablet|cap|capsule|syrup|inj|injection)\.?\s+([A-Za-z][A-Za-z0-9 -]{2,40})", text)))
        dosages = sorted(set(re.findall(r"\b\d+(?:\.\d+)?\s?(?:mg|mcg|g|ml|iu|units|%)\b", lowered)))

        def present(terms: list[str]) -> list[str]:
            return sorted({term for term in terms if term in lowered})

        return {
            "conditions": present(condition_terms),
            "medicines": meds,
            "dosages": dosages,
            "symptoms": present(symptom_terms),
            "procedures": present(procedure_terms),
            "body_parts": present(body_terms),
            "lab_tests": present(lab_terms),
        }

    @staticmethod
    def _detect_red_flags(text: str) -> list[str]:
        red_flags = []
        lowered = text.lower()
        checks = {
            "Chest pain needs urgent clinical assessment if acute, severe, or associated with sweating/breathlessness.": "chest pain",
            "Shortness of breath needs urgent clinical assessment if new, severe, or worsening.": "shortness of breath",
            "Low oxygen saturation should be verified and escalated according to clinic protocol.": "oxygen_level",
            "High fever with altered mental state, dehydration, or severe pain needs urgent review.": "fever",
        }
        for message, needle in checks.items():
            if needle in lowered:
                red_flags.append(message)
        return red_flags
