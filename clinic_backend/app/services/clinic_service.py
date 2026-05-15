from datetime import datetime

from sqlalchemy.exc import IntegrityError

from ..extensions import db
from ..models.clinic import Clinic
from ..models.department import Department
from ..models.doctor import Doctor
from .user_service import UserService
from ..utils.validators import parse_time


class ClinicService:

    # ── Registration ──────────────────────────────────────────────────────────

    @staticmethod
    def register(data: dict) -> dict:
        """
        Create a clinic (status=pending) together with all user accounts.
        The entire operation runs in one transaction — any failure rolls back
        everything.

        Returns a dict with:
          - clinic        : clinic.to_dict()
          - created_accounts : {clinic_admin, doctors[], receptionist, pharmacy}
            each entry includes a one-time plain temp_password
        """
        try:
            # 1. Clinic record
            clinic = Clinic(
                clinic_name=data["clinic_name"].strip(),
                owner_name=data["owner_name"].strip(),
                email=data["email"].lower().strip(),
                phone=data["phone"].strip(),
                address=(data.get("address") or "").strip(),
                city=(data.get("city") or "").strip(),
                clinic_type=data["clinic_type"],
                number_of_doctors=int(data["number_of_doctors"]),
                has_pharmacy=bool(data.get("has_pharmacy", False)),
                has_receptionist=bool(data.get("has_receptionist", False)),
                opening_time=parse_time(data.get("opening_time")),
                closing_time=parse_time(data.get("closing_time")),
                working_days=data.get("working_days"),
                status="pending",
            )
            db.session.add(clinic)
            db.session.flush()  # get clinic.id

            created = {"clinic_admin": None, "doctors": [], "receptionist": None, "pharmacy": None}

            # 2. Clinic admin (uses clinic's own email + owner_name)
            admin_user, admin_pwd = UserService.create_user(
                name=clinic.owner_name,
                email=clinic.email,
                phone=clinic.phone,
                role="clinic_admin",
                clinic_id=clinic.id,
            )
            created["clinic_admin"] = _account_dict(admin_user, admin_pwd)

            # 3. Doctors
            for doc_data in data.get("doctors", []):
                dept_name = (doc_data.get("department") or "General").strip()

                # Get or create department for this clinic
                dept = Department.query.filter_by(
                    clinic_id=clinic.id, name=dept_name
                ).first()
                if not dept:
                    dept = Department(clinic_id=clinic.id, name=dept_name, status="active")
                    db.session.add(dept)
                    db.session.flush()

                # Doctor login account
                doc_user, doc_pwd = UserService.create_user(
                    name=doc_data["name"].strip(),
                    email=doc_data["email"],
                    phone=doc_data.get("phone", ""),
                    role="doctor",
                    clinic_id=clinic.id,
                )

                # Doctor profile record
                doctor = Doctor(
                    clinic_id=clinic.id,
                    user_id=doc_user.id,
                    department_id=dept.id,
                    name=doc_data["name"].strip(),
                    email=doc_data["email"].lower().strip(),
                    phone=(doc_data.get("phone") or "").strip() or None,
                    specialization=(doc_data.get("specialization") or "").strip() or None,
                    qualification=(doc_data.get("qualification") or "").strip() or None,
                    experience=doc_data.get("experience"),
                    license_number=(doc_data.get("license_number") or "").strip() or None,
                    consultation_fee=doc_data.get("consultation_fee") or 0,
                    available_days=doc_data.get("available_days"),
                    available_start_time=parse_time(doc_data.get("available_start_time")),
                    available_end_time=parse_time(doc_data.get("available_end_time")),
                    status="active",
                )
                db.session.add(doctor)
                db.session.flush()  # get doctor.id

                # Resolve the circular FK: user ↔ doctor
                doc_user.doctor_id = doctor.id

                entry = _account_dict(doc_user, doc_pwd)
                entry["specialization"] = doctor.specialization
                entry["department"] = dept_name
                created["doctors"].append(entry)

            # 4. Receptionist
            if clinic.has_receptionist and data.get("receptionist"):
                r = data["receptionist"]
                r_user, r_pwd = UserService.create_user(
                    name=r["name"].strip(),
                    email=r["email"],
                    phone=r.get("phone", ""),
                    role="receptionist",
                    clinic_id=clinic.id,
                )
                created["receptionist"] = _account_dict(r_user, r_pwd)

            # 5. Pharmacy
            if clinic.has_pharmacy and data.get("pharmacy"):
                p = data["pharmacy"]
                p_user, p_pwd = UserService.create_user(
                    name=p["name"].strip(),
                    email=p["email"],
                    phone=p.get("phone", ""),
                    role="pharmacy",
                    clinic_id=clinic.id,
                )
                created["pharmacy"] = _account_dict(p_user, p_pwd)

            db.session.commit()

            return {
                "clinic": clinic.to_dict(),
                "created_accounts": created,
                "note": (
                    "All passwords are temporary. "
                    "Users will be prompted to change them on first login. "
                    "These passwords are shown only once."
                ),
            }

        except (ValueError, IntegrityError) as exc:
            db.session.rollback()
            msg = str(exc)
            if isinstance(exc, IntegrityError):
                msg = "A duplicate email was detected. Please check your registration data."
            raise ValueError(msg) from exc
        except Exception:
            db.session.rollback()
            raise

    # ── Listing ───────────────────────────────────────────────────────────────

    @staticmethod
    def get_all(page: int = 1, per_page: int = 20, status_filter: str = None):
        query = Clinic.query
        if status_filter:
            query = query.filter_by(status=status_filter)
        return query.order_by(Clinic.created_at.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

    # ── Approval / suspension ─────────────────────────────────────────────────

    @staticmethod
    def approve(clinic_id: int, approved_by_user_id: int):
        clinic = Clinic.query.get(clinic_id)
        if not clinic:
            return None, "Clinic not found."
        if clinic.status == "approved":
            return None, "Clinic is already approved."
        clinic.status = "approved"
        clinic.approved_by = approved_by_user_id
        clinic.approved_at = datetime.utcnow()
        db.session.commit()
        return clinic, None

    @staticmethod
    def suspend(clinic_id: int):
        clinic = Clinic.query.get(clinic_id)
        if not clinic:
            return None, "Clinic not found."
        if clinic.status == "suspended":
            return None, "Clinic is already suspended."
        clinic.status = "suspended"
        db.session.commit()
        return clinic, None

    @staticmethod
    def unsuspend(clinic_id: int):
        clinic = Clinic.query.get(clinic_id)
        if not clinic:
            return None, "Clinic not found."
        if clinic.status != "suspended":
            return None, "Clinic is not suspended."
        clinic.status = "approved"
        db.session.commit()
        return clinic, None


# ── Helpers ───────────────────────────────────────────────────────────────────

def _account_dict(user, plain_password: str) -> dict:
    return {
        "name": user.name,
        "email": user.email,
        "role": user.role,
        "temp_password": plain_password,
    }
