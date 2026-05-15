from datetime import datetime
from ..extensions import db


class Appointment(db.Model):
    __tablename__ = "appointments"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    doctor_id = db.Column(
        db.Integer,
        db.ForeignKey("doctors.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    patient_id = db.Column(
        db.Integer,
        db.ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    receptionist_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    appointment_date = db.Column(db.Date, nullable=False, index=True)
    appointment_time = db.Column(db.Time, nullable=False)
    token_number = db.Column(db.Integer, nullable=False)
    consultation_type = db.Column(
        db.Enum("new", "followup", "emergency", name="consultation_types"),
        default="new",
        nullable=False,
    )
    status = db.Column(
        db.Enum(
            "waiting",
            "sent_to_assistant",
            "in_consultation",
            "completed",
            "cancelled",
            name="appointment_statuses",
        ),
        default="waiting",
        nullable=False,
    )
    fee = db.Column(db.Numeric(10, 2), default=0, nullable=False)
    payment_status = db.Column(
        db.Enum("unpaid", "paid", "partial", name="appt_payment_statuses"),
        default="unpaid",
        nullable=False,
    )
    notes = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        # Token must be unique per doctor per day
        db.UniqueConstraint(
            "clinic_id", "doctor_id", "appointment_date", "token_number",
            name="uq_token_per_doctor_per_day",
        ),
    )

    # Relationships
    clinic = db.relationship("Clinic", back_populates="appointments")
    doctor = db.relationship("Doctor", back_populates="appointments")
    patient = db.relationship("Patient", back_populates="appointments")
    receptionist = db.relationship("User", foreign_keys=[receptionist_id])
    prescription = db.relationship(
        "Prescription", back_populates="appointment", uselist=False
    )

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "doctor_id": self.doctor_id,
            "patient_id": self.patient_id,
            "receptionist_id": self.receptionist_id,
            "appointment_date": (
                self.appointment_date.isoformat() if self.appointment_date else None
            ),
            "appointment_time": (
                self.appointment_time.strftime("%H:%M") if self.appointment_time else None
            ),
            "token_number": self.token_number,
            "consultation_type": self.consultation_type,
            "status": self.status,
            "fee": float(self.fee) if self.fee is not None else 0,
            "payment_status": self.payment_status,
            "notes": self.notes,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Appointment {self.id} [{self.status}] {self.appointment_date}>"
