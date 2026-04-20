-- Phase 1: Admin Dashboard Database Schema
-- Creates tables for admin user management, roles, permissions, and audit logging

-- Admin Roles Table
CREATE TABLE IF NOT EXISTS admin_roles (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	role_name TEXT NOT NULL UNIQUE,
	description TEXT,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin Permissions Table
CREATE TABLE IF NOT EXISTS admin_permissions (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	permission_name TEXT NOT NULL UNIQUE,
	description TEXT,
	resource TEXT NOT NULL,
	action TEXT NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Role-Permission Junction Table
CREATE TABLE IF NOT EXISTS role_permissions (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
	permission_id UUID NOT NULL REFERENCES admin_permissions(id) ON DELETE CASCADE,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
	UNIQUE(role_id, permission_id)
);

-- Admin Users Table
CREATE TABLE IF NOT EXISTS admin_users (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	email TEXT NOT NULL UNIQUE,
	password_hash TEXT NOT NULL,
	full_name TEXT,
	phone TEXT,
	is_active BOOLEAN DEFAULT true,
	role_id UUID NOT NULL REFERENCES admin_roles(id),
	shop_id TEXT,
	last_login TIMESTAMP WITH TIME ZONE,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin Sessions Table
CREATE TABLE IF NOT EXISTS admin_sessions (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	user_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
	token_hash TEXT NOT NULL UNIQUE,
	ip_address TEXT,
	user_agent TEXT,
	expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin Audit Log Table
CREATE TABLE IF NOT EXISTS admin_audit_log (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	user_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
	action TEXT NOT NULL,
	resource TEXT NOT NULL,
	resource_id TEXT,
	changes JSONB,
	ip_address TEXT,
	status TEXT DEFAULT 'success',
	error_message TEXT,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_role_id ON admin_users(role_id);
CREATE INDEX IF NOT EXISTS idx_admin_users_active ON admin_users(is_active);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_user_id ON admin_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_token_hash ON admin_sessions(token_hash);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_expires ON admin_sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_admin_audit_user_id ON admin_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_audit_created ON admin_audit_log(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_audit_action ON admin_audit_log(action);

-- Insert Default Roles
INSERT INTO admin_roles (role_name, description) VALUES
	('super_admin', 'Full system access'),
	('shop_owner', 'Shop management access'),
	('inventory_manager', 'Inventory management only'),
	('viewer', 'Read-only access')
ON CONFLICT (role_name) DO NOTHING;

-- Insert Default Permissions
INSERT INTO admin_permissions (permission_name, description, resource, action) VALUES
	('manage_users', 'Create, edit, delete admin users', 'users', 'manage'),
	('view_users', 'View admin users', 'users', 'read'),
	('manage_inventory', 'Create, edit, delete inventory items', 'inventory', 'manage'),
	('view_inventory', 'View inventory', 'inventory', 'read'),
	('manage_analytics', 'Access analytics dashboard', 'analytics', 'manage'),
	('view_analytics', 'View analytics reports', 'analytics', 'read'),
	('manage_shop', 'Edit shop settings', 'shop', 'manage'),
	('view_audit_log', 'Access audit logs', 'audit_log', 'read'),
	('manage_roles', 'Create and edit roles', 'roles', 'manage'),
	('manage_invoices', 'Edit and delete invoices', 'invoices', 'manage'),
	('view_invoices', 'View invoices', 'invoices', 'read')
ON CONFLICT (permission_name) DO NOTHING;

-- Assign Permissions to Super Admin Role
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
	(SELECT id FROM admin_roles WHERE role_name = 'super_admin'),
	id
FROM admin_permissions
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign Permissions to Shop Owner Role
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
	(SELECT id FROM admin_roles WHERE role_name = 'shop_owner'),
	id
FROM admin_permissions
WHERE permission_name IN (
	'manage_inventory', 'view_inventory', 'manage_analytics', 'view_analytics',
	'manage_shop', 'view_audit_log', 'manage_invoices', 'view_invoices'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign Permissions to Inventory Manager Role
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
	(SELECT id FROM admin_roles WHERE role_name = 'inventory_manager'),
	id
FROM admin_permissions
WHERE permission_name IN ('manage_inventory', 'view_inventory')
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- Assign Permissions to Viewer Role
INSERT INTO role_permissions (role_id, permission_id)
SELECT 
	(SELECT id FROM admin_roles WHERE role_name = 'viewer'),
	id
FROM admin_permissions
WHERE permission_name IN (
	'view_users', 'view_inventory', 'view_analytics', 'view_audit_log', 'view_invoices'
)
ON CONFLICT (role_id, permission_id) DO NOTHING;
