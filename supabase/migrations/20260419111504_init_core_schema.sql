CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create shops table (required by later migrations)
CREATE TABLE IF NOT EXISTS shops (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	owner_id UUID NOT NULL,
	name TEXT,
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
	id TEXT PRIMARY KEY,
	shop_id TEXT NOT NULL,
	name TEXT NOT NULL,
	price NUMERIC NOT NULL,
	stock_quantity INT DEFAULT 0,
	category TEXT
);

CREATE TABLE IF NOT EXISTS draft_invoices (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	shop_id TEXT NOT NULL,
	customer_id TEXT,
	items JSONB NOT NULL,
	total_amount NUMERIC NOT NULL,
	status TEXT DEFAULT 'draft',
	created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
