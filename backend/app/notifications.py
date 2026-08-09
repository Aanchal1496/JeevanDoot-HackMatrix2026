"""Centralized notification creation.

Push/SMS/IVR are wired later through provider services; this module is the
single place in-app notifications are persisted for any role.
"""
from typing import Optional

from sqlalchemy.orm import Session

from app.models import Notification, NotificationType


def create_notification(
    db: Session,
    user_id: int,
    title: str,
    message: str,
    ntype: NotificationType = NotificationType.generic,
    related_id: Optional[int] = None,
) -> Notification:
    n = Notification(
        user_id=user_id,
        type=ntype,
        title=title,
        message=message,
        related_id=related_id,
    )
    db.add(n)
    db.flush()
    return n