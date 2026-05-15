from .auth_routes import auth_bp
from .health_routes import health_bp
from .clinic_routes import clinic_bp
from .super_admin_routes import super_admin_bp
from .clinic_admin_routes import clinic_admin_bp
from .department_routes import department_bp
from .doctor_routes import doctor_bp
from .receptionist_routes import receptionist_bp
from .pharmacy_routes import pharmacy_bp
from .patient_routes import patient_bp
from .appointment_routes import appointment_bp
from .payment_routes import payment_bp
from .assistant_routes import assistant_bp, assistant_workflow_bp
from .prescription_routes import prescription_bp
from .report_routes import report_bp

__all__ = [
	"auth_bp",
	"health_bp",
	"clinic_bp",
	"super_admin_bp",
	"clinic_admin_bp",
	"department_bp",
	"doctor_bp",
	"receptionist_bp",
	"pharmacy_bp",
	"patient_bp",
	"appointment_bp",
	"payment_bp",
	"assistant_bp",
	"assistant_workflow_bp",
	"prescription_bp",
	"report_bp",
]
