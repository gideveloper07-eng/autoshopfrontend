import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/ai_message.dart';

class AIMessageBubble extends StatelessWidget {
  final AIMessage message;

  const AIMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _avatar(false),
            const SizedBox(width: 10),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xff1565C0)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (message.isMarkdown && !isUser)
                      MarkdownBody(
                        data: message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      )
                    else
                      SelectableText(
                        message.text,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTime(message.time),
                        style: TextStyle(
                          fontSize: 11,
                          color: isUser
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isUser) ...[
            const SizedBox(width: 10),
            _avatar(true),
          ],
        ],
      ),
    );
  }

  Widget _avatar(bool user) {
    return CircleAvatar(
      radius: 18,
      backgroundColor:
          user ? const Color(0xff1565C0) : Colors.orange,
      child: Icon(
        user ? Icons.person : Icons.smart_toy_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copy"),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: message.text),
                  );
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Copied"),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text("Share"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour > 12
        ? date.hour - 12
        : date.hour;

    final m = date.minute.toString().padLeft(2, '0');

    final ap =
        date.hour >= 12 ? "PM" : "AM";

    return "$h:$m $ap";
  }
}