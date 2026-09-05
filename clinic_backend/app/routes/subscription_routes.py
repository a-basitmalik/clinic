from flask import Blueprint, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from ..services.audit_service import AuditService
from ..services.subscription_service import SubscriptionService
from ..utils.decorators import role_required
from ..utils.response_utils import error_response, success_response


subscription_bp = Blueprint("subscriptions", __name__)


@subscription_bp.route("/plans", methods=["GET"])
@jwt_required()
@role_required("super_admin", "clinic_admin")
def list_plans():
    include_inactive = request.args.get("include_inactive", "true").lower() == "true"
    plans = SubscriptionService.list_plans(include_inactive=include_inactive)
    return success_response("Subscription plans retrieved.", data={"plans": [p.to_dict() for p in plans]})


@subscription_bp.route("/plans", methods=["POST"])
@jwt_required()
@role_required("super_admin")
def create_plan():
    try:
        plan = SubscriptionService.create_plan(request.get_json(silent=True) or {})
        AuditService.log("CREATE_SUBSCRIPTION_PLAN", "subscriptions", user_id=int(get_jwt_identity()), details={"plan_id": plan.id})
        return success_response("Subscription plan created.", data={"plan": plan.to_dict()}, status_code=201)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)


@subscription_bp.route("/plans/<int:plan_id>", methods=["PUT"])
@jwt_required()
@role_required("super_admin")
def update_plan(plan_id):
    try:
        plan = SubscriptionService.update_plan(plan_id, request.get_json(silent=True) or {})
        AuditService.log("UPDATE_SUBSCRIPTION_PLAN", "subscriptions", user_id=int(get_jwt_identity()), details={"plan_id": plan.id})
        return success_response("Subscription plan updated.", data={"plan": plan.to_dict()})
    except ValueError as exc:
        return error_response(str(exc), status_code=422)


@subscription_bp.route("", methods=["GET"])
@jwt_required()
@role_required("super_admin")
def list_subscriptions():
    subscriptions = SubscriptionService.list_subscriptions(request.args.get("clinic_id", type=int))
    return success_response("Subscriptions retrieved.", data={"subscriptions": [s.to_dict() for s in subscriptions]})


@subscription_bp.route("/clinics/<int:clinic_id>", methods=["POST"])
@jwt_required()
@role_required("super_admin")
def assign_subscription(clinic_id):
    try:
        subscription = SubscriptionService.assign(clinic_id, request.get_json(silent=True) or {})
        AuditService.log(
            "ASSIGN_SUBSCRIPTION",
            "subscriptions",
            user_id=int(get_jwt_identity()),
            clinic_id=clinic_id,
            details={"subscription_id": subscription.id, "plan_id": subscription.plan_id},
        )
        return success_response("Subscription assigned.", data={"subscription": subscription.to_dict()}, status_code=201)
    except ValueError as exc:
        return error_response(str(exc), status_code=422)
