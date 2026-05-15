# Import order matters: tables with no cross-model deps first,
# then progressively dependent tables, so SQLAlchemy's mapper
# resolves all string-based relationship references at startup.

from .subscription import SubscriptionPlan, ClinicSubscription
from .clinic import Clinic
from .user import User
from .department import Department
from .doctor import Doctor
from .assistant import Assistant
from .patient import Patient
from .appointment import Appointment
from .prescription import Prescription, PrescriptionMedicine
from .prescription_lab_test import PrescriptionLabTest
from .pharmacy import PharmacyItem, PharmacySale, PharmacySaleItem
from .payment import Payment
from .patient_vitals import PatientVitals
from .patient_report import PatientReport
from .consultation_draft import ConsultationDraft
from .audit_log import AuditLog

__all__ = [
    "SubscriptionPlan",
    "ClinicSubscription",
    "Clinic",
    "User",
    "Department",
    "Doctor",
    "Assistant",
    "Patient",
    "Appointment",
    "Prescription",
    "PrescriptionMedicine",
    "PrescriptionLabTest",
    "PharmacyItem",
    "PharmacySale",
    "PharmacySaleItem",
    "Payment",
    "PatientVitals",
    "PatientReport",
    "ConsultationDraft",
    "AuditLog",
]
