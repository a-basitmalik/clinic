from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt

from ..services.doctor_service import DoctorService
from ..services.appointment_service import AppointmentService
from ..utils.decorators import clinic_admin_required, active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import success_response, error_response
from ..utils.validators import parse_date


doctor_bp = Blueprint("doctors", __name__)


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


@doctor_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def create_doctor():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    try:
        result = DoctorService.create(clinic_id, data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response(
        "Doctor created successfully.",
        data=result,
        status_code=201,
    )


@doctor_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def list_doctors():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    include_inactive = request.args.get("include_inactive", "1") in ("1", "true", "True")
    doctors = DoctorService.list(clinic_id, include_inactive=include_inactive)
    return success_response("Doctors retrieved.", data={"doctors": [d.to_dict() for d in doctors]})


@doctor_bp.route("/<int:doctor_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def get_doctor(doctor_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    doctor = DoctorService.get(clinic_id, doctor_id)
    if not doctor:
        return error_response("Doctor not found.", status_code=404)

    return success_response("Doctor retrieved.", data={"doctor": doctor.to_dict()})


@doctor_bp.route("/<int:doctor_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def update_doctor(doctor_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    try:
        doctor = DoctorService.update(clinic_id, doctor_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=422 if msg != "Doctor not found." else 404)

    return success_response("Doctor updated successfully.", data={"doctor": doctor.to_dict()})


@doctor_bp.route("/<int:doctor_id>/deactivate", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def deactivate_doctor(doctor_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    try:
        doctor = DoctorService.deactivate(clinic_id, doctor_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Doctor deactivated successfully.", data={"doctor": doctor.to_dict()})


@doctor_bp.route("/<int:doctor_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def delete_doctor(doctor_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    try:
        doctor = DoctorService.soft_delete(clinic_id, doctor_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Doctor deleted successfully (soft delete).", data={"doctor": doctor.to_dict()})


# ── Phase 6: Doctor workflow (doctor role) ──────────────────────────────────


def _resolve_doctor_context():
    claims = get_jwt()
    clinic_id = claims.get("clinic_id")
    doctor_id = claims.get("doctor_id")
    if not clinic_id or not doctor_id:
        return None, None, error_response("Doctor context is missing.", status_code=400)
    return int(clinic_id), int(doctor_id), None


@doctor_bp.route("/dashboard", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def doctor_dashboard():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    data = DoctorService.dashboard(clinic_id, doctor_id)

    # Ensure token_code in queue items
    data["today_queue"] = [AppointmentService.to_dict(a) for a in AppointmentService.doctor_queue(clinic_id, doctor_id)]
    return success_response("Doctor dashboard retrieved.", data=data)


@doctor_bp.route("/today-appointments", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def doctor_today_appointments():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    appts = AppointmentService.today(clinic_id, doctor_id=doctor_id)
    return success_response(
        "Today's appointments retrieved.",
        data={"appointments": [AppointmentService.to_dict(a) for a in appts]},
    )


@doctor_bp.route("/queue", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def doctor_queue():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    on_date = request.args.get("date")
    try:
        d = parse_date(on_date) if on_date else None
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    appts = AppointmentService.doctor_queue(clinic_id, doctor_id, on_date=d)
    return success_response("Doctor queue retrieved.", data={"appointments": [AppointmentService.to_dict(a) for a in appts]})


@doctor_bp.route("/patients/<int:patient_id>/profile", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def doctor_patient_profile(patient_id):
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    include_clinic_history = request.args.get("include_clinic_history", "1") in ("1", "true", "True")

    try:
        profile = DoctorService.patient_profile(
            clinic_id,
            doctor_id,
            patient_id,
            include_clinic_history=include_clinic_history,
        )
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Patient profile retrieved.", data=profile)


@doctor_bp.route("/appointments/<int:appointment_id>/start", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def start_consultation(appointment_id):
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    try:
        appt = AppointmentService.start_consultation(clinic_id, doctor_id=doctor_id, appointment_id=appointment_id)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Appointment not found." else 422)

    return success_response("Consultation started.", data={"appointment": AppointmentService.to_dict(appt)})


@doctor_bp.route("/appointments/<int:appointment_id>/complete", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def complete_consultation(appointment_id):
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    allow_no_prescription = bool(data.get("allow_no_prescription"))

    try:
        appt = AppointmentService.complete_appointment(
            clinic_id,
            doctor_id=doctor_id,
            appointment_id=appointment_id,
            allow_no_prescription=allow_no_prescription,
        )
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Appointment not found." else 422)

    return success_response("Appointment completed.", data={"appointment": AppointmentService.to_dict(appt)})


@doctor_bp.route("/earnings", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def doctor_earnings():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    try:
        start_date = parse_date(request.args.get("start_date"))
        end_date = parse_date(request.args.get("end_date"))
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    data = DoctorService.earnings(clinic_id, doctor_id, start_date=start_date, end_date=end_date)
    return success_response("Doctor earnings retrieved.", data=data)


@doctor_bp.route("/reports", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("doctor")
def doctor_reports():
    clinic_id, doctor_id, err = _resolve_doctor_context()
    if err:
        return err

    try:
        start_date = parse_date(request.args.get("start_date"))
        end_date = parse_date(request.args.get("end_date"))
        group_by = request.args.get("group_by") or "day"
        data = DoctorService.reports(clinic_id, doctor_id, start_date=start_date, end_date=end_date, group_by=group_by)
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    return success_response("Doctor reports retrieved.", data=data)
