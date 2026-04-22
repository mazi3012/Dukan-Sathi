#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   PROJECT_REF=your-project-ref SHOP_ID=71a... ./scripts/clear_shop_supabase.sh
# Requires: `supabase` CLI in PATH OR a `DATABASE_URL`/`PG*` env for psql fallback.

PROJECT_REF="${PROJECT_REF:-${SUPABASE_PROJECT_REF:-}}"
SHOP_ID="${SHOP_ID:-71a343a4-2e91-4e11-85b3-3a15f013d5a4}"

SQL_FILE="$(mktemp /tmp/clear_shop_${SHOP_ID}_XXXX.sql)"
cat > "$SQL_FILE" <<SQL
BEGIN;

CREATE TEMP TABLE tmp_shop_ids(id_text text);
INSERT INTO tmp_shop_ids VALUES ('$SHOP_ID');

-- Delete dependent records (casts to text for safety)
DELETE FROM sales WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id, invoice_number;
DELETE FROM draft_invoices WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id;
DELETE FROM draft_approvals WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING approval_id;
DELETE FROM customers WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id;
-- cart_items and products may not exist in all schemas
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cart_items') THEN
    EXECUTE 'DELETE FROM cart_items WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id';
  END IF;
END$$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='products') THEN
    EXECUTE 'DELETE FROM products WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id, name';
  END IF;
END$$;

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='admin_audit_log') THEN
    EXECUTE 'DELETE FROM admin_audit_log WHERE shop_id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id';
  END IF;
END$$;

DELETE FROM shops WHERE id::text IN (SELECT id_text FROM tmp_shop_ids) RETURNING id, name;

DROP TABLE tmp_shop_ids;
COMMIT;
SQL

echo "Running clear-shop SQL for shop_id=$SHOP_ID"

if command -v supabase >/dev/null 2>&1; then
  if [ -n "$PROJECT_REF" ]; then
    echo "Using supabase CLI (project ref: $PROJECT_REF)"
    supabase db query --project-ref "$PROJECT_REF" < "$SQL_FILE"
  else
    echo "Using supabase CLI (no project ref provided)"
    supabase db query < "$SQL_FILE"
  fi
else
  echo "supabase CLI not found. Trying psql fallback."
  if [ -n "${DATABASE_URL:-}" ]; then
    psql "$DATABASE_URL" -f "$SQL_FILE"
  else
    echo "ERROR: No DATABASE_URL set. Install supabase CLI or set DATABASE_URL to use psql." >&2
    rm -f "$SQL_FILE"
    exit 2
  fi
fi

rm -f "$SQL_FILE"
echo "Done."
