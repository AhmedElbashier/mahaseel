"""add media table + one-main-image index

Revision ID: 56573dd07c00
Revises: dc3248361508
Create Date: 2025-08-21 20:32:50.972666

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '56573dd07c00'
down_revision: Union[str, None] = 'dc3248361508'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    # drop the incorrectly created unique index (no WHERE)
    op.drop_index('uq_media_one_per_crop', table_name='media')

    # recreate as a partial unique index on Postgres
    op.create_index(
        'uq_media_one_per_crop',
        'media',
        ['crop_id'],
        unique=True,
        postgresql_where=sa.text('is_main = true')
    )


def downgrade():
    op.drop_index('uq_media_one_per_crop', table_name='media')
    # If you want to re-create the non-partial one on downgrade (optional):
    op.create_index('uq_media_one_per_crop', 'media', ['crop_id'], unique=True)
