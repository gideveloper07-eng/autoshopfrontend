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

  // ── Period state (independent per chart) ────────────────────
  String _bookingPeriod = '7days';
  String _salePeriod = '7days';
  bool _loadingBookingTrend = false;
  bool _loadingSaleTrend = false;

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
    if (_bookingPeriod == '7days') {
      _bookingTrend = widget.bookingTrend;
    }
    if (_salePeriod == '7days') {
      _saleTrend = widget.saleTrend;
    }
  }

  Future<void> _switchBookingPeriod(String newPeriod) async {
    if (newPeriod == _bookingPeriod) return;

    setState(() {
      _bookingPeriod = newPeriod;
      _loadingBookingTrend = true;
    });

    try {
      print("📊 BOOKING PERIOD CHANGED: $newPeriod");

      final stats = await ApiService.getDashboardStats(period: newPeriod);

      if (!mounted) return;

      final bookingData = stats['bookingTrend'];
      print("📊 BOOKING TREND RAW: $bookingData");

      setState(() {
        _bookingTrend = bookingData is List
            ? bookingData.map((e) => (e as num).toDouble()).toList()
            : [];
      });

      print("📊 BOOKING TREND FINAL: $_bookingTrend");
    } catch (e, stackTrace) {
      print("❌ BOOKING TREND SWITCH ERROR: $e");
      print(stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _loadingBookingTrend = false;
        });
      }
    }
  }

  Future<void> _switchSalePeriod(String newPeriod) async {
    if (newPeriod == _salePeriod) return;

    setState(() {
      _salePeriod = newPeriod;
      _loadingSaleTrend = true;
    });

    try {
      print("📊 SALE PERIOD CHANGED: $newPeriod");

      final stats = await ApiService.getDashboardStats(period: newPeriod);

      if (!mounted) return;

      final saleData = stats['saleTrend'];
      print("📊 SALE TREND RAW: $saleData");

      setState(() {
        _saleTrend = saleData is List
            ? saleData.map((e) => (e as num).toDouble()).toList()
            : [];
      });

      print("📊 SALE TREND FINAL: $_saleTrend");
    } catch (e, stackTrace) {
      print("❌ SALE TREND SWITCH ERROR: $e");
      print(stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _loadingSaleTrend = false;
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
                  period: _bookingPeriod,
                  onPeriodChanged: _switchBookingPeriod,
                ),
              ),

              if (_loadingBookingTrend)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
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
                  period: _salePeriod,
                  onPeriodChanged: _switchSalePeriod,
                ),
              ),

              if (_loadingSaleTrend)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
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
