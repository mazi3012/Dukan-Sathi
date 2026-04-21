import 'dart:io';
import 'package:dukansathi_new/bootstrap.dart';
import 'package:dukansathi_new/runtime/genkit_runtime.dart';

void main(List<String> arguments) {
  // Initialize all tools and flows
  initializeBackend();
  
  // The Genkit reflection server will start automatically in dev mode
  // Access it at: http://localhost:4000 (or $PORT if set)
  
  print('');
  print('🚀 ✨ Genkit Development Server');
  print('');
  print('✅ Genkit flows and tools initialized:');
  print('   • Flow: retailAssistantFlow');
  print('   • Tools: checkInventory, createDraftInvoice');
  print('');
  print('📊 UI Dashboard:');
  print('   http://localhost:4000');
  print('');
  print('🤖 Model: $aiProvider ($modelId)');
  print('💬 Telegram: @Sathiaibeta_bot');
  print('');
  print('The Genkit reflection server is running.');
  print('Visit http://localhost:4000 to see the Genkit UI');
  print('');
  
  // Keep the process alive
  ProcessSignal.sigint.watch().first.then((_) => exit(0));
  while(true) {
    sleep(Duration(hours: 1));
  }
}
