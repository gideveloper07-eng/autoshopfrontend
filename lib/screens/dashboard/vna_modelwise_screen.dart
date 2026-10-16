import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../home/rgb_border_card.dart';
import 'vna_details_screen.dart';

/// VNA (Vehicles Not Allocated) — Model+Variant+Color wise demand gap screen.
/// Calls SP: A_SP_FOR_ApplicationChallangrid @what='Vna_modelwise'
class VnaModelwiseScreen extends StatefulWidget {
  const VnaModelwiseScreen({super.key});

  @override
  State<VnaModelwiseScreen> createState() => _VnaModelwiseScreenState();
}

class _VnaModelwiseScreenState extends State<VnaModelwiseScreen> {
  static const Color _primary = Color(0xFF880E4F);
  static const Color _accent = Color(0xFFE91E63);

  bool _isLoading = true;
  String? _error;
  int _total = 0;
  List<Map<String, dynamic>> _rows = [];

  // Group rows by model name for collapsible sections
  Map<String, List<Map<String, dynamic>>> _grouped = {};
  Set<String> _expandedModels = {};

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
      final result = await ApiService.getVnaModelwise();

      final rawRows = result['rows'];
      final rows = rawRows is List
          ? rawRows
                .whereType<Map>()
                .map((r) => Map<String, dynamic>.from(r))
                .toList()
          : <Map<String, dynamic>>[];

      // Group by model
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in rows) {
        final model = row['model']?.toString() ?? 'Unknown';
        grouped.putIfAbsent(model, () => []).add(row);
      }

      if (mounted) {
        setState(() {
          _total = (result['total'] as num?)?.toInt() ?? 0;
          _rows = rows;
          _grouped = grouped;
          // Expand all models by default
          _expandedModels = grouped.keys.toSet();
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
          'VNA — Model Wise',
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
        if (_rows.isEmpty)
          _buildEmpty()
        else
          ..._grouped.entries.toList().asMap().entries.map(
            (outer) => _buildModelSection(
              outer.key,
              outer.value.key,
              outer.value.value,
              theme,
            ),
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
              ? [const Color(0xFF4A0020), const Color(0xFF880E4F)]
              : [const Color(0xFF880E4F), const Color(0xFFE91E63)],
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.no_crash_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicles Not Allocated',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    'Demand exceeds stock (VNA)',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            '${_grouped.length} ${_grouped.length == 1 ? 'Model' : 'Models'} • ${_rows.length} variant combinations',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Model section (collapsible) ────────────────────────────────────────────

  Widget _buildModelSection(
    int index,
    String modelName,
    List<Map<String, dynamic>> variants,
    ThemeData theme,
  ) {
    final isExpanded = _expandedModels.contains(modelName);
    final modelTotal = variants.fold<int>(
      0,
      (sum, r) => sum + ((r['qty'] as num?)?.toInt() ?? 0),
    );
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: RgbBorderCard(
        borderRadius: 18,
        borderWidth: 2.0,
        glow: true,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              // ── Model header row (tappable) ──
              InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(18),
                ),
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedModels.remove(modelName);
                    } else {
                      _expandedModels.add(modelName);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                      const SizedBox(width: 12),
                      // Model name + variant count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modelName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${variants.length} variant${variants.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Model total badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          modelTotal.toString(),
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _primary.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Variant rows (animated expand) ──
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white12
                          : Colors.grey.shade200,
                    ),
                    ...variants.asMap().entries.map(
                      (entry) => _buildVariantRow(
                        entry.key,
                        entry.value,
                        variants.length,
                        theme,
                      ),
                    ),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Variant row inside a model section ─────────────────────────────────────

  Widget _buildVariantRow(
    int index,
    Map<String, dynamic> row,
    int total,
    ThemeData theme,
  ) {
    final variant = row['variant']?.toString() ?? '';
    final color   = row['color']?.toString()   ?? '';
    final qty     = (row['qty'] as num?)?.toInt() ?? 0;
    final model   = row['model']?.toString()   ?? '';
    final isDark  = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VnaDetailsScreen(
            modelName:   model,
            variantName: variant,
            colorName:   color,
            qty:         qty,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          border: index < total - 1
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade100,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            // Variant + Color chips
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (variant.isNotEmpty && variant != '—')
                    _chip(
                      icon: Icons.tune_rounded,
                      label: variant,
                      color: _primary,
                      theme: theme,
                    ),
                  if (variant.isNotEmpty && variant != '—')
                    const SizedBox(height: 5),
                  if (color.isNotEmpty && color != '—')
                    _chip(
                      icon: Icons.color_lens_rounded,
                      label: color,
                      color: _accent,
                      theme: theme,
                    ),
                ],
              ),
            ),
            // QTY badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 13,
                    color: _accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    qty.toString(),
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: _primary.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String label,
    required Color color,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

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
            'No unallocated vehicle demand',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All booking demand is covered by current stock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
