from fastapi import APIRouter, Query

router = APIRouter(prefix="/cms", tags=["cms"])


# For now return static placeholders; later wire to a table
@router.get("/blogs")
def blogs(page: int = Query(1, ge=1), limit: int = Query(20, ge=1, le=100)):
    return {"items": [], "page": page, "limit": limit, "total": 0}


@router.get("/pages")
def page(slug: str = Query(..., pattern="^(terms|advertising|support|contact)$")):
    return {"slug": slug, "title": slug.title(), "content": "Static placeholder — connect to DB later"}

