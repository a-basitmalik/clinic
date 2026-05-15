from __future__ import annotations

from datetime import date

from sqlalchemy import func

from ..extensions import db
from ..models.clinic import Clinic
from ..models.department import Department
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..models.appointment import Appointment
from ..models.payment import Payment
from ..models.prescription import Prescription
from ..models.patient_vitals import PatientVitals
from ..models.patient_report import PatientReport
from ..models.user import User
from ..services.user_service import UserService
from ..utils.validators import validate_email, parse_time


class DoctorService:

    @staticmethod
    def dashboard(clinic_id: int, doctor_id: int) -> dict:
        today = date.today()

        q_today = Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id).filter(
            Appointment.appointment_date == today
        )

        today_appointments = q_today.count()
        waiting_patients = q_today.filter(Appointment.status.in_(["waiting", "sent_to_assistant"])).count()
        in_consultation = q_today.filter(Appointment.status == "in_consultation").count()
        completed_today = q_today.filter(Appointment.status == "completed").count()

        total_patients_seen = (
            db.session.query(func.count(func.distinct(Appointment.patient_id)))
            .filter(
                Appointment.clinic_id == clinic_id,
                Appointment.doctor_id == doctor_id,
                Appointment.status == "completed",
            )
            .scalar()
        )

        # Earnings: prefer paid consultation payments joined to appointments
        today_earning = (
            db.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.payment_type == "consultation",
                Payment.status == "paid",
                Appointment.doctor_id == doctor_id,
                Appointment.appointment_date == today,
            )
            .scalar()
        )

        month_start = today.replace(day=1)
        monthly_earning = (
            db.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.payment_type == "consultation",
                Payment.status == "paid",
                Appointment.doctor_id == doctor_id,
                Appointment.appointment_date >= month_start,
                Appointment.appointment_date <= today,
            )
            .scalar()
        )

        upcoming_followups = (
            Prescription.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id)
            .filter(Prescription.follow_up_date != None)  # noqa: E711
            .filter(Prescription.follow_up_date >= today)
            .order_by(Prescription.follow_up_date.asc())
            .limit(20)
            .all()
        )

        recent_patients = (
            db.session.query(Patient)
            .join(Appointment, Appointment.patient_id == Patient.id)
            .filter(
                Appointment.clinic_id == clinic_id,
                Appointment.doctor_id == doctor_id,
            )
            .order_by(Appointment.created_at.desc())
            .limit(10)
            .all()
        )

        today_queue = q_today.order_by(Appointment.token_number.asc()).all()

        return {
            "date": today.isoformat(),
            "today_appointments": int(today_appointments),
            "waiting_patients": int(waiting_patients),
            "in_consultation": int(in_consultation),
            "completed_today": int(completed_today),
            "total_patients_seen": int(total_patients_seen or 0),
            "today_earning": float(today_earning or 0),
            "monthly_earning": float(monthly_earning or 0),
            "upcoming_followups": [p.to_dict(include_medicines=True, include_lab_tests=True) for p in upcoming_followups],
            "recent_patients": [p.to_dict() for p in recent_patients],
            "today_queue": [a.to_dict() for a in today_queue],
        }

    @staticmethod
    def earnings(
        clinic_id: int,
        doctor_id: int,
        *,
        start_date: date | None = None,
        end_date: date | None = None,
    ) -> dict:
        q = (
            db.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.payment_type == "consultation",
                Payment.status == "paid",
                Appointment.doctor_id == doctor_id,
            )
        )
        if start_date:
            q = q.filter(Appointment.appointment_date >= start_date)
        if end_date:
            q = q.filter(Appointment.appointment_date <= end_date)

        total_earning = q.scalar()

        today = date.today()
        month_start = today.replace(day=1)

        # Calculate today/monthly via single queries (avoid recursion)
        today_amount = (
            db.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.payment_type == "consultation",
                Payment.status == "paid",
                Appointment.doctor_id == doctor_id,
                Appointment.appointment_date == today,
            )
            .scalar()
        )
        monthly_amount = (
            db.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.payment_type == "consultation",
                Payment.status == "paid",
                Appointment.doctor_id == doctor_id,
                Appointment.appointment_date >= month_start,
                Appointment.appointment_date <= today,
            )
            .scalar()
        )

        appointment_count = (
            Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id)
            .filter(Appointment.status == "completed")
            .count()
        )

        completed_consultations = appointment_count

        return {
            "today_earning": float(today_amount or 0),
            "monthly_earning": float(monthly_amount or 0),
            "total_earning": float(total_earning or 0),
            "appointment_count": int(appointment_count),
            "completed_consultations": int(completed_consultations),
            "date_range": {
                "start_date": start_date.isoformat() if start_date else None,
                "end_date": end_date.isoformat() if end_date else None,
            },
        }

    @staticmethod
    def reports(
        clinic_id: int,
        doctor_id: int,
        *,
        start_date: date | None = None,
        end_date: date | None = None,
        group_by: str = "day",
    ) -> dict:
        from ..services.report_service import ReportService

        filters = ReportService.normalize_filters(start_date=start_date, end_date=end_date, group_by=group_by)
        return ReportService.doctor_overview(
            clinic_id,
            doctor_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
        )

    @staticmethod
    def patient_profile(
        clinic_id: int,
        doctor_id: int,
        patient_id: int,
        *,
        include_clinic_history: bool = True,
    ) -> dict:
        patient = Patient.query.filter_by(clinic_id=clinic_id, id=patient_id).first()
        if not patient:
            raise ValueError("Patient not found in this clinic.")

        appts_with_doctor = (
            Appointment.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, patient_id=patient_id)
            .order_by(Appointment.appointment_date.desc(), Appointment.token_number.desc())
            .limit(100)
            .all()
        )

        if include_clinic_history:
            all_prescriptions = (
                Prescription.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
                .order_by(Prescription.created_at.desc())
                .limit(100)
                .all()
            )
            all_appointments = (
                Appointment.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
                .order_by(Appointment.appointment_date.desc(), Appointment.token_number.desc())
                .limit(200)
                .all()
            )
        else:
            all_prescriptions = (
                Prescription.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, patient_id=patient_id)
                .order_by(Prescription.created_at.desc())
                .limit(100)
                .all()
            )
            all_appointments = appts_with_doctor

        vitals = (
            PatientVitals.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, patient_id=patient_id)
            .order_by(PatientVitals.created_at.desc())
            .limit(50)
            .all()
        )

        reports = (
            PatientReport.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, patient_id=patient_id)
            .order_by(PatientReport.created_at.desc())
            .limit(50)
            .all()
        )

        payments_total = (
            db.session.query(func.coalesce(func.sum(Payment.amount), 0))
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.patient_id == patient_id,
                Payment.payment_type == "consultation",
                Payment.status == "paid",
                Appointment.doctor_id == doctor_id,
            )
            .scalar()
        )

        upcoming_followups = (
            Prescription.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id, patient_id=patient_id)
            .filter(Prescription.follow_up_date != None)  # noqa: E711
            .filter(Prescription.follow_up_date >= date.today())
            .order_by(Prescription.follow_up_date.asc())
            .limit(20)
            .all()
        )

        return {
            "patient": patient.to_dict(),
            "appointment_history_with_doctor": [a.to_dict() for a in appts_with_doctor],
            "appointments": [a.to_dict() for a in all_appointments],
            "prescriptions": [p.to_dict(include_medicines=True, include_lab_tests=True) for p in all_prescriptions],
            "vitals": [v.to_dict() for v in vitals],
            "reports": [r.to_dict() for r in reports],
            "payments_summary": {
                "consultation_paid_total_for_doctor": float(payments_total or 0),
            },
            "upcoming_followups": [p.to_dict(include_medicines=True, include_lab_tests=True) for p in upcoming_followups],
            "include_clinic_history": bool(include_clinic_history),
        }

    @staticmethod
    def create(clinic_id: int, data: dict) -> dict:
        name = (data.get("name") or "").strip()
        email = (data.get("email") or "").lower().strip()
        phone = (data.get("phone") or "").strip()

        if not name:
            raise ValueError("Doctor name is required.")
        if not email:
            raise ValueError("Doctor email is required.")
        if not validate_email(email):
            raise ValueError("Invalid email address.")

        dept_id = data.get("department_id")
        department_id = int(dept_id) if dept_id not in (None, "") else None
        if department_id:
            dept = Department.query.filter_by(id=department_id, clinic_id=clinic_id).first()
            if not dept:
                raise ValueError("Department does not belong to this clinic.")
        else:
            dept = None

        # Subscription max doctors guard
        clinic = Clinic.query.get(clinic_id)
        if not clinic:
            raise ValueError("Clinic not found.")
        if clinic.subscription_plan and clinic.subscription_plan.max_doctors:
            active_doctors = Doctor.query.filter_by(clinic_id=clinic_id, status="active").count()
            if active_doctors >= int(clinic.subscription_plan.max_doctors):
                raise ValueError("Doctor limit reached for the current subscription plan.")

        # Create user first
        user, temp_pwd = UserService.create_user(
            name=name,
            email=email,
            phone=phone,
            role="doctor",
            clinic_id=clinic_id,
        )

        doctor = Doctor(
            clinic_id=clinic_id,
            user_id=user.id,
            department_id=department_id,
            name=name,
            email=email,
            phone=phone or None,
            specialization=(data.get("specialization") or "").strip() or None,
            qualification=(data.get("qualification") or "").strip() or None,
            experience=data.get("experience"),
            license_number=(data.get("license_number") or "").strip() or None,
            consultation_fee=data.get("consultation_fee") or 0,
            available_days=data.get("available_days"),
            available_start_time=parse_time(data.get("available_start_time")),
            available_end_time=parse_time(data.get("available_end_time")),
            status=(data.get("status") or "active"),
        )
        if doctor.status not in ("active", "inactive"):
            raise ValueError("Invalid doctor status.")

        db.session.add(doctor)
        db.session.flush()

        user.doctor_id = doctor.id
        db.session.commit()

        return {
            "doctor": doctor.to_dict(),
            "account": {
                "user": user.to_dict(),
                "temp_password": temp_pwd,
                "note": "Temporary password is shown only once.",
            },
        }

    @staticmethod
    def list(clinic_id: int, include_inactive: bool = True):
        q = Doctor.query.filter_by(clinic_id=clinic_id)
        if not include_inactive:
            q = q.filter(Doctor.status == "active")
        return q.order_by(Doctor.created_at.desc()).all()

    @staticmethod
    def get(clinic_id: int, doctor_id: int) -> Doctor | None:
        return Doctor.query.filter_by(clinic_id=clinic_id, id=doctor_id).first()

    @staticmethod
    def update(clinic_id: int, doctor_id: int, data: dict) -> Doctor:
        doctor = DoctorService.get(clinic_id, doctor_id)
        if not doctor:
            raise ValueError("Doctor not found.")

        if "department_id" in data:
            dept_id = data.get("department_id")
            department_id = int(dept_id) if dept_id not in (None, "") else None
            if department_id:
                dept = Department.query.filter_by(id=department_id, clinic_id=clinic_id).first()
                if not dept:
                    raise ValueError("Department does not belong to this clinic.")
            doctor.department_id = department_id

        # Update doctor profile fields
        for field in [
            "name",
            "phone",
            "specialization",
            "qualification",
            "experience",
            "license_number",
            "consultation_fee",
            "available_days",
            "status",
            "email",
        ]:
            if field in data:
                if field == "email":
                    new_email = (data.get("email") or "").lower().strip()
                    if not new_email:
                        raise ValueError("Email is required.")
                    if not validate_email(new_email):
                        raise ValueError("Invalid email address.")
                    if doctor.user_id:
                        user = User.query.get(doctor.user_id)
                        if user and UserService.email_taken_by_other(new_email, user.id):
                            raise ValueError(f"Email '{new_email}' is already registered in the system.")
                        if user:
                            user.email = new_email
                    doctor.email = new_email
                elif field == "name":
                    doctor.name = (data.get("name") or "").strip() or doctor.name
                    if doctor.user_id:
                        user = User.query.get(doctor.user_id)
                        if user:
                            user.name = doctor.name
                elif field == "phone":
                    doctor.phone = (data.get("phone") or "").strip() or None
                    if doctor.user_id:
                        user = User.query.get(doctor.user_id)
                        if user:
                            user.phone = doctor.phone
                elif field == "status":
                    status = data.get("status")
                    if status not in ("active", "inactive"):
                        raise ValueError("Invalid doctor status.")
                    doctor.status = status
                    if doctor.user_id:
                        user = User.query.get(doctor.user_id)
                        if user:
                            user.status = "active" if status == "active" else "inactive"
                else:
                    setattr(doctor, field, data.get(field))

        # Parse times if present
        for tf in ("available_start_time", "available_end_time"):
            if tf in data:
                setattr(doctor, tf, parse_time(data.get(tf)))

        db.session.commit()
        return doctor

    @staticmethod
    def deactivate(clinic_id: int, doctor_id: int) -> Doctor:
        doctor = DoctorService.get(clinic_id, doctor_id)
        if not doctor:
            raise ValueError("Doctor not found.")

        doctor.status = "inactive"
        if doctor.user_id:
            user = User.query.get(doctor.user_id)
            if user:
                user.status = "inactive"
        db.session.commit()
        return doctor

    @staticmethod
    def soft_delete(clinic_id: int, doctor_id: int) -> Doctor:
        return DoctorService.deactivate(clinic_id, doctor_id)
