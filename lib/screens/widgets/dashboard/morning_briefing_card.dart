import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MorningBriefingCard extends StatefulWidget {
  const MorningBriefingCard({super.key});

  @override
  State<MorningBriefingCard> createState() => _MorningBriefingCardState();
}

class _MorningBriefingCardState extends State<MorningBriefingCard> {
  bool _loading = true;
  bool _expanded = false;
  String _error = '';

  Map<String, dynamic> _data = {};
  List<dynamic> _priorityAlerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    try {
      final result = await ApiService.getMorningBriefing();

      if (!mounted) return;

      setState(() {
        _data = result;
        _priorityAlerts =
            List<dynamic>.from(result['priorityAlerts'] ?? const []);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    if (_loading) return _loadingCard(isDark);
    if (_error.isNotEmpty) return _errorCard(isDark);

    final summary =
        Map<String, dynamic>.from(
      _data['summary'] ?? const {},
    );

    final total = _n(summary['totalAlerts']);
    final critical = _n(summary['critical']);
    final high = _n(summary['high']);
    final overdue = _n(summary['overdueDeliveries']);
    final lowStock = _n(summary['lowStock']);
    final demandLowStock =
        _n(summary['highDemandLowStock']);

    final ai =
        Map<String, dynamic>.from(
      _data['ai'] ?? const {},
    );

    final aiAvailable =
        ai['available'] == true;

    final aiBriefing =
        Map<String, dynamic>.from(
      ai['briefing'] ?? const {},
    );

    final headline =
        '${aiBriefing['headline'] ?? ''}'.trim();

    final insights =
        List<dynamic>.from(
      aiBriefing['insights'] ?? const [],
    );

    if (total == 0) {
      return _noAlerts(isDark);
    }

    final visibleAlerts = _expanded
        ? _priorityAlerts
        : _priorityAlerts.take(3).toList();

    final visibleInsights = _expanded
        ? insights
        : insights.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF162131)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: critical > 0
              ? Colors.red.withOpacity(.20)
              : Colors.orange.withOpacity(.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              isDark ? .18 : .07,
            ),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          _header(isDark),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              14,
              12,
              14,
              14,
            ),
            child: Column(
              children: [
                _summaryRow(
                  isDark: isDark,
                  critical: critical,
                  high: high,
                  overdue: overdue,
                  lowStock: lowStock,
                ),

                if (demandLowStock > 0) ...[
                  const SizedBox(height: 10),
                  _demandBanner(
                    isDark,
                    demandLowStock,
                  ),
                ],

                if (headline.isNotEmpty ||
                    visibleInsights.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _aiSection(
                    isDark: isDark,
                    available: aiAvailable,
                    headline: headline,
                    insights: visibleInsights,
                  ),
                ],

                if (visibleAlerts.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionLabel(
                    isDark,
                    'Priority alerts',
                    Icons.notifications_active_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...visibleAlerts.map(
                    (e) => _alertTile(
                      isDark,
                      Map<String, dynamic>.from(e),
                    ),
                  ),
                ],

                if (_priorityAlerts.length > 3 ||
                    insights.length > 3) ...[
                  const SizedBox(height: 3),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 9,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            _expanded
                                ? 'Show fewer insights'
                                : 'View more insights',
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF7DB8FF)
                                  : const Color(0xFF1565C0),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons
                                    .keyboard_arrow_up_rounded
                                : Icons
                                    .keyboard_arrow_down_rounded,
                            size: 18,
                            color: isDark
                                ? const Color(0xFF7DB8FF)
                                : const Color(0xFF1565C0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (_expanded) ...[
                  const SizedBox(height: 5),
                  _allTypes(
                    isDark,
                    summary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool dark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        15,
        12,
        15,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF1976D2),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Dealership Briefing",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Here's what needs your attention today",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required bool isDark,
    required int critical,
    required int high,
    required int overdue,
    required int lowStock,
  }) {
    return Row(
      children: [
        _summary(
          isDark,
          Icons.priority_high_rounded,
          'Critical',
          critical,
          Colors.red,
        ),
        const SizedBox(width: 8),
        _summary(
          isDark,
          Icons.warning_amber_rounded,
          'High',
          high,
          Colors.orange,
        ),
        const SizedBox(width: 8),
        _summary(
          isDark,
          Icons.local_shipping_outlined,
          'Overdue',
          overdue,
          Colors.deepPurple,
        ),
        const SizedBox(width: 8),
        _summary(
          isDark,
          Icons.inventory_2_outlined,
          'Low stock',
          lowStock,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _summary(
    bool dark,
    IconData icon,
    String label,
    int value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF1E2C3D)
              : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              '$value',
              style: TextStyle(
                color: dark
                    ? Colors.white
                    : const Color(0xFF17202A),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark
                    ? Colors.white60
                    : Colors.grey.shade600,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demandBanner(
    bool dark,
    int count,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF3B2B13)
            : const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$count model${count == 1 ? '' : 's'} have high demand but insufficient stock.',
              style: TextStyle(
                color: dark
                    ? const Color(0xFFFFD180)
                    : const Color(0xFF7A4B00),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiSection({
    required bool isDark,
    required bool available,
    required String headline,
    required List<dynamic> insights,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF172638)
            : const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1565C0)
              .withOpacity(.13),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0)
                      .withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF1565C0),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  available
                      ? 'AI MANAGEMENT SUMMARY'
                      : 'MANAGEMENT SUMMARY',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF8FC2FF)
                        : const Color(0xFF1565C0),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
              if (!available)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey
                        .withOpacity(.12),
                    borderRadius:
                        BorderRadius.circular(6),
                  ),
                  child: Text(
                    'FACTS',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white54
                          : Colors.grey.shade600,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),

          if (headline.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              headline,
              style: TextStyle(
                color: isDark
                    ? Colors.white
                    : const Color(0xFF263238),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],

          if (insights.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...insights.map(
              (e) => _insightCard(
                isDark,
                Map<String, dynamic>.from(e),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightCard(
    bool dark,
    Map<String, dynamic> insight,
  ) {
    final type =
        '${insight['type'] ?? ''}';

    final severity =
        '${insight['severity'] ?? 'HIGH'}'
            .toUpperCase();

    final title =
        '${insight['title'] ?? 'Attention needed'}';

    final issue =
        '${insight['issue'] ?? ''}'.trim();

    final why =
        '${insight['whyItMatters'] ?? ''}'.trim();

    final action =
        '${insight['recommendedAction'] ?? ''}'.trim();

    final visual =
        _insightVisual(type);

    final severityColor =
        severity == 'CRITICAL'
            ? Colors.red
            : severity == 'MEDIUM'
                ? Colors.amber.shade800
                : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1B2A3B)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: visual.color.withOpacity(.16),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: visual.color
                      .withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  visual.icon,
                  color: visual.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: dark
                        ? Colors.white
                        : const Color(0xFF17202A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: severityColor
                      .withOpacity(.10),
                  borderRadius:
                      BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          if (issue.isNotEmpty) ...[
            const SizedBox(height: 9),
            _insightText(
              dark,
              'ISSUE',
              issue,
            ),
          ],

          if (why.isNotEmpty) ...[
            const SizedBox(height: 7),
            _insightText(
              dark,
              'WHY IT MATTERS',
              why,
            ),
          ],

          if (action.isNotEmpty) ...[
            const SizedBox(height: 7),
            _insightText(
              dark,
              'RECOMMENDED ACTION',
              action,
              actionColor: const Color(0xFF1565C0),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insightText(
    bool dark,
    String label,
    String text, {
    Color? actionColor,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: actionColor ??
                (dark
                    ? Colors.white54
                    : Colors.grey.shade600),
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: TextStyle(
            color: dark
                ? Colors.white70
                : const Color(0xFF455A64),
            fontSize: 10.5,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(
    bool dark,
    String text,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: dark
              ? Colors.white60
              : Colors.grey.shade600,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: dark
                ? Colors.white70
                : Colors.grey.shade700,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _alertTile(
    bool dark,
    Map<String, dynamic> alert,
  ) {
    final type =
        '${alert['type'] ?? ''}';

    final severity =
        '${alert['severity'] ?? 'HIGH'}'
            .toUpperCase();

    final model =
        '${alert['model'] ?? ''}';

    final customer =
        '${alert['customerName'] ?? ''}';

    final bookings =
        _n(alert['bookingCount']);

    final stock =
        _n(alert['stockFree']);

    final gap =
        _n(alert['demandStockGap']);

    final overdue =
        _n(alert['daysOverdue']);

    final drop =
        _d(alert['salesDropPercent']);

    IconData icon =
        Icons.notifications_active_rounded;

    Color color = Colors.blue;

    String title;
    String detail;

    switch (type) {
      case 'HIGH_DEMAND_LOW_STOCK':
        icon =
            Icons.local_fire_department_rounded;
        color = Colors.red;
        title = model.isNotEmpty
            ? '$model — high demand, low stock'
            : 'High demand + low stock';
        detail =
            '$bookings booking${bookings == 1 ? '' : 's'} • '
            '$stock in stock • Demand gap $gap';
        break;

      case 'HIGH_BOOKING_DEMAND':
        icon =
            Icons.bookmark_added_rounded;
        color = Colors.orange;
        title = model.isNotEmpty
            ? '$model — strong booking demand'
            : 'Strong booking demand';
        detail =
            '$bookings booking${bookings == 1 ? '' : 's'} • '
            '$stock in stock';
        break;

      case 'LOW_STOCK':
        icon =
            Icons.inventory_2_rounded;
        color = Colors.teal;
        title = model.isNotEmpty
            ? '$model — low stock'
            : 'Low stock';
        detail =
            '$stock in stock • Minimum '
            '${_n(alert['stockThreshold'])}';
        break;

      case 'OVERDUE_DELIVERY':
        icon =
            Icons.local_shipping_rounded;
        color = Colors.deepPurple;
        title = model.isNotEmpty
            ? 'Overdue delivery — $model'
            : 'Overdue delivery';
        detail =
            '$overdue day${overdue == 1 ? '' : 's'} overdue';
        break;

      case 'SALES_PERFORMANCE':
        icon =
            Icons.trending_down_rounded;
        color = Colors.redAccent;
        title =
            'Sales performance needs attention';
        detail = drop > 0
            ? 'Sales are ${drop.toStringAsFixed(0)}% below the recent average'
            : 'Sales performance needs attention';
        break;

      default:
        title = model.isNotEmpty
            ? model
            : 'Dealership alert';
        detail = 'Needs attention';
    }

    final severityColor =
        severity == 'CRITICAL'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin:
          const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF1A2535)
            : const Color(0xFFFAFBFD),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(.16),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: dark
                              ? Colors.white
                              : const Color(
                                  0xFF17202A,
                                ),
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      decoration:
                          BoxDecoration(
                        color: severityColor
                            .withOpacity(.10),
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: Text(
                        severity,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 7,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: dark
                        ? Colors.white60
                        : Colors.grey.shade600,
                    fontSize: 10.5,
                  ),
                ),
                if (customer.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    customer,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark
                          ? Colors.white54
                          : Colors.grey.shade600,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allTypes(
    bool dark,
    Map<String, dynamic> summary,
  ) {
    final rows = [
      [
        'High booking demand',
        'highBookingDemand',
        Icons.bookmark_added_outlined
      ],
      [
        'High demand + low stock',
        'highDemandLowStock',
        Icons.local_fire_department_outlined
      ],
      [
        'Low stock',
        'lowStock',
        Icons.inventory_2_outlined
      ],
      [
        'Overdue deliveries',
        'overdueDeliveries',
        Icons.local_shipping_outlined
      ],
      [
        'Sales performance',
        'salesPerformance',
        Icons.trending_down_rounded
      ],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding:
              const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              Icon(
                row[2] as IconData,
                size: 17,
                color: dark
                    ? Colors.white60
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row[0] as String,
                  style: TextStyle(
                    color: dark
                        ? Colors.white70
                        : Colors.grey.shade700,
                    fontSize: 10.5,
                  ),
                ),
              ),
              Text(
                '${_n(summary[row[1]])}',
                style: TextStyle(
                  color: dark
                      ? Colors.white
                      : const Color(0xFF17202A),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  _InsightVisual _insightVisual(
    String type,
  ) {
    switch (type) {
      case 'HIGH_DEMAND_LOW_STOCK':
        return const _InsightVisual(
          Icons.local_fire_department_rounded,
          Colors.red,
        );

      case 'HIGH_BOOKING_DEMAND':
        return const _InsightVisual(
          Icons.bookmark_added_rounded,
          Colors.orange,
        );

      case 'LOW_STOCK':
        return const _InsightVisual(
          Icons.inventory_2_rounded,
          Colors.teal,
        );

      case 'OVERDUE_DELIVERY':
        return const _InsightVisual(
          Icons.local_shipping_rounded,
          Colors.deepPurple,
        );

      case 'SALES_PERFORMANCE':
        return const _InsightVisual(
          Icons.trending_down_rounded,
          Colors.redAccent,
        );

      default:
        return const _InsightVisual(
          Icons.auto_awesome_rounded,
          Color(0xFF1565C0),
        );
    }
  }

  Widget _loadingCard(bool dark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF162131)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child:
                CircularProgressIndicator(
              strokeWidth: 2.4,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Preparing today's dealership briefing...",
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(bool dark) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF241B1B)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red
              .withOpacity(.16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.red,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Could not load today's briefing.",
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _load,
            child:
                const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _noAlerts(bool dark) {
    return Container(
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF162131)
            : Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green
              .withOpacity(.16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons
                .check_circle_outline_rounded,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Good morning. Nothing urgent needs your attention today.",
              style: TextStyle(
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
    );
  }

  int _n(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          '$value',
        ) ??
        0;
  }

  double _d(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          '$value',
        ) ??
        0;
  }
}

class _InsightVisual {
  final IconData icon;
  final Color color;

  const _InsightVisual(
    this.icon,
    this.color,
  );
}
