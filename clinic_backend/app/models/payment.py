from datetime import datetime
from ..extensions import db


class Payment(db.Model):
    __tablename__ = "payments"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    patient_id = db.Column(
        db.Integer,
        db.ForeignKey("patients.id", ondelete="SET NULL"),
        nullable=True,
    )
    appointment_id = db.Column(
        db.Integer,
        db.ForeignKey("appointments.id", ondelete="SET NULL"),
        nullable=True,
    )
    payment_type = db.Column(
        db.Enum("consultation", "pharmacy", "lab", "other", name="payment_types"),
        nullable=False,
    )
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    method = db.Column(
        db.Enum("cash", "card", "easypaisa", "jazzcash", "bank", name="payment_methods"),
        default="cash",
        nullable=False,
    )
    status = db.Column(
        db.Enum("paid", "pending", "refunded", name="payment_statuses"),
        default="paid",
        nullable=False,
    )
    received_by = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    clinic = db.relationship("Clinic", back_populates="payments")
    patient = db.relationship("Patient")
    appointment = db.relationship("Appointment")
    receiver = db.relationship("User", foreign_keys=[received_by])

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "patient_id": self.patient_id,
            "appointment_id": self.appointment_id,
            "payment_type": self.payment_type,
            "amount": float(self.amount),
            "method": self.method,
            "status": self.status,
            "received_by": self.received_by,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<Payment {self.id} {self.payment_type} {self.amount}>"
