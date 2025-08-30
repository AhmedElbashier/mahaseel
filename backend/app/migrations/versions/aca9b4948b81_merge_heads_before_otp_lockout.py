"""merge heads before otp lockout

Revision ID: aca9b4948b81
Revises: 61eeca43e995, d9b3a1e7c2ab
Create Date: 2025-08-31 01:13:30.989802

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'aca9b4948b81'
down_revision: Union[str, None] = ('61eeca43e995', 'd9b3a1e7c2ab')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    # merge only — no schema changes here
    pass

def downgrade():
    # undo the merge if needed
    pass
