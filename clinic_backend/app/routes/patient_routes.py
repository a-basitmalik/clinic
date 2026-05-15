from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt, get_jwt_identity

from ..models.patient import Patient
from ..services.patient_service import PatientService
from ..utils.decorators import active_user_required, clinic_approved_required, role_required
from ..utils.response_utils import success_response, error_response, paginated_response


patient_bp = Blueprint("patients", __name__)


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


@patient_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist")
def create_patient():
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
    try:
        patient = PatientService.create(clinic_id, created_by=get_jwt_identity(), data=data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Patient created successfully.", data={"patient": patient.to_dict()}, status_code=201)


@patient_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor")
def list_patients():
    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    claims = get_jwt()
    role = claims.get("role")
    doctor_id = claims.get("doctor_id")

    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)

    search = request.args.get("q")
    gender = request.args.get("gender")
    blood_group = request.args.get("blood_group")

    # Doctor sees only their own patients (based on appointments)
    if role == "doctor":
        if not doctor_id:
            return error_response("Doctor context is missing.", status_code=400)
        from ..models.appointment import Appointment
        from sqlalchemy import or_

        subq = Appointment.query.with_entities(Appointment.patient_id).filter(
            Appointment.clinic_id == clinic_id,
            Appointment.doctor_id == int(doctor_id),
        ).subquery()

        query = Patient.query.filter(Patient.clinic_id == clinic_id, Patient.id.in_(subq))
        if search:
            s = f"%{search.strip()}%"
            query = query.filter(
                or_(
                    Patient.name.ilike(s),
                    Patient.phone.ilike(s),
                    Patient.patient_code.ilike(s),
                    Patient.cnic.ilike(s),
                )
            )
        if gender:
            query = query.filter(Patient.gender == gender)
        if blood_group:
            query = query.filter(Patient.blood_group == blood_group)

        paginated = query.order_by(Patient.created_at.desc()).paginate(page=page, per_page=per_page, error_out=False)
    else:
        paginated = PatientService.list(
            clinic_id,
            page=page,
            per_page=per_page,
            search=search,
            gender=gender,
            blood_group=blood_group,
        )

    return paginated_response(
        "Patients retrieved.",
        data=[p.to_dict() for p in paginated.items],
        pagination={
            "page": paginated.page,
            "per_page": paginated.per_page,
            "total": paginated.total,
            "pages": paginated.pages,
        },
    )


@patient_bp.route("/<int:patient_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor", "patient")
def get_patient(patient_id):
    claims = get_jwt()
    role = claims.get("role")

    if role == "patient":
        # Patient can only see their linked profile
        user_id = get_jwt_identity()
        patient = Patient.query.filter_by(user_id=user_id).first()
        if not patient or patient.id != patient_id:
            return error_response("Access denied.", status_code=403)
        return success_response("Patient retrieved.", data={"patient": patient.to_dict()})

    clinic_id, err = _resolve_clinic_id_for_read()
    if err:
        return err

    if role == "doctor":
        doctor_id = claims.get("doctor_id")
        if not doctor_id:
            return error_response("Doctor context is missing.", status_code=400)
        if not PatientService.doctor_can_access_patient(clinic_id, int(doctor_id), patient_id):
            return error_response("Access denied.", status_code=403)

    patient = PatientService.get(clinic_id, patient_id)
    if not patient:
        return error_response("Patient not found.", status_code=404)

    return success_response("Patient retrieved.", data={"patient": patient.to_dict()})


@patient_bp.route("/<int:patient_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist")
def update_patient(patient_id):
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
    try:
        patient = PatientService.update(clinic_id, patient_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=422 if msg != "Patient not found." else 404)

    return success_response("Patient updated successfully.", data={"patient": patient.to_dict()})


@patient_bp.route("/<int:patient_id>/history", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_approved_required
@role_required("super_admin", "clinic_admin", "receptionist", "doctor", "patient")
def patient_history(patient_id):
    claims = get_jwt()
    role = claims.get("role")

    if role == "patient":
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

    try:
        history = PatientService.history(clinic_id, patient_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Patient history retrieved.", data=history)
