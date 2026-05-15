from flask import Blueprint, request
from flask_jwt_extended import jwt_required, get_jwt

from ..services.department_service import DepartmentService
from ..utils.decorators import clinic_admin_required, active_user_required, clinic_approved_required
from ..utils.response_utils import success_response, error_response


department_bp = Blueprint("departments", __name__)


def _resolve_clinic_id():
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


@department_bp.route("", methods=["POST"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def create_department():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    try:
        dept = DepartmentService.create(clinic_id, data)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)

    return success_response("Department created successfully.", data={"department": dept.to_dict()}, status_code=201)


@department_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def list_departments():
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    include_inactive = request.args.get("include_inactive", "1") in ("1", "true", "True")
    depts = DepartmentService.list(clinic_id, include_inactive=include_inactive)
    return success_response("Departments retrieved.", data={"departments": [d.to_dict() for d in depts]})


@department_bp.route("/<int:department_id>", methods=["GET"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def get_department(department_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    dept = DepartmentService.get(clinic_id, department_id)
    if not dept:
        return error_response("Department not found.", status_code=404)

    return success_response("Department retrieved.", data={"department": dept.to_dict()})


@department_bp.route("/<int:department_id>", methods=["PUT"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def update_department(department_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    data = request.get_json(silent=True) or {}
    try:
        dept = DepartmentService.update(clinic_id, department_id, data)
    except ValueError as exc:
        msg = str(exc)
        return error_response(msg, status_code=422 if msg != "Department not found." else 404)

    return success_response("Department updated successfully.", data={"department": dept.to_dict()})


@department_bp.route("/<int:department_id>", methods=["DELETE"])
@jwt_required()
@active_user_required
@clinic_admin_required
@clinic_approved_required
def delete_department(department_id):
    clinic_id, err = _resolve_clinic_id()
    if err:
        return err

    try:
        dept = DepartmentService.soft_delete(clinic_id, department_id)
    except ValueError as exc:
        return error_response(str(exc), status_code=404)

    return success_response("Department deleted successfully (soft delete).", data={"department": dept.to_dict()})
