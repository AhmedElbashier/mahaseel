from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass


from app.models.user import User          # noqa
from app.models.crop import Crop          # noqa
from app.models.media import Media        # noqa
from app.models.order import Order        # noqa
from app.models.rating import Rating      # <-- NEW  # noqa
