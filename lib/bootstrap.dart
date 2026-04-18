import 'flows/retail_assistant.dart';
import 'tools/billing_tools.dart';
import 'tools/inventory_tools.dart';

void initializeBackend() {
  checkInventory;
  createDraftInvoice;
  retailAssistantFlow;
}
