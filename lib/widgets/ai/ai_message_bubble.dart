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
    final bool isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // AI bubble adapts to theme; user bubble stays blue
    final aiBubbleColor = isDark ? const Color(0xFF1E2A3A) : Colors.white;
    final bodyTextColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xff263238);
    final headingColor = isDark ? const Color(0xFF82B1FF) : const Color(0xff1565C0);
    final subHeadColor = isDark ? const Color(0xFFCFD8DC) : const Color(0xff263238);
    final mutedColor   = isDark ? const Color(0xFF90A4AE) : const Color(0xff455A64);
    final codeColor    = isDark ? const Color(0xFFCFD8DC) : const Color(0xff37474F);
    final codeBgColor  = isDark ? const Color(0xFF0D1117) : const Color(0xffF5F7FA);
    final borderColor  = isDark ? const Color(0xFF37474F) : const Color(0xffE0E0E0);

    final screenWidth = MediaQuery.of(context).size.width;
    // Cap bubble width: 75% on phones, 55% on tablets/large screens
    final maxBubbleWidth = screenWidth < 600
        ? screenWidth * 0.75
        : screenWidth * 0.55;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _avatar(false),
            const SizedBox(width: 10),
          ],

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxBubbleWidth),
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xff1565C0) : aiBubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 5),
                    bottomRight: Radius.circular(isUser ? 5 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.055),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.isMarkdown && !isUser)
                      MarkdownBody(
                        data: message.text,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(fontSize: 15, height: 1.48, color: bodyTextColor),
                          pPadding: const EdgeInsets.only(bottom: 5),
                          h1: TextStyle(fontSize: 22, height: 1.25, fontWeight: FontWeight.w800, color: headingColor),
                          h1Padding: const EdgeInsets.only(top: 4, bottom: 8),
                          h2: TextStyle(fontSize: 19, height: 1.3, fontWeight: FontWeight.w800, color: headingColor),
                          h2Padding: const EdgeInsets.only(top: 5, bottom: 7),
                          h3: TextStyle(fontSize: 16.5, height: 1.35, fontWeight: FontWeight.w700, color: subHeadColor),
                          h3Padding: const EdgeInsets.only(top: 4, bottom: 5),
                          h4: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: subHeadColor),
                          h5: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: subHeadColor),
                          h6: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: subHeadColor),
                          strong: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xff111111)),
                          em: TextStyle(fontStyle: FontStyle.italic, color: mutedColor),
                          del: TextStyle(decoration: TextDecoration.lineThrough, color: mutedColor),
                          a: TextStyle(color: headingColor, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                          listBullet: TextStyle(fontSize: 15, height: 1.5, color: headingColor, fontWeight: FontWeight.w800),
                          listBulletPadding: const EdgeInsets.only(right: 5),
                          listIndent: 20,
                          blockSpacing: 7,
                          blockquote: TextStyle(fontSize: 14, height: 1.45, color: mutedColor, fontStyle: FontStyle.italic),
                          blockquotePadding: const EdgeInsets.all(10),
                          blockquoteDecoration: BoxDecoration(
                            color: codeBgColor,
                            borderRadius: BorderRadius.circular(9),
                            border: const Border(left: BorderSide(color: Color(0xff1565C0), width: 3)),
                          ),
                          code: TextStyle(fontSize: 13, color: codeColor, fontFamily: 'monospace', backgroundColor: codeBgColor),
                          codeblockPadding: const EdgeInsets.all(12),
                          codeblockDecoration: BoxDecoration(
                            color: codeBgColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          tableHead: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: subHeadColor),
                          tableBody: TextStyle(fontSize: 14, color: codeColor),
                          tableHeadAlign: TextAlign.left,
                          tableBorder: TableBorder.all(color: borderColor, width: 0.7),
                          tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                          horizontalRuleDecoration: BoxDecoration(
                            border: Border(top: BorderSide(color: borderColor, width: 1)),
                          ),
                        ),
                      )
                    else
                      SelectableText(
                        message.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: 7),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTime(message.time),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isUser ? Colors.white70 : Colors.grey.shade500,
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

  // ==================================================================
  // AVATAR
  // ==================================================================

  Widget _avatar(bool user) {
    return CircleAvatar(
      radius: 18,

      backgroundColor: user
          ? const Color(0xff1565C0)
          : const Color(0xffff9800),

      child: Icon(
        user
            ? Icons.person
            : Icons.smart_toy_rounded,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  // ==================================================================
  // LONG PRESS OPTIONS
  // ==================================================================

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,

      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              // --------------------------------------------------------
              // COPY
              // --------------------------------------------------------

              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Copy"),

                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: message.text,
                    ),
                  );

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text("Copied"),
                    ),
                  );
                },
              ),

              // --------------------------------------------------------
              // SHARE
              // --------------------------------------------------------

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

  // ==================================================================
  // TIME
  // ==================================================================

  String _formatTime(DateTime date) {
    final int h = date.hour > 12
        ? date.hour - 12
        : date.hour;

    final String m =
        date.minute.toString().padLeft(2, '0');

    final String ap =
        date.hour >= 12 ? "PM" : "AM";

    return "$h:$m $ap";
  }
}