from __future__ import annotations

from datetime import date

from ..extensions import db
from ..models.appointment import Appointment
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..models.payment import Payment
from ..models.prescription import Prescription
from ..services.token_service import TokenService
from ..utils.validators import parse_time, parse_date


class AppointmentService:

    @staticmethod
    def build_token_code(appt: Appointment) -> str | None:
        if not appt or not appt.appointment_date or not appt.doctor_id or not appt.token_number:
            return None
        return TokenService.build_appointment_token_code(appt.doctor_id, appt.appointment_date, appt.token_number)

    @staticmethod
    def create(
        clinic_id: int,
        receptionist_user_id: int | None,
        data: dict,
    ) -> dict:
        patient_id = data.get("patient_id")
        doctor_id = data.get("doctor_id")
        if not patient_id:
            raise ValueError("patient_id is required.")
        if not doctor_id:
            raise ValueError("doctor_id is required.")

        patient = Patient.query.filter_by(clinic_id=clinic_id, id=int(patient_id)).first()
        if not patient:
            raise ValueError("Patient not found in this clinic.")

        doctor = Doctor.query.filter_by(clinic_id=clinic_id, id=int(doctor_id)).first()
        if not doctor:
            raise ValueError("Doctor not found in this clinic.")
        if doctor.status != "active":
            raise ValueError("Doctor is inactive.")

        appt_date = parse_date(data.get("appointment_date"))
        if not appt_date:
            raise ValueError("appointment_date is required (YYYY-MM-DD).")

        appt_time = parse_time(data.get("appointment_time"))
        if not appt_time:
            raise ValueError("appointment_time is required (HH:MM).")

        consultation_type = data.get("consultation_type") or "new"
        if consultation_type not in ("new", "followup", "emergency"):
            raise ValueError("consultation_type must be new, followup, or emergency.")

        fee = data.get("fee")
        try:
            fee_amount = float(fee) if fee is not None else float(doctor.consultation_fee or 0)
        except (TypeError, ValueError):
            raise ValueError("fee must be a number.")
        if fee_amount < 0:
            raise ValueError("fee cannot be negative.")

        payment_status = data.get("payment_status") or "unpaid"
        if payment_status not in ("unpaid", "paid", "partial"):
            raise ValueError("payment_status must be unpaid, paid, or partial.")

        paid_amount = data.get("paid_amount")
        payment_method = data.get("payment_method")

        if payment_status in ("paid", "partial"):
            if not payment_method:
                raise ValueError("payment_method is required when payment_status is paid/partial.")
            if payment_method not in ("cash", "card", "easypaisa", "jazzcash", "bank"):
                raise ValueError("Invalid payment_method.")

            if paid_amount is None:
                paid_amount = fee_amount
            try:
                paid_amount = float(paid_amount)
            except (TypeError, ValueError):
                raise ValueError("paid_amount must be a number.")
            if paid_amount <= 0:
                raise ValueError("paid_amount must be greater than 0.")
            if payment_status == "paid" and abs(paid_amount - fee_amount) > 0.0001:
                raise ValueError("paid_amount must equal fee when payment_status is paid.")
            if payment_status == "partial" and paid_amount >= fee_amount:
                raise ValueError("paid_amount must be less than fee when payment_status is partial.")

        # Token sequence
        token_seq = TokenService.next_doctor_daily_token_sequence(clinic_id, doctor.id, appt_date)

        appt = Appointment(
            clinic_id=clinic_id,
            doctor_id=doctor.id,
            patient_id=patient.id,
            receptionist_id=receptionist_user_id,
            appointment_date=appt_date,
            appointment_time=appt_time,
            token_number=token_seq,
            consultation_type=consultation_type,
            status="waiting",
            fee=fee_amount,
            payment_status=payment_status,
            notes=(data.get("notes") or "").strip() or None,
        )
        db.session.add(appt)
        db.session.flush()

        payment = None
        if payment_status in ("paid", "partial"):
            payment = Payment(
                clinic_id=clinic_id,
                patient_id=patient.id,
                appointment_id=appt.id,
                payment_type="consultation",
                amount=paid_amount,
                method=payment_method,
                status="paid",
                received_by=receptionist_user_id,
            )
            db.session.add(payment)

        db.session.commit()

        return {
            "appointment": AppointmentService.to_dict(appt),
            "payment": payment.to_dict() if payment else None,
        }

    @staticmethod
    def to_dict(appt: Appointment) -> dict:
        data = appt.to_dict()
        data["token_code"] = AppointmentService.build_token_code(appt)
        return data

    @staticmethod
    def get(clinic_id: int, appointment_id: int) -> Appointment | None:
        return Appointment.query.filter_by(clinic_id=clinic_id, id=appointment_id).first()

    @staticmethod
    def list(
        clinic_id: int,
        page: int,
        per_page: int,
        *,
        status: str | None = None,
        doctor_id: int | None = None,
        exact_date: date | None = None,
        start_date: date | None = None,
        end_date: date | None = None,
    ):
        q = Appointment.query.filter_by(clinic_id=clinic_id)
        if status:
            q = q.filter(Appointment.status == status)
        if doctor_id:
            q = q.filter(Appointment.doctor_id == doctor_id)
        if exact_date:
            q = q.filter(Appointment.appointment_date == exact_date)
        if start_date:
            q = q.filter(Appointment.appointment_date >= start_date)
        if end_date:
            q = q.filter(Appointment.appointment_date <= end_date)

        return q.order_by(Appointment.appointment_date.desc(), Appointment.token_number.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

    @staticmethod
    def today(clinic_id: int, doctor_id: int | None = None):
        q = Appointment.query.filter_by(clinic_id=clinic_id).filter(Appointment.appointment_date == date.today())
        if doctor_id:
            q = q.filter(Appointment.doctor_id == doctor_id)
        return q.order_by(Appointment.token_number.asc()).all()

    @staticmethod
    def doctor_queue(clinic_id: int, doctor_id: int, on_date: date | None = None):
        if on_date is None:
            on_date = date.today()
        return (
            Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id)
            .filter(Appointment.appointment_date == on_date)
            .order_by(Appointment.token_number.asc())
            .all()
        )

    @staticmethod
    def update_status(clinic_id: int, appointment_id: int, new_status: str) -> Appointment:
        appt = AppointmentService.get(clinic_id, appointment_id)
        if not appt:
            raise ValueError("Appointment not found.")

        if new_status not in (
            "waiting",
            "sent_to_assistant",
            "in_consultation",
            "completed",
            "cancelled",
        ):
            raise ValueError("Invalid appointment status.")

        appt.status = new_status
        db.session.commit()
        return appt

    @staticmethod
    def cancel(clinic_id: int, appointment_id: int, reason: str | None = None) -> Appointment:
        appt = AppointmentService.get(clinic_id, appointment_id)
        if not appt:
            raise ValueError("Appointment not found.")

        appt.status = "cancelled"
        if reason:
            existing = (appt.notes or "").strip()
            prefix = "Cancel reason: "
            appt.notes = (existing + "\n" if existing else "") + prefix + reason.strip()

        db.session.commit()
        return appt

    @staticmethod
    def reschedule(
        clinic_id: int,
        appointment_id: int,
        new_date: date,
        new_time,
    ) -> Appointment:
        appt = AppointmentService.get(clinic_id, appointment_id)
        if not appt:
            raise ValueError("Appointment not found.")

        appt.appointment_date = new_date
        appt.appointment_time = new_time

        # New token sequence for that doctor & date
        appt.token_number = TokenService.next_doctor_daily_token_sequence(
            clinic_id, appt.doctor_id, new_date
        )

        # Reset to waiting (unless already cancelled/completed; caller should guard)
        appt.status = "waiting"

        db.session.commit()
        return appt

    @staticmethod
    def start_consultation(clinic_id: int, *, doctor_id: int, appointment_id: int) -> Appointment:
        appt = AppointmentService.get(clinic_id, appointment_id)
        if not appt:
            raise ValueError("Appointment not found.")
        if int(appt.doctor_id) != int(doctor_id):
            raise ValueError("Access denied.")

        if appt.status in ("cancelled", "completed"):
            raise ValueError("Cancelled/completed appointments cannot be started.")

        appt.status = "in_consultation"
        db.session.commit()
        return appt

    @staticmethod
    def complete_appointment(
        clinic_id: int,
        *,
        doctor_id: int,
        appointment_id: int,
        allow_no_prescription: bool = False,
    ) -> Appointment:
        appt = AppointmentService.get(clinic_id, appointment_id)
        if not appt:
            raise ValueError("Appointment not found.")
        if int(appt.doctor_id) != int(doctor_id):
            raise ValueError("Access denied.")

        if appt.status in ("cancelled", "completed"):
            raise ValueError("Cancelled/completed appointments cannot be completed.")

        rx = Prescription.query.filter_by(appointment_id=appt.id).first()
        if not rx and not allow_no_prescription:
            raise ValueError("Cannot complete appointment without a prescription. Pass allow_no_prescription=true to override.")

        appt.status = "completed"
        db.session.commit()
        return appt
