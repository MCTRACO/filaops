"""Add first_name, last_name to customers table

Revision ID: 043_add_customer_name_fields
Revises: 042_add_catalog_system
Create Date: 2026-01-10

Adds first_name and last_name columns to customers table for:
- B2B: Contact person at the organization
- B2C: Individual customer name for shipping
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic
revision = '043_add_customer_name_fields'
down_revision = '040_update_material_item_types'
branch_labels = None
depends_on = None


def upgrade():
    # Add first_name and last_name to customers table
    op.add_column('customers', sa.Column('first_name', sa.String(100), nullable=True))
    op.add_column('customers', sa.Column('last_name', sa.String(100), nullable=True))


def downgrade():
    op.drop_column('customers', 'last_name')
    op.drop_column('customers', 'first_name')
