// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  senderType: json['senderType'] as String,
  message: json['message'] as String?,
  timestamp: json['timestamp'] as String,
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  mediaUrl: json['mediaUrl'] as String?,
  isRead: json['isRead'] as bool? ?? false,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderType': instance.senderType,
      'message': instance.message,
      'timestamp': instance.timestamp,
      'type': _$MessageTypeEnumMap[instance.type]!,
      'mediaUrl': instance.mediaUrl,
      'isRead': instance.isRead,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'TEXT',
  MessageType.image: 'IMAGE',
  MessageType.video: 'VIDEO',
  MessageType.file: 'FILE',
};

ChatContext _$ChatContextFromJson(Map<String, dynamic> json) => ChatContext(
  tripId: json['tripId'] as String,
  tripName: json['tripName'] as String,
  busRouteId: json['busRouteId'] as String,
  busRouteName: json['busRouteName'] as String,
  participants:
      (json['participants'] as List<dynamic>)
          .map((e) => ChatUser.fromJson(e as Map<String, dynamic>))
          .toList(),
  lastMessage: json['lastMessage'] as String?,
  lastMessageTime: json['lastMessageTime'] as String?,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$ChatContextToJson(ChatContext instance) =>
    <String, dynamic>{
      'tripId': instance.tripId,
      'tripName': instance.tripName,
      'busRouteId': instance.busRouteId,
      'busRouteName': instance.busRouteName,
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'lastMessageTime': instance.lastMessageTime,
      'unreadCount': instance.unreadCount,
      'isActive': instance.isActive,
    };

ChatUser _$ChatUserFromJson(Map<String, dynamic> json) => ChatUser(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  photoUrl: json['photoUrl'] as String?,
  isOnline: json['isOnline'] as bool? ?? false,
  lastSeen: json['lastSeen'] as String?,
);

Map<String, dynamic> _$ChatUserToJson(ChatUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'type': instance.type,
  'photoUrl': instance.photoUrl,
  'isOnline': instance.isOnline,
  'lastSeen': instance.lastSeen,
};

ChatResponse _$ChatResponseFromJson(Map<String, dynamic> json) => ChatResponse(
  success: json['success'] as bool,
  message: json['message'] as String?,
  statusCode: (json['statusCode'] as num).toInt(),
  data: json['data'],
);

Map<String, dynamic> _$ChatResponseToJson(ChatResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'statusCode': instance.statusCode,
      'data': instance.data,
    };

MessagesResponse _$MessagesResponseFromJson(Map<String, dynamic> json) =>
    MessagesResponse(
      success: json['success'] as bool,
      messages:
          (json['messages'] as List<dynamic>)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList(),
      message: json['message'] as String?,
      statusCode: (json['statusCode'] as num).toInt(),
    );

Map<String, dynamic> _$MessagesResponseToJson(MessagesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'messages': instance.messages,
      'message': instance.message,
      'statusCode': instance.statusCode,
    };

ChatContextResponse _$ChatContextResponseFromJson(Map<String, dynamic> json) =>
    ChatContextResponse(
      success: json['success'] as bool,
      context:
          json['context'] == null
              ? null
              : ChatContext.fromJson(json['context'] as Map<String, dynamic>),
      message: json['message'] as String?,
      statusCode: (json['statusCode'] as num).toInt(),
    );

Map<String, dynamic> _$ChatContextResponseToJson(
  ChatContextResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'context': instance.context,
  'message': instance.message,
  'statusCode': instance.statusCode,
};
