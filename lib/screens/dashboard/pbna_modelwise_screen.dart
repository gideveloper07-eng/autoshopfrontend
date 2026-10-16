import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';
import 'pbna_details_screen.dart';

/// PBNA (Pending Booking No Allocation) — Model-wise breakdown screen.
/// Calls SP: A_SP_FOR_ApplicationChallangrid @what='Pbna_Modelwise'
class PbnaModelwiseScreen extends StatefulWidget {
  const PbnaModelwiseScreen({super.key});

  @override
  State<PbnaModelwiseScreen> createState() => _PbnaModelwiseScreenState();
}

class _PbnaModelwiseScreenState extends State<PbnaModelwiseScreen> {
  static const Color _primary = Color(0xFF6A1B9A);
  static const Color _accent = Color(0xFFAB47BC);

  bool _isLoading = true;
  String? _error;
  int _total = 0;
  List<Map<String, dynamic>> _models = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getPbnaModelwise();

      final rawModels = result['models'];
      final models = rawModels is List
          ? rawModels
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
          : <Map<String, dynamic>>[];

      // Sort highest count first
      models.sort(
        (a, b) => ((b['count'] as num?) ?? 0).compareTo(
          (a['count'] as num?) ?? 0,
        ),
      );

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'PBNA — Model Wise',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _buildBody(theme),
      ),
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
              child: CircularProgressIndicator(color: _primary),
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
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(),
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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF3A0750), const Color(0xFF6A1B9A)]
              : [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Booking',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    'No Allocation (PBNA)',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total count
          Text(
            _total.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_models.length} ${_models.length == 1 ? 'Model' : 'Models'} with pending bookings',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Model Card ─────────────────────────────────────────────────────────────

  Widget _buildModelCard(
    int index,
    Map<String, dynamic> model,
    ThemeData theme,
  ) {
    final modelName = model['modelName']?.toString() ?? 'Unknown';
    final count = (model['count'] as num?)?.toInt() ?? 0;
    final isDark = theme.brightness == Brightness.dark;
    final fraction = _total > 0 ? count / _total : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PbnaDetailsScreen(
            modelName: modelName,
            totalCount: count,
          ),
        ),
      ),
      child: Container(
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
                        color: _primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          color: _primary,
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
                        color: _primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Chevron
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _primary.withOpacity(0.5),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(fraction * 100).toStringAsFixed(1)}% of total',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      '$count pending',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: _primary.withOpacity(0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No pending bookings without allocation',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All bookings have vehicles allocated.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
