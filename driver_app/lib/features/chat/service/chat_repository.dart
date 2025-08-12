import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/features/chat/models/chat_models.dart';
import 'package:driver_app/core/error_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Repository service for handling chat message persistence
class ChatRepository {
  static final ChatRepository instance = ChatRepository._internal();
  ChatRepository._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  // Cache for in-memory message storage
  final Map<String, List<ChatMessage>> _messageCache = {};

  /// Get messages for a specific trip
  Future<List<ChatMessage>> getMessages(String tripId) async {
    try {
      print('📋 ChatRepository: Getting messages for trip: $tripId');

      // Check in-memory cache first
      if (_messageCache.containsKey(tripId)) {
        final cachedMessages = _messageCache[tripId]!;
        print(
          '✅ ChatRepository: Found ${cachedMessages.length} messages in cache',
        );
        return cachedMessages;
      }

      // Check local storage
      final localMessages = await _getMessagesFromLocalStorage(tripId);
      if (localMessages.isNotEmpty) {
        print(
          '✅ ChatRepository: Found ${localMessages.length} messages in local storage',
        );
        _messageCache[tripId] = localMessages;
        return localMessages;
      }

      // Fetch from database
      print('🔄 ChatRepository: Fetching messages from database...');
      final dbMessages = await _fetchMessagesFromDatabase(tripId);

      _messageCache[tripId] = dbMessages;
      await _saveMessagesToLocalStorage(tripId, dbMessages);

      print(
        '✅ ChatRepository: Retrieved ${dbMessages.length} messages from database',
      );
      return dbMessages;
    } catch (e) {
      print('❌ ChatRepository: Error getting messages - $e');
      return [];
    }
  }

  /// Save a new message
  Future<bool> saveMessage(ChatMessage message) async {
    try {
      print('💾 ChatRepository: Saving message: ${message.message}');

      // Add to cache
      if (!_messageCache.containsKey(message.tripId)) {
        _messageCache[message.tripId] = [];
      }
      _messageCache[message.tripId]!.add(message);

      // Save to local storage
      await _saveMessagesToLocalStorage(
        message.tripId,
        _messageCache[message.tripId]!,
      );

      // Save to database (async)
      _saveMessageToDatabase(message).catchError((e) {
        print('⚠️ ChatRepository: Failed to save message to database - $e');
      });

      print('✅ ChatRepository: Message saved successfully');
      return true;
    } catch (e) {
      print('❌ ChatRepository: Error saving message - $e');
      return false;
    }
  }

  /// Mark messages as read for a trip
  Future<bool> markMessagesAsRead(String tripId) async {
    try {
      print('👁️ ChatRepository: Marking messages as read for trip: $tripId');

      // Update cache
      if (_messageCache.containsKey(tripId)) {
        final messages = _messageCache[tripId]!;
        for (int i = 0; i < messages.length; i++) {
          if (!messages[i].isRead) {
            messages[i] = messages[i].markAsRead();
          }
        }
      }

      // Update local storage
      await _saveMessagesToLocalStorage(tripId, _messageCache[tripId] ?? []);

      print('✅ ChatRepository: Messages marked as read');
      return true;
    } catch (e) {
      print('❌ ChatRepository: Error marking messages as read - $e');
      return false;
    }
  }

  /// Clear messages for a specific trip
  Future<void> clearMessages(String tripId) async {
    try {
      print('🗑️ ChatRepository: Clearing messages for trip: $tripId');

      _messageCache.remove(tripId);
      await _storage.delete(key: 'chat_messages_$tripId');

      print('✅ ChatRepository: Messages cleared for trip: $tripId');
    } catch (e) {
      print('❌ ChatRepository: Error clearing messages - $e');
    }
  }

  /// Get message count for a trip
  int getMessageCount(String tripId) {
    return _messageCache[tripId]?.length ?? 0;
  }

  /// Check if trip has unread messages
  bool hasUnreadMessages(String tripId) {
    final messages = _messageCache[tripId];
    if (messages == null) return false;
    return messages.any((message) => !message.isRead);
  }

  /// Get unread message count for a trip
  int getUnreadCount(String tripId) {
    final messages = _messageCache[tripId];
    if (messages == null) return 0;
    return messages.where((message) => !message.isRead).length;
  }

  // Private methods for local storage operations

  Future<List<ChatMessage>> _getMessagesFromLocalStorage(String tripId) async {
    try {
      final key = 'chat_messages_$tripId';
      final data = await _storage.read(key: key);

      if (data == null) return [];

      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      print('❌ ChatRepository: Error reading from local storage - $e');
      return [];
    }
  }

  Future<void> _saveMessagesToLocalStorage(
    String tripId,
    List<ChatMessage> messages,
  ) async {
    try {
      final key = 'chat_messages_$tripId';
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      final data = jsonEncode(jsonList);

      await _storage.write(key: key, value: data);
      print(
        '💾 ChatRepository: Saved ${messages.length} messages to local storage',
      );
    } catch (e) {
      print('❌ ChatRepository: Error saving to local storage - $e');
    }
  }

  // Private methods for database operations

  Future<List<ChatMessage>> _fetchMessagesFromDatabase(String tripId) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/chat/messages/$tripId';
      print('📡 ChatRepository: Fetching messages from: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> messagesJson = responseData['data'];
          final messages =
              messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

          print(
            '✅ ChatRepository: Fetched ${messages.length} messages from database',
          );
          return messages;
        } else {
          print('ℹ️ ChatRepository: No messages found in database');
          return [];
        }
      } else {
        print(
          '⚠️ ChatRepository: Database returned status: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('❌ ChatRepository: Error fetching from database - $e');
      return [];
    }
  }

  Future<void> _saveMessageToDatabase(ChatMessage message) async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/chat/messages';
      print('📡 ChatRepository: Saving message to database: $url');

      final response = await _dio.post(
        url,
        data: message.toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ ChatRepository: Message saved to database successfully');
      } else {
        print(
          '⚠️ ChatRepository: Database save returned status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ ChatRepository: Error saving to database - $e');
      rethrow;
    }
  }

  /// Refresh messages from database
  Future<void> refreshMessages(String tripId) async {
    try {
      print('🔄 ChatRepository: Refreshing messages for trip: $tripId');

      _messageCache.remove(tripId);
      await _storage.delete(key: 'chat_messages_$tripId');

      final messages = await _fetchMessagesFromDatabase(tripId);

      _messageCache[tripId] = messages;
      await _saveMessagesToLocalStorage(tripId, messages);

      print('✅ ChatRepository: Messages refreshed successfully');
    } catch (e) {
      print('❌ ChatRepository: Error refreshing messages - $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      print('🗑️ ChatRepository: Clearing all cached data');

      _messageCache.clear();

      final keys = await _storage.readAll();
      for (final key in keys.keys) {
        if (key.startsWith('chat_messages_')) {
          await _storage.delete(key: key);
        }
      }

      print('✅ ChatRepository: All cached data cleared');
    } catch (e) {
      print('❌ ChatRepository: Error clearing cache - $e');
    }
  }
}
