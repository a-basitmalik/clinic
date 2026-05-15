from functools import wraps
from flask import g
from flask_jwt_extended import verify_jwt_in_request, get_jwt, get_jwt_identity
from .response_utils import error_response
from ..models.user import User


# ── Core role guard ────────────────────────────────────────────────────────────

def role_required(*roles):
    """Restrict an endpoint to one or more named roles.

    Usage:
        @role_required("super_admin")
        @role_required("clinic_admin", "doctor")
    """
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            user_role = get_jwt().get("role")
            if user_role not in roles:
                return error_response(
                    "Access denied. You do not have permission to perform this action.",
                    errors={"required_roles": list(roles), "your_role": user_role},
                    status_code=403,
                )
            return fn(*args, **kwargs)
        return wrapper
    return decorator


def roles_required(roles: list):
    """List-based alias for role_required so both calling styles work.

    Usage:
        @roles_required(["clinic_admin", "doctor"])
    """
    return role_required(*roles)


# ── Active-user guard ──────────────────────────────────────────────────────────

def active_user_required(fn):
    """Ensure the JWT identity maps to a currently active DB user."""
    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        user = User.query.get(get_jwt_identity())
        if not user or not user.is_active:
            return error_response("Account is inactive or does not exist.", status_code=401)
        return fn(*args, **kwargs)
    return wrapper


# ── Clinic-scope guard ─────────────────────────────────────────────────────────

def clinic_access_required(fn):
    """Allow super_admin unrestricted access; restrict everyone else to their
    own clinic.

    The route must expose the target clinic as a ``clinic_id`` URL parameter.
    """
    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        claims = get_jwt()
        user_role = claims.get("role")

        # super_admin passes unconditionally
        if user_role == "super_admin":
            return fn(*args, **kwargs)

        url_clinic_id = kwargs.get("clinic_id")
        jwt_clinic_id = claims.get("clinic_id")

        if url_clinic_id is None or jwt_clinic_id is None:
            return error_response("Clinic context is missing.", status_code=400)

        if int(jwt_clinic_id) != int(url_clinic_id):
            return error_response(
                "Access denied. You do not have access to this clinic.",
                status_code=403,
            )
        return fn(*args, **kwargs)
    return wrapper


def clinic_approved_required(fn):
    """Ensure the current clinic is approved (or allow super_admin).

    Note: Auth already blocks login for pending/suspended clinics, but this
    guard protects against long-lived tokens if clinic status changes.
    """

    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        claims = get_jwt()
        role = claims.get("role")

        if role == "super_admin":
            return fn(*args, **kwargs)

        clinic_id = claims.get("clinic_id")
        if not clinic_id:
            return error_response("Clinic context is missing.", status_code=400)

        # Local import avoids circular imports
        from ..models.clinic import Clinic

        clinic = Clinic.query.get(int(clinic_id))
        if not clinic:
            return error_response("Clinic not found.", status_code=404)
        if clinic.status != "approved":
            return error_response(
                "Your clinic is not approved or is suspended.",
                errors={"clinic_status": clinic.status},
                status_code=403,
            )
        return fn(*args, **kwargs)

    return wrapper


# ── Convenience wrappers ───────────────────────────────────────────────────────

def super_admin_required(fn):
    return role_required("super_admin")(fn)


def clinic_admin_required(fn):
    return role_required("super_admin", "clinic_admin")(fn)


def doctor_required(fn):
    return role_required("super_admin", "clinic_admin", "doctor")(fn)


def receptionist_required(fn):
    return role_required("super_admin", "clinic_admin", "receptionist")(fn)


def pharmacy_required(fn):
    return role_required("super_admin", "clinic_admin", "pharmacy")(fn)


# ── Assistant context & permissions ─────────────────────────────────────────

def assistant_context_required(fn):
    """Load the active Assistant record for the current user.

    Stores it in `flask.g.current_assistant`.
    """

    @wraps(fn)
    def wrapper(*args, **kwargs):
        verify_jwt_in_request()
        claims = get_jwt()
        if claims.get("role") != "assistant":
            return error_response("Access denied.", status_code=403)

        clinic_id = claims.get("clinic_id")
        doctor_id = claims.get("doctor_id")
        if not clinic_id or not doctor_id:
            return error_response("Assistant context is missing.", status_code=400)

        from ..models.assistant import Assistant

        assistant = Assistant.query.filter_by(
            clinic_id=int(clinic_id),
            doctor_id=int(doctor_id),
            user_id=get_jwt_identity(),
            status="active",
        ).first()
        if not assistant:
            return error_response("Assistant record not found or inactive.", status_code=403)

        g.current_assistant = assistant
        return fn(*args, **kwargs)

    return wrapper


def assistant_permission_required(permission_field: str):
    """Require a specific Assistant permission flag (e.g. can_add_vitals)."""

    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            verify_jwt_in_request()
            assistant = getattr(g, "current_assistant", None)
            if assistant is None:
                return error_response("Assistant context not loaded.", status_code=500)
            if not hasattr(assistant, permission_field):
                return error_response("Invalid assistant permission.", status_code=500)
            if not bool(getattr(assistant, permission_field)):
                return error_response("Access denied. Assistant permission required.", errors={"permission": permission_field}, status_code=403)
            return fn(*args, **kwargs)

        return wrapper

    return decorator
