import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isConnected;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isConnected,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.trim().isNotEmpty;
    });
  }

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
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button (disabled for now)
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFF6B7280)),
              onPressed: null, // Disabled for now
              tooltip: 'Attach file',
            ),

            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        widget.isConnected
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFFFCA5A5),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  enabled: widget.isConnected,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText:
                        widget.isConnected
                            ? 'Type a message...'
                            : 'Connection lost...',
                    hintStyle: TextStyle(
                      color:
                          widget.isConnected
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFFFCA5A5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                  onSubmitted: (_) {
                    if (_hasText && widget.isConnected) {
                      widget.onSend();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: BoxDecoration(
                color:
                    _hasText && widget.isConnected
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color:
                      _hasText && widget.isConnected
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                ),
                onPressed:
                    _hasText && widget.isConnected ? widget.onSend : null,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }
}
