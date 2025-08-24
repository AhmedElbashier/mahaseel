"""add seller rating unique constraint

Revision ID: 60aef2f0a962
Revises: 0087b3733570
Create Date: 2025-08-24 14:29:33.746346

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '60aef2f0a962'
down_revision: Union[str, None] = '0087b3733570'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_index(
        "uix_rating_seller",
        "ratings",
        ["buyer_id", "seller_id"],
        unique=True,
        postgresql_where=sa.text("crop_id IS NULL"),
        sqlite_where=sa.text("crop_id IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("uix_rating_seller", table_name="ratings")
