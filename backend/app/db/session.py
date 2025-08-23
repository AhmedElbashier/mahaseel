from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

_engine = None
_SessionLocal = None

def _ensure_engine():
    global _engine, _SessionLocal
    if _engine is None:
        url = settings.sqlalchemy_url
        if not url:
            raise RuntimeError("DATABASE_URL is not set/normalized")
        _engine = create_engine(url, pool_pre_ping=True)
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=_engine)

def get_engine():
    _ensure_engine()
    return _engine

def get_session_factory():
    _ensure_engine()
    return _SessionLocal

def get_db():
    _ensure_engine()
    db = _SessionLocal()
    try:
        yield db
    finally:
        db.close()
