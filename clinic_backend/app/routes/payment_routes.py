from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..models.patient import Patient
from ..services.payment_service import PaymentService
from ..services.patient_service import PatientService
from ..utils.decorators import active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import success_response, error_response, paginated_response
from ..utils.validators import parse_date, parse_int


payment_bp = Blueprint("payments", __name__)


def _resolve_clinic_id_for_read():
    claims = get_jwt()
    role = claims.get("role")

    if role == "super_admin":
        clinic_id = request.args.get("clinic_id", type=int)
        if not clinic_id:
            return None, error_response("clinic_id query param is required for super_admin.", status_code=400)
        return clinic_id, None

    clinic_id = claims.get("clinic_id")
    if not clinic_id:
        return None, error_response("Clinic context is missing.", status_code=400)
    return int(clinic_id), None


@payment_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "pharmacy")
def create_payment():
    claims = get_jwt()
    role = claims.get("role")

    if role == "super_admin":
        clinic_id = request.args.get("clinic_id", type=int)
        if not clinic_id:
            return error_response("clinic_id query param is required for super_admin.", status_code=400)
    else:
        clinic_id = claims.get("clinic_id")
        if not clinic_id:
            return error_response("Clinic context is missing.", status_code=400)
        clinic_id = int(clinic_id)

    data = request.get_json(silent=True) or {}

    # Role-based payment type enforcement
    ptype = data.get("payment_type")
    if role in ("clinic_admin", "receptionist") and ptype not in (None, "consultation"):
        return error_response("Receptionist/Clinic Admin can create consultation payments only.", status_code=403)
    if role == "pharmacy" and ptype not in (None, "pharmacy"):
        return error_response("Pharmacy role can create pharmacy payments only.", status_code=403)

    if ptype is None:
        data["payment_type"] = "consultation" if role in ("clinic_admin", "receptionist") else "pharmacy"

    try:
        payment = PaymentService.create(clinic_id, received_by=get_jwt_identity(), data=data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Payment created successfully.", data={"payment": payment.to_dict()}, status_code=201)


@payment_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor")
def list_payments():
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")
    payment_type = request.args.get("payment_type")
    status = request.args.get("status")
    doctor_id = request.args.get("doctor_id")

    try:
        d_start = parse_date(start_date)
        d_end = parse_date(end_date)
        did = parse_int(doctor_id, "doctor_id", minimum=1) if doctor_id is not None else None
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    if role == "doctor":
        jwt_doctor_id = claims.get("doctor_id")
        if not jwt_doctor_id:
            return error_response("Doctor context is missing.", status_code=400)
        did = int(jwt_doctor_id)

    paginated = PaymentService.list(
        clinic_id,
        page=page,
        per_page=per_page,
        start_date=d_start,
        end_date=d_end,
        payment_type=payment_type,
        status=status,
        doctor_id=did,
    )

    return paginated_response(
        "Payments retrieved.",
        data=[p.to_dict() for p in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@payment_bp.route("/patient/<int:patient_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor", "patient")
def patient_payments(patient_id):
    claims = get_jwt()
    role = claims.get("role")

    if role == "patient":
        # Patient can only view their own linked record
        user_id = get_jwt_identity()
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or patient.id != patient_id:
            return error_response("Access denied.", status_code=403)
        clinic_id = patient.clinic_id
    else:
        clinic_id, err = _resolve_clinic_id_for_read()
        if err:
            return err

        if role == "doctor":
            doctor_id = claims.get("doctor_id")
            if not doctor_id:
                return error_response("Doctor context is missing.", status_code=400)
            if not PatientService.doctor_can_access_patient(clinic_id, int(doctor_id), patient_id):
                return error_response("Access denied.", status_code=403)

    payments = PaymentService.patient_payments(clinic_id, patient_id)
    return success_response("Patient payments retrieved.", data={"payments": [p.to_dict() for p in payments]})


@payment_bp.route("/revenue-summary", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist")
def revenue_summary():
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    start_date = request.args.get("start_date")
    end_date = request.args.get("end_date")
    doctor_id = request.args.get("doctor_id")
    payment_type = request.args.get("payment_type")

    try:
        d_start = parse_date(start_date)
        d_end = parse_date(end_date)
        did = parse_int(doctor_id, "doctor_id", minimum=1) if doctor_id is not None else None
    except ValueError as exc:
        return error_response("Validation failed.", errors={"detail": str(exc)}, status_code=422)

    data = PaymentService.revenue_summary(
        clinic_id,
        start_date=d_start,
        end_date=d_end,
        doctor_id=did,
        payment_type=payment_type,
    )

    return success_response("Revenue summary retrieved.", data=data)
