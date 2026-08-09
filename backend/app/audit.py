"""Centralized audit logging of important actions."""
import json
import logging

from sqlalchemy.orm import Session

from app.models import AuditLog

logger = logging.getLogger("jeevandoot.audit")


def record_audit(
    db: Session,
    user_id: int | None,
    action: str,
    entity: str | None = None,
    entity_id: int | None = None,
    meta: dict | None = None,
) -> None:
    try:
        db.add(
            AuditLog(
                user_id=user_id,
                action=action,
                entity=entity,
                entity_id=entity_id,
                meta=json.dumps(meta) if meta else None,
            )
        )
        db.commit()
    except Exception:
        logger.exception("failed to write audit log")
        db.rollback()