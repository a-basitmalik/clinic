import os
import click
from flask import Flask
from flask_cors import CORS

from .config import config_by_name
from .extensions import db, jwt, migrate
from .utils.response_utils import error_response


def create_app(config_name: str = None) -> Flask:
    if config_name is None:
        config_name = os.getenv("FLASK_ENV", "development")

    app = Flask(__name__)
    app.config.from_object(config_by_name.get(config_name, config_by_name["default"]))

    # Extensions
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    db.init_app(app)
    jwt.init_app(app)
    migrate.init_app(app, db)

    # Register all models so Flask-Migrate detects every table
    from . import models as _models  # noqa: F401

    # Blueprints
    from .routes.auth_routes import auth_bp
    from .routes.health_routes import health_bp
    from .routes.clinic_routes import clinic_bp
    from .routes.super_admin_routes import super_admin_bp
    from .routes.clinic_admin_routes import clinic_admin_bp
    from .routes.department_routes import department_bp
    from .routes.doctor_routes import doctor_bp
    from .routes.receptionist_routes import receptionist_bp
    from .routes.pharmacy_routes import pharmacy_bp
    from .routes.patient_routes import patient_bp
    from .routes.appointment_routes import appointment_bp
    from .routes.payment_routes import payment_bp
    from .routes.assistant_routes import assistant_bp, assistant_workflow_bp
    from .routes.prescription_routes import prescription_bp
    from .routes.report_routes import report_bp

    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(health_bp, url_prefix="/api")
    app.register_blueprint(clinic_bp, url_prefix="/api/clinics")
    app.register_blueprint(super_admin_bp, url_prefix="/api/super-admin")
    app.register_blueprint(clinic_admin_bp, url_prefix="/api/clinic-admin")
    app.register_blueprint(department_bp, url_prefix="/api/departments")
    app.register_blueprint(doctor_bp, url_prefix="/api/doctors")
    app.register_blueprint(receptionist_bp, url_prefix="/api/receptionists")
    app.register_blueprint(pharmacy_bp, url_prefix="/api/pharmacy")
    app.register_blueprint(patient_bp, url_prefix="/api/patients")
    app.register_blueprint(appointment_bp, url_prefix="/api/appointments")
    app.register_blueprint(payment_bp, url_prefix="/api/payments")
    app.register_blueprint(assistant_bp, url_prefix="/api/assistants")
    app.register_blueprint(assistant_workflow_bp, url_prefix="/api/assistant")
    app.register_blueprint(prescription_bp, url_prefix="/api/prescriptions")
    app.register_blueprint(report_bp, url_prefix="/api/reports")

    _register_jwt_handlers(app)
    _register_cli(app)

    return app


def _register_jwt_handlers(app: Flask) -> None:
    @jwt.expired_token_loader
    def expired_token(jwt_header, jwt_payload):
        return error_response("Token has expired. Please log in again.", status_code=401)

    @jwt.invalid_token_loader
    def invalid_token(reason):
        return error_response(f"Invalid token: {reason}", status_code=401)

    @jwt.unauthorized_loader
    def missing_token(reason):
        return error_response("Authentication required. No token provided.", status_code=401)

    @jwt.revoked_token_loader
    def revoked_token(jwt_header, jwt_payload):
        return error_response("Token has been revoked. Please log in again.", status_code=401)


def _register_cli(app: Flask) -> None:

    @app.cli.command("create-super-admin")
    @click.option("--email", prompt=True)
    @click.option("--password", prompt=True, hide_input=True, confirmation_prompt=True)
    @click.option("--name", prompt=True, help="Full name")
    def create_super_admin(email, password, name):
        """Seed the first Super Admin account."""
        from .models.user import User
        from .utils.password_utils import hash_password

        if User.query.filter_by(email=email.lower()).first():
            click.echo("Error: a user with that email already exists.")
            return

        admin = User(
            email=email.lower().strip(),
            password_hash=hash_password(password),
            name=name.strip(),
            role="super_admin",
            status="active",
            must_change_password=False,
        )
        db.session.add(admin)
        db.session.commit()
        click.echo(f"Super Admin '{email}' created successfully (id={admin.id}).")
