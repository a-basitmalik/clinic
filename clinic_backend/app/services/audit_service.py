from __future__ import annotations

from flask import has_request_context, request

from ..extensions import db
from ..models.audit_log import AuditLog


class AuditService:
    """Write minimal, non-PHI audit events for sensitive application actions."""

    @staticmethod
    def log(
        action: str,
        module: str,
        *,
        user_id: int | None = None,
        clinic_id: int | None = None,
        details: dict | None = None,
        commit: bool = True,
    ) -> AuditLog:
        ip_address = None
        if has_request_context():
            forwarded = request.headers.get("X-Forwarded-For", "")
            ip_address = (forwarded.split(",")[0].strip() or request.remote_addr)

        event = AuditLog(
            clinic_id=clinic_id,
            user_id=user_id,
            action=action[:100],
            module=module[:100],
            details=details or {},
            ip_address=ip_address,
        )
        db.session.add(event)
        if commit:
            db.session.commit()
        return event
