from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..services.assistant_service import AssistantService
from ..services.appointment_service import AppointmentService
from ..services.patient_service import PatientService
from ..services.prescription_service import PrescriptionService
from ..utils.decorators import (
    active_user_required,
    clinic_approved_required,
    role_required,
    assistant_context_required,
    assistant_permission_required,
)
from ..utils.response_utils import success_response, error_response


assistant_bp = Blueprint("assistants", __name__)
assistant_workflow_bp = Blueprint("assistant_workflow", __name__)


def _resolve_clinic_id():
    claims = get_jwt()
    role = claims.get("role")

    if role == "super_admin":
        clinic_id = request.args.get("clinic_id", type=int)
        if not clinic_id:
            return None, error_response("clinic_id query param is required for super_admin.", status_code=400)
        return clinic_id, None

    clinic_id = claims.get("clinic_id")
    if not clinic_id:
        return None, error_response("Clinic context is missing.", status_code=400)
    return int(clinic_id), None


# ── Assistant management (doctor / clinic_admin) ─────────────────────────────


@assistant_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor")
def create_assistant():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")
    doctor_id = claims.get("doctor_id")

    data = request.get_json(silent=True) or {}

    try:
        result = AssistantService.create(
            clinic_id,
            creator_role=role,
            creator_doctor_id=int(doctor_id) if doctor_id else None,
            data=data,
        )
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Assistant created successfully.", data=result, status_code=201)


@assistant_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor")
def list_assistants():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")

    doctor_id = None
    if role == "doctor":
        doctor_id = claims.get("doctor_id")
        if not doctor_id:
            return error_response("Doctor context is missing.", status_code=400)
        doctor_id = int(doctor_id)

    assistants = AssistantService.list(clinic_id, doctor_id=doctor_id)
    return success_response("Assistants retrieved.", data={"assistants": [a.to_dict() for a in assistants]})


@assistant_bp.route("/my-assistants", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def my_assistants():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    claims = get_jwt()
    doctor_id = claims.get("doctor_id")
    if not doctor_id:
        return error_response("Doctor context is missing.", status_code=400)

    assistants = AssistantService.list(clinic_id, doctor_id=int(doctor_id))
    return success_response("Assistants retrieved.", data={"assistants": [a.to_dict() for a in assistants]})


@assistant_bp.route("/<int:assistant_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor")
def get_assistant(assistant_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")
    actor_doctor_id = claims.get("doctor_id")

    assistant = AssistantService.get(clinic_id, assistant_id)
    if not assistant:
        return error_response("Assistant not found.", status_code=404)

    if role == "doctor":
        if not actor_doctor_id or int(actor_doctor_id) != int(assistant.doctor_id):
            return error_response("Access denied.", status_code=403)

    return success_response("Assistant retrieved.", data={"assistant": assistant.to_dict()})


@assistant_bp.route("/<int:assistant_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor")
def update_assistant(assistant_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")
    actor_doctor_id = claims.get("doctor_id")

    data = request.get_json(silent=True) or {}
    try:
        assistant = AssistantService.update(
            clinic_id,
            actor_role=role,
            actor_doctor_id=int(actor_doctor_id) if actor_doctor_id else None,
            assistant_id=assistant_id,
            data=data,
        )
    except ValueError as exc:
        msg = str(exc)
        status = 404 if msg == "Assistant not found." else 422 if msg != "Access denied." else 403
        return error_response(msg, status_code=status)

    return success_response("Assistant updated successfully.", data={"assistant": assistant.to_dict()})


@assistant_bp.route("/<int:assistant_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor")
def delete_assistant(assistant_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")
    actor_doctor_id = claims.get("doctor_id")

    try:
        assistant = AssistantService.soft_delete(
            clinic_id,
            actor_role=role,
            actor_doctor_id=int(actor_doctor_id) if actor_doctor_id else None,
            assistant_id=assistant_id,
        )
    except ValueError as exc:
        msg = str(exc)
        status = 404 if msg == "Assistant not found." else 403 if msg == "Access denied." else 422
        return error_response(msg, status_code=status)

    return success_response("Assistant deleted successfully (soft delete).", data={"assistant": assistant.to_dict()})


# ── Assistant workflow (assistant role) ──────────────────────────────────────


@assistant_workflow_bp.route("/dashboard", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_view_appointments")
def assistant_dashboard():
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    data = AssistantService.dashboard(clinic_id, doctor_id)

    # Include token_code in queue
    data["today_queue"] = [AppointmentService.to_dict(a) for a in AssistantService.queue(clinic_id, doctor_id)]

    return success_response("Assistant dashboard retrieved.", data=data)


@assistant_workflow_bp.route("/queue", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_view_appointments")
def assistant_queue():
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    queue = AssistantService.queue(clinic_id, doctor_id)
    return success_response("Assistant queue retrieved.", data={"appointments": [AppointmentService.to_dict(a) for a in queue]})


@assistant_workflow_bp.route("/vitals", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_add_vitals")
def add_vitals():
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    from flask import g

    assistant = g.current_assistant

    data = request.get_json(silent=True) or {}
    try:
        vitals = AssistantService.add_vitals(
            clinic_id,
            doctor_id=doctor_id,
            assistant_id=assistant.id,
            data=data,
        )
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Vitals saved.", data={"vitals": vitals.to_dict()}, status_code=201)


@assistant_workflow_bp.route("/vitals/<int:patient_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_view_patient_history")
def list_patient_vitals(patient_id):
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    if not PatientService.doctor_can_access_patient(clinic_id, doctor_id, patient_id):
        return error_response("Access denied.", status_code=403)

    vitals = AssistantService.list_vitals(clinic_id, doctor_id=doctor_id, patient_id=patient_id)
    return success_response("Vitals retrieved.", data={"vitals": [v.to_dict() for v in vitals]})


@assistant_workflow_bp.route("/reports", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_upload_reports")
def upload_report_metadata():
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    data = request.get_json(silent=True) or {}
    try:
        report = AssistantService.create_report(
            clinic_id,
            doctor_id=doctor_id,
            uploaded_by_user_id=get_jwt_identity(),
            data=data,
        )
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Report metadata saved.", data={"report": report.to_dict()}, status_code=201)


@assistant_workflow_bp.route("/symptoms-draft", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_prepare_prescription_draft")
def save_symptoms_draft():
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    from flask import g

    assistant = g.current_assistant

    data = request.get_json(silent=True) or {}
    appointment_id = data.get("appointment_id")
    patient_id = data.get("patient_id")
    if not appointment_id or not patient_id:
        return error_response("appointment_id and patient_id are required.", status_code=422)

    try:
        draft = AssistantService.upsert_symptoms_draft(
            clinic_id,
            appointment_id=int(appointment_id),
            doctor_id=doctor_id,
            patient_id=int(patient_id),
            assistant_id=assistant.id,
            symptoms_draft=data.get("symptoms_draft"),
            vitals_summary=data.get("vitals_summary"),
            notes=data.get("notes"),
        )
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Consultation draft saved.", data={"draft": draft.to_dict()}, status_code=201)


@assistant_workflow_bp.route("/appointments/<int:appointment_id>/call-next", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_view_appointments")
def call_next_patient(appointment_id):
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    try:
        appt = AssistantService.call_next(clinic_id, doctor_id=doctor_id, appointment_id=appointment_id)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Appointment not found." else 422)

    return success_response("Next patient called.", data={"appointment": AppointmentService.to_dict(appt)})


@assistant_workflow_bp.route("/patients/<int:patient_id>/history", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_view_patient_history")
def assistant_patient_history(patient_id):
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    if not PatientService.doctor_can_access_patient(clinic_id, doctor_id, patient_id):
        return error_response("Access denied.", status_code=403)

    try:
        history = PatientService.history(clinic_id, patient_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Patient history retrieved.", data=history)


@assistant_workflow_bp.route("/prescriptions/<int:prescription_id>/print-data", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@assistant_context_required
@assistant_permission_required("can_print_prescription")
def assistant_print_prescription_data(prescription_id):
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id"))
    doctor_id = int(claims.get("doctor_id"))

    try:
        data = PrescriptionService.print_data(clinic_id, prescription_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    if int((data.get("doctor") or {}).get("id") or 0) != int(doctor_id):
        return error_response("Access denied.", status_code=403)

    return success_response("Prescription print data retrieved.", data=data)
