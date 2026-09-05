"""Generate the Technical Evaluation Report PDF.

Mirrors the styling of the existing plain-language report (teal headings,
branded header tables, page footer). Run:

    .venv/bin/python generate_technical_evaluation_report.py
"""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4
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

REPORT_DATE = "16 June 2026"
DARK = colors.HexColor("#134E4A")
PRIMARY = colors.HexColor("#0F766E")
GREY = colors.HexColor("#475569")
LIGHT = colors.HexColor("#F1F5F9")
BORDER = colors.HexColor("#CBD5E1")

styles = getSampleStyleSheet()


def style(name, **kw):
    parent = kw.pop("parent", styles["Normal"])
    styles.add(ParagraphStyle(name, parent=parent, **kw))


style("CoverTitle", parent=styles["Title"], fontSize=24, leading=30,
      alignment=TA_CENTER, textColor=DARK)
style("CoverSub", fontSize=11, leading=16, alignment=TA_CENTER, textColor=GREY)
style("H1", fontSize=15, leading=20, spaceBefore=14, spaceAfter=6,
      textColor=PRIMARY, fontName="Helvetica-Bold")
style("H2", fontSize=12, leading=16, spaceBefore=10, spaceAfter=4,
      textColor=DARK, fontName="Helvetica-Bold")
style("Body", fontSize=9.5, leading=14, textColor=colors.HexColor("#1E293B"),
      alignment=TA_LEFT, spaceAfter=4)
style("Bul", fontSize=9.5, leading=14, textColor=colors.HexColor("#1E293B"),
      leftIndent=12, bulletIndent=2, spaceAfter=2)
style("Note", fontSize=9, leading=13, textColor=colors.HexColor("#7C2D12"),
      backColor=colors.HexColor("#FEF3C7"), borderPadding=6, spaceAfter=6)
style("Cell", fontSize=8.5, leading=11.5, textColor=colors.HexColor("#1E293B"))
style("CellHead", fontSize=8.5, leading=11.5, textColor=colors.white,
      fontName="Helvetica-Bold")
style("Mono", fontSize=8, leading=11, fontName="Courier",
      textColor=colors.HexColor("#0F172A"), backColor=LIGHT, borderPadding=6,
      spaceAfter=6)
style("Footer", fontSize=8, textColor=GREY)


def P(text, s="Body"):
    return Paragraph(text, styles[s])


def bullets(items):
    return [Paragraph(f"• {t}", styles["Bul"]) for t in items]


def make_table(rows, col_widths, head=True):
    data = []
    for r, row in enumerate(rows):
        if head and r == 0:
            data.append([Paragraph(c, styles["CellHead"]) for c in row])
        else:
            data.append([Paragraph(c, styles["Cell"]) for c in row])
    t = Table(data, colWidths=col_widths, repeatRows=1 if head else 0)
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


def footer(canvas, doc):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(GREY)
    canvas.drawString(20 * mm, 12 * mm, "Clinic Management System — Technical Evaluation Report")
    canvas.drawRightString(A4[0] - 20 * mm, 12 * mm, f"Page {doc.page}")
    canvas.setStrokeColor(BORDER)
    canvas.line(20 * mm, 15 * mm, A4[0] - 20 * mm, 15 * mm)
    canvas.restoreState()


CW = A4[0] - 40 * mm  # content width

story = []

# ---- Cover ----
story += [
    Spacer(1, 60 * mm),
    P("Clinic Management System", "CoverTitle"),
    Spacer(1, 4 * mm),
    P("Technical Evaluation Report", "CoverSub"),
    Spacer(1, 12 * mm),
    make_table(
        [
            ["Item", "Details"],
            ["Report date", REPORT_DATE],
            ["Purpose", "Detailed technical reference for evaluation — deployment, "
             "architecture, servers, frontend, and AI/ML models (inputs → outputs)."],
            ["Live domain", "clinic.nalexustechnologies.com"],
            ["Basis", "Compiled from direct inspection of the clinic_backend (Flask) "
             "and clinic_app (Flutter) source code."],
        ],
        [40 * mm, CW - 40 * mm],
    ),
    PageBreak(),
]

# ---- 1. Deployment & Domain ----
story += [
    P("1. Deployment &amp; Domain", "H1"),
    make_table(
        [
            ["Item", "Value"],
            ["Public domain (live)", "https://clinic.nalexustechnologies.com"],
            ["Public API base URL", "https://clinic.nalexustechnologies.com/api"],
            ["Internal app URL", "http://127.0.0.1:5110"],
            ["App port", "5110"],
            ["Host OS (production)", "Ubuntu / Linux"],
            ["Server deploy path", "/home/nalexus/clinic/clinic_backend"],
        ],
        [55 * mm, CW - 55 * mm],
    ),
    Spacer(1, 4 * mm),
    P("<b>Correction:</b> The earlier plain-language PDF listed the live site as "
      "restaurant.nalexustechnologies.com. That is stale/incorrect — every reference in the "
      "actual code (Flutter base URL, backend CORS allow-list, README) uses "
      "<b>clinic.nalexustechnologies.com</b>. Use the clinic domain for evaluation.", "Note"),
    P("<b>Topology:</b> Flutter web client (browser) → HTTPS to clinic.nalexustechnologies.com "
      "→ reverse proxy (TLS termination) → Gunicorn on 0.0.0.0:5110 → Flask app → MySQL. "
      "The scikit-learn risk models run in-process; the clinical LLM calls the OpenAI API "
      "(with a local fallback)."),
]

# ---- 2. Backend Architecture ----
story += [
    P("2. Backend Architecture", "H1"),
    P("2.1 Stack", "H2"),
    make_table(
        [
            ["Layer", "Technology", "Version"],
            ["Language", "Python", "3.10+"],
            ["Web framework", "Flask", "3.0.3"],
            ["WSGI server (prod)", "Gunicorn (-w 4 -b 0.0.0.0:5110)", "22.0.0"],
            ["ORM", "Flask-SQLAlchemy", "3.1.1"],
            ["Migrations", "Flask-Migrate (Alembic)", "4.0.7"],
            ["Auth", "Flask-JWT-Extended", "4.6.0"],
            ["CORS", "Flask-CORS", "4.0.1"],
            ["DB driver", "PyMySQL", "1.1.1"],
            ["Database", "MySQL (utf8mb4)", "8.0+"],
            ["ML", "scikit-learn / numpy", "sklearn 1.5.x / numpy 1.26+"],
        ],
        [42 * mm, CW - 82 * mm, 40 * mm],
    ),
    P("2.2 Application pattern — App Factory + Blueprints", "H2"),
    P("create_app() builds the app, initializes extensions (db, jwt, migrate), enables CORS "
      "for /api/*, and registers <b>18 blueprints</b>, each mounted under an /api/... prefix:"),
    P("/api/auth · /api/clinics · /api/super-admin · /api/clinic-admin · /api/departments · "
      "/api/doctors · /api/receptionists · /api/pharmacy · /api/patients · /api/appointments · "
      "/api/payments · /api/assistants · /api/assistant · /api/prescriptions · /api/reports · "
      "/api/clinical-ai · /api/subscriptions · /api/audit-logs · /api (health)", "Mono"),
    P("2.3 Layered design", "H2"),
    P("routes/  → HTTP layer (blueprints, JWT guards)<br/>"
      "services/ → business logic (19 service modules, one per domain)<br/>"
      "models/   → SQLAlchemy ORM entities (18 tables)<br/>"
      "utils/    → response envelope, password hashing<br/>"
      "extensions/ → db, jwt, migrate singletons", "Mono"),
    P("Routes are thin; all logic lives in services. Models (18): user, clinic, department, "
      "doctor, assistant, patient, patient_vitals, patient_report, appointment, "
      "consultation_draft, prescription, prescription_lab_test, payment, pharmacy, "
      "subscription, audit_log."),
    P("2.4 Authentication &amp; authorization", "H2"),
    *bullets([
        "JWT (Bearer header); access token 24 h, refresh token 30 days.",
        "Role-Based Access Control with 7 roles: super_admin, clinic_admin, doctor, "
        "assistant, receptionist, pharmacy, patient.",
        "User statuses: active, inactive, pending.",
        "First super admin seeded via CLI: flask create-super-admin.",
        "Passwords stored as hashes, never returned.",
    ]),
    P("2.5 Auditing", "H2"),
    P("An after_request hook auto-logs every successful mutating request (POST/PUT/PATCH/"
      "DELETE, status &lt; 400) to the audit_log table with user_id, clinic_id, method, path, "
      "and status — excluding login. Failures roll back cleanly."),
    P("2.6 Configuration (env-driven)", "H2"),
    P("config.py reads from .env with three profiles: development, production, testing "
      "(SQLite in-memory). DB URI: mysql+pymysql://user:pass@host:port/clinic?charset=utf8mb4. "
      "Secrets (SECRET_KEY, JWT_SECRET_KEY, DB_PASSWORD, OPENAI_API_KEY) come from environment."),
]

# ---- 3. Server / Runtime ----
story += [
    PageBreak(),
    P("3. Server / Runtime", "H1"),
    make_table(
        [
            ["Concern", "Detail"],
            ["Dev server", "python run.py → Flask dev server, 0.0.0.0:5110"],
            ["Prod server", "gunicorn -w 4 -b 0.0.0.0:5110 \"run:app\" (4 worker processes)"],
            ["TLS / domain", "Served under clinic.nalexustechnologies.com (reverse proxy in "
             "front of Gunicorn)"],
            ["Database", "MySQL 8, database clinic, user clinic, charset utf8mb4"],
            ["Schema mgmt", "Flask-Migrate (flask db upgrade) or raw migrations/schema.sql"],
            ["Seed data", "scripts/seed_demo_data.py"],
        ],
        [38 * mm, CW - 38 * mm],
    ),
]

# ---- 4. Frontend Architecture ----
story += [
    P("4. Frontend Architecture", "H1"),
    P("4.1 Stack", "H2"),
    make_table(
        [
            ["Item", "Detail"],
            ["Framework", "Flutter (Dart SDK &gt;=3.3.0 &lt;4.0.0)"],
            ["Target", "Web build (web/io conditional imports) + cross-platform capable"],
            ["State management", "Provider (ChangeNotifierProvider wrapping AuthService)"],
            ["HTTP", "http ^1.2.1 via a central ApiService"],
            ["Token storage", "flutter_secure_storage ^9.2.2 (web/io split)"],
            ["UI", "Material Design, google_fonts, custom theme (glassmorphism)"],
            ["PDF/Export", "pdf ^3.11.3 + export_service (PDF / CSV / JSON)"],
            ["Date/format", "intl ^0.19.0"],
        ],
        [42 * mm, CW - 42 * mm],
    ),
    P("4.2 Structure (mirrors backend domains)", "H2"),
    P("lib/main.dart   → bootstraps Provider, wires 401→login redirect<br/>"
      "lib/app.dart    → MaterialApp, named routes, route guards, global navigatorKey<br/>"
      "lib/core/       → constants (api endpoints), services (one client per domain), "
      "theme, utils, widgets<br/>"
      "lib/models/     → Dart data models<br/>"
      "lib/routes/     → app_routes, route_guard (role-gated navigation)<br/>"
      "lib/screens/    → per-role portals: super_admin / clinic_admin / doctor / assistant / "
      "receptionist / pharmacy / patient / reports / auth", "Mono"),
    P("4.3 Key client behaviors", "H2"),
    *bullets([
        "ApiService centralizes HTTP + auth-header injection; a global setUnauthorizedCallback "
        "forces logout to login on any 401.",
        "route_guard.dart enforces RBAC client-side: reads currentUser.role and redirects to "
        "the role's dashboard if the route is not in allowedRoles.",
        "Conditional io vs web implementations for storage and export.",
    ]),
]

# ---- 5. Models & AI ----
story += [
    PageBreak(),
    P("5. Models &amp; AI — Inputs → Outputs", "H1"),
    P("The system contains two distinct AI subsystems, both routed under /api/clinical-ai/*."),
    P("5.1 Disease Risk Models (scikit-learn, in-process)", "H2"),
    P("Four supervised classifiers, trained once at first use (lru_cache) on a deterministic "
      "educational/demo dataset (numpy seed 42; breast cancer uses the real sklearn Wisconsin "
      "dataset). 75/25 stratified split; each reports test accuracy."),
    make_table(
        [
            ["Model", "Algorithm", "Input features (ranges)", "Output"],
            ["diabetes", "LogisticRegression (StandardScaler pipeline)",
             "age (1–120), BMI (10–70), glucose (40–400 mg/dL), systolic BP (60–260), "
             "family history (0/1)", "risk probability + percent + level"],
            ["heart_disease", "RandomForest (160 trees, depth 7)",
             "age (18–120), sex (0/1), cholesterol (80–700), resting BP (60–260), "
             "max heart rate (40–240), smoker (0/1)", "risk probability + percent + level"],
            ["stroke", "DecisionTree (depth 6)",
             "age, hypertension (0/1), known heart disease (0/1), avg glucose (40–400), "
             "BMI (10–70), smoker (0/1)", "risk probability + percent + level"],
            ["breast_cancer", "RandomForest (180 trees, depth 8)",
             "mean radius, mean texture, mean perimeter, mean area, mean concavity",
             "malignant-risk probability + percent + level"],
        ],
        [24 * mm, 32 * mm, CW - 86 * mm, 30 * mm],
    ),
    Spacer(1, 3 * mm),
    P("<b>Output JSON:</b> { model{key,name,algorithm,accuracy,features,safety_notice}, "
      "risk_probability (0–1), risk_percent (0–100), risk_level (low&lt;0.35 / moderate&lt;0.70 "
      "/ high≥0.70), inputs, safety_notice }. Every feature is validated numeric and within "
      "min/max. Endpoints: GET /risk-models, POST /risk-predict/&lt;modelKey&gt;."),
    P("These are educational demonstrations only — explicitly not for diagnosis. Accuracy "
      "reflects synthetic demo data, not validated clinical performance.", "Note"),
    P("5.2 Clinical AI (LLM) documentation assistant", "H2"),
    make_table(
        [
            ["Item", "Detail"],
            ["Provider (configurable)", "CLINICAL_AI_PROVIDER = openai (default) or local"],
            ["Model", "CLINICAL_AI_MODEL = gpt-5.2 (env-overridable)"],
            ["API", "OpenAI Responses API (POST /v1/responses) with strict json_schema output"],
            ["Timeout", "45 s (configurable)"],
            ["Fallback", "If no API key or call fails → local rule-based engine (regex entity "
             "extraction + red-flag keyword rules) so it degrades gracefully offline"],
            ["Provider auth", "OPENAI_API_KEY from environment (never in reports)"],
        ],
        [40 * mm, CW - 40 * mm],
    ),
    Spacer(1, 3 * mm),
    P("<b>Capabilities (inputs → output):</b>"),
    make_table(
        [
            ["Endpoint", "Input", "What it does"],
            ["POST /patient-summary", "clinic/doctor/patient ids → patient profile "
             "(vitals, prescriptions, reports, appointments, follow-ups)",
             "Concise clinician-facing history summary"],
            ["POST /consultation-assist", "appointment + patient ids + working note "
             "(symptoms, diagnosis, notes, vitals)",
             "Draft symptoms/diagnosis/notes, entity extraction, red flags, "
             "patient-friendly explanation"],
            ["POST /extract-medical-text", "free-text string",
             "Extract medical entities + short summary"],
            ["GET /status", "—", "Reports enabled / provider / model / features"],
        ],
        [42 * mm, CW - 92 * mm, 50 * mm],
    ),
    Spacer(1, 3 * mm),
    P("<b>Structured output (every response):</b> summary, symptoms_draft, diagnosis_draft, "
      "notes_draft, patient_friendly_explanation, red_flags[], suggested_questions[], "
      "extracted_entities{conditions, medicines, dosages, symptoms, procedures, body_parts, "
      "lab_tests}, follow_up_guidance, provider, safety_notice."),
    P("<b>Safety:</b> a system prompt + safety_notice on every response enforce that output is "
      "a draft for a licensed clinician to verify — no autonomous diagnosis, prescription, or "
      "triage."),
]

# ---- 6 + 7 ----
story += [
    PageBreak(),
    P("6. Reports &amp; Exports", "H1"),
    P("Backend report endpoints: clinic-revenue, doctor-revenue, pharmacy-sales, "
      "patient-visits, appointments, payments (/api/reports/*). The Flutter export_service "
      "renders these to PDF (via the pdf package), CSV, and JSON, with web/native code paths."),
    P("7. Evaluation Quick-Reference", "H1"),
    make_table(
        [
            ["Question", "Answer"],
            ["Domain deployed?", "clinic.nalexustechnologies.com (HTTPS); API at /api; "
             "internal 127.0.0.1:5110"],
            ["Backend architecture?", "Flask 3 REST API, App-Factory + 18 Blueprints, layered "
             "routes→services→models, JWT RBAC (7 roles), audit hook, env config"],
            ["Which server?", "Gunicorn (4 workers, port 5110) on Ubuntu/Linux behind a TLS "
             "reverse proxy; MySQL 8 database"],
            ["Frontend architecture?", "Flutter (Dart 3.3+) web app, Provider state mgmt, "
             "central ApiService + secure token storage, role-guarded routes, per-role portals"],
            ["Models used?", "4 scikit-learn classifiers (LogisticRegression, 2× RandomForest, "
             "DecisionTree) for educational risk + OpenAI gpt-5.2 LLM (local rule-based fallback)"],
            ["Inputs → outputs?", "Risk models: numeric clinical features → risk "
             "probability/percent/level. Clinical LLM: patient record / consultation note / "
             "free text → structured JSON drafts, entities, red flags, summaries"],
        ],
        [42 * mm, CW - 42 * mm],
    ),
    Spacer(1, 6 * mm),
    P("<i>Prepared from direct inspection of clinic_backend (Flask) and clinic_app (Flutter) "
      "source on 16 June 2026.</i>", "Footer"),
]

doc = SimpleDocTemplate(
    str(OUT / "Clinic_Technical_Evaluation_Report.pdf"),
    pagesize=A4,
    leftMargin=20 * mm,
    rightMargin=20 * mm,
    topMargin=18 * mm,
    bottomMargin=20 * mm,
    title="Clinic Management System — Technical Evaluation Report",
)
doc.build(story, onFirstPage=footer, onLaterPages=footer)
print("Wrote", OUT / "Clinic_Technical_Evaluation_Report.pdf")
