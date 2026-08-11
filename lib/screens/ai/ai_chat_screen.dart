import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../models/ai_message.dart';
import '../../widgets/ai/ai_input_bar.dart';
import '../../widgets/ai/ai_message_bubble.dart';
import '../../widgets/ai/ai_quick_actions.dart';
import '../../widgets/ai/ai_typing_indicator.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<AIMessage> _messages = [];

  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // GREETING
  // ============================================================

  String get _greeting {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    }

    if (hour < 17) {
      return "Good Afternoon";
    }

    return "Good Evening";
  }

  // ============================================================
  // SCROLL TO BOTTOM
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> _sendMessage([String? quickMessage]) async {
    final text = (quickMessage ?? _controller.text).trim();

    if (text.isEmpty || _isTyping) {
      return;
    }

    // ----------------------------------------------------------
    // Add user message
    // ----------------------------------------------------------

    setState(() {
      _messages.add(
        AIMessage.user(text),
      );

      _controller.clear();

      _isTyping = true;
    });

    _scrollToBottom();

    // ----------------------------------------------------------
    // Call AI API
    // ----------------------------------------------------------

    try {
      final reply = await ApiService.askAI(text);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AIMessage.ai(reply),
        );

        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("AI CHAT ERROR: $e");

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          AIMessage.ai(
            "Unable to contact MyAutoShop AI right now. Please try again.",
          ),
        );

        _isTyping = false;
      });

      _scrollToBottom();
    }
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _welcomeCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        12,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff1565C0),
            Color(0xff42A5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1565C0).withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // Greeting
          // ------------------------------------------------------

          Text(
            "$_greeting 👋",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // Title
          // ------------------------------------------------------

          const Text(
            "MyAutoShop AI",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // Description
          // ------------------------------------------------------

          const Text(
            "Your intelligent dealership assistant.\n"
            "Ask anything about bookings, sales, finance, "
            "workshop or inventory.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY CHAT VIEW
  // ============================================================

  Widget _emptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xffE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 32,
                color: Color(0xff1565C0),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Start a conversation",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xff263238),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Ask MyAutoShop AI about your dealership data.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE LIST
  // ============================================================

  Widget _messageList() {
    if (_messages.isEmpty && !_isTyping) {
      return _emptyChat();
    }

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      itemCount:
          _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // --------------------------------------------------------
        // Typing indicator
        // --------------------------------------------------------

        if (_isTyping && index == _messages.length) {
          return const AITypingIndicator();
        }

        // --------------------------------------------------------
        // Message bubble
        // --------------------------------------------------------

        return AIMessageBubble(
          message: _messages[index],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff1565C0),
        foregroundColor: Colors.white,
        centerTitle: false,

        title: const Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 21,
            ),

            SizedBox(width: 8),

            Text(
              "MyAutoShop AI",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // Welcome card
            // --------------------------------------------------

            _welcomeCard(),

            // --------------------------------------------------
            // Quick actions
            // --------------------------------------------------

            AIQuickActions(
              onSelected: (text) {
                _sendMessage(text);
              },
            ),

            const SizedBox(height: 4),

            const Divider(
              height: 1,
              thickness: 1,
            ),

            // --------------------------------------------------
            // Messages
            // --------------------------------------------------

            Expanded(
              child: _messageList(),
            ),

            // --------------------------------------------------
            // Input bar
            // --------------------------------------------------

            AIInputBar(
              controller: _controller,
              isLoading: _isTyping,

              onSend: _sendMessage,

              onVoice: () {
                // Voice functionality can be implemented here.
              },

              onAttachment: () {
                // Attachment functionality can be implemented here.
              },
            ),
          ],
        ),
      ),
    );
  }
}