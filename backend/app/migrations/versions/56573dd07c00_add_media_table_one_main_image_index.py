"""add media table + one-main-image index

Revision ID: 56573dd07c00
Revises: 82f8a4f9fb49
Create Date: 2025-08-21 20:32:50.972666

"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "56573dd07c00"
down_revision: Union[str, None] = "82f8a4f9fb49"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.alter_column(
        "media",
        "path",
        existing_type=sa.VARCHAR(length=255),
        type_=sa.String(length=512),
        existing_nullable=False,
    )
    op.create_index(op.f("ix_media_is_main"), "media", ["is_main"], unique=False)
    op.create_index(
        "uq_media_one_per_crop",
        "media",
        ["crop_id"],
        unique=True,
        postgresql_where=sa.text("is_main = true"),
    )


def downgrade() -> None:
    op.drop_index(
        "uq_media_one_per_crop",
        table_name="media",
        postgresql_where=sa.text("is_main = true"),
    )
    op.drop_index(op.f("ix_media_is_main"), table_name="media")
    op.alter_column(
        "media",
        "path",
        existing_type=sa.String(length=512),
        type_=sa.VARCHAR(length=255),
        existing_nullable=False,
    )
