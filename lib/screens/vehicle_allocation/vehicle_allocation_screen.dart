import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/activity_service.dart';
import 'vehicle_allocation_form_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Column definition helper
// ─────────────────────────────────────────────────────────────────────────────
class _ColDef {
  final String key;
  final String label;
  final double width;
  const _ColDef({required this.key, required this.label, required this.width});
}

// Fixed readable widths prevent the columns from becoming cramped on small
// screens. The whole grid becomes horizontally scrollable when necessary.
const List<_ColDef> _columns = [
  _ColDef(key: 'va_17', label: 'Date', width: 125),
  _ColDef(key: 'va_18', label: 'Booking No', width: 115),
  _ColDef(key: 'va_24', label: 'Customer', width: 255),
  _ColDef(key: 'va_26', label: 'Model', width: 145),
  _ColDef(key: 'va_29', label: 'VIN', width: 220),
];

const double _gridMinWidth = 860;

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Allocation Screen
// ─────────────────────────────────────────────────────────────────────────────
class VehicleAllocationScreen extends StatefulWidget {
  const VehicleAllocationScreen({super.key});

  @override
  State<VehicleAllocationScreen> createState() =>
      _VehicleAllocationScreenState();
}

class _VehicleAllocationScreenState extends State<VehicleAllocationScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _accent = Color(0xFF2C6CE0);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _filteredRows = [];
  int _selectedTab = 0;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _gridVerticalController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadData();
    ActivityService.logActivity(
      activityType: "VIEW",
      activityName: "Vehicle Allocation List",
      screenName: "VehicleAllocationScreen",
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    _gridVerticalController.dispose();
    super.dispose();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    _animController.reset();

    try {
      final data = await ApiService.getVehicleAllocationList();

      if (!mounted) return;

      setState(() {
        _rows = data;
        _loading = false;
      });

      _applyCurrentTabFilter();

      _animController.forward();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  // ─────────────────────────────────────────────────────────────────────────────
  // TODAY FILTER
  // ─────────────────────────────────────────────────────────────────────────────

  bool _isTodayAllocation(Map<String, dynamic> row) {
    final value = row['va_17'];

    if (value == null) return false;

    final dateText = value.toString().trim();
    if (dateText.isEmpty) return false;

    DateTime? allocationDate;

    // SQL/ISO formats such as:
    // 2026-09-09
    // 2026-09-09T14:15:30
    // 2026-09-09 14:15:30
    allocationDate = DateTime.tryParse(dateText);

    // Fallback for dd/MM/yyyy or dd-MM-yyyy.
    if (allocationDate == null) {
      final clean = dateText.split(' ').first.replaceAll('/', '-');
      final parts = clean.split('-');

      if (parts.length == 3) {
        try {
          if (parts[0].length == 4) {
            allocationDate = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          } else {
            allocationDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }
    }

    if (allocationDate == null) return false;

    final now = DateTime.now();

    return allocationDate.year == now.year &&
        allocationDate.month == now.month &&
        allocationDate.day == now.day;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // APPLY TAB + SEARCH FILTER
  // ─────────────────────────────────────────────────────────────────────────────

  void _applyCurrentTabFilter() {
    List<Map<String, dynamic>> result;

    if (_selectedTab == 1) {
      // TODAY ALLOCATION
      result = _rows.where(_isTodayAllocation).toList();
    } else {
      // ALL ALLOCATION
      result = List<Map<String, dynamic>>.from(_rows);
    }

    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((row) {
        return _cell(row, 'va_24').toLowerCase().contains(query) ||
            _cell(row, 'va_29').toLowerCase().contains(query) ||
            _cell(row, 'va_18').toLowerCase().contains(query) ||
            _cell(row, 'va_26').toLowerCase().contains(query);
      }).toList();
    }

    if (!mounted) return;

    setState(() {
      _filteredRows = result;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // TAB CHANGE
  // ─────────────────────────────────────────────────────────────────────────────

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });

    _applyCurrentTabFilter();
  }

  void _filterSearch(String query) {
    _applyCurrentTabFilter();
  }

  String _cell(Map<String, dynamic> row, String key) {
    final v = row[key];
    if (v == null) return '-';
    String t = v.toString();
    if (t.isEmpty) return '-';
    // Format date fields
    if (key == 'va_17') {
      if (t.contains('T')) t = t.split('T').first;
      final parts = t.split('-');
      if (parts.length == 3) {
        final yy = parts[0].length >= 2
            ? parts[0].substring(parts[0].length - 2)
            : parts[0];
        return '${parts[2]}-${parts[1]}-$yy';
      }
    }
    return t;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _onAdd() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'VehicleAllocationFormScreen'),
        builder: (_) => const VehicleAllocationFormScreen(),
      ),
    );
    if (result == true) _loadData();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;
    final cardBg = theme.colorScheme.surface;
    final textDark = theme.colorScheme.onSurface;
    final textMid = isDark ? const Color(0xFF8A9BB0) : const Color(0xFF64748B);
    final gridBorder = isDark
        ? const Color(0xFF2A3A4A)
        : const Color(0xFFC7D2FE);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildAllocationTabs(isDark),
          _buildSearchBar(isDark, textMid),
          Expanded(
            child: _loading
                ? _buildLoader(textMid)
                : _error != null
                ? _buildError(textDark, textMid)
                : _filteredRows.isEmpty
                ? _buildEmpty(textMid)
                : _buildGrid(cardBg, textMid, gridBorder, isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAdd,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Allocation',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0A2A5C),
                  const Color(0xFF1A4A8C),
                  const Color(0xFF2A6AAC),
                ]
              : [
                  const Color(0xFF0D3F8A),
                  const Color(0xFF2C6CE0),
                  const Color(0xFF82C9FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x331A4A8C) : const Color(0x332C6CE0),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 18),
          child: Row(
            children: [
              // Back button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.car_rental_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Title
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Allocation',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      'Manage vehicle allocations',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Refresh button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _loadData,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ALLOCATION TABS
  // ─────────────────────────────────────────────────────────────────────────────

  Widget _buildAllocationTabs(bool isDark) {
    final selectedBg = _primary;
    final unselectedBg = isDark ? const Color(0xFF1A2535) : Colors.white;

    final selectedText = Colors.white;
    final unselectedText = isDark
        ? const Color(0xFFB8C7D9)
        : const Color(0xFF334E7A);

    final todayCount = _rows.where(_isTodayAllocation).length;

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F6FF),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: unselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2A3A4A) : const Color(0xFFD1E3FF),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildAllocationTabButton(
                title: 'All Allocation',
                icon: Icons.list_alt_rounded,
                selected: _selectedTab == 0,
                count: _rows.length,
                selectedBg: selectedBg,
                selectedText: selectedText,
                unselectedText: unselectedText,
                onTap: () => _onTabChanged(0),
              ),
            ),
            Expanded(
              child: _buildAllocationTabButton(
                title: 'Today Allocation',
                icon: Icons.today_rounded,
                selected: _selectedTab == 1,
                count: todayCount,
                selectedBg: selectedBg,
                selectedText: selectedText,
                unselectedText: unselectedText,
                onTap: () => _onTabChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationTabButton({
    required String title,
    required IconData icon,
    required bool selected,
    required int count,
    required Color selectedBg,
    required Color selectedText,
    required Color unselectedText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: selected ? selectedBg : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? selectedText : unselectedText,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? selectedText : unselectedText,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : _accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar(bool isDark, Color textMid) {
    return Container(
      color: isDark ? const Color(0xFF0F1923) : const Color(0xFFF0F6FF),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: TextField(
        controller: _searchController,
        onChanged: _filterSearch,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: 'Search customer, booking no, VIN...',
          hintStyle: TextStyle(
            color: textMid,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: textMid, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded, color: textMid, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _filterSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1A2535) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF2A3A4A) : const Color(0xFFD1E3FF),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── States ────────────────────────────────────────────────────────────────

  Widget _buildLoader(Color textMid) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: _primary,
              backgroundColor: _accent.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading vehicle allocations...',
            style: TextStyle(
              fontSize: 14,
              color: textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Color textDark, Color textMid) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Color(0xFFE53935),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: textMid),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(Color textMid) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.car_rental_rounded,
              size: 44,
              color: Color(0xFF2C6CE0),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedTab == 1
                ? 'No allocations found for today'
                : 'No allocations found',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textMid,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTab == 1
                ? 'There are no vehicle allocations dated today.'
                : 'Tap + to create a new vehicle allocation.',
            style: TextStyle(fontSize: 13, color: textMid),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Data grid ─────────────────────────────────────────────────────────────

  Widget _buildGrid(
    Color cardBg,
    Color textMid,
    Color gridBorder,
    bool isDark,
  ) {
    const headerBg = Color(0xFF0D3F8A);
    final evenRow = isDark ? const Color(0xFF1A2535) : Colors.white;
    final oddRow = isDark ? const Color(0xFF1E2E42) : const Color(0xFFF3F7FF);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accent.withValues(alpha: 0.16)),
                  ),
                  child: Text(
                    '${_filteredRows.length} record${_filteredRows.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gridBorder),
                color: cardBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.28 : 0.055,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // The table fills wide screens. On narrow screens it keeps
                    // readable column widths and becomes horizontally scrollable.
                    final tableWidth = constraints.maxWidth > _gridMinWidth
                        ? constraints.maxWidth
                        : _gridMinWidth;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: tableWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          children: [
                            _buildGridHeader(headerBg, isDark),
                            Expanded(
                              child: Scrollbar(
                                controller: _gridVerticalController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                interactive: true,
                                child: ListView.separated(
                                  controller: _gridVerticalController,
                                  primary: false,
                                  padding: EdgeInsets.zero,
                                  itemCount: _filteredRows.length,
                                  physics: const ClampingScrollPhysics(),
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: gridBorder,
                                  ),
                                  itemBuilder: (_, i) {
                                    final row = _filteredRows[i];
                                    return _DataRow(
                                      row: row,
                                      bg: i.isEven ? evenRow : oddRow,
                                      textMid: textMid,
                                      cellFn: _cell,
                                      isDark: isDark,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridHeader(Color headerBg, bool isDark) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerBg, const Color(0xFF2C6CE0)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ..._columns.map(
            (c) => SizedBox(
              width: c.width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.unfold_more_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data row widget — read-only, no actions
// ─────────────────────────────────────────────────────────────────────────────
class _DataRow extends StatelessWidget {
  final Map<String, dynamic> row;
  final Color bg;
  final Color textMid;
  final String Function(Map<String, dynamic>, String) cellFn;
  final bool isDark;

  const _DataRow({
    required this.row,
    required this.bg,
    required this.textMid,
    required this.cellFn,
    required this.isDark,
  });

  Widget _modelBadge(String model) {
    final label = model.trim().isEmpty || model == '-' ? '-' : model.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF284D7A) : const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: isDark ? const Color(0xFFBBD7FF) : const Color(0xFF1559C7),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date
          SizedBox(
            width: _columns[0].width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 17,
                    color: isDark
                        ? const Color(0xFF9DB8D8)
                        : const Color(0xFF31527E),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      cellFn(row, 'va_17'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white : const Color(0xFF334E7A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Booking number
          SizedBox(
            width: _columns[1].width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                cellFn(row, 'va_18'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF334E7A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Customer — deliberately wider and allowed two lines.
          SizedBox(
            width: _columns[2].width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                cellFn(row, 'va_24'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  color: isDark ? Colors.white : const Color(0xFF334E7A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // Model badge
          SizedBox(
            width: _columns[3].width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _modelBadge(cellFn(row, 'va_26')),
            ),
          ),

          // VIN + right arrow
          SizedBox(
            width: _columns[4].width,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cellFn(row, 'va_29'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.15,
                        color: isDark ? Colors.white : const Color(0xFF334E7A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 24,
                    color: Color(0xFF1764E8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
