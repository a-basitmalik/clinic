from __future__ import annotations

from datetime import date, timedelta

from ..extensions import db
from ..models.clinic import Clinic
from ..models.subscription import ClinicSubscription, SubscriptionPlan
from ..utils.validators import parse_date, parse_float, parse_int


class SubscriptionService:
    @staticmethod
    def list_plans(include_inactive: bool = True):
        query = SubscriptionPlan.query
        if not include_inactive:
            query = query.filter_by(status="active")
        return query.order_by(SubscriptionPlan.price.asc(), SubscriptionPlan.id.asc()).all()

    @staticmethod
    def create_plan(data: dict) -> SubscriptionPlan:
        name = (data.get("name") or "").strip()
        if not name:
            raise ValueError("name is required.")
        if SubscriptionPlan.query.filter(db.func.lower(SubscriptionPlan.name) == name.lower()).first():
            raise ValueError("A subscription plan with this name already exists.")
        plan = SubscriptionPlan(name=name)
        SubscriptionService._apply_plan_fields(plan, data, creating=True)
        db.session.add(plan)
        db.session.commit()
        return plan

    @staticmethod
    def update_plan(plan_id: int, data: dict) -> SubscriptionPlan:
        plan = SubscriptionPlan.query.get(plan_id)
        if not plan:
            raise ValueError("Subscription plan not found.")
        if "name" in data:
            name = (data.get("name") or "").strip()
            if not name:
                raise ValueError("name cannot be blank.")
            duplicate = SubscriptionPlan.query.filter(
                db.func.lower(SubscriptionPlan.name) == name.lower(),
                SubscriptionPlan.id != plan.id,
            ).first()
            if duplicate:
                raise ValueError("A subscription plan with this name already exists.")
            plan.name = name
        SubscriptionService._apply_plan_fields(plan, data)
        db.session.commit()
        return plan

    @staticmethod
    def _apply_plan_fields(plan: SubscriptionPlan, data: dict, creating: bool = False) -> None:
        if creating or "price" in data:
            plan.price = parse_float(data.get("price", 0), "price", minimum=0) or 0
        if creating or "duration_days" in data:
            plan.duration_days = parse_int(data.get("duration_days", 30), "duration_days", minimum=1) or 30
        if creating or "max_doctors" in data:
            plan.max_doctors = parse_int(data.get("max_doctors", 1), "max_doctors", minimum=1) or 1
        for field in ("has_pharmacy", "has_reports"):
            if creating or field in data:
                setattr(plan, field, bool(data.get(field, field == "has_reports")))
        if creating or "status" in data:
            status = data.get("status", "active")
            if status not in ("active", "inactive"):
                raise ValueError("status must be active or inactive.")
            plan.status = status

    @staticmethod
    def assign(clinic_id: int, data: dict) -> ClinicSubscription:
        clinic = Clinic.query.get(clinic_id)
        if not clinic:
            raise ValueError("Clinic not found.")
        plan_id = parse_int(data.get("plan_id"), "plan_id", minimum=1)
        if not plan_id:
            raise ValueError("plan_id is required.")
        plan = SubscriptionPlan.query.get(plan_id)
        if not plan or plan.status != "active":
            raise ValueError("Active subscription plan not found.")

        start = parse_date(data.get("start_date")) or date.today()
        end = parse_date(data.get("end_date")) or (start + timedelta(days=plan.duration_days))
        if end <= start:
            raise ValueError("end_date must be after start_date.")
        amount = parse_float(data.get("amount_paid", plan.price), "amount_paid", minimum=0) or 0

        ClinicSubscription.query.filter_by(clinic_id=clinic.id, status="active").update({"status": "cancelled"})
        subscription = ClinicSubscription(
            clinic_id=clinic.id,
            plan_id=plan.id,
            start_date=start,
            end_date=end,
            status="active",
            amount_paid=amount,
        )
        clinic.subscription_plan_id = plan.id
        db.session.add(subscription)
        db.session.commit()
        return subscription

    @staticmethod
    def list_subscriptions(clinic_id: int | None = None):
        query = ClinicSubscription.query
        if clinic_id:
            query = query.filter_by(clinic_id=clinic_id)
        return query.order_by(ClinicSubscription.created_at.desc()).all()
