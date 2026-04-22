import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:dukansathi_new/core/database.dart';
import 'package:teledart/model.dart' as tg;

class OnboardingSession {
  OnboardingSession({required this.chatId, required this.startedBy}) : step = 0;

  final int chatId;
  final String startedBy;
  int step;
  final Map<String, String> data = {};
}

class OnboardingPrompt {
  OnboardingPrompt({required this.text, this.keyboard});
  final String text;
  final tg.InlineKeyboardMarkup? keyboard;
}

final Map<int, OnboardingSession> _sessions = {};
final _uuid = Uuid();

String _askForShopName(OnboardingSession s) => 'Welcome to Dukan Sathi! What is the name of your shop?';
String _askForState(OnboardingSession s) => 'Which state is your shop located in? (example: Assam or AS)';
String _askForGstRegistered(OnboardingSession s) => 'Are you registered for GST?';
String _askForGstNumber(OnboardingSession s) => 'Please enter your GSTIN (15 characters).';
String _askForBusinessType(OnboardingSession s) => 'What is your business type?';
String _confirmSummary(OnboardingSession s) {
  final name = s.data['shop_name'] ?? '<unknown>';
  final state = s.data['state'] ?? '<unknown>';
  final gstMode = s.data['gst_mode'] ?? 'UNREGISTERED';
  final gst = s.data['gst_registration_number'] ?? 'N/A';
  final biz = s.data['business_type'] ?? '<unknown>';
  return 'Please confirm the details:\n\n*Shop:* $name\n*State:* $state\n*GST Mode:* $gstMode\n*GSTIN:* $gst\n*Business Type:* $biz\n\nAre you happy?';
}

tg.InlineKeyboardMarkup _buildConfirmationKeyboard(int chatId) {
  return tg.InlineKeyboardMarkup(
    inlineKeyboard: [
      [
        tg.InlineKeyboardButton(text: '❌ Cancel', callbackData: 'onboard_cancel_$chatId'),
        tg.InlineKeyboardButton(text: '✅ Submit', callbackData: 'onboard_submit_$chatId'),
      ]
    ],
  );
}

tg.InlineKeyboardMarkup _buildGstKeyboard(int chatId) {
  return tg.InlineKeyboardMarkup(
    inlineKeyboard: [
      [
        tg.InlineKeyboardButton(text: '✅ Yes', callbackData: 'onboard_gst_yes_$chatId'),
        tg.InlineKeyboardButton(text: '❌ No', callbackData: 'onboard_gst_no_$chatId'),
      ]
    ],
  );
}

tg.InlineKeyboardMarkup _buildBusinessTypeKeyboard(int chatId) {
  return tg.InlineKeyboardMarkup(
    inlineKeyboard: [
      [
        tg.InlineKeyboardButton(text: 'Retail', callbackData: 'onboard_biz_retail_$chatId'),
        tg.InlineKeyboardButton(text: 'Wholesale', callbackData: 'onboard_biz_wholesale_$chatId'),
      ],
      [
        tg.InlineKeyboardButton(text: 'Manufacturer', callbackData: 'onboard_biz_manufacturer_$chatId'),
        tg.InlineKeyboardButton(text: 'Other', callbackData: 'onboard_biz_other_$chatId'),
      ]
    ],
  );
}

Future<OnboardingPrompt> startOnboarding(int chatId, String startedBy) async {
  final s = OnboardingSession(chatId: chatId, startedBy: startedBy);
  _sessions[chatId] = s;
  return OnboardingPrompt(text: _askForShopName(s));
}

bool isInOnboarding(int chatId) => _sessions.containsKey(chatId);

bool _looksLikeGreeting(String text) {
  final t = text.toLowerCase().trim();
  const greetings = {
    'hi',
    'hello',
    'hey',
    'hii',
    'hiii',
    'yo',
    'start',
    '/start',
  };
  return greetings.contains(t);
}

const Set<String> _validStateCodes = {
  'AP', 'AR', 'AS', 'BR', 'CG', 'GA', 'GJ', 'HR', 'HP', 'JK', 'JH', 'KA',
  'KL', 'MP', 'MH', 'MN', 'ML', 'MZ', 'OD', 'PB', 'RJ', 'SK', 'TN', 'TS',
  'TR', 'UP', 'UK', 'WB', 'AN', 'CH', 'DL', 'DD', 'DH', 'JL', 'LA', 'LD', 'PY'
};

const Map<String, String> _stateNameToCode = {
  'andhra pradesh': 'AP',
  'arunachal pradesh': 'AR',
  'assam': 'AS',
  'bihar': 'BR',
  'chhattisgarh': 'CG',
  'goa': 'GA',
  'gujarat': 'GJ',
  'haryana': 'HR',
  'himachal pradesh': 'HP',
  'jammu and kashmir': 'JK',
  'jharkhand': 'JH',
  'karnataka': 'KA',
  'kerala': 'KL',
  'madhya pradesh': 'MP',
  'maharashtra': 'MH',
  'manipur': 'MN',
  'meghalaya': 'ML',
  'mizoram': 'MZ',
  'odisha': 'OD',
  'orissa': 'OD',
  'punjab': 'PB',
  'rajasthan': 'RJ',
  'sikkim': 'SK',
  'tamil nadu': 'TN',
  'telangana': 'TS',
  'tripura': 'TR',
  'uttar pradesh': 'UP',
  'uttarakhand': 'UK',
  'west bengal': 'WB',
  'andaman and nicobar islands': 'AN',
  'chandigarh': 'CH',
  'delhi': 'DL',
  'dadra and nagar haveli and daman and diu': 'DH',
  'daman and diu': 'DD',
  'dadra and nagar haveli': 'DH',
  'ladakh': 'LA',
  'lakshadweep': 'LD',
  'puducherry': 'PY',
};

String? _normalizeStateCode(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final upper = trimmed.toUpperCase();
  if (_validStateCodes.contains(upper)) {
    return upper;
  }

  final normalizedName = trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return _stateNameToCode[normalizedName];
}

Future<OnboardingPrompt> processOnboardingInput(int chatId, String input) async {
  final s = _sessions[chatId];
  if (s == null) return OnboardingPrompt(text: '');
  final text = input.trim();

  // Allow cancel at any time
  if (text.toLowerCase() == 'cancel') {
    _sessions.remove(chatId);
    return OnboardingPrompt(text: 'Onboarding cancelled.');
  }

  switch (s.step) {
    case 0:
      if (text.length < 3 || _looksLikeGreeting(text)) {
        return OnboardingPrompt(
          text: 'Please enter your actual shop/business name (example: Mazi Shop).',
        );
      }
      s.data['shop_name'] = text;
      s.step = 1;
      return OnboardingPrompt(text: _askForState(s));
    case 1:
      final stateCode = _normalizeStateCode(text);
      if (stateCode == null) {
        return OnboardingPrompt(
          text: 'Please enter a valid Indian state name or code (example: Assam or AS).',
        );
      }
      s.data['state'] = stateCode;
      s.step = 2;
      return OnboardingPrompt(
        text: _askForGstRegistered(s),
        keyboard: _buildGstKeyboard(chatId),
      );
    case 2:
      // Text fallback for GST (in case user types instead of clicking)
      final n = text.toLowerCase();
      if (n == 'yes' || n == 'y') {
        s.data['gst_mode'] = 'REGISTERED';
        s.step = 3;
        return OnboardingPrompt(text: _askForGstNumber(s));
      } else if (n == 'no' || n == 'n') {
        s.data['gst_mode'] = 'UNREGISTERED';
        s.step = 4;
        return OnboardingPrompt(
          text: _askForBusinessType(s),
          keyboard: _buildBusinessTypeKeyboard(chatId),
        );
      } else {
        return OnboardingPrompt(text: 'Please reply with *yes* or *no*, or use the buttons.');
      }
    case 3:
      final gst = text.toUpperCase();
      if (_validateGstin(gst)) {
        s.data['gst_registration_number'] = gst;
        s.step = 4;
        return OnboardingPrompt(
          text: _askForBusinessType(s),
          keyboard: _buildBusinessTypeKeyboard(chatId),
        );
      }
      return OnboardingPrompt(text: 'GSTIN does not look valid. Please re-enter the 15-character GSTIN in uppercase.');
    case 4:
      s.data['business_type'] = text;
      s.step = 5;
      return OnboardingPrompt(
        text: _confirmSummary(s),
        keyboard: _buildConfirmationKeyboard(chatId),
      );
    case 5:
      final t = text.toLowerCase();
      if (t == 'confirm' || t == 'yes' || t == 'y') {
        // Persist shop record
        final shopId = _uuid.v4();
        final ownerId = _uuid.v5(Uuid.NAMESPACE_URL, 'telegram:${s.startedBy}');
        final insert = {
          'id': shopId,
          'owner_id': ownerId,
          'name': s.data['shop_name'],
          'state': s.data['state'],
          'gst_mode': s.data['gst_mode'] ?? 'UNREGISTERED',
          'gst_registration_number': s.data['gst_registration_number'],
          'business_type': s.data['business_type'],
          'onboarding_started_at': DateTime.now().toIso8601String(),
          'onboarding_completed': true,
          'created_by': s.startedBy,
        }..removeWhere((k, v) => v == null);

        try {
          await supabase.from('shops').insert(insert).select().single();
          _sessions.remove(chatId);
          return OnboardingPrompt(text: '✅ Onboarding complete. Your shop has been created and set as the active shop. You can now create bills.');
        } catch (e) {
          return OnboardingPrompt(text: 'Failed to create shop: $e');
        }
      } else if (t == 'cancel' || t == 'n') {
        _sessions.remove(chatId);
        return OnboardingPrompt(text: 'Onboarding cancelled.');
      } else {
        // At confirmation step, only buttons or confirm/cancel allowed - ignore other text
        return OnboardingPrompt(
          text: _confirmSummary(s),
          keyboard: _buildConfirmationKeyboard(chatId),
        );
      }
    default:
      _sessions.remove(chatId);
      return OnboardingPrompt(text: 'Onboarding session ended unexpectedly. Please start again with /start.');
  }
}

// Callback handlers for button presses
Future<OnboardingPrompt> handleGstButtonPress(int chatId, bool isYes) async {
  final s = _sessions[chatId];
  if (s == null || s.step != 2) return OnboardingPrompt(text: 'Onboarding session expired.');
  
  if (isYes) {
    s.data['gst_mode'] = 'REGISTERED';
    s.step = 3;
    return OnboardingPrompt(text: _askForGstNumber(s));
  } else {
    s.data['gst_mode'] = 'UNREGISTERED';
    s.step = 4;
    return OnboardingPrompt(
      text: _askForBusinessType(s),
      keyboard: _buildBusinessTypeKeyboard(chatId),
    );
  }
}

Future<OnboardingPrompt> handleBusinessTypeButtonPress(int chatId, String bizType) async {
  final s = _sessions[chatId];
  if (s == null || s.step != 4) return OnboardingPrompt(text: 'Onboarding session expired.');
  
  s.data['business_type'] = bizType;
  s.step = 5;
  return OnboardingPrompt(
    text: _confirmSummary(s),
    keyboard: _buildConfirmationKeyboard(chatId),
  );
}

Future<OnboardingPrompt> handleConfirmationButtonPress(int chatId, bool isSubmit) async {
  final s = _sessions[chatId];
  if (s == null || s.step != 5) return OnboardingPrompt(text: 'Onboarding session expired.');

  if (!isSubmit) {
    // Cancel
    _sessions.remove(chatId);
    return OnboardingPrompt(text: 'Onboarding cancelled.');
  }

  // Submit
  final shopId = _uuid.v4();
  final ownerId = _uuid.v5(Uuid.NAMESPACE_URL, 'telegram:${s.startedBy}');
  final insert = {
    'id': shopId,
    'owner_id': ownerId,
    'name': s.data['shop_name'],
    'state': s.data['state'],
    'gst_mode': s.data['gst_mode'] ?? 'UNREGISTERED',
    'gst_registration_number': s.data['gst_registration_number'],
    'business_type': s.data['business_type'],
    'onboarding_started_at': DateTime.now().toIso8601String(),
    'onboarding_completed': true,
    'created_by': s.startedBy,
  }..removeWhere((k, v) => v == null);

  try {
    await supabase.from('shops').insert(insert).select().single();
    _sessions.remove(chatId);
    return OnboardingPrompt(
      text: '✅ Onboarding complete. Your shop has been created and set as the active shop. You can now create bills.'
    );
  } catch (e) {
    return OnboardingPrompt(text: 'Failed to create shop: $e');
  }
}

bool _validateGstin(String gst) {
  if (gst.length != 15) return false;
  final re = RegExp(r'^[0-9A-Z]+$');
  return re.hasMatch(gst);
}
