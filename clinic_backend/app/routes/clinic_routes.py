from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt

from ..extensions import db
from ..models.clinic import Clinic
from ..services.clinic_service import ClinicService
from ..utils.response_utils import success_response, error_response, paginated_response
from ..utils.decorators import role_required, clinic_access_required
from ..utils.validators import validate_clinic_registration, parse_time

clinic_bp = Blueprint("clinics", __name__)


# ── Registration (public) ──────────────────────────────────────────────────────

@clinic_bp.route("/register", methods=["POST"])
def register_clinic():
    data = request.get_json(silent=True)
    if not data:
        return error_response("Request body must be JSON.", status_code=400)

    errors = validate_clinic_registration(data)
    if errors:
        return error_response("Validation failed.", errors=errors, status_code=422)

    try:
        result = ClinicService.register(data)
    except ValueError as exc:
        return error_response(str(exc), status_code=409)
    except Exception as exc:
        return error_response(
            "Registration failed due to a server error. Please try again.",
            errors={"detail": str(exc)},
            status_code=500,
        )

    return success_response(
        "Clinic registered successfully. Your application is under review and "
        "will be activated after Super Admin approval.",
        data=result,
        status_code=201,
    )


# ── List all clinics (super_admin only) ───────────────────────────────────────

@clinic_bp.route("", methods=["GET"])
@jwt_required()
@role_required("super_admin")
def list_clinics():
    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)
    status_filter = request.args.get("status")

    paginated = ClinicService.get_all(
        page=page, per_page=per_page, status_filter=status_filter
    )

    return paginated_response(
        "Clinics retrieved.",
        data=[c.to_dict() for c in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


# ── Single clinic ─────────────────────────────────────────────────────────────

@clinic_bp.route("/<int:clinic_id>", methods=["GET"])
@jwt_required()
@clinic_access_required
def get_clinic(clinic_id):
    clinic = Clinic.query.get(clinic_id)
    if not clinic:
        return error_response("Clinic not found.", status_code=404)
    return success_response("Clinic retrieved.", data={"clinic": clinic.to_dict()})


# ── Update clinic details ─────────────────────────────────────────────────────

@clinic_bp.route("/<int:clinic_id>", methods=["PUT"])
@jwt_required()
@clinic_access_required
def update_clinic(clinic_id):
    clinic = Clinic.query.get(clinic_id)
    if not clinic:
        return error_response("Clinic not found.", status_code=404)

    # Within same clinic, only clinic_admin may update; super_admin always allowed
    role = get_jwt().get("role")
    if role not in ("super_admin", "clinic_admin"):
        return error_response(
            "Only clinic_admin or super_admin can update clinic details.",
            status_code=403,
        )

    data = request.get_json(silent=True) or {}
    if not data:
        return error_response("Request body must be JSON.", status_code=400)

    plain_fields = [
        "clinic_name", "owner_name", "phone", "address",
        "city", "logo", "working_days",
    ]
    for field in plain_fields:
        if field in data:
            setattr(clinic, field, data[field])

    for tf in ("opening_time", "closing_time"):
        if tf in data:
            try:
                setattr(clinic, tf, parse_time(data[tf]))
            except ValueError as exc:
                return error_response(str(exc), status_code=422)

    db.session.commit()
    return success_response("Clinic updated successfully.", data={"clinic": clinic.to_dict()})


# ── Approve clinic (super_admin only) ─────────────────────────────────────────

@clinic_bp.route("/<int:clinic_id>/approve", methods=["PUT"])
@jwt_required()
@role_required("super_admin")
def approve_clinic(clinic_id):
    clinic, err = ClinicService.approve(clinic_id, approved_by_user_id=get_jwt_identity())
    if err:
        return error_response(err, status_code=400)
    return success_response(
        "Clinic approved. All clinic users can now log in.",
        data={"clinic": clinic.to_dict()},
    )


# ── Suspend clinic (super_admin only) ─────────────────────────────────────────

@clinic_bp.route("/<int:clinic_id>/suspend", methods=["PUT"])
@jwt_required()
@role_required("super_admin")
def suspend_clinic(clinic_id):
    clinic, err = ClinicService.suspend(clinic_id)
    if err:
        return error_response(err, status_code=400)
    return success_response(
        "Clinic suspended. Users of this clinic can no longer log in.",
        data={"clinic": clinic.to_dict()},
    )


# ── Unsuspend clinic (super_admin only) ───────────────────────────────────────

@clinic_bp.route("/<int:clinic_id>/unsuspend", methods=["PUT"])
@jwt_required()
@role_required("super_admin")
def unsuspend_clinic(clinic_id):
    clinic, err = ClinicService.unsuspend(clinic_id)
    if err:
        return error_response(err, status_code=400)
    return success_response(
        "Clinic reinstated. Users can log in again.",
        data={"clinic": clinic.to_dict()},
    )
