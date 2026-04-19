ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE draft_invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS products_read_all ON products;
CREATE POLICY products_read_all
ON products
FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS draft_invoices_read_all ON draft_invoices;
CREATE POLICY draft_invoices_read_all
ON draft_invoices
FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS draft_invoices_insert_all ON draft_invoices;
CREATE POLICY draft_invoices_insert_all
ON draft_invoices
FOR INSERT
TO anon, authenticated
WITH CHECK (true);
