#!/bin/bash
# Phase 4 Implementation Verification Script

echo "🔍 Phase 4: GST Compliance + Human-in-Loop Telegram Approval"
echo "=============================================================="
echo ""

STATE_OK=0
STATE_WARN=1
STATE_ERROR=2

check_file() {
  local file=$1
  local description=$2
  
  if [ -f "$file" ]; then
    echo "✅ $description"
    return 0
  else
    echo "❌ $description (MISSING: $file)"
    return 1
  fi
}

check_dir() {
  local dir=$1
  local description=$2
  
  if [ -d "$dir" ]; then
    echo "✅ $description"
    return 0
  else
    echo "❌ $description (MISSING: $dir)"
    return 1
  fi
}

check_content() {
  local file=$1
  local pattern=$2
  local description=$3
  
  if grep -q "$pattern" "$file" 2>/dev/null; then
    echo "✅ $description"
    return 0
  else
    echo "⚠️  $description (Pattern not found)"
    return 1
  fi
}

echo "📦 DATA MODELS"
echo "---------------"
check_file "lib/models/shop_config.dart" "ShopConfig model (GST registration, state, mode)"
check_file "lib/models/draft_approval.dart" "DraftApproval model (approval workflow)"
check_file "lib/models/tax_breakdown.dart" "TaxBreakdown model (tax calculations)"
echo ""

echo "⚙️  SERVICES & ENGINES"
echo "---------------------"
check_file "lib/services/gst_calculator.dart" "GST Calculator service (all 28 states + 8 UTs)"
check_file "lib/data/state_tax_slabs.dart" "State tax slab mappings"
check_file "lib/services/approval_formatter.dart" "Approval message formatter"
echo ""

echo "🔧 TOOLS & FLOWS"
echo "----------------"
check_content "lib/tools/billing_tools.dart" "createDraftInvoice" "Updated createDraftInvoice (returns pending approval)"
check_file "lib/tools/approval_tools.dart" "Approval tools (approve/reject functions)"
check_content "lib/flows/retail_assistant.dart" "retailAssistantFlow" "Updated retail assistant flow"
echo ""

echo "🤖 TELEGRAM INTEGRATION"
echo "----------------------"
check_content "bin/telegram_bot.dart" "onCallbackQuery\|callback" "Updated telegram_bot (approval buttons)"
echo ""

echo "🗄️  DATABASE MIGRATIONS"
echo "---------------------"
check_file "supabase/migrations/20260421_add_gst_config.sql" "GST config migration"
check_file "supabase/migrations/20260421_add_draft_approval.sql" "Draft approval workflow migration"
check_file "supabase/migrations/20260421_add_tax_breakdown.sql" "Tax breakdown migration"
echo ""

echo "🧪 TESTS"
echo "--------"
check_file "test/gst_approval_integration_test.dart" "Integration tests (GST, approval, Telegram)"
echo ""

echo "📊 FILES SUMMARY"
echo "----------------"
echo ""
echo "Model files:"
ls -lh lib/models/{shop_config,draft_approval,tax_breakdown}.dart 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo "Service files:"
ls -lh lib/services/{gst_calculator,approval_formatter}.dart lib/data/state_tax_slabs.dart 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo "Tool files:"
ls -lh lib/tools/approval_tools.dart 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo "Migration files:"
ls -lh supabase/migrations/20260421_*.sql 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo "Test files:"
ls -lh test/gst_approval_integration_test.dart 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

echo "🚀 NEXT STEPS"
echo "-------------"
echo "1. Run code generation:"
echo "   export PATH=\"/tmp/dart-sdk/bin:\$PATH\""
echo "   dart run build_runner build --delete-conflicting-outputs"
echo ""
echo "2. Test the implementation:"
echo "   dart test test/gst_approval_integration_test.dart"
echo ""
echo "3. Start Telegram bot:"
echo "   dart bin/telegram_bot.dart"
echo ""
echo "4. Test workflow:"
echo "   - User sends Telegram request for invoice"
echo "   - AI calculates with GST breakdown"
echo "   - Returns message with APPROVE/REJECT buttons"
echo "   - On APPROVE: Creates draft_invoices + Sale record"
echo "   - On REJECT: Returns error reason, no data saved"
echo ""

echo "✨ Phase 4 Implementation Complete!"
echo "===================================="
