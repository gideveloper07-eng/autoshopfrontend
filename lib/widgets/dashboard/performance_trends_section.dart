import 'package:flutter/material.dart';
import '../../services/api_service.dart';
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

  // ── Period state ────────────────────────────────────────────
  String _period = '7days';
  bool _loadingTrend = false;

  List<double> _bookingTrend = [];
  List<double> _saleTrend = [];

  @override
  void initState() {
    super.initState();
    _bookingTrend = widget.bookingTrend;
    _saleTrend = widget.saleTrend;
  }

  @override
  void didUpdateWidget(covariant PerformanceTrendsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refresh if period is still the default (7days) — avoid overwriting
    // user-selected 6months data when parent rebuilds.
    if (_period == '7days') {
      _bookingTrend = widget.bookingTrend;
      _saleTrend = widget.saleTrend;
    }
  }

  Future<void> _switchPeriod(String newPeriod) async {
    if (newPeriod == _period) return;

    setState(() {
      _period = newPeriod;
      _loadingTrend = true;
    });

    try {
      print("======================================");
      print("📊 TREND PERIOD CHANGED: $newPeriod");
      print("📊 Calling dashboard API...");
      print("======================================");

      final stats = await ApiService.getDashboardStats(period: newPeriod);

      print("📊 DASHBOARD RESPONSE:");
      print(stats);

      if (!mounted) return;

      final bookingData = stats['bookingTrend'];
      final saleData = stats['saleTrend'];

      print("📊 BOOKING TREND RAW: $bookingData");
      print("📊 SALE TREND RAW: $saleData");

      setState(() {
        _bookingTrend = bookingData is List
            ? bookingData.map((e) => (e as num).toDouble()).toList()
            : [];

        _saleTrend = saleData is List
            ? saleData.map((e) => (e as num).toDouble()).toList()
            : [];
      });

      print("📊 BOOKING TREND FINAL: $_bookingTrend");
      print("📊 SALE TREND FINAL: $_saleTrend");
    } catch (e, stackTrace) {
      print("❌ TREND SWITCH ERROR: $e");
      print(stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _loadingTrend = false;
        });
      }
    }
  }

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
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                              fontSize: 13,
                            ),
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
                  trend: _bookingTrend,
                  period: _period,
                  onPeriodChanged: _switchPeriod,
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
                  trend: _saleTrend,
                  period: _period,
                  onPeriodChanged: _switchPeriod,
                ),
              ),

              if (_loadingTrend)
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
