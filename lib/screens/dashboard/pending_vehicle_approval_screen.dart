import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class PendingVehicleApprovalScreen extends StatefulWidget {
  const PendingVehicleApprovalScreen({super.key});

  @override
  State<PendingVehicleApprovalScreen> createState() =>
      _PendingVehicleApprovalScreenState();
}

class _PendingVehicleApprovalScreenState
    extends State<PendingVehicleApprovalScreen> {
  late Future<List<Map<String, dynamic>>> _ordersFuture;
  String _selectedStatus = 'Pending';

  static const Color primary = Color(0xFF7020A0);
  static const Color accent = Color(0xFFB344C6);

  // Tracks approval requests independently so only the selected card is disabled.
  final Set<String> _approvingOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    _ordersFuture = _selectedStatus == 'Approved'
        ? ApiService.getApprovedVehicleOrders()
        : ApiService.getPendingVehicleOrderApprovals();
  }

  Future<void> _refresh() async {
    setState(_loadOrders);
    try {
      await _ordersFuture;
    } catch (_) {
      // The FutureBuilder displays the error.
    }
  }

  String _value(Map<String, dynamic> row, String key) {
    return (row[key] ?? '').toString().trim();
  }

  String _formatDate(String value) {
    if (value.isEmpty) return 'Date not available';

    try {
      final date = DateTime.parse(value).toLocal();
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return value;
    }
  }

  int _ageingDays(String value) {
    if (value.isEmpty) return 0;

    try {
      final date = DateTime.parse(value).toLocal();
      final today = DateTime.now();

      final startDate = DateTime(date.year, date.month, date.day);
      final currentDate = DateTime(today.year, today.month, today.day);

      final days = currentDate.difference(startDate).inDays;
      return days < 0 ? 0 : days;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _approveOrder(Map<String, dynamic> row) async {
    final orderDetailId = _value(row, 'orderdetailid');

    if (orderDetailId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Order detail ID is missing. Ensure the Approval API returns orderdetailid.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Vehicle Order?'),
        content: Text(
          'Do you want to approve Order No: ${_value(row, 'orderno')}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _approvingOrderIds.add(orderDetailId));

    try {
      final result = await ApiService.approveVehicleOrder(orderDetailId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (result['message'] ?? 'Vehicle order approved successfully.')
                .toString(),
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );

      await _refresh();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approval failed: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _approvingOrderIds.remove(orderDetailId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageBackground = isDark
        ? const Color(0xFF101522)
        : theme.scaffoldBackgroundColor;
    final primaryText = isDark
        ? const Color(0xFFF1F5F9)
        : theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: AppBar(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Vehicle Order Approval',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                'Pending and approved vehicle orders',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'Pending',
                    label: Text('Pending'),
                    icon: Icon(Icons.pending_actions),
                  ),
                  ButtonSegment<String>(
                    value: 'Approved',
                    label: Text('Approved'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {_selectedStatus},
                onSelectionChanged: (selection) {
                  if (selection.isEmpty) return;
                  setState(() {
                    _selectedStatus = selection.first;
                    _loadOrders();
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 44,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedStatus == 'Pending'
                                ? 'Unable to load pending vehicle orders'
                                : 'Unable to load approved vehicle orders',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: primaryText),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(_loadOrders);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildHeader(orders.length),
                    Expanded(
                      child: orders.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 120),
                                  Icon(
                                    _selectedStatus == 'Pending'
                                        ? Icons.pending_actions
                                        : Icons.check_circle_outline,
                                    size: 58,
                                    color: _selectedStatus == 'Pending'
                                        ? Colors.deepOrange
                                        : Colors.green,
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Text(
                                      _selectedStatus == 'Pending'
                                          ? 'No pending vehicle orders'
                                          : 'No approved vehicle orders',
                                      style: TextStyle(
                                        color: primaryText,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      'Pull down to refresh',
                                      style: TextStyle(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refresh,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  12,
                                  12,
                                  20,
                                ),
                                itemCount: orders.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderCard(
                                    orders[index],
                                    index + 1,
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF342044)
                  : Colors.white.withValues(alpha: 0.17),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedStatus == 'Pending'
                      ? 'Total Pending'
                      : 'Total Approved',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> row, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1B2433) : theme.cardColor;
    final primaryText = isDark
        ? const Color(0xFFF1F5F9)
        : theme.colorScheme.onSurface;
    final secondaryText = isDark
        ? const Color(0xFFB8C4D6)
        : theme.colorScheme.onSurfaceVariant;
    final outlineColor = isDark
        ? const Color(0xFF39465A)
        : theme.colorScheme.outlineVariant;
    final orderNo = _value(row, 'orderno');
    final orderDate = _value(row, 'orderdate');
    final model = _value(row, 'model');
    final variant = _value(row, 'variant');
    final color = _value(row, 'color');
    final customer = _value(row, 'customername');
    final ageing = _ageingDays(orderDate);
    final orderDetailId = _value(row, 'orderdetailid');
    final isApproving =
        orderDetailId.isNotEmpty && _approvingOrderIds.contains(orderDetailId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: outlineColor.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.055),
            blurRadius: 9,
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
                width: 29,
                height: 29,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? primary.withValues(alpha: 0.24)
                      : const Color(0xFFF1E6F5),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customer.isEmpty ? 'Customer not available' : customer,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _selectedStatus == 'Pending'
                    ? Icons.pending_actions
                    : Icons.check_circle,
                size: 19,
                color: _selectedStatus == 'Pending'
                    ? Colors.deepOrange
                    : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 39),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(
                  Icons.calendar_today_outlined,
                  _formatDate(orderDate),
                ),
                if (orderNo.isNotEmpty)
                  _infoLine(Icons.receipt_long_outlined, 'Order No: $orderNo'),
                _infoLine(
                  Icons.access_time,
                  'Ageing: $ageing ${ageing == 1 ? 'day' : 'days'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.8, color: outlineColor),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              if (model.isNotEmpty)
                _vehicleChip(
                  Icons.directions_car_outlined,
                  model,
                  const Color(0xFF8E24AA),
                ),
              if (variant.isNotEmpty)
                _vehicleChip(Icons.tune, variant, const Color(0xFF8E24AA)),
              if (color.isNotEmpty)
                _vehicleChip(
                  Icons.palette_outlined,
                  color,
                  const Color(0xFFD81B60),
                ),
            ],
          ),
          const SizedBox(height: 9),
          const SizedBox(height: 2),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _selectedStatus == 'Pending'
                      ? (isDark
                            ? const Color(0xFF4A3218)
                            : const Color(0xFFFFF2DF))
                      : (isDark
                            ? const Color(0xFF173D2B)
                            : const Color(0xFFE5F7EC)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedStatus == 'Pending'
                          ? Icons.schedule
                          : Icons.check_circle_outline,
                      size: 14,
                      color: _selectedStatus == 'Pending'
                          ? Colors.deepOrange
                          : Colors.green,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _selectedStatus == 'Pending'
                          ? 'Pending Approval'
                          : 'Approved',
                      style: TextStyle(
                        color: _selectedStatus == 'Pending'
                            ? (isDark
                                  ? const Color(0xFFFFC16B)
                                  : const Color(0xFF80501B))
                            : (isDark
                                  ? const Color(0xFF8CE0AA)
                                  : const Color(0xFF176B3A)),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedStatus == 'Pending')
                ElevatedButton.icon(
                  onPressed: isApproving || orderDetailId.isEmpty
                      ? null
                      : () => _approveOrder(row),
                  icon: isApproving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(isApproving ? 'Approving...' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.green.shade200,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleChip(IconData icon, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipForeground = isDark
        ? (color == const Color(0xFFEC407A)
              ? const Color(0xFFFFB4CC)
              : const Color(0xFFE9D5FF))
        : color;
    final chipBackground = isDark
        ? color.withValues(alpha: 0.20)
        : color.withValues(alpha: 0.09);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: chipBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: chipForeground.withValues(alpha: isDark ? 0.28 : 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: chipForeground),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: chipForeground,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
