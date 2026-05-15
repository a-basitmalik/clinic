from datetime import datetime
from ..extensions import db


class Department(db.Model):
    __tablename__ = "departments"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(
        db.Enum("active", "inactive", name="department_statuses"),
        default="active",
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    clinic = db.relationship("Clinic", back_populates="departments")
    doctors = db.relationship("Doctor", back_populates="department", lazy="dynamic")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "name": self.name,
            "description": self.description,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<Department {self.name} (clinic={self.clinic_id})>"
