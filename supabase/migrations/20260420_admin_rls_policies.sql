-- Phase 1: Admin Database RLS Policies

-- Enable RLS on all admin tables
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Admin Users RLS Policies
-- Super admin can see all users
CREATE POLICY "super_admin_view_all_users" ON admin_users
FOR SELECT
USING (
	auth.uid()::uuid IN (
		SELECT user_id FROM admin_sessions WHERE token_hash IS NOT NULL
	)
	AND EXISTS (
		SELECT 1 FROM admin_users au
		JOIN admin_roles ar ON au.role_id = ar.id
		WHERE au.id = auth.uid()::uuid
		AND ar.role_name = 'super_admin'
	)
);

-- Admin can view their own user profile
CREATE POLICY "admin_view_own_profile" ON admin_users
FOR SELECT
USING (id = auth.uid()::uuid);

-- Super admin can update users
CREATE POLICY "super_admin_update_users" ON admin_users
FOR UPDATE
USING (
	EXISTS (
		SELECT 1 FROM admin_users au
		JOIN admin_roles ar ON au.role_id = ar.id
		WHERE au.id = auth.uid()::uuid
		AND ar.role_name = 'super_admin'
	)
);

-- Admin Sessions RLS
-- Users can only see/manage their own sessions
CREATE POLICY "admin_view_own_sessions" ON admin_sessions
FOR SELECT
USING (user_id = auth.uid()::uuid);

CREATE POLICY "admin_manage_own_sessions" ON admin_sessions
FOR DELETE
USING (user_id = auth.uid()::uuid);

-- Audit Log RLS
-- Super admin can view all audit logs
CREATE POLICY "super_admin_view_audit_log" ON admin_audit_log
FOR SELECT
USING (
	EXISTS (
		SELECT 1 FROM admin_users au
		JOIN admin_roles ar ON au.role_id = ar.id
		WHERE au.id = auth.uid()::uuid
		AND ar.role_name = 'super_admin'
	)
);

-- Shop owner can view audit logs for their shop
CREATE POLICY "shop_owner_view_own_audit" ON admin_audit_log
FOR SELECT
USING (
	user_id IN (
		SELECT id FROM admin_users
		WHERE shop_id = (SELECT shop_id FROM admin_users WHERE id = auth.uid()::uuid)
	)
);

-- Auto insert audit log on admin user creation
CREATE OR REPLACE FUNCTION audit_log_admin_user()
RETURNS TRIGGER AS $$
BEGIN
	INSERT INTO admin_audit_log (user_id, action, resource, resource_id, changes, status)
	VALUES (
		auth.uid()::uuid,
		'user_created',
		'admin_users',
		NEW.id::TEXT,
		jsonb_build_object(
			'email', NEW.email,
			'role_id', NEW.role_id,
			'full_name', NEW.full_name
		),
		'success'
	);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for audit logging on user creation
CREATE TRIGGER audit_admin_user_creation
AFTER INSERT ON admin_users
FOR EACH ROW
EXECUTE FUNCTION audit_log_admin_user();

-- Auto update updated_at timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
	NEW.updated_at = NOW();
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER admin_users_update_timestamp
BEFORE UPDATE ON admin_users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER admin_roles_update_timestamp
BEFORE UPDATE ON admin_roles
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
