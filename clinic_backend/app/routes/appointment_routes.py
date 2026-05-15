from datetime import date

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..models.appointment import Appointment
from ..models.doctor import Doctor
from ..services.appointment_service import AppointmentService
from ..utils.decorators import active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import success_response, error_response, paginated_response
from ..utils.validators import parse_date, parse_time, parse_int


appointment_bp = Blueprint("appointments", __name__)


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


@appointment_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist")
def create_appointment():
    claims = get_jwt()
    role = claims.get("role")

    if role == "super_admin":
        clinic_id = request.args.get("clinic_id", type=int)
        if not clinic_id:
            return error_response("clinic_id query param is required for super_admin.", status_code=400)
        receptionist_user_id = get_jwt_identity()
    else:
        clinic_id = claims.get("clinic_id")
        if not clinic_id:
            return error_response("Clinic context is missing.", status_code=400)
        clinic_id = int(clinic_id)
        receptionist_user_id = get_jwt_identity()

    data = request.get_json(silent=True) or {}
    try:
        result = AppointmentService.create(clinic_id, receptionist_user_id=receptionist_user_id, data=data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Appointment booked successfully.", data=result, status_code=201)


@appointment_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor")
def list_appointments():
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    status = request.args.get("status")
    doctor_id = request.args.get("doctor_id")
    exact_date = request.args.get("date")
    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")

    try:
        did = parse_int(doctor_id, "doctor_id", minimum=1) if doctor_id is not None else None
        d_exact = parse_date(exact_date)
        d_start = parse_date(start_date)
        d_end = parse_date(end_date)
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    if role == "doctor":
        jwt_doctor_id = claims.get("doctor_id")
        if not jwt_doctor_id:
            return error_response("Doctor context is missing.", status_code=400)
        did = int(jwt_doctor_id)

    paginated = AppointmentService.list(
        clinic_id,
        page=page,
        per_page=per_page,
        status=status,
        doctor_id=did,
        exact_date=d_exact,
        start_date=d_start,
        end_date=d_end,
    )

    return paginated_response(
        "Appointments retrieved.",
        data=[AppointmentService.to_dict(a) for a in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@appointment_bp.route("/today", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor")
def today_appointments():
    clinic_id, err = _resolve_clinic_id_for_read()
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

    appts = AppointmentService.today(clinic_id, doctor_id=doctor_id)
    return success_response("Today's appointments retrieved.", data={"appointments": [AppointmentService.to_dict(a) for a in appts]})


@appointment_bp.route("/doctor/<int:doctor_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor")
def doctor_queue(doctor_id):
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")

    if role == "doctor":
        jwt_doctor_id = claims.get("doctor_id")
        if not jwt_doctor_id or int(jwt_doctor_id) != int(doctor_id):
            return error_response("Access denied.", status_code=403)

    # Validate doctor belongs to clinic
    doc = Doctor.query.filter_by(clinic_id=clinic_id, id=doctor_id).first()
    if not doc:
        return error_response("Doctor not found in this clinic.", status_code=404)

    d = request.args.get("date")
    try:
        on_date = parse_date(d) if d else date.today()
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    appts = AppointmentService.doctor_queue(clinic_id, doctor_id, on_date=on_date)
    return success_response("Doctor queue retrieved.", data={"date": on_date.isoformat(), "appointments": [AppointmentService.to_dict(a) for a in appts]})


@appointment_bp.route("/<int:appointment_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor")
def get_appointment(appointment_id):
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    appt = AppointmentService.get(clinic_id, appointment_id)
    if not appt:
        return error_response("Appointment not found.", status_code=404)

    claims = get_jwt()
    if claims.get("role") == "doctor":
        if int(claims.get("doctor_id") or 0) != int(appt.doctor_id):
            return error_response("Access denied.", status_code=403)

    return success_response("Appointment retrieved.", data={"appointment": AppointmentService.to_dict(appt)})


@appointment_bp.route("/<int:appointment_id>/status", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor", "assistant")
def update_appointment_status(appointment_id):
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    appt = AppointmentService.get(clinic_id, appointment_id)
    if not appt:
        return error_response("Appointment not found.", status_code=404)

    data = request.get_json(silent=True) or {}
    new_status = data.get("status")
    if not new_status:
        return error_response("status is required.", status_code=422)

    claims = get_jwt()
    role = claims.get("role")

    # Locked statuses
    if appt.status in ("cancelled", "completed") and role not in ("super_admin", "clinic_admin"):
        return error_response("Cancelled/completed appointments cannot be modified.", status_code=403)

    allowed = set()
    if role in ("super_admin", "clinic_admin"):
        allowed = {"waiting", "sent_to_assistant", "in_consultation", "completed", "cancelled"}
    elif role == "receptionist":
        allowed = {"waiting", "sent_to_assistant", "cancelled"}
    elif role == "doctor":
        if int(claims.get("doctor_id") or 0) != int(appt.doctor_id):
            return error_response("Access denied.", status_code=403)
        allowed = {"in_consultation", "completed"}
    elif role == "assistant":
        # Minimal: assistant can only mark sent_to_assistant if they belong to doctor and have permission
        from ..models.assistant import Assistant
        assistant = Assistant.query.filter_by(user_id=get_jwt_identity(), clinic_id=clinic_id, status="active").first()
        if not assistant or int(assistant.doctor_id) != int(appt.doctor_id) or not assistant.can_view_appointments:
            return error_response("Access denied.", status_code=403)
        allowed = {"sent_to_assistant"}

    if new_status not in allowed:
        return error_response("Status update not allowed for your role.", errors={"allowed": sorted(list(allowed))}, status_code=403)

    try:
        updated = AppointmentService.update_status(clinic_id, appointment_id, new_status)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Appointment status updated.", data={"appointment": AppointmentService.to_dict(updated)})


@appointment_bp.route("/<int:appointment_id>/cancel", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist")
def cancel_appointment(appointment_id):
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    appt = AppointmentService.get(clinic_id, appointment_id)
    if not appt:
        return error_response("Appointment not found.", status_code=404)

    if appt.status == "completed":
        return error_response("Completed appointments cannot be cancelled.", status_code=400)

    data = request.get_json(silent=True) or {}
    reason = (data.get("reason") or "").strip() or None

    try:
        cancelled = AppointmentService.cancel(clinic_id, appointment_id, reason=reason)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Appointment cancelled.", data={"appointment": AppointmentService.to_dict(cancelled)})


@appointment_bp.route("/<int:appointment_id>/reschedule", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist")
def reschedule_appointment(appointment_id):
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    appt = AppointmentService.get(clinic_id, appointment_id)
    if not appt:
        return error_response("Appointment not found.", status_code=404)

    if appt.status in ("cancelled", "completed"):
        return error_response("Cancelled/completed appointments cannot be rescheduled.", status_code=400)

    data = request.get_json(silent=True) or {}
    try:
        new_date = parse_date(data.get("appointment_date"))
        new_time = parse_time(data.get("appointment_time"))
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    if not new_date or not new_time:
        return error_response("appointment_date and appointment_time are required.", status_code=422)

    try:
        updated = AppointmentService.reschedule(clinic_id, appointment_id, new_date=new_date, new_time=new_time)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Appointment rescheduled.", data={"appointment": AppointmentService.to_dict(updated)})
