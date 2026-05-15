from __future__ import annotations

from datetime import date

from ..extensions import db
from ..models.assistant import Assistant
from ..models.doctor import Doctor
from ..models.user import User
from ..models.patient import Patient
from ..models.appointment import Appointment
from ..models.patient_vitals import PatientVitals
from ..models.patient_report import PatientReport
from ..models.consultation_draft import ConsultationDraft
from ..services.user_service import UserService
from ..utils.validators import validate_email, parse_float, parse_int


class AssistantService:

    @staticmethod
    def get_active_assistant_for_user(*, clinic_id: int, user_id: int, doctor_id: int | None) -> Assistant | None:
        if not clinic_id or not user_id or not doctor_id:
            return None
        return Assistant.query.filter_by(
            clinic_id=int(clinic_id),
            user_id=int(user_id),
            doctor_id=int(doctor_id),
            status="active",
        ).first()

    @staticmethod
    def create(clinic_id: int, *, creator_role: str, creator_doctor_id: int | None, data: dict) -> dict:
        name = (data.get("name") or "").strip()
        email = (data.get("email") or "").lower().strip()
        phone = (data.get("phone") or "").strip()

        if not name:
            raise ValueError("Assistant name is required.")
        if not email:
            raise ValueError("Assistant email is required.")
        if not validate_email(email):
            raise ValueError("Invalid email address.")

        # Determine assigned doctor
        doctor_id = data.get("doctor_id")
        if creator_role == "doctor":
            if not creator_doctor_id:
                raise ValueError("Doctor context is missing.")
            assigned_doctor_id = int(creator_doctor_id)
        else:
            if not doctor_id:
                raise ValueError("doctor_id is required when created by clinic_admin.")
            assigned_doctor_id = int(doctor_id)

        doctor = Doctor.query.filter_by(clinic_id=clinic_id, id=assigned_doctor_id).first()
        if not doctor:
            raise ValueError("Doctor not found in this clinic.")

        # Create user account
        user, temp_pwd = UserService.create_user(
            name=name,
            email=email,
            phone=phone,
            role="assistant",
            clinic_id=clinic_id,
            doctor_id=assigned_doctor_id,
            must_change_password=True,
            status="active",
        )

        assistant = Assistant(
            clinic_id=clinic_id,
            doctor_id=assigned_doctor_id,
            user_id=user.id,
            name=name,
            duties=data.get("duties"),
            can_view_appointments=bool(data.get("can_view_appointments", True)),
            can_add_vitals=bool(data.get("can_add_vitals", True)),
            can_upload_reports=bool(data.get("can_upload_reports", False)),
            can_prepare_prescription_draft=bool(data.get("can_prepare_prescription_draft", False)),
            can_print_prescription=bool(data.get("can_print_prescription", False)),
            can_view_patient_history=bool(data.get("can_view_patient_history", True)),
            status="active",
        )
        db.session.add(assistant)
        db.session.commit()

        return {
            "assistant": assistant.to_dict(),
            "account": {
                "user": user.to_dict(),
                "temp_password": temp_pwd,
                "note": "Temporary password is shown only once.",
            },
        }

    @staticmethod
    def list(clinic_id: int, *, doctor_id: int | None = None):
        q = Assistant.query.filter_by(clinic_id=clinic_id)
        if doctor_id:
            q = q.filter(Assistant.doctor_id == int(doctor_id))
        return q.order_by(Assistant.created_at.desc()).all()

    @staticmethod
    def get(clinic_id: int, assistant_id: int) -> Assistant | None:
        return Assistant.query.filter_by(clinic_id=clinic_id, id=assistant_id).first()

    @staticmethod
    def update(clinic_id: int, *, actor_role: str, actor_doctor_id: int | None, assistant_id: int, data: dict) -> Assistant:
        assistant = AssistantService.get(clinic_id, assistant_id)
        if not assistant:
            raise ValueError("Assistant not found.")

        if actor_role == "doctor":
            if not actor_doctor_id or int(actor_doctor_id) != int(assistant.doctor_id):
                raise ValueError("Access denied.")

        if "name" in data:
            assistant.name = (data.get("name") or "").strip() or assistant.name

        if "duties" in data:
            assistant.duties = data.get("duties")

        for flag in [
            "can_view_appointments",
            "can_add_vitals",
            "can_upload_reports",
            "can_prepare_prescription_draft",
            "can_print_prescription",
            "can_view_patient_history",
        ]:
            if flag in data:
                setattr(assistant, flag, bool(data.get(flag)))

        if "status" in data:
            status = data.get("status")
            if status not in ("active", "inactive"):
                raise ValueError("Invalid assistant status.")
            assistant.status = status
            if assistant.user_id:
                user = User.query.get(assistant.user_id)
                if user:
                    user.status = "active" if status == "active" else "inactive"

        # clinic_admin may move assistant to different doctor
        if actor_role in ("clinic_admin", "super_admin") and "doctor_id" in data:
            new_doctor_id = int(data.get("doctor_id")) if data.get("doctor_id") else None
            if not new_doctor_id:
                raise ValueError("doctor_id cannot be blank.")
            doctor = Doctor.query.filter_by(clinic_id=clinic_id, id=new_doctor_id).first()
            if not doctor:
                raise ValueError("Doctor not found in this clinic.")
            assistant.doctor_id = new_doctor_id
            if assistant.user_id:
                user = User.query.get(assistant.user_id)
                if user:
                    user.doctor_id = new_doctor_id

        db.session.commit()
        return assistant

    @staticmethod
    def soft_delete(clinic_id: int, *, actor_role: str, actor_doctor_id: int | None, assistant_id: int) -> Assistant:
        assistant = AssistantService.get(clinic_id, assistant_id)
        if not assistant:
            raise ValueError("Assistant not found.")

        if actor_role == "doctor":
            if not actor_doctor_id or int(actor_doctor_id) != int(assistant.doctor_id):
                raise ValueError("Access denied.")

        assistant.status = "inactive"
        if assistant.user_id:
            user = User.query.get(assistant.user_id)
            if user:
                user.status = "inactive"

        db.session.commit()
        return assistant

    # ── Assistant workflow ─────────────────────────────────────────────────

    @staticmethod
    def dashboard(clinic_id: int, doctor_id: int):
        today = date.today()
        q = Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id).filter(
            Appointment.appointment_date == today
        )

        total_today = q.count()
        waiting = q.filter(Appointment.status.in_(["waiting", "sent_to_assistant"])).count()
        in_consultation = q.filter(Appointment.status == "in_consultation").count()
        completed = q.filter(Appointment.status == "completed").count()

        queue = q.order_by(Appointment.token_number.asc()).all()

        return {
            "date": today.isoformat(),
            "today_total_appointments": total_today,
            "waiting_patients": waiting,
            "in_consultation": in_consultation,
            "completed_today": completed,
            "today_queue": [a.to_dict() for a in queue],
        }

    @staticmethod
    def queue(clinic_id: int, doctor_id: int):
        return (
            Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id)
            .filter(Appointment.appointment_date == date.today())
            .order_by(Appointment.token_number.asc())
            .all()
        )

    @staticmethod
    def add_vitals(
        clinic_id: int,
        *,
        doctor_id: int,
        assistant_id: int | None,
        data: dict,
    ) -> PatientVitals:
        patient_id = data.get("patient_id")
        appointment_id = data.get("appointment_id")
        if not patient_id:
            raise ValueError("patient_id is required.")

        appt = None
        if appointment_id not in (None, ""):
            appt = Appointment.query.filter_by(clinic_id=clinic_id, id=int(appointment_id)).first()
            if not appt:
                raise ValueError("Appointment not found in this clinic.")
            if int(appt.doctor_id) != int(doctor_id):
                raise ValueError("Access denied. Appointment does not belong to this doctor.")
            if int(appt.patient_id) != int(patient_id):
                raise ValueError("patient_id does not match appointment patient.")

        patient = Patient.query.filter_by(clinic_id=clinic_id, id=int(patient_id)).first()
        if not patient:
            raise ValueError("Patient not found in this clinic.")

        vitals = PatientVitals(
            clinic_id=clinic_id,
            patient_id=patient.id,
            appointment_id=appt.id if appt else None,
            doctor_id=doctor_id,
            assistant_id=assistant_id,
            temperature=parse_float(data.get("temperature"), "temperature"),
            blood_pressure=(data.get("blood_pressure") or "").strip() or None,
            pulse=parse_int(data.get("pulse"), "pulse", minimum=0),
            weight=parse_float(data.get("weight"), "weight", minimum=0),
            height=parse_float(data.get("height"), "height", minimum=0),
            oxygen_level=parse_int(data.get("oxygen_level"), "oxygen_level", minimum=0),
            notes=(data.get("notes") or "").strip() or None,
        )
        db.session.add(vitals)
        db.session.commit()
        return vitals

    @staticmethod
    def list_vitals(clinic_id: int, *, doctor_id: int, patient_id: int):
        return (
            PatientVitals.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, patient_id=patient_id)
            .order_by(PatientVitals.created_at.desc())
            .limit(200)
            .all()
        )

    @staticmethod
    def create_report(
        clinic_id: int,
        *,
        doctor_id: int,
        uploaded_by_user_id: int,
        data: dict,
    ) -> PatientReport:
        patient_id = data.get("patient_id")
        if not patient_id:
            raise ValueError("patient_id is required.")

        patient = Patient.query.filter_by(clinic_id=clinic_id, id=int(patient_id)).first()
        if not patient:
            raise ValueError("Patient not found in this clinic.")

        appointment_id = data.get("appointment_id")
        appt = None
        if appointment_id not in (None, ""):
            appt = Appointment.query.filter_by(clinic_id=clinic_id, id=int(appointment_id)).first()
            if not appt:
                raise ValueError("Appointment not found in this clinic.")
            if int(appt.doctor_id) != int(doctor_id):
                raise ValueError("Access denied. Appointment does not belong to this doctor.")

        title = (data.get("report_title") or "").strip()
        if not title:
            raise ValueError("report_title is required.")

        report = PatientReport(
            clinic_id=clinic_id,
            patient_id=patient.id,
            appointment_id=appt.id if appt else None,
            doctor_id=doctor_id,
            uploaded_by=uploaded_by_user_id,
            report_title=title,
            report_type=(data.get("report_type") or "").strip() or None,
            file_url=(data.get("file_url") or "").strip() or None,
            notes=(data.get("notes") or "").strip() or None,
        )
        db.session.add(report)
        db.session.commit()
        return report

    @staticmethod
    def upsert_symptoms_draft(
        clinic_id: int,
        *,
        appointment_id: int,
        doctor_id: int,
        patient_id: int,
        assistant_id: int | None,
        symptoms_draft: str | None,
        vitals_summary: str | None,
        notes: str | None,
    ) -> ConsultationDraft:
        appt = Appointment.query.filter_by(clinic_id=clinic_id, id=int(appointment_id)).first()
        if not appt:
            raise ValueError("Appointment not found in this clinic.")
        if int(appt.doctor_id) != int(doctor_id):
            raise ValueError("Access denied.")
        if int(appt.patient_id) != int(patient_id):
            raise ValueError("patient_id does not match appointment patient.")

        draft = ConsultationDraft.query.filter_by(clinic_id=clinic_id, appointment_id=appt.id).first()
        if not draft:
            draft = ConsultationDraft(
                clinic_id=clinic_id,
                appointment_id=appt.id,
                patient_id=appt.patient_id,
                doctor_id=appt.doctor_id,
                assistant_id=assistant_id,
            )
            db.session.add(draft)

        if symptoms_draft is not None:
            draft.symptoms_draft = symptoms_draft.strip() or None
        if vitals_summary is not None:
            draft.vitals_summary = vitals_summary.strip() or None
        if notes is not None:
            draft.notes = notes.strip() or None

        draft.assistant_id = assistant_id

        db.session.commit()
        return draft

    @staticmethod
    def call_next(clinic_id: int, *, doctor_id: int, appointment_id: int) -> Appointment:
        appt = Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, id=appointment_id).first()
        if not appt:
            raise ValueError("Appointment not found.")

        if appt.appointment_date != date.today():
            raise ValueError("Only today's appointments can be called.")

        if appt.status != "waiting":
            raise ValueError("Only waiting appointments can be called.")

        appt.status = "sent_to_assistant"
        db.session.commit()
        return appt
