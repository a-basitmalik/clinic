from datetime import datetime
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "reports"
OUT.mkdir(exist_ok=True)

REPORT_DATE = "16 June 2026 (Asia/Karachi)"
PRIMARY = colors.HexColor("#0F766E")
DARK = colors.HexColor("#134E4A")
LIGHT = colors.HexColor("#ECFDF5")
GREY = colors.HexColor("#475569")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle("CoverTitle", parent=styles["Title"], fontSize=24, leading=30, alignment=TA_CENTER, textColor=DARK))
styles.add(ParagraphStyle("CoverSub", parent=styles["Normal"], fontSize=10, leading=15, alignment=TA_CENTER, textColor=GREY))
styles.add(ParagraphStyle("H1x", parent=styles["Heading1"], fontSize=16, leading=20, textColor=DARK, spaceBefore=8, spaceAfter=7))
styles.add(ParagraphStyle("H2x", parent=styles["Heading2"], fontSize=12, leading=15, textColor=PRIMARY, spaceBefore=7, spaceAfter=5))
styles.add(ParagraphStyle("Bodyx", parent=styles["BodyText"], fontSize=8.3, leading=11.2, spaceAfter=4))
styles.add(ParagraphStyle("Small", parent=styles["BodyText"], fontSize=7, leading=9))
styles.add(ParagraphStyle("Bulletx", parent=styles["BodyText"], fontSize=8, leading=10.8, leftIndent=11, firstLineIndent=-6, spaceAfter=2))


def p(text, style="Bodyx"):
    return Paragraph(text, styles[style])


def bullet(text):
    return Paragraph(f"- {text}", styles["Bulletx"])


def heading(text, level=1):
    return p(text, "H1x" if level == 1 else "H2x")


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
    canvas.line(14 * mm, 12 * mm, landscape(A4)[0] - 14 * mm, 12 * mm)
    canvas.setFont("Helvetica", 7)
    canvas.setFillColor(GREY)
    canvas.drawString(14 * mm, 7 * mm, "Clinic portal feature and login report")
    canvas.drawRightString(landscape(A4)[0] - 14 * mm, 7 * mm, f"Page {doc.page}")
    canvas.restoreState()


def table(rows, widths=None, font=6.7, repeat=1):
    cooked = [[cell if hasattr(cell, "wrap") else p(str(cell), "Small") for cell in row] for row in rows]
    t = Table(cooked, colWidths=widths, repeatRows=repeat, hAlign="LEFT")
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), DARK),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), font),
        ("LEADING", (0, 0), (-1, -1), font + 2),
        ("GRID", (0, 0), (-1, -1), 0.32, colors.HexColor("#CBD5E1")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
        ("LEFTPADDING", (0, 0), (-1, -1), 3.5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3.5),
        ("TOPPADDING", (0, 0), (-1, -1), 3.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3.5),
    ]))
    return t


PORTALS = [
    {
        "portal": "Public / Authentication",
        "role": "Unauthenticated users",
        "routes": "/, /login, /register-clinic, /change-password",
        "frontend": "screens/auth/*.dart, routes/app_routes.dart, core/services/auth_service.dart",
        "backend": "routes/auth_routes.py, routes/clinic_routes.py, services/auth_service.py, services/clinic_service.py",
        "features": "Splash, login, clinic registration, JWT session, current-user lookup, password change, profile update redirects.",
    },
    {
        "portal": "Super Admin",
        "role": "super_admin",
        "routes": "/super-admin, /super-admin/clinics, /super-admin/pending, /super-admin/stats, /super-admin/revenue, /super-admin/subscriptions, /reports/payments",
        "frontend": "screens/super_admin/*.dart, core/services/super_admin_service.dart",
        "backend": "routes/super_admin_routes.py, routes/clinic_routes.py, routes/subscription_routes.py, routes/payment_routes.py, routes/report_routes.py",
        "features": "System dashboard, all clinics, clinic detail, pending approvals, approve/suspend/reactivate clinic, system statistics, revenue breakdown, payment report, subscription plan CRUD, assign plan to clinic.",
    },
    {
        "portal": "Clinic Admin",
        "role": "clinic_admin",
        "routes": "/clinic-admin, /clinic-admin/doctors, /departments, /receptionists, /pharmacy-users, /patients, /appointments, /revenue, /reports, /settings",
        "frontend": "screens/clinic_admin/*.dart, core/services/clinic_admin_service.dart",
        "backend": "routes/clinic_admin_routes.py, doctor_routes.py, department_routes.py, receptionist_routes.py, patient_routes.py, appointment_routes.py, pharmacy_routes.py, report_routes.py, clinic_routes.py",
        "features": "Clinic dashboard, doctor/department/receptionist/pharmacy-user management, patient and appointment administration, clinic revenue, reports hub, clinic settings update.",
    },
    {
        "portal": "Doctor",
        "role": "doctor",
        "routes": "/doctor, /doctor/queue, /doctor/schedule, /doctor/disease-risk, /prescriptions, /doctor/earnings, /reports/doctor-revenue, /doctor/assistants",
        "frontend": "screens/doctor/*.dart, core/services/doctor_service.dart, core/services/clinical_ai_service.dart",
        "backend": "routes/doctor_routes.py, prescription_routes.py, assistant_routes.py, clinical_ai_routes.py, services/clinical_ai_service.py, services/disease_risk_service.py",
        "features": "Doctor dashboard, appointment queue, start/complete consultation, patient profile, prescriptions, assistant management, earnings, schedule, Clinical AI consultation support, scikit-learn disease risk demos.",
    },
    {
        "portal": "Assistant",
        "role": "assistant",
        "routes": "/assistant, /assistant/queue",
        "frontend": "screens/assistant/*.dart, core/services/assistant_service.dart where present",
        "backend": "routes/assistant_routes.py, services/assistant_service.py",
        "features": "Assistant dashboard, doctor queue support, call next patient, add vitals, upload report URL, prepare symptom draft, view patient history when permitted.",
    },
    {
        "portal": "Receptionist",
        "role": "receptionist",
        "routes": "/receptionist, /receptionist/patients, /receptionist/queue, /book-appointment, /billing, /receipts, /reports/appointments",
        "frontend": "screens/receptionist/*.dart, core/services/receptionist_service.dart where present",
        "backend": "routes/receptionist_routes.py, patient_routes.py, appointment_routes.py, payment_routes.py, report_routes.py",
        "features": "Reception dashboard, patient registration/list/detail/history, token queue, appointment booking/reschedule/cancel, consultation billing, receipts, appointment report.",
    },
    {
        "portal": "Pharmacy",
        "role": "pharmacy",
        "routes": "/pharmacy, /pharmacy/inventory, /pharmacy/orders, /pharmacy/sales, /low-stock, /expiry-alerts, /pharmacy/reports, /reports/pharmacy-sales",
        "frontend": "screens/pharmacy/*.dart, core/services/pharmacy_service.dart where present",
        "backend": "routes/pharmacy_routes.py, services/pharmacy_service.py, report_routes.py",
        "features": "Pharmacy dashboard, medicine inventory CRUD, low-stock/expired/expiring lists, prescription orders, sale creation, invoice screen, sales list, pharmacy reports.",
    },
    {
        "portal": "Patient",
        "role": "patient",
        "routes": "/patient, /patient/doctors, /patient/appointments, /patient/prescriptions, /patient/medical-records, /patient/bills",
        "frontend": "screens/patient/*.dart",
        "backend": "patient-visible routes in doctor/prescription/payment/patient services, role guards in decorators.py",
        "features": "Read-only patient dashboard, doctors, appointments, prescriptions, medical records, bills. Production currently has no patient login account.",
    },
    {
        "portal": "Reports Shared Module",
        "role": "super_admin, clinic_admin, doctor, receptionist, pharmacy",
        "routes": "/reports/clinic-revenue, /doctor-revenue, /pharmacy-sales, /patient-visits, /appointments, /payments",
        "frontend": "screens/reports/*.dart, core/widgets/export_button.dart, core/widgets/simple_chart_placeholder.dart",
        "backend": "routes/report_routes.py, services/report_service.py, payment_routes.py",
        "features": "Filtered operational/finance reports, proportional chart display, JSON/CSV/PDF export from the frontend.",
    },
]


LOGINS = [
    ["Portal", "Name", "Email / username", "Role", "Status", "Clinic", "Password status"],
    ["Super Admin", "Super Admin", "admin@nalexustechnologies.com", "super_admin", "active", "System", "Must change password = True"],
    ["Super Admin", "Super Admin", "superadmin@clinic.com", "super_admin", "active", "System", "Password not readable from DB"],
    ["Clinic Admin", "Zainab Touseef", "alpha@nalexus.com", "clinic_admin", "active", "Alpha", "Password not readable from DB"],
    ["Doctor", "Zainab", "zainab@nalexus.com", "doctor", "active", "Alpha", "Password not readable from DB"],
    ["Doctor", "Abdul Basit", "basit@nalexus.com", "doctor", "active", "Alpha", "Password not readable from DB"],
    ["Receptionist", "Zoha Touseed", "zoha@nalexus.com", "receptionist", "active", "Alpha", "Password not readable from DB"],
    ["Pharmacy", "Arfa Noor", "arfa@nalexus.com", "pharmacy", "active", "Alpha", "Password not readable from DB"],
    ["Assistant", "No production account", "-", "assistant", "-", "-", "Create from doctor/clinic workflow"],
    ["Patient", "No production account", "-", "patient", "-", "-", "Create/link patient portal account first"],
]


SCIKIT = [
    ["Model", "Algorithm", "Demo accuracy", "Implemented at", "Portal"],
    ["Diabetes risk", "LogisticRegression", "88.9%", "services/disease_risk_service.py; /api/clinical-ai/risk-predict/diabetes", "Doctor"],
    ["Heart disease risk", "RandomForestClassifier", "85.5%", "services/disease_risk_service.py; /api/clinical-ai/risk-predict/heart_disease", "Doctor"],
    ["Stroke risk", "DecisionTreeClassifier", "79.1%", "services/disease_risk_service.py; /api/clinical-ai/risk-predict/stroke", "Doctor"],
    ["Breast cancer screening risk", "RandomForestClassifier", "93.0%", "services/disease_risk_service.py; /api/clinical-ai/risk-predict/breast_cancer", "Doctor"],
]


def build():
    story = [
        Spacer(1, 28 * mm),
        p("Clinic Application Portal Feature and Login Report", "CoverTitle"),
        p("Portal-wise features, implementation locations, live deployment notes, and production login accounts", "CoverSub"),
        Spacer(1, 14 * mm),
        table([
            ["Item", "Value"],
            ["Report date", REPORT_DATE],
            ["Current live domain requested", "https://restaurant.nalexustechnologies.com"],
            ["Clinic API base used by app", "https://clinic.nalexustechnologies.com/api"],
            ["Production clinic", "Alpha, approved, multi_doctor, Lahore"],
            ["Security note", "Passwords and password hashes are intentionally not included. Use password reset/change flows for access."],
        ], [42 * mm, 188 * mm]),
        PageBreak(),
        heading("Executive Summary"),
        bullet("The same Flutter web app has been released on restaurant.nalexustechnologies.com and currently points to the clinic production API."),
        bullet("The app implements role-based portals for Super Admin, Clinic Admin, Doctor, Assistant, Receptionist, Pharmacy, and Patient."),
        bullet("Production currently has login accounts for Super Admin, Clinic Admin, Doctor, Receptionist, and Pharmacy. Assistant and Patient portal code exists, but no production login account exists for those roles yet."),
        bullet("Clinical AI is implemented in the Doctor portal. OpenAI supports consultation drafting/summaries, and scikit-learn supports educational disease-risk demos."),
        bullet("Reports and exports are available through shared report screens and role-specific report navigation."),
        heading("Portal Login Accounts"),
        p("These are production application accounts observed in the database. Passwords are not recoverable because the application stores password hashes only."),
        table(LOGINS, [30 * mm, 35 * mm, 52 * mm, 28 * mm, 22 * mm, 28 * mm, 45 * mm]),
        PageBreak(),
        heading("Portal-wise Feature Map"),
    ]
    rows = [["Portal", "Role", "Routes / screens", "Implemented frontend", "Implemented backend", "Features"]]
    for item in PORTALS:
        rows.append([item["portal"], item["role"], item["routes"], item["frontend"], item["backend"], item["features"]])
    story += [table(rows, [29 * mm, 24 * mm, 48 * mm, 48 * mm, 52 * mm, 54 * mm], font=6.2), PageBreak()]

    story += [
        heading("AI and Disease Prediction Features"),
        table(SCIKIT, [45 * mm, 38 * mm, 26 * mm, 95 * mm, 28 * mm]),
        Spacer(1, 4 * mm),
        bullet("Clinical AI consultation support is implemented at frontend core/services/clinical_ai_service.dart and screens/doctor/consultation_screen.dart."),
        bullet("OpenAI provider/model configuration is server-side; the frontend never receives provider API keys."),
        bullet("Disease prediction demos are educational screening tools only. They are not validated diagnostic models and must not replace clinician judgment."),
        bullet("Doctor-only endpoints: GET /api/clinical-ai/risk-models and POST /api/clinical-ai/risk-predict/<model_key>."),
        heading("Backend Route Groups"),
        table([
            ["Area", "Route file", "Purpose"],
            ["Authentication/profile", "auth_routes.py", "Login, current user, refresh/logout, change password, profile update"],
            ["Clinic onboarding/settings", "clinic_routes.py", "Clinic registration, clinic detail/update, approval actions"],
            ["Super admin", "super_admin_routes.py", "System dashboard, pending clinics, stats, revenue"],
            ["Clinic admin", "clinic_admin_routes.py", "Clinic dashboard and admin summaries"],
            ["Staff management", "doctor_routes.py, receptionist_routes.py, department_routes.py", "Doctor, receptionist, pharmacy user, and department operations"],
            ["Clinical workflow", "patient_routes.py, appointment_routes.py, prescription_routes.py, assistant_routes.py", "Patients, appointments, prescriptions, assistants, vitals, reports, drafts"],
            ["Finance/pharmacy", "payment_routes.py, pharmacy_routes.py", "Payments, receipts, inventory, sales, pharmacy orders"],
            ["Reports", "report_routes.py", "Revenue, visits, appointment, pharmacy, payment reports"],
            ["AI", "clinical_ai_routes.py", "OpenAI clinical assistant endpoints and scikit-learn disease risk endpoints"],
            ["Audit/subscription", "audit_routes.py, subscription_routes.py", "Audit log listing, subscription plan CRUD, clinic assignment"],
        ], [42 * mm, 70 * mm, 118 * mm]),
        PageBreak(),
        heading("Deployment Notes"),
        table([
            ["Item", "Current value"],
            ["Web app released to", "https://restaurant.nalexustechnologies.com"],
            ["Restaurant Nginx root", "/var/www/restaurant.nalexustechnologies.com"],
            ["Previous restaurant site backup", "/root/restaurant-site-backups/20260616_033006/site"],
            ["Clinic backend service", "clinic-backend.service, Gunicorn on 127.0.0.1:5110"],
            ["Database", "MySQL/Percona bound to localhost"],
            ["CORS", "Production API CORS currently allows clinic.nalexustechnologies.com"],
            ["Important note", "Because the app build uses the clinic API base, restaurant.nalexustechnologies.com may need to be added to CORS if browsers block API calls from that domain."],
        ], [58 * mm, 172 * mm]),
        heading("Portal Coverage Summary"),
        table([
            ["Portal", "Implemented?", "Production login?", "Main remaining setup"],
            ["Super Admin", "Yes", "Yes", "Use/reset password as needed"],
            ["Clinic Admin", "Yes", "Yes", "Complete live data acceptance testing"],
            ["Doctor", "Yes", "Yes", "Create real patients/appointments for clinical testing"],
            ["Assistant", "Yes", "No", "Create assistant account and assign permissions"],
            ["Receptionist", "Yes", "Yes", "Create patients/appointments/payments for testing"],
            ["Pharmacy", "Yes", "Yes", "Add inventory and prescription/sale test data"],
            ["Patient", "Read-only portal implemented", "No", "Link/create patient user accounts"],
        ], [42 * mm, 38 * mm, 38 * mm, 112 * mm]),
        heading("Password Handling"),
        p("The database stores password hashes, not plaintext passwords. This report therefore lists login usernames/emails and account status only. If a password is unknown, use the application password-change/reset/admin workflow rather than attempting to retrieve it from the database."),
    ]
    path = OUT / "clinic_portal_features_and_logins.pdf"
    doc = SimpleDocTemplate(
        str(path),
        pagesize=landscape(A4),
        rightMargin=12 * mm,
        leftMargin=12 * mm,
        topMargin=13 * mm,
        bottomMargin=16 * mm,
        title="Clinic Portal Features and Logins",
        author="Codex",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    return path


if __name__ == "__main__":
    print(build())
