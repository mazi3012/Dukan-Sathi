-- Migration to add performance indexes to handle scaling up to 50,000 active users.
-- Optimizes background synchronization and query response times.

-- 1. Products table indexes
CREATE INDEX IF NOT EXISTS idx_products_shop_id ON products(shop_id);

-- 2. Customers table indexes
CREATE INDEX IF NOT EXISTS idx_customers_shop_id ON customers(shop_id);

-- 3. Draft Invoices table indexes
CREATE INDEX IF NOT EXISTS idx_draft_invoices_shop_id ON draft_invoices(shop_id);

-- 4. Shops table indexes (multi-tenant lookup index)
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON shops(owner_id);

-- 5. Sales table customer indexes
CREATE INDEX IF NOT EXISTS idx_sales_customer_id ON sales(customer_id);

-- 6. Compound indexes for high-speed dashboards & paginated catalogs
CREATE INDEX IF NOT EXISTS idx_sales_shop_timestamp ON sales(shop_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_products_shop_category ON products(shop_id, category);
CREATE INDEX IF NOT EXISTS idx_customers_shop_name ON customers(shop_id, name);

-- 7. High-speed lookup indexes for user auth and barcode scanner
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);


