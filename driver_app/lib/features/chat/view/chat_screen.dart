import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/chat/controller/chat_controller.dart';
import 'package:driver_app/widgets/chat_widgets/chat_message_bubble.dart';
import 'package:driver_app/widgets/chat_widgets/chat_input_field.dart';
import 'package:driver_app/widgets/chat_widgets/chat_header.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    print('🔄 _initializeChat called');
    final controller = ref.read(chatControllerProvider.notifier);

    try {
      // Get current trip ID from storage
      final storage = const FlutterSecureStorage();
      final tripId = await storage.read(key: 'currentTripId');

      if (tripId != null) {
        await controller.initializeChat(tripId);
        print('✅ Chat system initialized for trip: $tripId');
      } else {
        print('⚠️ No active trip found for chat initialization');
      }
    } catch (e) {
      print('❌ Error in _initializeChat: $e');
      print('🔄 Continuing with UI despite initialization error');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final controller = ref.read(chatControllerProvider.notifier);
    await controller.sendMessage(message);

    _messageController.clear();
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final controller = ref.read(chatControllerProvider.notifier);

    // Show error if any
    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorSnackBar(chatState.error!);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Header
            ChatHeader(
              chatContext: null,
              isConnected: chatState.isConnected,
              onRefresh: () async {
                final controller = ref.read(chatControllerProvider.notifier);
                await controller.refreshMessages();
              },
            ),

            // Messages List
            Expanded(
              child:
                  chatState.isLoading && chatState.messages.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF3B82F6),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading messages...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                      : chatState.messages.isEmpty
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Color(0xFF6B7280),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start a conversation!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: controller.sortedMessages.length,
                        itemBuilder: (context, index) {
                          final message = controller.sortedMessages[index];
                          final isLastMessage =
                              index == controller.sortedMessages.length - 1;

                          return Column(
                            children: [
                              ChatMessageBubble(
                                message: message,
                                isLastMessage: isLastMessage,
                              ),
                              if (isLastMessage) const SizedBox(height: 8),
                            ],
                          );
                        },
                      ),
            ),

            // Connection status indicator
            if (!chatState.isConnected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: const Text(
                        'Connection lost. Trying to reconnect...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _initializeChat,
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Chat Input
            ChatInputField(
              controller: _messageController,
              onSend: _sendMessage,
              isConnected: chatState.isConnected,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
