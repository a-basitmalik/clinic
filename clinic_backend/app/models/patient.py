from datetime import datetime
from ..extensions import db


class Patient(db.Model):
    __tablename__ = "patients"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Linked when patient self-registers via portal
    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )
    patient_code = db.Column(db.String(50), nullable=False)  # e.g. P-0001
    name = db.Column(db.String(200), nullable=False)
    age = db.Column(db.Integer, nullable=True)
    gender = db.Column(
        db.Enum("male", "female", "other", name="patient_genders"),
        nullable=True,
    )
    phone = db.Column(db.String(20), nullable=False)
    cnic = db.Column(db.String(20), nullable=True)
    address = db.Column(db.Text, nullable=True)
    blood_group = db.Column(db.String(10), nullable=True)
    emergency_contact = db.Column(db.String(20), nullable=True)
    created_by = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint("clinic_id", "patient_code", name="uq_patient_code_per_clinic"),
    )

    # Relationships
    clinic = db.relationship("Clinic", back_populates="patients")
    user = db.relationship("User", foreign_keys=[user_id])
    creator = db.relationship("User", foreign_keys=[created_by])
    appointments = db.relationship("Appointment", back_populates="patient", lazy="dynamic")
    prescriptions = db.relationship("Prescription", back_populates="patient", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "user_id": self.user_id,
            "patient_code": self.patient_code,
            "name": self.name,
            "age": self.age,
            "gender": self.gender,
            "phone": self.phone,
            "cnic": self.cnic,
            "address": self.address,
            "blood_group": self.blood_group,
            "emergency_contact": self.emergency_contact,
            "created_by": self.created_by,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Patient {self.name} ({self.patient_code})>"
