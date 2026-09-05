from flask import Blueprint, request
from flask_jwt_extended import get_jwt, jwt_required

from ..models.audit_log import AuditLog
from ..utils.decorators import active_user_required, role_required
from ..utils.response_utils import error_response, paginated_response


audit_bp = Blueprint("audit_logs", __name__)


@audit_bp.route("", methods=["GET"])
@jwt_required()
@active_user_required
@role_required("super_admin", "clinic_admin")
def list_audit_logs():
    claims = get_jwt()
    role = claims.get("role")
    query = AuditLog.query

    if role == "clinic_admin":
        clinic_id = claims.get("clinic_id")
        if not clinic_id:
            return error_response("Clinic context is missing.", status_code=400)
        query = query.filter(AuditLog.clinic_id == int(clinic_id))
    elif request.args.get("clinic_id", type=int):
        query = query.filter(AuditLog.clinic_id == request.args.get("clinic_id", type=int))

    if request.args.get("user_id", type=int):
        query = query.filter(AuditLog.user_id == request.args.get("user_id", type=int))
    if request.args.get("module"):
        query = query.filter(AuditLog.module == request.args["module"])
    if request.args.get("action"):
        query = query.filter(AuditLog.action == request.args["action"])

    page = max(request.args.get("page", 1, type=int), 1)
    per_page = min(max(request.args.get("per_page", 50, type=int), 1), 100)
    result = query.order_by(AuditLog.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    return paginated_response(
        "Audit logs retrieved.",
        data=[item.to_dict() for item in result.items],
        pagination={
            "page": result.page,
            "per_page": result.per_page,
            "total": result.total,
            "pages": result.pages,
        },
    )
