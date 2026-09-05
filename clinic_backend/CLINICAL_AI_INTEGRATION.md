# Clinical AI Integration

This system now includes a first-class Clinical AI layer for doctor workflows. It is built into the consultation screen and backend API instead of being a separate add-on page.

## What Is Integrated

The current production-ready integration is focused on medical text understanding and clinical documentation support:

- Patient history summaries for doctors.
- Consultation draft generation from current symptoms, notes, vitals, appointment context, and recent history.
- Medical entity extraction for conditions, medicines, dosages, symptoms, procedures, body parts, and lab tests.
- Patient-friendly explanation drafts.
- Red-flag prompts and suggested follow-up questions for clinician review.

The implementation uses the OpenAI Responses API when `OPENAI_API_KEY` is configured. If no key is present, the system automatically uses a local rule-based fallback so the feature remains functional in development and demonstrations.

## Why This API Was Chosen First

For this clinic system, the highest-value AI workflows are doctor note drafting, patient summaries, report explanation, and entity extraction inside an existing consultation flow. OpenAI is the best first integration here because one provider can support summarization, structured medical text extraction, patient-friendly explanations, and referral or note drafting without adding separate infrastructure for every workflow.

Provider-specific medical APIs can still be added later:

- Amazon Comprehend Medical or Azure Text Analytics for Health: deeper clinical entity extraction in notes and reports.
- Infermedica: dedicated symptom checker and triage before appointment booking.
- AWS HealthScribe, Dragon Copilot, Abridge: doctor-patient audio to clinical note workflows.
- Google Cloud Healthcare API: FHIR, HL7v2, and DICOM record storage and interoperability.
- Aidoc, Gleamer, NVIDIA Clara, MONAI, Roboflow: imaging workflows that require validation and separate clinical governance.

## Safety Boundary

AI output is never saved automatically as a final medical record. The doctor must review and apply the draft manually, then save the prescription or consultation record through the existing workflow.

Every API response includes:

```json
{
  "safety_notice": "AI output is a draft clinical support note. A licensed clinician must review, verify, and edit it before it is used for diagnosis, treatment, prescription, triage, referral, or patient communication."
}
```

This is intentional. The system treats AI as clinical documentation support, not an autonomous diagnosis, treatment, triage, or prescribing engine.

## Configuration

Add these values to `clinic_backend/.env`:

```env
CLINICAL_AI_PROVIDER=openai
CLINICAL_AI_MODEL=gpt-5.2
CLINICAL_AI_TIMEOUT_SECONDS=45
OPENAI_API_KEY=your-openai-api-key
```

If `OPENAI_API_KEY` is empty, the backend uses `local_fallback`. This fallback extracts simple entities and drafts conservative summaries from existing structured data.

## Backend Endpoints

All endpoints are prefixed with `/api/clinical-ai` and require a logged-in doctor.

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/status` | Show configured provider, model, feature list, and safety notice. |
| POST | `/patient-summary` | Generate a doctor-facing patient history summary. |
| POST | `/consultation-assist` | Generate an editable consultation draft from the active appointment. |
| POST | `/extract-medical-text` | Extract structured medical entities from pasted clinical text. |

### Patient Summary

```bash
curl -X POST "$BASE_URL/api/clinical-ai/patient-summary" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "patient_id": 42 }'
```

### Consultation Assist

```bash
curl -X POST "$BASE_URL/api/clinical-ai/consultation-assist" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": 1001,
    "patient_id": 42,
    "symptoms": "Fever and cough for three days",
    "diagnosis": "",
    "notes": "No known allergies",
    "vitals_summary": "BP 120/80, pulse 92, temp 38.1, O2 98"
  }'
```

### Response Shape

```json
{
  "success": true,
  "message": "Consultation AI draft generated.",
  "data": {
    "summary": "Short clinical summary",
    "symptoms_draft": "Editable symptoms text",
    "diagnosis_draft": "Editable diagnosis text",
    "notes_draft": "Editable note text",
    "patient_friendly_explanation": "Simple explanation for the patient",
    "red_flags": [],
    "suggested_questions": [],
    "extracted_entities": {
      "conditions": [],
      "medicines": [],
      "dosages": [],
      "symptoms": [],
      "procedures": [],
      "body_parts": [],
      "lab_tests": []
    },
    "follow_up_guidance": "Draft follow-up guidance",
    "provider": "openai",
    "safety_notice": "..."
  }
}
```

## Frontend Workflow

In the doctor consultation screen:

1. The doctor opens a patient appointment.
2. The `Clinical AI` panel appears beside vitals and previous prescriptions.
3. `Summarize` generates a concise patient-history summary.
4. `Draft` generates editable symptoms, diagnosis, notes, entity extraction, red flags, and questions.
5. `Apply Draft` copies AI draft text into the consultation form.
6. The doctor reviews and edits before saving the prescription.

## Privacy And Compliance Notes

- Do not send protected health information to a third-party AI provider unless your clinic has the required legal, privacy, and security agreements in place.
- For HIPAA-regulated workflows, OpenAI says API customers that need to process PHI must first have a BAA with OpenAI.
- Keep API keys only in server-side environment variables. Never place provider keys in Flutter or browser code.
- Log clinical AI requests carefully. Avoid storing raw PHI prompts in application logs.
- Validate outputs with local clinical governance before production use.

## Sources

- OpenAI Responses API documentation: https://platform.openai.com/docs/api-reference/responses/object
- OpenAI text generation guide, which recommends the Responses API for new projects: https://platform.openai.com/docs/guides/text
- OpenAI Structured Outputs guide: https://platform.openai.com/docs/guides/structured-outputs
- OpenAI BAA help article for API services: https://help.openai.com/en/articles/8660679
# Educational scikit-learn disease risk demos

The doctor portal includes four educational risk-screening demonstrations:

- Diabetes: `LogisticRegression`
- Heart disease: `RandomForestClassifier`
- Stroke: `DecisionTreeClassifier`
- Breast cancer: `RandomForestClassifier`

The models are trained from deterministic demonstration data when first used and expose
their held-out demo accuracy, required feature ranges, risk probability, and risk tier.
They are not validated diagnostic models and must not be used to diagnose, exclude disease,
prescribe treatment, or replace clinical judgment and medical testing.

Endpoints:

- `GET /api/clinical-ai/risk-models`
- `POST /api/clinical-ai/risk-predict/<model_key>`
