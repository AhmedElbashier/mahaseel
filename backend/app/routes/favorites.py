from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional

from app.db.session import get_db
from app.api.deps import require_roles
from app.schemas.favorite import (
    FavoriteListCreate, FavoriteListUpdate, FavoriteListOut,
    FavoriteItemCreate, FavoriteItemOut, FavoriteSummaryItem, Paginated
)
from app.models.favorite import FavoriteList, FavoriteItem
from app.models import Crop

router = APIRouter(prefix="/favorites", tags=["favorites"])

def _get_or_create_default_list(db: Session, user_id: int) -> FavoriteList:
    default_list = db.query(FavoriteList).filter_by(user_id=user_id, is_default=True).first()
    if default_list:
        return default_list
    default_list = FavoriteList(user_id=user_id, name="My Favorites", is_default=True)
    db.add(default_list)
    db.commit()
    db.refresh(default_list)
    return default_list

# ----- Lists -----
@router.get("/lists", response_model=List[FavoriteListOut])
def list_lists(
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    _get_or_create_default_list(db, user.id)  # ensure it exists
    return db.query(FavoriteList).filter_by(user_id=user.id).order_by(FavoriteList.is_default.desc(), FavoriteList.created_at.asc()).all()

@router.post("/lists", response_model=FavoriteListOut, status_code=201)
def create_list(
    data: FavoriteListCreate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    exists = db.query(FavoriteList).filter_by(user_id=user.id, name=data.name).first()
    if exists:
        raise HTTPException(400, "You already have a list with this name.")
    fl = FavoriteList(user_id=user.id, name=data.name, is_default=False)
    db.add(fl); db.commit(); db.refresh(fl)
    return fl

@router.patch("/lists/{list_id}", response_model=FavoriteListOut)
def rename_list(
    list_id: int,
    data: FavoriteListUpdate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    fl = db.query(FavoriteList).filter_by(id=list_id, user_id=user.id).first()
    if not fl:
        raise HTTPException(404, "List not found.")
    if fl.is_default:
        raise HTTPException(400, "Default list cannot be renamed.")
    if data.name:
        clash = db.query(FavoriteList).filter(
            FavoriteList.user_id == user.id,
            FavoriteList.name == data.name,
            FavoriteList.id != fl.id
        ).first()
        if clash:
            raise HTTPException(400, "You already have a list with this name.")
        fl.name = data.name
    db.commit(); db.refresh(fl)
    return fl

@router.delete("/lists/{list_id}", status_code=204)
def delete_list(
    list_id: int,
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    fl = db.query(FavoriteList).filter_by(id=list_id, user_id=user.id).first()
    if not fl:
        raise HTTPException(404, "List not found.")
    if fl.is_default:
        raise HTTPException(400, "Default list cannot be deleted.")
    db.delete(fl); db.commit()
    return

# ----- Items -----
@router.get("/items", response_model=List[FavoriteItemOut])
def get_items(
    list_id: Optional[int] = None,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    if list_id is None:
        list_id = _get_or_create_default_list(db, user.id).id
    # Ensure list belongs to user
    fl = db.query(FavoriteList).filter_by(id=list_id, user_id=user.id).first()
    if not fl:
        raise HTTPException(404, "List not found.")

    q = db.query(FavoriteItem).filter(FavoriteItem.list_id == fl.id)
    total = q.count()
    rows = q.order_by(FavoriteItem.created_at.desc()) \
            .offset((page-1)*limit).limit(limit).all()
    # NOTE: You can wrap with a Paginated envelope if you prefer
    return rows

@router.post("/items", response_model=FavoriteItemOut, status_code=201)
def add_item(
    data: FavoriteItemCreate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    # Verify crop exists
    crop = db.query(Crop).filter_by(id=data.crop_id).first()
    if not crop:
        raise HTTPException(404, "Crop not found.")

    target_list_id = data.list_id
    if target_list_id is None:
        target_list_id = _get_or_create_default_list(db, user.id).id

    # Ensure list belongs to user
    fl = db.query(FavoriteList).filter_by(id=target_list_id, user_id=user.id).first()
    if not fl:
        raise HTTPException(404, "List not found.")

    # Upsert-like: check duplicate
    existing = db.query(FavoriteItem).filter_by(list_id=fl.id, crop_id=crop.id).first()
    if existing:
        return existing

    fi = FavoriteItem(list_id=fl.id, crop_id=crop.id)
    db.add(fi); db.commit(); db.refresh(fi)
    return fi

@router.delete("/items/{item_id}", status_code=204)
def remove_item(
    item_id: int,
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    fi = db.query(FavoriteItem).join(FavoriteList, FavoriteList.id == FavoriteItem.list_id) \
         .filter(FavoriteItem.id == item_id, FavoriteList.user_id == user.id).first()
    if not fi:
        raise HTTPException(404, "Item not found.")
    db.delete(fi); db.commit()
    return

@router.post("/toggle", response_model=FavoriteItemOut)
def toggle_favorite(
    data: FavoriteItemCreate,
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    target_list = _get_or_create_default_list(db, user.id) if data.list_id is None \
        else db.query(FavoriteList).filter_by(id=data.list_id, user_id=user.id).first()
    if target_list is None:
        raise HTTPException(404, "List not found.")

    crop = db.query(Crop).filter_by(id=data.crop_id).first()
    if not crop:
        raise HTTPException(404, "Crop not found.")

    existing = db.query(FavoriteItem).filter_by(list_id=target_list.id, crop_id=crop.id).first()
    if existing:
        db.delete(existing); db.commit()
        # Return a “toggled off” marker; simplest: same shape with id=0
        return FavoriteItemOut(id=0, crop_id=crop.id, list_id=target_list.id, created_at=existing.created_at)
    else:
        fi = FavoriteItem(list_id=target_list.id, crop_id=crop.id)
        db.add(fi); db.commit(); db.refresh(fi)
        return fi

@router.get("/summary", response_model=List[FavoriteSummaryItem])
def favorites_summary(
    db: Session = Depends(get_db),
    user = Depends(require_roles("buyer", "seller", "admin")),
):
    sub = db.query(
        FavoriteList.id.label("list_id"),
        FavoriteList.name,
        FavoriteList.is_default,
        func.count(FavoriteItem.id).label("count")
    ).outerjoin(FavoriteItem, FavoriteItem.list_id == FavoriteList.id) \
     .filter(FavoriteList.user_id == user.id) \
     .group_by(FavoriteList.id) \
     .order_by(FavoriteList.is_default.desc(), FavoriteList.created_at.asc())

    return [
        FavoriteSummaryItem(list_id=row.list_id, name=row.name, is_default=row.is_default, count=row.count)
        for row in sub.all()
    ]
