import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class B2RDetailsScreen extends StatefulWidget {
  final String period;

  const B2RDetailsScreen({super.key, required this.period});

  @override
  State<B2RDetailsScreen> createState() => _B2RDetailsScreenState();
}

class _B2RDetailsScreenState extends State<B2RDetailsScreen> {
  static const Color _primary = Color(0xFF1565C0);
  static const Color _accent = Color(0xFF008577);

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  String get _periodLabel => switch (widget.period) {
    'today' => 'Today',
    'month' => 'Month to date',
    _ => 'Total',
  };

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
      final rows = await ApiService.getB2RDetails(widget.period);

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _value(Map<String, dynamic> row, String key) {
    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        return entry.value?.toString().trim() ?? '';
      }
    }
    return '';
  }

  String _formatDate(String value) {
    if (value.isEmpty) return '';

    final date = DateTime.tryParse(value);
    if (date == null) return value;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  Widget _chip(
    IconData icon,
    String text, {
    Color? color,
    required ThemeData theme,
  }) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark
        ? (color == _accent ? const Color(0xFF80CBC4) : const Color(0xFF90CAF9))
        : (color ?? _primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryHeader(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 15),
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF102A43), Color(0xFF174A7E)]
              : const [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: isDark ? 0.10 : 0.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking To Retail Records',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Booking To Retail delivery details',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${_rows.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'Total B2R • $_periodLabel',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> row, int index, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final customer = _value(row, 'Customer');
    final deliveryDate = _formatDate(_value(row, 'DeliveryDate'));
    final variant = _value(row, 'variant');
    final colorName = _value(row, 'colorname');

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE5ECF7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.12)
                : Colors.blueGrey.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263B52)
                      : const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF90CAF9) : _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    customer.isEmpty ? 'Customer not available' : customer,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: isDark ? Colors.white12 : const Color(0xFFEEEEEE),
            ),
          ),
          Wrap(
            spacing: 7,
            runSpacing: 8,
            children: [
              _chip(Icons.directions_car_rounded, variant, theme: theme),
              _chip(
                Icons.calendar_month_rounded,
                deliveryDate,
                color: _accent,
                theme: theme,
              ),
              _chip(
                Icons.palette_outlined,
                colorName,
                color: const Color(0xFF5265A8),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _messageState({
    required ThemeData theme,
    required IconData icon,
    required String message,
    bool showRetry = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF102A43) : _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'B2R — $_periodLabel Details',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 300),
                  Center(child: CircularProgressIndicator(color: _primary)),
                ],
              )
            : _error != null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 450,
                    child: _messageState(
                      theme: theme,
                      icon: Icons.error_outline_rounded,
                      message: 'Unable to load B2R records.\n$_error',
                      showRetry: true,
                    ),
                  ),
                ],
              )
            : _rows.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  _summaryHeader(theme),
                  SizedBox(
                    height: 300,
                    child: _messageState(
                      theme: theme,
                      icon: Icons.receipt_long_outlined,
                      message: 'No B2R records found',
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                itemCount: _rows.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) return _summaryHeader(theme);

                  return _recordCard(_rows[index - 1], index - 1, theme);
                },
              ),
      ),
    );
  }
}
