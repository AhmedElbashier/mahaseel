"""search indexes for crops

Revision ID: c4c4224b3141
Revises: 767d4485d251
Create Date: 2025-08-30 12:32:02.124101
"""
from typing import Sequence, Union
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c4c4224b3141"
down_revision: Union[str, None] = "767d4485d251"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _is_postgres() -> bool:
    bind = op.get_bind()
    return bind.dialect.name.lower() in ("postgresql", "postgres")


def upgrade() -> None:
    if not _is_postgres():
        # Non-Postgres (e.g., SQLite in tests) – nothing to do
        return

    # 1) Ensure pg_trgm is available (safe if already installed)
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;")

    # 2) Create trigram GIN indexes on normalized text
    # NOTE: We index the same expression we will use in queries
    #       (lower + Arabic letter unification) so the planner uses the index.
    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_crops_name_trgm
        ON crops
        USING gin (
          lower(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      replace(name,'أ','ا'),'إ','ا'
                    ),
                    'آ','ا'
                  ),
                  'ى','ي'
                ),
                'ؤ','و'
              ),
              'ئ','ي'
            )
          ) gin_trgm_ops
        );
        """
    )

    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_crops_type_trgm
        ON crops
        USING gin (
          lower(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      replace(type,'أ','ا'),'إ','ا'
                    ),
                    'آ','ا'
                  ),
                  'ى','ي'
                ),
                'ؤ','و'
              ),
              'ئ','ي'
            )
          ) gin_trgm_ops
        );
        """
    )

    op.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_crops_state_trgm
        ON crops
        USING gin (
          lower(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      replace(state,'أ','ا'),'إ','ا'
                    ),
                    'آ','ا'
                  ),
                  'ى','ي'
                ),
                'ؤ','و'
              ),
              'ئ','ي'
            )
          ) gin_trgm_ops
        );
        """
    )


def downgrade() -> None:
    if not _is_postgres():
        return

    op.execute("DROP INDEX IF EXISTS idx_crops_state_trgm;")
    op.execute("DROP INDEX IF EXISTS idx_crops_type_trgm;")
    op.execute("DROP INDEX IF EXISTS idx_crops_name_trgm;")
    # (No need to drop the extension on downgrade)
