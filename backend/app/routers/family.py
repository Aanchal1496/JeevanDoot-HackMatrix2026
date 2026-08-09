from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.audit import record_audit
from app.database import get_db
from app.models import FamilyMember, User, UserRole
from app.routers.auth import get_current_user
from app.schemas import (
    FamilyMemberCreate,
    FamilyMemberOut,
    FamilyMemberUpdate,
)

router = APIRouter(prefix="/family-members", tags=["family"])


def _parse_date(value):
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except (ValueError, TypeError):
        return None


@router.get("", response_model=list[FamilyMemberOut])
def list_family_members(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Patients and ASHA workers may list their own family members.
    owner_id = current_user.id
    return (
        db.query(FamilyMember)
        .filter(FamilyMember.owner_id == owner_id)
        .order_by(FamilyMember.created_at.desc())
        .all()
    )


@router.post("", response_model=FamilyMemberOut, status_code=status.HTTP_201_CREATED)
def create_family_member(
    payload: FamilyMemberCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    member = FamilyMember(
        owner_id=current_user.id,
        name=payload.name.strip(),
        relationship_type=payload.relationship_type,
        date_of_birth=_parse_date(payload.date_of_birth),
        gender=payload.gender,
        blood_group=payload.blood_group,
        medical_info=payload.medical_info,
    )
    db.add(member)
    db.commit()
    db.refresh(member)
    record_audit(db, current_user.id, "family_member.create", "family_member", member.id)
    return member


@router.put("/{member_id}", response_model=FamilyMemberOut)
def update_family_member(
    member_id: int,
    payload: FamilyMemberUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    member = db.query(FamilyMember).filter(FamilyMember.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Family member not found.")
    if member.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed.")
    data = payload.model_dump(exclude_unset=True)
    if "date_of_birth" in data:
        data["date_of_birth"] = _parse_date(data.pop("date_of_birth"))
    for k, v in data.items():
        setattr(member, k, v)
    db.commit()
    db.refresh(member)
    record_audit(db, current_user.id, "family_member.update", "family_member", member.id)
    return member


@router.delete("/{member_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_family_member(
    member_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    member = db.query(FamilyMember).filter(FamilyMember.id == member_id).first()
    if not member:
        raise HTTPException(status_code=404, detail="Family member not found.")
    if member.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not allowed.")
    db.delete(member)
    db.commit()
    record_audit(db, current_user.id, "family_member.delete", "family_member", member_id)


def assert_family_ownership(db: Session, current_user: User, family_member_id: int | None):
    """Backend enforcement: a family member must belong to the acting user."""
    if family_member_id is None:
        return
    member = db.query(FamilyMember).filter(FamilyMember.id == family_member_id).first()
    if not member or member.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your family member.")