from __future__ import annotations

from datetime import date

from ..extensions import db
from ..models.appointment import Appointment
from ..models.patient import Patient


class TokenService:

    @staticmethod
    def build_appointment_token_code(doctor_id: int, appointment_date: date, token_sequence: int) -> str:
        return f"D{int(doctor_id):03d}-{appointment_date.strftime('%Y%m%d')}-{int(token_sequence):03d}"

    @staticmethod
    def next_doctor_daily_token_sequence(clinic_id: int, doctor_id: int, appointment_date: date) -> int:
        """Return next token sequence (int) per doctor per day.

        Stored in Appointment.token_number as an integer for ordering.
        """
        last = (
            Appointment.query.filter_by(
                clinic_id=clinic_id,
                doctor_id=doctor_id,
                appointment_date=appointment_date,
            )
            .order_by(Appointment.token_number.desc())
            .with_for_update()
            .first()
        )
        return int(last.token_number) + 1 if last else 1

    @staticmethod
    def next_patient_code(clinic_id: int, on_date: date) -> str:
        """Generate patient_code: P-YYYYMMDD-0001 (sequence per clinic per day)."""
        prefix = f"P-{on_date.strftime('%Y%m%d')}-"

        last = (
            Patient.query.filter(
                Patient.clinic_id == clinic_id,
                Patient.patient_code.like(f"{prefix}%"),
            )
            .order_by(Patient.patient_code.desc())
            .with_for_update()
            .first()
        )

        next_seq = 1
        if last and last.patient_code:
            try:
                next_seq = int(last.patient_code.split("-")[-1]) + 1
            except Exception:
                next_seq = 1

        return f"{prefix}{next_seq:04d}"
