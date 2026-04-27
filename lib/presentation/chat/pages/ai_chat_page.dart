import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_box.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/invoice_draft_card.dart';
import '../widgets/inventory_draft_card.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _textController.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatControllerProvider.notifier).sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
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
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.magic_star, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                "Dukan Sathi",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F111A), Color(0xFF1E1936)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Chat List
          SafeArea(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(20).copyWith(
                bottom: MediaQuery.of(context).viewInsets.bottom + 140,
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
          
          // Input Area
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildInputArea(context),
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
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
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
          borderRadius: 20,
          border: Border.all(color: AppColors.darkGlassBorder),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isTyping
                ? const SizedBox(
                    width: 30,
                    height: 20,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  )
                : Text(text, style: const TextStyle(color: Colors.white, fontSize: 15)),
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
            color: AppColors.darkBackground.withOpacity(0.8),
            border: const Border(top: BorderSide(color: AppColors.darkGlassBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.darkGlassBorder),
                  ),
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Ask Dukan Sathi...",
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      icon: Icon(Iconsax.camera, color: Colors.white54),
                    ),
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
                      color: AppColors.primary.withOpacity(0.4),
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
