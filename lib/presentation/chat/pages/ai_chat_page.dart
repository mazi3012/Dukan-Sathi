import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../main/pages/main_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/invoice_draft_card.dart';
import '../widgets/inventory_draft_card.dart';
import '../widgets/ai_thinking_indicator.dart';
import '../widgets/analytics_summary_card.dart';
import '../widgets/customer_dues_card.dart';
import '../widgets/customer_due_detail_card.dart';
import '../widgets/expense_report_card.dart';
import '../widgets/invoice_lookup_card.dart';
import '../widgets/product_catalog_card.dart';
import '../widgets/payment_confirmation_card.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/widgets/barcode_scanner_dialog.dart';
import '../../../core/config.dart';


import '../../../core/widgets/dukan_sathi_logo.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isVoiceEnabled = false;
  final TtsService _ttsService = TtsService();
  late StreamSubscription<bool> _connectivitySubscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _isOnline = ConnectivityService.instance.isOnline;
    _connectivitySubscription = ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() {
          _isOnline = online;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatControllerProvider.notifier).loadHistory();
    });
  }


  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _audioRecorder.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig();
        await _audioRecorder.start(config, path: ''); 
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        _transcribeAudio(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _transcribeAudio(String path) async {
    setState(() => _isTranscribing = true);
    try {
      final response = await http.get(Uri.parse(path));
      final bytes = response.bodyBytes;

      final transResponse = await http.post(
        _getApiUri('/api/transcribe'),
        body: bytes,
      );

      if (transResponse.statusCode == 200) {
        final data = jsonDecode(transResponse.body);
        final text = data['text'] as String;
        if (text.trim().isNotEmpty) {
          _textController.text = text;
          _sendMessage(); // Auto-send transcribed text
        }
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
    } finally {
      setState(() => _isTranscribing = false);
    }
  }

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  void _openBarcodeScanner(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => BarcodeScannerDialog(
        onProductScanned: (product) {
          _textController.text = "Add ${product.name} to my bill";
          _sendMessage();
        },
      ),
    );
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.trash, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              "Clear Conversation?",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete all messages? This will also reset the AI assistant's short-term memory.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(chatControllerProvider.notifier).clearChat();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Chat cleared and AI memory reset!"),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  void _showApiUrlConfigDialog(BuildContext context) {
    final controller = TextEditingController(text: AppConfig.apiUrl);
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Iconsax.setting_2, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              "Assistant Server Config",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Configure the server URL that the Dukan Sathi AI assistant connects to.",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkGlassBorder),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: "API Server URL",
                    labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Quick Presets:",
                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    backgroundColor: Colors.white10,
                    label: const Text("Localhost (USB)", style: TextStyle(color: Colors.white, fontSize: 11)),
                    onPressed: () {
                      controller.text = "http://localhost:3100";
                    },
                  ),
                  ActionChip(
                    backgroundColor: Colors.white10,
                    label: const Text("Production (Render)", style: TextStyle(color: Colors.white, fontSize: 11)),
                    onPressed: () {
                      controller.text = "https://dukan-sathi-pro.onrender.com";
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 8),
              const Text(
                "💡 Physical Vivo Phone Testing Tip:",
                style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "1. Connect your Vivo phone via USB cable.\n"
                "2. Ensure USB Debugging is turned ON in developer options.\n"
                "3. Select 'Localhost (USB)' preset.\n"
                "4. Run this command on your computer terminal:\n"
                "   adb reverse tcp:3100 tcp:3100\n"
                "This links your physical phone directly to your computer's local Genkit server!",
                style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await AppConfig.setApiUrl(newUrl);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("API URL updated to: $newUrl"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider);

    // Auto-scroll when new messages arrive
    ref.listen<List<ChatMessage>>(chatControllerProvider, (previous, next) {
      if (previous?.length != next.length) {
        _scrollToBottom();
        
        // If voice is enabled, find the new messages and speak the AI text
        if (_isVoiceEnabled && previous != null && next.length > previous.length) {
          final newMessages = next.sublist(previous.length);
          for (var msg in newMessages) {
            if (msg.type == MessageType.aiText && !msg.isTyping) {
              _ttsService.speak(msg.text);
              break; // Speak the first new AI text found in this update
            }
          }
        }
      }
    });


    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Iconsax.arrow_left_2, color: Theme.of(context).iconTheme.color),
                onPressed: () => Navigator.pop(context),
              )
            : IconButton(
                icon: Icon(Iconsax.menu, color: Theme.of(context).iconTheme.color),
                onPressed: () => mainScaffoldKey.currentState?.openDrawer(),
              ),
        title: const DukanSathiHeader(
          height: 28,
          showGlow: false,
          animate: true,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Iconsax.setting_2, color: Theme.of(context).iconTheme.color),
            onPressed: () => _showApiUrlConfigDialog(context),
          ),
          IconButton(
            icon: Icon(Iconsax.trash, color: Theme.of(context).iconTheme.color),
            onPressed: () => _confirmClearChat(context),
          ),
          IconButton(
            icon: Icon(
              _isVoiceEnabled ? Iconsax.volume_high : Iconsax.volume_cross,
              color: _isVoiceEnabled ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
            ),
            onPressed: () {
              setState(() {
                _isVoiceEnabled = !_isVoiceEnabled;
              });
              if (!_isVoiceEnabled) {
                _ttsService.stop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Voice Output Enabled"),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: !_isOnline
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GlassBox(
                    blur: 20,
                    opacity: 0.1,
                    border: Border.all(color: AppColors.darkGlassBorder),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Iconsax.wifi_square,
                              size: 48,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "AI Assistant is Offline",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Dukan Sathi AI utilizes strictly online neural processing engines to run voice recognition and billing generation. Please check your internet connection.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isOnline = ConnectivityService.instance.isOnline;
                              });
                              if (_isOnline) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Connected! AI Voice Chat initialized."),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Iconsax.refresh, size: 18),
                            label: const Text("Retry Connection"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                // Background handled by Scaffold
                const SizedBox.expand(),
                
                // Chat List
                SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20).copyWith(
                          bottom: 100,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildMessageRow(context, msg),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                // Input Area
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _buildInputArea(context),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageRow(BuildContext context, ChatMessage msg) {
    switch (msg.type) {
      case MessageType.user:
        return _buildUserMessage(context, msg.text);
      case MessageType.aiText:
        return _buildAiMessage(context, msg.text, msg.isTyping);
      case MessageType.aiDraftInvoice:
        return InvoiceDraftCard(payload: msg.payload as Map<String, dynamic>?);
      case MessageType.aiDraftInventory:
        return InventoryDraftCard(payload: msg.payload);
      case MessageType.aiAnalyticsSummary:
        return AnalyticsSummaryCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      case MessageType.aiCustomerDuesList:
        return CustomerDuesCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      case MessageType.aiCustomerDueDetail:
        return CustomerDueDetailCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      case MessageType.aiExpenseReport:
        return ExpenseReportCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      case MessageType.aiInvoiceLookup:
        return InvoiceLookupCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      case MessageType.aiProductCatalog:
        return ProductCatalogCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      case MessageType.aiPaymentConfirmation:
        return PaymentConfirmationCard(payload: Map<String, dynamic>.from(msg.payload as Map));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserMessage(BuildContext context, String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  Widget _buildAiMessage(BuildContext context, String text, bool isTyping) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 40),
        child: GlassBox(
          opacity: 0.1,
          blur: 10,
          borderRadius: 12,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? AppColors.darkGlassBorder 
                : AppColors.lightGlassBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isTyping
                ? const AiThinkingIndicator()
                : Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 15,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0
                ? 15
                : MediaQuery.of(context).padding.bottom + 15,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? AppColors.darkGlassBorder 
                    : AppColors.lightGlassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? AppColors.darkGlassBorder 
                          : AppColors.lightGlassBorder,
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _isTranscribing ? "Transcribing..." : "Ask Dukan Sathi...",
                      hintStyle: Theme.of(context).textTheme.bodySmall,
                      border: InputBorder.none,
                      icon: IconButton(
                        icon: const Icon(Iconsax.scan, color: AppColors.primary),
                        onPressed: () => _openBarcodeScanner(context),
                      ),
                      suffixIcon: _isTranscribing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                },
                onLongPress: _startRecording,
                onLongPressUp: _stopRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording 
                        ? Colors.red.withOpacity(0.2) 
                        : Theme.of(context).cardColor,
                    border: Border.all(
                      color: _isRecording 
                          ? Colors.red 
                          : (Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkGlassBorder 
                              : AppColors.lightGlassBorder),
                    ),
                    boxShadow: _isRecording
                        ? [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    _isRecording ? Iconsax.stop : Iconsax.microphone_2,
                    color: _isRecording ? Colors.red : Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Iconsax.send_1, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Uri _getApiUri(String path) {
  return AppConfig.getApiUri(path);
}
