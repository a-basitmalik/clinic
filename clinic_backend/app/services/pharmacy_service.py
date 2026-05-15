from __future__ import annotations

from datetime import date, datetime, timedelta

from sqlalchemy import and_, or_, func

from ..extensions import db
from ..models.clinic import Clinic
from ..models.patient import Patient
from ..models.prescription import Prescription
from ..models.pharmacy import PharmacyItem, PharmacySale, PharmacySaleItem
from ..models.payment import Payment
from ..models.user import User
from ..services.user_service import UserService
from ..utils.validators import validate_email, parse_date, parse_float, parse_int


class PharmacyService:

    # ── Helpers ──────────────────────────────────────────────────────────

    @staticmethod
    def require_pharmacy_enabled(clinic_id: int) -> Clinic:
        clinic = Clinic.query.get(int(clinic_id))
        if not clinic:
            raise ValueError("Clinic not found.")
        if not clinic.has_pharmacy:
            raise ValueError("This clinic does not have pharmacy enabled.")
        return clinic

    @staticmethod
    def _item_duplicate_exists(
        clinic_id: int,
        medicine_name: str,
        batch_number: str | None,
        *,
        exclude_item_id: int | None = None,
    ) -> bool:
        name = (medicine_name or "").strip().lower()
        batch = (batch_number or "").strip().lower()
        q = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            func.lower(PharmacyItem.medicine_name) == name,
            func.lower(func.coalesce(PharmacyItem.batch_number, "")) == batch,
        )
        if exclude_item_id:
            q = q.filter(PharmacyItem.id != int(exclude_item_id))
        return db.session.query(q.exists()).scalar()

    @staticmethod
    def create_user(clinic_id: int, data: dict) -> dict:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        name = (data.get("name") or "").strip()
        email = (data.get("email") or "").lower().strip()
        phone = (data.get("phone") or "").strip()

        if not name:
            raise ValueError("Pharmacy user name is required.")
        if not email:
            raise ValueError("Pharmacy user email is required.")
        if not validate_email(email):
            raise ValueError("Invalid email address.")

        user, temp_pwd = UserService.create_user(
            name=name,
            email=email,
            phone=phone,
            role="pharmacy",
            clinic_id=clinic_id,
        )
        db.session.commit()

        return {
            "user": user.to_dict(),
            "temp_password": temp_pwd,
            "note": "Temporary password is shown only once.",
        }

    @staticmethod
    def list_users(clinic_id: int, include_inactive: bool = True):
        q = User.query.filter_by(clinic_id=clinic_id, role="pharmacy")
        if not include_inactive:
            q = q.filter(User.status == "active")
        return q.order_by(User.created_at.desc()).all()

    @staticmethod
    def get_user(clinic_id: int, user_id: int) -> User | None:
        return User.query.filter_by(clinic_id=clinic_id, role="pharmacy", id=user_id).first()

    @staticmethod
    def update_user(clinic_id: int, user_id: int, data: dict) -> User:
        user = PharmacyService.get_user(clinic_id, user_id)
        if not user:
            raise ValueError("Pharmacy user not found.")

        if "email" in data:
            new_email = (data.get("email") or "").lower().strip()
            if not validate_email(new_email):
                raise ValueError("Invalid email address.")

        UserService.update_user(
            user,
            name=data.get("name") if "name" in data else None,
            email=data.get("email") if "email" in data else None,
            phone=data.get("phone") if "phone" in data else None,
            status=data.get("status") if "status" in data else None,
        )
        db.session.commit()
        return user

    @staticmethod
    def soft_delete_user(clinic_id: int, user_id: int) -> User:
        user = PharmacyService.get_user(clinic_id, user_id)
        if not user:
            raise ValueError("Pharmacy user not found.")
        UserService.deactivate_user(user)
        db.session.commit()
        return user


    # ── Inventory (PharmacyItem) ─────────────────────────────────────────

    @staticmethod
    def create_item(clinic_id: int, data: dict) -> PharmacyItem:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        medicine_name = (data.get("medicine_name") or "").strip()
        if not medicine_name:
            raise ValueError("medicine_name is required.")

        category = (data.get("category") or "").strip() or None
        batch_number = (data.get("batch_number") or "").strip() or None
        supplier = (data.get("supplier") or "").strip() or None
        rack_number = (data.get("rack_number") or "").strip() or None

        expiry_date = parse_date(data.get("expiry_date"))
        purchase_price = parse_float(data.get("purchase_price"), "purchase_price", minimum=0) or 0.0
        sale_price = parse_float(data.get("sale_price"), "sale_price", minimum=0)
        if sale_price is None:
            raise ValueError("sale_price is required and must be a number.")
        quantity = parse_int(data.get("quantity"), "quantity", minimum=0)
        if quantity is None:
            raise ValueError("quantity is required and must be a non-negative integer.")

        low_stock_limit = parse_int(data.get("low_stock_limit"), "low_stock_limit", minimum=0)
        if low_stock_limit is None:
            low_stock_limit = 10

        status = (data.get("status") or "active").strip()
        if status not in ("active", "inactive"):
            raise ValueError("status must be 'active' or 'inactive'.")

        if PharmacyService._item_duplicate_exists(clinic_id, medicine_name, batch_number):
            raise ValueError("Duplicate medicine_name + batch_number in this clinic is not allowed.")

        item = PharmacyItem(
            clinic_id=int(clinic_id),
            medicine_name=medicine_name,
            category=category,
            batch_number=batch_number,
            expiry_date=expiry_date,
            purchase_price=purchase_price,
            sale_price=sale_price,
            quantity=int(quantity),
            supplier=supplier,
            rack_number=rack_number,
            low_stock_limit=int(low_stock_limit),
            status=status,
        )
        db.session.add(item)
        db.session.commit()
        return item

    @staticmethod
    def list_items(
        clinic_id: int,
        page: int,
        per_page: int,
        *,
        q: str | None = None,
        category: str | None = None,
        status: str | None = None,
        low_stock: bool | None = None,
        expiring: bool | None = None,
        expired: bool | None = None,
    ):
        PharmacyService.require_pharmacy_enabled(clinic_id)

        qry = PharmacyItem.query.filter_by(clinic_id=int(clinic_id))

        if q:
            s = f"%{q.strip()}%"
            qry = qry.filter(or_(PharmacyItem.medicine_name.ilike(s), PharmacyItem.batch_number.ilike(s)))

        if category:
            qry = qry.filter(PharmacyItem.category == category)

        if status:
            qry = qry.filter(PharmacyItem.status == status)

        today = date.today()
        if low_stock:
            qry = qry.filter(PharmacyItem.status == "active", PharmacyItem.quantity <= PharmacyItem.low_stock_limit)

        if expiring:
            until = today + timedelta(days=30)
            qry = qry.filter(
                PharmacyItem.status == "active",
                PharmacyItem.expiry_date.isnot(None),
                PharmacyItem.expiry_date >= today,
                PharmacyItem.expiry_date <= until,
            )

        if expired:
            qry = qry.filter(
                PharmacyItem.status == "active",
                PharmacyItem.expiry_date.isnot(None),
                PharmacyItem.expiry_date < today,
            )

        return qry.order_by(PharmacyItem.medicine_name.asc(), PharmacyItem.id.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

    @staticmethod
    def get_item(clinic_id: int, item_id: int) -> PharmacyItem | None:
        PharmacyService.require_pharmacy_enabled(clinic_id)
        return PharmacyItem.query.filter_by(clinic_id=int(clinic_id), id=int(item_id)).first()

    @staticmethod
    def update_item(clinic_id: int, item_id: int, data: dict) -> PharmacyItem:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        item = PharmacyService.get_item(clinic_id, item_id)
        if not item:
            raise ValueError("Medicine not found.")

        if "medicine_name" in data:
            name = (data.get("medicine_name") or "").strip()
            if not name:
                raise ValueError("medicine_name is required.")
            item.medicine_name = name

        if "category" in data:
            item.category = (data.get("category") or "").strip() or None

        if "batch_number" in data:
            item.batch_number = (data.get("batch_number") or "").strip() or None

        if "expiry_date" in data:
            item.expiry_date = parse_date(data.get("expiry_date"))

        if "purchase_price" in data:
            pp = parse_float(data.get("purchase_price"), "purchase_price", minimum=0)
            if pp is None:
                pp = 0.0
            item.purchase_price = pp

        if "sale_price" in data:
            sp = parse_float(data.get("sale_price"), "sale_price", minimum=0)
            if sp is None:
                raise ValueError("sale_price must be a number.")
            item.sale_price = sp

        if "quantity" in data:
            qty = parse_int(data.get("quantity"), "quantity", minimum=0)
            if qty is None:
                raise ValueError("quantity must be a non-negative integer.")
            item.quantity = int(qty)

        if "supplier" in data:
            item.supplier = (data.get("supplier") or "").strip() or None

        if "rack_number" in data:
            item.rack_number = (data.get("rack_number") or "").strip() or None

        if "low_stock_limit" in data:
            lsl = parse_int(data.get("low_stock_limit"), "low_stock_limit", minimum=0)
            if lsl is None:
                raise ValueError("low_stock_limit must be a non-negative integer.")
            item.low_stock_limit = int(lsl)

        if "status" in data:
            status = (data.get("status") or "").strip()
            if status not in ("active", "inactive"):
                raise ValueError("status must be 'active' or 'inactive'.")
            item.status = status

        # Duplicate guard (medicine_name + batch_number in same clinic)
        if PharmacyService._item_duplicate_exists(
            clinic_id,
            item.medicine_name,
            item.batch_number,
            exclude_item_id=item.id,
        ):
            raise ValueError("Duplicate medicine_name + batch_number in this clinic is not allowed.")

        db.session.commit()
        return item

    @staticmethod
    def soft_delete_item(clinic_id: int, item_id: int) -> PharmacyItem:
        PharmacyService.require_pharmacy_enabled(clinic_id)
        item = PharmacyService.get_item(clinic_id, item_id)
        if not item:
            raise ValueError("Medicine not found.")
        item.status = "inactive"
        db.session.commit()
        return item


    # ── Dashboard & alerts ───────────────────────────────────────────────

    @staticmethod
    def dashboard(clinic_id: int) -> dict:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        today = date.today()
        in_30 = today + timedelta(days=30)

        total_medicines = PharmacyItem.query.filter_by(clinic_id=int(clinic_id), status="active").count()
        low_stock_count = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            PharmacyItem.status == "active",
            PharmacyItem.quantity <= PharmacyItem.low_stock_limit,
        ).count()

        expiring_count = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            PharmacyItem.status == "active",
            PharmacyItem.expiry_date.isnot(None),
            PharmacyItem.expiry_date >= today,
            PharmacyItem.expiry_date <= in_30,
        ).count()

        expired_count = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            PharmacyItem.status == "active",
            PharmacyItem.expiry_date.isnot(None),
            PharmacyItem.expiry_date < today,
        ).count()

        today_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(
            PharmacySale.clinic_id == int(clinic_id),
            func.date(PharmacySale.created_at) == today,
        ).scalar()

        monthly_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(
            PharmacySale.clinic_id == int(clinic_id),
            func.date(PharmacySale.created_at) >= today.replace(day=1),
            func.date(PharmacySale.created_at) <= today,
        ).scalar()

        pending_prescription_orders = Prescription.query.filter(
            Prescription.clinic_id == int(clinic_id),
            Prescription.pharmacy_status.in_(["pending", "partial_dispensed"]),
        ).count()

        completed_prescription_orders = Prescription.query.filter(
            Prescription.clinic_id == int(clinic_id),
            Prescription.pharmacy_status == "dispensed",
        ).count()

        recent_sales = (
            PharmacySale.query.filter_by(clinic_id=int(clinic_id))
            .order_by(PharmacySale.created_at.desc())
            .limit(10)
            .all()
        )

        low_stock_items = (
            PharmacyItem.query.filter(
                PharmacyItem.clinic_id == int(clinic_id),
                PharmacyItem.status == "active",
                PharmacyItem.quantity <= PharmacyItem.low_stock_limit,
            )
            .order_by(PharmacyItem.quantity.asc())
            .limit(10)
            .all()
        )

        expiring_items = (
            PharmacyItem.query.filter(
                PharmacyItem.clinic_id == int(clinic_id),
                PharmacyItem.status == "active",
                PharmacyItem.expiry_date.isnot(None),
                PharmacyItem.expiry_date >= today,
                PharmacyItem.expiry_date <= in_30,
            )
            .order_by(PharmacyItem.expiry_date.asc())
            .limit(10)
            .all()
        )

        return {
            "total_medicines": int(total_medicines),
            "low_stock_count": int(low_stock_count),
            "expiring_count": int(expiring_count),
            "expired_count": int(expired_count),
            "today_sales": float(today_sales or 0),
            "monthly_sales": float(monthly_sales or 0),
            "pending_prescription_orders": int(pending_prescription_orders),
            "completed_prescription_orders": int(completed_prescription_orders),
            "recent_sales": [s.to_dict(include_items=True) for s in recent_sales],
            "low_stock_items": [i.to_dict() for i in low_stock_items],
            "expiring_items": [i.to_dict() for i in expiring_items],
        }


    # ── Prescription Orders ──────────────────────────────────────────────

    @staticmethod
    def _inventory_match_for_medicine(clinic_id: int, medicine_name: str) -> dict:
        name = (medicine_name or "").strip().lower()
        today = date.today()

        matches = (
            PharmacyItem.query.filter(
                PharmacyItem.clinic_id == int(clinic_id),
                PharmacyItem.status == "active",
                func.lower(PharmacyItem.medicine_name) == name,
            )
            .order_by(
                # prioritize non-expired
                PharmacyItem.expiry_date.is_(None).asc(),
                PharmacyItem.expiry_date.asc(),
                PharmacyItem.quantity.desc(),
            )
            .all()
        )

        available_stock = 0
        match_items = []
        for it in matches:
            is_expired = bool(it.expiry_date and it.expiry_date < today)
            available_stock += max(int(it.quantity or 0), 0)
            match_items.append(
                {
                    "id": it.id,
                    "batch_number": it.batch_number,
                    "expiry_date": it.expiry_date.isoformat() if it.expiry_date else None,
                    "is_expired": is_expired,
                    "quantity": int(it.quantity or 0),
                    "sale_price": float(it.sale_price or 0),
                    "status": it.status,
                }
            )

        return {
            "medicine_name": medicine_name,
            "available_stock": int(available_stock),
            "inventory_matches": match_items,
        }

    @staticmethod
    def list_prescription_orders(
        clinic_id: int,
        page: int,
        per_page: int,
        *,
        status: str | None = None,
        doctor_id: int | None = None,
        patient_id: int | None = None,
        on_date: date | None = None,
        start_date: date | None = None,
        end_date: date | None = None,
    ):
        PharmacyService.require_pharmacy_enabled(clinic_id)

        q = Prescription.query.filter_by(clinic_id=int(clinic_id))
        if status:
            q = q.filter(Prescription.pharmacy_status == status)
        if doctor_id:
            q = q.filter(Prescription.doctor_id == int(doctor_id))
        if patient_id:
            q = q.filter(Prescription.patient_id == int(patient_id))

        if on_date:
            q = q.filter(func.date(Prescription.created_at) == on_date)
        if start_date:
            q = q.filter(func.date(Prescription.created_at) >= start_date)
        if end_date:
            q = q.filter(func.date(Prescription.created_at) <= end_date)

        return q.order_by(Prescription.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def prescription_order_detail(clinic_id: int, prescription_id: int) -> dict:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        rx = Prescription.query.filter_by(clinic_id=int(clinic_id), id=int(prescription_id)).first()
        if not rx:
            raise ValueError("Prescription not found.")

        rx_data = rx.to_dict(include_medicines=True, include_lab_tests=True)
        rx_data["patient"] = rx.patient.to_dict() if rx.patient else None
        rx_data["doctor"] = rx.doctor.to_dict() if rx.doctor else None
        rx_data["appointment"] = rx.appointment.to_dict() if rx.appointment else None

        meds_match = []
        for m in rx.medicines:
            meds_match.append(
                {
                    **m.to_dict(),
                    "inventory": PharmacyService._inventory_match_for_medicine(clinic_id, m.medicine_name),
                }
            )

        return {
            "prescription": rx_data,
            "medicines": meds_match,
            "order_status": rx.pharmacy_status,
        }

    @staticmethod
    def update_prescription_order_status(clinic_id: int, prescription_id: int, status: str) -> Prescription:
        PharmacyService.require_pharmacy_enabled(clinic_id)
        rx = Prescription.query.filter_by(clinic_id=int(clinic_id), id=int(prescription_id)).first()
        if not rx:
            raise ValueError("Prescription not found.")

        if status not in ("pending", "partial_dispensed", "dispensed", "cancelled"):
            raise ValueError("Invalid pharmacy_status.")

        rx.pharmacy_status = status
        db.session.commit()
        return rx


    # ── Sales ────────────────────────────────────────────────────────────

    @staticmethod
    def create_sale(clinic_id: int, sold_by_user_id: int, data: dict) -> PharmacySale:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        payment_status = (data.get("payment_status") or "pending").strip()
        if payment_status not in ("paid", "pending", "partial"):
            raise ValueError("payment_status must be one of: paid, pending, partial.")

        payment_method = (data.get("payment_method") or "cash").strip()
        if payment_method not in ("cash", "card", "easypaisa", "jazzcash", "bank"):
            raise ValueError("Invalid payment_method.")

        patient_id = parse_int(data.get("patient_id"), "patient_id", minimum=1)
        prescription_id = parse_int(data.get("prescription_id"), "prescription_id", minimum=1)

        patient = None
        if patient_id:
            patient = Patient.query.filter_by(clinic_id=int(clinic_id), id=int(patient_id)).first()
            if not patient:
                raise ValueError("Patient not found in this clinic.")

        rx = None
        if prescription_id:
            rx = Prescription.query.filter_by(clinic_id=int(clinic_id), id=int(prescription_id)).first()
            if not rx:
                raise ValueError("Prescription not found in this clinic.")
            if patient_id and int(rx.patient_id) != int(patient_id):
                raise ValueError("patient_id does not match prescription patient.")
            if not patient_id:
                patient = rx.patient

        items = data.get("items")
        if not isinstance(items, list) or len(items) == 0:
            raise ValueError("items must be a non-empty list.")

        today = date.today()

        # Preload and validate stock
        resolved = []
        for idx, it in enumerate(items):
            if not isinstance(it, dict):
                raise ValueError(f"items[{idx}] must be an object.")
            med_id = parse_int(it.get("medicine_id"), f"items[{idx}].medicine_id", minimum=1)
            qty = parse_int(it.get("quantity"), f"items[{idx}].quantity", minimum=1)
            if not med_id:
                raise ValueError(f"items[{idx}].medicine_id is required.")
            if not qty:
                raise ValueError(f"items[{idx}].quantity must be >= 1.")

            med = PharmacyItem.query.filter_by(clinic_id=int(clinic_id), id=int(med_id), status="active").with_for_update().first()
            if not med:
                raise ValueError(f"Medicine {med_id} not found or inactive in this clinic.")
            if med.expiry_date and med.expiry_date < today:
                raise ValueError(f"Medicine '{med.medicine_name}' is expired.")
            if int(med.quantity or 0) < int(qty):
                raise ValueError(f"Insufficient stock for '{med.medicine_name}'.")

            unit_price = float(med.sale_price or 0)
            total_price = unit_price * int(qty)
            resolved.append((med, int(qty), unit_price, total_price))

        subtotal = sum(tp for _, _, _, tp in resolved)

        def _prescription_fully_covered(prescription: Prescription | None) -> bool:
            if not prescription:
                return False
            prescribed = list(prescription.medicines)
            if not prescribed:
                return True

            sold_ids = {int(med.id) for med, _, _, _ in resolved}
            sold_names = {(med.medicine_name or "").strip().lower() for med, _, _, _ in resolved}
            for prescribed_med in prescribed:
                if prescribed_med.medicine_id and int(prescribed_med.medicine_id) in sold_ids:
                    continue
                if (prescribed_med.medicine_name or "").strip().lower() in sold_names:
                    continue
                return False
            return True

        # Transaction: sale + items + stock deduction + payment + rx update
        try:
            sale = PharmacySale(
                clinic_id=int(clinic_id),
                patient_id=int(patient.id) if patient else None,
                prescription_id=int(rx.id) if rx else None,
                total_amount=subtotal,
                payment_status=payment_status,
                payment_method=payment_method,
                sold_by=int(sold_by_user_id) if sold_by_user_id else None,
            )
            db.session.add(sale)
            db.session.flush()

            for med, qty, unit_price, total_price in resolved:
                db.session.add(
                    PharmacySaleItem(
                        sale_id=sale.id,
                        medicine_id=med.id,
                        quantity=int(qty),
                        unit_price=unit_price,
                        total_price=total_price,
                    )
                )
                med.quantity = int(med.quantity or 0) - int(qty)
                if med.quantity < 0:
                    raise ValueError("Stock cannot go below zero.")

            # Create payment record (not linked to sale; used for accounting/patient ledger)
            payment_status_for_payment = "paid" if payment_status == "paid" else "pending"
            payment = Payment(
                clinic_id=int(clinic_id),
                patient_id=int(patient.id) if patient else None,
                appointment_id=None,
                payment_type="pharmacy",
                amount=subtotal,
                method=payment_method,
                status=payment_status_for_payment,
                received_by=int(sold_by_user_id) if sold_by_user_id else None,
            )
            db.session.add(payment)

            if rx:
                rx.pharmacy_status = "dispensed" if _prescription_fully_covered(rx) else "partial_dispensed"

            db.session.commit()
            return sale
        except Exception:
            db.session.rollback()
            raise

    @staticmethod
    def list_sales(
        clinic_id: int,
        page: int,
        per_page: int,
        *,
        patient_id: int | None = None,
        prescription_id: int | None = None,
        payment_status: str | None = None,
        start_date: date | None = None,
        end_date: date | None = None,
    ):
        PharmacyService.require_pharmacy_enabled(clinic_id)
        q = PharmacySale.query.filter_by(clinic_id=int(clinic_id))

        if patient_id:
            q = q.filter(PharmacySale.patient_id == int(patient_id))
        if prescription_id:
            q = q.filter(PharmacySale.prescription_id == int(prescription_id))
        if payment_status:
            q = q.filter(PharmacySale.payment_status == payment_status)

        if start_date:
            q = q.filter(func.date(PharmacySale.created_at) >= start_date)
        if end_date:
            q = q.filter(func.date(PharmacySale.created_at) <= end_date)

        return q.order_by(PharmacySale.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def get_sale(clinic_id: int, sale_id: int) -> PharmacySale | None:
        PharmacyService.require_pharmacy_enabled(clinic_id)
        return PharmacySale.query.filter_by(clinic_id=int(clinic_id), id=int(sale_id)).first()

    @staticmethod
    def invoice_data(clinic_id: int, sale_id: int) -> dict:
        PharmacyService.require_pharmacy_enabled(clinic_id)
        sale = PharmacyService.get_sale(clinic_id, sale_id)
        if not sale:
            raise ValueError("Sale not found.")

        clinic = Clinic.query.get(int(clinic_id))
        patient = sale.patient
        seller = sale.seller

        items = []
        subtotal = 0.0
        for it in sale.items:
            row = it.to_dict()
            subtotal += float(row.get("total_price") or 0)
            items.append(row)

        return {
            "clinic": clinic.to_dict() if clinic else None,
            "sale": sale.to_dict(include_items=True),
            "patient": patient.to_dict() if patient else None,
            "prescription_id": sale.prescription_id,
            "sold_by": seller.to_dict() if seller else None,
            "items": items,
            "subtotal": float(subtotal),
            "total": float(sale.total_amount or 0),
            "payment_status": sale.payment_status,
            "payment_method": sale.payment_method,
            "created_at": sale.created_at.isoformat() if sale.created_at else None,
        }


    # ── Reports ──────────────────────────────────────────────────────────

    @staticmethod
    def reports(
        clinic_id: int,
        *,
        start_date: date | None,
        end_date: date | None,
        page: int | None = None,
        per_page: int | None = None,
    ) -> dict:
        PharmacyService.require_pharmacy_enabled(clinic_id)

        today = date.today()
        if not end_date:
            end_date = today
        if not start_date:
            start_date = today.replace(day=1)

        base_sales = PharmacySale.query.filter(
            PharmacySale.clinic_id == int(clinic_id),
            func.date(PharmacySale.created_at) >= start_date,
            func.date(PharmacySale.created_at) <= end_date,
        )

        total_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(
            PharmacySale.clinic_id == int(clinic_id),
            func.date(PharmacySale.created_at) >= start_date,
            func.date(PharmacySale.created_at) <= end_date,
        ).scalar()

        today_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(
            PharmacySale.clinic_id == int(clinic_id),
            func.date(PharmacySale.created_at) == today,
        ).scalar()

        monthly_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(
            PharmacySale.clinic_id == int(clinic_id),
            func.date(PharmacySale.created_at) >= today.replace(day=1),
            func.date(PharmacySale.created_at) <= today,
        ).scalar()

        # Profit estimate: sum((unit_price - purchase_price) * qty)
        profit = (
            db.session.query(
                func.coalesce(
                    func.sum(
                        (PharmacySaleItem.unit_price - func.coalesce(PharmacyItem.purchase_price, 0))
                        * PharmacySaleItem.quantity
                    ),
                    0,
                )
            )
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .join(PharmacyItem, PharmacyItem.id == PharmacySaleItem.medicine_id)
            .filter(
                PharmacySale.clinic_id == int(clinic_id),
                func.date(PharmacySale.created_at) >= start_date,
                func.date(PharmacySale.created_at) <= end_date,
            )
            .scalar()
        )

        total_items_sold = (
            db.session.query(func.coalesce(func.sum(PharmacySaleItem.quantity), 0))
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .filter(
                PharmacySale.clinic_id == int(clinic_id),
                func.date(PharmacySale.created_at) >= start_date,
                func.date(PharmacySale.created_at) <= end_date,
            )
            .scalar()
        )

        most_sold_rows = (
            db.session.query(
                PharmacyItem.medicine_name,
                func.coalesce(func.sum(PharmacySaleItem.quantity), 0),
                func.coalesce(func.sum(PharmacySaleItem.total_price), 0),
            )
            .join(PharmacySaleItem, PharmacySaleItem.medicine_id == PharmacyItem.id)
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .filter(
                PharmacySale.clinic_id == int(clinic_id),
                func.date(PharmacySale.created_at) >= start_date,
                func.date(PharmacySale.created_at) <= end_date,
            )
            .group_by(PharmacyItem.medicine_name)
            .order_by(func.sum(PharmacySaleItem.quantity).desc())
            .limit(10)
            .all()
        )
        most_sold_medicines = [
            {"medicine_name": n, "quantity": int(qty), "total": float(total)}
            for n, qty, total in most_sold_rows
        ]

        # Stock alerts counts
        low_stock_count = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            PharmacyItem.status == "active",
            PharmacyItem.quantity <= PharmacyItem.low_stock_limit,
        ).count()

        expired_stock_count = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            PharmacyItem.status == "active",
            PharmacyItem.expiry_date.isnot(None),
            PharmacyItem.expiry_date < today,
        ).count()

        expiring_stock_count = PharmacyItem.query.filter(
            PharmacyItem.clinic_id == int(clinic_id),
            PharmacyItem.status == "active",
            PharmacyItem.expiry_date.isnot(None),
            PharmacyItem.expiry_date >= today,
            PharmacyItem.expiry_date <= today + timedelta(days=30),
        ).count()

        payment_method_rows = (
            db.session.query(
                PharmacySale.payment_method,
                func.coalesce(func.sum(PharmacySale.total_amount), 0),
                func.count(PharmacySale.id),
            )
            .filter(
                PharmacySale.clinic_id == int(clinic_id),
                func.date(PharmacySale.created_at) >= start_date,
                func.date(PharmacySale.created_at) <= end_date,
            )
            .group_by(PharmacySale.payment_method)
            .all()
        )
        sales_by_payment_method = [
            {"method": m, "total": float(total), "sales": int(cnt)}
            for m, total, cnt in payment_method_rows
        ]

        sales_by_date_rows = (
            db.session.query(
                func.date(PharmacySale.created_at),
                func.coalesce(func.sum(PharmacySale.total_amount), 0),
                func.count(PharmacySale.id),
            )
            .filter(
                PharmacySale.clinic_id == int(clinic_id),
                func.date(PharmacySale.created_at) >= start_date,
                func.date(PharmacySale.created_at) <= end_date,
            )
            .group_by(func.date(PharmacySale.created_at))
            .order_by(func.date(PharmacySale.created_at).asc())
            .all()
        )
        sales_by_date = [
            {"date": d.isoformat() if hasattr(d, "isoformat") else str(d), "total": float(total), "sales": int(cnt)}
            for d, total, cnt in sales_by_date_rows
        ]

        sales_by_category_rows = (
            db.session.query(
                func.coalesce(PharmacyItem.category, "Uncategorized"),
                func.coalesce(func.sum(PharmacySaleItem.total_price), 0),
            )
            .join(PharmacySaleItem, PharmacySaleItem.medicine_id == PharmacyItem.id)
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .filter(
                PharmacySale.clinic_id == int(clinic_id),
                func.date(PharmacySale.created_at) >= start_date,
                func.date(PharmacySale.created_at) <= end_date,
            )
            .group_by(func.coalesce(PharmacyItem.category, "Uncategorized"))
            .order_by(func.sum(PharmacySaleItem.total_price).desc())
            .all()
        )
        sales_by_category = [
            {"category": cat, "total": float(total)}
            for cat, total in sales_by_category_rows
        ]

        sales_detail_paginated = None
        if page is not None and per_page is not None:
            sales_detail_paginated = base_sales.order_by(PharmacySale.created_at.desc()).paginate(
                page=page, per_page=per_page, error_out=False
            )
            sales_detail = [s.to_dict(include_items=True) for s in sales_detail_paginated.items]
        else:
            sales_detail = [s.to_dict(include_items=True) for s in base_sales.order_by(PharmacySale.created_at.desc()).limit(50).all()]

        result = {
            "date_range": {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()},
            "today_sales": float(today_sales or 0),
            "monthly_sales": float(monthly_sales or 0),
            "total_sales": float(total_sales or 0),
            "total_profit_estimate": float(profit or 0),
            "total_items_sold": int(total_items_sold or 0),
            "most_sold_medicines": most_sold_medicines,
            "low_stock_count": int(low_stock_count),
            "expired_stock_count": int(expired_stock_count),
            "expiring_stock_count": int(expiring_stock_count),
            "sales_by_payment_method": sales_by_payment_method,
            "sales_by_date": sales_by_date,
            "sales_by_category": sales_by_category,
            "sales_detail": sales_detail,
        }

        if sales_detail_paginated is not None:
            result["pagination"] = {
                "page": sales_detail_paginated.page,
                "per_page": sales_detail_paginated.per_page,
                "total": sales_detail_paginated.total,
                "pages": sales_detail_paginated.pages,
            }

        return result
