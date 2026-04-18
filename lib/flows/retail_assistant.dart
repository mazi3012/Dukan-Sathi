import 'package:genkit/genkit.dart';
import 'package:schemantic/schemantic.dart';
import 'package:genkit_vertexai/genkit_vertexai.dart';

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
    } else if (normalizedPrompt.contains('price') ||
        normalizedPrompt.contains('stock') ||
        normalizedPrompt.contains('inventory')) {
      toolNames.add('checkInventory');
    }

    final response = await ai.generate(
      model: vertexAI.gemini('gemini-2.5-flash'),
      messages: [
        Message(
          role: Role.system,
          content: [
            TextPart(
              text:
                  'You are the AI brain for Dukan Sathi Pro. When a user asks about prices or stock, use the checkInventory tool. When a user asks to create a bill, use the createDraftInvoice tool. Always reply concisely in a friendly manner. If a bill is created, summarize the draft items and total amount.',
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
