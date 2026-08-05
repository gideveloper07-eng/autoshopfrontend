import 'package:flutter/material.dart';

class AIQuickActions extends StatelessWidget {
  final Function(String) onSelected;

  const AIQuickActions({
    super.key,
    required this.onSelected,
  });

  static const List<_QuickAction> _actions = [
    _QuickAction(
      icon: Icons.analytics_outlined,
      color: Color(0xff1565C0),
      title: "How is business today?",
    ),
    _QuickAction(
      icon: Icons.calendar_today_outlined,
      color: Colors.green,
      title: "Today's bookings",
    ),
    _QuickAction(
      icon: Icons.currency_rupee,
      color: Colors.orange,
      title: "Today's sales",
    ),
    _QuickAction(
      icon: Icons.local_shipping_outlined,
      color: Colors.deepPurple,
      title: "Pending deliveries",
    ),
    _QuickAction(
      icon: Icons.directions_car_outlined,
      color: Colors.redAccent,
      title: "Vehicle stock",
    ),
    _QuickAction(
      icon: Icons.person_search_outlined,
      color: Colors.teal,
      title: "Search customer",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = _actions[index];

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(item.title),
            child: Container(
              width: 145,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        item.color.withOpacity(.15),
                    child: Icon(
                      item.icon,
                      color: item.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final Color color;
  final String title;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
  });
}