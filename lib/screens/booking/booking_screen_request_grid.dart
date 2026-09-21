import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import 'booking_request_form_screen.dart';

class BookingScreenRequestGrid extends StatefulWidget {
  const BookingScreenRequestGrid({super.key});

  @override
  State<BookingScreenRequestGrid> createState() =>
      _BookingScreenRequestGridState();
}

class _BookingScreenRequestGridState extends State<BookingScreenRequestGrid> {
  // ─────────────────────────────────────────────────────────────────────────
  // Theme
  // ─────────────────────────────────────────────────────────────────────────

  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _accent = Color(0xFF2C6CE0);

  // ─────────────────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────────────────

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _bookingRequests = [];

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    ActivityService.logActivity(
      activityType: 'SCREEN',
      activityName: 'BookingScreenRequestGrid',
      screenName: 'BookingScreenRequestGrid',
    );

    _loadBookingRequests();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Load Data
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadBookingRequests() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getBookingRequestGrid();

      if (!mounted) return;

      setState(() {
        _bookingRequests = data;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Open New Booking Request
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openNewBookingRequest() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'BookingRequestFormScreen'),
        builder: (_) => const BookingRequestFormScreen(),
      ),
    );

    if (mounted) {
      _loadBookingRequests();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.bg(context),

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),

        title: Builder(
          builder: (context) {
            final width = MediaQuery.sizeOf(context).width;

            return Text(
              'Booking Requests',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: width < 360 ? 15 : 18,
              ),
            );
          },
        ),

        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0A2A5C), Color(0xFF1A4A8C)]
                  : const [_primary, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        foregroundColor: Colors.white,
        elevation: 0,

        actions: [
          Builder(
            builder: (context) {
              final width = MediaQuery.sizeOf(context).width;

              // Small / Extra-small screens:
              // Use icon-only actions so the AppBar never overflows.
              if (width < 600) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Add New Booking',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: _openNewBookingRequest,
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loading ? null : _loadBookingRequests,
                    ),
                  ],
                );
              }

              // Medium / Large / Extra-large screens:
              // Show the full ADD NEW button.
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ElevatedButton.icon(
                      onPressed: _openNewBookingRequest,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'ADD NEW',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loading ? null : _loadBookingRequests,
                  ),
                ],
              );
            },
          ),
        ],
      ),

      body: _buildBody(context),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Loading booking requests...', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 50,
              ),
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadBookingRequests,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookingRequests,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: _pageHorizontalPadding(constraints.maxWidth),
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(constraints.maxWidth),

                const SizedBox(height: 16),

                if (_bookingRequests.isEmpty)
                  _buildEmptyState()
                else
                  _buildBookingGrid(constraints),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Responsive Breakpoints
  // ─────────────────────────────────────────────────────────────────────────

  double _pageHorizontalPadding(double width) {
    if (width < 360) return 8;
    if (width < 600) return 12;
    if (width < 900) return 16;
    if (width < 1200) return 20;
    return 28;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Summary
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(double width) {
    final compact = width < 600;
    final extraLarge = width >= 1200;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact
            ? 14
            : extraLarge
            ? 24
            : 18,
        vertical: compact
            ? 12
            : extraLarge
            ? 20
            : 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 40 : 46,
            height: compact ? 40 : 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.book_online_rounded,
              color: Colors.white,
              size: compact ? 21 : 25,
            ),
          ),

          SizedBox(width: compact ? 10 : 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact
                        ? 15
                        : extraLarge
                        ? 19
                        : 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pending customer booking requests',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 12,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_bookingRequests.length}',
              style: TextStyle(
                color: _primary,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 70),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No booking requests found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a new booking request to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _openNewBookingRequest,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add New Booking'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Responsive Grid
  //
  // Extra Small : < 360   -> compact cards
  // Small       : 360-599 -> cards
  // Medium      : 600-899 -> compact responsive table
  // Large       : 900-1199 -> full responsive table
  // Extra Large : >=1200 -> spacious full responsive table
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBookingGrid(BoxConstraints constraints) {
    final width = constraints.maxWidth;

    if (width < 360) {
      return _buildMobileCards(compact: true);
    }

    if (width < 600) {
      return _buildMobileCards(compact: false);
    }

    if (width < 900) {
      return _buildResponsiveTable(compact: true);
    }

    if (width < 1200) {
      return _buildResponsiveTable(compact: false);
    }

    return _buildResponsiveTable(compact: false, extraLarge: true);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Responsive Table
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildResponsiveTable({
    bool compact = false,
    bool extraLarge = false,
  }) {
    final theme = Theme.of(context);

    final horizontalPadding = extraLarge
        ? 28.0
        : compact
        ? 12.0
        : 20.0;

    final verticalPadding = extraLarge
        ? 18.0
        : compact
        ? 12.0
        : 15.0;

    final headerFontSize = extraLarge
        ? 14.0
        : compact
        ? 12.0
        : 13.0;

    final dataFontSize = extraLarge
        ? 14.0
        : compact
        ? 12.0
        : 13.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.8),
            3: FlexColumnWidth(1.5),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header
            TableRow(
              decoration: const BoxDecoration(color: _primary),
              children: [
                _buildTableHeader(
                  'Customer Name',
                  fontSize: headerFontSize,
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
                _buildTableHeader(
                  'Model',
                  fontSize: headerFontSize,
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
                _buildTableHeader(
                  'Variant',
                  fontSize: headerFontSize,
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
                _buildTableHeader(
                  'Color',
                  fontSize: headerFontSize,
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ],
            ),

            // Data
            ...List.generate(_bookingRequests.length, (index) {
              final item = _bookingRequests[index];
              final isEven = index % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven
                      ? theme.cardColor
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          0.35,
                        ),
                ),
                children: [
                  _buildTableCell(
                    _value(item['customername']),
                    fontSize: dataFontSize,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding,
                    bold: true,
                  ),
                  _buildTableCell(
                    _value(item['Model']),
                    fontSize: dataFontSize,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding,
                  ),
                  _buildTableCell(
                    _value(item['Variant']),
                    fontSize: dataFontSize,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding,
                  ),
                  _buildTableCell(
                    _value(item['Color']),
                    fontSize: dataFontSize,
                    horizontalPadding: horizontalPadding,
                    verticalPadding: verticalPadding,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(
    String text, {
    required double fontSize,
    required double horizontalPadding,
    required double verticalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    required double fontSize,
    required double horizontalPadding,
    required double verticalPadding,
    bool bold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Mobile Cards
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMobileCards({bool compact = false}) {
    return Column(
      children: List.generate(_bookingRequests.length, (index) {
        final item = _bookingRequests[index];

        return _buildBookingCard(index + 1, item, compact: compact);
      }),
    );
  }

  Widget _buildBookingCard(
    int index,
    Map<String, dynamic> item, {
    bool compact = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: _primary,
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  _value(item['customername']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          Divider(height: compact ? 20 : 24),

          _infoRow(
            Icons.directions_car_outlined,
            'Model',
            _value(item['Model']),
            compact: compact,
          ),

          SizedBox(height: compact ? 8 : 10),

          _infoRow(
            Icons.category_outlined,
            'Variant',
            _value(item['Variant']),
            compact: compact,
          ),

          SizedBox(height: compact ? 8 : 10),

          _infoRow(
            Icons.palette_outlined,
            'Color',
            _value(item['Color']),
            compact: compact,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: compact ? 18 : 20, color: _accent),

        const SizedBox(width: 10),

        SizedBox(
          width: compact ? 62 : 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: compact ? 12 : 13),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _value(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty) return '-';

    return text;
  }
}
