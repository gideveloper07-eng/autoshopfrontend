import 'package:flutter/material.dart';

class AIInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onVoice;
  final VoidCallback? onAttachment;
  final bool isLoading;

  const AIInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoice,
    this.onAttachment,
    this.isLoading = false,
  });

  @override
  State<AIInputBar> createState() => _AIInputBarState();
}

class _AIInputBarState extends State<AIInputBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black.withOpacity(.08),
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            //----------------------------------------------------------
            // Attachment
            //----------------------------------------------------------

            IconButton(
              onPressed: widget.onAttachment,
              icon: const Icon(Icons.attach_file_rounded),
              tooltip: "Attachment",
            ),

            //----------------------------------------------------------
            // TextField
            //----------------------------------------------------------

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF5F7FA),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: widget.controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: "Ask MyAutoShop AI...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) {
                    if (!widget.isLoading &&
                        widget.controller.text.trim().isNotEmpty) {
                      widget.onSend();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(width: 6),

            //----------------------------------------------------------
            // Voice
            //----------------------------------------------------------

            IconButton(
              onPressed:
                  widget.isLoading ? null : widget.onVoice,
              icon: const Icon(Icons.mic_none_rounded),
              tooltip: "Voice",
            ),

            //----------------------------------------------------------
            // Send
            //----------------------------------------------------------

            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor:
                      const Color(0xff1565C0),
                ),
                onPressed: widget.isLoading
                    ? null
                    : () {
                        if (widget.controller.text
                            .trim()
                            .isEmpty) return;

                        widget.onSend();
                      },
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}