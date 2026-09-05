import unittest

from flask_jwt_extended import create_access_token

from app import create_app
from app.extensions import db
from app.models.clinic import Clinic
from app.models.appointment import Appointment
from app.models.audit_log import AuditLog
from app.models.doctor import Doctor
from app.models.patient import Patient
from app.models.user import User
from app.services.payment_service import PaymentService
from app.services.subscription_service import SubscriptionService
from app.utils.password_utils import hash_password


class RegressionTests(unittest.TestCase):
    def setUp(self):
        self.app = create_app("testing")
        self.ctx = self.app.app_context()
        self.ctx.push()
        db.create_all()
        self.clinic = Clinic(
            clinic_name="Test Clinic",
            owner_name="Owner",
            email="clinic@example.com",
            phone="03000000000",
            clinic_type="single_doctor",
            status="approved",
        )
        db.session.add(self.clinic)
        db.session.flush()
        self.user = User(
            name="Admin",
            email="admin@example.com",
            password_hash=hash_password("OldPass1"),
            role="clinic_admin",
            clinic_id=self.clinic.id,
            status="active",
            must_change_password=True,
        )
        self.patient = Patient(
            clinic_id=self.clinic.id,
            patient_code="P-1",
            name="Patient",
            phone="03000000001",
        )
        db.session.add_all([self.user, self.patient])
        db.session.commit()

    def tearDown(self):
        db.session.remove()
        db.drop_all()
        self.ctx.pop()

    def token(self):
        return create_access_token(
            identity=str(self.user.id),
            additional_claims={"role": self.user.role, "clinic_id": self.clinic.id},
        )

    def test_payment_accepts_frontend_aliases(self):
        payment = PaymentService.create(
            self.clinic.id,
            self.user.id,
            {
                "patient_id": self.patient.id,
                "payment_type": "consultation",
                "amount": 1000,
                "paid_amount": 400,
                "payment_method": "card",
                "status": "partial",
            },
        )
        self.assertEqual(float(payment.amount), 400)
        self.assertEqual(payment.method, "card")
        self.assertEqual(payment.status, "paid")

    def test_consultation_payments_update_appointment_balance(self):
        doctor = Doctor(
            clinic_id=self.clinic.id,
            name="Doctor",
            email="doctor@example.com",
            phone="03000000003",
            consultation_fee=1000,
        )
        db.session.add(doctor)
        db.session.flush()
        appointment = Appointment(
            clinic_id=self.clinic.id,
            doctor_id=doctor.id,
            patient_id=self.patient.id,
            appointment_date=__import__("datetime").date.today(),
            appointment_time=__import__("datetime").datetime.now().time(),
            token_number=1,
            fee=1000,
        )
        db.session.add(appointment)
        db.session.commit()

        PaymentService.create(
            self.clinic.id,
            self.user.id,
            {
                "patient_id": self.patient.id,
                "appointment_id": appointment.id,
                "payment_type": "consultation",
                "amount": 400,
            },
        )
        self.assertEqual(Appointment.query.get(appointment.id).payment_status, "partial")
        PaymentService.create(
            self.clinic.id,
            self.user.id,
            {
                "patient_id": self.patient.id,
                "appointment_id": appointment.id,
                "payment_type": "consultation",
                "amount": 600,
            },
        )
        self.assertEqual(Appointment.query.get(appointment.id).payment_status, "paid")

    def test_change_password_uses_old_password_contract(self):
        response = self.app.test_client().post(
            "/api/auth/change-password",
            headers={"Authorization": f"Bearer {self.token()}"},
            json={"old_password": "OldPass1", "new_password": "NewPass1"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(User.query.get(self.user.id).must_change_password)

    def test_profile_update_route(self):
        response = self.app.test_client().put(
            "/api/auth/profile",
            headers={"Authorization": f"Bearer {self.token()}"},
            json={"name": "Updated Admin", "email": "updated@example.com", "phone": "03000000002"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json()["data"]["user"]["name"], "Updated Admin")

    def test_subscription_plan_and_assignment(self):
        plan = SubscriptionService.create_plan(
            {"name": "Pro", "price": 5000, "duration_days": 30, "max_doctors": 5}
        )
        subscription = SubscriptionService.assign(self.clinic.id, {"plan_id": plan.id})
        self.assertEqual(subscription.plan_id, plan.id)
        self.assertEqual(Clinic.query.get(self.clinic.id).subscription_plan_id, plan.id)

    def test_clinic_admin_audit_log_is_scoped_to_own_clinic(self):
        other = Clinic(
            clinic_name="Other Clinic",
            owner_name="Other",
            email="other@example.com",
            phone="03000000004",
            clinic_type="single_doctor",
            status="approved",
        )
        db.session.add(other)
        db.session.flush()
        db.session.add_all(
            [
                AuditLog(clinic_id=self.clinic.id, action="OWN", module="test"),
                AuditLog(clinic_id=other.id, action="OTHER", module="test"),
            ]
        )
        db.session.commit()
        response = self.app.test_client().get(
            "/api/audit-logs",
            headers={"Authorization": f"Bearer {self.token()}"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["action"] for item in response.get_json()["data"]], ["OWN"])


if __name__ == "__main__":
    unittest.main()
