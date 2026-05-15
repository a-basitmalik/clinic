from __future__ import annotations

from datetime import date

from sqlalchemy import or_, func

from ..extensions import db
from ..models.appointment import Appointment
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..models.payment import Payment
from ..models.prescription import Prescription
from ..services.token_service import TokenService


class PatientService:

    @staticmethod
    def create(clinic_id: int, created_by: int, data: dict) -> Patient:
        name = (data.get("name") or "").strip()
        phone = (data.get("phone") or "").strip()

        if not name:
            raise ValueError("Patient name is required.")
        if not phone:
            raise ValueError("Patient phone is required.")

        # Duplicate phone/cnic within clinic
        if Patient.query.filter_by(clinic_id=clinic_id, phone=phone).first():
            raise ValueError("A patient with this phone already exists in this clinic.")

        cnic = (data.get("cnic") or "").strip() or None
        if cnic and Patient.query.filter_by(clinic_id=clinic_id, cnic=cnic).first():
            raise ValueError("A patient with this CNIC already exists in this clinic.")

        gender = data.get("gender")
        if gender is not None and gender not in ("male", "female", "other"):
            raise ValueError("gender must be 'male', 'female', or 'other'.")

        patient_code = TokenService.next_patient_code(clinic_id, date.today())

        patient = Patient(
            clinic_id=clinic_id,
            user_id=data.get("user_id"),
            patient_code=patient_code,
            name=name,
            age=data.get("age"),
            gender=gender,
            phone=phone,
            cnic=cnic,
            address=(data.get("address") or "").strip() or None,
            blood_group=(data.get("blood_group") or "").strip() or None,
            emergency_contact=(data.get("emergency_contact") or "").strip() or None,
            created_by=created_by,
        )

        db.session.add(patient)
        db.session.commit()
        return patient

    @staticmethod
    def list(
        clinic_id: int,
        page: int,
        per_page: int,
        *,
        search: str | None = None,
        gender: str | None = None,
        blood_group: str | None = None,
    ):
        query = Patient.query.filter_by(clinic_id=clinic_id)

        if search:
            s = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    Patient.name.ilike(s),
                    Patient.phone.ilike(s),
                    Patient.patient_code.ilike(s),
                    Patient.cnic.ilike(s),
                )
            )

        if gender:
            query = query.filter(Patient.gender == gender)
        if blood_group:
            query = query.filter(Patient.blood_group == blood_group)

        return query.order_by(Patient.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def get(clinic_id: int, patient_id: int) -> Patient | None:
        return Patient.query.filter_by(clinic_id=clinic_id, id=patient_id).first()

    @staticmethod
    def update(clinic_id: int, patient_id: int, data: dict) -> Patient:
        patient = PatientService.get(clinic_id, patient_id)
        if not patient:
            raise ValueError("Patient not found.")

        if "phone" in data:
            phone = (data.get("phone") or "").strip()
            if not phone:
                raise ValueError("Patient phone is required.")
            exists = Patient.query.filter(
                Patient.clinic_id == clinic_id,
                Patient.phone == phone,
                Patient.id != patient.id,
            ).first()
            if exists:
                raise ValueError("A patient with this phone already exists in this clinic.")
            patient.phone = phone

        if "cnic" in data:
            cnic = (data.get("cnic") or "").strip() or None
            if cnic:
                exists = Patient.query.filter(
                    Patient.clinic_id == clinic_id,
                    Patient.cnic == cnic,
                    Patient.id != patient.id,
                ).first()
                if exists:
                    raise ValueError("A patient with this CNIC already exists in this clinic.")
            patient.cnic = cnic

        if "name" in data:
            patient.name = (data.get("name") or "").strip() or patient.name

        if "age" in data:
            patient.age = data.get("age")

        if "gender" in data:
            gender = data.get("gender")
            if gender is not None and gender not in ("male", "female", "other"):
                raise ValueError("gender must be 'male', 'female', or 'other'.")
            patient.gender = gender

        for field in ("address", "blood_group", "emergency_contact", "user_id"):
            if field in data:
                val = data.get(field)
                if isinstance(val, str):
                    val = val.strip() or None
                setattr(patient, field, val)

        db.session.commit()
        return patient

    @staticmethod
    def doctor_can_access_patient(clinic_id: int, doctor_id: int, patient_id: int) -> bool:
        return (
            Appointment.query.filter_by(
                clinic_id=clinic_id,
                doctor_id=doctor_id,
                patient_id=patient_id,
            ).first()
            is not None
        )

    @staticmethod
    def history(clinic_id: int, patient_id: int) -> dict:
        patient = PatientService.get(clinic_id, patient_id)
        if not patient:
            raise ValueError("Patient not found.")

        appointments = (
            Appointment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .order_by(Appointment.appointment_date.desc(), Appointment.appointment_time.desc())
            .limit(200)
            .all()
        )

        from ..services.appointment_service import AppointmentService

        prescriptions = (
            Prescription.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .order_by(Prescription.created_at.desc())
            .limit(200)
            .all()
        )

        payments = (
            Payment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .order_by(Payment.created_at.desc())
            .limit(500)
            .all()
        )

        visited_doctor_rows = (
            db.session.query(Doctor.id, Doctor.name, func.count(Appointment.id))
            .join(Appointment, Appointment.doctor_id == Doctor.id)
            .filter(
                Appointment.clinic_id == clinic_id,
                Appointment.patient_id == patient_id,
                Appointment.status != "cancelled",
            )
            .group_by(Doctor.id, Doctor.name)
            .order_by(func.count(Appointment.id).desc())
            .all()
        )
        visited_doctors = [
            {"doctor_id": did, "doctor_name": name, "visits": int(cnt)}
            for did, name, cnt in visited_doctor_rows
        ]

        total_visits = (
            Appointment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .filter(Appointment.status != "cancelled")
            .count()
        )

        last_visit = (
            Appointment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id, status="completed")
            .order_by(Appointment.appointment_date.desc(), Appointment.appointment_time.desc())
            .first()
        )

        upcoming = (
            Appointment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .filter(
                Appointment.appointment_date >= date.today(),
                Appointment.status.in_(["waiting", "sent_to_assistant", "in_consultation"]),
            )
            .order_by(Appointment.appointment_date.asc(), Appointment.token_number.asc())
            .limit(50)
            .all()
        )

        return {
            "profile": patient.to_dict(),
            "appointments": [AppointmentService.to_dict(a) for a in appointments],
            "prescriptions": [p.to_dict(include_medicines=True, include_lab_tests=True) for p in prescriptions],
            "payments": [p.to_dict() for p in payments],
            "visited_doctors": visited_doctors,
            "total_visits": total_visits,
            "last_visit_date": last_visit.appointment_date.isoformat() if last_visit else None,
            "upcoming_appointments": [AppointmentService.to_dict(a) for a in upcoming],
        }
