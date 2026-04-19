ALTER TABLE draft_invoices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anon insert" ON draft_invoices;
CREATE POLICY "Allow anon insert" ON draft_invoices FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Allow anon select" ON draft_invoices;
CREATE POLICY "Allow anon select" ON draft_invoices FOR SELECT USING (true);
