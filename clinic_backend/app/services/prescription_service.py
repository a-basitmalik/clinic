from __future__ import annotations

from datetime import date

from ..extensions import db
from ..models.appointment import Appointment
from ..models.patient import Patient
from ..models.prescription import Prescription, PrescriptionMedicine
from ..models.prescription_lab_test import PrescriptionLabTest
from ..utils.validators import parse_date


class PrescriptionService:

    @staticmethod
    def _validate_medicines(medicines) -> list[dict]:
        if medicines is None:
            return []
        if not isinstance(medicines, list):
            raise ValueError("medicines must be a list.")

        cleaned = []
        for idx, m in enumerate(medicines):
            if not isinstance(m, dict):
                raise ValueError(f"medicines[{idx}] must be an object.")
            name = (m.get("medicine_name") or "").strip()
            if not name:
                raise ValueError(f"medicines[{idx}].medicine_name is required.")
            cleaned.append(
                {
                    "medicine_id": m.get("medicine_id"),
                    "medicine_name": name,
                    "dosage": (m.get("dosage") or "").strip() or None,
                    "frequency": (m.get("frequency") or "").strip() or None,
                    "duration": (m.get("duration") or "").strip() or None,
                    "instructions": (m.get("instructions") or "").strip() or None,
                }
            )
        return cleaned

    @staticmethod
    def _validate_lab_tests(lab_tests) -> list[dict]:
        if lab_tests is None:
            return []
        if not isinstance(lab_tests, list):
            raise ValueError("lab_tests must be a list.")

        cleaned = []
        for idx, t in enumerate(lab_tests):
            if not isinstance(t, dict):
                raise ValueError(f"lab_tests[{idx}] must be an object.")
            test_name = (t.get("test_name") or "").strip()
            if not test_name:
                raise ValueError(f"lab_tests[{idx}].test_name is required.")
            cleaned.append(
                {
                    "test_name": test_name,
                    "instructions": (t.get("instructions") or "").strip() or None,
                }
            )
        return cleaned

    @staticmethod
    def create(clinic_id: int, doctor_id: int, data: dict) -> Prescription:
        appointment_id = data.get("appointment_id")
        patient_id = data.get("patient_id")
        if not appointment_id:
            raise ValueError("appointment_id is required.")
        if not patient_id:
            raise ValueError("patient_id is required.")

        appt = Appointment.query.filter_by(clinic_id=clinic_id, id=int(appointment_id)).first()
        if not appt:
            raise ValueError("Appointment not found in this clinic.")
        if int(appt.doctor_id) != int(doctor_id):
            raise ValueError("Access denied. Appointment does not belong to this doctor.")
        if int(appt.patient_id) != int(patient_id):
            raise ValueError("patient_id does not match appointment patient.")

        patient = Patient.query.filter_by(clinic_id=clinic_id, id=int(patient_id)).first()
        if not patient:
            raise ValueError("Patient not found in this clinic.")

        if Prescription.query.filter_by(appointment_id=appt.id).first():
            raise ValueError("A prescription already exists for this appointment.")

        medicines = PrescriptionService._validate_medicines(data.get("medicines"))
        lab_tests = PrescriptionService._validate_lab_tests(data.get("lab_tests"))

        rx = Prescription(
            clinic_id=clinic_id,
            doctor_id=doctor_id,
            patient_id=patient.id,
            appointment_id=appt.id,
            symptoms=(data.get("symptoms") or "").strip() or None,
            diagnosis=(data.get("diagnosis") or "").strip() or None,
            notes=(data.get("notes") or "").strip() or None,
            follow_up_date=parse_date(data.get("follow_up_date")),
            pharmacy_status="pending",
        )
        db.session.add(rx)
        db.session.flush()

        for m in medicines:
            db.session.add(
                PrescriptionMedicine(
                    prescription_id=rx.id,
                    medicine_id=int(m["medicine_id"]) if m.get("medicine_id") not in (None, "") else None,
                    medicine_name=m["medicine_name"],
                    dosage=m.get("dosage"),
                    frequency=m.get("frequency"),
                    duration=m.get("duration"),
                    instructions=m.get("instructions"),
                )
            )

        for t in lab_tests:
            db.session.add(
                PrescriptionLabTest(
                    prescription_id=rx.id,
                    test_name=t["test_name"],
                    instructions=t.get("instructions"),
                )
            )

        db.session.commit()
        return rx

    @staticmethod
    def get(clinic_id: int, prescription_id: int) -> Prescription | None:
        return Prescription.query.filter_by(clinic_id=clinic_id, id=prescription_id).first()

    @staticmethod
    def list(clinic_id: int, page: int, per_page: int, *, patient_id: int | None = None, doctor_id: int | None = None):
        q = Prescription.query.filter_by(clinic_id=clinic_id)
        if patient_id:
            q = q.filter(Prescription.patient_id == int(patient_id))
        if doctor_id:
            q = q.filter(Prescription.doctor_id == int(doctor_id))
        return q.order_by(Prescription.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)

    @staticmethod
    def get_by_patient(clinic_id: int, patient_id: int):
        return (
            Prescription.query.filter_by(clinic_id=clinic_id, patient_id=patient_id)
            .order_by(Prescription.created_at.desc())
            .all()
        )

    @staticmethod
    def get_by_appointment(clinic_id: int, appointment_id: int) -> Prescription | None:
        return Prescription.query.filter_by(clinic_id=clinic_id, appointment_id=appointment_id).first()

    @staticmethod
    def update(clinic_id: int, doctor_id: int, prescription_id: int, data: dict) -> Prescription:
        rx = PrescriptionService.get(clinic_id, prescription_id)
        if not rx:
            raise ValueError("Prescription not found.")

        if int(rx.doctor_id or 0) != int(doctor_id):
            raise ValueError("Access denied. Prescription does not belong to this doctor.")

        for tf in ("symptoms", "diagnosis", "notes"):
            if tf in data:
                setattr(rx, tf, (data.get(tf) or "").strip() or None)

        if "follow_up_date" in data:
            rx.follow_up_date = parse_date(data.get("follow_up_date"))

        if "medicines" in data:
            medicines = PrescriptionService._validate_medicines(data.get("medicines"))
            rx.medicines = []
            db.session.flush()
            for m in medicines:
                rx.medicines.append(
                    PrescriptionMedicine(
                        medicine_id=int(m["medicine_id"]) if m.get("medicine_id") not in (None, "") else None,
                        medicine_name=m["medicine_name"],
                        dosage=m.get("dosage"),
                        frequency=m.get("frequency"),
                        duration=m.get("duration"),
                        instructions=m.get("instructions"),
                    )
                )

        if "lab_tests" in data:
            lab_tests = PrescriptionService._validate_lab_tests(data.get("lab_tests"))
            PrescriptionLabTest.query.filter_by(prescription_id=rx.id).delete()
            db.session.flush()
            for t in lab_tests:
                db.session.add(
                    PrescriptionLabTest(
                        prescription_id=rx.id,
                        test_name=t["test_name"],
                        instructions=t.get("instructions"),
                    )
                )

        db.session.commit()
        return rx

    @staticmethod
    def delete(clinic_id: int, doctor_id: int, prescription_id: int) -> None:
        rx = PrescriptionService.get(clinic_id, prescription_id)
        if not rx:
            raise ValueError("Prescription not found.")
        if int(rx.doctor_id or 0) != int(doctor_id):
            raise ValueError("Access denied.")

        db.session.delete(rx)
        db.session.commit()

    @staticmethod
    def print_data(clinic_id: int, prescription_id: int) -> dict:
        rx = PrescriptionService.get(clinic_id, prescription_id)
        if not rx:
            raise ValueError("Prescription not found.")

        data = rx.to_dict(include_medicines=True, include_lab_tests=True)
        data["patient"] = rx.patient.to_dict() if rx.patient else None
        data["doctor"] = rx.doctor.to_dict() if rx.doctor else None
        data["appointment"] = rx.appointment.to_dict() if rx.appointment else None
        return data
