from datetime import date

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..services.receptionist_service import ReceptionistService
from ..extensions import db
from ..models.appointment import Appointment
from ..models.patient import Patient
from ..models.payment import Payment
from ..services.appointment_service import AppointmentService
from ..utils.decorators import clinic_admin_required, active_user_required, clinic_approved_required, receptionist_required
from ..utils.response_utils import success_response, error_response
from ..utils.validators import parse_date, parse_int


receptionist_bp = Blueprint("receptionists", __name__)


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


@receptionist_bp.route("/dashboard", methods=["GET"])
@jwt_required()
@active_user_required
@receptionist_required
@clinic_approved_required
def receptionist_dashboard():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    today = date.today()

    today_total_appointments = Appointment.query.filter_by(clinic_id=clinic_id).filter(
        Appointment.appointment_date == today
    ).count()

    today_waiting = Appointment.query.filter_by(clinic_id=clinic_id).filter(
        Appointment.appointment_date == today,
        Appointment.status.in_(["waiting", "sent_to_assistant", "in_consultation"]),
    ).count()

    today_completed = Appointment.query.filter_by(clinic_id=clinic_id).filter(
        Appointment.appointment_date == today,
        Appointment.status == "completed",
    ).count()

    today_cancelled = Appointment.query.filter_by(clinic_id=clinic_id).filter(
        Appointment.appointment_date == today,
        Appointment.status == "cancelled",
    ).count()

    today_revenue_collected = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
        Payment.clinic_id == clinic_id,
        Payment.status == "paid",
        db.func.date(Payment.created_at) == today,
        Payment.payment_type == "consultation",
    ).scalar()

    total_patients = Patient.query.filter_by(clinic_id=clinic_id).count()

    recent_patients = (
        Patient.query.filter_by(clinic_id=clinic_id)
        .order_by(Patient.created_at.desc())
        .limit(10)
        .all()
    )

    today_queue = (
        Appointment.query.filter_by(clinic_id=clinic_id)
        .filter(Appointment.appointment_date == today)
        .order_by(Appointment.token_number.asc())
        .limit(50)
        .all()
    )

    return success_response(
        "Receptionist dashboard retrieved.",
        data={
            "today_total_appointments": today_total_appointments,
            "today_waiting": today_waiting,
            "today_completed": today_completed,
            "today_cancelled": today_cancelled,
            "today_revenue_collected": float(today_revenue_collected or 0),
            "total_patients": total_patients,
            "recent_patients": [p.to_dict() for p in recent_patients],
            "today_queue": [AppointmentService.to_dict(a) for a in today_queue],
        },
    )


@receptionist_bp.route("/reports", methods=["GET"])
@jwt_required()
@active_user_required
@receptionist_required
@clinic_approved_required
def receptionist_reports():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    try:
        role = get_jwt().get("role")
        if role == "receptionist":
            receptionist_id = get_jwt_identity()
        else:
            raw_id = request.args.get("receptionist_id")
            receptionist_id = parse_int(raw_id, "receptionist_id", minimum=1) if raw_id is not None else None
        data = ReceptionistService.reports(
            clinic_id,
            receptionist_id,
            start_date=parse_date(request.args.get("start_date")),
            end_date=parse_date(request.args.get("end_date")),
            group_by=request.args.get("group_by") or "day",
        )
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    return success_response("Receptionist reports retrieved.", data=data)


@receptionist_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def create_receptionist():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    try:
        result = ReceptionistService.create(clinic_id, data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Receptionist created successfully.", data=result, status_code=201)


@receptionist_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def list_receptionists():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    include_inactive = request.args.get("include_inactive", "1") in ("1", "true", "True")
    users = ReceptionistService.list(clinic_id, include_inactive=include_inactive)
    return success_response("Receptionists retrieved.", data={"receptionists": [u.to_dict() for u in users]})


@receptionist_bp.route("/<int:user_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def get_receptionist(user_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    user = ReceptionistService.get(clinic_id, user_id)
    if not user:
        return error_response("Receptionist not found.", status_code=404)

    return success_response("Receptionist retrieved.", data={"receptionist": user.to_dict()})


@receptionist_bp.route("/<int:user_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def update_receptionist(user_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    try:
        user = ReceptionistService.update(clinic_id, user_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=422 if msg != "Receptionist not found." else 404)

    return success_response("Receptionist updated successfully.", data={"receptionist": user.to_dict()})


@receptionist_bp.route("/<int:user_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def delete_receptionist(user_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    try:
        user = ReceptionistService.soft_delete(clinic_id, user_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Receptionist deleted successfully (soft delete).", data={"receptionist": user.to_dict()})
