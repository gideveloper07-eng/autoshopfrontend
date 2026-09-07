import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/activity_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Allocation Form Screen
// Add (va12 == null) or Edit (va12 provided)
// Mirrors the ASP.NET frm_vehicle_allocation page exactly:
//   Customer → auto-fills address / contact / booking no / SC / TL / Manager /
//              Model / Variant / Colour → auto-loads VIN list
// ─────────────────────────────────────────────────────────────────────────────
class VehicleAllocationFormScreen extends StatefulWidget {
  final String? va12; // null → new record

  const VehicleAllocationFormScreen({super.key, this.va12});

  @override
  State<VehicleAllocationFormScreen> createState() =>
      _VehicleAllocationFormScreenState();
}

class _VehicleAllocationFormScreenState
    extends State<VehicleAllocationFormScreen> {
  // ── Theme colours ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _accent = Color(0xFF2C6CE0);

  // ── Loading states ─────────────────────────────────────────────────────────
  bool _loadingDropdowns = true;
  bool _loadingEdit = false;
  bool _loadingVin = false;
  bool _saving = false;
  String? _initError;

  // ── Dropdown data ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _colours = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _staff = [];

  // ── VIN details grid ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _vinDetails = [];

  // ── Controllers ───────────────────────────────────────────────────────────
  final _dateCtrl = TextEditingController();
  final _bookingNoCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mfgYearCtrl = TextEditingController();
  final _deliveryDateCtrl = TextEditingController();
  final _statusCtrl = TextEditingController();

  // ── Selected values ────────────────────────────────────────────────────────
  String? _selCustomer; // m1_2
  String? _selSC; // mcm_14
  String? _selTL; // mcm_14
  String? _selManager; // mcm_14
  String? _selModel; // sp_202
  String? _selVariant; // sp_20_2
  String? _selColour; // sp_142
  String? _selVin; // sp_55 / data
  String? _selLocation; // sp_152
  String? _selFscCode; // sp_71

  // ── Hidden / server-side fields ────────────────────────────────────────────
  String _bookingUnq = ''; // bO_18 (internal key, not display)

  // ── Role ──────────────────────────────────────────────────────────────────
  bool _isAdmin = false; // loaded in _init()

  // ── Lock rules ────────────────────────────────────────────────────────────
  // BOTH admin & non-admin — new entry:
  //   • Customer Name is ALWAYS unlocked (everyone can select a customer)
  //   • Before customer selected  → all other fields locked/empty
  //   • After customer selected   → all other fields fill with booking data,
  //                                 but stay read-only for EVERYONE
  //   • Admin only                → VIN + FSC become editable after customer selected
  //   • Admin only                → Save button is visible
  //
  // EDIT MODE — same: VIN + FSC editable for admin, rest read-only for everyone.

  /// True when the form is waiting for a customer to be picked.
  /// Applies to BOTH admin and non-admin on a new-entry form.
  bool get _isLocked =>
      (widget.va12 == null || widget.va12!.isEmpty) &&
      (_selCustomer == null || _selCustomer!.isEmpty);

  /// True when VIN + FSC should be editable.
  /// Only admin after a customer is already selected (or in edit mode).
  bool get _vinEnabled => _isAdmin && !_isLocked;
  void initState() {
    super.initState();
    _dateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _init();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _bookingNoCtrl.dispose();
    _contactCtrl.dispose();
    _addressCtrl.dispose();
    _mfgYearCtrl.dispose();
    _deliveryDateCtrl.dispose();
    _statusCtrl.dispose();
    super.dispose();
  }

  // ── Initialise: load dropdowns, then optionally load edit data ─────────────
  Future<void> _init() async {
    setState(() {
      _loadingDropdowns = true;
      _initError = null;
    });
    try {
      // Load admin flag first
      final adminFlag = await ApiService.isAdmin();
      if (!mounted) return;
      setState(() => _isAdmin = adminFlag);

      final dd = await ApiService.getVehicleAllocationDropdowns();
      if (!mounted) return;
      setState(() {
        _customers = dd['customers'] ?? [];
        _models = dd['models'] ?? [];
        _variants = dd['variants'] ?? [];
        _colours = dd['colours'] ?? [];
        _locations = dd['locations'] ?? [];
        _staff = dd['staff'] ?? [];
        _loadingDropdowns = false;
      });

      if (widget.va12 != null && widget.va12!.isNotEmpty) {
        await _loadEditData(widget.va12!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _loadingDropdowns = false;
      });
    }
  }

  // ── Load existing record for editing ──────────────────────────────────────
  Future<void> _loadEditData(String va12) async {
    setState(() => _loadingEdit = true);
    try {
      final result = await ApiService.getVehicleAllocationEdit(va12);
      if (!mounted || result == null) return;

      final d = result['data'] as Map<String, dynamic>;
      final vinList = result['vinList'] as List<Map<String, dynamic>>;

      // Merge vinList into _variants so the VIN dropdown works
      if (vinList.isNotEmpty) {
        // Replace VIN list with what came back from edit
        _vinDetails = vinList
            .map(
              (v) => <String, dynamic>{
                'sp_55': v['data']?.toString() ?? '',
                'sp_45': '',
                'sp_46': '',
                'sp_47': '',
                'sp_49': '',
                'sp_38': '',
                'sp_50': '',
                'sp_56': '',
                'ageing': '',
              },
            )
            .toList();
      }

      setState(() {
        _selCustomer = _safeVal(d['custunq']);
        _contactCtrl.text = d['contactno']?.toString() ?? '';
        _dateCtrl.text = _formatDateStr(d['date']?.toString());
        _bookingNoCtrl.text = d['receipt']?.toString() ?? '';
        _bookingUnq = d['receiptno']?.toString() ?? '';
        _addressCtrl.text = d['address']?.toString() ?? '';
        _selSC = _safeVal(d['scunq']);
        _selTL = _safeVal(d['TLunq']);
        _selManager = _safeVal(d['Managerunq']);
        _selModel = _safeVal(d['modelunq']);
        _selVariant = _safeVal(d['varunq']);
        _selColour = _safeVal(d['colorunq']);
        _selVin = _safeVal(d['vin']);
        _selFscCode = _safeVal(d['fsccode']);
        _selLocation = _safeVal(d['location']);
        _mfgYearCtrl.text = d['mfcyr']?.toString() ?? '';
        _deliveryDateCtrl.text = _formatDateStr(d['delivery_date']?.toString());
        _loadingEdit = false;
      });

      // Load VIN details grid for the selected combo
      if (_selModel != null && _selVariant != null && _selColour != null) {
        await _loadVinDetails();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingEdit = false);
      _showSnack('Failed to load record: $e', isError: true);
    }
  }

  // ── Customer selected: auto-fill all related fields ────────────────────────
  Future<void> _onCustomerChanged(String? custUnq) async {
    setState(() => _selCustomer = custUnq);
    if (custUnq == null || custUnq.isEmpty) return;

    try {
      final d = await ApiService.getVehicleAllocationCustomerDetails(custUnq);
      if (!mounted || d == null) return;
      setState(() {
        _contactCtrl.text = d['phone']?.toString() ?? '';
        _bookingNoCtrl.text = d['repno']?.toString() ?? '';
        _bookingUnq = d['bo_18']?.toString() ?? '';
        _addressCtrl.text = d['add1']?.toString() ?? '';
        _deliveryDateCtrl.text = _formatDateStr(d['bo_32']?.toString());
        _selSC = _safeVal(d['scunq']);
        _selTL = _safeVal(d['BO_21']);
        _selManager = _safeVal(d['BO_22']);
        _selModel = _safeVal(d['BO_26']);
        _selVariant = _safeVal(d['BO_27']);
        _selColour = _safeVal(d['BO_28']);
      });

      // Load VIN list for the auto-filled model/variant/colour
      if (_selModel != null && _selVariant != null && _selColour != null) {
        await _loadVinDetails();
        await _loadVinDropdown();
      }
    } catch (e) {
      _showSnack('Could not load customer details.', isError: true);
    }
  }

  // ── Model / Variant / Colour changed: reload VINs ─────────────────────────
  Future<void> _onModelVariantColourChanged() async {
    if (_selModel == null || _selVariant == null || _selColour == null) return;
    await Future.wait([_loadVinDetails(), _loadVinDropdown()]);
  }

  Future<void> _loadVinDropdown() async {
    if (_selModel == null || _selVariant == null || _selColour == null) return;
    try {
      final list = await ApiService.getVehicleAllocationVinList(
        model: _selModel!,
        variant: _selVariant!,
        colour: _selColour!,
      );
      if (!mounted) return;
      // Auto-select first VIN if available
      if (list.isNotEmpty && _selVin == null) {
        setState(() {
          _selVin = list.first['data']?.toString();
          _mfgYearCtrl.text = list.first['mfcyr']?.toString() ?? '';
          _selFscCode = list.first['fsccode']?.toString();
          _selLocation = list.first['location']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadVinDetails() async {
    if (_selModel == null || _selVariant == null || _selColour == null) return;
    setState(() => _loadingVin = true);
    try {
      final details = await ApiService.getVehicleAllocationVinDetails(
        model: _selModel!,
        variant: _selVariant!,
        colour: _selColour!,
      );
      if (!mounted) return;
      setState(() {
        _vinDetails = details;
        _loadingVin = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingVin = false);
    }
  }

  // ── VIN selected: fill mfg year / fsc code / location ─────────────────────
  void _onVinChanged(String? vin) {
    setState(() => _selVin = vin);
    if (vin == null) return;

    // Find it in the vin details grid
    final match = _vinDetails.firstWhere(
      (r) => r['sp_55']?.toString() == vin,
      orElse: () => {},
    );
    if (match.isNotEmpty) {
      setState(() {
        _mfgYearCtrl.text = match['sp_49']?.toString() ?? '';
        _selFscCode = match['sp_38']?.toString();
        _selLocation = match['sp_56']?.toString();
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _onSave() async {
    // Validation
    if (_selCustomer == null || _selCustomer!.isEmpty) {
      _showSnack('Please select a Customer.', isError: true);
      return;
    }
    if (_selVin == null || _selVin!.isEmpty) {
      _showSnack('Please select a VIN.', isError: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.saveVehicleAllocation({
        'VA_17': _dateCtrl.text,
        'VA_18': _bookingUnq,
        'VA_20': _selSC ?? '',
        'VA_21': _selTL ?? '',
        'VA_22': _selManager ?? '',
        'VA_23': _selCustomer ?? '',
        'VA_24': _addressCtrl.text,
        'VA_25': _contactCtrl.text,
        'VA_26': _selModel ?? '',
        'VA_27': _selVariant ?? '',
        'VA_28': _selColour ?? '',
        'VA_29': _selVin ?? '',
        'VA_30': _selLocation ?? '',
      });

      if (!mounted) return;
      _showSnack('Vehicle allocation saved successfully.');

      await ActivityService.logActivity(
        activityType: 'INSERT',
        activityName: 'Vehicle Allocation Save',
        screenName: 'VehicleAllocationFormScreen',
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatDateStr(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      if (raw.contains('T')) {
        final dt = DateTime.parse(raw);
        return DateFormat('dd/MM/yyyy').format(dt);
      }
      // already dd/MM/yyyy
      if (raw.contains('/')) return raw;
      // yyyy-MM-dd
      final parts = raw.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {}
    return raw;
  }

  /// Returns the value only if it exists in the relevant list, else null.
  /// Prevents DropdownButtonFormField "value not in items" assertion.
  String? _safeVal(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool _inList(List<Map<String, dynamic>> list, String keyField, String? val) {
    if (val == null) return false;
    return list.any((m) => m[keyField]?.toString() == val);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Date picker helper ────────────────────────────────────────────────────
  Future<void> _pickDate(TextEditingController ctrl) async {
    DateTime initial = DateTime.now();
    try {
      if (ctrl.text.isNotEmpty) {
        final parts = ctrl.text.split('/');
        if (parts.length == 3) {
          initial = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.va12 != null && widget.va12!.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(isDark, isEdit),
          if (_loadingDropdowns || _loadingEdit)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_initError != null)
            Expanded(child: _buildInitError())
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCustomerSection(isDark),
                    const SizedBox(height: 16),
                    _buildBasicInfoSection(isDark),
                    const SizedBox(height: 16),
                    _buildStaffSection(isDark),
                    const SizedBox(height: 16),
                    _buildVehicleSection(isDark),
                    const SizedBox(height: 16),
                    _buildVinDetailsGrid(isDark),
                    const SizedBox(height: 24),
                    _buildActionButtons(isDark, isEdit),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, bool isEdit) {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? 'Edit Vehicle Allocation'
                          : 'New Vehicle Allocation',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      isEdit
                          ? 'Update allocation details'
                          : 'Allocate a vehicle to a booking',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (!_loadingDropdowns)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _isAdmin ? 'Admin' : 'View Only',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Init error ────────────────────────────────────────────────────────────
  Widget _buildInitError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load form data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _initError ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _init,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2535) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A3A4A) : const Color(0xFFD1E3FF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0D3F8A).withValues(alpha: 0.4)
                  : const Color(0xFFEAF1FF),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _accent),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Field decoration ──────────────────────────────────────────────────────
  InputDecoration _fieldDecor(
    String label, {
    IconData? suffix,
    bool readOnly = false,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDisabled = readOnly || !enabled;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFF8A9BB0) : const Color(0xFF64748B),
      ),
      floatingLabelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? const Color(0xFF82B1FF) : _primary,
      ),
      filled: true,
      fillColor: isDisabled
          ? (isDark
                ? const Color(0xFF0F1923).withValues(alpha: 0.5)
                : const Color(0xFFF0F6FF))
          : (isDark ? const Color(0xFF0F1923) : Colors.white),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A3A4A) : const Color(0xFFD1E3FF),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF2A3A4A) : const Color(0xFFD1E3FF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E2535) : const Color(0xFFE8EFFF),
        ),
      ),
      suffixIcon: suffix != null
          ? Icon(suffix, size: 18, color: _accent)
          : null,
    );
  }

  // ── Dropdown builder ──────────────────────────────────────────────────────
  // ── Responsive searchable dropdown builder ────────────────────────────────
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String labelKey,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
    bool enabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cleanValue = value?.trim();

    final validItems = items.where((m) {
      final v = m[valueKey]?.toString().trim() ?? '';
      return v.isNotEmpty;
    }).toList();

    final selectedItem = validItems.cast<Map<String, dynamic>?>().firstWhere(
      (m) => m?[valueKey]?.toString().trim() == cleanValue,
      orElse: () => null,
    );

    final selectedText =
        selectedItem?[labelKey]?.toString().trim() ??
        selectedItem?[valueKey]?.toString().trim();

    return AbsorbPointer(
      absorbing: !enabled,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled
            ? () async {
                final selected = await _showSearchableDropdown(
                  title: isRequired ? '$label *' : label,
                  selectedValue: cleanValue,
                  items: validItems,
                  valueKey: valueKey,
                  labelKey: labelKey,
                  isDark: isDark,
                );

                if (selected != null) {
                  onChanged(selected);
                }
              }
            : null,
        child: InputDecorator(
          decoration: _fieldDecor(
            isRequired ? '$label *' : label,
            enabled: enabled,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedText?.isNotEmpty == true
                      ? selectedText!
                      : 'Select $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selectedText?.isNotEmpty == true
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: enabled
                    ? _accent
                    : (isDark
                          ? const Color(0xFF536579)
                          : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Searchable dropdown popup ─────────────────────────────────────────────
  Future<String?> _showSearchableDropdown({
    required String title,
    required String? selectedValue,
    required List<Map<String, dynamic>> items,
    required String valueKey,
    required String labelKey,
    required bool isDark,
  }) async {
    final searchController = TextEditingController();

    final screenSize = MediaQuery.of(context).size;

    // Responsive popup height:
    // Small screens  → around 45% of screen
    // Medium screens → around 50% of screen
    // Large screens  → maximum 420px
    final double popupHeight = (screenSize.height * 0.52)
        .clamp(260.0, 420.0)
        .toDouble();

    final double popupWidth = (screenSize.width - 32)
        .clamp(280.0, 600.0)
        .toDouble();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        List<Map<String, dynamic>> filteredItems = List.from(items);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void performSearch(String query) {
              final q = query.trim().toLowerCase();

              setDialogState(() {
                if (q.isEmpty) {
                  filteredItems = List.from(items);
                } else {
                  filteredItems = items.where((item) {
                    final name = item[labelKey]?.toString().toLowerCase() ?? '';

                    final value =
                        item[valueKey]?.toString().toLowerCase() ?? '';

                    return name.contains(q) || value.contains(q);
                  }).toList();
                }
              });
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: popupWidth,
                height: popupHeight,
                child: Column(
                  children: [
                    // ─────────────────────────────────────────────
                    // POPUP HEADER
                    // ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D3F8A) : _primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Navigator.pop(dialogContext);
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─────────────────────────────────────────────
                    // SEARCH BOX
                    // ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: performSearch,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search customer name...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFF8A9BB0)
                                : const Color(0xFF64748B),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: _accent,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    performSearch('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF0F1923)
                              : const Color(0xFFF8FAFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2A3A4A)
                                  : const Color(0xFFD1E3FF),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF2A3A4A)
                                  : const Color(0xFFD1E3FF),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: _accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),

                    // ─────────────────────────────────────────────
                    // RESULT COUNT
                    // ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 3,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${filteredItems.length} result${filteredItems.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? const Color(0xFF8A9BB0)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),

                    // ─────────────────────────────────────────────
                    // CUSTOMER LIST
                    // ─────────────────────────────────────────────
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_search_rounded,
                                    size: 42,
                                    color: isDark
                                        ? const Color(0xFF536579)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No customer found',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Scrollbar(
                              thumbVisibility: true,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: isDark
                                      ? const Color(0xFF2A3A4A)
                                      : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];

                                  final itemValue =
                                      item[valueKey]?.toString().trim() ?? '';

                                  final itemLabel =
                                      item[labelKey]?.toString().trim() ??
                                      itemValue;

                                  final isSelected = itemValue == selectedValue;

                                  return Material(
                                    color: isSelected
                                        ? (isDark
                                              ? const Color(0xFF173D70)
                                              : const Color(0xFFEAF2FF))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        Navigator.pop(dialogContext, itemValue);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 11,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? _accent.withValues(
                                                        alpha: 0.15,
                                                      )
                                                    : (isDark
                                                          ? const Color(
                                                              0xFF24364A,
                                                            )
                                                          : const Color(
                                                              0xFFF1F5F9,
                                                            )),
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: Icon(
                                                Icons.person_outline_rounded,
                                                size: 18,
                                                color: isSelected
                                                    ? _accent
                                                    : (isDark
                                                          ? const Color(
                                                              0xFF9DB8D8,
                                                            )
                                                          : const Color(
                                                              0xFF475569,
                                                            )),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                itemLabel,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  height: 1.25,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle_rounded,
                                                color: _accent,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
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
        );
      },
    );

    searchController.dispose();

    return result;
  }
  // ── Sections ──────────────────────────────────────────────────────────────

  Widget _buildCustomerSection(bool isDark) {
    return _sectionCard(
      title: 'Customer Information',
      icon: Icons.person_rounded,
      isDark: isDark,
      children: [
        // Customer Name — always editable for EVERYONE (both admin & non-admin)
        _buildDropdown(
          label: 'Customer Name',
          value: _selCustomer,
          items: _customers,
          valueKey: 'm1_2',
          labelKey: 'm1_7',
          onChanged: _onCustomerChanged,
          isRequired: true,
          enabled: true,
        ),
        const SizedBox(height: 12),
        // Address — always read-only (filled from booking after customer select)
        TextFormField(
          controller: _addressCtrl,
          readOnly: true,
          decoration: _fieldDecor('Address', readOnly: true, enabled: true),
          maxLines: 2,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(bool isDark) {
    return _sectionCard(
      title: 'Booking Details',
      icon: Icons.receipt_long_rounded,
      isDark: isDark,
      children: [
        Row(
          children: [
            Expanded(
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _dateCtrl,
                  readOnly: true, // always read-only
                  decoration: _fieldDecor(
                    'Date',
                    suffix: Icons.calendar_today_rounded,
                    enabled: false,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bookingNoCtrl,
                readOnly: true,
                decoration: _fieldDecor(
                  'Booking No',
                  readOnly: true,
                  enabled: true,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contactCtrl,
          readOnly: true,
          decoration: _fieldDecor('Contact No', readOnly: true, enabled: true),
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffSection(bool isDark) {
    return _sectionCard(
      title: 'Sales Team',
      icon: Icons.people_rounded,
      isDark: isDark,
      children: [
        _buildDropdown(
          label: 'Sale Consultant',
          value: _inList(_staff, 'mcm_14', _selSC) ? _selSC : null,
          items: _staff,
          valueKey: 'mcm_14',
          labelKey: 'mcm_15',
          onChanged: (v) => setState(() => _selSC = v),
          enabled: false, // always read-only
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Team Leader',
          value: _inList(_staff, 'mcm_14', _selTL) ? _selTL : null,
          items: _staff,
          valueKey: 'mcm_14',
          labelKey: 'mcm_15',
          onChanged: (v) => setState(() => _selTL = v),
          enabled: false,
        ),
        const SizedBox(height: 12),
        _buildDropdown(
          label: 'Manager',
          value: _inList(_staff, 'mcm_14', _selManager) ? _selManager : null,
          items: _staff,
          valueKey: 'mcm_14',
          labelKey: 'mcm_15',
          onChanged: (v) => setState(() => _selManager = v),
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildVehicleSection(bool isDark) {
    // Build VIN list from vinDetails — only populated after customer selected
    final vinItems = _vinDetails
        .map(
          (r) => {
            'data': r['sp_55']?.toString() ?? '',
            'label': r['sp_55']?.toString() ?? '',
          },
        )
        .where((r) => r['data']!.isNotEmpty)
        .toList();

    // VIN is editable only for admin when form is unblocked
    final vinEnabled = _vinEnabled;

    return _sectionCard(
      title: 'Vehicle Details',
      icon: Icons.directions_car_rounded,
      isDark: isDark,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Model',
                value: _inList(_models, 'sp_202', _selModel) ? _selModel : null,
                items: _models,
                valueKey: 'sp_202',
                labelKey: 'sp_207',
                enabled: false, // always locked — filled from booking
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                label: 'Variant',
                value: _inList(_variants, 'sp_20_2', _selVariant)
                    ? _selVariant
                    : null,
                items: _variants,
                valueKey: 'sp_20_2',
                labelKey: 'sp_20_3',
                enabled: false,
                onChanged: (_) {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Colour',
                value: _inList(_colours, 'sp_142', _selColour)
                    ? _selColour
                    : null,
                items: _colours,
                valueKey: 'sp_142',
                labelKey: 'sp_147',
                enabled: false,
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // VIN — editable for admin after customer selection.
              // Read-only for non-admin, but still displayed in bold.
              child: AbsorbPointer(
                absorbing: !vinEnabled,
                child: DropdownButtonFormField<String>(
                  value: vinItems.any((m) => m['data'] == _selVin)
                      ? _selVin
                      : null,
                  decoration: _fieldDecor('VIN *', enabled: true),
                  isExpanded: true,
                  iconEnabledColor: _accent,
                  hint: Text(
                    vinEnabled ? 'Select VIN' : (_selVin ?? '-'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  items: vinItems.isNotEmpty
                      ? vinItems.map((m) {
                          return DropdownMenuItem<String>(
                            value: m['data'],
                            child: Text(
                              m['label']!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          );
                        }).toList()
                      : null,
                  onChanged: _onVinChanged,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _mfgYearCtrl,
                readOnly: true,
                decoration: _fieldDecor(
                  'Mfg. Year',
                  readOnly: true,
                  enabled: true,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // FSC Code — editable for admin (after customer), locked for non-admin
            Expanded(
              child: vinEnabled
                  ? _buildDropdown(
                      label: 'FSC Code',
                      value: _selFscCode,
                      items: _vinDetails
                          .where(
                            (r) => (r['sp_38']?.toString() ?? '').isNotEmpty,
                          )
                          .map(
                            (r) => {
                              'sp_71': r['sp_38']?.toString() ?? '',
                              'label': r['sp_38']?.toString() ?? '',
                            },
                          )
                          .toSet()
                          .toList(),
                      valueKey: 'sp_71',
                      labelKey: 'label',
                      enabled: vinEnabled,
                      onChanged: (v) => setState(() => _selFscCode = v),
                    )
                  : TextFormField(
                      readOnly: true,
                      controller: TextEditingController(
                        text: _selFscCode ?? '',
                      ),
                      decoration: _fieldDecor('FSC Code', readOnly: true),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Location',
                value: _inList(_locations, 'sp_152', _selLocation)
                    ? _selLocation
                    : null,
                items: _locations,
                valueKey: 'sp_152',
                labelKey: 'sp_157',
                enabled: false,
                onChanged: (_) {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _deliveryDateCtrl,
                  readOnly: true,
                  decoration: _fieldDecor(
                    'Delivery Date',
                    suffix: Icons.calendar_today_rounded,
                    readOnly: true,
                    enabled: true,
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── VIN Details Grid (mirrors the WebDataGrid in the ASPX) ────────────────
  Widget _buildVinDetailsGrid(bool isDark) {
    return _sectionCard(
      title: 'Available Vehicles (Stock)',
      icon: Icons.table_chart_rounded,
      isDark: isDark,
      children: [
        if (_loadingVin)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_vinDetails.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isLocked
                    ? 'Select a customer to see available stock.'
                    : 'No stock available for the selected combination.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF8A9BB0)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildVinTable(isDark),
          ),
      ],
    );
  }

  Widget _buildVinTable(bool isDark) {
    const headers = [
      'Model',
      'Variant',
      'Colour',
      'VIN',
      'PDI',
      'FSC Code',
      'Year',
      'Location',
      'Ageing',
    ];
    const keys = [
      'sp_45',
      'sp_46',
      'sp_47',
      'sp_55',
      'sp_50',
      'sp_38',
      'sp_49',
      'sp_56',
      'ageing',
    ];
    const widths = [100.0, 100.0, 110.0, 180.0, 70.0, 100.0, 60.0, 120.0, 70.0];

    final headerBg = isDark ? const Color(0xFF0D3F8A) : const Color(0xFF0D3F8A);
    final evenBg = isDark ? const Color(0xFF1A2535) : Colors.white;
    final oddBg = isDark ? const Color(0xFF1E2E42) : const Color(0xFFEAF1FF);
    final textColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final borderColor = isDark
        ? const Color(0xFF2A3A4A)
        : const Color(0xFFC7D2FE);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Table(
        border: TableBorder.all(color: borderColor, width: 0.5),
        columnWidths: {
          for (int i = 0; i < widths.length; i++)
            i: FixedColumnWidth(widths[i]),
        },
        children: [
          // Header row
          TableRow(
            decoration: BoxDecoration(color: headerBg),
            children: headers
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      h,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          // Data rows
          ..._vinDetails.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            final isSelected = row['sp_55']?.toString() == _selVin;
            final rowBg = isSelected
                ? _accent.withValues(alpha: 0.18)
                : (i.isEven ? evenBg : oddBg);

            return TableRow(
              decoration: BoxDecoration(color: rowBg),
              children: keys
                  .map(
                    (k) => GestureDetector(
                      onTap: () => _onVinChanged(row['sp_55']?.toString()),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 7,
                        ),
                        child: Text(
                          row[k]?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? _accent : textColor,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────
  Widget _buildActionButtons(bool isDark, bool isEdit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Close'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : _primary,
              side: BorderSide(
                color: isDark
                    ? const Color(0xFF2A3A4A)
                    : const Color(0xFFD1E3FF),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        // Save button — admin only
        if (_isAdmin) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: (_saving || _isLocked) ? null : _onSave,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _saving
                    ? 'Saving...'
                    : _isLocked
                    ? 'Select a Customer First'
                    : (isEdit ? 'Update' : 'Save Allocation'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? const Color(0xFF1A2535)
                    : const Color(0xFFD1E3FF),
                disabledForegroundColor: isDark
                    ? const Color(0xFF4A5A6A)
                    : const Color(0xFF8A9BB0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
