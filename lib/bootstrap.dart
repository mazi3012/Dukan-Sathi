import 'flows/retail_assistant.dart';
import 'tools/analytics_tools.dart';
import 'tools/billing_tools.dart';
import 'tools/inventory_tools.dart';

void initializeBackend() {
  checkInventory;
  browseCatalog;
  createDraftInvoice;
  businessInsightsTool;
  proposeProducts;
  requestProductDeletion;
  retailAssistantFlow;
}
