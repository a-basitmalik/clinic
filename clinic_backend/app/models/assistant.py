from datetime import datetime
from ..extensions import db


class Assistant(db.Model):
    __tablename__ = "assistants"

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
    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )
    name = db.Column(db.String(200), nullable=False)
    duties = db.Column(db.JSON, nullable=True)

    # Granular permission flags
    can_view_appointments = db.Column(db.Boolean, default=True, nullable=False)
    can_add_vitals = db.Column(db.Boolean, default=True, nullable=False)
    can_upload_reports = db.Column(db.Boolean, default=False, nullable=False)
    can_prepare_prescription_draft = db.Column(db.Boolean, default=False, nullable=False)
    can_print_prescription = db.Column(db.Boolean, default=False, nullable=False)
    can_view_patient_history = db.Column(db.Boolean, default=True, nullable=False)

    status = db.Column(
        db.Enum("active", "inactive", name="assistant_statuses"),
        default="active",
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    clinic = db.relationship("Clinic")
    doctor = db.relationship("Doctor", back_populates="assistants", foreign_keys=[doctor_id])
    user = db.relationship("User", foreign_keys=[user_id])

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "doctor_id": self.doctor_id,
            "user_id": self.user_id,
            "name": self.name,
            "duties": self.duties,
            "can_view_appointments": self.can_view_appointments,
            "can_add_vitals": self.can_add_vitals,
            "can_upload_reports": self.can_upload_reports,
            "can_prepare_prescription_draft": self.can_prepare_prescription_draft,
            "can_print_prescription": self.can_print_prescription,
            "can_view_patient_history": self.can_view_patient_history,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Assistant {self.name} (doctor={self.doctor_id})>"
