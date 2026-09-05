from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parent
OUT = ROOT / "reports"
OUT.mkdir(exist_ok=True)

REPORT_DATE = "16 June 2026"
DARK = colors.HexColor("#134E4A")
PRIMARY = colors.HexColor("#0F766E")
GREY = colors.HexColor("#475569")

styles = getSampleStyleSheet()
styles.add(
    ParagraphStyle(
        "CoverTitle",
        parent=styles["Title"],
        fontSize=24,
        leading=30,
        alignment=TA_CENTER,
        textColor=DARK,
    )
)
styles.add(
    ParagraphStyle(
        "CoverSub",
        parent=styles["Normal"],
        fontSize=11,
        leading=16,
        alignment=TA_CENTER,
        textColor=GREY,
    )
)
styles.add(
    ParagraphStyle(
        "H1x",
        parent=styles["Heading1"],
        fontSize=17,
        leading=21,
        textColor=DARK,
        spaceBefore=10,
        spaceAfter=7,
    )
)
styles.add(
    ParagraphStyle(
        "H2x",
        parent=styles["Heading2"],
        fontSize=12,
        leading=15,
        textColor=PRIMARY,
        spaceBefore=7,
        spaceAfter=4,
    )
)
styles.add(ParagraphStyle("Bodyx", parent=styles["BodyText"], fontSize=9, leading=12.5, spaceAfter=5))
styles.add(ParagraphStyle("Small", parent=styles["BodyText"], fontSize=7.4, leading=9.6))
styles.add(
    ParagraphStyle(
        "Bulletx",
        parent=styles["BodyText"],
        fontSize=8.7,
        leading=11.8,
        leftIndent=12,
        firstLineIndent=-7,
        spaceAfter=3,
    )
)


def p(text, style="Bodyx"):
    return Paragraph(text, styles[style])


def heading(text, level=1):
    return p(text, "H1x" if level == 1 else "H2x")


def bullet(text):
    return Paragraph(f"- {text}", styles["Bulletx"])


def table(rows, widths=None, font=7.2):
    cooked = [[cell if hasattr(cell, "wrap") else p(str(cell), "Small") for cell in row] for row in rows]
    t = Table(cooked, colWidths=widths, repeatRows=1, hAlign="LEFT")
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), DARK),
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


def footer(canvas, doc):
    canvas.saveState()
    canvas.setStrokeColor(colors.HexColor("#CBD5E1"))
    canvas.line(16 * mm, 13 * mm, A4[0] - 16 * mm, 13 * mm)
    canvas.setFont("Helvetica", 7)
    canvas.setFillColor(GREY)
    canvas.drawString(16 * mm, 8 * mm, "Clinic system plain-language feature report")
    canvas.drawRightString(A4[0] - 16 * mm, 8 * mm, f"Page {doc.page}")
    canvas.restoreState()


def build():
    story = [
        Spacer(1, 38 * mm),
        p("Clinic Management System", "CoverTitle"),
        p("Plain-Language Feature Report for Non-Technical Readers", "CoverSub"),
        Spacer(1, 14 * mm),
        table(
            [
                ["Item", "Details"],
                ["Report date", REPORT_DATE],
                ["Purpose", "Explain what the system does in simple business and clinic-operation language."],
                ["Live website", "restaurant.nalexustechnologies.com currently serves this app build."],
                ["Important note", "This report explains features and usage. It does not include passwords or private technical secrets."],
            ],
            [38 * mm, 128 * mm],
        ),
        PageBreak(),
        heading("1. Simple Overview"),
        p(
            "This application is a clinic management system. It is designed to help a clinic manage daily work from "
            "one place: clinic setup, doctors, reception, patients, appointments, billing, pharmacy, prescriptions, "
            "reports, and selected AI-assisted tools for doctors."
        ),
        p(
            "Different staff members see different portals. A receptionist sees patient booking and billing tools. "
            "A doctor sees patient queues, consultation tools, prescriptions, and AI support. A pharmacy user sees "
            "inventory and medicine sales. A clinic owner or administrator sees management and reporting tools."
        ),
        heading("2. Who Uses the System"),
        table(
            [
                ["User type", "What they mainly do"],
                ["Super Admin", "Manages the full platform, all clinics, subscriptions, approvals, and overall system reports."],
                ["Clinic Admin", "Manages one clinic: staff, doctors, departments, patients, appointments, reports, and clinic settings."],
                ["Doctor", "Handles patient consultations, prescriptions, patient records, daily queue, earnings, and AI-assisted tools."],
                ["Assistant", "Supports a doctor by managing queue tasks, adding vitals, uploading reports, and preparing draft notes."],
                ["Receptionist", "Registers patients, books appointments, manages tokens/queue, collects consultation payments, and prints receipts."],
                ["Pharmacy", "Manages medicines, stock, expiry alerts, prescription orders, sales, and pharmacy reports."],
                ["Patient", "Views their own appointments, doctors, prescriptions, medical records, and bills."],
            ],
            [38 * mm, 128 * mm],
        ),
        PageBreak(),
        heading("3. Super Admin Portal"),
        p("The Super Admin portal is for the person or company operating the whole platform."),
        bullet("View the total number of clinics, active clinics, pending clinics, doctors, patients, and system revenue."),
        bullet("See all registered clinics in one place."),
        bullet("Review new clinic requests before allowing them to use the system."),
        bullet("Approve a clinic when it is ready to go live."),
        bullet("Suspend a clinic if access needs to be blocked."),
        bullet("Reactivate a suspended clinic."),
        bullet("View system-level statistics and revenue summaries."),
        bullet("Manage subscription plans such as pricing, number of doctors allowed, pharmacy access, and reports access."),
        bullet("Assign a subscription plan to a clinic."),
        bullet("View payment reports across the system."),
        heading("4. Clinic Admin Portal"),
        p("The Clinic Admin portal is for the clinic owner, manager, or administrator."),
        bullet("View a clinic dashboard showing key clinic activity."),
        bullet("Add and manage doctors."),
        bullet("Add and manage departments, such as Cardiology, General Medicine, Dermatology, etc."),
        bullet("Add and manage receptionist accounts."),
        bullet("Add and manage pharmacy user accounts."),
        bullet("View and manage patients registered at the clinic."),
        bullet("View and manage appointments."),
        bullet("Check clinic revenue and financial summaries."),
        bullet("Open reports for appointments, patient visits, payments, and clinic revenue."),
        bullet("Update clinic information such as name, contact details, timings, and working days."),
        PageBreak(),
        heading("5. Doctor Portal"),
        p("The Doctor portal is focused on the doctor’s daily patient work."),
        bullet("View today’s appointments and queue."),
        bullet("Start a consultation when the patient is ready."),
        bullet("See patient profile and recent medical history."),
        bullet("Review previous prescriptions and reports where available."),
        bullet("Write consultation details and complete the appointment."),
        bullet("Create prescriptions with medicines and lab tests."),
        bullet("View and manage prescriptions."),
        bullet("View earnings and doctor-specific reports."),
        bullet("View schedule information."),
        bullet("Create and manage assistant accounts for help during consultations."),
        heading("Doctor AI Features", 2),
        p(
            "The system includes AI support for doctors. The AI tools are meant to help with drafting and summarizing. "
            "They do not replace the doctor, and the doctor must review all AI output."
        ),
        bullet("Clinical AI can help summarize patient history."),
        bullet("Clinical AI can help draft consultation notes from available information."),
        bullet("Clinical AI can suggest questions or highlight possible red-flag items for the doctor to check."),
        bullet("Disease Risk Demo uses scikit-learn to show educational risk predictions for diabetes, heart disease, stroke, and breast cancer screening."),
        bullet("The disease prediction feature shows risk percentage and risk level, but it is only an educational screening demo, not a diagnosis."),
        table(
            [
                ["Disease demo", "What it means in simple words"],
                ["Diabetes risk", "Estimates diabetes risk from values such as age, BMI, glucose, blood pressure, and family history."],
                ["Heart disease risk", "Estimates heart disease risk from cardiovascular risk factors."],
                ["Stroke risk", "Estimates stroke risk from age, blood pressure/health conditions, glucose, BMI, and smoking."],
                ["Breast cancer screening risk", "Uses sample measurement-style inputs to demonstrate a screening classifier."],
            ],
            [48 * mm, 118 * mm],
        ),
        PageBreak(),
        heading("6. Assistant Portal"),
        p("The Assistant portal is for staff who help doctors during consultations."),
        bullet("View assistant dashboard information."),
        bullet("View the doctor’s patient queue."),
        bullet("Call the next patient when needed."),
        bullet("Add patient vitals such as temperature, pulse, oxygen level, weight, and height."),
        bullet("Upload or record patient report information."),
        bullet("Prepare symptoms or notes as a draft for the doctor."),
        bullet("View patient history if the assistant has permission."),
        p("Production note: the portal is implemented, but there is currently no production assistant login account created."),
        heading("7. Receptionist Portal"),
        p("The Receptionist portal is for front-desk clinic work."),
        bullet("View receptionist dashboard information."),
        bullet("Register new patients."),
        bullet("View patient list and patient details."),
        bullet("View patient history where allowed."),
        bullet("Book appointments for patients."),
        bullet("Manage the token queue for waiting patients."),
        bullet("Open appointment details."),
        bullet("Cancel or reschedule appointments where allowed."),
        bullet("Collect consultation payments."),
        bullet("Generate and view receipts."),
        bullet("View appointment reports."),
        heading("8. Pharmacy Portal"),
        p("The Pharmacy portal is for medicine stock and pharmacy sales."),
        bullet("View pharmacy dashboard information."),
        bullet("Add and edit medicines in inventory."),
        bullet("Track available stock."),
        bullet("See low-stock medicines."),
        bullet("See expired and near-expiry medicines."),
        bullet("View prescription orders sent to pharmacy."),
        bullet("Create medicine sales."),
        bullet("Generate pharmacy invoices."),
        bullet("View pharmacy sales history."),
        bullet("View pharmacy reports and sales reports."),
        PageBreak(),
        heading("9. Patient Portal"),
        p("The Patient portal is designed for patients to see their own information."),
        bullet("View patient dashboard."),
        bullet("View assigned or available doctors."),
        bullet("View appointments."),
        bullet("View prescriptions."),
        bullet("View medical records."),
        bullet("View bills."),
        p("Production note: the patient portal is implemented as a read-only portal, but there is currently no production patient login account created."),
        heading("10. Reports and Exports"),
        p("The system includes reports to help clinic managers understand activity and finances."),
        bullet("Clinic revenue report."),
        bullet("Doctor revenue report."),
        bullet("Pharmacy sales report."),
        bullet("Patient visits report."),
        bullet("Appointments report."),
        bullet("Payments report."),
        bullet("Reports can be viewed with charts and exported as PDF, CSV, or JSON from the app."),
        heading("11. Billing and Payments"),
        bullet("Reception can collect consultation payments."),
        bullet("The system supports payment methods such as cash, card, Easypaisa, JazzCash, and bank."),
        bullet("Payments can be linked to patients and appointments."),
        bullet("The system can track partial and full appointment payment status."),
        bullet("Receipts can be viewed from the receptionist portal."),
        heading("12. Subscriptions"),
        bullet("The platform owner can create subscription plans."),
        bullet("Plans can define price, duration, doctor limit, pharmacy access, and reports access."),
        bullet("A plan can be assigned to a clinic."),
        bullet("This helps control what each clinic is allowed to use."),
        PageBreak(),
        heading("13. Current Production Login Availability"),
        p("The following role types currently have production accounts available. Passwords are not listed because they are stored securely as hashes and cannot be read back."),
        table(
            [
                ["Portal", "Production account available?"],
                ["Super Admin", "Yes"],
                ["Clinic Admin", "Yes"],
                ["Doctor", "Yes, two doctor accounts"],
                ["Receptionist", "Yes"],
                ["Pharmacy", "Yes"],
                ["Assistant", "No account currently created"],
                ["Patient", "No account currently created"],
            ],
            [55 * mm, 111 * mm],
        ),
        heading("14. Important Non-Technical Notes"),
        bullet("The system is role-based, so each user only sees the portal meant for their job."),
        bullet("AI tools are support tools only. They should never be treated as final medical decisions."),
        bullet("Before real clinic use, the clinic should create test patients, appointments, payments, prescriptions, pharmacy stock, and reports to confirm the workflow."),
        bullet("Assistant and patient accounts should be created if those portals will be used."),
        bullet("Staff should be trained on daily workflows: patient registration, appointment booking, consultation, prescription, pharmacy sale, and billing."),
        bullet("Passwords should be shared through secure operational processes, not through reports."),
        heading("15. Final Summary"),
        p(
            "Overall, this system covers the main day-to-day needs of a clinic: registration, administration, "
            "appointments, consultation, prescriptions, pharmacy, billing, reporting, subscriptions, and AI-assisted "
            "doctor tools. The biggest remaining business setup items are creating live data, creating missing "
            "assistant/patient accounts if needed, staff training, and completing real workflow testing before using "
            "the system for full clinical operations."
        ),
    ]

    path = OUT / "clinic_nontechnical_feature_report.pdf"
    doc = SimpleDocTemplate(
        str(path),
        pagesize=A4,
        rightMargin=16 * mm,
        leftMargin=16 * mm,
        topMargin=16 * mm,
        bottomMargin=18 * mm,
        title="Clinic Non-Technical Feature Report",
        author="Codex",
    )
    doc.build(story, onFirstPage=footer, onLaterPages=footer)
    return path


if __name__ == "__main__":
    print(build())
