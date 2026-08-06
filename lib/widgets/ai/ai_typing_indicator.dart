import 'dart:async';
import 'package:flutter/material.dart';

class AITypingIndicator extends StatefulWidget {
  const AITypingIndicator({super.key});

  @override
  State<AITypingIndicator> createState() =>
      _AITypingIndicatorState();
}

class _AITypingIndicatorState
    extends State<AITypingIndicator> {

  int _activeDot = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: 350),
      (_) {

        if (!mounted) return;

        setState(() {

          _activeDot =
              (_activeDot + 1) % 3;

        });

      },
    );
  }

  @override
  void dispose() {

    _timer?.cancel();

    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF1E2A3A) : Colors.white;

    return Padding(

      padding: const EdgeInsets.only(
        left: 14,
        right: 14,
        bottom: 8,
        top: 6,
      ),

      child: Row(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          CircleAvatar(

            radius: 18,

            backgroundColor:
                Colors.orange,

            child: const Icon(

              Icons.smart_toy_rounded,

              color: Colors.white,

              size: 18,

            ),

          ),

          const SizedBox(width: 10),

          Container(

            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            decoration: BoxDecoration(

              color: bubbleColor,

              borderRadius:
                  BorderRadius.circular(18),

              boxShadow: [

                BoxShadow(

                  color: Colors.black.withOpacity(.05),

                  blurRadius: 8,

                  offset: const Offset(0, 3),

                )

              ],

            ),

            child: Row(

              mainAxisSize: MainAxisSize.min,

              children: List.generate(

                3,

                (index) {

                  return AnimatedContainer(

                    duration: const Duration(
                      milliseconds: 250,
                    ),

                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),

                    width:
                        _activeDot == index
                            ? 10
                            : 8,

                    height:
                        _activeDot == index
                            ? 10
                            : 8,

                    decoration:
                        BoxDecoration(

                      color:
                          _activeDot == index
                              ? Colors.blue
                              : Colors.grey.shade400,

                      shape:
                          BoxShape.circle,

                    ),

                  );

                },

              ),

            ),

          )

        ],

      ),

    );

  }

}