from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timedelta

from sqlalchemy import func

from ..extensions import db
from ..models.appointment import Appointment
from ..models.clinic import Clinic
from ..models.department import Department
from ..models.doctor import Doctor
from ..models.patient import Patient
from ..models.payment import Payment
from ..models.pharmacy import PharmacyItem, PharmacySale, PharmacySaleItem
from ..models.prescription import Prescription, PrescriptionMedicine
from ..models.user import User
from ..services.pharmacy_service import PharmacyService


class ReportService:
    VALID_GROUPS = ("day", "month", "year")

    @staticmethod
    def normalize_filters(
        *,
        start_date: date | None,
        end_date: date | None,
        group_by: str | None = None,
        export: bool | str = False,
    ) -> dict:
        today = date.today()
        start = start_date or today.replace(day=1)
        end = end_date or today
        if end < start:
            raise ValueError("end_date must be greater than or equal to start_date.")

        group = group_by or "day"
        if group not in ReportService.VALID_GROUPS:
            raise ValueError("group_by must be one of: day, month, year.")

        export_bool = export in (True, "1", "true", "True", "yes", "Yes")
        return {"start_date": start, "end_date": end, "group_by": group, "export": export_bool}

    @staticmethod
    def _date_filter(column, start_date: date, end_date: date):
        return [func.date(column) >= start_date, func.date(column) <= end_date]

    @staticmethod
    def _appointment_filter(start_date: date, end_date: date):
        return [Appointment.appointment_date >= start_date, Appointment.appointment_date <= end_date]

    @staticmethod
    def _period(value, group_by: str) -> str:
        if isinstance(value, datetime):
            value = value.date()
        if not value:
            return "Unknown"
        if group_by == "year":
            return f"{value.year:04d}"
        if group_by == "month":
            return f"{value.year:04d}-{value.month:02d}"
        return value.isoformat()

    @staticmethod
    def _chart(rows: list[dict], label_key: str, value_key: str) -> dict:
        return {
            "labels": [row.get(label_key) for row in rows],
            "values": [row.get(value_key) for row in rows],
            "series": rows,
        }

    @staticmethod
    def _export(report_name: str, filters: dict, summary: dict, rows: list[dict]) -> dict:
        return {
            "report_name": report_name,
            "generated_at": datetime.utcnow().isoformat(),
            "filters": {
                "start_date": filters["start_date"].isoformat(),
                "end_date": filters["end_date"].isoformat(),
                "group_by": filters["group_by"],
            },
            "summary": summary,
            "rows": rows,
        }

    @staticmethod
    def _normal(summary: dict, charts: dict, rows: list[dict], filters: dict) -> dict:
        return {
            "filters": {
                "start_date": filters["start_date"].isoformat(),
                "end_date": filters["end_date"].isoformat(),
                "group_by": filters["group_by"],
            },
            "summary": summary,
            "charts": charts,
            "rows": rows,
        }

    @staticmethod
    def _clinic_filter(model, clinic_id: int | None):
        return [model.clinic_id == int(clinic_id)] if clinic_id else []

    @staticmethod
    def _doctor_in_clinic(clinic_id: int | None, doctor_id: int | None) -> Doctor | None:
        if not doctor_id:
            return None
        q = Doctor.query.filter(Doctor.id == int(doctor_id))
        if clinic_id:
            q = q.filter(Doctor.clinic_id == int(clinic_id))
        doctor = q.first()
        if not doctor:
            raise ValueError("Doctor not found in this scope.")
        return doctor

    @staticmethod
    def clinic_revenue_report(
        clinic_id: int | None,
        *,
        start_date: date,
        end_date: date,
        group_by: str,
        payment_type: str | None = None,
        doctor_id: int | None = None,
        export: bool = False,
    ) -> dict:
        ReportService._doctor_in_clinic(clinic_id, doctor_id)
        if payment_type and payment_type not in ("consultation", "pharmacy", "lab", "other"):
            raise ValueError("payment_type must be one of: consultation, pharmacy, lab, other.")

        q = Payment.query.filter(*ReportService._date_filter(Payment.created_at, start_date, end_date))
        if clinic_id:
            q = q.filter(Payment.clinic_id == int(clinic_id))
        if payment_type:
            q = q.filter(Payment.payment_type == payment_type)
        if doctor_id:
            q = q.join(Appointment, Appointment.id == Payment.appointment_id).filter(Appointment.doctor_id == int(doctor_id))

        payments = q.order_by(Payment.created_at.desc()).all()

        paid = [p for p in payments if p.status == "paid"]
        pending = [p for p in payments if p.status == "pending"]
        refunded = [p for p in payments if p.status == "refunded"]
        by_type = defaultdict(float)
        by_method = defaultdict(float)
        by_date = defaultdict(float)
        for p in paid:
            by_type[p.payment_type] += float(p.amount or 0)
            by_method[p.method] += float(p.amount or 0)
            by_date[ReportService._period(p.created_at, group_by)] += float(p.amount or 0)

        today = date.today()
        month_start = today.replace(day=1)
        today_revenue = sum(float(p.amount or 0) for p in paid if p.created_at and p.created_at.date() == today)
        monthly_revenue = sum(
            float(p.amount or 0)
            for p in paid
            if p.created_at and month_start <= p.created_at.date() <= today
        )

        doctor_rows = (
            db.session.query(Doctor.id, Doctor.name, func.coalesce(func.sum(Payment.amount), 0), func.count(Payment.id))
            .join(Appointment, Appointment.doctor_id == Doctor.id)
            .join(Payment, Payment.appointment_id == Appointment.id)
            .filter(
                *(ReportService._clinic_filter(Payment, clinic_id)),
                Payment.status == "paid",
                Payment.payment_type == "consultation",
                *ReportService._date_filter(Payment.created_at, start_date, end_date),
            )
            .group_by(Doctor.id, Doctor.name)
            .order_by(func.sum(Payment.amount).desc())
            .all()
        )
        revenue_by_doctor = [
            {"doctor_id": did, "doctor_name": name, "revenue": float(total), "payments": int(count)}
            for did, name, total, count in doctor_rows
        ]

        revenue_by_date = [{"date": k, "revenue": round(v, 2)} for k, v in sorted(by_date.items())]
        revenue_by_payment_method = [
            {"method": k, "revenue": round(v, 2)} for k, v in sorted(by_method.items())
        ]
        revenue_by_type = [{"type": k, "revenue": round(v, 2)} for k, v in sorted(by_type.items())]

        summary = {
            "total_revenue": round(sum(float(p.amount or 0) for p in paid), 2),
            "consultation_revenue": round(by_type.get("consultation", 0), 2),
            "pharmacy_revenue": round(by_type.get("pharmacy", 0), 2),
            "lab_revenue": round(by_type.get("lab", 0), 2),
            "other_revenue": round(by_type.get("other", 0), 2),
            "today_revenue": round(today_revenue, 2),
            "monthly_revenue": round(monthly_revenue, 2),
            "pending_amount": round(sum(float(p.amount or 0) for p in pending), 2),
            "refunded_amount": round(sum(float(p.amount or 0) for p in refunded), 2),
            "revenue_by_payment_method": revenue_by_payment_method,
            "revenue_by_date": revenue_by_date,
            "revenue_by_doctor": revenue_by_doctor,
            "revenue_by_type": revenue_by_type,
            "fallback_used": False,
        }
        rows = [p.to_dict() for p in payments]
        filters = {"start_date": start_date, "end_date": end_date, "group_by": group_by}
        if export:
            return ReportService._export("Clinic Revenue Report", filters, summary, rows)
        return ReportService._normal(
            summary,
            {
                "revenue_by_date": ReportService._chart(revenue_by_date, "date", "revenue"),
                "revenue_by_payment_method": ReportService._chart(revenue_by_payment_method, "method", "revenue"),
                "revenue_by_type": ReportService._chart(revenue_by_type, "type", "revenue"),
                "revenue_by_doctor": ReportService._chart(revenue_by_doctor, "doctor_name", "revenue"),
            },
            rows,
            filters,
        )

    @staticmethod
    def doctor_revenue_report(
        clinic_id: int | None,
        doctor_id: int,
        *,
        start_date: date,
        end_date: date,
        group_by: str,
        export: bool = False,
    ) -> dict:
        doctor = ReportService._doctor_in_clinic(clinic_id, doctor_id)

        appt_q = Appointment.query.filter(
            Appointment.doctor_id == int(doctor_id),
            *ReportService._appointment_filter(start_date, end_date),
        )
        if clinic_id:
            appt_q = appt_q.filter(Appointment.clinic_id == int(clinic_id))
        appointments = appt_q.order_by(Appointment.appointment_date.desc()).all()

        pay_q = Payment.query.join(Appointment, Appointment.id == Payment.appointment_id).filter(
            Payment.payment_type == "consultation",
            Payment.status == "paid",
            Appointment.doctor_id == int(doctor_id),
            *ReportService._date_filter(Payment.created_at, start_date, end_date),
        )
        if clinic_id:
            pay_q = pay_q.filter(Payment.clinic_id == int(clinic_id))
        payments = pay_q.all()

        fallback_used = False
        total_revenue = sum(float(p.amount or 0) for p in payments)
        if not payments:
            completed = [a for a in appointments if a.status == "completed"]
            total_revenue = sum(float(a.fee or 0) for a in completed)
            fallback_used = bool(completed)

        today = date.today()
        month_start = today.replace(day=1)
        today_revenue = sum(float(p.amount or 0) for p in payments if p.created_at and p.created_at.date() == today)
        monthly_revenue = sum(
            float(p.amount or 0)
            for p in payments
            if p.created_at and month_start <= p.created_at.date() <= today
        )
        by_date = defaultdict(float)
        appts_by_date = defaultdict(int)
        for p in payments:
            by_date[ReportService._period(p.created_at, group_by)] += float(p.amount or 0)
        for a in appointments:
            appts_by_date[ReportService._period(a.appointment_date, group_by)] += 1

        revenue_by_date = [{"date": k, "revenue": round(v, 2)} for k, v in sorted(by_date.items())]
        appointment_count_by_date = [
            {"date": k, "appointments": int(v)} for k, v in sorted(appts_by_date.items())
        ]
        paid_appointments = sum(1 for a in appointments if a.payment_status == "paid")
        unpaid_appointments = sum(1 for a in appointments if a.payment_status == "unpaid")
        completed_appointments = sum(1 for a in appointments if a.status == "completed")

        summary = {
            "doctor_id": doctor.id,
            "doctor_name": doctor.name,
            "total_revenue": round(total_revenue, 2),
            "today_revenue": round(today_revenue, 2),
            "monthly_revenue": round(monthly_revenue, 2),
            "completed_appointments": completed_appointments,
            "paid_appointments": paid_appointments,
            "unpaid_appointments": unpaid_appointments,
            "average_consultation_fee": round(total_revenue / completed_appointments, 2) if completed_appointments else 0,
            "revenue_by_date": revenue_by_date,
            "appointment_count_by_date": appointment_count_by_date,
            "fallback_used": fallback_used,
        }
        rows = [a.to_dict() for a in appointments]
        filters = {"start_date": start_date, "end_date": end_date, "group_by": group_by}
        if export:
            return ReportService._export("Doctor Revenue Report", filters, summary, rows)
        return ReportService._normal(
            summary,
            {
                "revenue_by_date": ReportService._chart(revenue_by_date, "date", "revenue"),
                "appointment_count_by_date": ReportService._chart(appointment_count_by_date, "date", "appointments"),
            },
            rows,
            filters,
        )

    @staticmethod
    def pharmacy_sales_report(
        clinic_id: int | None,
        *,
        start_date: date,
        end_date: date,
        group_by: str = "day",
        page: int | None = None,
        per_page: int | None = None,
        export: bool = False,
    ) -> dict:
        if clinic_id:
            summary = PharmacyService.reports(
                clinic_id,
                start_date=start_date,
                end_date=end_date,
                page=page,
                per_page=per_page,
            )
            rows = summary.get("sales_detail", [])
        else:
            summary = ReportService._global_pharmacy_report(start_date, end_date, page=page, per_page=per_page)
            rows = summary.get("sales_detail", [])

        filters = {"start_date": start_date, "end_date": end_date, "group_by": group_by}
        if export:
            return ReportService._export("Pharmacy Sales Report", filters, summary, rows)
        charts = {
            "sales_by_date": ReportService._chart(summary.get("sales_by_date", []), "date", "total"),
            "sales_by_payment_method": ReportService._chart(summary.get("sales_by_payment_method", []), "method", "total"),
            "sales_by_category": ReportService._chart(summary.get("sales_by_category", []), "category", "total"),
            "most_sold_medicines": ReportService._chart(summary.get("most_sold_medicines", []), "medicine_name", "quantity"),
        }
        return ReportService._normal(summary, charts, rows, filters)

    @staticmethod
    def _global_pharmacy_report(start_date: date, end_date: date, page: int | None = None, per_page: int | None = None) -> dict:
        # Mirrors PharmacyService.reports without requiring a single clinic context.
        today = date.today()
        date_filters = ReportService._date_filter(PharmacySale.created_at, start_date, end_date)
        total_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(*date_filters).scalar()
        today_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(func.date(PharmacySale.created_at) == today).scalar()
        monthly_sales = db.session.query(func.coalesce(func.sum(PharmacySale.total_amount), 0)).filter(
            func.date(PharmacySale.created_at) >= today.replace(day=1),
            func.date(PharmacySale.created_at) <= today,
        ).scalar()
        profit = (
            db.session.query(func.coalesce(func.sum((PharmacySaleItem.unit_price - func.coalesce(PharmacyItem.purchase_price, 0)) * PharmacySaleItem.quantity), 0))
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .join(PharmacyItem, PharmacyItem.id == PharmacySaleItem.medicine_id)
            .filter(*date_filters)
            .scalar()
        )
        total_items_sold = (
            db.session.query(func.coalesce(func.sum(PharmacySaleItem.quantity), 0))
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .filter(*date_filters)
            .scalar()
        )
        most_sold = (
            db.session.query(PharmacyItem.medicine_name, func.coalesce(func.sum(PharmacySaleItem.quantity), 0), func.coalesce(func.sum(PharmacySaleItem.total_price), 0))
            .join(PharmacySaleItem, PharmacySaleItem.medicine_id == PharmacyItem.id)
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .filter(*date_filters)
            .group_by(PharmacyItem.medicine_name)
            .order_by(func.sum(PharmacySaleItem.quantity).desc())
            .limit(10)
            .all()
        )
        by_method = (
            db.session.query(PharmacySale.payment_method, func.coalesce(func.sum(PharmacySale.total_amount), 0), func.count(PharmacySale.id))
            .filter(*date_filters)
            .group_by(PharmacySale.payment_method)
            .all()
        )
        by_date = (
            db.session.query(func.date(PharmacySale.created_at), func.coalesce(func.sum(PharmacySale.total_amount), 0), func.count(PharmacySale.id))
            .filter(*date_filters)
            .group_by(func.date(PharmacySale.created_at))
            .order_by(func.date(PharmacySale.created_at).asc())
            .all()
        )
        by_category = (
            db.session.query(func.coalesce(PharmacyItem.category, "Uncategorized"), func.coalesce(func.sum(PharmacySaleItem.total_price), 0))
            .join(PharmacySaleItem, PharmacySaleItem.medicine_id == PharmacyItem.id)
            .join(PharmacySale, PharmacySale.id == PharmacySaleItem.sale_id)
            .filter(*date_filters)
            .group_by(func.coalesce(PharmacyItem.category, "Uncategorized"))
            .all()
        )
        sales_q = PharmacySale.query.filter(*date_filters).order_by(PharmacySale.created_at.desc())
        if page is not None and per_page is not None:
            paginated = sales_q.paginate(page=page, per_page=per_page, error_out=False)
            sales_detail = [s.to_dict(include_items=True) for s in paginated.items]
            pagination = {"page": paginated.page, "per_page": paginated.per_page, "total": paginated.total, "pages": paginated.pages}
        else:
            sales_detail = [s.to_dict(include_items=True) for s in sales_q.limit(50).all()]
            pagination = None

        result = {
            "date_range": {"start_date": start_date.isoformat(), "end_date": end_date.isoformat()},
            "today_sales": float(today_sales or 0),
            "monthly_sales": float(monthly_sales or 0),
            "total_sales": float(total_sales or 0),
            "total_profit_estimate": float(profit or 0),
            "total_items_sold": int(total_items_sold or 0),
            "most_sold_medicines": [{"medicine_name": n, "quantity": int(q), "total": float(t)} for n, q, t in most_sold],
            "low_stock_count": PharmacyItem.query.filter(PharmacyItem.status == "active", PharmacyItem.quantity <= PharmacyItem.low_stock_limit).count(),
            "expired_stock_count": PharmacyItem.query.filter(PharmacyItem.status == "active", PharmacyItem.expiry_date.isnot(None), PharmacyItem.expiry_date < today).count(),
            "expiring_stock_count": PharmacyItem.query.filter(PharmacyItem.status == "active", PharmacyItem.expiry_date.isnot(None), PharmacyItem.expiry_date >= today, PharmacyItem.expiry_date <= today + timedelta(days=30)).count(),
            "sales_by_payment_method": [{"method": m, "total": float(t), "sales": int(c)} for m, t, c in by_method],
            "sales_by_date": [{"date": d.isoformat() if hasattr(d, "isoformat") else str(d), "total": float(t), "sales": int(c)} for d, t, c in by_date],
            "sales_by_category": [{"category": c, "total": float(t)} for c, t in by_category],
            "sales_detail": sales_detail,
        }
        if pagination:
            result["pagination"] = pagination
        return result

    @staticmethod
    def patient_visits_report(
        clinic_id: int | None,
        *,
        start_date: date,
        end_date: date,
        group_by: str,
        doctor_id: int | None = None,
        export: bool = False,
    ) -> dict:
        ReportService._doctor_in_clinic(clinic_id, doctor_id)
        appt_q = Appointment.query.filter(*ReportService._appointment_filter(start_date, end_date))
        patient_q = Patient.query
        if clinic_id:
            appt_q = appt_q.filter(Appointment.clinic_id == int(clinic_id))
            patient_q = patient_q.filter(Patient.clinic_id == int(clinic_id))
        if doctor_id:
            appt_q = appt_q.filter(Appointment.doctor_id == int(doctor_id))

        appointments = appt_q.all()
        patient_ids = {a.patient_id for a in appointments}
        new_patients = patient_q.filter(func.date(Patient.created_at) >= start_date, func.date(Patient.created_at) <= end_date).count()
        repeat_patients = sum(1 for pid in patient_ids if sum(1 for a in appointments if a.patient_id == pid) > 1)
        visits_by_date_map = defaultdict(int)
        for a in appointments:
            visits_by_date_map[ReportService._period(a.appointment_date, group_by)] += 1

        visits_by_doctor_rows = (
            db.session.query(Doctor.id, Doctor.name, func.count(Appointment.id))
            .join(Appointment, Appointment.doctor_id == Doctor.id)
            .filter(*ReportService._clinic_filter(Appointment, clinic_id), *ReportService._appointment_filter(start_date, end_date))
            .group_by(Doctor.id, Doctor.name)
            .all()
        )
        visits_by_department_rows = (
            db.session.query(Department.id, Department.name, func.count(Appointment.id))
            .join(Doctor, Doctor.department_id == Department.id)
            .join(Appointment, Appointment.doctor_id == Doctor.id)
            .filter(*ReportService._clinic_filter(Appointment, clinic_id), *ReportService._appointment_filter(start_date, end_date))
            .group_by(Department.id, Department.name)
            .all()
        )
        patients = patient_q.filter(Patient.id.in_(patient_ids)).all() if patient_ids else []
        gender_breakdown = defaultdict(int)
        age_groups = {"0-12": 0, "13-19": 0, "20-39": 0, "40-59": 0, "60+": 0, "unknown": 0}
        for p in patients:
            gender_breakdown[p.gender or "unknown"] += 1
            if p.age is None:
                age_groups["unknown"] += 1
            elif p.age <= 12:
                age_groups["0-12"] += 1
            elif p.age <= 19:
                age_groups["13-19"] += 1
            elif p.age <= 39:
                age_groups["20-39"] += 1
            elif p.age <= 59:
                age_groups["40-59"] += 1
            else:
                age_groups["60+"] += 1

        visits_by_date = [{"date": k, "visits": int(v)} for k, v in sorted(visits_by_date_map.items())]
        summary = {
            "total_patients": len(patient_ids),
            "new_patients": int(new_patients),
            "repeat_patients": int(repeat_patients),
            "total_visits": len(appointments),
            "visits_by_date": visits_by_date,
            "visits_by_doctor": [{"doctor_id": did, "doctor_name": n, "visits": int(c)} for did, n, c in visits_by_doctor_rows],
            "visits_by_department": [{"department_id": did, "department_name": n, "visits": int(c)} for did, n, c in visits_by_department_rows],
            "gender_breakdown": [{"gender": k, "patients": int(v)} for k, v in sorted(gender_breakdown.items())],
            "age_group_breakdown": [{"age_group": k, "patients": int(v)} for k, v in age_groups.items()],
        }
        rows = [a.to_dict() for a in appointments]
        filters = {"start_date": start_date, "end_date": end_date, "group_by": group_by}
        if export:
            return ReportService._export("Patient Visits Report", filters, summary, rows)
        return ReportService._normal(
            summary,
            {
                "visits_by_date": ReportService._chart(visits_by_date, "date", "visits"),
                "visits_by_doctor": ReportService._chart(summary["visits_by_doctor"], "doctor_name", "visits"),
                "visits_by_department": ReportService._chart(summary["visits_by_department"], "department_name", "visits"),
            },
            rows,
            filters,
        )

    @staticmethod
    def appointments_report(
        clinic_id: int | None,
        *,
        start_date: date,
        end_date: date,
        group_by: str,
        doctor_id: int | None = None,
        status: str | None = None,
        export: bool = False,
    ) -> dict:
        ReportService._doctor_in_clinic(clinic_id, doctor_id)
        q = Appointment.query.filter(*ReportService._appointment_filter(start_date, end_date))
        if clinic_id:
            q = q.filter(Appointment.clinic_id == int(clinic_id))
        if doctor_id:
            q = q.filter(Appointment.doctor_id == int(doctor_id))
        if status:
            q = q.filter(Appointment.status == status)
        appointments = q.order_by(Appointment.appointment_date.desc()).all()

        statuses = defaultdict(int)
        payment_statuses = defaultdict(int)
        by_date = defaultdict(int)
        for a in appointments:
            statuses[a.status] += 1
            payment_statuses[a.payment_status] += 1
            by_date[ReportService._period(a.appointment_date, group_by)] += 1

        by_doctor = (
            db.session.query(Doctor.id, Doctor.name, func.count(Appointment.id))
            .join(Appointment, Appointment.doctor_id == Doctor.id)
            .filter(*ReportService._clinic_filter(Appointment, clinic_id), *ReportService._appointment_filter(start_date, end_date))
            .group_by(Doctor.id, Doctor.name)
            .all()
        )
        by_department = (
            db.session.query(Department.id, Department.name, func.count(Appointment.id))
            .join(Doctor, Doctor.department_id == Department.id)
            .join(Appointment, Appointment.doctor_id == Doctor.id)
            .filter(*ReportService._clinic_filter(Appointment, clinic_id), *ReportService._appointment_filter(start_date, end_date))
            .group_by(Department.id, Department.name)
            .all()
        )
        appointments_by_date = [{"date": k, "appointments": int(v)} for k, v in sorted(by_date.items())]
        summary = {
            "total_appointments": len(appointments),
            "waiting": statuses.get("waiting", 0),
            "sent_to_assistant": statuses.get("sent_to_assistant", 0),
            "in_consultation": statuses.get("in_consultation", 0),
            "completed": statuses.get("completed", 0),
            "cancelled": statuses.get("cancelled", 0),
            "appointment_status_breakdown": [{"status": k, "appointments": int(v)} for k, v in sorted(statuses.items())],
            "appointments_by_date": appointments_by_date,
            "appointments_by_doctor": [{"doctor_id": did, "doctor_name": n, "appointments": int(c)} for did, n, c in by_doctor],
            "appointments_by_department": [{"department_id": did, "department_name": n, "appointments": int(c)} for did, n, c in by_department],
            "payment_status_breakdown": [{"status": k, "appointments": int(v)} for k, v in sorted(payment_statuses.items())],
            "cancellation_count": statuses.get("cancelled", 0),
        }
        rows = [a.to_dict() for a in appointments]
        filters = {"start_date": start_date, "end_date": end_date, "group_by": group_by}
        if export:
            return ReportService._export("Appointments Report", filters, summary, rows)
        return ReportService._normal(
            summary,
            {
                "appointments_by_date": ReportService._chart(appointments_by_date, "date", "appointments"),
                "appointments_by_doctor": ReportService._chart(summary["appointments_by_doctor"], "doctor_name", "appointments"),
                "appointment_status_breakdown": ReportService._chart(summary["appointment_status_breakdown"], "status", "appointments"),
            },
            rows,
            filters,
        )

    @staticmethod
    def payments_report(
        clinic_id: int | None,
        *,
        start_date: date,
        end_date: date,
        group_by: str,
        payment_type: str | None = None,
        status: str | None = None,
        export: bool = False,
    ) -> dict:
        if payment_type and payment_type not in ("consultation", "pharmacy", "lab", "other"):
            raise ValueError("payment_type must be one of: consultation, pharmacy, lab, other.")
        q = Payment.query.filter(*ReportService._date_filter(Payment.created_at, start_date, end_date))
        if clinic_id:
            q = q.filter(Payment.clinic_id == int(clinic_id))
        if payment_type:
            q = q.filter(Payment.payment_type == payment_type)
        if status:
            q = q.filter(Payment.status == status)
        payments = q.order_by(Payment.created_at.desc()).limit(500).all()

        by_type = defaultdict(float)
        by_method = defaultdict(float)
        by_date = defaultdict(float)
        for p in payments:
            by_type[p.payment_type] += float(p.amount or 0)
            by_method[p.method] += float(p.amount or 0)
            by_date[ReportService._period(p.created_at, group_by)] += float(p.amount or 0)
        payments_by_date = [{"date": k, "amount": round(v, 2)} for k, v in sorted(by_date.items())]
        summary = {
            "total_payments": len(payments),
            "total_paid_amount": round(sum(float(p.amount or 0) for p in payments if p.status == "paid"), 2),
            "total_pending_amount": round(sum(float(p.amount or 0) for p in payments if p.status == "pending"), 2),
            "total_refunded_amount": round(sum(float(p.amount or 0) for p in payments if p.status == "refunded"), 2),
            "payments_by_type": [{"type": k, "amount": round(v, 2)} for k, v in sorted(by_type.items())],
            "payments_by_method": [{"method": k, "amount": round(v, 2)} for k, v in sorted(by_method.items())],
            "payments_by_date": payments_by_date,
            "recent_payments": [p.to_dict() for p in payments[:20]],
        }
        rows = [p.to_dict() for p in payments]
        filters = {"start_date": start_date, "end_date": end_date, "group_by": group_by}
        if export:
            return ReportService._export("Payments Report", filters, summary, rows)
        return ReportService._normal(
            summary,
            {
                "payments_by_date": ReportService._chart(payments_by_date, "date", "amount"),
                "payments_by_type": ReportService._chart(summary["payments_by_type"], "type", "amount"),
                "payments_by_method": ReportService._chart(summary["payments_by_method"], "method", "amount"),
            },
            rows,
            filters,
        )

    @staticmethod
    def system_stats(start_date: date, end_date: date, group_by: str = "day") -> dict:
        revenue = ReportService.clinic_revenue_report(None, start_date=start_date, end_date=end_date, group_by=group_by)["summary"]
        return {
            "clinics": {
                "total": Clinic.query.count(),
                "approved": Clinic.query.filter_by(status="approved").count(),
                "pending": Clinic.query.filter_by(status="pending").count(),
                "suspended": Clinic.query.filter_by(status="suspended").count(),
                "by_type": [{"clinic_type": t, "count": int(c)} for t, c in db.session.query(Clinic.clinic_type, func.count(Clinic.id)).group_by(Clinic.clinic_type).all()],
            },
            "users": {
                "total": User.query.count(),
                "by_role": [{"role": r, "count": int(c)} for r, c in db.session.query(User.role, func.count(User.id)).group_by(User.role).all()],
            },
            "appointments": {
                "total": Appointment.query.filter(*ReportService._appointment_filter(start_date, end_date)).count(),
                "by_status": [{"status": s, "count": int(c)} for s, c in db.session.query(Appointment.status, func.count(Appointment.id)).filter(*ReportService._appointment_filter(start_date, end_date)).group_by(Appointment.status).all()],
            },
            "prescriptions": {
                "total": Prescription.query.filter(*ReportService._date_filter(Prescription.created_at, start_date, end_date)).count(),
                "by_pharmacy_status": [{"status": s, "count": int(c)} for s, c in db.session.query(Prescription.pharmacy_status, func.count(Prescription.id)).filter(*ReportService._date_filter(Prescription.created_at, start_date, end_date)).group_by(Prescription.pharmacy_status).all()],
            },
            "revenue": revenue,
        }

    @staticmethod
    def clinic_admin_overview(clinic_id: int, *, start_date: date, end_date: date, group_by: str) -> dict:
        revenue = ReportService.clinic_revenue_report(clinic_id, start_date=start_date, end_date=end_date, group_by=group_by)["summary"]
        appointments = ReportService.appointments_report(clinic_id, start_date=start_date, end_date=end_date, group_by=group_by)["summary"]
        patients = ReportService.patient_visits_report(clinic_id, start_date=start_date, end_date=end_date, group_by=group_by)["summary"]
        try:
            pharmacy = PharmacyService.reports(clinic_id, start_date=start_date, end_date=end_date)
        except ValueError as exc:
            pharmacy = {"enabled": False, "message": str(exc)}
        top_doctors = sorted(revenue.get("revenue_by_doctor", []), key=lambda row: row["revenue"], reverse=True)[:10]
        pending_amount = revenue.get("pending_amount", 0)
        return {
            "clinic_summary": {
                "total_doctors": Doctor.query.filter_by(clinic_id=clinic_id, status="active").count(),
                "total_patients": Patient.query.filter_by(clinic_id=clinic_id).count(),
                "total_appointments": appointments["total_appointments"],
            },
            "revenue_summary": revenue,
            "doctor_wise_revenue": revenue.get("revenue_by_doctor", []),
            "appointment_summary": appointments,
            "patient_visit_summary": patients,
            "pharmacy_summary": pharmacy,
            "pending_payments": {"amount": pending_amount},
            "top_doctors": top_doctors,
        }

    @staticmethod
    def doctor_overview(clinic_id: int, doctor_id: int, *, start_date: date, end_date: date, group_by: str) -> dict:
        revenue = ReportService.doctor_revenue_report(clinic_id, doctor_id, start_date=start_date, end_date=end_date, group_by=group_by)["summary"]
        appointments = ReportService.appointments_report(clinic_id, start_date=start_date, end_date=end_date, group_by=group_by, doctor_id=doctor_id)["summary"]
        prescriptions = Prescription.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id).filter(*ReportService._date_filter(Prescription.created_at, start_date, end_date)).count()
        followups = Prescription.query.filter_by(clinic_id=clinic_id, doctor_id=doctor_id).filter(Prescription.follow_up_date >= start_date, Prescription.follow_up_date <= end_date).count()
        patients_seen = db.session.query(func.count(func.distinct(Appointment.patient_id))).filter(
            Appointment.clinic_id == clinic_id,
            Appointment.doctor_id == doctor_id,
            Appointment.status == "completed",
            *ReportService._appointment_filter(start_date, end_date),
        ).scalar()
        return {
            "patients_seen": int(patients_seen or 0),
            "earnings": revenue,
            "consultations": appointments,
            "follow_ups": int(followups or 0),
            "prescriptions": int(prescriptions or 0),
            "date_series": revenue.get("revenue_by_date", []),
        }

    @staticmethod
    def receptionist_overview(clinic_id: int, user_id: int | None, *, start_date: date, end_date: date, group_by: str) -> dict:
        appt_q = Appointment.query.filter_by(clinic_id=clinic_id).filter(*ReportService._appointment_filter(start_date, end_date))
        patient_q = Patient.query.filter_by(clinic_id=clinic_id).filter(func.date(Patient.created_at) >= start_date, func.date(Patient.created_at) <= end_date)
        payment_q = Payment.query.filter_by(clinic_id=clinic_id).filter(*ReportService._date_filter(Payment.created_at, start_date, end_date))
        if user_id:
            appt_q = appt_q.filter(Appointment.receptionist_id == int(user_id))
            patient_q = patient_q.filter(Patient.created_by == int(user_id))
            payment_q = payment_q.filter(Payment.received_by == int(user_id))
        appointments = appt_q.all()
        patients_registered = patient_q.count()
        payments = payment_q.all()
        status_summary = defaultdict(int)
        payment_status_summary = defaultdict(int)
        for a in appointments:
            status_summary[a.status] += 1
        for p in payments:
            payment_status_summary[p.status] += 1
        return {
            "appointments_booked": len(appointments),
            "patients_registered": int(patients_registered),
            "payments_collected": round(sum(float(p.amount or 0) for p in payments if p.status == "paid"), 2),
            "appointment_status_summary": [{"status": k, "count": int(v)} for k, v in sorted(status_summary.items())],
            "payment_status_summary": [{"status": k, "count": int(v)} for k, v in sorted(payment_status_summary.items())],
            "recent_appointments": [a.to_dict() for a in appointments[:20]],
            "recent_payments": [p.to_dict() for p in payments[:20]],
        }
