"""users relationships_wallet2

Revision ID: dcbb2ef49a79
Revises: 0572567344bc
Create Date: 2025-08-31 16:40:27.161145

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'dcbb2ef49a79'
down_revision: Union[str, None] = '0572567344bc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
