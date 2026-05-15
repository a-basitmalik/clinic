from datetime import datetime

from ..extensions import db


class PatientReport(db.Model):
    __tablename__ = "patient_reports"

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
    uploaded_by = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    report_title = db.Column(db.String(200), nullable=False)
    report_type = db.Column(db.String(100), nullable=True)
    file_url = db.Column(db.String(500), nullable=True)
    notes = db.Column(db.Text, nullable=True)

    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    clinic = db.relationship("Clinic")
    patient = db.relationship("Patient")
    appointment = db.relationship("Appointment")
    doctor = db.relationship("Doctor")
    uploader = db.relationship("User", foreign_keys=[uploaded_by])

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "patient_id": self.patient_id,
            "appointment_id": self.appointment_id,
            "doctor_id": self.doctor_id,
            "uploaded_by": self.uploaded_by,
            "report_title": self.report_title,
            "report_type": self.report_type,
            "file_url": self.file_url,
            "notes": self.notes,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<PatientReport {self.id} patient={self.patient_id}>"
