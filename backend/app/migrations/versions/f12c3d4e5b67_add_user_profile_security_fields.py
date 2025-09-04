"""add user profile & security fields

Revision ID: f12c3d4e5b67
Revises: 5587a8042735
Create Date: 2025-09-04 16:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f12c3d4e5b67'
down_revision: Union[str, None] = '5587a8042735'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Security/auth fields
    op.add_column('users', sa.Column('password_hash', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('two_fa_enabled', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('users', sa.Column('two_fa_secret', sa.String(length=32), nullable=True))
    op.add_column('users', sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column('users', sa.Column('last_login', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('last_ip', sa.String(length=45), nullable=True))

    # Profile/communication fields
    op.add_column('users', sa.Column('locale', sa.String(length=10), nullable=True))
    op.add_column('users', sa.Column('timezone', sa.String(length=50), nullable=True))
    op.add_column('users', sa.Column('profile_picture', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('bio', sa.String(length=500), nullable=True))
    op.add_column('users', sa.Column('website', sa.String(length=255), nullable=True))
    op.add_column('users', sa.Column('social_links', sa.String(length=1000), nullable=True))
    op.add_column('users', sa.Column('email', sa.String(length=100), nullable=True))
    op.add_column('users', sa.Column('email_verified', sa.Boolean(), nullable=False, server_default=sa.false()))

    # Commercial/prefs
    op.add_column('users', sa.Column('is_premium', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('users', sa.Column('premium_expires_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('receive_newsletter', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column('users', sa.Column('receive_sms_alerts', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('users', sa.Column('receive_app_notifications', sa.Boolean(), nullable=False, server_default=sa.true()))
    op.add_column('users', sa.Column('marketing_consent', sa.Boolean(), nullable=False, server_default=sa.false()))

    # Legal
    op.add_column('users', sa.Column('terms_accepted', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('users', sa.Column('terms_accepted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('privacy_accepted', sa.Boolean(), nullable=False, server_default=sa.false()))
    op.add_column('users', sa.Column('privacy_accepted_at', sa.DateTime(timezone=True), nullable=True))

    # Soft delete
    op.add_column('users', sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True))

    # Clean server defaults for booleans to rely on app-level defaults
    op.alter_column('users', 'two_fa_enabled', server_default=None)
    op.alter_column('users', 'is_active', server_default=None)
    op.alter_column('users', 'email_verified', server_default=None)
    op.alter_column('users', 'is_premium', server_default=None)
    op.alter_column('users', 'receive_newsletter', server_default=None)
    op.alter_column('users', 'receive_sms_alerts', server_default=None)
    op.alter_column('users', 'receive_app_notifications', server_default=None)
    op.alter_column('users', 'marketing_consent', server_default=None)
    op.alter_column('users', 'terms_accepted', server_default=None)
    op.alter_column('users', 'privacy_accepted', server_default=None)


def downgrade() -> None:
    op.drop_column('users', 'deleted_at')
    op.drop_column('users', 'privacy_accepted_at')
    op.drop_column('users', 'privacy_accepted')
    op.drop_column('users', 'terms_accepted_at')
    op.drop_column('users', 'terms_accepted')
    op.drop_column('users', 'marketing_consent')
    op.drop_column('users', 'receive_app_notifications')
    op.drop_column('users', 'receive_sms_alerts')
    op.drop_column('users', 'receive_newsletter')
    op.drop_column('users', 'premium_expires_at')
    op.drop_column('users', 'is_premium')
    op.drop_column('users', 'email_verified')
    op.drop_column('users', 'email')
    op.drop_column('users', 'social_links')
    op.drop_column('users', 'website')
    op.drop_column('users', 'bio')
    op.drop_column('users', 'profile_picture')
    op.drop_column('users', 'timezone')
    op.drop_column('users', 'locale')
    op.drop_column('users', 'last_ip')
    op.drop_column('users', 'last_login')
    op.drop_column('users', 'is_active')
    op.drop_column('users', 'two_fa_secret')
    op.drop_column('users', 'two_fa_enabled')
    op.drop_column('users', 'password_hash')

