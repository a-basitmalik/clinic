from flask import Blueprint, request
from flask_jwt_extended import get_jwt, jwt_required

from ..services.clinical_ai_service import ClinicalAIService
from ..services.disease_risk_service import DiseaseRiskService
from ..utils.decorators import active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import error_response, success_response


clinical_ai_bp = Blueprint("clinical_ai", __name__)


def _resolve_doctor_context():
    claims = get_jwt()
    clinic_id = claims.get("clinic_id")
    doctor_id = claims.get("doctor_id")
    if not clinic_id or not doctor_id:
        return None, None, error_response("Doctor context is missing.", status_code=400)
    return int(clinic_id), int(doctor_id), None


@clinical_ai_bp.route("/status", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def clinical_ai_status():
    return success_response("Clinical AI status retrieved.", data=ClinicalAIService.status())


@clinical_ai_bp.route("/patient-summary", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def patient_summary():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    patient_id = data.get("patient_id")
    if not patient_id:
        return error_response("patient_id is required.", status_code=422)

    try:
        result = ClinicalAIService.patient_summary(clinic_id, doctor_id, int(patient_id))
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Patient summary generated.", data=result)


@clinical_ai_bp.route("/consultation-assist", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def consultation_assist():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    appointment_id = data.get("appointment_id")
    patient_id = data.get("patient_id")
    if not appointment_id or not patient_id:
        return error_response("appointment_id and patient_id are required.", status_code=422)

    try:
        result = ClinicalAIService.consultation_assist(
            clinic_id,
            doctor_id,
            appointment_id=int(appointment_id),
            patient_id=int(patient_id),
            data=data,
        )
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Appointment not found." else 422)

    return success_response("Consultation AI draft generated.", data=result)


@clinical_ai_bp.route("/extract-medical-text", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def extract_medical_text():
    data = request.get_json(silent=True) or {}
    try:
        result = ClinicalAIService.extract_medical_text(data.get("text") or "")
    except ValueError as exc:
        return error_response(str(exc), status_code=422)
    return success_response("Medical text extracted.", data=result)


@clinical_ai_bp.route("/risk-models", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def risk_models():
    return success_response(
        "Disease risk demo models retrieved.",
        data={"models": DiseaseRiskService.list_models()},
    )


@clinical_ai_bp.route("/risk-predict/<string:model_key>", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def risk_predict(model_key):
    try:
        result = DiseaseRiskService.predict(model_key, request.get_json(silent=True) or {})
    except ValueError as exc:
        return error_response(str(exc), status_code=422)
    return success_response("Educational disease risk estimate generated.", data=result)
