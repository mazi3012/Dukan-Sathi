import 'package:dukansathi_server/core/database.dart';
import 'package:teledart/model.dart' as tg;
import 'package:uuid/uuid.dart';

// ─── STEP ENUM ────────────────────────────────────────────────────────────────
enum OnboardingStep {
  shopName,    // 0 – text
  state,       // 1 – text
  gstChoice,   // 2 – buttons
  gstin,       // 3 – text (only if registered)
  bizType,     // 4 – buttons
  upiId,       // 5 – text or skip
  review,      // 6 – summary with approve/reject
}

// ─── SESSION (in-memory) ──────────────────────────────────────────────────────
class OnboardingSession {
  OnboardingSession({required this.chatId, required this.createdBy})
      : step = OnboardingStep.shopName;

  final int chatId;
  final String createdBy;
  OnboardingStep step;

  String? shopName;
  String? state;
  String gstMode = 'UNREGISTERED';
  String? gstin;
  String? bizType;
  String? upiId;

  // Supabase draft row ID
  String? draftId;
}

// ─── SESSION STORE ────────────────────────────────────────────────────────────
final Map<int, OnboardingSession> _sessions = {};
// Track last processed callback data per chat to avoid duplicate handling
final Map<int, String> _lastCallback = {};
final _uuid = Uuid();

bool isInOnboarding(int chatId) => _sessions.containsKey(chatId);

// ─── RESULT TYPE ──────────────────────────────────────────────────────────────
class OnboardingResult {
  OnboardingResult({required this.text, this.keyboard, this.done = false});
  final String text;
  final tg.InlineKeyboardMarkup? keyboard;
  final bool done;
}

// ─── INLINE KEYBOARDS ─────────────────────────────────────────────────────────
tg.InlineKeyboardMarkup _gstKeyboard() => tg.InlineKeyboardMarkup(
      inlineKeyboard: [
        [
          tg.InlineKeyboardButton(text: '✅ Yes, I have GSTIN', callbackData: 'ob_gst_yes'),
          tg.InlineKeyboardButton(text: '❌ No GST',            callbackData: 'ob_gst_no'),
        ]
      ],
    );

tg.InlineKeyboardMarkup _bizKeyboard() => tg.InlineKeyboardMarkup(
      inlineKeyboard: [
        [
          tg.InlineKeyboardButton(text: '🛍 Retail',       callbackData: 'ob_biz_Retail'),
          tg.InlineKeyboardButton(text: '📦 Wholesale',    callbackData: 'ob_biz_Wholesale'),
        ],
        [
          tg.InlineKeyboardButton(text: '🏭 Manufacturer', callbackData: 'ob_biz_Manufacturer'),
          tg.InlineKeyboardButton(text: '🔧 Other',        callbackData: 'ob_biz_Other'),
        ],
      ],
    );

tg.InlineKeyboardMarkup _upiKeyboard() => tg.InlineKeyboardMarkup(
      inlineKeyboard: [
        [
          tg.InlineKeyboardButton(text: '⏭ Skip UPI', callbackData: 'ob_upi_skip'),
        ]
      ],
    );

tg.InlineKeyboardMarkup _reviewKeyboard() => tg.InlineKeyboardMarkup(
      inlineKeyboard: [
        [
          tg.InlineKeyboardButton(text: '❌ Cancel',  callbackData: 'ob_cancel'),
          tg.InlineKeyboardButton(text: '✅ Approve', callbackData: 'ob_approve'),
        ]
      ],
    );

// ─── SUMMARY TEXT ─────────────────────────────────────────────────────────────
String _summaryText(OnboardingSession s) =>
    '📋 *Please review your shop details:*\n\n'
    '🏪 *Shop Name:* ${s.shopName}\n'
    '📍 *State:* ${s.state}\n'
    '🧾 *GST Mode:* ${s.gstMode}${s.gstin != null ? '\n🆔 *GSTIN:* ${s.gstin}' : ''}\n'
    '💼 *Business Type:* ${s.bizType}\n'
    '💳 *UPI ID:* ${s.upiId ?? 'Not set'}\n\n'
    'Press *Approve* to save, or *Cancel* to discard.';

// ─── PERSIST DRAFT TO SUPABASE ────────────────────────────────────────────────
Future<void> _upsertDraft(OnboardingSession s) async {
  try {
    final data = <String, dynamic>{
      'telegram_chat_id': s.chatId,
      'created_by':       s.createdBy,
      'shop_name':        s.shopName,
      'state':            s.state,
      'gst_mode':         s.gstMode,
      'gst_registration_number': s.gstin,
      'business_type':    s.bizType,
      'upi_id':           s.upiId,
      'current_step':     s.step.index,
      'updated_at':       DateTime.now().toIso8601String(),
    }..removeWhere((_, v) => v == null);

    if (s.draftId == null) {
      final row = await supabase
          .from('onboarding_drafts')
          .insert(data)
          .select('id')
          .single();
      s.draftId = (row)['id'] as String;
    } else {
      await supabase
          .from('onboarding_drafts')
          .update(data)
          .eq('id', s.draftId!);
    }
  } catch (e) {
    // Non-fatal: session stays in memory even if DB save fails
    print('[onboarding][upsert-draft] WARNING: DB save failed (chat=${s.chatId}): $e');
  }
}

// ─── STATE CODE HELPERS ───────────────────────────────────────────────────────
const Set<String> _validStateCodes = {
  'AP','AR','AS','BR','CG','GA','GJ','HR','HP','JK','JH','KA',
  'KL','MP','MH','MN','ML','MZ','NL','OD','PB','RJ','SK','TN','TS',
  'TR','UP','UK','WB','AN','CH','DL','DD','DH','JL','LA','LD','PY',
};

const Map<String, String> _stateNameToCode = {
  'andhra pradesh': 'AP', 'arunachal pradesh': 'AR', 'assam': 'AS',
  'bihar': 'BR', 'chhattisgarh': 'CG', 'goa': 'GA', 'gujarat': 'GJ',
  'haryana': 'HR', 'himachal pradesh': 'HP', 'jammu and kashmir': 'JK',
  'jharkhand': 'JH', 'karnataka': 'KA', 'kerala': 'KL',
  'madhya pradesh': 'MP', 'maharashtra': 'MH', 'manipur': 'MN',
  'meghalaya': 'ML', 'mizoram': 'MZ', 'nagaland': 'NL', 'odisha': 'OD', 'orissa': 'OD',
  'punjab': 'PB', 'rajasthan': 'RJ', 'sikkim': 'SK', 'tamil nadu': 'TN',
  'telangana': 'TS', 'tripura': 'TR', 'uttar pradesh': 'UP',
  'uttarakhand': 'UK', 'west bengal': 'WB',
  'andaman and nicobar islands': 'AN', 'chandigarh': 'CH', 'delhi': 'DL',
  'daman and diu': 'DD', 'dadra and nagar haveli': 'DH',
  'dadra and nagar haveli and daman and diu': 'DH',
  'ladakh': 'LA', 'lakshadweep': 'LD', 'puducherry': 'PY',
};

String? _normalizeState(String raw) {
  final upper = raw.trim().toUpperCase();
  if (_validStateCodes.contains(upper)) return upper;
  final lower = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return _stateNameToCode[lower];
}

bool _validGstin(String v) =>
    v.length == 15 && RegExp(r'^[0-9A-Z]+$').hasMatch(v);

// ─── PUBLIC API ───────────────────────────────────────────────────────────────

/// Start a new onboarding session.
Future<OnboardingResult> startOnboarding(int chatId, String createdBy) async {
  _sessions.remove(chatId);
  _lastCallback.remove(chatId);

  try {
    // Check if user already has a shop linked to their telegram_id
    final userWithShop = await supabase
        .from('users')
        .select('id, shops!fk_shops_owner(id, name)')
        .eq('telegram_id', chatId)
        .maybeSingle();

    if (userWithShop != null && userWithShop['shops'] != null) {
      final shop = (userWithShop['shops'] as List).first;
      return OnboardingResult(
        text: '👋 *Welcome back!* Your shop *${shop['name']}* is already set up.\n\nHow can I help you today?',
        done: true,
      );
    }
  } catch (e) {
    print('[onboarding][start] Error checking existing user: $e');
  }

  final session = OnboardingSession(chatId: chatId, createdBy: createdBy);
  _sessions[chatId] = session;

  return OnboardingResult(
    text: '👋 *Welcome to Dukan Sathi Pro!* 🚀\n\n'
        "We're excited to help you manage and grow your retail business with AI.\n\n"
        '✨ Let\'s set up your shop. What is the *name of your shop?*',
  );
}

/// Handle a plain text message during onboarding.
Future<OnboardingResult> processOnboardingText(int chatId, String input) async {
  final s = _sessions[chatId];
  if (s == null) return OnboardingResult(text: '');

  final text = input.trim();
  if (text.isEmpty) return OnboardingResult(text: '');

  if (text.toLowerCase() == '/cancel') {
    await _cancelSession(chatId);
    return OnboardingResult(text: '❌ Onboarding cancelled. Send /start to begin again.');
  }

  print('[onboarding] chat=$chatId step=${s.step.name} input="$text"');

  switch (s.step) {
    case OnboardingStep.shopName:
      if (text.length < 2) {
        return OnboardingResult(text: '⚠️ Shop name is too short. Please enter a valid shop name.');
      }
      s.shopName = text;
      s.step = OnboardingStep.state;
      await _upsertDraft(s);
      return OnboardingResult(
        text: '📍 Which *state* is your shop in?\n_(e.g. Assam, AS, Maharashtra, MH)_',
      );

    case OnboardingStep.state:
      final code = _normalizeState(text);
      if (code == null) {
        return OnboardingResult(
          text: '⚠️ Could not recognise that state. Please enter a valid Indian state name or 2-letter code.\n_(e.g. "Assam" or "AS")_',
        );
      }
      s.state = code;
      s.step = OnboardingStep.gstChoice;
      await _upsertDraft(s);
      return OnboardingResult(
        text: '🧾 Is your shop *registered for GST?*',
        keyboard: _gstKeyboard(),
      );

    case OnboardingStep.gstChoice:
      return OnboardingResult(
        text: '👆 Please use the buttons above to select your GST status.',
        keyboard: _gstKeyboard(),
      );

    case OnboardingStep.gstin:
      final v = text.toUpperCase();
      if (!_validGstin(v)) {
        return OnboardingResult(
          text: '⚠️ Invalid GSTIN. It must be exactly 15 uppercase alphanumeric characters.\n\nPlease re-enter:',
        );
      }
      s.gstin = v;
      s.step = OnboardingStep.bizType;
      await _upsertDraft(s);
      return OnboardingResult(
        text: '💼 What is your *business type?*',
        keyboard: _bizKeyboard(),
      );

    case OnboardingStep.bizType:
      return OnboardingResult(
        text: '👆 Please use the buttons above to select your business type.',
        keyboard: _bizKeyboard(),
      );

    case OnboardingStep.upiId:
      s.upiId = text;
      s.step = OnboardingStep.review;
      await _upsertDraft(s);
      return OnboardingResult(
        text: _summaryText(s),
        keyboard: _reviewKeyboard(),
      );

    case OnboardingStep.review:
      return OnboardingResult(
        text: '👆 Please use the *Approve* or *Cancel* buttons to confirm.',
        keyboard: _reviewKeyboard(),
      );
  }
}

/// Handle a callback button press during onboarding.
Future<OnboardingResult?> processOnboardingCallback(int chatId, String data) async {
  if (!data.startsWith('ob_')) return null;

  // Prevent duplicate callbacks (Telegram sometimes fires twice)
  if (_lastCallback[chatId] == data) {
    print('[onboarding] chat=$chatId DUPLICATE callback ignored: "$data"');
    return null;
  }
  _lastCallback[chatId] = data;

  final s = _sessions[chatId];
  if (s == null) {
    return OnboardingResult(
      text: '⚠️ Session expired. Please send /start to begin again.',
    );
  }

  print('[onboarding] chat=$chatId step=${s.step.name} callback="$data"');

  // ── GST CHOICE ─────────────────────────────────────────────────────────────
  if (data == 'ob_gst_yes') {
    if (s.step != OnboardingStep.gstChoice) return null;
    s.gstMode = 'REGISTERED';
    s.step = OnboardingStep.gstin;
    await _upsertDraft(s);
    return OnboardingResult(text: '🆔 Please enter your *GSTIN* (15 characters):');
  }

  if (data == 'ob_gst_no') {
    if (s.step != OnboardingStep.gstChoice) return null;
    s.gstMode = 'UNREGISTERED';
    s.step = OnboardingStep.bizType;
    await _upsertDraft(s);
    return OnboardingResult(
      text: '💼 What is your *business type?*',
      keyboard: _bizKeyboard(),
    );
  }

  // ── BUSINESS TYPE → skip phone, go straight to UPI ─────────────────────────
  if (data.startsWith('ob_biz_')) {
    if (s.step != OnboardingStep.bizType) return null;
    final biz = data.replaceFirst('ob_biz_', '');
    s.bizType = biz;
    s.step = OnboardingStep.upiId;
    await _upsertDraft(s);
    return OnboardingResult(
      text: '💳 Enter your *UPI ID* for receiving payments _(optional)_\nor tap Skip:',
      keyboard: _upiKeyboard(),
    );
  }

  // ── UPI SKIP ───────────────────────────────────────────────────────────────
  if (data == 'ob_upi_skip') {
    if (s.step != OnboardingStep.upiId) return null;
    s.upiId = null;
    s.step = OnboardingStep.review;
    await _upsertDraft(s);
    return OnboardingResult(
      text: _summaryText(s),
      keyboard: _reviewKeyboard(),
    );
  }

  // ── APPROVE ────────────────────────────────────────────────────────────────
  if (data == 'ob_approve') {
    if (s.step != OnboardingStep.review) return null;
    return await _approveOnboarding(s);
  }

  // ── CANCEL ─────────────────────────────────────────────────────────────────
  if (data == 'ob_cancel') {
    await _cancelSession(chatId);
    return OnboardingResult(
      text: '❌ Onboarding cancelled. Send /start whenever you\'re ready to set up your shop.',
    );
  }

  return null;
}

// ─── APPROVE: persist shop ────────────────────────────────────────────────────
Future<OnboardingResult> _approveOnboarding(OnboardingSession s) async {
  try {
    final shopId = _uuid.v4();
    
    // 1. Ensure user exists in 'users' table
    // We upsert based on telegram_id to unify identity
    final userRow = await supabase
        .from('users')
        .upsert({
          'telegram_id': s.chatId,
          'full_name':   s.createdBy,
          'updated_at':  DateTime.now().toIso8601String(),
        }, onConflict: 'telegram_id')
        .select('id')
        .single();
    
    final ownerId = userRow['id'] as String;

    final insert = <String, dynamic>{
      'id':                       shopId,
      'owner_id':                 ownerId,
      'name':                     s.shopName,
      'state':                    s.state,
      'gst_mode':                 s.gstMode,
      'gst_registration_number':  s.gstin,
      'business_type':            s.bizType,
      'upi_id':                   s.upiId,
      'onboarding_completed':     true,
      'onboarding_started_at':    DateTime.now().toIso8601String(),
      'created_by':               s.createdBy,
    }..removeWhere((_, v) => v == null);

    await supabase.from('shops').insert(insert);

    if (s.draftId != null) {
      await supabase
          .from('onboarding_drafts')
          .update({'status': 'APPROVED', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', s.draftId!);
    }

    _sessions.remove(s.chatId);
    _lastCallback.remove(s.chatId);

    return OnboardingResult(
      text: '🎉 *Shop created successfully!*\n\n'
          '🏪 *${s.shopName}* is now live on Dukan Sathi Pro.\n\n'
          'You can now:\n'
          '• 🧾 Create invoices\n'
          '• 📦 Add products\n'
          '• 📊 View analytics\n\n'
          'Just tell me what you need!',
      done: true,
    );
  } catch (e) {
    print('[onboarding][approve] error: $e');
    return OnboardingResult(
      text: '❌ Failed to save your shop. Please try again.\n\nError: $e',
      keyboard: _reviewKeyboard(),
    );
  }
}

// ─── CANCEL SESSION ───────────────────────────────────────────────────────────
Future<void> _cancelSession(int chatId) async {
  final s = _sessions.remove(chatId);
  _lastCallback.remove(chatId);
  if (s?.draftId != null) {
    try {
      await supabase
          .from('onboarding_drafts')
          .update({'status': 'REJECTED', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', s!.draftId!);
    } catch (_) {}
  }
}
