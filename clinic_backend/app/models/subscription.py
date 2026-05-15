from datetime import datetime
from ..extensions import db


class SubscriptionPlan(db.Model):
    __tablename__ = "subscription_plans"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False, unique=True)
    price = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    duration_days = db.Column(db.Integer, nullable=False, default=30)
    max_doctors = db.Column(db.Integer, nullable=False, default=1)
    has_pharmacy = db.Column(db.Boolean, default=False, nullable=False)
    has_reports = db.Column(db.Boolean, default=True, nullable=False)
    status = db.Column(
        db.Enum("active", "inactive", name="plan_statuses"),
        default="active",
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    subscriptions = db.relationship("ClinicSubscription", back_populates="plan", lazy="dynamic")
    clinics = db.relationship(
        "Clinic",
        back_populates="subscription_plan",
        foreign_keys="Clinic.subscription_plan_id",
    )

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "price": float(self.price) if self.price is not None else 0,
            "duration_days": self.duration_days,
            "max_doctors": self.max_doctors,
            "has_pharmacy": self.has_pharmacy,
            "has_reports": self.has_reports,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<SubscriptionPlan {self.name}>"


class ClinicSubscription(db.Model):
    __tablename__ = "clinic_subscriptions"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    plan_id = db.Column(
        db.Integer,
        db.ForeignKey("subscription_plans.id", ondelete="RESTRICT"),
        nullable=False,
    )
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)
    status = db.Column(
        db.Enum("active", "expired", "cancelled", name="subscription_statuses"),
        default="active",
        nullable=False,
    )
    amount_paid = db.Column(db.Numeric(10, 2), nullable=False, default=0)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    clinic = db.relationship("Clinic", back_populates="subscriptions")
    plan = db.relationship("SubscriptionPlan", back_populates="subscriptions")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "plan_id": self.plan_id,
            "plan_name": self.plan.name if self.plan else None,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "status": self.status,
            "amount_paid": float(self.amount_paid) if self.amount_paid is not None else 0,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<ClinicSubscription clinic={self.clinic_id} plan={self.plan_id}>"
