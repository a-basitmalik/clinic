"""Generate the Clinic System — Server & Infrastructure Report (PDF).

Plain-language explanations for non-technical readers, paired with full
technical specifications for engineers. Facts gathered from live inspection
of the production server (31.97.190.216) on 16 June 2026.

Run:  .venv/bin/python generate_server_infrastructure_report.py
"""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import (
    PageBreak, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle, KeepTogether,
)

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "reports"
OUT.mkdir(exist_ok=True)

REPORT_DATE = "16 June 2026"
DARK = colors.HexColor("#0F3D3A")
PRIMARY = colors.HexColor("#0F766E")
ACCENT = colors.HexColor("#0EA5A4")
GREY = colors.HexColor("#475569")
LIGHT = colors.HexColor("#F1F5F9")
MINT = colors.HexColor("#ECFDF5")
BLUEBG = colors.HexColor("#EFF6FF")
BORDER = colors.HexColor("#CBD5E1")
INK = colors.HexColor("#1E293B")

styles = getSampleStyleSheet()


def mk(name, **kw):
    parent = kw.pop("parent", styles["Normal"])
    styles.add(ParagraphStyle(name, parent=parent, **kw))


mk("Cover", parent=styles["Title"], fontSize=26, leading=32, alignment=TA_CENTER, textColor=DARK)
mk("CoverSub", fontSize=12, leading=18, alignment=TA_CENTER, textColor=GREY)
mk("H1", fontSize=15.5, leading=20, spaceBefore=16, spaceAfter=6, textColor=PRIMARY, fontName="Helvetica-Bold")
mk("H2", fontSize=12, leading=16, spaceBefore=11, spaceAfter=4, textColor=DARK, fontName="Helvetica-Bold")
mk("Body", fontSize=9.7, leading=14.5, textColor=INK, alignment=TA_JUSTIFY, spaceAfter=5)
mk("Bul", fontSize=9.7, leading=14, textColor=INK, leftIndent=12, spaceAfter=2)
mk("Plain", fontSize=9.7, leading=14.5, textColor=colors.HexColor("#065F46"),
   backColor=MINT, borderColor=colors.HexColor("#A7F3D0"), borderWidth=0.5,
   borderPadding=8, spaceAfter=7, alignment=TA_JUSTIFY)
mk("Tech", fontSize=9.2, leading=13.5, textColor=colors.HexColor("#1E3A8A"),
   backColor=BLUEBG, borderColor=colors.HexColor("#BFDBFE"), borderWidth=0.5,
   borderPadding=8, spaceAfter=7, alignment=TA_LEFT)
mk("Cell", fontSize=8.6, leading=11.5, textColor=INK)
mk("CellHead", fontSize=8.6, leading=11.5, textColor=colors.white, fontName="Helvetica-Bold")
mk("Footer", fontSize=8, textColor=GREY)
mk("BoxLabel", fontSize=8, leading=10, textColor=colors.white, fontName="Helvetica-Bold", alignment=TA_CENTER)
mk("BoxText", fontSize=7.4, leading=9, textColor=colors.white, alignment=TA_CENTER)


def P(t, s="Body"):
    return Paragraph(t, styles[s])


def bullets(items):
    return [Paragraph(f"• {t}", styles["Bul"]) for t in items]


def table(rows, widths, head=True, fontsize=8.6):
    data = []
    for i, row in enumerate(rows):
        sty = "CellHead" if (head and i == 0) else "Cell"
        data.append([Paragraph(str(c), styles[sty]) for c in row])
    t = Table(data, colWidths=widths, repeatRows=1 if head else 0)
    ts = [
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.5, BORDER),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 4),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, LIGHT]),
    ]
    if head:
        ts.append(("BACKGROUND", (0, 0), (-1, 0), DARK))
    t.setStyle(TableStyle(ts))
    return t


def flow_diagram():
    """Horizontal architecture flow rendered as colored boxes with arrows."""
    boxes = [
        (PRIMARY, "USER", "Browser / phone<br/>on the internet"),
        (ACCENT, "NGINX 1.30", "Front door + HTTPS<br/>(reverse proxy)"),
        (DARK, "GUNICORN", "3 app workers<br/>port 5110 (local)"),
        (colors.HexColor("#0369A1"), "FLASK API", "Python business<br/>logic + AI"),
        (colors.HexColor("#7C3AED"), "PERCONA DB", "MySQL 8.4<br/>data storage"),
    ]
    cells = []
    for i, (clr, label, sub) in enumerate(boxes):
        inner = Table(
            [[Paragraph(label, styles["BoxLabel"])], [Paragraph(sub, styles["BoxText"])]],
            colWidths=[26 * mm],
        )
        inner.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), clr),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ("LEFTPADDING", (0, 0), (-1, -1), 3),
            ("RIGHTPADDING", (0, 0), (-1, -1), 3),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ]))
        cells.append(inner)
        if i < len(boxes) - 1:
            cells.append(Paragraph("&rarr;", ParagraphStyle(
                "arr", fontSize=14, textColor=GREY, alignment=TA_CENTER)))
    widths = []
    for i in range(len(cells)):
        widths.append(26 * mm if i % 2 == 0 else 6 * mm)
    flow = Table([cells], colWidths=widths)
    flow.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "MIDDLE")]))
    return flow


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(GREY)
    canvas.drawString(20 * mm, 12 * mm, "Clinic Management System — Server & Infrastructure Report")
    canvas.drawRightString(A4[0] - 20 * mm, 12 * mm, f"Page {doc.page}")
    canvas.setStrokeColor(BORDER)
    canvas.line(20 * mm, 15 * mm, A4[0] - 20 * mm, 15 * mm)
    canvas.restoreState()


CW = A4[0] - 40 * mm
story = []

# ============================ COVER ============================
story += [
    Spacer(1, 48 * mm),
    P("Clinic Management System", "Cover"),
    Spacer(1, 3 * mm),
    P("Server &amp; Infrastructure Report", "CoverSub"),
    P("What runs the system, where it lives, and how it is built —<br/>"
      "explained for everyone, detailed for engineers.", "CoverSub"),
    Spacer(1, 14 * mm),
    table([
        ["Item", "Details"],
        ["Report date", REPORT_DATE],
        ["Live website", "https://clinic.nalexustechnologies.com"],
        ["Server", "Cloud VPS · Ubuntu 24.04 LTS · IP 31.97.190.216"],
        ["Prepared from", "A live, read-only inspection of the production server and database."],
        ["Confidentiality", "Passwords and secret keys are intentionally excluded from this document."],
    ], [38 * mm, CW - 38 * mm]),
    Spacer(1, 8 * mm),
    P("This report is written in two voices on every topic: a plain-language explanation "
      "(green) anyone can follow, and a technical specification (blue / tables) for engineers.", "CoverSub"),
    PageBreak(),
]

# ============================ 1. AT A GLANCE ============================
story += [
    P("1. The System at a Glance", "H1"),
    P("In plain words: this is a complete software system that helps a clinic run its daily "
      "work — registering patients, booking appointments, doctor consultations, prescriptions, "
      "pharmacy, billing, reports, and AI assistance for doctors. It is a live website that "
      "staff open in a browser. Behind that website sits a powerful rented computer (a server) "
      "in a data centre that is online 24/7, keeps everyone's data safe, and does all the "
      "heavy thinking.", "Plain"),
    P("Think of it like a restaurant. The <b>website you see</b> is the dining room. <b>Nginx</b> "
      "is the front-door host who greets every guest and checks they came through the secure "
      "(HTTPS) entrance. <b>Gunicorn + Flask</b> are the kitchen where every order is actually "
      "cooked. The <b>database</b> is the store-room where all ingredients and records are kept. "
      "Each part has one job, and together they serve every request quickly and safely."),
    table([
        ["Question", "Short answer"],
        ["Where is it deployed?", "Cloud VPS server, IP 31.97.190.216, domain clinic.nalexustechnologies.com"],
        ["What is the backend?", "Python (Flask) REST API run by Gunicorn, kept alive by the operating system"],
        ["What database is used?", "Percona Server for MySQL 8.4 (a hardened, enterprise build of MySQL)"],
        ["What is the frontend?", "A Flutter web app (compiled to a fast static website) served by Nginx"],
        ["How is it secured?", "HTTPS/TLS certificate, firewall via localhost-only services, fail2ban, isolated app user"],
        ["Is it live now?", "Yes — running continuously; the server has been up 108 days"],
    ], [42 * mm, CW - 42 * mm]),
]

# ============================ 2. THE SERVER ============================
story += [
    P("2. The Server (the physical home of the system)", "H1"),
    P("In plain words: instead of buying a computer and keeping it in the office, the clinic "
      "rents a professional-grade computer in a secure data centre. It is always on, always "
      "connected to the internet, has battery/Generator backup, and is far more reliable than "
      "an office PC. This rented computer is called a <b>VPS</b> (Virtual Private Server). Ours "
      "is a fast, modern machine with 4 processor cores and 15 GB of memory — comfortably more "
      "than this clinic system needs, so it stays quick even when busy.", "Plain"),
    P("<b>Technical specification (read live from the server):</b>", "Body"),
    table([
        ["Component", "Specification"],
        ["Server type", "Virtual Private Server (VPS), hostname srv951538"],
        ["Public IP address", "31.97.190.216"],
        ["Operating system", "Ubuntu 24.04.3 LTS (Noble Numbat) — long-term-support Linux"],
        ["Kernel", "Linux 6.8.0-90-generic (64-bit)"],
        ["Processor", "AMD EPYC 9354P (4 vCPU cores allocated)"],
        ["Memory (RAM)", "15 GiB total + 2 GiB swap"],
        ["Storage", "193 GB SSD (about 20% used)"],
        ["Availability", "Up 108 days continuously at time of report; load average &lt; 0.2 (very light)"],
    ], [42 * mm, CW - 42 * mm]),
    P("Why this matters: a long uptime and a very low load average mean the system is stable "
      "and nowhere near its limits — there is large headroom for more clinics, users, and data.", "Body"),
]

# ============================ 3. ARCHITECTURE FLOW ============================
story += [
    PageBreak(),
    P("3. How a Request Travels (architecture)", "H1"),
    P("In plain words: every time a staff member clicks something, their request makes a short, "
      "well-guarded journey and comes back with an answer in a fraction of a second. Here is "
      "that journey, left to right:", "Plain"),
    Spacer(1, 2 * mm),
    KeepTogether(flow_diagram()),
    Spacer(1, 4 * mm),
    table([
        ["Step", "Component", "What it does"],
        ["1", "User device", "A browser or phone opens clinic.nalexustechnologies.com over the secure internet."],
        ["2", "Nginx (reverse proxy)", "The 'front door'. Forces HTTPS, serves the website files, and forwards data "
         "requests (/api/...) inward. Shields the application from the open internet."],
        ["3", "Gunicorn", "The application server. Runs 3 parallel worker processes so several users are "
         "served at once. Listens only on the server's own internal address (127.0.0.1:5110)."],
        ["4", "Flask API", "The 'brain'. Python code that checks permissions (JWT login), applies clinic "
         "rules, runs AI features, and reads/writes data."],
        ["5", "Percona / MySQL", "The 'memory'. Safely stores every patient, appointment, payment, prescription, "
         "and record, and returns exactly what was asked for."],
    ], [10 * mm, 38 * mm, CW - 48 * mm]),
    P("A key security point in plain words: only Nginx is exposed to the public internet. The "
      "application (Gunicorn/Flask) and the database both listen on the server's private internal "
      "address only, so the outside world can never talk to them directly — every request must "
      "pass through the guarded front door first.", "Plain"),
]

# ============================ 4. BACKEND ============================
story += [
    P("4. The Backend (the engine room)", "H1"),
    P("In plain words: the backend is the part nobody sees but everybody depends on. It enforces "
      "the rules ('a receptionist can book appointments but not prescribe medicine'), keeps "
      "logins secure, calculates revenue, and talks to the database. It is written in Python "
      "using a well-established framework called Flask, and it is kept permanently running by "
      "the operating system — if it ever crashed, the server restarts it automatically within "
      "seconds.", "Plain"),
    table([
        ["Item", "Detail"],
        ["Language", "Python 3.12.3"],
        ["Web framework", "Flask 3 (REST API)"],
        ["Application server", "Gunicorn — 3 worker processes, bound to 127.0.0.1:5110, 120s timeout"],
        ["Process manager", "systemd service 'clinic-backend.service' (auto-restart on failure, starts on boot)"],
        ["Runs as", "Non-root user 'nalexus', group 'www-data' (limited privileges = safer)"],
        ["Environment", "FLASK_ENV=production; isolated Python virtual-env at /home/nalexus/clinic/backend/venv"],
        ["API design", "18 route groups under /api/* (auth, doctors, pharmacy, payments, reports, clinical-ai, …)"],
        ["Security model", "JWT login tokens (24h), 7 user roles, every change written to an audit log"],
    ], [40 * mm, CW - 40 * mm]),
    P("<b>For engineers:</b> the app uses the Flask application-factory pattern with 18 blueprints, "
      "a layered routes → services → models design (SQLAlchemy ORM + Flask-Migrate), "
      "Flask-JWT-Extended for stateless auth, and an after-request hook that records every "
      "successful mutating call to an audit_logs table. Run target is <i>run:app</i> behind "
      "Gunicorn, supervised by systemd with Restart=always.", "Tech"),
]

# ============================ 5. DATABASE ============================
story += [
    PageBreak(),
    P("5. The Database (where everything is remembered)", "H1"),
    P("In plain words: the database is the system's permanent memory. Every patient, doctor, "
      "appointment, prescription, payment and report is stored here in neatly organised tables, "
      "like a set of perfectly maintained ledgers. We use Percona Server — a professional, "
      "extra-reliable version of the world's most popular open-source database, MySQL. It lives "
      "on the same server but is locked to internal access only, so no outsider can reach it.", "Plain"),
    table([
        ["Item", "Detail"],
        ["Engine", "Percona Server for MySQL 8.4.7 (drop-in MySQL-compatible, enterprise-grade)"],
        ["Database name", "clinic"],
        ["Access", "Local only (127.0.0.1:3306) — not reachable from the internet"],
        ["Character set", "utf8mb4 (full Unicode — supports any language and emoji)"],
        ["Login user", "dedicated 'clinic' account with password (excluded from this report)"],
        ["Total size", "≈ 1.44 MB across 20 tables (live operational + sample data)"],
        ["Schema management", "Flask-Migrate (versioned migrations) — schema changes are tracked and repeatable"],
    ], [40 * mm, CW - 40 * mm]),
    P("<b>Live table inventory</b> (the 20 tables that make up the system, with approximate row counts):", "Body"),
    table([
        ["Table", "Rows", "Table", "Rows"],
        ["users", "24", "patient_vitals", "15"],
        ["clinics", "1", "patient_reports", "15"],
        ["departments", "7", "consultation_drafts", "15"],
        ["doctors", "2", "prescriptions", "15"],
        ["assistants", "2", "prescription_medicines", "30"],
        ["patients", "15", "prescription_lab_tests", "15"],
        ["appointments", "15", "pharmacy_items", "15"],
        ["payments", "15", "pharmacy_sales", "15"],
        ["subscription_plans", "4", "pharmacy_sale_items", "15"],
        ["clinic_subscriptions", "1", "audit_logs", "15"],
    ], [42 * mm, 18 * mm, 42 * mm, CW - 102 * mm]),
    P("The 24 user accounts already span all seven roles (super_admin, clinic_admin, doctor, "
      "assistant, receptionist, pharmacy, and patient), confirming every portal has at least "
      "one working login on the live system.", "Body"),
]

# ============================ 6. FRONTEND ============================
story += [
    P("6. The Frontend (what people actually see)", "H1"),
    P("In plain words: the frontend is the screen the staff use — the buttons, menus, tables and "
      "forms. It is built with Flutter, Google's modern app technology, and compiled into a fast "
      "website. Because each role sees its own tailored portal, a receptionist, a doctor and a "
      "pharmacist all open the same address but get completely different, relevant screens.", "Plain"),
    table([
        ["Item", "Detail"],
        ["Technology", "Flutter (Dart) — compiled to an optimised static web app"],
        ["Served by", "Nginx directly from /home/nalexus/clinic/frontend (very fast, cached)"],
        ["Talks to backend", "Via HTTPS calls to /api/* on the same domain"],
        ["State / login", "Provider state management; JWT token kept in secure storage; auto-logout on expiry"],
        ["Portals", "Super Admin, Clinic Admin, Doctor, Assistant, Receptionist, Pharmacy, Patient"],
        ["Exports", "Built-in PDF, CSV and JSON export for reports"],
    ], [40 * mm, CW - 40 * mm]),
    P("<b>For engineers:</b> single-page Flutter web build with client-side role guards "
      "(route_guard), a central ApiService injecting the bearer token and handling 401 → forced "
      "re-login, and conditional web/io implementations for storage and file export. Nginx uses "
      "try_files $uri /index.html so client-side routing works on refresh.", "Tech"),
]

# ============================ 7. SECURITY ============================
story += [
    PageBreak(),
    P("7. Security &amp; Safety", "H1"),
    P("In plain words: the system is built so that data stays private and the service stays "
      "available. Connections are encrypted, the sensitive parts are hidden from the internet, "
      "and the server defends itself against intruders automatically.", "Plain"),
    *bullets([
        "<b>Encrypted traffic (HTTPS/TLS):</b> a valid Let's Encrypt certificate secures every "
        "connection; plain HTTP is automatically redirected to HTTPS.",
        "<b>Hidden internals:</b> the application (port 5110) and database (port 3306) listen on "
        "the internal address only — the public can reach Nginx and nothing else.",
        "<b>Strong logins:</b> passwords are stored only as secure hashes (never as plain text) "
        "and access is controlled by JWT tokens with a 24-hour expiry.",
        "<b>Role-based access:</b> seven roles ensure each user can only do what their job allows.",
        "<b>Full audit trail:</b> every create/update/delete is logged with who, what, and when.",
        "<b>Intrusion defence:</b> fail2ban is active, automatically blocking repeated malicious "
        "login attempts (e.g. against SSH).",
        "<b>Least privilege:</b> the app runs as a restricted user, not as the all-powerful root account.",
        "<b>Automatic recovery:</b> systemd restarts the backend within seconds if it ever fails.",
    ]),
    P("<b>For engineers:</b> TLS 1.2/1.3 via certbot with HSTS-ready options-ssl-nginx.conf and a "
      "custom dhparam; reverse-proxy isolation; non-root systemd unit with Restart=always; "
      "secrets injected through an .env file readable only by the service user (mode 0640); "
      "CORS locked to the production origin only.", "Tech"),
]

# ============================ 8. AI ============================
story += [
    P("8. The AI Features (briefly)", "H1"),
    P("In plain words: the system includes AI help for doctors — it can summarise a patient's "
      "history, draft consultation notes, and flag things worth checking. There are also "
      "educational 'risk score' tools (for diabetes, heart, stroke, breast-cancer screening) "
      "that turn simple measurements into a risk percentage. These are assistants, not "
      "decision-makers: a doctor always reviews and confirms.", "Plain"),
    table([
        ["AI capability", "How it works"],
        ["Clinical documentation AI", "Sends the patient's clinic data to an OpenAI model (configured: gpt-5.2) and "
         "returns structured drafts; if the AI is unreachable it falls back to a built-in offline engine."],
        ["Disease risk tools", "Four scikit-learn machine-learning models run directly on the server, turning "
         "numeric inputs (age, BMI, glucose, etc.) into a risk probability and a low/moderate/high level."],
        ["Safety", "Every AI output carries a notice that a licensed clinician must verify it before use."],
    ], [48 * mm, CW - 48 * mm]),
    P("<b>Note on AI provider:</b> the clinical assistant is configured to call OpenAI's API. The "
      "provider is a single configuration value (CLINICAL_AI_PROVIDER / CLINICAL_AI_MODEL), so it "
      "can be switched — for example to Anthropic's Claude models — with a small, isolated change, "
      "since all provider calls are contained in one service module.", "Tech"),
]

# ============================ 9. SUMMARY ============================
story += [
    P("9. Summary for Evaluators", "H1"),
    P("This is a professionally deployed, production-grade clinic platform. It runs on a modern "
      "Ubuntu cloud server with a clean, secure architecture: Nginx as the public gateway, "
      "Gunicorn + Flask as a resilient Python backend supervised by the operating system, and a "
      "hardened Percona/MySQL database — all reachable only through one encrypted front door. "
      "The frontend is a fast Flutter web app with role-specific portals, and the system layers "
      "in both classical machine-learning and large-language-model AI for doctors, with explicit "
      "human-in-the-loop safety. The technology choices are mainstream, well-supported, and "
      "scalable, and the live server shows ample spare capacity for growth.", "Plain"),
    Spacer(1, 4 * mm),
    table([
        ["Layer", "Technology (verified live)"],
        ["Domain / TLS", "clinic.nalexustechnologies.com · Let's Encrypt HTTPS"],
        ["Server", "Ubuntu 24.04 LTS VPS · AMD EPYC · 4 vCPU · 15 GB RAM · IP 31.97.190.216"],
        ["Web / proxy", "Nginx 1.30.1 (HTTP→HTTPS, static frontend + /api proxy)"],
        ["App server", "Gunicorn (3 workers) via systemd · Python 3.12"],
        ["Backend", "Flask 3 REST API · JWT · 7 roles · audit logging"],
        ["Database", "Percona Server for MySQL 8.4 · 'clinic' · 20 tables · utf8mb4"],
        ["Frontend", "Flutter web (static) · per-role portals · PDF/CSV/JSON export"],
        ["AI", "OpenAI gpt-5.2 (configurable) + 4 scikit-learn risk models"],
    ], [38 * mm, CW - 38 * mm]),
    Spacer(1, 6 * mm),
    P("<i>Prepared on 16 June 2026 from a direct, read-only inspection of the production server "
      "and database. Credentials and secret keys are deliberately omitted.</i>", "Footer"),
]

doc = SimpleDocTemplate(
    str(OUT / "Clinic_Server_Infrastructure_Report.pdf"),
    pagesize=A4, leftMargin=20 * mm, rightMargin=20 * mm,
    topMargin=18 * mm, bottomMargin=20 * mm,
    title="Clinic Management System — Server & Infrastructure Report",
    author="Nalexus Technologies",
)
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print("Wrote", OUT / "Clinic_Server_Infrastructure_Report.pdf")
