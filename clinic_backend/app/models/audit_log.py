from datetime import datetime
from ..extensions import db


class AuditLog(db.Model):
    __tablename__ = "audit_logs"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    user_id = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    action = db.Column(db.String(100), nullable=False)   # e.g. "LOGIN", "CREATE_PATIENT"
    module = db.Column(db.String(100), nullable=True)    # e.g. "auth", "appointments"
    details = db.Column(db.JSON, nullable=True)
    ip_address = db.Column(db.String(50), nullable=True)
    created_at = db.Column(
        db.DateTime, default=datetime.utcnow, nullable=False, index=True
    )

    clinic = db.relationship("Clinic")
    user = db.relationship("User")

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "user_id": self.user_id,
            "action": self.action,
            "module": self.module,
            "details": self.details,
            "ip_address": self.ip_address,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<AuditLog {self.action} user={self.user_id}>"
