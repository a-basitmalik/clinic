from datetime import datetime
from ..extensions import db

USER_ROLES = (
    "super_admin",
    "clinic_admin",
    "doctor",
    "assistant",
    "receptionist",
    "pharmacy",
    "patient",
)

USER_STATUSES = ("active", "inactive", "pending")


class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    phone = db.Column(db.String(20), nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.Enum(*USER_ROLES, name="user_roles"), nullable=False)

    # Null only for super_admin; required for all clinic-scoped roles
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    # Populated when role == 'doctor'; deferred FK to break circular dependency
    doctor_id = db.Column(
        db.Integer,
        db.ForeignKey(
            "doctors.id",
            ondelete="SET NULL",
            use_alter=True,
            name="fk_users_doctor_id",
        ),
        nullable=True,
        index=True,
    )
    status = db.Column(
        db.Enum(*USER_STATUSES, name="user_statuses"),
        default="active",
        nullable=False,
    )
    must_change_password = db.Column(db.Boolean, default=False, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(
        db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
    last_login = db.Column(db.DateTime, nullable=True)

    # Relationships
    clinic = db.relationship("Clinic", back_populates="users", foreign_keys=[clinic_id])
    doctor_profile = db.relationship(
        "Doctor",
        foreign_keys=[doctor_id],
        primaryjoin="User.doctor_id == Doctor.id",
        uselist=False,
    )

    @property
    def is_active(self) -> bool:
        return self.status == "active"

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "role": self.role,
            "clinic_id": self.clinic_id,
            "doctor_id": self.doctor_id,
            "status": self.status,
            "must_change_password": self.must_change_password,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
        }

    def __repr__(self):
        return f"<User {self.email} ({self.role})>"
