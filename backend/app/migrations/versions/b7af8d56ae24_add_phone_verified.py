"""add phone_verified

Revision ID: b7af8d56ae24
Revises: 60aef2f0a962
Create Date: 2025-08-24 22:58:50.259433

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b7af8d56ae24'
down_revision: Union[str, None] = '60aef2f0a962'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("phone_verified", sa.Boolean(), nullable=False, server_default=sa.false()))
    op.alter_column("users", "phone_verified", server_default=None)
    op.alter_column("users", "phone", existing_type=sa.String(length=32), nullable=True)
    op.create_table(
    "social_accounts",
    sa.Column("id", sa.Integer(), primary_key=True),
    sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
    sa.Column("provider", sa.Enum("google", "facebook", name="socialprovider"), nullable=False),
    sa.Column("provider_user_id", sa.String(length=128), nullable=False),
    sa.Column("email", sa.String(length=255)),
    sa.Column("display_name", sa.String(length=255)),
    sa.Column("avatar_url", sa.String(length=1024)),
    sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
    sa.UniqueConstraint("provider", "provider_user_id", name="uq_social_provider_user"),
    )

    pass


def downgrade() -> None:
    pass
