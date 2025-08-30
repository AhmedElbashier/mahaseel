"""fchat_init2

Revision ID: 61eeca43e995
Revises: c15148c2d8db
Create Date: 2025-08-30 19:26:40.520417

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '61eeca43e995'
down_revision: Union[str, None] = 'c15148c2d8db'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade():
    op.add_column("conversations", sa.Column("u_lo", sa.Integer(), nullable=True))
    op.add_column("conversations", sa.Column("u_hi", sa.Integer(), nullable=True))
    op.create_index("ix_conversations_u_lo", "conversations", ["u_lo"])
    op.create_index("ix_conversations_u_hi", "conversations", ["u_hi"])
    op.create_unique_constraint(
        "uq_conversation_listing_pair",
        "conversations",
        ["listing_id", "u_lo", "u_hi"]
    )

def downgrade():
    op.drop_constraint("uq_conversation_listing_pair", "conversations", type_="unique")
    op.drop_index("ix_conversations_u_lo", table_name="conversations")
    op.drop_index("ix_conversations_u_hi", table_name="conversations")
    op.drop_column("conversations", "u_lo")
    op.drop_column("conversations", "u_hi")
