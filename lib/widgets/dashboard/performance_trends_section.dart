import 'package:flutter/material.dart';
import 'trend_card.dart';

class PerformanceTrendsSection extends StatefulWidget {
  final double bookingGrowth;
  final double saleGrowth;

  final List<double> bookingTrend;
  final List<double> saleTrend;

  const PerformanceTrendsSection({
    super.key,
    required this.bookingGrowth,
    required this.saleGrowth,
    required this.bookingTrend,
    required this.saleTrend,
  });

  @override
  State<PerformanceTrendsSection> createState() =>
      _PerformanceTrendsSectionState();
}

class _PerformanceTrendsSectionState extends State<PerformanceTrendsSection>
    with TickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xff2563EB).withOpacity(.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xff2563EB),
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Performance Trends",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Booking & Sales Analytics",
                            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    AnimatedRotation(
                      turns: _expanded ? .5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _expanded
                              ? const Color(0xff2563EB).withOpacity(.10)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _expanded
                              ? const Color(0xff2563EB)
                              : Colors.grey.shade700,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_expanded) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(height: 1, color: theme.dividerColor),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TrendCard(
                  title: "Bookings",
                  icon: Icons.bookmark_added_rounded,
                  color: Colors.blue,
                  growth: widget.bookingGrowth,
                  trend: widget.bookingTrend,
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: TrendCard(
                  title: "Sales",
                  icon: Icons.sell_rounded,
                  color: Colors.green,
                  growth: widget.saleGrowth,
                  trend: widget.saleTrend,
                ),
              ),

              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
