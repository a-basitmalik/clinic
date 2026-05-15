from datetime import datetime
from ..extensions import db


class PharmacyItem(db.Model):
    __tablename__ = "pharmacy_items"

    id = db.Column(db.Integer, primary_key=True)
    clinic_id = db.Column(
        db.Integer,
        db.ForeignKey("clinics.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    medicine_name = db.Column(db.String(200), nullable=False)
    category = db.Column(db.String(100), nullable=True)
    batch_number = db.Column(db.String(100), nullable=True)
    expiry_date = db.Column(db.Date, nullable=True)
    purchase_price = db.Column(db.Numeric(10, 2), default=0, nullable=False)
    sale_price = db.Column(db.Numeric(10, 2), default=0, nullable=False)
    quantity = db.Column(db.Integer, default=0, nullable=False)
    supplier = db.Column(db.String(200), nullable=True)
    rack_number = db.Column(db.String(50), nullable=True)
    low_stock_limit = db.Column(db.Integer, default=10, nullable=False)
    status = db.Column(
        db.Enum("active", "inactive", name="pharmacy_item_statuses"),
        default="active",
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    clinic = db.relationship("Clinic", back_populates="pharmacy_items")
    sale_items = db.relationship(
        "PharmacySaleItem", back_populates="pharmacy_item", lazy="dynamic"
    )

    def to_dict(self):
        return {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "medicine_name": self.medicine_name,
            "category": self.category,
            "batch_number": self.batch_number,
            "expiry_date": self.expiry_date.isoformat() if self.expiry_date else None,
            "purchase_price": float(self.purchase_price) if self.purchase_price is not None else 0,
            "sale_price": float(self.sale_price) if self.sale_price is not None else 0,
            "quantity": self.quantity,
            "supplier": self.supplier,
            "rack_number": self.rack_number,
            "low_stock_limit": self.low_stock_limit,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

    def __repr__(self):
        return f"<PharmacyItem {self.medicine_name}>"


class PharmacySale(db.Model):
    __tablename__ = "pharmacy_sales"

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
    prescription_id = db.Column(
        db.Integer,
        db.ForeignKey("prescriptions.id", ondelete="SET NULL"),
        nullable=True,
    )
    total_amount = db.Column(db.Numeric(10, 2), default=0, nullable=False)
    payment_status = db.Column(
        db.Enum("paid", "pending", "partial", name="pharmacy_payment_statuses"),
        default="pending",
        nullable=False,
    )
    payment_method = db.Column(
        db.Enum("cash", "card", "easypaisa", "jazzcash", "bank", name="pharmacy_payment_methods"),
        default="cash",
        nullable=False,
    )
    sold_by = db.Column(
        db.Integer,
        db.ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    clinic = db.relationship("Clinic")
    patient = db.relationship("Patient")
    prescription = db.relationship("Prescription")
    seller = db.relationship("User", foreign_keys=[sold_by])
    items = db.relationship(
        "PharmacySaleItem",
        back_populates="sale",
        cascade="all, delete-orphan",
    )

    def to_dict(self, include_items=False):
        data = {
            "id": self.id,
            "clinic_id": self.clinic_id,
            "patient_id": self.patient_id,
            "prescription_id": self.prescription_id,
            "total_amount": float(self.total_amount) if self.total_amount is not None else 0,
            "payment_status": self.payment_status,
            "payment_method": self.payment_method,
            "sold_by": self.sold_by,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }
        if include_items:
            data["items"] = [i.to_dict() for i in self.items]
        return data

    def __repr__(self):
        return f"<PharmacySale {self.id} total={self.total_amount}>"


class PharmacySaleItem(db.Model):
    __tablename__ = "pharmacy_sale_items"

    id = db.Column(db.Integer, primary_key=True)
    sale_id = db.Column(
        db.Integer,
        db.ForeignKey("pharmacy_sales.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    medicine_id = db.Column(
        db.Integer,
        db.ForeignKey("pharmacy_items.id", ondelete="RESTRICT"),
        nullable=False,
    )
    quantity = db.Column(db.Integer, nullable=False)
    unit_price = db.Column(db.Numeric(10, 2), nullable=False)
    total_price = db.Column(db.Numeric(10, 2), nullable=False)

    sale = db.relationship("PharmacySale", back_populates="items")
    pharmacy_item = db.relationship("PharmacyItem", back_populates="sale_items")

    def to_dict(self):
        return {
            "id": self.id,
            "sale_id": self.sale_id,
            "medicine_id": self.medicine_id,
            "medicine_name": self.pharmacy_item.medicine_name if self.pharmacy_item else None,
            "quantity": self.quantity,
            "unit_price": float(self.unit_price),
            "total_price": float(self.total_price),
        }

    def __repr__(self):
        return f"<PharmacySaleItem sale={self.sale_id} med={self.medicine_id}>"
