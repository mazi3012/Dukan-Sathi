import 'package:test/test.dart';
import 'package:dukansathi_new/flows/onboarding_flow.dart';

void main() {
  test('onboarding sequence prompts and advances steps', () async {
    final chatId = 999999;
    final startedBy = 'unittest';

    final p1 = await startOnboarding(chatId, startedBy);
    expect(p1.toLowerCase(), contains('what is the name of your shop'));

    final p2 = await processOnboardingInput(chatId, 'My Test Shop');
    expect(p2.toLowerCase(), contains('which state'));

    final p3 = await processOnboardingInput(chatId, 'Karnataka');
    expect(p3.toLowerCase(), contains('are you registered for gst'));

    final p4 = await processOnboardingInput(chatId, 'no');
    expect(p4.toLowerCase(), contains('what is your business type'));

    final p5 = await processOnboardingInput(chatId, 'Retail');
    expect(p5.toLowerCase(), contains('please confirm the details'));
  });
}
