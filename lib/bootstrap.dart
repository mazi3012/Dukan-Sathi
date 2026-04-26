import 'flows/retail_assistant.dart';
import 'tools/analytics_tools.dart';
import 'tools/billing_tools.dart';
import 'tools/inventory_tools.dart';
import 'tools/utility_tools.dart';
import 'tools/expense_tools.dart';

void initializeBackend() {
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
  retailAssistantFlow;
}
