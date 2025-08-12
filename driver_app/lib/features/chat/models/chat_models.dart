// chat_models.dart
import 'package:json_annotation/json_annotation.dart';

part 'chat_models.g.dart';

// Utility function for consistent timestamp formatting
String formatTimestampForZod(DateTime dateTime) {
  // Ensure UTC timezone and format for Zod z.string().datetime() validation
  return dateTime.toUtc().toIso8601String();
}

// Message Model - Simplified to use tripId as primary identifier
@JsonSerializable()
class ChatMessage {
  final String id;
  final String tripId; // Primary identifier - replaces roomId
  final String senderId;
  final String senderName;
  final String senderType; // "DRIVER", "ADMIN", "PARENT"
  final String? message; // message text, nullable if media only
  final String timestamp;
  final MessageType type; // "TEXT", "IMAGE", "VIDEO", "FILE"
  final String? mediaUrl;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.tripId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    this.message,
    required this.timestamp,
    required this.type,
    this.mediaUrl,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle type mismatches from backend API
    final id =
        json['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    // Extract tripId from nested trip object or fallback to routeId
    String tripId;
    if (json['trip'] is Map<String, dynamic>) {
      // New API structure with nested trip object
      final tripData = json['trip'] as Map<String, dynamic>;
      tripId =
          tripData['tripSessionId']?.toString() ??
          tripData['routeId']?.toString() ??
          'unknown_trip';
    } else {
      // Fallback to direct fields
      tripId =
          json['tripId']?.toString() ??
          json['routeId']?.toString() ??
          'unknown_trip';
    }

    return ChatMessage(
      id: id,
      tripId: tripId,
      senderId: json['senderId']?.toString() ?? 'unknown_sender',
      senderName: json['senderName']?.toString() ?? 'Unknown User',
      senderType: json['senderType']?.toString() ?? 'UNKNOWN',
      message: json['message']?.toString(),
      timestamp:
          json['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
      type: _parseMessageType(json['type']),
      mediaUrl: json['mediaUrl']?.toString(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  // Helper method to parse message type with fallback
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;

    final typeStr = type.toString().toUpperCase();
    switch (typeStr) {
      case 'TEXT':
        return MessageType.text;
      case 'IMAGE':
        return MessageType.image;
      case 'VIDEO':
        return MessageType.video;
      case 'FILE':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  // Create a new message - Simplified to use tripId only
  factory ChatMessage.create({
    required String tripId,
    required String senderId,
    required String senderName,
    required String senderType,
    String? message,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: tripId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      message: message,
      timestamp: formatTimestampForZod(DateTime.now()),
      type: type,
      mediaUrl: mediaUrl,
    );
  }

  // Mark as read
  ChatMessage markAsRead() {
    return ChatMessage(
      id: id,
      tripId: tripId,
      senderId: senderId,
      senderName: senderName,
      senderType: senderType,
      message: message,
      timestamp: timestamp,
      type: type,
      mediaUrl: mediaUrl,
      isRead: true,
    );
  }
}

// Message Type Enum - Updated to match backend schema
enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('IMAGE')
  image,
  @JsonValue('VIDEO')
  video,
  @JsonValue('FILE')
  file,
}

// Chat Context Model - Replaces ChatRoom with trip-based context
@JsonSerializable()
class ChatContext {
  final String tripId;
  final String tripName;
  final String busRouteId;
  final String busRouteName;
  final List<ChatUser> participants;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final bool isActive;

  ChatContext({
    required this.tripId,
    required this.tripName,
    required this.busRouteId,
    required this.busRouteName,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = true,
  });

  factory ChatContext.fromJson(Map<String, dynamic> json) =>
      _$ChatContextFromJson(json);
  Map<String, dynamic> toJson() => _$ChatContextToJson(this);

  // Create chat context from trip data
  factory ChatContext.create({
    required String tripId,
    required String tripName,
    required String busRouteId,
    required String busRouteName,
    required List<ChatUser> participants,
  }) {
    return ChatContext(
      tripId: tripId,
      tripName: tripName,
      busRouteId: busRouteId,
      busRouteName: busRouteName,
      participants: participants,
    );
  }

  // Update with new message
  ChatContext updateWithMessage(ChatMessage message) {
    return ChatContext(
      tripId: tripId,
      tripName: tripName,
      busRouteId: busRouteId,
      busRouteName: busRouteName,
      participants: participants,
      lastMessage: message.message,
      lastMessageTime: message.timestamp,
      unreadCount: unreadCount + 1,
      isActive: isActive,
    );
  }

  // Mark as read
  ChatContext markAsRead() {
    return ChatContext(
      tripId: tripId,
      tripName: tripName,
      busRouteId: busRouteId,
      busRouteName: busRouteName,
      participants: participants,
      lastMessage: lastMessage,
      lastMessageTime: lastMessageTime,
      unreadCount: 0,
      isActive: isActive,
    );
  }
}

// Chat User Model
@JsonSerializable()
class ChatUser {
  final String id;
  final String name;
  final String type; // "DRIVER", "ADMIN", "PARENT", "STUDENT"
  final String? photoUrl;
  final bool isOnline;
  final String? lastSeen;

  ChatUser({
    required this.id,
    required this.name,
    required this.type,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeen,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) =>
      _$ChatUserFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserToJson(this);

  // Update online status
  ChatUser updateOnlineStatus(bool isOnline) {
    return ChatUser(
      id: id,
      name: name,
      type: type,
      photoUrl: photoUrl,
      isOnline: isOnline,
      lastSeen: isOnline ? null : formatTimestampForZod(DateTime.now()),
    );
  }
}

// Chat Response Models
@JsonSerializable()
class ChatResponse {
  final bool success;
  final String? message;
  final int statusCode;
  final dynamic data;

  ChatResponse({
    required this.success,
    this.message,
    required this.statusCode,
    this.data,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
}

@JsonSerializable()
class MessagesResponse {
  final bool success;
  final List<ChatMessage> messages;
  final String? message;
  final int statusCode;

  MessagesResponse({
    required this.success,
    required this.messages,
    this.message,
    required this.statusCode,
  });

  factory MessagesResponse.fromJson(Map<String, dynamic> json) =>
      _$MessagesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MessagesResponseToJson(this);
}

@JsonSerializable()
class ChatContextResponse {
  final bool success;
  final ChatContext? context;
  final String? message;
  final int statusCode;

  ChatContextResponse({
    required this.success,
    this.context,
    this.message,
    required this.statusCode,
  });

  factory ChatContextResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatContextResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatContextResponseToJson(this);
}
