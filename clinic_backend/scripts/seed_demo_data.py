from __future__ import annotations

import sys
from datetime import date, datetime, time, timedelta
from decimal import Decimal
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import create_app
from app.extensions import db
from app.models.appointment import Appointment
from app.models.assistant import Assistant
from app.models.audit_log import AuditLog
from app.models.clinic import Clinic
from app.models.consultation_draft import ConsultationDraft
from app.models.department import Department
from app.models.doctor import Doctor
from app.models.patient import Patient
from app.models.patient_report import PatientReport
from app.models.patient_vitals import PatientVitals
from app.models.payment import Payment
from app.models.pharmacy import PharmacyItem, PharmacySale, PharmacySaleItem
from app.models.prescription import Prescription, PrescriptionMedicine
from app.models.prescription_lab_test import PrescriptionLabTest
from app.models.subscription import ClinicSubscription, SubscriptionPlan
from app.models.user import User
from app.utils.password_utils import hash_password


DEMO_PASSWORD = "Demo@12345!"


def get_or_create(model, defaults=None, **filters):
    obj = model.query.filter_by(**filters).first()
    if obj:
        return obj, False
    obj = model(**filters, **(defaults or {}))
    db.session.add(obj)
    db.session.flush()
    return obj, True


def main():
    app = create_app("production")
    with app.app_context():
        clinic = Clinic.query.filter_by(status="approved").order_by(Clinic.id.asc()).first()
        if not clinic:
            raise RuntimeError("No approved clinic found.")

        admin = User.query.filter_by(clinic_id=clinic.id, role="clinic_admin").first()
        receptionist = User.query.filter_by(clinic_id=clinic.id, role="receptionist").first() or admin
        pharmacist = User.query.filter_by(clinic_id=clinic.id, role="pharmacy").first() or admin
        doctors = Doctor.query.filter_by(clinic_id=clinic.id, status="active").order_by(Doctor.id.asc()).all()
        if not doctors:
            raise RuntimeError("No active doctors found.")

        created = {}

        departments = []
        department_names = [
            ("DEMO General Medicine", "General outpatient demo department"),
            ("DEMO Cardiology", "Heart and blood pressure demo department"),
            ("DEMO Dermatology", "Skin care demo department"),
            ("DEMO Pediatrics", "Children care demo department"),
            ("DEMO Diagnostics", "Lab and diagnostic demo department"),
        ]
        for name, description in department_names:
            item, was_created = get_or_create(
                Department,
                clinic_id=clinic.id,
                name=name,
                defaults={"description": description, "status": "active"},
            )
            created["departments"] = created.get("departments", 0) + int(was_created)
            departments.append(item)

        plan, was_created = get_or_create(
            SubscriptionPlan,
            name="DEMO Premium Clinic Plan",
            defaults={
                "price": Decimal("15000.00"),
                "duration_days": 365,
                "max_doctors": 15,
                "has_pharmacy": True,
                "has_reports": True,
                "status": "active",
            },
        )
        created["subscription_plans"] = int(was_created)
        sub = ClinicSubscription.query.filter_by(clinic_id=clinic.id, plan_id=plan.id, status="active").first()
        if not sub:
            db.session.add(
                ClinicSubscription(
                    clinic_id=clinic.id,
                    plan_id=plan.id,
                    start_date=date.today(),
                    end_date=date.today() + timedelta(days=365),
                    status="active",
                    amount_paid=plan.price,
                )
            )
            clinic.subscription_plan_id = plan.id
            created["clinic_subscriptions"] = 1

        assistants = []
        for i, doctor in enumerate(doctors[:2], start=1):
            email = f"demo.assistant{i:02d}@nalexus.com"
            user, user_created = get_or_create(
                User,
                email=email,
                defaults={
                    "name": f"DEMO Assistant {i:02d}",
                    "phone": f"03990010{i:02d}",
                    "password_hash": hash_password(DEMO_PASSWORD),
                    "role": "assistant",
                    "clinic_id": clinic.id,
                    "doctor_id": doctor.id,
                    "status": "active",
                    "must_change_password": True,
                },
            )
            assistant, assistant_created = get_or_create(
                Assistant,
                user_id=user.id,
                defaults={
                    "clinic_id": clinic.id,
                    "doctor_id": doctor.id,
                    "name": user.name,
                    "duties": ["DEMO vitals", "DEMO queue support", "DEMO draft notes"],
                    "can_view_appointments": True,
                    "can_add_vitals": True,
                    "can_upload_reports": True,
                    "can_prepare_prescription_draft": True,
                    "can_print_prescription": True,
                    "can_view_patient_history": True,
                    "status": "active",
                },
            )
            created["assistant_users"] = created.get("assistant_users", 0) + int(user_created)
            created["assistants"] = created.get("assistants", 0) + int(assistant_created)
            assistants.append(assistant)

        patients = []
        genders = ["male", "female", "other"]
        blood_groups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]
        for i in range(1, 16):
            patient_code = f"P-DEMO-{i:03d}"
            user, user_created = get_or_create(
                User,
                email=f"demo.patient{i:02d}@nalexus.com",
                defaults={
                    "name": f"DEMO Patient {i:02d}",
                    "phone": f"03990100{i:02d}",
                    "password_hash": hash_password(DEMO_PASSWORD),
                    "role": "patient",
                    "clinic_id": clinic.id,
                    "status": "active",
                    "must_change_password": True,
                },
            )
            patient, patient_created = get_or_create(
                Patient,
                clinic_id=clinic.id,
                patient_code=patient_code,
                defaults={
                    "user_id": user.id,
                    "name": user.name,
                    "age": 18 + (i * 3) % 65,
                    "gender": genders[i % len(genders)],
                    "phone": user.phone,
                    "cnic": f"35202-90000{i:02d}-{i % 9}",
                    "address": f"DEMO House {i}, Lahore",
                    "blood_group": blood_groups[i % len(blood_groups)],
                    "emergency_contact": f"03990200{i:02d}",
                    "created_by": receptionist.id if receptionist else None,
                },
            )
            created["patient_users"] = created.get("patient_users", 0) + int(user_created)
            created["patients"] = created.get("patients", 0) + int(patient_created)
            patients.append(patient)

        medicines = [
            ("Paracetamol 500mg", "Pain/Fever", "DEMO-BAT-001", 5, 12),
            ("Amoxicillin 250mg", "Antibiotic", "DEMO-BAT-002", 18, 35),
            ("Cetirizine 10mg", "Allergy", "DEMO-BAT-003", 4, 10),
            ("Omeprazole 20mg", "Gastro", "DEMO-BAT-004", 9, 22),
            ("Metformin 500mg", "Diabetes", "DEMO-BAT-005", 8, 18),
            ("Amlodipine 5mg", "Cardiology", "DEMO-BAT-006", 7, 16),
            ("Atorvastatin 20mg", "Cardiology", "DEMO-BAT-007", 15, 32),
            ("Salbutamol Inhaler", "Respiratory", "DEMO-BAT-008", 180, 260),
            ("ORS Sachet", "Hydration", "DEMO-BAT-009", 12, 25),
            ("Ibuprofen 400mg", "Pain", "DEMO-BAT-010", 6, 14),
            ("Azithromycin 500mg", "Antibiotic", "DEMO-BAT-011", 45, 80),
            ("Losartan 50mg", "Cardiology", "DEMO-BAT-012", 12, 28),
            ("Insulin Pen Demo", "Diabetes", "DEMO-BAT-013", 700, 950),
            ("Vitamin D3", "Supplement", "DEMO-BAT-014", 35, 60),
            ("Cough Syrup", "Respiratory", "DEMO-BAT-015", 80, 135),
        ]
        items = []
        for i, (name, category, batch, purchase, sale) in enumerate(medicines, start=1):
            item, was_created = get_or_create(
                PharmacyItem,
                clinic_id=clinic.id,
                batch_number=batch,
                defaults={
                    "medicine_name": f"DEMO {name}",
                    "category": category,
                    "expiry_date": date.today() + timedelta(days=90 + i * 20),
                    "purchase_price": Decimal(str(purchase)),
                    "sale_price": Decimal(str(sale)),
                    "quantity": 80 + i * 7,
                    "supplier": "DEMO Supplier",
                    "rack_number": f"D-{i:02d}",
                    "low_stock_limit": 10 + i % 5,
                    "status": "active",
                },
            )
            created["pharmacy_items"] = created.get("pharmacy_items", 0) + int(was_created)
            items.append(item)

        diagnoses = [
            "Seasonal allergic rhinitis",
            "Acute upper respiratory infection",
            "Gastritis",
            "Hypertension follow-up",
            "Type 2 diabetes follow-up",
            "Migraine headache",
            "Back pain",
            "Fever evaluation",
            "Dermatitis",
            "Asthma review",
            "Vitamin deficiency",
            "Hyperlipidemia review",
            "Sore throat",
            "Abdominal pain",
            "Routine wellness visit",
        ]
        appointment_statuses = ["completed", "waiting", "sent_to_assistant", "in_consultation", "cancelled"]
        payment_methods = ["cash", "card", "easypaisa", "jazzcash", "bank"]
        for i, patient in enumerate(patients, start=1):
            doctor = doctors[(i - 1) % len(doctors)]
            appt, appt_created = get_or_create(
                Appointment,
                clinic_id=clinic.id,
                doctor_id=doctor.id,
                appointment_date=date.today() + timedelta(days=(i % 5) - 2),
                token_number=200 + i,
                defaults={
                    "patient_id": patient.id,
                    "receptionist_id": receptionist.id if receptionist else None,
                    "appointment_time": time(9 + (i % 7), (i * 5) % 60),
                    "consultation_type": ["new", "followup", "emergency"][i % 3],
                    "status": appointment_statuses[i % len(appointment_statuses)],
                    "fee": Decimal(str(1200 + (i % 4) * 300)),
                    "payment_status": ["paid", "partial", "unpaid"][i % 3],
                    "notes": f"DEMO appointment note {i}",
                },
            )
            created["appointments"] = created.get("appointments", 0) + int(appt_created)

            vitals, vitals_created = get_or_create(
                PatientVitals,
                clinic_id=clinic.id,
                patient_id=patient.id,
                appointment_id=appt.id,
                defaults={
                    "doctor_id": doctor.id,
                    "assistant_id": assistants[(i - 1) % len(assistants)].id if assistants else None,
                    "temperature": Decimal(str(round(36.4 + (i % 5) * 0.3, 1))),
                    "blood_pressure": f"{110 + i}/{70 + i % 15}",
                    "pulse": 68 + i,
                    "weight": Decimal(str(55 + i * 2)),
                    "height": Decimal(str(150 + i)),
                    "oxygen_level": 95 + i % 5,
                    "notes": f"DEMO vitals entry {i}",
                },
            )
            created["patient_vitals"] = created.get("patient_vitals", 0) + int(vitals_created)

            prescription = Prescription.query.filter_by(appointment_id=appt.id).first()
            if not prescription:
                prescription = Prescription(
                    clinic_id=clinic.id,
                    doctor_id=doctor.id,
                    patient_id=patient.id,
                    appointment_id=appt.id,
                    symptoms=f"DEMO symptoms: {['cough', 'fever', 'headache', 'fatigue'][i % 4]}",
                    diagnosis=f"DEMO {diagnoses[i - 1]}",
                    notes=f"DEMO prescription notes {i}; review clinically.",
                    follow_up_date=date.today() + timedelta(days=7 + i),
                    pharmacy_status=["pending", "dispensed", "partial_dispensed"][i % 3],
                )
                db.session.add(prescription)
                db.session.flush()
                created["prescriptions"] = created.get("prescriptions", 0) + 1
                for med_idx in range(2):
                    med_item = items[(i + med_idx) % len(items)]
                    db.session.add(
                        PrescriptionMedicine(
                            prescription_id=prescription.id,
                            medicine_id=med_item.id,
                            medicine_name=med_item.medicine_name,
                            dosage=["1 tablet", "5 ml", "1 capsule"][med_idx % 3],
                            frequency=["Once daily", "Twice daily", "Three times daily"][(i + med_idx) % 3],
                            duration=f"{5 + med_idx * 2} days",
                            instructions="DEMO take after meals",
                        )
                    )
                    created["prescription_medicines"] = created.get("prescription_medicines", 0) + 1
                db.session.add(
                    PrescriptionLabTest(
                        prescription_id=prescription.id,
                        test_name=["CBC", "Fasting Blood Sugar", "Lipid Profile", "LFT", "Urine R/E"][i % 5],
                        instructions="DEMO lab test; fasting if applicable",
                    )
                )
                created["prescription_lab_tests"] = created.get("prescription_lab_tests", 0) + 1

            report = PatientReport.query.filter_by(clinic_id=clinic.id, patient_id=patient.id, report_title=f"DEMO Report {i:02d}").first()
            if not report:
                db.session.add(
                    PatientReport(
                        clinic_id=clinic.id,
                        patient_id=patient.id,
                        appointment_id=appt.id,
                        doctor_id=doctor.id,
                        uploaded_by=admin.id if admin else None,
                        report_title=f"DEMO Report {i:02d}",
                        report_type=["Lab", "Imaging", "Clinical Note"][i % 3],
                        file_url=f"https://example.com/demo-reports/report-{i:02d}.pdf",
                        notes=f"DEMO report notes {i}",
                    )
                )
                created["patient_reports"] = created.get("patient_reports", 0) + 1

            draft = ConsultationDraft.query.filter_by(appointment_id=appt.id).first()
            if not draft:
                db.session.add(
                    ConsultationDraft(
                        clinic_id=clinic.id,
                        appointment_id=appt.id,
                        patient_id=patient.id,
                        doctor_id=doctor.id,
                        assistant_id=assistants[(i - 1) % len(assistants)].id if assistants else None,
                        symptoms_draft=f"DEMO draft symptoms {i}",
                        vitals_summary=f"DEMO BP {110+i}/{70+i%15}, pulse {68+i}",
                        notes=f"DEMO assistant draft note {i}",
                    )
                )
                created["consultation_drafts"] = created.get("consultation_drafts", 0) + 1

            if not Payment.query.filter_by(clinic_id=clinic.id, appointment_id=appt.id, payment_type="consultation").first():
                db.session.add(
                    Payment(
                        clinic_id=clinic.id,
                        patient_id=patient.id,
                        appointment_id=appt.id,
                        payment_type="consultation",
                        amount=Decimal(str(600 + (i % 4) * 300)),
                        method=payment_methods[i % len(payment_methods)],
                        status=["paid", "paid", "pending"][i % 3],
                        received_by=receptionist.id if receptionist else None,
                    )
                )
                created["payments"] = created.get("payments", 0) + 1

            if not PharmacySale.query.filter_by(clinic_id=clinic.id, prescription_id=prescription.id).first():
                sale_item = items[(i - 1) % len(items)]
                qty = 1 + (i % 3)
                total = Decimal(str(sale_item.sale_price)) * qty
                sale = PharmacySale(
                    clinic_id=clinic.id,
                    patient_id=patient.id,
                    prescription_id=prescription.id,
                    total_amount=total,
                    payment_status=["paid", "pending", "partial"][i % 3],
                    payment_method=payment_methods[(i + 2) % len(payment_methods)],
                    sold_by=pharmacist.id if pharmacist else None,
                )
                db.session.add(sale)
                db.session.flush()
                db.session.add(
                    PharmacySaleItem(
                        sale_id=sale.id,
                        medicine_id=sale_item.id,
                        quantity=qty,
                        unit_price=sale_item.sale_price,
                        total_price=total,
                    )
                )
                sale_item.quantity = max(0, int(sale_item.quantity) - qty)
                created["pharmacy_sales"] = created.get("pharmacy_sales", 0) + 1
                created["pharmacy_sale_items"] = created.get("pharmacy_sale_items", 0) + 1

            if not AuditLog.query.filter_by(clinic_id=clinic.id, action=f"DEMO_ACTION_{i:02d}").first():
                db.session.add(
                    AuditLog(
                        clinic_id=clinic.id,
                        user_id=admin.id if admin else None,
                        action=f"DEMO_ACTION_{i:02d}",
                        module="demo_seed",
                        details={"patient_code": patient.patient_code, "purpose": "demo data"},
                        ip_address="127.0.0.1",
                    )
                )
                created["audit_logs"] = created.get("audit_logs", 0) + 1

        db.session.commit()

        summary_models = [
            Clinic,
            User,
            Department,
            Assistant,
            Patient,
            Appointment,
            PatientVitals,
            PatientReport,
            ConsultationDraft,
            Prescription,
            PrescriptionMedicine,
            PrescriptionLabTest,
            PharmacyItem,
            PharmacySale,
            PharmacySaleItem,
            Payment,
            AuditLog,
            SubscriptionPlan,
            ClinicSubscription,
        ]
        print("created", created)
        print("totals")
        for model in summary_models:
            print(f"{model.__tablename__}={model.query.count()}")
        print("demo_patient_login_pattern=demo.patient01@nalexus.com ... demo.patient15@nalexus.com")
        print("demo_assistant_login_pattern=demo.assistant01@nalexus.com ... demo.assistant02@nalexus.com")


if __name__ == "__main__":
    main()
