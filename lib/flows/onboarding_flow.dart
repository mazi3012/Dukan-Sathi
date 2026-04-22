import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:dukansathi_new/core/database.dart';

class OnboardingSession {
  OnboardingSession({required this.chatId, required this.startedBy}) : step = 0;

  final int chatId;
  final String startedBy;
  int step;
  final Map<String, String> data = {};
}

final Map<int, OnboardingSession> _sessions = {};
final _uuid = Uuid();

String _askForShopName(OnboardingSession s) => 'Welcome to Dukan Sathi! What is the name of your shop?';
String _askForState(OnboardingSession s) => 'Which state is your shop located in? (e.g., Maharashtra, Karnataka)';
String _askForGstRegistered(OnboardingSession s) => 'Are you registered for GST? Reply with *yes* or *no*.';
String _askForGstNumber(OnboardingSession s) => 'Please enter your GSTIN (15 characters).';
String _askForBusinessType(OnboardingSession s) => 'What is your business type? (eg. Retail, Wholesale, Manufacturer)';
String _confirmSummary(OnboardingSession s) {
  final name = s.data['shop_name'] ?? '<unknown>';
  final state = s.data['state'] ?? '<unknown>';
  final gstMode = s.data['gst_mode'] ?? 'UNREGISTERED';
  final gst = s.data['gst_registration_number'] ?? 'N/A';
  final biz = s.data['business_type'] ?? '<unknown>';
  return 'Please confirm the details:\n\n*Shop:* $name\n*State:* $state\n*GST Mode:* $gstMode\n*GSTIN:* $gst\n*Business Type:* $biz\n\nReply with *confirm* to finish or *cancel* to abort.';
}

Future<String> startOnboarding(int chatId, String startedBy) async {
  final s = OnboardingSession(chatId: chatId, startedBy: startedBy);
  _sessions[chatId] = s;
  return _askForShopName(s);
}

bool isInOnboarding(int chatId) => _sessions.containsKey(chatId);

Future<String> processOnboardingInput(int chatId, String input) async {
  final s = _sessions[chatId];
  if (s == null) return '';
  final text = input.trim();

  // Allow cancel at any time
  if (text.toLowerCase() == 'cancel') {
    _sessions.remove(chatId);
    return 'Onboarding cancelled.';
  }

  switch (s.step) {
    case 0:
      s.data['shop_name'] = text;
      s.step = 1;
      return _askForState(s);
    case 1:
      s.data['state'] = text;
      s.step = 2;
      return _askForGstRegistered(s);
    case 2:
      final n = text.toLowerCase();
      if (n == 'yes' || n == 'y') {
        s.data['gst_mode'] = 'REGISTERED';
        s.step = 3;
        return _askForGstNumber(s);
      } else if (n == 'no' || n == 'n') {
        s.data['gst_mode'] = 'UNREGISTERED';
        s.step = 4;
        return _askForBusinessType(s);
      } else {
        return 'Please reply with *yes* or *no*.';
      }
    case 3:
      final gst = text.toUpperCase();
      if (_validateGstin(gst)) {
        s.data['gst_registration_number'] = gst;
        s.step = 4;
        return _askForBusinessType(s);
      }
      return 'GSTIN does not look valid. Please re-enter the 15-character GSTIN in uppercase.';
    case 4:
      s.data['business_type'] = text;
      s.step = 5;
      return _confirmSummary(s);
    case 5:
      final t = text.toLowerCase();
      if (t == 'confirm' || t == 'yes' || t == 'y') {
        // Persist shop record
        final shopId = _uuid.v4();
        final insert = {
          'id': shopId,
          'name': s.data['shop_name'],
          'state': s.data['state'],
          'gst_mode': s.data['gst_mode'] ?? 'UNREGISTERED',
          'gst_registration_number': s.data['gst_registration_number'],
          'business_type': s.data['business_type'],
          'created_by': s.startedBy,
        }..removeWhere((k, v) => v == null);

        try {
          await supabase.from('shops').insert(insert).select().single();
          _sessions.remove(chatId);
          return '✅ Onboarding complete. Your shop has been created and set as the active shop. You can now create bills.';
        } catch (e) {
          return 'Failed to create shop: $e';
        }
      } else {
        return 'Reply *confirm* to finish or *cancel* to abort.';
      }
    default:
      _sessions.remove(chatId);
      return 'Onboarding session ended unexpectedly. Please start again with /start.';
  }
}

bool _validateGstin(String gst) {
  if (gst.length != 15) return false;
  final re = RegExp(r'^[0-9A-Z]+$');
  return re.hasMatch(gst);
}
