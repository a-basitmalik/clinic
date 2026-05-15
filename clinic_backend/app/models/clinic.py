from datetime import datetime
from ..extensions import db


class Clinic(db.Model):
    __tablename__ = "clinics"

    id = db.Column(db.Integer, primary_key=True)
    clinic_name = db.Column(db.String(200), nullable=False)
    owner_name = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    phone = db.Column(db.String(20), nullable=False)
    address = db.Column(db.Text, nullable=True)
    city = db.Column(db.String(100), nullable=True)
    logo = db.Column(db.String(500), nullable=True)
    clinic_type = db.Column(
        db.Enum("single_doctor", "multi_doctor", name="clinic_types"),
        nullable=False,
    )
    number_of_doctors = db.Column(db.Integer, default=1, nullable=False)
    has_pharmacy = db.Column(db.Boolean, default=False, nullable=False)
    has_receptionist = db.Column(db.Boolean, default=False, nullable=False)
    opening_time = db.Column(db.Time, nullable=True)
    closing_time = db.Column(db.Time, nullable=True)
    working_days = db.Column(db.JSON, nullable=True)  # e.g. ["Monday","Tuesday",...]
    status = db.Column(
        db.Enum("pending", "approved", "suspended", name="clinic_statuses"),
        default="pending",
        nullable=False,
    )
    subscription_plan_id = db.Column(
        db.Integer,
        db.ForeignKey("subscription_plans.id", ondelete="SET NULL"),
        nullable=True,
    )
    # use_alter defers this FK so MySQL can create clinics before users
    approved_by = db.Column(
        db.Integer,
        db.ForeignKey(
            "users.id",
            ondelete="SET NULL",
            use_alter=True,
            name="fk_clinics_approved_by",
        ),
        nullable=True,
    )
    approved_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    users = db.relationship(
        "User", back_populates="clinic", foreign_keys="User.clinic_id", lazy="dynamic"
    )
    approver = db.relationship("User", foreign_keys=[approved_by])
    subscription_plan = db.relationship(
        "SubscriptionPlan",
        back_populates="clinics",
        foreign_keys=[subscription_plan_id],
    )
    subscriptions = db.relationship(
        "ClinicSubscription", back_populates="clinic", lazy="dynamic"
    )
    departments = db.relationship(
        "Department", back_populates="clinic", lazy="dynamic"
    )
    doctors = db.relationship(
        "Doctor", back_populates="clinic", foreign_keys="Doctor.clinic_id", lazy="dynamic"
    )
    patients = db.relationship("Patient", back_populates="clinic", lazy="dynamic")
    appointments = db.relationship("Appointment", back_populates="clinic", lazy="dynamic")
    pharmacy_items = db.relationship(
        "PharmacyItem", back_populates="clinic", lazy="dynamic"
    )
    payments = db.relationship("Payment", back_populates="clinic", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_name": self.clinic_name,
            "owner_name": self.owner_name,
            "email": self.email,
            "phone": self.phone,
            "address": self.address,
            "city": self.city,
            "logo": self.logo,
            "clinic_type": self.clinic_type,
            "number_of_doctors": self.number_of_doctors,
            "has_pharmacy": self.has_pharmacy,
            "has_receptionist": self.has_receptionist,
            "opening_time": self.opening_time.strftime("%H:%M") if self.opening_time else None,
            "closing_time": self.closing_time.strftime("%H:%M") if self.closing_time else None,
            "working_days": self.working_days,
            "status": self.status,
            "subscription_plan_id": self.subscription_plan_id,
            "approved_by": self.approved_by,
            "approved_at": self.approved_at.isoformat() if self.approved_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Clinic {self.clinic_name} ({self.status})>"
