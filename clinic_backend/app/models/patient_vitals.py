from datetime import datetime

from ..extensions import db


class PatientVitals(db.Model):
    __tablename__ = "patient_vitals"

    id = db.Column(db.Integer, primary_key=True)

    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    patient_id = db.Column(
        db.Integer,
        db.ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    appointment_id = db.Column(
        db.Integer,
        db.ForeignKey("appointments.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    doctor_id = db.Column(
        db.Integer,
        db.ForeignKey("doctors.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    assistant_id = db.Column(
        db.Integer,
        db.ForeignKey("assistants.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    temperature = db.Column(db.Numeric(5, 2), nullable=True)  # Celsius
    blood_pressure = db.Column(db.String(20), nullable=True)  # e.g. 120/80
    pulse = db.Column(db.Integer, nullable=True)
    weight = db.Column(db.Numeric(6, 2), nullable=True)  # kg
    height = db.Column(db.Numeric(6, 2), nullable=True)  # cm
    oxygen_level = db.Column(db.Integer, nullable=True)  # %
    notes = db.Column(db.Text, nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    clinic = db.relationship("Clinic")
    patient = db.relationship("Patient")
    appointment = db.relationship("Appointment")
    doctor = db.relationship("Doctor")
    assistant = db.relationship("Assistant")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "patient_id": self.patient_id,
            "appointment_id": self.appointment_id,
            "doctor_id": self.doctor_id,
            "assistant_id": self.assistant_id,
            "temperature": float(self.temperature) if self.temperature is not None else None,
            "blood_pressure": self.blood_pressure,
            "pulse": self.pulse,
            "weight": float(self.weight) if self.weight is not None else None,
            "height": float(self.height) if self.height is not None else None,
            "oxygen_level": self.oxygen_level,
            "notes": self.notes,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<PatientVitals {self.id} patient={self.patient_id}>"
