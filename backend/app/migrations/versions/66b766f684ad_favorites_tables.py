"""favorites tables

Revision ID: 66b766f684ad
Revises: c4c4224b3141
Create Date: 2025-08-30 16:37:50.353866

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '66b766f684ad'
down_revision: Union[str, None] = 'c4c4224b3141'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.create_table(
        "favorite_lists",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, nullable=False, index=True),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("is_default", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id", "name", name="uq_favorite_list_user_name"),
    )

    op.create_table(
        "favorite_items",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("list_id", sa.Integer, nullable=False, index=True),
        sa.Column("crop_id", sa.Integer, nullable=False, index=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["list_id"], ["favorite_lists.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["crop_id"], ["crops.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("list_id", "crop_id", name="uq_favorite_item_list_crop"),
    )

def downgrade():
    op.drop_table("favorite_items")
    op.drop_table("favorite_lists")
