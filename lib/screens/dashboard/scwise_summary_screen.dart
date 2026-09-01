import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';
import 'sc_sale_details_screen.dart';

/// Shows Sales Consultant (SC) wise sale counts for today or yesterday.
class SCwiseSummaryScreen extends StatefulWidget {
  /// 'today' or 'yesterday'
  final String period;

  const SCwiseSummaryScreen({
    super.key,
    required this.period,
  });

  @override
  State<SCwiseSummaryScreen> createState() => _SCwiseSummaryScreenState();
}

class _SCwiseSummaryScreenState extends State<SCwiseSummaryScreen> {
  bool _isLoading = true;
  String? _error;
  int _total = 0;
  List<Map<String, dynamic>> _scs = [];

  static const Color _primaryColor = Color(0xFF3949AB);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });

    try {
      final result = await ApiService.getDashboardSCwise(widget.period);

      final rawSCs = result['scs'];
      final scs = rawSCs is List
          ? rawSCs
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList()
          : <Map<String, dynamic>>[];

      scs.sort(
        (a, b) =>
            (b['count'] as num? ?? 0).compareTo(a['count'] as num? ?? 0),
      );

      if (mounted) {
        setState(() {
          _total = (result['total'] as num?)?.toInt() ?? 0;
          _scs = scs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodLabel = widget.period == 'today' ? "Today's" : "Yesterday's";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '$periodLabel Sale — SC Summary',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody(theme)),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: const Center(
              child: CircularProgressIndicator(color: _primaryColor),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off_rounded, color: Colors.grey[400], size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildSummaryHeader(theme),
        const SizedBox(height: 16),
        if (_scs.isEmpty)
          _buildEmpty()
        else
          ..._scs.asMap().entries.map(
            (entry) => _buildSCCard(entry.key, entry.value, theme),
          ),
      ],
    );
  }

  Widget _buildSummaryHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final periodLabel = widget.period == 'today' ? "Today's" : "Yesterday's";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A237E), const Color(0xFF283593)]
              : [const Color(0xFF1A237E), const Color(0xFF3949AB)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$periodLabel Total Sale',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_scs.length} Sales Consultant${_scs.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSCCard(int index, Map<String, dynamic> sc, ThemeData theme) {
    final scId    = sc['scId']?.toString()   ?? '';
    final scName  = sc['scName']?.toString() ?? 'Unknown SC';
    final count   = (sc['count'] as num?)?.toInt() ?? 0;
    final isDark  = theme.brightness == Brightness.dark;
    final fraction = _total > 0 ? count / _total : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: RgbBorderCard(
        borderRadius: 18,
        borderWidth: 2.0,
        glow: true,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SCSaleDetailsScreen(
                    scId: scId,
                    scName: scName,
                    period: widget.period,
                    saleCount: count,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // SC avatar initial
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _primaryColor.withOpacity(0.15),
                          child: Text(
                            scName.isNotEmpty ? scName[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // SC name
                        Expanded(
                          child: Text(
                            scName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Count badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: _primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: _primaryColor.withOpacity(0.5),
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 8,
                        backgroundColor:
                            isDark ? Colors.white12 : Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_primaryColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(fraction * 100).toStringAsFixed(1)}% of total  ·  '
                      '$count ${count == 1 ? 'Sale' : 'Sales'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            color: _primaryColor.withOpacity(0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            widget.period == 'today'
                ? 'No sales found today'
                : 'No sales found yesterday',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
