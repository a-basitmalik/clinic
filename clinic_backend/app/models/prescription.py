from datetime import datetime
from ..extensions import db


class Prescription(db.Model):
    __tablename__ = "prescriptions"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    doctor_id = db.Column(
        db.Integer,
        db.ForeignKey("doctors.id", ondelete="SET NULL"),
        nullable=True,
    )
    patient_id = db.Column(
        db.Integer,
        db.ForeignKey("patients.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # One prescription per appointment
    appointment_id = db.Column(
        db.Integer,
        db.ForeignKey("appointments.id", ondelete="SET NULL"),
        nullable=True,
        unique=True,
    )
    symptoms = db.Column(db.Text, nullable=True)
    diagnosis = db.Column(db.Text, nullable=True)
    notes = db.Column(db.Text, nullable=True)
    follow_up_date = db.Column(db.Date, nullable=True)

    # Phase 7: pharmacy workflow status
    pharmacy_status = db.Column(
        db.Enum(
            "pending",
            "partial_dispensed",
            "dispensed",
            "cancelled",
            name="prescription_pharmacy_statuses",
        ),
        default="pending",
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    clinic = db.relationship("Clinic")
    doctor = db.relationship("Doctor", back_populates="prescriptions")
    patient = db.relationship("Patient", back_populates="prescriptions")
    appointment = db.relationship("Appointment", back_populates="prescription")
    medicines = db.relationship(
        "PrescriptionMedicine",
        back_populates="prescription",
        cascade="all, delete-orphan",
    )
    lab_tests = db.relationship(
        "PrescriptionLabTest",
        cascade="all, delete-orphan",
        lazy="select",
    )

    def to_dict(self, include_medicines=False, include_lab_tests=False):
        data = {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "doctor_id": self.doctor_id,
            "patient_id": self.patient_id,
            "appointment_id": self.appointment_id,
            "symptoms": self.symptoms,
            "diagnosis": self.diagnosis,
            "notes": self.notes,
            "follow_up_date": (
                self.follow_up_date.isoformat() if self.follow_up_date else None
            ),
            "pharmacy_status": self.pharmacy_status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
        if include_medicines:
            data["medicines"] = [m.to_dict() for m in self.medicines]
        if include_lab_tests:
            data["lab_tests"] = [t.to_dict() for t in self.lab_tests]
        return data

    def __repr__(self):
        return f"<Prescription {self.id} patient={self.patient_id}>"


class PrescriptionMedicine(db.Model):
    __tablename__ = "prescription_medicines"

    id = db.Column(db.Integer, primary_key=True)
    prescription_id = db.Column(
        db.Integer,
        db.ForeignKey("prescriptions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    # Nullable — doctor may prescribe a medicine not yet in pharmacy inventory
    medicine_id = db.Column(
        db.Integer,
        db.ForeignKey("pharmacy_items.id", ondelete="SET NULL"),
        nullable=True,
    )
    medicine_name = db.Column(db.String(200), nullable=False)
    dosage = db.Column(db.String(100), nullable=True)       # e.g. "500mg"
    frequency = db.Column(db.String(100), nullable=True)    # e.g. "3 times a day"
    duration = db.Column(db.String(100), nullable=True)     # e.g. "7 days"
    instructions = db.Column(db.Text, nullable=True)        # e.g. "take after meals"
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    prescription = db.relationship("Prescription", back_populates="medicines")
    pharmacy_item = db.relationship("PharmacyItem")

    def to_dict(self):
        return {
            "id": self.id,
            "prescription_id": self.prescription_id,
            "medicine_id": self.medicine_id,
            "medicine_name": self.medicine_name,
            "dosage": self.dosage,
            "frequency": self.frequency,
            "duration": self.duration,
            "instructions": self.instructions,
        }

    def __repr__(self):
        return f"<PrescriptionMedicine {self.medicine_name}>"
