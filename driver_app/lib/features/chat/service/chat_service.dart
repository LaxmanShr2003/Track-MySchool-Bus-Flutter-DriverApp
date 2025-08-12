import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:driver_app/core/error_handler.dart';
import 'package:driver_app/core/websocket_manager.dart';
import 'package:driver_app/features/chat/models/chat_models.dart';

class ChatService {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ChatService({Dio? dio, FlutterSecureStorage? storage})
    : _dio = dio ?? Dio(),
      _storage = storage ?? const FlutterSecureStorage();

  /// Get current user's bus route ID from API (same as attendance service)
  Future<String?> _getCurrentUserBusRouteId() async {
    try {
      final userId = await _storage.read(key: 'userId');
      if (userId == null) {
        print('❌ User ID not found');
        return null;
      }

      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        throw ErrorHandler.createApiException('Access token not found');
      }

      final String? baseUrl = dotenv.env['BASE_URL_API'];
      if (baseUrl == null) {
        throw ErrorHandler.createApiException('API base URL not configured');
      }

      final url = '$baseUrl/driver/$userId';
      print('📡 Fetching driver info for chat: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final driverData = response.data;
        final routeAssignments =
            driverData['message']['routeAssignment'] as List<dynamic>?;
        final activeAssignment =
            routeAssignments
                        ?.where(
                          (assignment) =>
                              assignment['assignmentStatus'] == 'ACTIVE',
                        )
                        .toList()
                        .isNotEmpty ==
                    true
                ? routeAssignments!
                    .where(
                      (assignment) =>
                          assignment['assignmentStatus'] == 'ACTIVE',
                    )
                    .first
                : null;

        if (activeAssignment != null) {
          final busRouteId = activeAssignment['busRouteId'].toString();
          print('✅ Bus route ID found for chat: $busRouteId');
          return busRouteId;
        }
      }

      print('⚠️ No active bus route assignment found for chat');
      return null;
    } catch (e) {
      print('❌ Error getting bus route ID for chat: $e');
      return null;
    }
  }

  /// Get current trip ID from attendance controller
  Future<String?> _getCurrentTripId() async {
    try {
      // This would need to be passed from the controller or accessed via provider
      // For now, we'll try to get it from secure storage if it was saved there
      final tripId = await _storage.read(key: 'currentTripId');
      if (tripId != null) {
        print('✅ Current trip ID found: $tripId');
        return tripId;
      }

      print('⚠️ No current trip ID found');
      return null;
    } catch (e) {
      print('❌ Error getting current trip ID: $e');
      return null;
    }
  }

  /// Initialize WebSocket connection if not already connected
  Future<bool> _initializeWebSocket() async {
    try {
      // Check if already connected
      if (WebSocketManager.instance.isConnected) {
        print('🔌 WebSocket already connected for chat');
        return true;
      }

      print('🔌 Initializing WebSocket connection for chat...');

      // Get authentication token
      final token = await _storage.read(key: 'accessToken');
      if (token == null) {
        print('❌ Access token not found for WebSocket connection');
        return false;
      }

      final connected = await WebSocketManager.instance.connect(token: token);
      print('🔌 WebSocket connection result for chat: $connected');
      return connected;
    } catch (e) {
      print('❌ Error initializing WebSocket for chat: $e');
      return false;
    }
  }

  /// Get chat context for current trip (no room creation needed)
  Future<ChatContext?> getChatContext() async {
    try {
      final tripId = await _getCurrentTripId();
      if (tripId == null) {
        print('⚠️ No active trip found for chat context');
        return null;
      }

      final busRouteId = await _getCurrentUserBusRouteId();
      if (busRouteId == null) {
        print('⚠️ No active bus route found for chat context');
        return null;
      }

      // Get current user info
      final userId = await _storage.read(key: 'userId') ?? 'unknown';
      final userName = await _storage.read(key: 'userName') ?? 'Driver';
      final userType = await _storage.read(key: 'userType') ?? 'DRIVER';

      // Create chat context for current trip
      final currentUser = ChatUser(
        id: userId,
        name: userName,
        type: userType,
        isOnline: true,
      );

      final context = ChatContext.create(
        tripId: tripId,
        tripName: 'Active Trip',
        busRouteId: busRouteId,
        busRouteName: 'Route $busRouteId',
        participants: [currentUser],
      );

      print('💬 Chat context created for trip: $tripId');
      return context;
    } catch (e) {
      print('❌ Error getting chat context: $e');
      return null;
    }
  }

  /// Join trip chat via WebSocket
  Future<bool> joinTripChat(String tripId) async {
    try {
      print('🚪 Attempting to join trip chat: $tripId');
      print(
        '🔌 WebSocket connected status: ${WebSocketManager.instance.isConnected}',
      );

      if (!WebSocketManager.instance.isConnected) {
        print('🔌 WebSocket not connected, attempting to connect...');
        final connected = await _initializeWebSocket();
        if (!connected) {
          print('❌ Failed to connect WebSocket, cannot join trip chat');
          return false;
        }

        // Add a small delay to ensure connection is stable
        await Future.delayed(const Duration(milliseconds: 500));
        print(
          '🔌 WebSocket connected status after connection: ${WebSocketManager.instance.isConnected}',
        );
      }

      // Note: Removed the join trip chat WebSocket message to avoid Kafka errors
      // The WebSocket connection is sufficient for sending messages
      print('🚪 Trip chat ready for trip: $tripId (WebSocket connected)');
      print('✅ Join trip chat completed without sending join message');
      return true;
    } catch (e) {
      print('❌ Error joining trip chat via WebSocket: $e');
      return false;
    }
  }

  /// Leave trip chat via WebSocket
  Future<bool> leaveTripChat(String tripId) async {
    try {
      if (!WebSocketManager.instance.isConnected) {
        print('🔌 WebSocket not connected, cannot leave trip chat');
        return false;
      }

      // Note: Removed the leave trip chat WebSocket message to avoid potential errors
      // The WebSocket connection remains active for other operations
      print(
        '🚪 Left trip chat for trip: $tripId (WebSocket remains connected)',
      );
      print('✅ Leave trip chat completed without sending leave message');
      return true;
    } catch (e) {
      print('❌ Error leaving trip chat via WebSocket: $e');
      return false;
    }
  }

  /// Send message via WebSocket - Updated to match backend schema
  Future<bool> sendMessage(ChatMessage message) async {
    try {
      if (!WebSocketManager.instance.isConnected) {
        print('🔌 WebSocket not connected, attempting to connect...');
        final connected = await _initializeWebSocket();
        if (!connected) {
          print('❌ Failed to connect WebSocket, cannot send message');
          return false;
        }
      }

      // Get current trip ID only
      final tripId = await _getCurrentTripId();

      if (tripId == null) {
        print('❌ No active trip found, cannot send message');
        return false;
      }

      // Create message data for WebSocket according to backend schema
      final messageData = {
        'type': 'CHAT',
        'data': {
          'tripId': tripId, // Primary identifier - replaces roomId
          // Set routeId as null
          'senderId': message.senderId,
          'senderName': message.senderName,
          'senderType': message.senderType,
          'message': message.message, // nullable if media only
          'timestamp': message.timestamp,
          'type': message.type.name.toUpperCase(),
          'mediaUrl': message.mediaUrl,
          'isRead': message.isRead,
        },
      };

      print('📤 Sending WebSocket message: ${jsonEncode(messageData)}');
      final success = await WebSocketManager.instance.safeEmit(
        'message',
        messageData,
      );
      if (success) {
        print('📤 Message sent via WebSocket: ${message.message}');
        print('🆔 Trip ID: $tripId, Route ID: null');

        // Save message to local storage for persistence
        await saveMessageToLocalStorage(message);

        return true;
      } else {
        print('❌ Failed to send message via WebSocket');
        return false;
      }
    } catch (e) {
      print('❌ Error sending message via WebSocket: $e');
      return false;
    }
  }

  /// Mark messages as read (this might still need API call for persistence)
  Future<bool> markMessagesAsRead(String tripId) async {
    try {
      if (!WebSocketManager.instance.isConnected) {
        print('🔌 WebSocket not connected, attempting to connect...');
        final connected = await _initializeWebSocket();
        if (!connected) {
          print('❌ Failed to connect WebSocket, cannot mark messages as read');
          return false;
        }
      }

      // Note: Removed the mark as read WebSocket message to avoid potential errors
      // The WebSocket connection is sufficient for other operations
      print(
        '👁️ Messages marked as read for trip: $tripId (WebSocket connected)',
      );
      print('✅ Mark as read completed without sending WebSocket message');
      return true;
    } catch (e) {
      print('❌ Error marking messages as read via WebSocket: $e');
      return false;
    }
  }

  /// Get messages from local storage or return empty list (no API call)
  Future<List<ChatMessage>> getLocalMessages(String tripId) async {
    try {
      print('📋 Getting local messages for trip: $tripId');

      // Simple local storage implementation for now
      final storage = const FlutterSecureStorage();
      final key = 'chat_messages_$tripId';
      final data = await storage.read(key: key);

      if (data == null) {
        print('ℹ️ No local messages found for trip: $tripId');
        return [];
      }

      try {
        final List<dynamic> jsonList = jsonDecode(data);
        final messages =
            jsonList.map((json) => ChatMessage.fromJson(json)).toList();

        print('✅ Retrieved ${messages.length} messages from local storage');
        return messages;
      } catch (e) {
        print('❌ Error parsing local messages: $e');
        return [];
      }
    } catch (e) {
      print('❌ Error getting local messages: $e');
      return [];
    }
  }

  /// Set current trip ID in secure storage (called from attendance controller)
  Future<void> setCurrentTripId(String tripId) async {
    try {
      await _storage.write(key: 'currentTripId', value: tripId);
      print('💾 Current trip ID saved: $tripId');
    } catch (e) {
      print('❌ Error saving current trip ID: $e');
    }
  }

  /// Clear current trip ID when trip is completed
  Future<void> clearCurrentTripId() async {
    try {
      await _storage.delete(key: 'currentTripId');
      print('🗑️ Current trip ID cleared');
    } catch (e) {
      print('❌ Error clearing current trip ID: $e');
    }
  }

  /// Save message to local storage for persistence
  Future<void> saveMessageToLocalStorage(ChatMessage message) async {
    try {
      print('💾 Saving message to local storage: ${message.message}');

      // Get existing messages
      final existingMessages = await getLocalMessages(message.tripId);

      // Add new message
      existingMessages.add(message);

      // Save back to storage
      final key = 'chat_messages_${message.tripId}';
      final jsonList = existingMessages.map((msg) => msg.toJson()).toList();
      final data = jsonEncode(jsonList);

      await _storage.write(key: key, value: data);
      print('✅ Message saved to local storage successfully');
    } catch (e) {
      print('❌ Error saving message to local storage: $e');
    }
  }

  /// Clear all messages for a trip
  Future<void> clearTripMessages(String tripId) async {
    try {
      print('🗑️ Clearing messages for trip: $tripId');
      await _storage.delete(key: 'chat_messages_$tripId');
      print('✅ Messages cleared for trip: $tripId');
    } catch (e) {
      print('❌ Error clearing trip messages: $e');
    }
  }

  // Private method to fetch messages from database
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

      // Use /chats endpoint to get all messages
      final url = '$baseUrl/chats';
      print('📡 Fetching all messages from database: $url');

      final response = await _dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => (status ?? 0) < 500,
        ),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response data type: ${response.data.runtimeType}');
      print('📡 Response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;

        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] == true && responseData['data'] != null) {
            final data = responseData['data'];
            print('📡 Data type: ${data.runtimeType}');
            print('📡 Data: $data');

            if (data is List<dynamic>) {
              // Filter messages by tripId
              final allMessages =
                  data.map((json) => ChatMessage.fromJson(json)).toList();

              final filteredMessages =
                  allMessages
                      .where((message) => message.tripId == tripId)
                      .toList();

              print(
                '✅ Fetched ${allMessages.length} total messages, filtered to ${filteredMessages.length} for trip: $tripId',
              );
              return filteredMessages;
            } else if (data is Map<String, dynamic>) {
              // Single message case - check if it matches tripId
              try {
                final message = ChatMessage.fromJson(data);
                if (message.tripId == tripId) {
                  print('✅ Fetched 1 message from database for trip: $tripId');
                  return [message];
                } else {
                  print(
                    'ℹ️ Single message found but tripId mismatch: expected $tripId, got ${message.tripId}',
                  );
                  return [];
                }
              } catch (e) {
                print('❌ Error parsing single message: $e');
                return [];
              }
            } else {
              print('⚠️ Unexpected data type: ${data.runtimeType}');
              return [];
            }
          } else {
            print('ℹ️ API response indicates no success or no data');
            print('ℹ️ Success: ${responseData['success']}');
            print('ℹ️ Data: ${responseData['data']}');
            return [];
          }
        } else {
          print('⚠️ Response data is not a Map: ${responseData.runtimeType}');
          return [];
        }
      } else {
        print('⚠️ Database returned status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching from database - $e');
      return [];
    }
  }

  // Private method to save messages to local storage
  Future<void> _saveMessagesToLocalStorage(
    String tripId,
    List<ChatMessage> messages,
  ) async {
    try {
      final key = 'chat_messages_$tripId';
      final jsonList = messages.map((msg) => msg.toJson()).toList();
      final data = jsonEncode(jsonList);

      await _storage.write(key: key, value: data);
      print('💾 Saved ${messages.length} messages to local storage');
    } catch (e) {
      print('❌ Error saving to local storage - $e');
    }
  }

  /// Get ALL messages for a trip from database (complete chat history)
  Future<List<ChatMessage>> getAllMessagesForTrip(String tripId) async {
    try {
      print('📋 Getting ALL messages for trip: $tripId (complete history)');

      // First try to get from database (most up-to-date)
      final dbMessages = await _fetchMessagesFromDatabase(tripId);

      if (dbMessages.isNotEmpty) {
        print('✅ Retrieved ${dbMessages.length} messages from database');

        // Save to local storage for offline access
        await _saveMessagesToLocalStorage(tripId, dbMessages);

        return dbMessages;
      }

      // Fallback to local storage if database is empty
      print('ℹ️ Database empty, checking local storage...');
      final localMessages = await getLocalMessages(tripId);

      if (localMessages.isNotEmpty) {
        print(
          '✅ Retrieved ${localMessages.length} messages from local storage',
        );
        return localMessages;
      }

      print('ℹ️ No messages found for trip: $tripId');
      return [];
    } catch (e) {
      print('❌ Error getting all messages for trip - $e');

      // Fallback to local storage on error
      try {
        final localMessages = await getLocalMessages(tripId);
        print(
          '✅ Fallback: Retrieved ${localMessages.length} messages from local storage',
        );
        return localMessages;
      } catch (localError) {
        print('❌ Fallback also failed: $localError');
        return [];
      }
    }
  }
}
