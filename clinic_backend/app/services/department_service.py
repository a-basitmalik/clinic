from __future__ import annotations

from sqlalchemy import func

from ..extensions import db
from ..models.department import Department


class DepartmentService:

    @staticmethod
    def create(clinic_id: int, data: dict) -> Department:
        name = (data.get("name") or "").strip()
        if not name:
            raise ValueError("Department name is required.")

        exists = Department.query.filter(
            Department.clinic_id == clinic_id,
            func.lower(Department.name) == name.lower(),
        ).first()
        if exists:
            raise ValueError("A department with this name already exists in this clinic.")

        dept = Department(
            clinic_id=clinic_id,
            name=name,
            description=(data.get("description") or "").strip() or None,
            status=(data.get("status") or "active"),
        )
        if dept.status not in ("active", "inactive"):
            raise ValueError("Invalid department status.")

        db.session.add(dept)
        db.session.commit()
        return dept

    @staticmethod
    def list(clinic_id: int, include_inactive: bool = True):
        q = Department.query.filter_by(clinic_id=clinic_id)
        if not include_inactive:
            q = q.filter(Department.status == "active")
        return q.order_by(Department.name.asc()).all()

    @staticmethod
    def get(clinic_id: int, department_id: int) -> Department | None:
        return Department.query.filter_by(clinic_id=clinic_id, id=department_id).first()

    @staticmethod
    def update(clinic_id: int, department_id: int, data: dict) -> Department:
        dept = DepartmentService.get(clinic_id, department_id)
        if not dept:
            raise ValueError("Department not found.")

        if "name" in data:
            new_name = (data.get("name") or "").strip()
            if not new_name:
                raise ValueError("Department name is required.")
            if new_name.lower() != dept.name.lower():
                exists = Department.query.filter(
                    Department.clinic_id == clinic_id,
                    func.lower(Department.name) == new_name.lower(),
                    Department.id != dept.id,
                ).first()
                if exists:
                    raise ValueError("A department with this name already exists in this clinic.")
            dept.name = new_name

        if "description" in data:
            dept.description = (data.get("description") or "").strip() or None

        if "status" in data:
            status = data.get("status")
            if status not in ("active", "inactive"):
                raise ValueError("Invalid department status.")
            dept.status = status

        db.session.commit()
        return dept

    @staticmethod
    def soft_delete(clinic_id: int, department_id: int) -> Department:
        dept = DepartmentService.get(clinic_id, department_id)
        if not dept:
            raise ValueError("Department not found.")
        dept.status = "inactive"
        db.session.commit()
        return dept
