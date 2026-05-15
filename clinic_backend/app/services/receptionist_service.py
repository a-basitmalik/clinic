from __future__ import annotations

from datetime import date

from ..extensions import db
from ..models.user import User
from ..services.user_service import UserService
from ..utils.validators import validate_email


class ReceptionistService:

    @staticmethod
    def create(clinic_id: int, data: dict) -> dict:
        name = (data.get("name") or "").strip()
        email = (data.get("email") or "").lower().strip()
        phone = (data.get("phone") or "").strip()

        if not name:
            raise ValueError("Receptionist name is required.")
        if not email:
            raise ValueError("Receptionist email is required.")
        if not validate_email(email):
            raise ValueError("Invalid email address.")

        user, temp_pwd = UserService.create_user(
            name=name,
            email=email,
            phone=phone,
            role="receptionist",
            clinic_id=clinic_id,
        )
        db.session.commit()

        return {
            "user": user.to_dict(),
            "temp_password": temp_pwd,
            "note": "Temporary password is shown only once.",
        }

    @staticmethod
    def list(clinic_id: int, include_inactive: bool = True):
        q = User.query.filter_by(clinic_id=clinic_id, role="receptionist")
        if not include_inactive:
            q = q.filter(User.status == "active")
        return q.order_by(User.created_at.desc()).all()

    @staticmethod
    def get(clinic_id: int, user_id: int) -> User | None:
        return User.query.filter_by(clinic_id=clinic_id, role="receptionist", id=user_id).first()

    @staticmethod
    def update(clinic_id: int, user_id: int, data: dict) -> User:
        user = ReceptionistService.get(clinic_id, user_id)
        if not user:
            raise ValueError("Receptionist not found.")

        if "email" in data:
            new_email = (data.get("email") or "").lower().strip()
            if not validate_email(new_email):
                raise ValueError("Invalid email address.")

        UserService.update_user(
            user,
            name=data.get("name") if "name" in data else None,
            email=data.get("email") if "email" in data else None,
            phone=data.get("phone") if "phone" in data else None,
            status=data.get("status") if "status" in data else None,
        )
        db.session.commit()
        return user

    @staticmethod
    def soft_delete(clinic_id: int, user_id: int) -> User:
        user = ReceptionistService.get(clinic_id, user_id)
        if not user:
            raise ValueError("Receptionist not found.")
        UserService.deactivate_user(user)
        db.session.commit()
        return user

    @staticmethod
    def reports(
        clinic_id: int,
        user_id: int | None,
        *,
        start_date: date | None = None,
        end_date: date | None = None,
        group_by: str = "day",
    ) -> dict:
        from ..services.report_service import ReportService

        filters = ReportService.normalize_filters(start_date=start_date, end_date=end_date, group_by=group_by)
        return ReportService.receptionist_overview(
            clinic_id,
            user_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
        )
