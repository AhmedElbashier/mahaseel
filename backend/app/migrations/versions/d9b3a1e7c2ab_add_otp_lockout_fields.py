"""add otp lockout fields

Revision ID: d9b3a1e7c2ab
Revises: 767d4485d251
Create Date: 2025-08-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd9b3a1e7c2ab'
down_revision: Union[str, None] = '767d4485d251'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('otps', sa.Column('failed_attempts', sa.Integer(), nullable=False, server_default='0'))
    op.alter_column('otps', 'failed_attempts', server_default=None)
    op.add_column('otps', sa.Column('locked_until', sa.DateTime(), nullable=True))
    op.create_index(op.f('ix_otps_locked_until'), 'otps', ['locked_until'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_otps_locked_until'), table_name='otps')
    op.drop_column('otps', 'locked_until')
    op.drop_column('otps', 'failed_attempts')

