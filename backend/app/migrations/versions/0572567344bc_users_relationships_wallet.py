"""users relationships_wallet

Revision ID: 0572567344bc
Revises: e49abf983850
Create Date: 2025-08-31 16:39:51.463388

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0572567344bc'
down_revision: Union[str, None] = 'e49abf983850'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
