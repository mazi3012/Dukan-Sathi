import 'package:genkit/genkit.dart';
import 'package:schemantic/schemantic.dart';

import '../runtime/genkit_runtime.dart';

final retailAssistantFlow = ai.defineFlow(
  name: 'retailAssistantFlow',
  inputSchema: SchemanticType.string(),
  outputSchema: SchemanticType.string(),
  fn: (prompt, context) async {
    final normalizedPrompt = prompt.toLowerCase();
    final toolNames = <String>[];
    
    if (normalizedPrompt.contains('bill') ||
        normalizedPrompt.contains('invoice') ||
        normalizedPrompt.contains('draft')) {
      toolNames.add('createDraftInvoice');
    }
    
    if (normalizedPrompt.contains('price') ||
        normalizedPrompt.contains('stock') ||
        normalizedPrompt.contains('inventory')) {
      toolNames.add('checkInventory');
    }
    
    if (normalizedPrompt.contains('browse') ||
        normalizedPrompt.contains('catalog') ||
        normalizedPrompt.contains('what do you sell') ||
        normalizedPrompt.contains('list product') ||
        normalizedPrompt.contains('show me item')) {
      toolNames.add('browseCatalogTool');
    }
    
    if (normalizedPrompt.contains('add') ||
        normalizedPrompt.contains('create') ||
        normalizedPrompt.contains('new product')) {
      toolNames.add('proposeProducts');
    }
    
    if (normalizedPrompt.contains('delete') ||
        normalizedPrompt.contains('remove') ||
        normalizedPrompt.contains('archive') ||
        normalizedPrompt.contains('discard product') ||
        normalizedPrompt.contains('kill product')) {
      toolNames.add('requestProductDeletion');
    }
    
    if (normalizedPrompt.contains('revenue') ||
        normalizedPrompt.contains('sales') ||
        normalizedPrompt.contains('profit') ||
        normalizedPrompt.contains('analytics') ||
        normalizedPrompt.contains('insight') ||
        normalizedPrompt.contains('earnings') ||
        normalizedPrompt.contains('total sales') ||
        normalizedPrompt.contains('today') ||
        normalizedPrompt.contains('yesterday') ||
        normalizedPrompt.contains('week') ||
        normalizedPrompt.contains('month') ||
        normalizedPrompt.contains('date range') ||
        normalizedPrompt.contains('between') ||
        normalizedPrompt.contains('order')) {
      toolNames.add('businessInsightsTool');
    }
    
    if (normalizedPrompt.contains('expense') ||
        normalizedPrompt.contains('spent') ||
        normalizedPrompt.contains('bill paid') ||
        normalizedPrompt.contains('cost') ||
        normalizedPrompt.contains('log') ||
        normalizedPrompt.contains('utility')) {
      toolNames.add('logExpense');
      toolNames.add('getExpenses');
    }
    
    if (normalizedPrompt.contains('due') ||
        normalizedPrompt.contains('owe') ||
        normalizedPrompt.contains('balance') ||
        normalizedPrompt.contains('settle') ||
        normalizedPrompt.contains('udhar') ||
        normalizedPrompt.contains('baki') ||
        normalizedPrompt.contains('who owes') ||
        normalizedPrompt.contains('just paid') ||
        normalizedPrompt.contains('customer paid')) {
      toolNames.add('checkCustomerDue');
      toolNames.add('listCustomersDue');
      toolNames.add('recordPayment');
      toolNames.add('invoiceLookup');
    }
    
    if (normalizedPrompt.contains('lookup') ||
        normalizedPrompt.contains('find bill') ||
        normalizedPrompt.contains('past invoice') ||
        normalizedPrompt.contains('show bill') ||
        normalizedPrompt.contains('unpaid invoice') ||
        normalizedPrompt.contains('last bill')) {
      toolNames.add('invoiceLookup');
    }

    final response = await ai.generate(
      model: appModel(),
      messages: [
        Message(
          role: Role.system,
          content: [
            TextPart(
                text:
                  "You are the AI brain for Dukan Sathi Pro. CRITICAL RULES:\n"
                  "1. When a user asks about prices or stock, use checkInventory.\n"
                  "2. When a user asks to see your catalog or list products, use browseCatalogTool.\n"
                  "3. When a user asks to create a bill/invoice, use createDraftInvoice. IMPORTANT: If a customer name is mentioned (e.g., 'bill for Rahul'), pass it as 'customerName'. ALWAYS pass the raw user prompt as 'userPrompt' to this tool.\n"
                  "4. For business analytics (revenue, profit, orders), use businessInsightsTool. Present results clearly: 'Total Revenue: ₹X | Orders: Y | Approved: Z'.\n"
                  "5. For product additions, use proposeProducts. For deletions, use requestProductDeletion. Both require human approval.\n"
                  "6. For expenses, use logExpense and getExpenses.\n"
                  "7. For customer dues, balances, or payments, use checkCustomerDue, listCustomersDue, recordPayment, and invoiceLookup.\n"
                  "8. Use India Standard Time for all date-based queries. Reply concisely and professionally.\n"
                  "Summarize the action taken and mention that an interactive card will appear for their final approval.",
            ),
          ],
        ),
        Message(
          role: Role.user,
          content: [TextPart(text: prompt)],
        ),
      ],
      toolNames: toolNames.isNotEmpty ? toolNames : null,
      context: context.context,
    );

    return response.text;
  },
);

