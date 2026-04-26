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

    final response = await ai.generate(
      model: appModel(),
      messages: [
        Message(
          role: Role.system,
          content: [
            TextPart(
                text:
                  'You are the AI brain for Dukan Sathi Pro. Shop ID is \'b6ff658b-c750-4c9a-b9ce-909ef6c52674\'. When a user asks about prices or stock, use the checkInventory tool. When a user asks to create a bill, use the createDraftInvoice tool. For business analytics, revenue, profit, or date-based queries, use the businessInsightsTool and interpret date ranges in India Standard Time. When a user wants to add products, use proposeProducts. When a user wants to delete or remove a product, use requestProductDeletion and never delete directly. Use logExpense to record expenses and getExpenses to retrieve past expenses. Always reply concisely in a friendly manner. Important: Product additions and deletions require human approval before finalization. Summarize the draft items and tell the user to check for the approval message shortly.',
            ),
          ],
        ),
        Message(
          role: Role.user,
          content: [TextPart(text: prompt)],
        ),
      ],
      toolNames: toolNames,
    );

    return response.text;
  },
);
