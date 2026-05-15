from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt_identity

from ..models.user import User
from ..services.auth_service import AuthService
from ..services.user_service import UserService
from ..utils.password_utils import verify_password
from ..utils.response_utils import success_response, error_response

auth_bp = Blueprint("auth", __name__)


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json(silent=True)
    if not data:
        return error_response("Request body must be JSON.", status_code=400)

    errors = {}
    email = (data.get("email") or "").strip()
    password = data.get("password") or ""

    if not email:
        errors["email"] = "Email is required."
    if not password:
        errors["password"] = "Password is required."
    if errors:
        return error_response("Validation failed.", errors=errors, status_code=422)

    result, err = AuthService.login(email, password)
    if err:
        return error_response(err, status_code=401)

    return success_response("Login successful.", data=result)


@auth_bp.route("/me", methods=["GET"])
@jwt_required()
def me():
    user = User.query.get(get_jwt_identity())
    if not user:
        return error_response("User not found.", status_code=404)
    if not user.is_active:
        return error_response("Account is inactive.", status_code=401)
    return success_response("Profile retrieved.", data={"user": user.to_dict()})


@auth_bp.route("/change-password", methods=["POST"])
@jwt_required()
def change_password():
    user = User.query.get(get_jwt_identity())
    if not user or not user.is_active:
        return error_response("User not found or inactive.", status_code=401)

    data = request.get_json(silent=True) or {}
    errors = {}
    old_password = data.get("old_password") or ""
    new_password = data.get("new_password") or ""

    if not old_password:
        errors["old_password"] = "Current password is required."
    if not new_password:
        errors["new_password"] = "New password is required."
    elif len(new_password) < 6:
        errors["new_password"] = "New password must be at least 6 characters."
    if errors:
        return error_response("Validation failed.", errors=errors, status_code=422)

    if not verify_password(old_password, user.password_hash):
        return error_response("Current password is incorrect.", status_code=401)

    if old_password == new_password:
        return error_response(
            "New password must be different from your current password.",
            status_code=400,
        )

    UserService.change_password(user, new_password)
    return success_response("Password changed successfully.")


@auth_bp.route("/refresh", methods=["POST"])
@jwt_required(refresh=True)
def refresh():
    result, err = AuthService.refresh_token(get_jwt_identity())
    if err:
        return error_response(err, status_code=401)
    return success_response("Token refreshed.", data=result)


@auth_bp.route("/logout", methods=["POST"])
@jwt_required()
def logout():
    # JWT is stateless — the client discards the token.
    # Phase 5+: add Redis-backed token blacklist for server-side revocation.
    return success_response("Logged out successfully.")
