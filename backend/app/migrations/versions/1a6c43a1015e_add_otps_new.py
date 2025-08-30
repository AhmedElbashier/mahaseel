"""add otps_new

Revision ID: 1a6c43a1015e
Revises: 2ccf01c73ad6
Create Date: 2025-08-26 16:30:40.180862

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '1a6c43a1015e'
down_revision: Union[str, None] = '2ccf01c73ad6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
