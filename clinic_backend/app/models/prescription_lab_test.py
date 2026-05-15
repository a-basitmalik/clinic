from datetime import datetime

from ..extensions import db


class PrescriptionLabTest(db.Model):
    __tablename__ = "prescription_lab_tests"

    id = db.Column(db.Integer, primary_key=True)

    prescription_id = db.Column(
        db.Integer,
        db.ForeignKey("prescriptions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    test_name = db.Column(db.String(200), nullable=False)
    instructions = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    prescription = db.relationship("Prescription")

    def to_dict(self):
        return {
            "id": self.id,
            "prescription_id": self.prescription_id,
            "test_name": self.test_name,
            "instructions": self.instructions,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f"<PrescriptionLabTest {self.test_name}>"
