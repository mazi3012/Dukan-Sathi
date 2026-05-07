# Phase 5: Customer & Sales Intelligence 

## Overview
Dukan Sathi Pro has been upgraded from a basic invoice creator into a proactive "retail intelligence" agent. This phase bridges the gap between stored database insights (customer balances, unpaid invoices, payments) and conversational natural language.

## Database Additions
- **`payments` table created**: Supports the `recordPayment` tool.
- **RLS Policies**: Row Level Security enabled for the `payments` table to ensure shop-specific data isolation.

## New Intelligence Tools (Phase 1)
Implemented in `lib/tools/customer_tools.dart` and `lib/tools/invoice_lookup_tools.dart`:
1. **`checkCustomerDue`**: Queries customer balances and details recent unpaid or partially paid invoices.
2. **`listCustomersDue`**: Provides a quick ledger view of all customers with outstanding dues.
3. **`recordPayment`**: Processes payment entries, updates customer balances dynamically, and logs history into the `payments` table.
4. **`invoiceLookup`**: Enables retrieval of past invoice records by number, customer name, or payment status.

## Assistant Flow Integration
- **`bootstrap.dart`**: Registered the 4 new tools in the backend initialization.
- **`retail_assistant.dart`**: Expanded the AI system prompt to prioritize financial queries, and added keyword-based routing (e.g., "due", "owe", "balance", "udhar", "baki") to trigger the new tools.
- **`telegram_bot.dart`**: Added custom intent detectors (`_isCustomerDueIntent` and `_isInvoiceLookupIntent`) to appropriately route incoming Telegram messages to the Genkit engine with the correct tools enabled. Overly broad keywords (like "pay" or "paid") were carefully tuned to avoid conflicts with standard billing/expense paths.

## Next Steps for Future Phases
- **Phase 2 (Sales Intelligence)**: Implementation of `topSellingProducts` and `lowStockAlert`.
- **Phase 3 (Profit & Trends)**: Implementation of `netProfitSummary` and `dailySummary` to aggregate sales, expenses, and dues into a single End of Day report.
- **UI Integration**: Expose these capabilities gracefully via the Flutter Admin Dashboard if visual components are needed beyond Telegram.
