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

    final response = await ai.generate(
      model: appModel(),
      messages: [
        Message(
          role: Role.system,
          content: [
            TextPart(
              text:
                  'You are the AI brain for Dukan Sathi Pro. Shop ID is \'b6ff658b-c750-4c9a-b9ce-909ef6c52674\'. When a user asks about prices or stock, use the checkInventory tool. When a user asks to create a bill, use the createDraftInvoice tool. Always reply concisely in a friendly manner. Important: When a bill is created, it requires human approval before finalization. Summarize the draft items and total amount (including taxes). Tell the user to check for the approval message shortly.',
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
