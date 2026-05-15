from __future__ import annotations

from datetime import date, datetime, timedelta

from sqlalchemy import or_

from ..extensions import db
from ..models.appointment import Appointment
from ..models.department import Department
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..models.payment import Payment
from ..models.pharmacy import PharmacySale
from ..models.user import User


class ClinicAdminService:

    @staticmethod
    def dashboard(clinic_id: int) -> dict:
        today = date.today()
        month_start = today.replace(day=1)

        total_doctors = Doctor.query.filter_by(clinic_id=clinic_id, status="active").count()
        total_departments = Department.query.filter_by(clinic_id=clinic_id, status="active").count()
        total_receptionists = User.query.filter_by(
            clinic_id=clinic_id, role="receptionist", status="active"
        ).count()
        total_pharmacy_users = User.query.filter_by(
            clinic_id=clinic_id, role="pharmacy", status="active"
        ).count()
        total_patients = Patient.query.filter_by(clinic_id=clinic_id).count()

        today_appointments = Appointment.query.filter_by(clinic_id=clinic_id).filter(
            Appointment.appointment_date == today
        ).count()

        pending_appointments = Appointment.query.filter_by(clinic_id=clinic_id).filter(
            Appointment.status.in_(["waiting", "sent_to_assistant", "in_consultation"])
        ).count()

        completed_appointments = Appointment.query.filter_by(clinic_id=clinic_id, status="completed").count()

        today_revenue = ClinicAdminService._sum_payments(
            clinic_id=clinic_id, start_date=today, end_date=today, only_paid=True
        )
        monthly_revenue = ClinicAdminService._sum_payments(
            clinic_id=clinic_id, start_date=month_start, end_date=today, only_paid=True
        )

        recent_appointments = (
            Appointment.query.filter_by(clinic_id=clinic_id)
            .order_by(Appointment.created_at.desc())
            .limit(10)
            .all()
        )
        recent_patients = (
            Patient.query.filter_by(clinic_id=clinic_id)
            .order_by(Patient.created_at.desc())
            .limit(10)
            .all()
        )

        return {
            "total_doctors": total_doctors,
            "total_departments": total_departments,
            "total_receptionists": total_receptionists,
            "total_pharmacy_users": total_pharmacy_users,
            "total_patients": total_patients,
            "today_appointments": today_appointments,
            "pending_appointments": pending_appointments,
            "completed_appointments": completed_appointments,
            "today_revenue": float(today_revenue),
            "monthly_revenue": float(monthly_revenue),
            "recent_appointments": [ClinicAdminService._appointment_card(a) for a in recent_appointments],
            "recent_patients": [p.to_dict() for p in recent_patients],
        }

    @staticmethod
    def revenue(clinic_id: int) -> dict:
        today = date.today()
        month_start = today.replace(day=1)

        today_revenue = ClinicAdminService._sum_payments(clinic_id, today, today, only_paid=True)
        monthly_revenue = ClinicAdminService._sum_payments(clinic_id, month_start, today, only_paid=True)
        total_revenue = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "paid",
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

        pending_total = db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(
            Payment.clinic_id == clinic_id,
            Payment.status == "pending",
        ).scalar()
        pending_count = Payment.query.filter_by(clinic_id=clinic_id, status="pending").count()

        # Basic doctor-wise consultation revenue (based on payments tied to appointments)
        doctor_rows = (
            db.session.query(
                Doctor.id,
                Doctor.name,
                db.func.coalesce(db.func.sum(Payment.amount), 0),
                db.func.count(Payment.id),
            )
            .join(Appointment, Appointment.id == Payment.appointment_id)
            .join(Doctor, Doctor.id == Appointment.doctor_id)
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.status == "paid",
                Payment.payment_type == "consultation",
            )
            .group_by(Doctor.id, Doctor.name)
            .order_by(db.func.sum(Payment.amount).desc())
            .limit(50)
            .all()
        )
        doctor_wise = [
            {
                "doctor_id": did,
                "doctor_name": dname,
                "revenue": float(amount),
                "transactions": int(cnt),
            }
            for did, dname, amount, cnt in doctor_rows
        ]

        return {
            "today_revenue": float(today_revenue),
            "monthly_revenue": float(monthly_revenue),
            "total_revenue": float(total_revenue),
            "consultation_revenue": float(consultation_revenue),
            "pharmacy_revenue": float(pharmacy_revenue),
            "pending_payments": {"count": pending_count, "amount": float(pending_total)},
            "doctor_wise_revenue": doctor_wise,
        }

    @staticmethod
    def reports(clinic_id: int, start_date: date | None, end_date: date | None, doctor_id: int | None = None) -> dict:
        from ..services.report_service import ReportService

        filters = ReportService.normalize_filters(start_date=start_date, end_date=end_date, group_by="day")
        overview = ReportService.clinic_admin_overview(
            clinic_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
        )
        if doctor_id:
            overview["doctor_report"] = ReportService.doctor_revenue_report(
                clinic_id,
                doctor_id,
                start_date=filters["start_date"],
                end_date=filters["end_date"],
                group_by=filters["group_by"],
            )["summary"]
        return overview

    @staticmethod
    def advanced_reports(clinic_id: int, start_date: date | None, end_date: date | None, group_by: str = "day") -> dict:
        from ..services.report_service import ReportService

        filters = ReportService.normalize_filters(start_date=start_date, end_date=end_date, group_by=group_by)
        return ReportService.clinic_admin_overview(
            clinic_id,
            start_date=filters["start_date"],
            end_date=filters["end_date"],
            group_by=filters["group_by"],
        )

    @staticmethod
    def legacy_reports(clinic_id: int, start_date: date | None, end_date: date | None, doctor_id: int | None = None) -> dict:
        if not end_date:
            end_date = date.today()
        if not start_date:
            start_date = end_date - timedelta(days=30)

        q_appt = Appointment.query.filter_by(clinic_id=clinic_id).filter(
            Appointment.appointment_date >= start_date,
            Appointment.appointment_date <= end_date,
        )
        if doctor_id:
            q_appt = q_appt.filter(Appointment.doctor_id == doctor_id)

        appointment_count = q_appt.count()
        patient_visits = appointment_count

        doctor_count = Doctor.query.filter_by(clinic_id=clinic_id, status="active").count()

        payment_rows = (
            db.session.query(Payment.payment_type, db.func.coalesce(db.func.sum(Payment.amount), 0), db.func.count(Payment.id))
            .filter(
                Payment.clinic_id == clinic_id,
                Payment.status == "paid",
                db.func.date(Payment.created_at) >= start_date,
                db.func.date(Payment.created_at) <= end_date,
            )
            .group_by(Payment.payment_type)
            .all()
        )
        revenue_summary = [
            {"type": t, "total": float(total), "transactions": int(cnt)}
            for t, total, cnt in payment_rows
        ]

        sale_rows = (
            db.session.query(
                db.func.coalesce(db.func.sum(PharmacySale.total_amount), 0),
                db.func.count(PharmacySale.id),
            )
            .filter(
                PharmacySale.clinic_id == clinic_id,
                db.func.date(PharmacySale.created_at) >= start_date,
                db.func.date(PharmacySale.created_at) <= end_date,
                PharmacySale.payment_status.in_(["paid", "partial"]),
            )
            .first()
        )
        pharmacy_sales_summary = {
            "total_sales_amount": float(sale_rows[0] or 0),
            "total_sales": int(sale_rows[1] or 0),
        }

        return {
            "date_range": {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()},
            "appointment_count": appointment_count,
            "patient_visits": patient_visits,
            "doctor_count": doctor_count,
            "revenue_summary": revenue_summary,
            "pharmacy_sales_summary": pharmacy_sales_summary,
        }

    @staticmethod
    def list_patients(clinic_id: int, page: int, per_page: int, search: str | None = None):
        query = Patient.query.filter_by(clinic_id=clinic_id)
        if search:
            s = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    Patient.name.ilike(s),
                    Patient.phone.ilike(s),
                    Patient.patient_code.ilike(s),
                )
            )
        return query.order_by(Patient.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def list_appointments(
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
        query = Appointment.query.filter_by(clinic_id=clinic_id)

        if status:
            query = query.filter(Appointment.status == status)
        if doctor_id:
            query = query.filter(Appointment.doctor_id == doctor_id)
        if exact_date:
            query = query.filter(Appointment.appointment_date == exact_date)
        if start_date:
            query = query.filter(Appointment.appointment_date >= start_date)
        if end_date:
            query = query.filter(Appointment.appointment_date <= end_date)

        return query.order_by(Appointment.appointment_date.desc(), Appointment.appointment_time.desc()).paginate(
            page=page, per_page=per_page, error_out=False
        )

    # ── Helpers ──────────────────────────────────────────────────────────

    @staticmethod
    def _sum_payments(clinic_id: int, start_date: date, end_date: date, only_paid: bool = True):
        filters = [
            Payment.clinic_id == clinic_id,
            db.func.date(Payment.created_at) >= start_date,
            db.func.date(Payment.created_at) <= end_date,
        ]
        if only_paid:
            filters.append(Payment.status == "paid")
        return db.session.query(db.func.coalesce(db.func.sum(Payment.amount), 0)).filter(*filters).scalar()

    @staticmethod
    def _appointment_card(appt: Appointment) -> dict:
        return {
            "id": appt.id,
            "appointment_date": appt.appointment_date.isoformat() if appt.appointment_date else None,
            "appointment_time": appt.appointment_time.strftime("%H:%M") if appt.appointment_time else None,
            "status": appt.status,
            "token_number": appt.token_number,
            "payment_status": appt.payment_status,
            "fee": float(appt.fee) if appt.fee is not None else 0,
            "doctor": {"id": appt.doctor_id, "name": appt.doctor.name if appt.doctor else None},
            "patient": {"id": appt.patient_id, "name": appt.patient.name if appt.patient else None},
            "created_at": appt.created_at.isoformat() if appt.created_at else None,
        }
