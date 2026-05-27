import 'flows/retail_assistant.dart';
import 'tools/analytics_tools.dart';
import 'tools/billing_tools.dart';
import 'tools/inventory_tools.dart';
import 'tools/utility_tools.dart';
import 'tools/expense_tools.dart';
import 'tools/customer_tools.dart';
import 'tools/invoice_lookup_tools.dart';

// ─── Multi-Agent System ──────────────────────────────────────────────────
import 'agents/agent_registry.dart';
import 'agents/retail_agent.dart';
import 'agents/billing_agent.dart';
import 'agents/finance_agent.dart';

/// Global agent registry — accessible across the server
final agentRegistry = AgentRegistry();

void initializeBackend() {
  // ─── Legacy tool registrations (kept intact — tools are unchanged) ────
  checkInventory;
  browseCatalog;
  createDraftInvoice;
  businessInsightsTool;
  proposeProducts;
  requestProductDeletion;
  getWeather;
  setReminder;
  logExpense;
  getExpenses;
  checkCustomerDue;
  listCustomersDue;
  recordPayment;
  invoiceLookup;
  retailAssistantFlow;

  // ─── Multi-Agent Registry (Phase 1: runs alongside legacy system) ────
  agentRegistry.register(RetailAgent());
  agentRegistry.register(BillingAgent());
  agentRegistry.register(FinanceAgent());

  // Validate that no tools overlap across agents
  final errors = agentRegistry.validate();
  if (errors.isNotEmpty) {
    for (final error in errors) {
      print('⚠️ [AgentRegistry] Validation error: $error');
    }
  } else {
    print('✅ [AgentRegistry] All ${agentRegistry.all.length} agents validated — no tool overlaps');
  }
}
