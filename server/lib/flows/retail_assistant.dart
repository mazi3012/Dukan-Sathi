import 'package:genkit/genkit.dart';
import 'package:schemantic/schemantic.dart';

import '../runtime/genkit_runtime.dart';

final retailAssistantFlow = ai.defineFlow(
  name: 'retailAssistantFlow',
  inputSchema: SchemanticType.string(),
  outputSchema: SchemanticType.string(),
  fn: (prompt, context) async {
    final toolNames = [
      'createDraftInvoice',
      'checkInventory',
      'browseCatalogTool',
      'proposeProducts',
      'requestProductDeletion',
      'businessInsightsTool',
      'logExpense',
      'getExpenses',
      'checkCustomerDue',
      'listCustomersDue',
      'recordPayment',
      'invoiceLookup'
    ];

    final response = await ai.generate(
      model: appModel(),
      messages: [
        Message(
          role: Role.system,
          content: [
            TextPart(
                text:
                  "You are the AI brain for Dukan Sathi Pro. CRITICAL RULES:\n"
                  "1. YOU MUST NEVER PREDICT OR HALLUCINATE DATA. IF ASKED FOR DATA, YOU MUST USE A TOOL. IF NO TOOL FITS, SAY YOU DON'T KNOW.\n"
                  "2. When a user asks about prices or stock, use checkInventory.\n"
                  "3. When a user asks to see your catalog or list products, use browseCatalogTool.\n"
                  "4. When a user asks to create a bill/invoice, use createDraftInvoice. IMPORTANT: If a customer name is mentioned (e.g., 'bill for Rahul'), pass it as 'customerName'. ALWAYS pass the raw user prompt as 'userPrompt' to this tool.\n"
                  "5. For business analytics (revenue, profit, orders), use businessInsightsTool. Present results clearly.\n"
                  "6. For product additions, use proposeProducts. For deletions, use requestProductDeletion. Both require human approval.\n"
                  "7. For expenses, use logExpense and getExpenses.\n"
                  "8. For customer dues, balances, or payments, use checkCustomerDue, listCustomersDue, recordPayment, and invoiceLookup.\n"
                  "9. Use India Standard Time for all date-based queries. Reply concisely and professionally.\n"
                  "Summarize the action taken and mention that an interactive card will appear for their final approval.",
            ),
          ],
        ),
        Message(
          role: Role.user,
          content: [TextPart(text: prompt)],
        ),
      ],
      toolNames: toolNames,
      context: context.context,
    );

    return response.text;
  },
);

