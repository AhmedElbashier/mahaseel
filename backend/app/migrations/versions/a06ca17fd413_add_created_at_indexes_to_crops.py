"""add created_at & indexes to crops

Revision ID: a06ca17fd413
Revises: c0b2b0dfa48e
Create Date: 2025-08-24 14:03:07.065517

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a06ca17fd413'
down_revision: Union[str, None] = 'c0b2b0dfa48e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
