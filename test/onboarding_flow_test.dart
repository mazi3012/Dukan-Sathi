import 'package:test/test.dart';
import 'package:dukansathi_new/flows/onboarding_flow.dart';

void main() {
  test('onboarding rejects greeting as shop name', () async {
    final chatId = 999998;
    final startedBy = 'unittest';

    await startOnboarding(chatId, startedBy);

    final bad = await processOnboardingInput(chatId, 'Hello');
    expect(bad.text.toLowerCase(), contains('actual shop/business name'));

    final good = await processOnboardingInput(chatId, 'My Real Shop');
    expect(good.text.toLowerCase(), contains('which state'));
  });

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
    expect(p5.text.toLowerCase(), contains('please confirm the details'));
    expect(p5.keyboard, isNotNull, reason: 'Confirmation step should have submit/cancel buttons');
  });

  test('onboarding rejects invalid state and accepts valid code', () async {
    final chatId = 999997;
    final startedBy = 'unittest';

    await startOnboarding(chatId, startedBy);
    await processOnboardingInput(chatId, 'My Test Shop');

    final badState = await processOnboardingInput(chatId, 'Atlantis');
    expect(badState.text.toLowerCase(), contains('valid indian state'));

    final goodStateCode = await processOnboardingInput(chatId, 'AS');
    expect(goodStateCode.text.toLowerCase(), contains('are you registered for gst'));
  });
}


