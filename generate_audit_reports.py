from datetime import datetime
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "reports"
OUT.mkdir(exist_ok=True)

AUDIT_DATE = "16 June 2026 (Asia/Karachi)"
PRIMARY = colors.HexColor("#0F766E")
SECONDARY = colors.HexColor("#134E4A")
LIGHT = colors.HexColor("#E6FFFB")
RED = colors.HexColor("#B91C1C")
AMBER = colors.HexColor("#B45309")
GREEN = colors.HexColor("#047857")
GREY = colors.HexColor("#475569")

styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        name="CoverTitle",
        parent=styles["Title"],
        fontName="Helvetica-Bold",
        fontSize=24,
        leading=29,
        alignment=TA_CENTER,
        textColor=SECONDARY,
        spaceAfter=14,
    )
)
styles.add(
    ParagraphStyle(
        name="CoverSub",
        parent=styles["Normal"],
        fontSize=11,
        leading=16,
        alignment=TA_CENTER,
        textColor=GREY,
    )
)
styles.add(
    ParagraphStyle(
        name="H1x",
        parent=styles["Heading1"],
        fontName="Helvetica-Bold",
        fontSize=17,
        leading=21,
        textColor=SECONDARY,
        spaceBefore=10,
        spaceAfter=8,
    )
)
styles.add(
    ParagraphStyle(
        name="H2x",
        parent=styles["Heading2"],
        fontName="Helvetica-Bold",
        fontSize=12,
        leading=15,
        textColor=PRIMARY,
        spaceBefore=8,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        name="Bodyx",
        parent=styles["BodyText"],
        fontSize=8.7,
        leading=12,
        spaceAfter=5,
    )
)
styles.add(
    ParagraphStyle(
        name="Small",
        parent=styles["BodyText"],
        fontSize=7.2,
        leading=9.2,
    )
)
styles.add(
    ParagraphStyle(
        name="Bulletx",
        parent=styles["BodyText"],
        fontSize=8.5,
        leading=11.5,
        leftIndent=12,
        firstLineIndent=-7,
        bulletIndent=3,
        spaceAfter=3,
    )
)


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
    canvas.line(18 * mm, 14 * mm, A4[0] - 18 * mm, 14 * mm)
    canvas.setFont("Helvetica", 7)
    canvas.setFillColor(GREY)
    canvas.drawString(18 * mm, 9 * mm, "Clinic Management System audit")
    canvas.drawRightString(A4[0] - 18 * mm, 9 * mm, f"Page {doc.page}")
    canvas.restoreState()


def p(text, style="Bodyx"):
    return Paragraph(text, styles[style])


def bullet(text):
    return Paragraph(f"- {text}", styles["Bulletx"])


def heading(text, level=1):
    return p(text, "H1x" if level == 1 else "H2x")


def table(rows, widths=None, font=7.1, repeat=1):
    cooked = []
    for row in rows:
        cooked.append([cell if hasattr(cell, "wrap") else p(str(cell), "Small") for cell in row])
    t = Table(cooked, colWidths=widths, repeatRows=repeat, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), SECONDARY),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), font),
                ("LEADING", (0, 0), (-1, -1), font + 2),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CBD5E1")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return t


def cover(title, subtitle):
    return [
        Spacer(1, 45 * mm),
        p(title, "CoverTitle"),
        p(subtitle, "CoverSub"),
        Spacer(1, 18 * mm),
        table(
            [
                ["Audit item", "Value"],
                ["Application", "Clinic Management System (Flutter web + Flask/MySQL API)"],
                ["Production URL", "https://clinic.nalexustechnologies.com"],
                ["Audit date", AUDIT_DATE],
                ["Scope", "Local repository, deployed server, live public endpoint, database state, and static code review"],
                ["Security note", "Passwords, API keys, database credentials, and secret values are intentionally excluded."],
            ],
            [42 * mm, 120 * mm],
        ),
        PageBreak(),
    ]


def build_functionality_report():
    story = cover(
        "Clinic Application Functionality and AI Integration Audit",
        "What works, what is partial, what is absent, and where Clinical AI is actually deployed",
    )
    story += [
        heading("Executive Summary"),
        p(
            "The application has a broad and coherent clinic-management foundation: role-based authentication, "
            "clinic onboarding and approval, staff management, patient registration, appointments and token queues, "
            "doctor consultations, prescriptions, assistant workflows, pharmacy inventory and sales, payments, "
            "patient read-only portals, and multiple reports. The production API and database are healthy."
        ),
        p(
            "<b>Production is not fully ready for normal use yet.</b> The live database contains one clinic, two "
            "doctors, seven users, and subscription-plan seed data, but no patients, appointments, payments, "
            "prescriptions, vitals, reports, pharmacy stock, or sales. Therefore most workflows are implemented but "
            "have not been proven end-to-end with production data."
        ),
        p(
            "<b>Clinical AI is deployed to the live doctor workflow.</b> The production backend has the Clinical AI "
            "routes, an OpenAI API key, and model <b>gpt-5.2</b>. The verified release Flutter bundle containing the "
            "Clinical AI consultation interface is now served by Nginx."
        ),
        heading("Audit Evidence"),
        table(
            [
                ["Check", "Observed result", "Conclusion"],
                ["Public health endpoint", "HTTP 200; API=ok; database=ok", "Production API and DB connection are live"],
                ["Public web root", "HTTP 200 text/html", "Flutter web app is live"],
                ["Backend service", "clinic-backend.service active; Gunicorn on 127.0.0.1:5110", "Backend process is running"],
                ["Core services", "Nginx and MySQL active", "Required production services are running"],
                ["Production AI config", "provider=openai; model=gpt-5.2; API key present", "OpenAI provider is configured"],
                ["Production AI routes", "4 /api/clinical-ai routes registered", "AI backend is deployed"],
                ["Live web bundle", "Clinical AI interface present in /home/nalexus/clinic/frontend/main.dart.js", "AI UI is deployed on the active website"],
                ["Production security", "MySQL and Gunicorn bound to localhost; UFW rules removed for 3306/5110", "Database and backend are not publicly exposed"],
                ["Production CORS", "Production domain allowed; foreign test origin rejected", "Browser API access is origin-restricted"],
                ["Local Flutter analysis", "No errors/warnings; 20 style-level info notices", "Static analysis has no blocking issues"],
                ["Local Flutter tests", "1 boot test passed", "Only minimal automated UI coverage exists"],
                ["Local backend compile/tests", "Python compile passed; 128 routes; 6 regression tests passed", "Backend imports, routes, and corrected contracts succeed"],
                ["Production warnings", "No warning-level service logs in previous 7 days", "No recent service warning evidence"],
            ],
            [38 * mm, 72 * mm, 60 * mm],
        ),
        Spacer(1, 5 * mm),
        heading("Production Data State"),
        table(
            [
                ["Entity", "Rows", "Entity", "Rows"],
                ["Clinics", "1", "Users", "7"],
                ["Departments", "2", "Doctors", "2"],
                ["Subscription plans", "3", "Clinic subscriptions", "0"],
                ["Patients", "0", "Appointments", "0"],
                ["Payments", "0", "Prescriptions", "0"],
                ["Prescription medicines", "0", "Prescription lab tests", "0"],
                ["Patient vitals", "0", "Patient reports", "0"],
                ["Consultation drafts", "0", "Assistants", "0"],
                ["Pharmacy items", "0", "Pharmacy sales/items", "0 / 0"],
                ["Audit logs", "0", "", ""],
            ],
            [44 * mm, 18 * mm, 55 * mm, 18 * mm],
        ),
        p(
            "Interpretation: the system is deployed, but the absence of operational records means claims of complete "
            "production functionality should remain provisional until a controlled end-to-end acceptance test is run."
        ),
        PageBreak(),
        heading("Functional Module Assessment"),
    ]
    functional_rows = [
        ["Module", "Status", "What is functional", "Limitations / evidence gap"],
        ["Authentication", "Mostly functional", "Login, /me, refresh, logout, forced first-login password change, profile update, role/clinic checks", "Logout does not revoke JWT server-side"],
        ["Clinic registration", "Functional", "Multi-step clinic, doctor, receptionist, pharmacy registration; temp accounts; pending approval", "No production end-to-end test during audit; passwords shown once require operational handling"],
        ["Super admin", "Mostly functional", "Dashboard, clinics, approvals, suspension, stats, revenue, subscription plan CRUD/assignment", "No production subscription assignment acceptance test yet"],
        ["Clinic admin", "Mostly functional", "Dashboard, staff, patients, appointments, revenue, reports, clinic settings, profile", "Production end-to-end acceptance data is still absent"],
        ["Doctor", "Mostly functional", "Dashboard, queue, consultation, patient profile, prescriptions, assistants, earnings, schedule, Clinical AI", "Schedule appears informational; production has no consultations to verify"],
        ["Assistant", "Functional in code", "Queue, call next, vitals, report URL upload, symptom draft, history, prescription print data", "No production assistant records; report upload is URL-based rather than actual file storage"],
        ["Receptionist", "Mostly functional", "Dashboard, patient CRUD, appointments, queue, booking, billing, receipts, reports", "Production payment acceptance data is still absent"],
        ["Pharmacy", "Mostly functional", "Inventory CRUD, low stock, expiry alerts, prescription orders, sales, invoices, reports", "No production inventory/sales test data; no procurement/purchase-order workflow"],
        ["Patient portal", "Read-only partial", "Dashboard, doctors, appointments, prescriptions, records, bills", "No patient self-registration, appointment booking, cancellation, payment, profile update, or messaging workflow"],
        ["Reports", "Functional", "Filtered reports, proportional charts, and PDF/CSV/JSON downloads", "XLSX export is not included"],
        ["Audit logging", "Functional baseline", "Successful authenticated mutations and login are logged; scoped admin read API exists", "Before/after entity diffs and retention policy remain to be added"],
        ["Subscriptions", "Functional", "Plan CRUD, assignment API/UI, subscription records, and doctor-limit linkage", "Renewal/payment automation is not included"],
        ["Clinic settings/profile", "Functional", "Clinic settings form, validation, save API, profile screen, and update API", "Expanded branding/tax/holiday settings remain future scope"],
    ]
    story += [table(functional_rows, [30 * mm, 24 * mm, 62 * mm, 59 * mm]), PageBreak()]
    story += [
        heading("Clinical AI Audit"),
        heading("What Is Added", 2),
        table(
            [
                ["AI capability", "Backend", "Local frontend", "Live frontend"],
                ["Patient-history summary", "Implemented: POST /api/clinical-ai/patient-summary", "Used in doctor consultation screen", "Deployed"],
                ["Consultation draft", "Implemented: POST /api/clinical-ai/consultation-assist", "Used; draft can be reviewed/applied", "Deployed"],
                ["Medical entity extraction", "Implemented: POST /api/clinical-ai/extract-medical-text", "Service method exists but no user-facing screen calls it", "API deployed; no visible workflow"],
                ["Patient-friendly explanation", "Returned by AI response schema", "Displayed in consultation AI panel", "Deployed"],
                ["Red flags and questions", "Returned by AI response schema", "Displayed for doctor review", "Deployed"],
                ["Provider status", "Implemented: GET /api/clinical-ai/status", "Service method exists but not visibly used", "Backend reachable only with doctor auth"],
                ["Rule-based fallback", "Implemented for missing key/provider errors", "Consumed through same API", "Backend available"],
                ["Disease risk demos", "Implemented: GET /risk-models and POST /risk-predict/{model}", "Doctor Disease Risk Demo screen", "Deployed"],
            ],
            [42 * mm, 50 * mm, 46 * mm, 37 * mm],
        ),
        heading("scikit-learn Disease Prediction Models", 2),
        table(
            [
                ["Demo model", "Algorithm", "Demo accuracy", "Purpose"],
                ["Diabetes risk", "LogisticRegression", "88.9%", "Educational risk estimate from age, BMI, glucose, BP, and family history"],
                ["Heart disease risk", "RandomForestClassifier", "85.5%", "Educational risk estimate from cardiovascular risk-factor inputs"],
                ["Stroke risk", "DecisionTreeClassifier", "79.1%", "Educational risk estimate from age, comorbidity, glucose, BMI, and smoking inputs"],
                ["Breast cancer screening risk", "RandomForestClassifier", "93.0%", "Educational classifier using selected breast-cancer measurement features"],
            ],
            [42 * mm, 44 * mm, 28 * mm, 62 * mm],
        ),
        p(
            "Presentation line: We used scikit-learn to train disease prediction demo models on medical-style "
            "dataset features. The models predict an educational risk level based on patient inputs and report "
            "their held-out demonstration accuracy."
        ),
        heading("Model and Provider Placement", 2),
        bullet("<b>Provider:</b> OpenAI Responses API, called only from the Flask backend."),
        bullet("<b>Configured model:</b> gpt-5.2 in local defaults, documentation, and production environment."),
        bullet("<b>Backend implementation:</b> clinic_backend/app/services/clinical_ai_service.py."),
        bullet("<b>scikit-learn implementation:</b> clinic_backend/app/services/disease_risk_service.py."),
        bullet("<b>Backend routes:</b> clinic_backend/app/routes/clinical_ai_routes.py, registered in app/__init__.py."),
        bullet("<b>Frontend implementation:</b> clinic_app/lib/core/services/clinical_ai_service.dart and the doctor consultation screen."),
        bullet("<b>Production backend:</b> deployed under /home/nalexus/clinic/backend and configured with an OpenAI API key."),
        bullet("<b>Production active frontend:</b> /home/nalexus/clinic/frontend; verified release bundle contains the AI UI."),
        bullet("<b>Unused AI API:</b> extract-medical-text exists in the frontend service but has no visible screen/workflow."),
        heading("AI Areas Not Added", 2),
        bullet("No AI symptom checker or pre-appointment triage for patients."),
        bullet("No speech-to-text, ambient consultation recording, or medical transcription."),
        bullet("No document OCR or automatic interpretation of uploaded lab-report files."),
        bullet("No radiology/imaging AI, DICOM handling, or image model."),
        bullet("No autonomous diagnosis, treatment, prescribing, appointment prioritization, or emergency decision engine."),
        bullet("Disease risk models are educational screening demos only; they are not validated diagnostic models."),
        bullet("No AI audit table, prompt/version tracking, output approval record, cost tracking, or per-clinic AI controls."),
        bullet("No provider privacy/consent workflow, data-retention control, or verified BAA/compliance configuration in app code."),
        heading("AI Safety Assessment", 2),
        p(
            "The code correctly treats AI output as an editable draft and includes a clinician-review safety notice. "
            "It does not automatically save AI output as a final record. However, production readiness still requires "
            "formal privacy approval, access logging, prompt/output auditability, model/version governance, failure "
            "monitoring, and clinical validation. A configured API key alone does not prove successful live model calls; "
            "the audit could not execute a real patient-summary request because there is no production doctor test "
            "credential and no patient/appointment data."
        ),
        PageBreak(),
        heading("Confirmed Defects and Gaps"),
    ]
    defect_rows = [
        ["Previous severity", "Finding", "Resolution status", "Verification"],
        ["Critical", "Active production web bundle omitted Clinical AI UI", "Resolved", "Verified release bundle deployed to active Nginx root and contains Clinical AI UI"],
        ["High", "Standalone billing contract mismatch", "Resolved", "Canonical/legacy aliases supported; appointment partial/paid state synchronized; regression tested"],
        ["High", "Forced password-change workflow/payload mismatch", "Resolved", "Change-password screen, redirects, correct old_password payload, and API test"],
        ["High", "Profile route missing", "Resolved", "Profile screen, route, update API, validation, and API test"],
        ["Medium", "Subscription/settings placeholders", "Resolved", "Plan CRUD, clinic assignment, and clinic settings UI/API implemented"],
        ["Medium", "Audit table unused", "Resolved baseline", "Central mutation/login writes and clinic-scoped admin read endpoint implemented/tested"],
        ["Medium", "Report charts/export placeholders", "Resolved", "Proportional charts and PDF/CSV/JSON downloads implemented"],
        ["Medium", "Payment detail API missing", "Resolved", "Authorized GET /api/payments/{id} deployed"],
        ["Medium", "Patient phone UI/backend mismatch", "Resolved", "Phone is visibly required and validated"],
        ["Medium", "MySQL publicly exposed", "Resolved", "MySQL binds 127.0.0.1; UFW 3306/5110 rules removed"],
        ["Low", "CORS allowed all origins", "Resolved", "Production origin accepted and foreign test origin rejected"],
        ["Low", "Automated tests minimal", "Improved, ongoing", "6 backend regression tests and Flutter boot test pass; broader role integration tests still recommended"],
    ]
    story += [
        table(defect_rows, [22 * mm, 55 * mm, 52 * mm, 47 * mm]),
        PageBreak(),
        heading("Recommended Acceptance Test Sequence"),
        bullet("Create a dedicated non-production test clinic and accounts for every role."),
        bullet("Approve the clinic, force password changes, and verify role navigation/authorization."),
        bullet("Register a patient, book a paid and partial appointment, verify token and receipt."),
        bullet("Run assistant queue, vitals, report upload, symptom draft, and call-next flows."),
        bullet("Run doctor consultation, Clinical AI summary/draft, prescription, lab test, follow-up, and completion."),
        bullet("Stock pharmacy inventory, dispense prescription, run walk-in sale, and verify stock/payment/invoice."),
        bullet("Verify patient portal visibility and cross-clinic access denial."),
        bullet("Verify every report against database totals and export outputs."),
        bullet("Verify audit logs, backups, restoration, monitoring, rate limits, and secret rotation."),
        heading("Overall Readiness"),
        table(
            [
                ["Area", "Rating", "Reason"],
                ["Architecture", "Good foundation", "Clear Flask services/routes/models and role-based Flutter screens"],
                ["Core workflow implementation", "Mostly implemented", "Broad code coverage, but limited production records and end-to-end proof"],
                ["Clinical AI", "Deployed for controlled use", "OpenAI consultation support and scikit-learn disease risk demos deployed"],
                ["Security and compliance", "Improved baseline", "Audit writes/read API, restricted CORS, local-only database, and forced password change implemented"],
                ["Production readiness", "Controlled acceptance testing", "All identified application defects were corrected; operational/clinical acceptance and governance remain required"],
            ],
            [42 * mm, 40 * mm, 94 * mm],
        ),
        heading("Code and Server Evidence Locations"),
        bullet("Local backend: clinic_backend/app, clinic_backend/migrations/schema.sql, clinic_backend/README.md."),
        bullet("Local frontend: clinic_app/lib, especially routes, core/services, and screens."),
        bullet("Production backend: /home/nalexus/clinic/backend."),
        bullet("Production active frontend: /home/nalexus/clinic/frontend."),
        bullet("Production backend service: /etc/systemd/system/clinic-backend.service."),
    ]
    path = OUT / "clinic_functionality_and_ai_audit.pdf"
    doc = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="Clinic Functionality and AI Audit",
        author="Codex",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    return path


def field_rows():
    return [
        ["Area / record", "Data points to enter", "Required / validation / notes"],
        ["Login", "Email; password", "Both required; valid active user; clinic must be approved for non-super-admin roles"],
        ["Password change", "Current/old password; new password; confirmation (UI should add)", "New password >= 6 chars and different; frontend/backend key mismatch must be fixed"],
        ["Clinic core", "Clinic name; owner name; admin email; phone; address; city; logo", "Name, owner, email, phone required; email globally unique; logo exists in model but has no working UI"],
        ["Clinic operations", "Clinic type; number of doctors; has pharmacy; has receptionist; opening time; closing time; working days", "Type single_doctor/multi_doctor; doctor count must match; times HH:MM; closing after opening should be enforced"],
        ["Clinic status/subscription", "Status; subscription plan; approval actor/date; subscription start/end; amount paid", "Admin-controlled; plan assignment and subscription lifecycle UI/API are missing"],
        ["Doctor account/profile", "Name; email; phone; department; specialization; qualification; experience years; license number; consultation fee; available days; start/end time; status", "Name/email required; email unique; department selected/created; non-negative fee/experience recommended"],
        ["Receptionist user", "Name; email; phone; status", "Name/email required; valid unique email; temp password generated"],
        ["Pharmacy user", "Name; email; phone; status", "Name/email required; valid unique email; clinic pharmacy must be enabled"],
        ["Assistant", "Assigned doctor; name; email; phone; duties; six permission flags; status", "Doctor/name/email required; email unique; permissions control workflow endpoints"],
        ["Patient", "Name; age; gender; phone; CNIC; address; blood group; emergency contact; linked user ID", "Backend requires name and phone; phone/CNIC unique per clinic; gender male/female/other"],
        ["Appointment", "Patient; doctor; date; time; consultation type; fee; payment status; paid amount; payment method; notes", "Patient/doctor/date/time required; type new/followup/emergency; paid/partial rules enforced"],
        ["Queue/status", "Appointment status; cancel reason; reschedule date/time", "Role-restricted transitions; status waiting/sent_to_assistant/in_consultation/completed/cancelled"],
        ["Vitals", "Patient; appointment; temperature C; blood pressure; pulse; weight kg; height cm; oxygen %; notes", "Patient required; appointment optional but must match doctor/patient; numeric validation is limited"],
        ["Patient report", "Patient; appointment; report title; report type; file URL; notes", "Patient and title required; current implementation stores URL, not uploaded file"],
        ["Consultation draft", "Patient; appointment; symptoms draft; vitals summary; notes", "Assistant permission-controlled; draft supports doctor workflow"],
        ["Prescription", "Appointment; patient; symptoms; diagnosis; notes; follow-up date; medicines; lab tests", "Appointment/patient required; one prescription per appointment; doctor ownership enforced"],
        ["Prescription medicine", "Inventory medicine ID; medicine name; dosage; frequency; duration; instructions", "Medicine name required; inventory ID optional"],
        ["Prescription lab test", "Test name; instructions", "Test name required"],
        ["Inventory medicine", "Medicine name; category; batch number; expiry date; purchase price; sale price; quantity; supplier; rack; low-stock limit; status", "Name, sale price, quantity required by backend; duplicate name+batch blocked; values non-negative"],
        ["Pharmacy sale", "Patient; prescription; sale items; payment status; payment method", "Patient/prescription optional; item medicine ID and quantity required; stock must be available"],
        ["Pharmacy sale item", "Medicine ID; quantity; unit price/total derived", "Quantity positive; price and total should be server-derived"],
        ["General payment", "Patient; appointment; payment type; amount; method; status", "Type consultation/pharmacy/lab/other; amount > 0; method allowed; status paid/pending/refunded"],
        ["Reports/filters", "Start date; end date; group by; clinic/doctor/status/type/method filters; export flag", "Read-only input; validate date range and authorized scope"],
        ["Clinical AI input", "Patient ID; appointment ID; symptoms; diagnosis; notes; vitals summary; pasted medical text", "Doctor-only; patient/appointment required by task; clinician must review all outputs"],
    ]


def build_data_report():
    story = cover(
        "Clinic Application Data Entry Requirements Report",
        "Complete current data-point catalog, validation rules, and recommended missing clinical/operational fields",
    )
    story += [
        heading("Purpose"),
        p(
            "This report lists the data that users, administrators, staff, and integrations should enter into the "
            "Clinic Management System. It separates fields currently supported by the application from important "
            "data points that should be added before the system is used as a complete clinical record."
        ),
        heading("Current Application Data Points"),
        table(field_rows(), [35 * mm, 82 * mm, 59 * mm]),
        PageBreak(),
        heading("Detailed Allowed Values and Rules"),
    ]
    rules = [
        ["Field group", "Allowed values / format", "Rule"],
        ["User role", "super_admin, clinic_admin, doctor, assistant, receptionist, pharmacy, patient", "Role controls navigation and API authorization"],
        ["User status", "active, inactive, pending", "Inactive/pending users cannot use normal flows"],
        ["Clinic type", "single_doctor, multi_doctor", "Single doctor must provide exactly one doctor"],
        ["Clinic status", "pending, approved, suspended", "Non-super-admin login requires approved clinic"],
        ["Department status", "active, inactive", "Name unique within clinic"],
        ["Doctor/assistant status", "active, inactive", "Inactive staff should not be selectable"],
        ["Gender", "male, female, other", "Optional in current backend"],
        ["Blood group", "A+, A-, B+, B-, AB+, AB-, O+, O-", "Validated by UI and backend"],
        ["Date", "YYYY-MM-DD", "Backend parser format"],
        ["Time", "HH:MM, 24-hour", "Backend parser format"],
        ["Appointment type", "new, followup, emergency", "Defaults to new"],
        ["Appointment status", "waiting, sent_to_assistant, in_consultation, completed, cancelled", "Transitions restricted by role"],
        ["Appointment payment status", "unpaid, paid, partial", "Paid amount/method rules apply during booking"],
        ["Payment type", "consultation, pharmacy, lab, other", "Role-restricted when creating payments"],
        ["Payment method", "cash, card, easypaisa, jazzcash, bank", "Frontend/backend field name must be method for general payment"],
        ["General payment status", "paid, pending, refunded", "Partial appointment balances are represented by multiple paid ledger entries and appointment payment_status"],
        ["Prescription pharmacy status", "pending, processing, dispensed, cancelled", "Pharmacy order workflow"],
        ["Medicine status", "active, inactive", "Inactive items excluded from normal use"],
        ["Sale payment status", "paid, pending", "Confirm against pharmacy service before rollout"],
        ["Email", "Standard email format", "Globally unique for user accounts"],
        ["Phone/CNIC", "Text", "Patient phone and CNIC are unique within a clinic; stricter format validation should be added"],
        ["AI provider/model", "openai / gpt-5.2 currently", "Server-side only; never enter provider API keys in the browser"],
        ["Disease risk model", "diabetes, heart_disease, stroke, breast_cancer", "Doctor-only educational scikit-learn demo endpoints"],
    ]
    story += [table(rules, [42 * mm, 65 * mm, 69 * mm]), PageBreak()]
    story += [
        heading("Recommended Missing Patient and Clinical Data"),
        p(
            "The current patient model is too small for a complete longitudinal medical record. The following should "
            "be added with clear ownership, consent, retention, and access controls."
        ),
        table(
            [
                ["Category", "Recommended data points", "Priority / reason"],
                ["Patient identity", "Date of birth instead of age; preferred name; photo; marital status; occupation; language; nationality", "High: age becomes inaccurate; identity and communication needs"],
                ["Contact", "Email; multiple phones; preferred contact method; guardian/caregiver; emergency contact name/relationship", "High: current emergency contact stores phone only"],
                ["Address", "Structured street, area, city, province, postal code, country", "Medium: improves billing and reporting"],
                ["Allergies", "Substance; reaction; severity; status; date recorded; recorder", "Critical: required for safer prescribing"],
                ["Problem list", "Condition; ICD/SNOMED code; onset; status; severity; notes", "Critical: longitudinal diagnosis tracking"],
                ["Medical history", "Past illnesses; surgeries; hospitalizations; family history; social history", "High: needed for clinical decisions"],
                ["Current medication", "Medicine; dose; route; frequency; indication; start/end; adherence", "Critical: prescriptions alone do not represent current medicines"],
                ["Immunizations", "Vaccine; dose; date; manufacturer/lot; site; next due", "High for general practice"],
                ["Pregnancy/reproductive", "Pregnancy status; LMP; estimated due date; breastfeeding", "Critical where clinically applicable"],
                ["Clinical observations", "Respiratory rate; pain score; BMI; glucose; consciousness; waist; units and reference ranges", "High: current vitals are incomplete"],
                ["Encounter", "Chief complaint; history of present illness; review of systems; examination; assessment; plan; disposition", "Critical: current prescription notes are not a full encounter note"],
                ["Diagnosis coding", "Primary/secondary diagnosis; code; certainty; present-on-admission; resolved status", "High: reporting/interoperability"],
                ["Orders/results", "Lab/imaging order; specimen; result values; units; reference range; abnormal flag; status; performer; result date", "Critical: current lab tests are text-only orders"],
                ["Documents", "Actual file upload; MIME type; checksum; size; category; capture date; author; version", "High: current patient report stores only URL/title"],
                ["Referral", "Referred-to provider/facility; reason; urgency; status; appointment/result", "Medium"],
                ["Consent/privacy", "Consent type; scope; signed date; expiry; withdrawal; privacy notice acknowledgment", "Critical for clinical and AI processing"],
                ["Clinical communication", "Patient instructions; education; language; acknowledgment; secure messages", "Medium"],
            ],
            [38 * mm, 82 * mm, 56 * mm],
        ),
        PageBreak(),
        heading("Recommended Missing Operational and Financial Data"),
        table(
            [
                ["Area", "Recommended data points", "Reason"],
                ["Clinic settings", "Timezone; currency; tax ID; registration/license; invoice prefix; receipt footer; cancellation policy; holidays; branding", "Basic clinic identity/hours/days settings are implemented; these expanded fields remain recommended"],
                ["Staff", "Address; national ID; designation; employment dates; shift; payroll/rate; credentials; credential expiry; emergency contact", "Required for complete staff administration"],
                ["Doctor scheduling", "Slot duration; breaks; leave; holidays; capacity; appointment modes; location/room", "Current availability is only days and start/end time"],
                ["Appointments", "Booking source; reason for visit; priority; check-in/out; no-show; cancellation actor/time; reminder status", "Needed for operations and analytics"],
                ["Payments", "Invoice number; billed amount; discount; tax; balance; payer; transaction/reference ID; refund reason; notes; reconciliation status", "Current Payment ledger is minimal; billing contract and appointment balance synchronization are implemented"],
                ["Insurance", "Payer; member/policy ID; coverage; authorization; claim; status; approved/denied amount", "Absent"],
                ["Pharmacy purchasing", "Supplier contact; purchase order; goods receipt; purchase invoice; tax; discount; batch received quantity; return", "No procurement workflow"],
                ["Inventory safety", "Manufacturer; generic/brand; strength; form; barcode; reorder point/quantity; controlled-drug flag; storage condition", "Current inventory fields are basic"],
                ["Subscription", "Assigned plan; billing cycle; start/end; renewal; status; amount; payment reference; limits/usage", "Plan CRUD and assignment exist; renewal/payment automation and usage metering remain recommended"],
                ["Audit/security", "Actor; action; entity type/id; before/after values; IP; user agent; timestamp; correlation ID; AI provider/model/prompt version", "Baseline actor/action/module/IP logging exists; entity diffs, correlation IDs, and AI-specific traceability remain recommended"],
                ["Notifications", "Recipient; channel; template; scheduled/sent time; delivery/read status; failure reason", "No reminder/notification tracking"],
            ],
            [38 * mm, 82 * mm, 56 * mm],
        ),
        heading("Clinical AI Data Requirements and Governance"),
        table(
            [
                ["Data point", "Current state", "What should be entered/stored"],
                ["AI request context", "Patient history, appointment, working note, vitals summary", "Only minimum necessary data; avoid unnecessary identifiers"],
                ["AI provider/model", "OpenAI / gpt-5.2 configured", "Provider, exact model/version, request timestamp, feature used"],
                ["scikit-learn model", "Four educational demos implemented", "Model key, algorithm, feature schema, demo accuracy, risk probability, and safety notice"],
                ["Prompt/version", "Embedded in code only", "Prompt template ID/version and safety-policy version"],
                ["Output", "Returned to UI; not auto-saved", "Store only after clinician approval, clearly marked as AI-assisted"],
                ["Approval", "Doctor applies draft manually", "Approver user, approval time, edits/diff, final disposition"],
                ["Failure/fallback", "Rule-based fallback and provider_error returned", "Provider latency, status, fallback reason; never log raw PHI carelessly"],
                ["Consent/legal basis", "Not represented", "Clinic/provider agreement, patient consent/legal basis, retention rule"],
                ["Usage/cost", "Not represented", "Token/usage estimate and per-clinic cost/limits where permitted"],
            ],
            [46 * mm, 58 * mm, 72 * mm],
        ),
        PageBreak(),
        heading("Data Quality and Validation Corrections"),
        bullet("Patient phone is visibly required in the UI and backend; add jurisdiction-specific normalization if required."),
        bullet("Use date of birth and calculate age; do not store age as the primary demographic value."),
        bullet("Validate phone, CNIC, blood group, vital ranges, dosage, duration, and clinical units consistently."),
        bullet("Change-password payload and forced first-login password workflow are aligned and implemented."),
        bullet("Standalone billing payload, payment model response mapping, and appointment balance synchronization are aligned."),
        bullet("Relational checks exist for appointment patient/doctor/clinic, report appointment/patient, and sale prescription/patient."),
        bullet("Server-derived pharmacy prices and payment balance updates are implemented; add reconciliation controls as finance scope grows."),
        bullet("Baseline mutation audit history is implemented; add before/after values and explicit record ownership fields where needed."),
        bullet("Use actual secure file upload/storage rather than arbitrary report URLs."),
        bullet("Define data retention, deletion, backup, restoration, and cross-clinic isolation policies."),
        heading("Minimum Dataset Before Go-Live Testing"),
        table(
            [
                ["Dataset", "Minimum test entries"],
                ["Organization", "1 approved clinic with settings and an assigned subscription plan"],
                ["Users", "1 account for each role; all temporary passwords changed"],
                ["Doctors/departments", "At least 2 doctors in 2 departments with availability"],
                ["Patients", "At least 5 synthetic patients covering demographics, allergies, histories, and contact variations"],
                ["Appointments", "New, follow-up, emergency, paid, partial, cancelled, rescheduled, and completed examples"],
                ["Clinical", "Vitals, reports, prescriptions with medicines/lab tests, follow-ups, and doctor notes"],
                ["Pharmacy", "Active, low-stock, expiring, expired, duplicate-batch, prescription, and walk-in sale examples"],
                ["Finance", "Paid, pending, partial/booked, refunded, consultation, pharmacy, lab, and other payments"],
                ["AI", "Synthetic patient summary, consultation draft, provider failure/fallback, red-flag, and clinician-rejection examples"],
                ["Security", "Cross-clinic denial, role denial, inactive account, suspended clinic, expired token, and audit-log examples"],
            ],
            [54 * mm, 122 * mm],
        ),
        heading("Source of Truth"),
        p(
            "Current fields and rules were derived from the SQLAlchemy models, Flask services/routes/validators, "
            "Flutter forms/services, schema.sql, and the deployed production database. Recommended missing fields "
            "are requirements for a more complete operational and clinical system; they are not currently implemented."
        ),
    ]
    path = OUT / "clinic_data_entry_requirements.pdf"
    doc = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="Clinic Data Entry Requirements",
        author="Codex",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    return path


if __name__ == "__main__":
    first = build_functionality_report()
    second = build_data_report()
    print(first)
    print(second)
