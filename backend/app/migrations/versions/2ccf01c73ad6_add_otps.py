"""add otps

Revision ID: 2ccf01c73ad6
Revises: 039011e1d364
Create Date: 2025-08-26 16:19:09.164657

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2ccf01c73ad6'
down_revision: Union[str, None] = '039011e1d364'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
