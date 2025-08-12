import 'package:flutter/material.dart';
import 'package:driver_app/features/chat/models/chat_models.dart';

class ChatHeader extends StatelessWidget {
  final ChatContext? chatContext;
  final bool isConnected;
  final VoidCallback onRefresh;

  const ChatHeader({
    super.key,
    this.chatContext,
    required this.isConnected,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Room info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chatContext?.tripName ?? 'Trip Chat',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      isConnected ? Icons.circle : Icons.circle_outlined,
                      size: 8,
                      color:
                          isConnected
                              ? const Color(0xFF10B981)
                              : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isConnected
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6B7280),
                      ),
                    ),
                    if (chatContext != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6B7280),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${chatContext!.participants.length} participants',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1F2937)),
            onPressed: onRefresh,
          ),

          // More options button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1F2937)),
            onSelected: (value) {
              switch (value) {
                case 'participants':
                  _showParticipants(context);
                  break;
                case 'trip_info':
                  _showTripInfo(context);
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'participants',
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 20, color: Color(0xFF6B7280)),
                        SizedBox(width: 8),
                        Text('Participants'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'trip_info',
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 8),
                        Text('Trip Info'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  void _showParticipants(BuildContext context) {
    if (chatContext == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Participants',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: chatContext!.participants.length,
                  itemBuilder: (context, index) {
                    final participant = chatContext!.participants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            participant.photoUrl != null
                                ? NetworkImage(participant.photoUrl!)
                                : null,
                        child:
                            participant.photoUrl == null
                                ? Text(
                                  participant.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                : null,
                      ),
                      title: Text(participant.name),
                      subtitle: Text(participant.type),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            participant.isOnline
                                ? Icons.circle
                                : Icons.circle_outlined,
                            size: 8,
                            color:
                                participant.isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            participant.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  participant.isOnline
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTripInfo(BuildContext context) {
    if (chatContext == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Trip Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Trip Name', chatContext!.tripName),
              _buildInfoRow('Bus Route', chatContext!.busRouteName),
              _buildInfoRow(
                'Participants',
                '${chatContext!.participants.length}',
              ),
              _buildInfoRow(
                'Last Message',
                chatContext!.lastMessage != null
                    ? chatContext!.lastMessage!
                    : 'No messages yet',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }
}
