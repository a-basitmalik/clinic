from flask import Blueprint
from ..extensions import db
from ..utils.response_utils import success_response, error_response

health_bp = Blueprint("health", __name__)


@health_bp.route("/health", methods=["GET"])
def health():
    db_status = "ok"
    try:
        db.session.execute(db.text("SELECT 1"))
    except Exception as exc:
        db_status = str(exc)

    if db_status != "ok":
        return error_response(
            "Service unhealthy.",
            errors={"database": db_status},
            status_code=503,
        )

    return success_response(
        "Service is healthy.",
        data={"database": db_status, "api": "ok"},
    )
