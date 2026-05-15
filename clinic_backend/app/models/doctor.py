from datetime import datetime
from ..extensions import db


class Doctor(db.Model):
    __tablename__ = "doctors"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )
    department_id = db.Column(
        db.Integer,
        db.ForeignKey("departments.id", ondelete="SET NULL"),
        nullable=True,
    )
    name = db.Column(db.String(200), nullable=False)
    email = db.Column(db.String(120), nullable=False)
    phone = db.Column(db.String(20), nullable=True)
    specialization = db.Column(db.String(200), nullable=True)
    qualification = db.Column(db.String(300), nullable=True)
    experience = db.Column(db.Integer, nullable=True)  # years
    license_number = db.Column(db.String(100), nullable=True)
    consultation_fee = db.Column(db.Numeric(10, 2), default=0, nullable=False)
    available_days = db.Column(db.JSON, nullable=True)  # ["Monday","Tuesday",...]
    available_start_time = db.Column(db.Time, nullable=True)
    available_end_time = db.Column(db.Time, nullable=True)
    status = db.Column(
        db.Enum("active", "inactive", name="doctor_statuses"),
        default="active",
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    clinic = db.relationship(
        "Clinic", back_populates="doctors", foreign_keys=[clinic_id]
    )
    department = db.relationship("Department", back_populates="doctors")
    user = db.relationship(
        "User",
        foreign_keys=[user_id],
        primaryjoin="Doctor.user_id == User.id",
        uselist=False,
    )
    assistants = db.relationship("Assistant", back_populates="doctor", lazy="dynamic")
    appointments = db.relationship("Appointment", back_populates="doctor", lazy="dynamic")
    prescriptions = db.relationship("Prescription", back_populates="doctor", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "user_id": self.user_id,
            "department_id": self.department_id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "specialization": self.specialization,
            "qualification": self.qualification,
            "experience": self.experience,
            "license_number": self.license_number,
            "consultation_fee": float(self.consultation_fee) if self.consultation_fee is not None else 0,
            "available_days": self.available_days,
            "available_start_time": (
                self.available_start_time.strftime("%H:%M")
                if self.available_start_time else None
            ),
            "available_end_time": (
                self.available_end_time.strftime("%H:%M")
                if self.available_end_time else None
            ),
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Doctor {self.name} (clinic={self.clinic_id})>"
