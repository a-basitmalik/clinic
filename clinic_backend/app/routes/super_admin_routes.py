from flask import Blueprint, request
from flask_jwt_extended import jwt_required

from ..extensions import db
from ..models.clinic import Clinic
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..models.user import User
from ..models.appointment import Appointment
from ..models.payment import Payment
from ..services.report_service import ReportService
from ..utils.response_utils import success_response, paginated_response, error_response
from ..utils.decorators import role_required
from ..utils.validators import parse_date

super_admin_bp = Blueprint("super_admin", __name__)


# ── Dashboard ─────────────────────────────────────────────────────────────────

@super_admin_bp.route("/dashboard", methods=["GET"])
@jwt_required()
@role_required("super_admin")
def dashboard():
    total_clinics = Clinic.query.count()
    active_clinics = Clinic.query.filter_by(status="approved").count()
    pending_clinics = Clinic.query.filter_by(status="pending").count()
    suspended_clinics = Clinic.query.filter_by(status="suspended").count()
    total_doctors = Doctor.query.filter_by(status="active").count()
    total_patients = Patient.query.count()

    total_revenue = db.session.query(
        db.func.coalesce(db.func.sum(Payment.amount), 0)
    ).filter(Payment.status == "paid").scalar()

    return success_response(
        "Dashboard data retrieved.",
        data={
            "total_clinics": total_clinics,
            "active_clinics": active_clinics,
            "pending_clinics": pending_clinics,
            "suspended_clinics": suspended_clinics,
            "total_doctors": total_doctors,
            "total_patients": total_patients,
            "total_system_revenue": float(total_revenue),
        },
    )


# ── Pending clinics list ──────────────────────────────────────────────────────

@super_admin_bp.route("/clinics/pending", methods=["GET"])
@jwt_required()
@role_required("super_admin")
def pending_clinics():
    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    paginated = (
        Clinic.query.filter_by(status="pending")
        .order_by(Clinic.created_at.asc())  # oldest first — review in order
        .paginate(page=page, per_page=per_page, error_out=False)
    )

    return paginated_response(
        "Pending clinics retrieved.",
        data=[c.to_dict() for c in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


# ── System stats ──────────────────────────────────────────────────────────────

@super_admin_bp.route("/stats", methods=["GET"])
@jwt_required()
@role_required("super_admin")
def system_stats():
    try:
        filters = ReportService.normalize_filters(
            start_date=parse_date(request.args.get("start_date")),
            end_date=parse_date(request.args.get("end_date")),
            group_by=request.args.get("group_by"),
        )
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    data = ReportService.system_stats(
        start_date=filters["start_date"],
        end_date=filters["end_date"],
        group_by=filters["group_by"],
    )
    return success_response("System stats retrieved.", data=data)


# ── Revenue breakdown ─────────────────────────────────────────────────────────

@super_admin_bp.route("/revenue", methods=["GET"])
@jwt_required()
@role_required("super_admin")
def revenue():
    # Total paid revenue
    total = db.session.query(
        db.func.coalesce(db.func.sum(Payment.amount), 0)
    ).filter(Payment.status == "paid").scalar()

    # Revenue split by payment type
    by_type_rows = (
        db.session.query(
            Payment.payment_type,
            db.func.coalesce(db.func.sum(Payment.amount), 0),
            db.func.count(Payment.id),
        )
        .filter(Payment.status == "paid")
        .group_by(Payment.payment_type)
        .all()
    )
    by_type = [
        {"type": t, "total": float(amount), "transactions": count}
        for t, amount, count in by_type_rows
    ]

    # Revenue split by payment method
    by_method_rows = (
        db.session.query(
            Payment.method,
            db.func.coalesce(db.func.sum(Payment.amount), 0),
            db.func.count(Payment.id),
        )
        .filter(Payment.status == "paid")
        .group_by(Payment.method)
        .all()
    )
    by_method = [
        {"method": m, "total": float(amount), "transactions": count}
        for m, amount, count in by_method_rows
    ]

    return success_response(
        "Revenue data retrieved.",
        data={
            "total_revenue": float(total),
            "by_payment_type": by_type,
            "by_payment_method": by_method,
        },
    )
