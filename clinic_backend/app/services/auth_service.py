from datetime import datetime
from flask_jwt_extended import create_access_token, create_refresh_token

from ..extensions import db
from ..models.user import User
from ..models.clinic import Clinic
from ..utils.password_utils import verify_password


class AuthService:

    @staticmethod
    def _build_claims(user: User) -> dict:
        return {
            "role": user.role,
            "clinic_id": user.clinic_id,
            "doctor_id": user.doctor_id,
            "full_name": user.name,
            "must_change_password": user.must_change_password,
        }

    @staticmethod
    def login(email: str, password: str):
        user = User.query.filter_by(email=email.lower().strip()).first()

        # Single identical error message prevents user enumeration
        if not user or not verify_password(password, user.password_hash):
            return None, "Invalid email or password."

        if user.status == "pending":
            return None, "Your account is pending approval. Contact your clinic admin."

        if user.status == "inactive":
            return None, "Your account has been deactivated. Contact support."

        # Non-super-admin users can only log in once their clinic is approved
        if user.role != "super_admin" and user.clinic_id:
            clinic = Clinic.query.get(user.clinic_id)
            if clinic and clinic.status == "pending":
                return None, "Your clinic is awaiting Super Admin approval. Please check back later."
            if clinic and clinic.status == "suspended":
                return None, "Your clinic has been suspended. Contact support."

        user.last_login = datetime.utcnow()
        db.session.commit()

        claims = AuthService._build_claims(user)
        return {
            "token": create_access_token(identity=user.id, additional_claims=claims),
            "refresh_token": create_refresh_token(identity=user.id),
            "user": user.to_dict(),
        }, None

    @staticmethod
    def refresh_token(user_id: int):
        user = User.query.get(user_id)
        if not user or not user.is_active:
            return None, "User not found or inactive."

        claims = AuthService._build_claims(user)
        return {
            "token": create_access_token(identity=user.id, additional_claims=claims),
        }, None
