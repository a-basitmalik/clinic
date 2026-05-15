from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..models.patient import Patient
from ..models.pharmacy import PharmacySale
from ..services.pharmacy_service import PharmacyService
from ..services.report_service import ReportService
from ..utils.decorators import (
    clinic_admin_required,
    active_user_required,
    clinic_approved_required,
    role_required,
)
from ..utils.response_utils import success_response, error_response, paginated_response
from ..utils.validators import parse_date, parse_int


pharmacy_bp = Blueprint("pharmacy", __name__)


def _resolve_clinic_id():
    claims = get_jwt()
    role = claims.get("role")
    if role == "super_admin":
        clinic_id = request.args.get("clinic_id", type=int)
        if not clinic_id:
            return None, error_response("clinic_id query param is required for super_admin.", status_code=400)
        return clinic_id, None

    clinic_id = claims.get("clinic_id")
    if role == "patient" and not clinic_id:
        patient = Patient.query.filter_by(user_id=get_jwt_identity()).first()
        if patient:
            clinic_id = patient.clinic_id
    if not clinic_id:
        return None, error_response("Clinic context is missing.", status_code=400)
    return int(clinic_id), None


def _require_pharmacy_enabled(clinic_id: int):
    try:
        PharmacyService.require_pharmacy_enabled(clinic_id)
    except ValueError as exc:
        msg = str(exc)
        # 404 if clinic missing, else 422 for feature disabled
        return error_response(msg, status_code=404 if msg == "Clinic not found." else 422)
    return None


@pharmacy_bp.route("/users", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def create_pharmacy_user():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = request.get_json(silent=True) or {}
    try:
        result = PharmacyService.create_user(clinic_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=422)

    return success_response("Pharmacy user created successfully.", data=result, status_code=201)


@pharmacy_bp.route("/users", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def list_pharmacy_users():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    include_inactive = request.args.get("include_inactive", "1") in ("1", "true", "True")
    users = PharmacyService.list_users(clinic_id, include_inactive=include_inactive)
    return success_response("Pharmacy users retrieved.", data={"pharmacy_users": [u.to_dict() for u in users]})


@pharmacy_bp.route("/users/<int:user_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def get_pharmacy_user(user_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    user = PharmacyService.get_user(clinic_id, user_id)
    if not user:
        return error_response("Pharmacy user not found.", status_code=404)

    return success_response("Pharmacy user retrieved.", data={"pharmacy_user": user.to_dict()})


@pharmacy_bp.route("/users/<int:user_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def update_pharmacy_user(user_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = request.get_json(silent=True) or {}
    try:
        user = PharmacyService.update_user(clinic_id, user_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=422 if msg != "Pharmacy user not found." else 404)

    return success_response("Pharmacy user updated successfully.", data={"pharmacy_user": user.to_dict()})


@pharmacy_bp.route("/users/<int:user_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def delete_pharmacy_user(user_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    try:
        user = PharmacyService.soft_delete_user(clinic_id, user_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Pharmacy user deleted successfully (soft delete).", data={"pharmacy_user": user.to_dict()})


# ── Phase 7: Pharmacy workflow ─────────────────────────────────────────────


@pharmacy_bp.route("/dashboard", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def pharmacy_dashboard():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = PharmacyService.dashboard(clinic_id)
    return success_response("Pharmacy dashboard retrieved.", data=data)


# ── Inventory ─────────────────────────────────────────────────────────────


@pharmacy_bp.route("/items", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("clinic_admin", "pharmacy")
def create_medicine():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = request.get_json(silent=True) or {}
    try:
        item = PharmacyService.create_item(clinic_id, data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)
    return success_response("Medicine created successfully.", data={"medicine": item.to_dict()}, status_code=201)


@pharmacy_bp.route("/items", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def list_medicines():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    q = request.args.get("search") or request.args.get("q")
    category = request.args.get("category")
    status = request.args.get("status")

    low_stock = request.args.get("low_stock") in ("1", "true", "True")
    expiring = request.args.get("expiring") in ("1", "true", "True")
    expired = request.args.get("expired") in ("1", "true", "True")

    paginated = PharmacyService.list_items(
        clinic_id,
        page=page,
        per_page=per_page,
        q=q,
        category=category,
        status=status,
        low_stock=low_stock or None,
        expiring=expiring or None,
        expired=expired or None,
    )

    return paginated_response(
        "Medicines retrieved.",
        data=[i.to_dict() for i in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@pharmacy_bp.route("/items/<int:item_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def get_medicine(item_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    item = PharmacyService.get_item(clinic_id, item_id)
    if not item:
        return error_response("Medicine not found.", status_code=404)
    return success_response("Medicine retrieved.", data={"medicine": item.to_dict()})


@pharmacy_bp.route("/items/<int:item_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("clinic_admin", "pharmacy")
def update_medicine(item_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = request.get_json(silent=True) or {}
    try:
        item = PharmacyService.update_item(clinic_id, item_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Medicine not found." else 422)
    return success_response("Medicine updated successfully.", data={"medicine": item.to_dict()})


@pharmacy_bp.route("/items/<int:item_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("clinic_admin", "pharmacy")
def delete_medicine(item_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    try:
        item = PharmacyService.soft_delete_item(clinic_id, item_id)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Medicine not found." else 422)

    return success_response("Medicine deleted successfully (soft delete).", data={"medicine": item.to_dict()})


@pharmacy_bp.route("/low-stock", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def low_stock_items():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    q = request.args.get("search") or request.args.get("q")
    category = request.args.get("category")
    status = request.args.get("status")

    paginated = PharmacyService.list_items(
        clinic_id,
        page=page,
        per_page=per_page,
        q=q,
        category=category,
        status=status,
        low_stock=True,
    )

    return paginated_response(
        "Low stock items retrieved.",
        data=[i.to_dict() for i in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@pharmacy_bp.route("/expiring", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def expiring_items():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    q = request.args.get("search") or request.args.get("q")
    category = request.args.get("category")
    status = request.args.get("status")

    paginated = PharmacyService.list_items(
        clinic_id,
        page=page,
        per_page=per_page,
        q=q,
        category=category,
        status=status,
        expiring=True,
    )

    return paginated_response(
        "Expiring items retrieved.",
        data=[i.to_dict() for i in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@pharmacy_bp.route("/expired", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def expired_items():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    q = request.args.get("search") or request.args.get("q")
    category = request.args.get("category")
    status = request.args.get("status")

    paginated = PharmacyService.list_items(
        clinic_id,
        page=page,
        per_page=per_page,
        q=q,
        category=category,
        status=status,
        expired=True,
    )

    return paginated_response(
        "Expired items retrieved.",
        data=[i.to_dict() for i in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


# ── Prescription orders ───────────────────────────────────────────────────


@pharmacy_bp.route("/prescription-orders", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def list_prescription_orders():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    status = request.args.get("status")
    doctor_id = request.args.get("doctor_id")
    patient_id = request.args.get("patient_id")
    on_date = request.args.get("date")
    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")

    try:
        did = parse_int(doctor_id, "doctor_id", minimum=1) if doctor_id is not None else None
        pid = parse_int(patient_id, "patient_id", minimum=1) if patient_id is not None else None
        d_on = parse_date(on_date)
        d_start = parse_date(start_date)
        d_end = parse_date(end_date)
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    paginated = PharmacyService.list_prescription_orders(
        clinic_id,
        page=page,
        per_page=per_page,
        status=status,
        doctor_id=did,
        patient_id=pid,
        on_date=d_on,
        start_date=d_start,
        end_date=d_end,
    )

    # Lightweight list payload; detail endpoint includes inventory matching
    data = []
    for rx in paginated.items:
        row = rx.to_dict(include_medicines=True, include_lab_tests=False)
        row["patient"] = rx.patient.to_dict() if rx.patient else None
        row["doctor"] = rx.doctor.to_dict() if rx.doctor else None
        row["appointment"] = rx.appointment.to_dict() if rx.appointment else None
        row["order_status"] = rx.pharmacy_status
        data.append(row)

    return paginated_response(
        "Prescription orders retrieved.",
        data=data,
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@pharmacy_bp.route("/prescription-orders/<int:prescription_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def prescription_order_detail(prescription_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    try:
        data = PharmacyService.prescription_order_detail(clinic_id, prescription_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Prescription order retrieved.", data=data)


@pharmacy_bp.route("/prescription-orders/<int:prescription_id>/status", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("clinic_admin", "pharmacy")
def update_prescription_order_status(prescription_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = request.get_json(silent=True) or {}
    status = data.get("status") or data.get("pharmacy_status")
    if not status:
        return error_response("status is required.", status_code=422)

    try:
        rx = PharmacyService.update_prescription_order_status(clinic_id, prescription_id, str(status))
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=404 if msg == "Prescription not found." else 422)

    return success_response("Prescription order status updated.", data={"prescription": rx.to_dict(include_medicines=True, include_lab_tests=True)})


# ── Sales ────────────────────────────────────────────────────────────────


@pharmacy_bp.route("/sales", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("clinic_admin", "pharmacy")
def create_sale():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    data = request.get_json(silent=True) or {}
    try:
        sale = PharmacyService.create_sale(clinic_id, sold_by_user_id=get_jwt_identity(), data=data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Sale created successfully.", data={"sale": sale.to_dict(include_items=True)}, status_code=201)


@pharmacy_bp.route("/sales", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def list_sales():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    patient_id = request.args.get("patient_id")
    prescription_id = request.args.get("prescription_id")
    payment_status = request.args.get("payment_status")
    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")

    try:
        pid = parse_int(patient_id, "patient_id", minimum=1) if patient_id is not None else None
        rxid = parse_int(prescription_id, "prescription_id", minimum=1) if prescription_id is not None else None
        d_start = parse_date(start_date)
        d_end = parse_date(end_date)
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    paginated = PharmacyService.list_sales(
        clinic_id,
        page=page,
        per_page=per_page,
        patient_id=pid,
        prescription_id=rxid,
        payment_status=payment_status,
        start_date=d_start,
        end_date=d_end,
    )

    return paginated_response(
        "Sales retrieved.",
        data=[s.to_dict(include_items=True) for s in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


def _sale_access_guard(clinic_id: int, sale: PharmacySale):
    claims = get_jwt()
    role = claims.get("role")

    # super_admin already required to provide clinic_id in _resolve_clinic_id()
    if role in ("clinic_admin", "pharmacy", "super_admin"):
        return None

    if role == "receptionist":
        # same clinic enforced by clinic_id in token
        return None

    if role == "patient":
        patient = Patient.query.filter_by(user_id=get_jwt_identity()).first()
        if not patient or int(patient.clinic_id) != int(clinic_id):
            return error_response("Access denied.", status_code=403)
        if not sale.patient_id or int(sale.patient_id) != int(patient.id):
            return error_response("Access denied.", status_code=403)
        return None

    return error_response("Access denied.", status_code=403)


@pharmacy_bp.route("/sales/<int:sale_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy", "receptionist", "patient")
def get_sale(sale_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    sale = PharmacyService.get_sale(clinic_id, sale_id)
    if not sale:
        return error_response("Sale not found.", status_code=404)

    guard_err = _sale_access_guard(clinic_id, sale)
    if guard_err:
        return guard_err

    return success_response("Sale retrieved.", data={"sale": sale.to_dict(include_items=True)})


@pharmacy_bp.route("/sales/<int:sale_id>/invoice", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy", "receptionist", "patient")
def sale_invoice(sale_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    sale = PharmacyService.get_sale(clinic_id, sale_id)
    if not sale:
        return error_response("Sale not found.", status_code=404)

    guard_err = _sale_access_guard(clinic_id, sale)
    if guard_err:
        return guard_err

    try:
        data = PharmacyService.invoice_data(clinic_id, sale_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Invoice data retrieved.", data=data)


# ── Reports ──────────────────────────────────────────────────────────────


@pharmacy_bp.route("/reports", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "pharmacy")
def pharmacy_reports():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err
    feature_err = _require_pharmacy_enabled(clinic_id)
    if feature_err:
        return feature_err

    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")
    page = request.args.get("page", type=int)
    per_page = request.args.get("per_page", type=int)
    if per_page is not None:
        per_page = min(int(per_page), 100)

    try:
        d_start = parse_date(start_date)
        d_end = parse_date(end_date)
        filters = ReportService.normalize_filters(
            start_date=d_start,
            end_date=d_end,
            group_by=request.args.get("group_by"),
            export=request.args.get("export", "false"),
        )
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    data = ReportService.pharmacy_sales_report(
        clinic_id,
        start_date=filters["start_date"],
        end_date=filters["end_date"],
        group_by=filters["group_by"],
        page=page,
        per_page=per_page,
        export=filters["export"],
    )

    return success_response("Pharmacy reports retrieved.", data=data)
