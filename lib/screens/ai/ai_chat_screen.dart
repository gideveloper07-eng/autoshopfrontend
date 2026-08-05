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

  final TextEditingController _controller =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  final List<AIMessage> _messages = [];

  bool _isTyping = false;

  @override
  void dispose() {

    _controller.dispose();

    _scrollController.dispose();

    super.dispose();

  }

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

  void _scrollToBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(

        _scrollController.position.maxScrollExtent,

        duration: const Duration(milliseconds: 300),

        curve: Curves.easeOut,

      );

    });

  }

Future<void> _sendMessage([String? quickMessage]) async {

    final text =
        quickMessage ??
            _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {

      _messages.add(
        AIMessage.user(text),
      );

      _controller.clear();

      _isTyping = true;

    });

    _scrollToBottom();

    // API call will be added in Part 2

   try {

    final reply = await ApiService.askAI(text);

    setState(() {

        _messages.add(
            AIMessage.ai(reply),
        );

        _isTyping = false;

    });

} catch (e) {

    setState(() {

        _messages.add(
            AIMessage.ai(
                "Unable to contact MyAutoShop AI.",
            ),
        );

        _isTyping = false;

    });

}

_scrollToBottom();


}

  Widget _welcomeCard() {

    return Container(

      margin: const EdgeInsets.all(16),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        gradient: const LinearGradient(

          colors: [

            Color(0xff1565C0),

            Color(0xff42A5F5),

          ],

        ),

        borderRadius:
            BorderRadius.circular(20),

      ),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(

            "$_greeting 👋",

            style: const TextStyle(

              color: Colors.white70,

              fontSize: 16,

            ),

          ),

          const SizedBox(height: 10),

          const Text(

            "MyAutoShop AI",

            style: TextStyle(

              color: Colors.white,

              fontSize: 26,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 8),

          const Text(

            "Your intelligent dealership assistant.\nAsk anything about bookings, sales, finance, workshop or inventory.",

            style: TextStyle(

              color: Colors.white,

              height: 1.4,

            ),

          ),

        ],

      ),

    );

  }

  @override
  Widget build(BuildContext context) {
    // Total extra items before messages: welcome card + quick actions + divider
    const int headerCount = 3;
    final int messageCount = _messages.length + (_isTyping ? 1 : 0);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xff1565C0),
        foregroundColor: Colors.white,
        title: const Text("MyAutoShop AI"),
      ),
      body: Column(
        children: [
          // ── Messages + header all in one scrollable list ──────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: headerCount + (messageCount == 0 ? 1 : messageCount),
              itemBuilder: (context, index) {
                // Header slot 0: welcome card
                if (index == 0) return _welcomeCard();

                // Header slot 1: quick actions (only when no messages yet)
                if (index == 1) {
                  return AIQuickActions(
                    onSelected: _sendMessage,
                  );
                }

                // Header slot 2: divider
                if (index == 2) return const Divider(height: 1);

                // Empty state
                if (messageCount == 0) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        "Start a conversation with MyAutoShop AI",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final msgIndex = index - headerCount;

                // Typing indicator at the end
                if (_isTyping && msgIndex == _messages.length) {
                  return const AITypingIndicator();
                }

                return AIMessageBubble(message: _messages[msgIndex]);
              },
            ),
          ),

          // ── Input bar pinned at bottom ────────────────────────────────
          AIInputBar(
            controller: _controller,
            isLoading: _isTyping,
            onSend: _sendMessage,
            onVoice: () {},
            onAttachment: () {},
          ),
        ],
      ),
    );
  }

}