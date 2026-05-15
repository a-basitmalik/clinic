from __future__ import annotations

from datetime import date

from sqlalchemy import or_

from ..extensions import db
from ..models.appointment import Appointment
from ..models.payment import Payment
from ..models.patient import Patient


class PaymentService:

    @staticmethod
    def create(clinic_id: int, received_by: int, data: dict) -> Payment:
        payment_type = data.get("payment_type")
        if payment_type not in ("consultation", "pharmacy", "lab", "other"):
            raise ValueError("payment_type must be one of: consultation, pharmacy, lab, other.")

        amount = data.get("amount")
        try:
            amount_f = float(amount)
        except (TypeError, ValueError):
            raise ValueError("amount must be a number.")
        if amount_f <= 0:
            raise ValueError("amount must be greater than 0.")

        method = data.get("method") or "cash"
        if method not in ("cash", "card", "easypaisa", "jazzcash", "bank"):
            raise ValueError("Invalid payment method.")

        status = data.get("status") or "paid"
        if status not in ("paid", "pending", "refunded"):
            raise ValueError("Invalid payment status.")

        patient_id = data.get("patient_id")
        appointment_id = data.get("appointment_id")

        if patient_id:
            patient = Patient.query.filter_by(clinic_id=clinic_id, id=int(patient_id)).first()
            if not patient:
                raise ValueError("Patient not found in this clinic.")

        if appointment_id:
            appt = Appointment.query.filter_by(clinic_id=clinic_id, id=int(appointment_id)).first()
            if not appt:
                raise ValueError("Appointment not found in this clinic.")

        payment = Payment(
            clinic_id=clinic_id,
            patient_id=int(patient_id) if patient_id else None,
            appointment_id=int(appointment_id) if appointment_id else None,
            payment_type=payment_type,
            amount=amount_f,
            method=method,
            status=status,
            received_by=received_by,
        )
        db.session.add(payment)
        db.session.commit()
        return payment

    @staticmethod
    def list(
        clinic_id: int,
        page: int,
        per_page: int,
        *,
        start_date: date | None = None,
        end_date: date | None = None,
        payment_type: str | None = None,
        status: str | None = None,
        doctor_id: int | None = None,
    ):
        q = Payment.query.filter_by(clinic_id=clinic_id)

        if start_date:
            q = q.filter(db.func.date(Payment.created_at) >= start_date)
        if end_date:
            q = q.filter(db.func.date(Payment.created_at) <= end_date)

        if payment_type:
            q = q.filter(Payment.payment_type == payment_type)

        if status:
            q = q.filter(Payment.status == status)

        if doctor_id:
            # Only payments linked to appointments with this doctor
            q = q.join(Appointment, Appointment.id == Payment.appointment_id).filter(Appointment.doctor_id == doctor_id)

        return q.order_by(Payment.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def patient_payments(clinic_id: int, patient_id: int):
        return (
            Payment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .order_by(Payment.created_at.desc())
            .all()
        )

    @staticmethod
    def revenue_summary(
        clinic_id: int,
        start_date: date | None,
        end_date: date | None,
        *,
        doctor_id: int | None = None,
        payment_type: str | None = None,
    ) -> dict:
        today = date.today()
        if not end_date:
            end_date = today
        if not start_date:
            start_date = today.replace(day=1)

        q = Payment.query.filter_by(clinic_id=clinic_id)
        q = q.filter(db.func.date(Payment.created_at) >= start_date, db.func.date(Payment.created_at) <= end_date)

        if payment_type:
            q = q.filter(Payment.payment_type == payment_type)

        if doctor_id:
            q = q.join(Appointment, Appointment.id == Payment.appointment_id).filter(Appointment.doctor_id == doctor_id)

        total_revenue = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "paid",
        ).scalar()

        today_revenue = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "paid",
            db.func.date(Payment.created_at) == today,
        ).scalar()

        monthly_revenue = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "paid",
            db.func.date(Payment.created_at) >= today.replace(day=1),
            db.func.date(Payment.created_at) <= today,
        ).scalar()

        consultation_revenue = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "paid",
            Payment.payment_type == "consultation",
        ).scalar()

        pharmacy_revenue = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "paid",
            Payment.payment_type == "pharmacy",
        ).scalar()

        pending_amount = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "pending",
        ).scalar()

        refunded_amount = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "refunded",
        ).scalar()

        method_rows = (
            db.session.query(
                Payment.method,
                db.func.coalesce(db.func.sum(Payment.amount), 0),
                db.func.count(Payment.id),
            )
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.status == "paid",
                db.func.date(Payment.created_at) >= start_date,
                db.func.date(Payment.created_at) <= end_date,
            )
            .group_by(Payment.method)
            .all()
        )
        payment_method_breakdown = [
            {"method": m, "total": float(total), "transactions": int(cnt)}
            for m, total, cnt in method_rows
        ]

        return {
            "date_range": {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()},
            "today_revenue": float(today_revenue),
            "monthly_revenue": float(monthly_revenue),
            "total_revenue": float(total_revenue),
            "consultation_revenue": float(consultation_revenue),
            "pharmacy_revenue": float(pharmacy_revenue),
            "pending_amount": float(pending_amount),
            "refunded_amount": float(refunded_amount),
            "payment_method_breakdown": payment_method_breakdown,
        }

    @staticmethod
    def report(
        clinic_id: int | None,
        *,
        start_date: date,
        end_date: date,
        group_by: str = "day",
        payment_type: str | None = None,
        status: str | None = None,
        export: bool = False,
    ) -> dict:
        from ..services.report_service import ReportService

        return ReportService.payments_report(
            clinic_id,
            start_date=start_date,
            end_date=end_date,
            group_by=group_by,
            payment_type=payment_type,
            status=status,
            export=export,
        )
