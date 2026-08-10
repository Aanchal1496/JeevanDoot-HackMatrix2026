"""Lightweight idempotent migrations.

New tables are created by ``Base.metadata.create_all`` at startup. Existing
tables (users, user_profiles, doctors, consultations, triage_records) also gain
new columns over time; ``CREATE TABLE`` alone cannot add them, so this module
adds any missing columns via ``ALTER TABLE ... ADD COLUMN`` while preserving
existing rows. It is safe to run repeatedly (guarded by the inspector).
"""
import logging

from sqlalchemy import inspect

from app.database import engine

logger = logging.getLogger("jeevandoot.migrations")

# (table, column, SQLAlchemy type factory) -> applied only if column missing.
_ADD_COLUMNS: dict[str, list[tuple[str, object]]] = {
    "users": [
        ("language", "TEXT"),
        ("verification_status", "TEXT"),
        ("created_at", "DATETIME"),
        ("updated_at", "DATETIME"),
    ],
    "user_profiles": [
        ("blood_group", "TEXT"),
        ("date_of_birth", "DATE"),
        ("emergency_contact", "TEXT"),
    ],
    "doctors": [
        ("user_id", "INTEGER"),
        ("qualification", "TEXT"),
        ("registration_number", "TEXT"),
        ("languages", "TEXT"),
    ],
    "consultations": [
        ("started_at", "DATETIME"),
        ("ended_at", "DATETIME"),
        ("connection_quality", "TEXT"),
        ("risk_level", "TEXT"),
        ("symptoms", "TEXT"),
        ("created_at", "DATETIME"),
        ("updated_at", "DATETIME"),
    ],
    "triage_records": [
        ("family_member_id", "INTEGER"),
        ("risk_score", "INTEGER"),
        ("red_flags", "TEXT"),
        ("recommendations", "TEXT"),
        ("created_at", "DATETIME"),
        ("updated_at", "DATETIME"),
    ],
}
# Existing tables that predate ``TimestampMixin``: the new timestamp columns are
# added as nullable and filled by Python-side ``default=datetime.utcnow`` on new
# inserts; old rows will simply read as NULL. (SQLite forbids non-constant
# defaults on ALTER ADD COLUMN, so we never ship a server default here.)
_DEFAULTS: dict[tuple[str, str], str] = {}


def ensure_migrations() -> None:
    inspector = inspect(engine)
    with engine.begin() as conn:
        for table, cols in _ADD_COLUMNS.items():
            existing = {c["name"] for c in inspector.get_columns(table)}
            for name, type_ in cols:
                if name in existing:
                    continue
                ddl = f'ALTER TABLE "{table}" ADD COLUMN "{name}" {type_}'
                default = _DEFAULTS.get((table, name))
                if default:
                    ddl += f" DEFAULT {default}"
                conn.exec_driver_sql(ddl)
                logger.info("migration: added column %s.%s", table, name)


def run_migrations() -> None:
    """Create new tables then add any missing columns to existing tables."""
    from app import models  # noqa: F401  ensure all tables are on metadata

    import app.database as db

    Base = db.Base
    db.Base.metadata.create_all(bind=db.engine)
    ensure_migrations()