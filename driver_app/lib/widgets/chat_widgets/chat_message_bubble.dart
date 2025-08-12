import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:driver_app/features/chat/models/chat_models.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isLastMessage;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isLastMessage = false,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isCurrentUser = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final storage = const FlutterSecureStorage();
    final userId = await storage.read(key: 'userId');
    if (mounted) {
      setState(() {
        _currentUserId = userId ?? '';
        _isCurrentUser = widget.message.senderId == userId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: _isCurrentUser ? 64 : 0,
          right: _isCurrentUser ? 0 : 64,
          bottom: 8,
        ),
        child: Column(
          crossAxisAlignment:
              _isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            // Sender name (only for other users)
            if (!_isCurrentUser) ...[
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getSenderColor().withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          widget.message.senderName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getSenderColor(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getSenderTypeColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.message.senderType,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getSenderTypeColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isCurrentUser ? const Color(0xFF3B82F6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(_isCurrentUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  if (widget.message.type == MessageType.text &&
                      widget.message.message != null)
                    Text(
                      widget.message.message!,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _isCurrentUser
                                ? Colors.white
                                : const Color(0xFF1F2937),
                      ),
                    )
                  else if (widget.message.type == MessageType.image)
                    _buildImageMessage()
                  else if (widget.message.type == MessageType.file)
                    _buildFileMessage(),

                  // Timestamp and read status
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTimestamp(widget.message.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              _isCurrentUser
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (_isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color:
                              widget.message.isRead
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.mediaUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.message.mediaUrl!,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Color(0xFF9CA3AF)),
                  ),
                );
              },
            ),
          ),
        if (widget.message.message != null &&
            widget.message.message!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            widget.message.message!,
            style: TextStyle(
              fontSize: 16,
              color: _isCurrentUser ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFileMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            _isCurrentUser
                ? Colors.white.withValues(alpha: 0.2)
                : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, color: Color(0xFF6B7280), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.message.message != null)
                  Text(
                    widget.message.message!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                if (widget.message.mediaUrl != null)
                  Text(
                    'Tap to download',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          _isCurrentUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : const Color(0xFF6B7280),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSenderColor() {
    switch (widget.message.senderType) {
      case 'DRIVER':
        return const Color(0xFF3B82F6);
      case 'ADMIN':
        return const Color(0xFFEF4444);
      case 'PARENT':
        return const Color(0xFF10B981);
      case 'STUDENT':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _getSenderTypeColor() {
    switch (widget.message.senderType) {
      case 'DRIVER':
        return const Color(0xFF3B82F6);
      case 'ADMIN':
        return const Color(0xFFEF4444);
      case 'PARENT':
        return const Color(0xFF10B981);
      case 'STUDENT':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
