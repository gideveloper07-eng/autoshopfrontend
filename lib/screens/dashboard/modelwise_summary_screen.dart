import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';

/// Shows model-wise booking / sale counts for today or yesterday.
class ModelwiseSummaryScreen extends StatefulWidget {
  /// 'booking' or 'sale'
  final String reportType;

  /// 'today' or 'yesterday'
  final String period;

  const ModelwiseSummaryScreen({
    super.key,
    required this.reportType,
    required this.period,
  });

  @override
  State<ModelwiseSummaryScreen> createState() => _ModelwiseSummaryScreenState();
}

class _ModelwiseSummaryScreenState extends State<ModelwiseSummaryScreen> {
  bool _isLoading = true;
  String? _error;
  int _total = 0;
  List<Map<String, dynamic>> _models = [];

  bool get _isBooking => widget.reportType.toLowerCase() == 'booking';

  Color get _primaryColor =>
      _isBooking ? const Color(0xFF1565C0) : const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await ApiService.getDashboardModelwise(
        widget.reportType,
        widget.period,
      );

      final rawModels = result['models'];
      final models = rawModels is List
          ? rawModels
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _total = (result['total'] as num?)?.toInt() ?? 0;
          _models = models;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final periodLabel =
        widget.period == 'today' ? "Today's" : "Yesterday's";
    final typeLabel = _isBooking ? 'Booking' : 'Sale';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '$periodLabel $typeLabel — Model Summary',
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
            child: Center(
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
        if (_models.isEmpty)
          _buildEmpty()
        else
          ..._models.asMap().entries.map(
            (entry) => _buildModelCard(entry.key, entry.value, theme),
          ),
      ],
    );
  }

  Widget _buildSummaryHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final periodLabel =
        widget.period == 'today' ? "Today's" : "Yesterday's";
    final typeLabel = _isBooking ? 'Booking' : 'Sale';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isBooking
              ? (isDark
                  ? [const Color(0xFF0A2A5C), const Color(0xFF1A4A8C)]
                  : [const Color(0xFF0A3D8F), const Color(0xFF1E88E5)])
              : (isDark
                  ? [const Color(0xFF0A3A20), const Color(0xFF2A5A30)]
                  : [const Color(0xFF1B5E20), const Color(0xFF43A047)]),
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
            '$periodLabel Total $typeLabel',
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
            '${_models.length} ${_models.length == 1 ? 'Model' : 'Models'}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(
    int index,
    Map<String, dynamic> model,
    ThemeData theme,
  ) {
    final modelName = model['modelName']?.toString() ?? 'Unknown';
    final count = (model['count'] as num?)?.toInt() ?? 0;
    final isDark = theme.brightness == Brightness.dark;

    // Progress bar — fraction of total
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
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Model name
                    Expanded(
                      child: Text(
                        modelName,
                        style: TextStyle(
                          fontSize: 16,
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
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(fraction * 100).toStringAsFixed(1)}% of total',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
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
            _isBooking
                ? Icons.bookmark_border_rounded
                : Icons.sell_outlined,
            color: _primaryColor.withOpacity(0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _isBooking
                ? widget.period == 'today'
                      ? 'No bookings found today'
                      : 'No bookings found yesterday'
                : widget.period == 'today'
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
