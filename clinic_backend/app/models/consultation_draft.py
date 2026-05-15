from datetime import datetime

from ..extensions import db


class ConsultationDraft(db.Model):
    __tablename__ = "consultation_drafts"

    id = db.Column(db.Integer, primary_key=True)

    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    appointment_id = db.Column(
        db.Integer,
        db.ForeignKey("appointments.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    patient_id = db.Column(
        db.Integer,
        db.ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
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

    symptoms_draft = db.Column(db.Text, nullable=True)
    vitals_summary = db.Column(db.Text, nullable=True)
    notes = db.Column(db.Text, nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    clinic = db.relationship("Clinic")
    appointment = db.relationship("Appointment")
    patient = db.relationship("Patient")
    doctor = db.relationship("Doctor")
    assistant = db.relationship("Assistant")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "appointment_id": self.appointment_id,
            "patient_id": self.patient_id,
            "doctor_id": self.doctor_id,
            "assistant_id": self.assistant_id,
            "symptoms_draft": self.symptoms_draft,
            "vitals_summary": self.vitals_summary,
            "notes": self.notes,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<ConsultationDraft appt={self.appointment_id}>"
