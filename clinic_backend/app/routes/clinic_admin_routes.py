from datetime import date

from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt

from ..services.clinic_admin_service import ClinicAdminService
from ..utils.decorators import clinic_admin_required, active_user_required, clinic_approved_required
from ..utils.response_utils import success_response, error_response, paginated_response
from ..utils.validators import parse_date, parse_int


clinic_admin_bp = Blueprint("clinic_admin", __name__)


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


@clinic_admin_bp.route("/dashboard", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def dashboard():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = ClinicAdminService.dashboard(clinic_id)
    return success_response("Clinic admin dashboard retrieved.", data=data)


@clinic_admin_bp.route("/revenue", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def revenue():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = ClinicAdminService.revenue(clinic_id)
    return success_response("Clinic revenue summary retrieved.", data=data)


@clinic_admin_bp.route("/reports", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def reports():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    start_date_str = request.args.get("start_date")
    end_date_str = request.args.get("end_date")
    doctor_id = request.args.get("doctor_id")
    group_by = request.args.get("group_by") or "day"

    try:
        start = parse_date(start_date_str)
        end = parse_date(end_date_str)
        did = parse_int(doctor_id, "doctor_id", minimum=1) if doctor_id is not None else None
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    if did:
        data = ClinicAdminService.reports(clinic_id, start, end, did)
    else:
        try:
            data = ClinicAdminService.advanced_reports(clinic_id, start, end, group_by=group_by)
        except ValueError as exc:
            return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)
    return success_response("Clinic reports retrieved.", data=data)


@clinic_admin_bp.route("/patients", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def list_patients():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)
    search = request.args.get("q")

    paginated = ClinicAdminService.list_patients(clinic_id, page=page, per_page=per_page, search=search)

    return paginated_response(
        "Patients retrieved.",
        data=[p.to_dict() for p in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@clinic_admin_bp.route("/appointments", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def list_appointments():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    status = request.args.get("status")
    doctor_id = request.args.get("doctor_id")
    exact_date = request.args.get("date")
    start_date_str = request.args.get("start_date")
    end_date_str = request.args.get("end_date")

    try:
        did = parse_int(doctor_id, "doctor_id", minimum=1) if doctor_id is not None else None
        d_exact = parse_date(exact_date)
        d_start = parse_date(start_date_str)
        d_end = parse_date(end_date_str)
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    paginated = ClinicAdminService.list_appointments(
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
        data=[ClinicAdminService._appointment_card(a) for a in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )
