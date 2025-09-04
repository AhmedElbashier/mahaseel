"""wallet + payout_methods + saved_searches

Revision ID: e49abf983850
Revises: aca9b4948b81
Create Date: 2025-08-31 15:33:48.691696

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e49abf983850'
down_revision: Union[str, None] = 'aca9b4948b81'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.create_table(
        "wallet_transactions",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("amount", sa.Numeric(12,2), nullable=False),
        sa.Column("kind", sa.Enum("credit","debit", name="txnkind"), nullable=False),
        sa.Column("ref", sa.String(64)),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
    )
    op.create_table(
        "payout_methods",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("bank_name", sa.String(120), nullable=False),
        sa.Column("account_name", sa.String(120), nullable=False),
        sa.Column("iban", sa.String(64), nullable=False),
        sa.Column("is_default", sa.Boolean, server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
    )
    op.create_table(
        "saved_searches",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("query_json", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()")),
    )

def downgrade():
    op.drop_table("saved_searches")
    op.drop_table("payout_methods")
    op.drop_table("wallet_transactions")
    op.execute("DROP TYPE IF EXISTS txnkind")
