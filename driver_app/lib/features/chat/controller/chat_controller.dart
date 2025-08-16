import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driver_app/features/chat/service/chat_service.dart';
import 'package:driver_app/features/chat/models/chat_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/core/error_handler.dart';

class ChatState {
  final bool isLoading;
  final String? error;
  final List<ChatMessage> messages;
  final String? currentTripId;
  final bool isConnected;
  final int unreadCount;

  const ChatState({
    this.isLoading = false,
    this.error,
    this.messages = const [],
    this.currentTripId,
    this.isConnected = false,
    this.unreadCount = 0,
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    List<ChatMessage>? messages,
    String? currentTripId,
    bool? isConnected,
    int? unreadCount,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      messages: messages ?? this.messages,
      currentTripId: currentTripId ?? this.currentTripId,
      isConnected: isConnected ?? this.isConnected,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final ChatService _chatService;

  ChatController(this._chatService) : super(const ChatState());

  /// Initialize chat for a specific trip
  Future<void> initializeChat(String tripId) async {
    try {
      print('🔄 ChatController: Initializing chat for trip: $tripId');

      state = state.copyWith(isLoading: true, error: null);

      // Set current trip ID
      state = state.copyWith(currentTripId: tripId);

      // Load ALL messages for the trip (from database, not just local)
      final messages = await _chatService.getAllMessagesForTrip(tripId);

      // Calculate unread count
      final unreadCount = messages.where((msg) => !msg.isRead).length;

      state = state.copyWith(
        isLoading: false,
        messages: messages,
        unreadCount: unreadCount,
        isConnected: true,
      );

      print(
        '✅ ChatController: Chat initialized with ${messages.length} messages from all users',
      );
    } catch (e) {
      print('❌ ChatController: Error initializing chat - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Send a new message
  Future<bool> sendMessage(String messageText) async {
    try {
      if (state.currentTripId == null) {
        print('❌ ChatController: No active trip for sending message');
        return false;
      }

      print('📤 ChatController: Sending message: $messageText');

      // Get current user info
      final storage = const FlutterSecureStorage();
      final userId = await storage.read(key: 'userId');
      final userName = await storage.read(key: 'userName') ?? 'Driver';

      if (userId == null) {
        print('❌ ChatController: User ID not found');
        return false;
      }

      // Create chat message
      final message = ChatMessage.create(
        tripId: state.currentTripId!,
        senderId: userId,
        senderName: userName,
        senderType: 'DRIVER',
        message: messageText,
        type: MessageType.text,
      );

      // Send via WebSocket
      final success = await _chatService.sendMessage(message);

      if (success) {
        // Add message to local state
        final updatedMessages = [...state.messages, message];
        state = state.copyWith(
          messages: updatedMessages,
          unreadCount: state.unreadCount + 1,
        );

        print('✅ ChatController: Message sent and added to state');
        return true;
      } else {
        print('❌ ChatController: Failed to send message');
        return false;
      }
    } catch (e) {
      print('❌ ChatController: Error sending message - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(error: errorMessage);
      return false;
    }
  }

  /// Load messages from local storage
  Future<void> loadMessages() async {
    try {
      if (state.currentTripId == null) {
        print('❌ ChatController: No active trip for loading messages');
        return;
      }

      print(
        '🔄 ChatController: Loading messages for trip: ${state.currentTripId}',
      );

      state = state.copyWith(isLoading: true);

      // Load ALL messages for the trip (complete history from all users)
      final messages = await _chatService.getAllMessagesForTrip(
        state.currentTripId!,
      );
      final unreadCount = messages.where((msg) => !msg.isRead).length;

      state = state.copyWith(
        isLoading: false,
        messages: messages,
        unreadCount: unreadCount,
      );

      print(
        '✅ ChatController: Loaded ${messages.length} messages (complete history)',
      );
    } catch (e) {
      print('❌ ChatController: Error loading messages - $e');
      final errorMessage = ErrorHandler.handleError(e);
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead() async {
    try {
      if (state.currentTripId == null) return;

      print('👁️ ChatController: Marking messages as read');

      // Update local state
      final updatedMessages =
          state.messages.map((msg) => msg.markAsRead()).toList();

      state = state.copyWith(messages: updatedMessages, unreadCount: 0);

      // Mark as read in service
      await _chatService.markMessagesAsRead(state.currentTripId!);

      print('✅ ChatController: Messages marked as read');
    } catch (e) {
      print('❌ ChatController: Error marking messages as read - $e');
    }
  }

  /// Clear chat for current trip
  Future<void> clearChat() async {
    try {
      if (state.currentTripId == null) return;

      print(
        '🗑️ ChatController: Clearing chat for trip: ${state.currentTripId}',
      );

      // Clear messages from service
      await _chatService.clearTripMessages(state.currentTripId!);

      // Clear local state
      state = state.copyWith(messages: [], unreadCount: 0);

      print('✅ ChatController: Chat cleared successfully');
    } catch (e) {
      print('❌ ChatController: Error clearing chat - $e');
    }
  }

  /// Refresh messages (useful for syncing)
  Future<void> refreshMessages() async {
    try {
      if (state.currentTripId == null) return;

      print('🔄 ChatController: Refreshing messages from database...');

      // Force refresh from database to get latest messages
      final messages = await _chatService.getAllMessagesForTrip(
        state.currentTripId!,
      );
      final unreadCount = messages.where((msg) => !msg.isRead).length;

      state = state.copyWith(messages: messages, unreadCount: unreadCount);

      print(
        '✅ ChatController: Refreshed ${messages.length} messages from database',
      );
    } catch (e) {
      print('❌ ChatController: Error refreshing messages - $e');
    }
  }

  /// Get current messages
  List<ChatMessage> get messages => state.messages;

  /// Get current trip ID
  String? get currentTripId => state.currentTripId;

  /// Check if chat is connected
  bool get isConnected => state.isConnected;

  /// Get loading state
  bool get isLoading => state.isLoading;

  /// Get error message
  String? get error => state.error;

  /// Get unread count
  int get unreadCount => state.unreadCount;

  /// Check if there are unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Handle incoming message from other users (real-time updates)
  void handleIncomingMessage(ChatMessage message) {
    try {
      if (state.currentTripId != null &&
          message.tripId == state.currentTripId) {
        print(
          '📨 ChatController: Handling incoming message: ${message.message}',
        );

        // Check if message already exists to avoid duplicates
        final exists = state.messages.any((msg) => msg.id == message.id);
        if (!exists) {
          final updatedMessages = [...state.messages, message];
          final updatedUnreadCount = state.unreadCount + 1;

          state = state.copyWith(
            messages: updatedMessages,
            unreadCount: updatedUnreadCount,
          );

          print('✅ ChatController: Added incoming message to chat');
        } else {
          print(
            'ℹ️ ChatController: Message already exists, skipping duplicate',
          );
        }
      }
    } catch (e) {
      print('❌ ChatController: Error handling incoming message - $e');
    }
  }

  /// Get messages sorted by timestamp (oldest first)
  List<ChatMessage> get sortedMessages {
    final sorted = List<ChatMessage>.from(state.messages);
    sorted.sort(
      (a, b) =>
          DateTime.parse(a.timestamp).compareTo(DateTime.parse(b.timestamp)),
    );
    return sorted;
  }
}

// Provider for ChatController
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    return ChatController(ChatService());
  },
);
