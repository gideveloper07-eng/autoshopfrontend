import 'package:flutter/material.dart';

class DashboardGrowthChip extends StatelessWidget {
  final double growth;

  const DashboardGrowthChip({super.key, required this.growth});

  @override
  Widget build(BuildContext context) {
    final bool positive = growth > 0;
    final bool neutral = growth == 0;

    late final Color backgroundColor;
    late final IconData icon;
    late final String text;

    if (neutral) {
      backgroundColor = Colors.blueGrey.shade600;
      icon = Icons.trending_flat_rounded;
      text = "0%";
    } else if (positive) {
      backgroundColor = const Color(0xFF2E7D32);
      icon = Icons.trending_up_rounded;
      text = "+${growth.toStringAsFixed(1)}%";
    } else {
      backgroundColor = const Color(0xFFD32F2F);
      icon = Icons.trending_down_rounded;
      text = "${growth.toStringAsFixed(1)}%";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
