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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // ==========================================================
          // AI AVATAR
          // ==========================================================

          if (!isUser) ...[
            _avatar(false),
            const SizedBox(width: 10),
          ],

          // ==========================================================
          // MESSAGE BUBBLE
          // ==========================================================

          Flexible(
            child: GestureDetector(
              onLongPress: () => _showOptions(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,

                padding: const EdgeInsets.fromLTRB(
                  15,
                  13,
                  15,
                  10,
                ),

                decoration: BoxDecoration(
                  color: isUser
                      ? const Color(0xff1565C0)
                      : Colors.white,

                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(
                      isUser ? 18 : 5,
                    ),
                    bottomRight: Radius.circular(
                      isUser ? 5 : 18,
                    ),
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
                    // =================================================
                    // AI MARKDOWN RESPONSE
                    // =================================================

                    if (message.isMarkdown && !isUser)
                      MarkdownBody(
                        data: message.text,
                        selectable: true,

                        styleSheet: MarkdownStyleSheet(
                          // ------------------------------------------------
                          // NORMAL PARAGRAPH
                          // ------------------------------------------------

                          p: const TextStyle(
                            fontSize: 15,
                            height: 1.48,
                            color: Color(0xff263238),
                          ),

                          pPadding: const EdgeInsets.only(
                            bottom: 5,
                          ),

                          // ------------------------------------------------
                          // H1
                          // ------------------------------------------------

                          h1: const TextStyle(
                            fontSize: 22,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff1565C0),
                          ),

                          h1Padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 8,
                          ),

                          // ------------------------------------------------
                          // H2
                          // ------------------------------------------------

                          h2: const TextStyle(
                            fontSize: 19,
                            height: 1.3,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff1565C0),
                          ),

                          h2Padding: const EdgeInsets.only(
                            top: 5,
                            bottom: 7,
                          ),

                          // ------------------------------------------------
                          // H3
                          // ------------------------------------------------

                          h3: const TextStyle(
                            fontSize: 16.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff263238),
                          ),

                          h3Padding: const EdgeInsets.only(
                            top: 4,
                            bottom: 5,
                          ),

                          // ------------------------------------------------
                          // H4
                          // ------------------------------------------------

                          h4: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff263238),
                          ),

                          // ------------------------------------------------
                          // H5
                          // ------------------------------------------------

                          h5: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff263238),
                          ),

                          // ------------------------------------------------
                          // H6
                          // ------------------------------------------------

                          h6: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff263238),
                          ),

                          // ------------------------------------------------
                          // BOLD
                          // ------------------------------------------------

                          strong: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xff111111),
                          ),

                          // ------------------------------------------------
                          // ITALIC
                          // ------------------------------------------------

                          em: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Color(0xff455A64),
                          ),

                          // ------------------------------------------------
                          // STRIKETHROUGH
                          // ------------------------------------------------

                          del: const TextStyle(
                            decoration:
                                TextDecoration.lineThrough,
                            color: Color(0xff78909C),
                          ),

                          // ------------------------------------------------
                          // LINKS
                          // ------------------------------------------------

                          a: const TextStyle(
                            color: Color(0xff1565C0),
                            decoration:
                                TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                          ),

                          // ------------------------------------------------
                          // BULLET LIST
                          // ------------------------------------------------
                          //
                          // flutter_markdown uses listBullet.
                          // There is NO listNumber parameter in
                          // your installed version.
                          // ------------------------------------------------

                          listBullet: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xff1565C0),
                            fontWeight: FontWeight.w800,
                          ),

                          listBulletPadding:
                              const EdgeInsets.only(
                            right: 5,
                          ),

                          listIndent: 20,

                          // ------------------------------------------------
                          // BLOCK SPACING
                          // ------------------------------------------------

                          blockSpacing: 7,

                          // ------------------------------------------------
                          // BLOCKQUOTE
                          // ------------------------------------------------

                          blockquote: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xff455A64),
                            fontStyle: FontStyle.italic,
                          ),

                          blockquotePadding:
                              const EdgeInsets.all(10),

                          blockquoteDecoration:
                              BoxDecoration(
                            color: const Color(0xffF5F7FA),
                            borderRadius:
                                BorderRadius.circular(9),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xff1565C0),
                                width: 3,
                              ),
                            ),
                          ),

                          // ------------------------------------------------
                          // INLINE CODE
                          // ------------------------------------------------

                          code: const TextStyle(
                            fontSize: 13,
                            color: Color(0xff37474F),
                            fontFamily: 'monospace',
                            backgroundColor:
                                Color(0xffF5F7FA),
                          ),

                          // ------------------------------------------------
                          // CODE BLOCK
                          // ------------------------------------------------

                          codeblockPadding:
                              const EdgeInsets.all(12),

                          codeblockDecoration:
                              BoxDecoration(
                            color: const Color(0xffF5F7FA),
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: Color(0xffE0E0E0),
                            ),
                          ),

                          // ------------------------------------------------
                          // TABLE
                          // ------------------------------------------------

                          tableHead: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff263238),
                          ),

                          tableBody: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff37474F),
                          ),

                          tableHeadAlign: TextAlign.left,

                          tableBorder:
                              TableBorder.all(
                            color: Color(0xffE0E0E0),
                            width: 0.7,
                          ),

                          tableCellsPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 7,
                          ),

                          // ------------------------------------------------
                          // HORIZONTAL RULE
                          // ------------------------------------------------

                          horizontalRuleDecoration:
                              const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xffE0E0E0),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      )

                    // =====================================================
                    // USER MESSAGE
                    // =====================================================

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

                    // =====================================================
                    // MESSAGE TIME
                    // =====================================================

                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _formatTime(message.time),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isUser
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // USER AVATAR
          // ==========================================================

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