from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..models.assistant import Assistant
from ..models.patient import Patient
from ..services.prescription_service import PrescriptionService
from ..services.patient_service import PatientService
from ..services.appointment_service import AppointmentService
from ..utils.decorators import active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import success_response, error_response, paginated_response


prescription_bp = Blueprint("prescriptions", __name__)


def _resolve_clinic_id_for_read():
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


def _load_active_assistant_or_error():
    claims = get_jwt()
    clinic_id = claims.get("clinic_id")
    doctor_id = claims.get("doctor_id")
    if not clinic_id or not doctor_id:
        return None, error_response("Assistant context is missing.", status_code=400)

    assistant = Assistant.query.filter_by(
        clinic_id=int(clinic_id),
        doctor_id=int(doctor_id),
        user_id=get_jwt_identity(),
        status="active",
    ).first()
    if not assistant:
        return None, error_response("Assistant record not found or inactive.", status_code=403)

    return assistant, None


def _assistant_require_any_permission(assistant: Assistant, permission_fields: list[str]):
    ok = False
    for field in permission_fields:
        if hasattr(assistant, field) and bool(getattr(assistant, field)):
            ok = True
            break
    if not ok:
        return error_response(
            "Access denied. Assistant permission required.",
            errors={"any_of": permission_fields},
            status_code=403,
        )
    return None


@prescription_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def create_prescription():
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id") or 0)
    doctor_id = claims.get("doctor_id")
    if not clinic_id or not doctor_id:
        return error_response("Doctor context is missing.", status_code=400)

    data = request.get_json(silent=True) or {}
    mark_completed = bool(data.get("mark_appointment_completed"))

    try:
        rx = PrescriptionService.create(clinic_id, int(doctor_id), data)
        if mark_completed and rx.appointment_id:
            AppointmentService.complete_appointment(
                clinic_id,
                doctor_id=int(doctor_id),
                appointment_id=int(rx.appointment_id),
                allow_no_prescription=False,
            )
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response(
        "Prescription created successfully.",
        data={"prescription": rx.to_dict(include_medicines=True, include_lab_tests=True)},
        status_code=201,
    )


@prescription_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "pharmacy", "doctor")
def list_prescriptions():
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    patient_id = request.args.get("patient_id", type=int)
    doctor_id = request.args.get("doctor_id", type=int)

    if role == "doctor":
        doctor_id = int(claims.get("doctor_id") or 0)
        if not doctor_id:
            return error_response("Doctor context is missing.", status_code=400)

    paginated = PrescriptionService.list(
        clinic_id,
        page=page,
        per_page=per_page,
        patient_id=patient_id,
        doctor_id=doctor_id,
    )

    return paginated_response(
        "Prescriptions retrieved.",
        data=[p.to_dict(include_medicines=True, include_lab_tests=True) for p in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@prescription_bp.route("/<int:prescription_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "pharmacy", "doctor", "assistant", "patient")
def get_prescription(prescription_id):
    claims = get_jwt()
    role = claims.get("role")

    if role == "patient":
        user_id = get_jwt_identity()
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Access denied.", status_code=403)
        clinic_id = patient.clinic_id
    else:
        clinic_id, err = _resolve_clinic_id_for_read()
        if err:
            return err

    rx = PrescriptionService.get(clinic_id, prescription_id)
    if not rx:
        return error_response("Prescription not found.", status_code=404)

    if role == "doctor":
        doctor_id = claims.get("doctor_id")
        if not doctor_id or int(doctor_id) != int(rx.doctor_id or 0):
            return error_response("Access denied.", status_code=403)

    if role == "assistant":
        assistant, err = _load_active_assistant_or_error()
        if err:
            return err
        perm_err = _assistant_require_any_permission(
            assistant,
            ["can_view_patient_history", "can_print_prescription"],
        )
        if perm_err:
            return perm_err

        # assistant can only view prescriptions for their assigned doctor
        doctor_id = claims.get("doctor_id")
        if not doctor_id or int(doctor_id) != int(rx.doctor_id or 0):
            return error_response("Access denied.", status_code=403)

    if role == "patient":
        if int(rx.patient_id) != int(patient.id):
            return error_response("Access denied.", status_code=403)

    return success_response(
        "Prescription retrieved.",
        data={"prescription": rx.to_dict(include_medicines=True, include_lab_tests=True)},
    )


@prescription_bp.route("/patient/<int:patient_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "pharmacy", "doctor", "assistant", "patient")
def prescriptions_by_patient(patient_id):
    claims = get_jwt()
    role = claims.get("role")

    if role == "patient":
        user_id = get_jwt_identity()
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or patient.id != patient_id:
            return error_response("Access denied.", status_code=403)
        clinic_id = patient.clinic_id
    else:
        clinic_id, err = _resolve_clinic_id_for_read()
        if err:
            return err

        if role in ("doctor", "assistant"):
            doctor_id = claims.get("doctor_id")
            if not doctor_id:
                return error_response("Doctor context is missing.", status_code=400)

            if role == "assistant":
                assistant, err = _load_active_assistant_or_error()
                if err:
                    return err
                perm_err = _assistant_require_any_permission(
                    assistant,
                    ["can_view_patient_history", "can_print_prescription"],
                )
                if perm_err:
                    return perm_err

            if not PatientService.doctor_can_access_patient(clinic_id, int(doctor_id), patient_id):
                return error_response("Access denied.", status_code=403)

    prescriptions = PrescriptionService.get_by_patient(clinic_id, patient_id)
    return success_response(
        "Prescriptions retrieved.",
        data={"prescriptions": [p.to_dict(include_medicines=True, include_lab_tests=True) for p in prescriptions]},
    )


@prescription_bp.route("/appointment/<int:appointment_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "pharmacy", "doctor", "assistant", "patient")
def prescription_by_appointment(appointment_id):
    claims = get_jwt()
    role = claims.get("role")

    if role == "patient":
        user_id = get_jwt_identity()
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient:
            return error_response("Access denied.", status_code=403)
        clinic_id = patient.clinic_id
    else:
        clinic_id, err = _resolve_clinic_id_for_read()
        if err:
            return err

    rx = PrescriptionService.get_by_appointment(clinic_id, appointment_id)
    if not rx:
        return error_response("Prescription not found.", status_code=404)

    if role == "doctor":
        doctor_id = claims.get("doctor_id")
        if not doctor_id or int(doctor_id) != int(rx.doctor_id or 0):
            return error_response("Access denied.", status_code=403)

    if role == "assistant":
        assistant, err = _load_active_assistant_or_error()
        if err:
            return err
        perm_err = _assistant_require_any_permission(
            assistant,
            ["can_view_patient_history", "can_print_prescription"],
        )
        if perm_err:
            return perm_err

        doctor_id = claims.get("doctor_id")
        if not doctor_id or int(doctor_id) != int(rx.doctor_id or 0):
            return error_response("Access denied.", status_code=403)

    if role == "patient":
        if int(rx.patient_id) != int(patient.id):
            return error_response("Access denied.", status_code=403)

    return success_response(
        "Prescription retrieved.",
        data={"prescription": rx.to_dict(include_medicines=True, include_lab_tests=True)},
    )


@prescription_bp.route("/<int:prescription_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def update_prescription(prescription_id):
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id") or 0)
    doctor_id = claims.get("doctor_id")
    if not clinic_id or not doctor_id:
        return error_response("Doctor context is missing.", status_code=400)

    data = request.get_json(silent=True) or {}
    try:
        rx = PrescriptionService.update(clinic_id, int(doctor_id), prescription_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Prescription not found." else 422)

    return success_response(
        "Prescription updated successfully.",
        data={"prescription": rx.to_dict(include_medicines=True, include_lab_tests=True)},
    )


@prescription_bp.route("/<int:prescription_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def delete_prescription(prescription_id):
    claims = get_jwt()
    clinic_id = int(claims.get("clinic_id") or 0)
    doctor_id = claims.get("doctor_id")
    if not clinic_id or not doctor_id:
        return error_response("Doctor context is missing.", status_code=400)

    try:
        PrescriptionService.delete(clinic_id, int(doctor_id), prescription_id)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Prescription not found." else 422)

    return success_response("Prescription deleted successfully.")
