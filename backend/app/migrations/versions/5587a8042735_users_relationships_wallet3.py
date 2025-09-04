"""users relationships_wallet3

Revision ID: 5587a8042735
Revises: dcbb2ef49a79
Create Date: 2025-08-31 16:43:39.315681

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '5587a8042735'
down_revision: Union[str, None] = 'dcbb2ef49a79'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
