from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt

from ..services.pharmacy_service import PharmacyService
from ..services.report_service import ReportService
from ..utils.decorators import active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import success_response, error_response
from ..utils.validators import parse_date, parse_int


report_bp = Blueprint("reports", __name__)


def _common_filters():
    try:
        parsed = ReportService.normalize_filters(
            start_date=parse_date(request.args.get("start_date")),
            end_date=parse_date(request.args.get("end_date")),
            group_by=request.args.get("group_by"),
            export=request.args.get("export", "false"),
        )
    except ValueError as exc:
        return None, error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)
    return parsed, None


def _clinic_scope(*, super_admin_requires_clinic: bool = False):
    claims = get_jwt()
    role = claims.get("role")
    if role == "super_admin":
        clinic_id = request.args.get("clinic_id", type=int)
        if super_admin_requires_clinic and not clinic_id:
            return None, error_response("clinic_id query param is required for super_admin.", status_code=400)
        return clinic_id, None

    clinic_id = claims.get("clinic_id")
    if not clinic_id:
        return None, error_response("Clinic context is missing.", status_code=400)
    return int(clinic_id), None


def _doctor_filter_for_role(clinic_id: int | None):
    claims = get_jwt()
    role = claims.get("role")
    if role == "doctor":
        doctor_id = claims.get("doctor_id")
        if not doctor_id:
            return None, error_response("Doctor context is missing.", status_code=400)
        return int(doctor_id), None

    raw_doctor_id = request.args.get("doctor_id")
    try:
        doctor_id = parse_int(raw_doctor_id, "doctor_id", minimum=1) if raw_doctor_id is not None else None
        if doctor_id:
            ReportService._doctor_in_clinic(clinic_id, doctor_id)
    except ValueError as exc:
        return None, error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)
    return doctor_id, None


@report_bp.route("/clinic-revenue", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin")
def clinic_revenue_report():
    clinic_id, err = _clinic_scope(super_admin_requires_clinic=False)
    if err:
        return err
    filters, err = _common_filters()
    if err:
        return err
    doctor_id, err = _doctor_filter_for_role(clinic_id)
    if err:
        return err

    try:
        data = ReportService.clinic_revenue_report(
            clinic_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
            payment_type=request.args.get("payment_type"),
            doctor_id=doctor_id,
            export=filters["export"],
        )
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)
    return success_response("Clinic revenue report retrieved.", data=data)


@report_bp.route("/doctor-revenue", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor")
def doctor_revenue_report():
    clinic_id, err = _clinic_scope(super_admin_requires_clinic=False)
    if err:
        return err
    filters, err = _common_filters()
    if err:
        return err
    doctor_id, err = _doctor_filter_for_role(clinic_id)
    if err:
        return err
    if not doctor_id:
        return error_response("doctor_id query param is required.", status_code=400)

    try:
        data = ReportService.doctor_revenue_report(
            clinic_id,
            doctor_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
            export=filters["export"],
        )
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)
    return success_response("Doctor revenue report retrieved.", data=data)


@report_bp.route("/pharmacy-sales", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def pharmacy_sales_report():
    clinic_id, err = _clinic_scope(super_admin_requires_clinic=False)
    if err:
        return err
    if get_jwt().get("role") != "super_admin":
        feature_err = _require_pharmacy_enabled(clinic_id)
        if feature_err:
            return feature_err

    filters, err = _common_filters()
    if err:
        return err
    page = request.args.get("page", type=int)
    per_page = request.args.get("per_page", type=int)
    if per_page is not None:
        per_page = min(int(per_page), 100)

    data = ReportService.pharmacy_sales_report(
        clinic_id,
        start_date=filters["start_date"],
        end_date=filters["end_date"],
        group_by=filters["group_by"],
        page=page,
        per_page=per_page,
        export=filters["export"],
    )
    return success_response("Pharmacy sales report retrieved.", data=data)


@report_bp.route("/patient-visits", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor", "receptionist")
def patient_visits_report():
    clinic_id, err = _clinic_scope(super_admin_requires_clinic=False)
    if err:
        return err
    filters, err = _common_filters()
    if err:
        return err
    doctor_id, err = _doctor_filter_for_role(clinic_id)
    if err:
        return err
    data = ReportService.patient_visits_report(
        clinic_id,
        start_date=filters["start_date"],
        end_date=filters["end_date"],
        group_by=filters["group_by"],
        doctor_id=doctor_id,
        export=filters["export"],
    )
    return success_response("Patient visits report retrieved.", data=data)


@report_bp.route("/appointments", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "doctor", "receptionist")
def appointments_report():
    clinic_id, err = _clinic_scope(super_admin_requires_clinic=False)
    if err:
        return err
    filters, err = _common_filters()
    if err:
        return err
    doctor_id, err = _doctor_filter_for_role(clinic_id)
    if err:
        return err
    data = ReportService.appointments_report(
        clinic_id,
        start_date=filters["start_date"],
        end_date=filters["end_date"],
        group_by=filters["group_by"],
        doctor_id=doctor_id,
        status=request.args.get("status"),
        export=filters["export"],
    )
    return success_response("Appointments report retrieved.", data=data)


@report_bp.route("/payments", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "pharmacy")
def payments_report():
    clinic_id, err = _clinic_scope(super_admin_requires_clinic=False)
    if err:
        return err
    filters, err = _common_filters()
    if err:
        return err

    payment_type = request.args.get("payment_type")
    if get_jwt().get("role") == "pharmacy":
        payment_type = "pharmacy"

    try:
        data = ReportService.payments_report(
            clinic_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
            payment_type=payment_type,
            status=request.args.get("status"),
            export=filters["export"],
        )
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)
    return success_response("Payments report retrieved.", data=data)


def _require_pharmacy_enabled(clinic_id: int):
    try:
        PharmacyService.require_pharmacy_enabled(clinic_id)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Clinic not found." else 422)
    return None
