import 'package:test/test.dart';
import 'package:dukansathi_new/flows/onboarding_flow.dart';

void main() {
  test('onboarding sequence prompts and advances steps', () async {
    final chatId = 999999;
    final startedBy = 'unittest';

    final p1 = await startOnboarding(chatId, startedBy);
    expect(p1.text.toLowerCase(), contains('what is the name of your shop'));

    final p2 = await processOnboardingInput(chatId, 'My Test Shop');
    expect(p2.text.toLowerCase(), contains('which state'));

    final p3 = await processOnboardingInput(chatId, 'Karnataka');
    expect(p3.text.toLowerCase(), contains('are you registered for gst'));
    expect(p3.keyboard, isNotNull, reason: 'GST step should have keyboard buttons');

    final p4 = await processOnboardingInput(chatId, 'no');
    expect(p4.text.toLowerCase(), contains('what is your business type'));
    expect(p4.keyboard, isNotNull, reason: 'Business type step should have keyboard buttons');

    final p5 = await processOnboardingInput(chatId, 'Retail');
    expect(p5.text.toLowerCase(), contains('what is your business phone number'));

    final p6 = await processOnboardingInput(chatId, '9876543210');
    expect(p6.text.toLowerCase(), contains('please confirm the details'));
    expect(p6.keyboard, isNotNull, reason: 'Confirmation step should have submit/cancel buttons');
  });
}


