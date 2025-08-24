"""perf: add composite indexes for crops and fkeys for orders/media/users

Revision ID: c0b2b0dfa48e
Revises: 56573dd07c00
Create Date: 2025-08-24 10:34:34.603863

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c0b2b0dfa48e'
down_revision: Union[str, None] = '56573dd07c00'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def _create_index_if_not_exists(name: str, table: str, cols: list[str]):
    cols_sql = ", ".join(cols)
    op.execute(sa.text(f'CREATE INDEX IF NOT EXISTS {name} ON {table} ({cols_sql})'))

def upgrade():
    # ---- Crops ----
    _create_index_if_not_exists("ix_crops_state_type_created_at", "crops", ["state", "type", "created_at"])
    _create_index_if_not_exists("ix_crops_seller_id", "crops", ["seller_id"])

    # ---- Orders ----
    _create_index_if_not_exists("ix_orders_crop_id", "orders", ["crop_id"])
    _create_index_if_not_exists("ix_orders_buyer_id", "orders", ["buyer_id"])

    # ---- Media ----
    _create_index_if_not_exists("ix_media_crop_id", "media", ["crop_id"])

    # ---- Users ---- (skip silently if a unique index already exists)
    _create_index_if_not_exists("ix_users_phone", "users", ["phone"])

def downgrade():
    op.execute(sa.text('DROP INDEX IF EXISTS ix_users_phone'))
    op.execute(sa.text('DROP INDEX IF EXISTS ix_media_crop_id'))
    op.execute(sa.text('DROP INDEX IF EXISTS ix_orders_buyer_id'))
    op.execute(sa.text('DROP INDEX IF EXISTS ix_orders_crop_id'))
    op.execute(sa.text('DROP INDEX IF EXISTS ix_crops_seller_id'))
    op.execute(sa.text('DROP INDEX IF EXISTS ix_crops_state_type_created_at'))