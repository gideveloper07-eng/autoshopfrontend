import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/activity_service.dart';
import '../../services/api_service.dart';
import 'challan_grid_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// New Challan Form
// Layout exactly matches frm_challan.aspx column order from screenshots
// ─────────────────────────────────────────────────────────────────────────────
class ChallanFormScreen extends StatefulWidget {
  /// Pass [editSp462] to open an existing challan for editing.
  final String? editSp462;
  const ChallanFormScreen({super.key, this.editSp462});
  @override
  State<ChallanFormScreen> createState() => _ChallanFormScreenState();
}

class _ChallanFormScreenState extends State<ChallanFormScreen>
    with SingleTickerProviderStateMixin {
  // ── Theme colors ──────────────────────────────────────────────────────────
  static const Color _accent = Color(0xFF0D5BB5); // MyAutoShop accent blue
  static const Color _primary = Color(0xFF0A1B32);
  static const Color _secondary = Color(
    0xFF0D55A7,
  ); // MyAutoShop secondary blue
  static const Color _border = Color(0xFFD7E3F4);

  // ── Form & scroll ─────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();
  bool _loading = true;
  bool _saving = false;
  String? _initError;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  // ── Edit mode ─────────────────────────────────────────────────────────────
  bool get _isEditing =>
      widget.editSp462 != null && widget.editSp462!.isNotEmpty;
  String _editUnq = '0'; // holds the real sp_462 guid when editing

  // ── Receipt grid ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _receiptRows = [];
  double _receiptTotal = 0;
  double _receiptFinanceAmt = 0;
  double _receiptCustAmt = 0;
  bool _loadingReceipts = false;

  // ── City and Area lists ───────────────────────────────────────────────────
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _areas = [];

  // ── Challan type & date ───────────────────────────────────────────────────
  String _challanType = 'Customer Challan';
  DateTime _challanDate = DateTime.now();
  int _challanNo = 0;
  static const _challanTypes = [
    'Customer Challan',
    'CSD Challan',
    'Inter Delear Challan',
    'Stock to Branch',
    'Used Car',
  ];

  // ── Dropdown data ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _models = [];
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _colors = [];
  List<Map<String, dynamic>> _vins = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _rtoCities = [];
  List<Map<String, dynamic>> _hpnList = [];
  List<Map<String, dynamic>> _insuranceCos = [];

  // ── Selected IDs ──────────────────────────────────────────────────────────
  String? _custId, _modelId, _variantId, _colorId, _vinNo;
  String? _stateId, _branchId, _rtoCityId, _hpnId, _gstUnq;
  String? _cityId; // selected city from Add City popup
  String? _areaId; // selected area from Add Area popup
  String _cityName = '';
  String _areaName = '';
  bool _loadingVar = false, _loadingCol = false, _loadingVin = false;

  // ── Left column controllers ───────────────────────────────────────────────
  final _locationCtrl = TextEditingController(text: 'SHOWROOM');
  final _panCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _engineCtrl = TextEditingController();

  // ── Middle column controllers ─────────────────────────────────────────────
  final _mobileCtrl = TextEditingController();
  final _nomineeCtrl = TextEditingController();
  final _scCtrl = TextEditingController();

  // ── Right column controllers ──────────────────────────────────────────────
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _relation = 'CHOOSE RELATIONSHIP';
  final _tlCtrl = TextEditingController();
  final _managerCtrl = TextEditingController();
  String _title = 'MR';
  final _fatherCtrl = TextEditingController();

  // ── Finance ───────────────────────────────────────────────────────────────
  String _finType = 'In House';
  final _hypCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _netDisCtrl = TextEditingController(text: '0.00');
  final _loanAmtCtrl = TextEditingController(text: '0.00');

  // ── HPN (Hypothecation) parent + child branch ─────────────────────────────
  String? _hpnParentId; // sp_605 — mhpn (parent unq)
  String? _hpnChildId; // sp_523 — hypothecation child branch
  List<Map<String, dynamic>> _hpnBranches = [];

  // ── Discounts ─────────────────────────────────────────────────────────────
  String _corpYn = 'No', _corpGiven = 'No';
  String _exchYn = 'No', _exchGiven = 'No';
  String _dealYn = 'No', _dealGiven = 'No';
  String _loyYn = 'No', _loyGiven = 'No';
  final _corpValCtrl = TextEditingController(text: '0.00');
  final _exchValCtrl = TextEditingController(text: '0.00');
  final _dealValCtrl = TextEditingController(text: '0.00');
  final _loyValCtrl = TextEditingController(text: '0.00');
  final _exShowCtrl = TextEditingController(text: '0.00');
  final _schemesCtrl = TextEditingController(text: '0.00');
  final _subTotalCtrl = TextEditingController(text: '0.00');

  // ── Insurance ─────────────────────────────────────────────────────────────
  String _insType = 'In House';
  bool _epAdd = false, _rtiAdd = false, _cmAdd = false;
  final _insDisCtrl = TextEditingController();
  final _insExShowCtrl = TextEditingController(text: '0.00');
  final _cessCtrl = TextEditingController(text: '0.00');
  final _idvCtrl = TextEditingController(text: '0.00');
  final _idvAmtCtrl = TextEditingController(text: '0.00');
  final _afterIdvCtrl = TextEditingController(text: '0.00');
  final _insAmtCtrl = TextEditingController(text: '0.00');
  final _insPerCtrl = TextEditingController(text: '0.00');
  final _finalInsCtrl = TextEditingController(text: '0.00');
  final _disAmtCtrl = TextEditingController(text: '0.00');
  final _afterDisCtrl = TextEditingController(text: '0.00');
  final _cngPerCtrl = TextEditingController(text: '0.00');
  final _cngAmtCtrl = TextEditingController(text: '0.00');
  final _paCoverCtrl = TextEditingController(text: '0.00');
  final _paAmtCtrl = TextEditingController(text: '0.00');
  final _zdCtrl = TextEditingController(text: '0.00');
  final _zdAmtCtrl = TextEditingController(text: '0.00');
  final _epCtrl = TextEditingController(text: '0.00');
  final _epAmtCtrl = TextEditingController(text: '0.00');
  final _thirdPartyCtrl = TextEditingController(text: '0.00');
  final _pbCtrl = TextEditingController(text: '0.00');
  final _kpCtrl = TextEditingController(text: '0.00');
  final _kpAmtCtrl = TextEditingController(text: '0.00');
  final _paidDrvCtrl = TextEditingController(text: '0.00');
  final _afterPdCtrl = TextEditingController(text: '0.00');
  final _rtiCtrl = TextEditingController(text: '0.00');
  final _rtiAmtCtrl = TextEditingController(text: '0.00');
  final _cmCtrl = TextEditingController(text: '0.00');
  final _cmAmtCtrl = TextEditingController(text: '0.00');
  final _cgstCtrl = TextEditingController(text: '0.00');
  final _sgstCtrl = TextEditingController(text: '0.00');
  final _gstAmtCtrl = TextEditingController(text: '0.00');
  final _addLessCtrl = TextEditingController(text: '0.00');
  final _ncbCtrl = TextEditingController(text: '0.00');
  final _insAmtFinalCtrl = TextEditingController(text: '0.00');

  // ── RTO ───────────────────────────────────────────────────────────────────
  String _rtoFrom = 'In House';
  bool _scrappage = false;
  final _rtoExShowCtrl = TextEditingController(text: '0.00');
  final _rtoRateCtrl = TextEditingController(text: '0.00');
  final _rtoSurCtrl = TextEditingController(text: '0.00');
  final _greenTaxCtrl = TextEditingController(text: '0.00');
  final _regFeeCtrl = TextEditingController(text: '0.00');
  final _hpnRtoCtrl = TextEditingController(text: '0.00');
  final _dupCtrl = TextEditingController(text: '0.00');
  final _smartCtrl = TextEditingController(text: '0.00');
  final _otherRtoCtrl = TextEditingController(text: '0.00');
  final _bhPerCtrl = TextEditingController(text: '0.00');
  final _bhYearCtrl = TextEditingController();
  final _rtoTempCtrl = TextEditingController(text: '0.00');
  final _rtoAmtCtrl = TextEditingController(text: '0.00');

  // ── Others ────────────────────────────────────────────────────────────────
  final _oth1Ctrl = TextEditingController();
  final _oth2Ctrl = TextEditingController();
  final _oth3Ctrl = TextEditingController();
  final _amt1Ctrl = TextEditingController(text: '0.00');
  final _amt2Ctrl = TextEditingController(text: '0.00');
  final _amt3Ctrl = TextEditingController(text: '0.00');

  // ── Bottom amounts ────────────────────────────────────────────────────────
  final _workshopInvNo = TextEditingController();
  final _workshopInvAmt = TextEditingController(text: '0.00');
  final _trcCtrl = TextEditingController(text: '0.00');
  final _compAccCtrl = TextEditingController(text: '0.00');
  final _ownAccCtrl = TextEditingController(text: '0.00');
  final _accAmtCtrl = TextEditingController(text: '0.00');
  final _warrantyCtrl = TextEditingController(text: '0.00');
  final _warrantyYrCtrl = TextEditingController();
  final _rsaCtrl = TextEditingController(text: '0.00');
  String _sotType = 'SOT';
  final _sotAmtCtrl = TextEditingController(text: '0.00');
  final _fastTagCtrl = TextEditingController(text: '0.00');
  final _tcsCtrl = TextEditingController(text: '0.00');
  final _totalCtrl = TextEditingController(text: '0.00');

  // ── Receipt / balance totals ───────────────────────────────────────────────
  final _hpnReceivedCtrl = TextEditingController(text: '0.00');
  final _hpnBalanceCtrl = TextEditingController(text: '0.00');
  final _customerReceivedCtrl = TextEditingController(text: '0.00');
  final _customerBalanceCtrl = TextEditingController(text: '0.00');
  final _receivedCtrl = TextEditingController(text: '0.00');
  final _balanceCtrl = TextEditingController(text: '0.00');

  // ── Remarks ───────────────────────────────────────────────────────────────
  final _remarkCtrl = TextEditingController();
  final _appRemarkCtrl = TextEditingController();
  final _rejRemarkCtrl = TextEditingController();

  Future<String?> _getLoggedInUserBranch() async {
    try {
      final token = await ApiService.getToken();

      if (token == null || token.isEmpty) {
        debugPrint('❌ JWT token not found');
        return null;
      }

      final parts = token.split('.');

      if (parts.length != 3) {
        debugPrint('❌ Invalid JWT token');
        return null;
      }

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final decoded = jsonDecode(payload);

      debugPrint('========== JWT PAYLOAD ==========');
      debugPrint(decoded.toString());
      debugPrint('=================================');

      // IMPORTANT:
      // Backend creates JWT using branchUnq
      final branchUnq = decoded['branchUnq'] ?? decoded['branchunq'];

      debugPrint('JWT branchUnq = $branchUnq');

      if (branchUnq == null || branchUnq.toString().isEmpty) {
        debugPrint('❌ branchUnq not found in JWT');
        return null;
      }

      return branchUnq.toString();
    } catch (e) {
      debugPrint('❌ Error reading branch from JWT: $e');
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    ActivityService.logActivity(
      activityType: 'SCREEN',
      activityName: 'ChallanFormScreen',
      screenName: 'ChallanFormScreen',
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _loadDropdowns();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _scrollCtrl.dispose();
    for (final c in [
      _locationCtrl,
      _panCtrl,
      _gstinCtrl,
      _engineCtrl,
      _mobileCtrl,
      _nomineeCtrl,
      _scCtrl,
      _addressCtrl,
      _emailCtrl,
      _aadharCtrl,
      _ageCtrl,
      _tlCtrl,
      _managerCtrl,
      _fatherCtrl,
      _hypCtrl,
      _branchNameCtrl,
      _netDisCtrl,
      _loanAmtCtrl,
      _corpValCtrl,
      _exchValCtrl,
      _dealValCtrl,
      _loyValCtrl,
      _exShowCtrl,
      _schemesCtrl,
      _subTotalCtrl,
      _insDisCtrl,
      _insExShowCtrl,
      _cessCtrl,
      _idvCtrl,
      _idvAmtCtrl,
      _afterIdvCtrl,
      _insAmtCtrl,
      _insPerCtrl,
      _finalInsCtrl,
      _disAmtCtrl,
      _afterDisCtrl,
      _cngPerCtrl,
      _cngAmtCtrl,
      _paCoverCtrl,
      _paAmtCtrl,
      _zdCtrl,
      _zdAmtCtrl,
      _epCtrl,
      _epAmtCtrl,
      _thirdPartyCtrl,
      _pbCtrl,
      _kpCtrl,
      _kpAmtCtrl,
      _paidDrvCtrl,
      _afterPdCtrl,
      _rtiCtrl,
      _rtiAmtCtrl,
      _cmCtrl,
      _cmAmtCtrl,
      _cgstCtrl,
      _sgstCtrl,
      _gstAmtCtrl,
      _addLessCtrl,
      _ncbCtrl,
      _insAmtFinalCtrl,
      _rtoExShowCtrl,
      _rtoRateCtrl,
      _rtoSurCtrl,
      _greenTaxCtrl,
      _regFeeCtrl,
      _hpnRtoCtrl,
      _dupCtrl,
      _smartCtrl,
      _otherRtoCtrl,
      _bhPerCtrl,
      _bhYearCtrl,
      _rtoTempCtrl,
      _rtoAmtCtrl,
      _oth1Ctrl,
      _oth2Ctrl,
      _oth3Ctrl,
      _amt1Ctrl,
      _amt2Ctrl,
      _amt3Ctrl,
      _workshopInvNo,
      _workshopInvAmt,
      _trcCtrl,
      _compAccCtrl,
      _ownAccCtrl,
      _accAmtCtrl,
      _warrantyCtrl,
      _warrantyYrCtrl,
      _rsaCtrl,
      _sotAmtCtrl,
      _fastTagCtrl,
      _tcsCtrl,
      _totalCtrl,
      _hpnReceivedCtrl,
      _hpnBalanceCtrl,
      _customerReceivedCtrl,
      _customerBalanceCtrl,
      _receivedCtrl,
      _balanceCtrl,
      _remarkCtrl,
      _appRemarkCtrl,
      _rejRemarkCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Load dropdowns ────────────────────────────────────────────────────────
  Future<void> _loadDropdowns() async {
    setState(() => _loading = true);

    try {
      // ============================================================
      // GET LOGGED-IN USER BRANCH FROM JWT
      // ============================================================

      final loggedInBranchId = await _getLoggedInUserBranch();

      debugPrint('======================================');
      debugPrint('Logged-in Branch ID: $loggedInBranchId');
      debugPrint('======================================');

      // ============================================================
      // LOAD ALL DROPDOWNS
      // ============================================================

      final r = await Future.wait([
        ApiService.getChallanNewCustomers(),
        ApiService.getChallanModels(),
        ApiService.getChallanRtoCities(),
        ApiService.getChallanHpnList(),
        ApiService.getChallanStates(),
        ApiService.getChallanBranches(),
        ApiService.getChallanInsuranceCompanies(),
        ApiService.getChallanNextNo().then(
          (v) => [
            {'n': v},
          ],
        ),
        ApiService.getChallanCities(),
        ApiService.getChallanAreas(),
      ]);

      if (!mounted) return;

      final branches = r[5] as List<Map<String, dynamic>>;

      // ============================================================
      // CHECK WHETHER JWT BRANCH EXISTS IN BRANCH LIST
      // ============================================================

      String? selectedBranchId;

      if (loggedInBranchId != null) {
        final branchExists = branches.any(
          (branch) => branch['data']?.toString() == loggedInBranchId,
        );

        debugPrint('JWT branch exists in branch list: $branchExists');

        if (branchExists) {
          selectedBranchId = loggedInBranchId;
        }
      }

      // ============================================================
      // DEBUG BRANCH LIST
      // ============================================================

      debugPrint('========== BRANCH LIST ==========');

      for (final branch in branches) {
        debugPrint(
          'Branch ID: ${branch['data']} | '
          'Branch Name: ${branch['value']}',
        );
      }

      debugPrint('Selected Branch ID: $selectedBranchId');

      debugPrint('=================================');

      // ============================================================
      // SET DATA
      // ============================================================

      setState(() {
        _customers = r[0] as List<Map<String, dynamic>>;
        _models = r[1] as List<Map<String, dynamic>>;
        _rtoCities = r[2] as List<Map<String, dynamic>>;
        _hpnList = r[3] as List<Map<String, dynamic>>;
        _states = r[4] as List<Map<String, dynamic>>;
        _branches = branches;
        _insuranceCos = r[6] as List<Map<String, dynamic>>;

        _challanNo = ((r[7] as List).first as Map)['n'] as int? ?? 1;

        // IMPORTANT
        _cities = r[8] as List<Map<String, dynamic>>;
        _areas = r[9] as List<Map<String, dynamic>>;

        _branchId = selectedBranchId;

        _loading = false;
      });

      debugPrint('FINAL _branchId = $_branchId');

      _animCtrl.forward();
    } catch (e) {
      debugPrint('❌ _loadDropdowns ERROR: $e');

      if (!mounted) return;

      setState(() {
        _initError = e.toString();
        _loading = false;
      });
    }
  }

  /// Convert challan type display string → API type key
  String _challanTypeToApiType(String type) {
    switch (type) {
      case 'CSD Challan':
        return 'csd';
      case 'Inter Delear Challan':
        return 'dealer';
      case 'Stock to Branch':
        return 'stb';
      case 'Used Car':
        return 'usedcar';
      default:
        return 'booking';
    }
  }

  /// Reload customers when challan type changes
  Future<void> _reloadCustomersByType(String type) async {
    setState(() {
      _customers = [];
      _custId = null;
    });
    try {
      final list = await ApiService.getChallanCustomersByType(
        _challanTypeToApiType(type),
      );
      if (!mounted) return;
      setState(() => _customers = list);
    } catch (e) {
      print('_reloadCustomersByType ERROR: $e');
    }
  }

  /// Load existing challan data for edit mode
  Future<void> _loadEditData() async {
    final data = await ApiService.loadChallanForEdit(widget.editSp462!);
    if (data == null || !mounted) return;
    _populateFormFromData(data);
  }

  /// Populate all controllers from an Edit API response
  void _populateFormFromData(Map<String, dynamic> d) {
    setState(() {
      _editUnq = d['unq']?.toString() ?? widget.editSp462 ?? '0';

      // ── dates ──
      final dateStr = d['date']?.toString() ?? d['cdate']?.toString() ?? '';
      if (dateStr.isNotEmpty) {
        try {
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            _challanDate = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}
      }
      _challanNo = int.tryParse(d['challanno']?.toString() ?? '') ?? _challanNo;
      _challanType = d['challantype']?.toString().isNotEmpty == true
          ? d['challantype'].toString()
          : _challanType;

      // ── customer/vehicle ──
      _custId = d['custname']?.toString();
      _modelId = d['model']?.toString();
      _variantId = d['variant']?.toString();
      _colorId = d['color']?.toString();
      _vinNo = d['vinno']?.toString();
      _stateId = d['state_list']?.toString();
      _branchId = d['branchid']?.toString();

      // ── text fields ──
      _title = d['title']?.toString().isNotEmpty == true
          ? d['title'].toString()
          : 'MR';
      _addressCtrl.text = d['address']?.toString() ?? '';
      _mobileCtrl.text = d['mobileno']?.toString() ?? '';
      _emailCtrl.text =
          d['fathername']?.toString() ?? ''; // fathername = email in SP alias
      _fatherCtrl.text = d['fathername']?.toString() ?? '';
      _aadharCtrl.text = d['aadharcard']?.toString() ?? '';
      _panCtrl.text = d['panno']?.toString() ?? '';
      _gstinCtrl.text = d['gstin']?.toString() ?? '';
      _nomineeCtrl.text = d['nomineename']?.toString() ?? '';
      _ageCtrl.text = d['age']?.toString() ?? '';
      _relation = d['relation']?.toString().isNotEmpty == true
          ? d['relation'].toString()
          : 'CHOOSE RELATIONSHIP';
      _engineCtrl.text = d['engineno']?.toString() ?? '';
      _scCtrl.text = d['scunq']?.toString() ?? '';
      _tlCtrl.text = d['tlunq']?.toString() ?? '';
      _managerCtrl.text = d['managunq']?.toString() ?? '';

      // ── finance ──
      final finTypeRaw = d['financetype']?.toString() ?? '';
      _finType = finTypeRaw == 'in'
          ? 'In House'
          : finTypeRaw == 'out'
          ? 'Out House'
          : finTypeRaw == 'Cash'
          ? 'Cash'
          : 'In House';
      _hpnParentId = d['hpnp']?.toString();
      _hpnChildId = d['hypothecation']?.toString();
      _loanAmtCtrl.text = _f(d['bankamt']);
      _netDisCtrl.text = _f(d['bankamt']);

      // ── discounts ──
      _corpYn = (d['Corporateyn'] ?? d['corporateyn'] ?? 'out') == 'in'
          ? 'Yes'
          : 'No';
      _corpValCtrl.text = _f(d['Corporateamount'] ?? d['corporateamount']);
      _corpGiven = (d['Corporategiven'] ?? d['corporategiven'] ?? '') == 'Yes'
          ? 'Yes'
          : 'No';
      _exchYn = (d['Exchangeyn'] ?? d['exchangeyn'] ?? 'out') == 'In'
          ? 'Yes'
          : 'No';
      _exchValCtrl.text = _f(d['Exchangeamount'] ?? d['exchangeamount']);
      _exchGiven = (d['Exchangegiven'] ?? d['exchangegiven'] ?? '') == 'Yes'
          ? 'Yes'
          : 'No';
      _dealYn = (d['dealeryn'] ?? 'out') == 'in' ? 'Yes' : 'No';
      _dealValCtrl.text = _f(d['dealeramount']);
      _dealGiven = (d['dealergiven'] ?? '') == 'Yes' ? 'Yes' : 'No';
      _loyYn = (d['Loyalityyn'] ?? d['loyalityyn'] ?? 'out') == 'In'
          ? 'Yes'
          : 'No';
      _loyValCtrl.text = _f(d['Loyalityamount'] ?? d['loyalityamount']);
      _loyGiven = (d['Loyalitygiven'] ?? d['loyalitygiven'] ?? '') == 'Yes'
          ? 'Yes'
          : 'No';
      _exShowCtrl.text = _f(d['ExshowRoomPrice'] ?? d['exshowroomprice']);
      _schemesCtrl.text = _f(d['lessofallencashmentschemne']);
      _subTotalCtrl.text = _f(d['subtotal']);

      // ── insurance ──
      final insTypeRaw = d['instype']?.toString() ?? '';
      _insType = insTypeRaw == 'in' ? 'In House' : 'Out House';
      _insExShowCtrl.text = _f(d['insshowroom']);
      _cessCtrl.text = _f(d['CESS'] ?? d['cess']);
      _idvCtrl.text = _f(d['Idv'] ?? d['idv']);
      _idvAmtCtrl.text = _f(d['IdvAmount'] ?? d['idvamount']);
      _afterIdvCtrl.text = _f(d['afteridvamt']);
      _insAmtCtrl.text = _f(d['InsperAmount'] ?? d['insperamount']);
      _insPerCtrl.text = _f(
        d['InsurancePercentage'] ?? d['insurancepercentage'],
      );
      _finalInsCtrl.text = _f(d['InsuranceAmount'] ?? d['insuranceamount']);
      _insDisCtrl.text = _f(d['DiscountPrecentage'] ?? d['discountprecentage']);
      _disAmtCtrl.text = _f(d['DiscountAmount'] ?? d['discountamount']);
      _afterDisCtrl.text = _f(d['afterdisamtamt']);
      _thirdPartyCtrl.text = _f(d['ThirdParty'] ?? d['thirdparty']);
      _paCoverCtrl.text = _f(d['PACover'] ?? d['pacover']);
      _paAmtCtrl.text = _f(d['pacoveramt']);
      _zdCtrl.text = _f(d['ZD'] ?? d['zd']);
      _zdAmtCtrl.text = _f(d['zdamt']);
      _epCtrl.text = _f(d['ep']);
      _epAmtCtrl.text = _f(d['epamt']);
      _pbCtrl.text = _f(d['PB'] ?? d['pb']);
      _kpCtrl.text = _f(d['KP'] ?? d['kp']);
      _paidDrvCtrl.text = _f(d['PaidDriver'] ?? d['paiddriver']);
      _afterPdCtrl.text = _f(d['amtafterpaiddriver']);
      _rtiCtrl.text = _f(d['rti']);
      _rtiAmtCtrl.text = _f(d['rtiamt']);
      _cmCtrl.text = _f(d['cm']);
      _cmAmtCtrl.text = _f(d['cmamt']);
      _gstUnq = d['gstunq']?.toString();
      _cgstCtrl.text = _f(d['cgst']);
      _sgstCtrl.text = _f(d['sgst']);
      _gstAmtCtrl.text = _f(d['GSTAmount'] ?? d['gstamount']);
      _addLessCtrl.text = _f(d['addless']);
      _ncbCtrl.text = _f(d['NCB'] ?? d['ncb']);
      _cngPerCtrl.text = _f(d['cngp']);
      _cngAmtCtrl.text = _f(d['cngamt']);

      // ── RTO ──
      final rtoFromRaw = d['rtofrom']?.toString() ?? '';
      _rtoFrom = rtoFromRaw == 'in'
          ? 'In House'
          : rtoFromRaw == 'out'
          ? 'Out House'
          : rtoFromRaw == 'bh'
          ? 'BH'
          : 'In House';
      _scrappage = (d['scrapper']?.toString() ?? '0') != '0';
      _rtoCityId = d['rtounq']?.toString();
      _rtoExShowCtrl.text = _f(d['rtoexshow']);
      _rtoRateCtrl.text = _f(d['RTORate'] ?? d['rtorate']);
      _rtoSurCtrl.text = _f(d['RTOTaxSurcharge'] ?? d['rtotaxsurcharge']);
      _greenTaxCtrl.text = _f(d['GreenTax'] ?? d['greentax']);
      _regFeeCtrl.text = _f(d['RegFee'] ?? d['regfee']);
      _hpnRtoCtrl.text = _f(d['HPN'] ?? d['hpn']);
      _dupCtrl.text = _f(d['Duplicate'] ?? d['duplicate']);
      _smartCtrl.text = _f(d['SmartCard'] ?? d['smartcard']);
      _otherRtoCtrl.text = _f(d['Other'] ?? d['other']);
      _rtoTempCtrl.text = _f(d['RTO TEMP'] ?? d['rto temp']);
      _bhPerCtrl.text = _f(d['bhperc']);
      _bhYearCtrl.text = d['bhyear']?.toString() ?? '';
      _rtoAmtCtrl.text = _f(d['RTOAmount'] ?? d['rtoamount']);

      // ── others ──
      _oth1Ctrl.text = d['OTHER1']?.toString() ?? '';
      _amt1Ctrl.text = _f(d['AMOUNT1']);
      _oth2Ctrl.text = d['OTHER2']?.toString() ?? '';
      _amt2Ctrl.text = _f(d['AMOUNT2']);
      _oth3Ctrl.text = d['OTHER3']?.toString() ?? '';
      _amt3Ctrl.text = _f(d['AMOUNT3']);

      // ── final ──
      _workshopInvNo.text = d['WORKSHOPINVOICENO']?.toString() ?? '';
      _workshopInvAmt.text = _f(d['WORKSHOPINVOICEAMOUNT']);
      _trcCtrl.text = _f(d['trc']);
      _compAccCtrl.text = _f(d['Accessories'] ?? d['accessories']);
      _ownAccCtrl.text = _f(d['ownaccss']);
      _warrantyCtrl.text = _f(d['WarrantyAmount'] ?? d['warrantyamount']);
      _warrantyYrCtrl.text = d['WarrantyYear']?.toString() ?? '';
      _fastTagCtrl.text = _f(d['fasttag']);
      _tcsCtrl.text = _f(d['tcs']);
      _totalCtrl.text = _f(d['netamount']);

      // ── remarks ──
      _remarkCtrl.text = d['REMARK']?.toString() ?? '';
      _appRemarkCtrl.text = d['appremark']?.toString() ?? '';
      _rejRemarkCtrl.text = d['rejectremark']?.toString() ?? '';
    });

    // Load receipt grid, variant details, HPN branches in parallel
    if (_custId != null && _custId!.isNotEmpty) {
      _loadReceiptGrid(_custId!);
    }
    if (_variantId != null && _variantId!.isNotEmpty) {
      _loadVariantsColorsVinsForEdit();
    }
    if (_hpnParentId != null && _hpnParentId!.isNotEmpty) {
      _loadHpnBranches(_hpnParentId!);
    }
    _recalculateAspNet();
  }

  /// After loading edit data, also populate variant/color/vin cascades
  Future<void> _loadVariantsColorsVinsForEdit() async {
    if (_modelId == null) return;
    try {
      final variants = await ApiService.getChallanVariants(_modelId!);
      if (!mounted) return;
      setState(() => _variants = variants);

      if (_variantId != null) {
        final colors = await ApiService.getChallanColors(_variantId!);
        if (!mounted) return;
        setState(() => _colors = colors);

        if (_colorId != null) {
          final vins = await ApiService.getChallanVins(
            variantId: _variantId!,
            colorId: _colorId!,
            challanType: _challanType,
          );
          if (!mounted) return;
          setState(() => _vins = vins);
        }
      }
    } catch (e) {
      print('_loadVariantsColorsVinsForEdit ERROR: $e');
    }
  }

  /// Load receipt rows for a customer
  Future<void> _loadReceiptGrid(String customerId) async {
    if (customerId.isEmpty) return;
    setState(() => _loadingReceipts = true);
    try {
      final result = await ApiService.getChallanReceiptGrid(customerId);
      if (!mounted) return;
      final rows = result['rows'] as List? ?? [];
      setState(() {
        _receiptRows = rows
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _receiptTotal =
            double.tryParse(result['rcTotal']?['rcamt']?.toString() ?? '0') ??
            0;
        _receiptFinanceAmt =
            double.tryParse(result['fiTotal']?['fiamt']?.toString() ?? '0') ??
            0;
        _receiptCustAmt =
            double.tryParse(result['custTotal']?['camt']?.toString() ?? '0') ??
            0;
        _loadingReceipts = false;
      });
      // Pre-fill received amounts from actual receipt totals
      setState(() {
        _receivedCtrl.text = _receiptTotal.toStringAsFixed(2);
        _recalculateAspNet();
      });
    } catch (e) {
      if (mounted) setState(() => _loadingReceipts = false);
      print('_loadReceiptGrid ERROR: $e');
    }
  }

  /// Load HPN child branches
  Future<void> _loadHpnBranches(String hpnId) async {
    try {
      final branches = await ApiService.getChallanHpnBranches(hpnId);
      if (!mounted) return;
      setState(() => _hpnBranches = branches);
    } catch (e) {
      print('_loadHpnBranches ERROR: $e');
    }
  }

  // ── Cascade dropdowns ─────────────────────────────────────────────────────
  Future<void> _onModel(String? id) async {
    setState(() {
      _modelId = id;
      _variantId = null;
      _colorId = null;
      _vinNo = null;
      _variants = [];
      _colors = [];
      _vins = [];
    });
    _recalculateAspNet();
    if (id == null) return;
    setState(() => _loadingVar = true);
    try {
      final v = await ApiService.getChallanVariants(id);
      if (!mounted) return;
      setState(() => _variants = v);
    } finally {
      if (mounted) setState(() => _loadingVar = false);
    }
  }

  Future<void> _onVariant(String? id) async {
    setState(() {
      _variantId = id;
      _colorId = null;
      _vinNo = null;
      _colors = [];
      _vins = [];
    });
    _recalculateAspNet();
    if (id == null) return;
    setState(() => _loadingCol = true);
    try {
      final c = await ApiService.getChallanColors(id);
      if (mounted) setState(() => _colors = c);
    } finally {
      if (mounted) setState(() => _loadingCol = false);
    }
    await _fetchVariantDetails(id);
  }

  Future<void> _onColor(String? id) async {
    setState(() {
      _colorId = id;
      _vinNo = null;
      _vins = [];
    });
    _recalculateAspNet();
    if (id == null || _variantId == null) return;
    setState(() => _loadingVin = true);
    try {
      final v = await ApiService.getChallanVins(
        variantId: _variantId!,
        colorId: id,
        challanType: _challanType,
      );
      if (mounted) setState(() => _vins = v);
    } finally {
      if (mounted) setState(() => _loadingVin = false);
    }
  }

  void _onVinSelected(String? id) {
    setState(() => _vinNo = id);
    if (id != null) {
      final row = _vins.firstWhere(
        (e) => (e['data'] ?? e['value'] ?? e['id']).toString() == id,
        orElse: () => <String, dynamic>{},
      );
      if (row.isNotEmpty) {
        final engine = row['engine'] ?? row['engineno'] ?? row['engineNo'];
        if (engine != null && engine.toString().isNotEmpty) {
          _engineCtrl.text = engine.toString();
        }
      }
      _fetchRetailSupport(id);
    }
    _recalculateAspNet();
  }

  Future<void> _fetchRetailSupport(String vinNo) async {
    if (_variantId == null || _modelId == null) return;
    try {
      final dateStr =
          '${_challanDate.day.toString().padLeft(2, '0')}/${_challanDate.month.toString().padLeft(2, '0')}/${_challanDate.year}';
      final data = await ApiService.getChallanRetailSupport(
        variantId: _variantId!,
        modelId: _modelId!,
        vinNo: vinNo,
        challanDate: dateStr,
      );
      if (!mounted || data.isEmpty) return;
      setState(() {
        final corp = double.tryParse(data['corporate']?.toString() ?? '0') ?? 0;
        final exch = double.tryParse(data['exchange']?.toString() ?? '0') ?? 0;
        final loy = double.tryParse(data['loyality']?.toString() ?? '0') ?? 0;
        final deal = double.tryParse(data['dealer']?.toString() ?? '0') ?? 0;
        if (corp > 0) _corpValCtrl.text = corp.toStringAsFixed(2);
        if (exch > 0) _exchValCtrl.text = exch.toStringAsFixed(2);
        if (loy > 0) _loyValCtrl.text = loy.toStringAsFixed(2);
        if (deal > 0) _dealValCtrl.text = deal.toStringAsFixed(2);
      });
      _recalculateAspNet();
    } catch (e) {
      print('_fetchRetailSupport ERROR: $e');
    }
  }

  Future<void> _fetchVariantDetails(String varId) async {
    final d = await ApiService.getChallanVariantDetails(
      variantId: varId,
      challanDate: DateFormat('dd/MM/yyyy').format(_challanDate),
      stateId: _stateId ?? '',
    );
    if (d == null || !mounted) return;
    setState(() {
      _exShowCtrl.text = _f(d['exshowroom']);
      _fastTagCtrl.text = _f(d['fasttag']);
      _rtoExShowCtrl.text = _f(d['rtoexshow'] ?? d['exshowroom']);
      _rtoRateCtrl.text = _f(d['rtorate']);
      _rtoSurCtrl.text = _f(d['rtosurcharge']);
      _greenTaxCtrl.text = _f(d['greentax']);
      _regFeeCtrl.text = _f(d['regfee']);
      _hpnRtoCtrl.text = _f(d['hpn']);
      _dupCtrl.text = _f(d['duplicate']);
      _smartCtrl.text = _f(d['smartcard']);
      _otherRtoCtrl.text = _f(d['other']);
      _thirdPartyCtrl.text = _f(d['thirdparty']);
      _paCoverCtrl.text = _f(d['pacover']);
      _cngPerCtrl.text = _f(d['cng'] ?? '0');
      _bhPerCtrl.text = _f(d['bhperc'] ?? '0');
      if (d['gst'] != null) _gstUnq = d['gst'].toString();
      if (d['idv'] != null) _idvCtrl.text = _f(d['idv']);
      if (d['insurancepercent'] != null) {
        _insPerCtrl.text = _f(d['insurancepercent']);
      }
      if (d['insuranceexshowroom'] != null) {
        _insExShowCtrl.text = _f(d['insuranceexshowroom']);
      }
    });
    _recalculateAspNet();
  }

  void _onCustomerSelected(String? id) {
    setState(() => _custId = id);
    if (id == null) return;
    final c = _customers.firstWhere(
      (e) => (e['data'] ?? e['value'] ?? e['id']).toString() == id,
      orElse: () => <String, dynamic>{},
    );
    if (c.isEmpty) {
      _loadReceiptGrid(id);
      return;
    }
    setState(() {
      _addressCtrl.text = c['address']?.toString() ?? '';
      _mobileCtrl.text = c['mobile']?.toString() ?? '';
      _panCtrl.text = c['panno']?.toString() ?? c['pan']?.toString() ?? '';
      _aadharCtrl.text = c['aadhar']?.toString() ?? '';
      _gstinCtrl.text = c['gstin']?.toString() ?? '';
      _fatherCtrl.text = c['fathername']?.toString() ?? '';
      _emailCtrl.text = c['email']?.toString() ?? '';
      _ageCtrl.text = c['age']?.toString() ?? '';
      _nomineeCtrl.text = c['nominee']?.toString() ?? '';
      _scCtrl.text = c['scname']?.toString() ?? '';
      _tlCtrl.text = c['tl']?.toString() ?? '';
      _managerCtrl.text = c['manager']?.toString() ?? '';

      _title = (c['title']?.toString().isNotEmpty == true)
          ? c['title'].toString()
          : 'MR';
    });
    _loadReceiptGrid(id);
    _recalculateAspNet();
  }

  void _onStateSelected(String? id) {
    setState(() => _stateId = id);
    if (_variantId != null) _fetchVariantDetails(_variantId!);
    _recalculateAspNet();
  }

  void _onBranchSelected(String? id) {
    setState(() => _branchId = id);
    if (id != null) {
      _fetchVariantDetails(_variantId ?? '');
      _fetchOwnRtoCity(id);
    }
    _recalculateAspNet();
  }

  Future<void> _fetchOwnRtoCity(String branchId) async {
    if (branchId.isEmpty) return;
    try {
      final row = await ApiService.getChallanOwnRto(branchId);
      if (row == null || !mounted) return;
      setState(() {
        final rtoId = row['data']?.toString() ?? row['sp_332']?.toString();
        if (rtoId != null && rtoId.isNotEmpty) _rtoCityId = rtoId;
        _rtoRateCtrl.text = _f(row['rrate'] ?? row['sp_339']);
        _rtoSurCtrl.text = _f(row['rtax'] ?? row['sp_340']);
        _greenTaxCtrl.text = _f(row['rgreen'] ?? row['sp_341']);
        _regFeeCtrl.text = _f(row['rreg'] ?? row['sp_342']);
        _hpnRtoCtrl.text = _f(row['rhpn'] ?? row['sp_343']);
        _dupCtrl.text = _f(row['rduplicate'] ?? row['sp_344']);
        _smartCtrl.text = _f(row['rsmartcard'] ?? row['sp_345']);
        _otherRtoCtrl.text = _f(row['rother'] ?? row['sp_346']);
        _trcCtrl.text = _f(row['trc'] ?? row['sp_347']);
      });
      _recalculateAspNet();
    } catch (e) {
      print('_fetchOwnRtoCity ERROR: $e');
    }
  }

  void _onChallanTypeSelected(String? value) {
    if (value == null) return;
    setState(() => _challanType = value);
    _reloadCustomersByType(value);
    _recalculateAspNet();
  }

  void _onRtoCitySelected(String? id) {
    setState(() => _rtoCityId = id);
    // The RTO master lookup is wired in ApiService in the next layer.
    // Keep the selected master ID here and recalculate immediately.
    _recalculateAspNet();
  }

  String _f(dynamic v) =>
      (double.tryParse(v?.toString().replaceAll(',', '') ?? '0') ?? 0.0)
          .toStringAsFixed(2);

  double _d(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0.0;

  void _set(TextEditingController c, double value, {int decimals = 2}) {
    final text = value.isFinite ? value.toStringAsFixed(decimals) : '0.00';
    if (c.text != text) c.text = text;
  }

  // Mirrors the client-side ASP.NET cal() flow. API/master values are filled
  // by the selection handlers; this method only performs deterministic math.
  void _recalculateAspNet() {
    if (!mounted) return;

    final exShow = _d(_exShowCtrl);
    final schemes = _d(_schemesCtrl);
    final subtotal = exShow - schemes;
    _set(_subTotalCtrl, subtotal);

    // TCS: ASP.NET applies it when the applicable subtotal exceeds 10 lakh.
    // The percentage comes from the master/API layer; until it is supplied,
    // preserve an explicitly entered TCS value.
    if (subtotal <= 1000000) _set(_tcsCtrl, 0);

    // RTO calculation from Jchallan.js.
    var rtoExShow = _d(_rtoExShowCtrl);
    if (rtoExShow <= 0) {
      rtoExShow = exShow;
      _set(_rtoExShowCtrl, rtoExShow);
    }

    final stateName = _states
        .where((e) => (e['data'] ?? e['id']).toString() == _stateId)
        .map((e) => (e['value'] ?? e['name'] ?? '').toString().toUpperCase())
        .firstWhere((e) => e.isNotEmpty, orElse: () => '');

    final specialRtoState =
        stateName == 'JHARKHAND' ||
        stateName == 'BIHAR' ||
        stateName == 'PUNJAB';
    final remainder = rtoExShow % 1000;
    var rtamt = specialRtoState
        ? rtoExShow
        : (remainder >= 1 ? (rtoExShow - remainder + 1000) : rtoExShow);

    var rtoAmount = 0.0;
    if (_rtoFrom == 'BH') {
      // BH master contains additional year/multiple factors. The API layer
      // will populate BH-specific fields; use the available BH rate/year here.
      final bhRate = _d(_bhPerCtrl);
      final bhYear = _d(_bhYearCtrl);
      rtoAmount = bhYear > 0 ? rtamt * bhRate / 100 * bhYear : 0.0;
      _set(_rtoRateCtrl, 0);
      _set(_rtoSurCtrl, 0);
      _set(_greenTaxCtrl, 0);
      _set(_hpnRtoCtrl, 0);
      _set(_dupCtrl, 0);
      _set(_smartCtrl, 0);
      _set(_otherRtoCtrl, 0);
    } else if (_rtoFrom == 'Out House') {
      rtoAmount = 0.0;
    } else {
      var taxableRto = rtamt;
      if (_scrappage) {
        // Scrappage percentage is supplied by the master/API in the ASP.NET
        // implementation. Do not invent a percentage on the client.
        taxableRto = rtamt;
      }
      final rto = taxableRto * _d(_rtoRateCtrl) / 100;
      final surcharge = rto * _d(_rtoSurCtrl) / 100;
      rtoAmount =
          rto +
          surcharge +
          _d(_greenTaxCtrl) +
          _d(_regFeeCtrl) +
          _d(_hpnRtoCtrl) +
          _d(_dupCtrl) +
          _d(_smartCtrl) +
          _d(_otherRtoCtrl) +
          _d(_rtoTempCtrl);
    }
    _set(_rtoAmtCtrl, rtoAmount);

    // Insurance calculation from Jchallan.js.
    if (_insType == 'Out House') {
      for (final c in [
        _cessCtrl,
        _idvAmtCtrl,
        _afterIdvCtrl,
        _insAmtCtrl,
        _insPerCtrl,
        _disAmtCtrl,
        _afterDisCtrl,
        _thirdPartyCtrl,
        _paAmtCtrl,
        _zdAmtCtrl,
        _epAmtCtrl,
        _kpAmtCtrl,
        _afterPdCtrl,
        _rtiAmtCtrl,
        _cmAmtCtrl,
        _cgstCtrl,
        _sgstCtrl,
        _gstAmtCtrl,
        _insAmtFinalCtrl,
        _finalInsCtrl,
      ]) {
        _set(c, 0);
      }
    } else {
      final insExShow = _d(_insExShowCtrl) == 0 ? subtotal : _d(_insExShowCtrl);
      _set(_insExShowCtrl, insExShow);
      final cess = _d(_cessCtrl);
      final cessAmount = insExShow * cess / 100;
      final cessSubtotal = insExShow + cessAmount;
      final idvPct = _d(_idvCtrl);
      final idvAmount = cessSubtotal * idvPct / 100;
      final afterIdv = cessSubtotal - idvAmount;
      final odRate = _d(_insPerCtrl);
      final odAmount = afterIdv * odRate / 100;
      final discountPct = _d(_insDisCtrl);
      final discountAmount = odAmount * discountPct / 100;
      final afterDiscount = odAmount - discountAmount;
      final cngAmount = afterDiscount * _d(_cngPerCtrl) / 100;

      _set(_idvAmtCtrl, idvAmount);
      _set(_afterIdvCtrl, afterIdv, decimals: 0);
      _set(_insAmtCtrl, odAmount, decimals: 0);
      _set(_disAmtCtrl, discountAmount, decimals: 0);
      _set(_afterDisCtrl, afterDiscount, decimals: 0);
      _set(_cngAmtCtrl, cngAmount);

      final thirdParty = afterDiscount + _d(_thirdPartyCtrl) + _d(_paCoverCtrl);
      final zdpbkb = afterIdv * _d(_zdCtrl) / 100;
      final epAmount = afterIdv * _d(_epCtrl) / 100;
      final rtiAmount = afterIdv * _d(_rtiCtrl) / 100;
      final cmAmount = afterIdv * _d(_cmCtrl) / 100;
      final afterZd = zdpbkb + epAmount + _d(_pbCtrl) + _d(_kpCtrl);
      final beforeGst =
          afterDiscount +
          _d(_thirdPartyCtrl) +
          _d(_paCoverCtrl) +
          afterZd +
          _d(_paidDrvCtrl) +
          rtiAmount +
          cmAmount +
          cngAmount;
      final gstRate = double.tryParse(_gstUnq ?? '') ?? 0.0;
      final cgstRate = gstRate / 2;
      final sgstRate = gstRate / 2;
      final cgstAmount = beforeGst * cgstRate / 100;
      final sgstAmount = beforeGst * sgstRate / 100;
      final gstAmount = cgstAmount + sgstAmount;
      final finalInsurance =
          beforeGst + gstAmount - _d(_ncbCtrl) + _d(_addLessCtrl);

      _set(_paAmtCtrl, _d(_paCoverCtrl));
      _set(_epAmtCtrl, epAmount);
      _set(_zdAmtCtrl, zdpbkb);
      _set(_rtiAmtCtrl, rtiAmount);
      _set(_cmAmtCtrl, cmAmount);
      _set(_afterPdCtrl, _d(_paidDrvCtrl));
      _set(_cgstCtrl, cgstAmount);
      _set(_sgstCtrl, sgstAmount);
      _set(_gstAmtCtrl, gstAmount, decimals: 0);
      _set(_insAmtFinalCtrl, beforeGst);
      _set(_finalInsCtrl, finalInsurance, decimals: 0);
      _set(_thirdPartyCtrl, thirdParty, decimals: 0);
    }

    // ASP.NET final challan amount (sp_521).
    final total =
        _d(_fastTagCtrl) +
        _d(_tcsCtrl) +
        _d(_trcCtrl) +
        _d(_compAccCtrl) +
        _d(_ownAccCtrl) +
        _d(_warrantyCtrl) +
        _d(_rtoAmtCtrl) +
        _d(_finalInsCtrl) +
        _d(_subTotalCtrl) +
        _d(_amt1Ctrl) +
        _d(_amt2Ctrl) +
        _d(_amt3Ctrl) +
        _d(_workshopInvAmt);
    _set(_totalCtrl, total, decimals: 0);

    final received = _d(_receivedCtrl);
    _set(_balanceCtrl, total - received);
    _set(
      _customerBalanceCtrl,
      total - _d(_loanAmtCtrl) - _d(_customerReceivedCtrl),
    );
    _set(_hpnBalanceCtrl, _d(_hpnRtoCtrl) - _d(_hpnReceivedCtrl));
  }

  double get _rtoTotal => _d(_rtoAmtCtrl);

  double get _grandTotal => _d(_totalCtrl);

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _challanDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (c, ch) => Theme(
        data: Theme.of(
          c,
        ).copyWith(colorScheme: ColorScheme.light(primary: _accent)),
        child: ch!,
      ),
    );
    if (p != null) {
      setState(() => _challanDate = p);
      if (_variantId != null) _fetchVariantDetails(_variantId!);
      await _fetchTcsForDate(p);
      _recalculateAspNet();
    }
  }

  Future<void> _fetchTcsForDate(DateTime date) async {
    try {
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      final tcs = await ApiService.getChallanTcsData(dateStr);
      if (!mounted) return;
      setState(() {
        if (tcs > 0) {
          _tcsCtrl.text = tcs.toStringAsFixed(2);
        }
      });
    } catch (e) {
      print('_fetchTcsForDate ERROR: $e');
    }
  }

  // ── Add City popup (+ button) ─────────────────────────────────────────────
  void _openCitySheet() {
    // State pre-filled from what user already selected on the form
    String? selStateId = _stateId;
    final cityCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A8BBF),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add City',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          cityCtrl.dispose();
                          Navigator.pop(ctx);
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),

                // ── Body ──────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // State — dropdown, auto-filled from form
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 56,
                            child: Text(
                              'State *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child:
                                  DropdownButtonFormField<String>(
                                value: selStateId,
                                isDense: true,
                                isExpanded: true,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF333333),
                                ),
                                decoration:
                                    const InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(3)),
                                    borderSide: BorderSide(
                                        color:
                                            Color(0xFFCCCCCC)),
                                  ),
                                  enabledBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(3)),
                                    borderSide: BorderSide(
                                        color:
                                            Color(0xFFCCCCCC)),
                                  ),
                                  focusedBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(3)),
                                    borderSide: BorderSide(
                                        color: Color(0xFF1A8BBF),
                                        width: 1.5),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<
                                      String>(
                                    value: null,
                                    child: Text('-- Select --',
                                        style: TextStyle(
                                            fontSize: 13)),
                                  ),
                                  ..._states.map(
                                    (s) =>
                                        DropdownMenuItem<String>(
                                      value: s['data']
                                          ?.toString(),
                                      child: Text(
                                        s['value']
                                                ?.toString() ??
                                            '',
                                        style: const TextStyle(
                                            fontSize: 13),
                                        overflow:
                                            TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setDlg(() => selStateId = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // City — plain text input (user types new city)
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 56,
                            child: Text(
                              'City *',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                controller: cityCtrl,
                                autofocus: true,
                                style:
                                    const TextStyle(fontSize: 13),
                                decoration:
                                    const InputDecoration(
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(3)),
                                    borderSide: BorderSide(
                                        color:
                                            Color(0xFFCCCCCC)),
                                  ),
                                  enabledBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(3)),
                                    borderSide: BorderSide(
                                        color:
                                            Color(0xFFCCCCCC)),
                                  ),
                                  focusedBorder:
                                      OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(
                                            Radius.circular(3)),
                                    borderSide: BorderSide(
                                        color: Color(0xFF1A8BBF),
                                        width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // ── Footer ────────────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (selStateId == null) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                          const SnackBar(
                                    content: Text(
                                        'Please select a State'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ));
                                  return;
                                }
                                if (cityCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                          const SnackBar(
                                    content: Text(
                                        'Please enter City name'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ));
                                  return;
                                }

                                // Resolve state display name from ID
                                final stateRow = _states.firstWhere(
                                  (s) =>
                                      s['data']?.toString() ==
                                      selStateId,
                                  orElse: () => {},
                                );
                                final stateName =
                                    (stateRow['value'] ??
                                            selStateId ??
                                            '')
                                        .toString();
                                final cityName = cityCtrl.text
                                    .trim()
                                    .toUpperCase();

                                setDlg(() => saving = true);
                                try {
                                  // Insert via A_SP_FOR_ACCOUNTMASTER
                                  // and get back the refreshed city list
                                  final refreshed =
                                      await ApiService
                                          .saveChallanCity(
                                    cityName: cityName,
                                    stateName: stateName,
                                  );

                                  // Find the new city entry
                                  final newCity =
                                      refreshed.firstWhere(
                                    (c) =>
                                        (c['value'] ??
                                                c['sp_578'] ??
                                                '')
                                            .toString()
                                            .toUpperCase() ==
                                        cityName,
                                    orElse: () =>
                                        refreshed.isNotEmpty
                                            ? refreshed.last
                                            : {},
                                  );

                                  if (!mounted) return;
                                  setState(() {
                                    _cities = refreshed;
                                    _stateId = selStateId;
                                    if (newCity.isNotEmpty) {
                                      _cityId = (newCity['data'] ??
                                              newCity['sp_572'])
                                          ?.toString();
                                      _cityName = (newCity[
                                                  'value'] ??
                                              newCity['sp_578'] ??
                                              cityName)
                                          .toString();
                                    }
                                    _areaId = null;
                                    _areaName = '';
                                  });

                                  cityCtrl.dispose();
                                  if (ctx.mounted)
                                    Navigator.pop(ctx);
                                } catch (e) {
                                  setDlg(() => saving = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor:
                                        const Color(0xFFE53935),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF337AB7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 9),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(3)),
                          textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Text('Save'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: saving
                            ? null
                            : () {
                                cityCtrl.dispose();
                                Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9534F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 9),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(3)),
                          textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Add Area popup (+ button) ─────────────────────────────────────────────
  void _openAreaSheet() {
    final areaCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 40,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A8BBF),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Add Area',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          if (saving) return;
                          areaCtrl.dispose();
                          Navigator.pop(ctx);
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 56,
                        child: Text(
                          'Area *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: TextField(
                            controller: areaCtrl,
                            autofocus: true,
                            enabled: !saving,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(3)),
                                borderSide:
                                    BorderSide(color: Color(0xFFCCCCCC)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(3)),
                                borderSide:
                                    BorderSide(color: Color(0xFFCCCCCC)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(3)),
                                borderSide: BorderSide(
                                  color: Color(0xFF1A8BBF),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Footer ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final name = areaCtrl.text.trim();
                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content:
                                        Text('Please fill out Area'),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ));
                                  return;
                                }

                                setDlg(() => saving = true);
                                try {
                                  // Insert via A_SP_FOR_AreaMaster
                                  // and get back the refreshed area list
                                  final refreshed =
                                      await ApiService.saveChallanArea(
                                    areaName: name.toUpperCase(),
                                  );

                                  // Find the newly inserted area
                                  final newArea = refreshed.firstWhere(
                                    (a) =>
                                        (a['value'] ??
                                                a['sp_217'] ??
                                                '')
                                            .toString()
                                            .toUpperCase() ==
                                        name.toUpperCase(),
                                    orElse: () => refreshed.isNotEmpty
                                        ? refreshed.last
                                        : {},
                                  );

                                  if (!mounted) return;
                                  setState(() {
                                    _areas = refreshed;
                                    if (newArea.isNotEmpty) {
                                      _areaId = (newArea['data'] ??
                                              newArea['sp_212'])
                                          ?.toString();
                                      _areaName = (newArea['value'] ??
                                              newArea['sp_217'] ??
                                              name)
                                          .toString();
                                    } else {
                                      // fallback: just show typed name
                                      _areaId = null;
                                      _areaName = name;
                                    }
                                  });

                                  areaCtrl.dispose();
                                  if (ctx.mounted) Navigator.pop(ctx);
                                } catch (e) {
                                  setDlg(() => saving = false);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Error: ${e.toString().replaceAll('Exception: ', '')}'),
                                    backgroundColor:
                                        const Color(0xFFE53935),
                                    behavior:
                                        SnackBarBehavior.floating,
                                  ));
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF337AB7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: saving
                            ? null
                            : () {
                                areaCtrl.dispose();
                                Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9534F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Add Account Dialog (RTO City + button) ────────────────────────────────
  void _showAddAccountDialog() {
    final rtoCityCtrl = TextEditingController();
    final mainCityCtrl = TextEditingController();

    final chargeNames = <String>[
      'Rto Rate',
      'Rto Tax Surcharge',
      'Green Tax',
      'Reg Fee',
      'HPN',
      'Duplicate',
      'Smart Card',
      'Other',
      'TRC',
    ];

    final selectedCharges = <String, bool>{
      for (final name in chargeNames) name: false,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final allSelected = selectedCharges.values.every((v) => v);

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D55A7),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Add Account',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            rtoCityCtrl.dispose();
                            mainCityCtrl.dispose();
                            Navigator.pop(ctx);
                          },
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF0A1B32),
                            size: 27,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: Column(
                      children: [
                        _accountTextRow('Rto City :', rtoCityCtrl),
                        const SizedBox(height: 10),
                        _accountTextRow('Main City :', mainCityCtrl),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'RTO Charges Applicable',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Text(
                              'Check All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: allSelected,
                                visualDensity: VisualDensity.compact,
                                onChanged: (value) {
                                  setDlg(() {
                                    for (final name in chargeNames) {
                                      selectedCharges[name] = value ?? false;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        ...chargeNames.map(
                          (name) => SizedBox(
                            height: 25,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: selectedCharges[name],
                                    visualDensity: VisualDensity.compact,
                                    onChanged: (value) {
                                      setDlg(() {
                                        selectedCharges[name] = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    color: const Color(0xFFF2F2F2),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final rtoCity = rtoCityCtrl.text.trim();
                            final mainCity = mainCityCtrl.text.trim();

                            if (rtoCity.isEmpty || mainCity.isEmpty) {
                              _snack(
                                'Please fill out Rto City and Main City',
                                isError: true,
                              );
                              return;
                            }

                            setState(() {
                              _cityName = mainCity;

                              // Try to select an existing RTO city returned by
                              // the API. If no exact match exists, keep the
                              // typed value for the current challan.
                              final match = _rtoCities.firstWhere((e) {
                                final value = (e['data'] ?? e['value'] ?? '')
                                    .toString()
                                    .trim();
                                final label =
                                    (e['name'] ?? e['text'] ?? e['label'] ?? '')
                                        .toString()
                                        .trim();
                                return value == rtoCity ||
                                    label.toLowerCase() ==
                                        rtoCity.toLowerCase();
                              }, orElse: () => <String, dynamic>{});

                              if (match.isNotEmpty) {
                                _rtoCityId =
                                    (match['data'] ??
                                            match['value'] ??
                                            match['id'])
                                        ?.toString();
                              }
                            });

                            rtoCityCtrl.dispose();
                            mainCityCtrl.dispose();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1675D1),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFF1675D1)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        ElevatedButton(
                          onPressed: () {
                            rtoCityCtrl.dispose();
                            mainCityCtrl.dispose();
                            Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 9,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _accountTextRow(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 140,
          height: 31,
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFFCCCCCC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFFCCCCCC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFF1675D1)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dlgDec() => InputDecoration(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(color: _primary, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    isDense: true,
  );

  // ── Save / Update ─────────────────────────────────────────────────────────
  Future<void> _save() async {
    _recalculateAspNet();
    if (!_formKey.currentState!.validate()) return;
    if (_custId == null) {
      _snack('Please select a customer', isError: true);
      return;
    }
    if (_vinNo == null && !_isEditing) {
      _snack('Please select a VIN', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'prefix': 'rh_',
        'pageno': _stateId ?? '',
        'sp_462': _isEditing ? _editUnq : '0',
        'sp_463': '',
        'sp_464': '',
        'sp_467': DateFormat('dd/MM/yyyy').format(_challanDate),
        'sp_468': _challanNo.toString(),
        'sp_469': _custId,
        'sp_470': _modelId,
        'sp_471': _variantId,
        'sp_472': _colorId,
        'sp_473': _vinNo,
        'sp_558': _challanType,
        'sp_562': '',
        'sp_594': _branchId ?? '',
        'sp_610': _stateId ?? '',
        'sp_538': _title,
        'sp_524': _addressCtrl.text,
        'sp_526': _mobileCtrl.text,
        'sp_525': _emailCtrl.text,
        'sp_527': _aadharCtrl.text,
        'sp_528': _panCtrl.text,
        'sp_532': _gstinCtrl.text,
        'sp_550': _scCtrl.text,
        'sp_551': _tlCtrl.text,
        'sp_552': _managerCtrl.text,
        'sp_535': _engineCtrl.text,
        'sp_529': _nomineeCtrl.text,
        'sp_530': _ageCtrl.text,
        'sp_531': _relation,
        'sp_547': _finType == 'Cash'
            ? 'Cash'
            : (_finType == 'In House' ? 'in' : 'out'),
        'sp_523': _hpnChildId ?? _hypCtrl.text,
        'sp_605': _hpnParentId ?? '',
        'sp_536': _branchNameCtrl.text,
        'sp_537': _loanAmtCtrl.text,
        'sp_561': _loanAmtCtrl.text,
        'sp_483': _corpYn == 'Yes' ? 'in' : 'out',
        'sp_484': _corpValCtrl.text,
        'sp_485': _corpGiven,
        'sp_486': _exchYn == 'Yes' ? 'In' : 'out',
        'sp_487': _exchValCtrl.text,
        'sp_488': _exchGiven,
        'sp_611': _dealYn == 'Yes' ? 'in' : 'out',
        'sp_612': _dealValCtrl.text,
        'sp_613': _dealGiven,
        'sp_489': _loyYn == 'Yes' ? 'In' : 'out',
        'sp_490': _loyValCtrl.text,
        'sp_491': _loyGiven,
        'sp_482': _exShowCtrl.text,
        'sp_522': _schemesCtrl.text,
        'sp_503': _subTotalCtrl.text,
        'sp_548': _insType == 'In House' ? 'in' : 'out',
        'sp_520': _finalInsCtrl.text,
        'sp_502': _cessCtrl.text,
        'sp_505': _idvCtrl.text,
        'sp_506': _idvAmtCtrl.text,
        'sp_507': _insPerCtrl.text,
        'sp_508': _insAmtCtrl.text,
        'sp_510': _disAmtCtrl.text,
        'sp_511': _thirdPartyCtrl.text,
        'sp_512': _paCoverCtrl.text,
        'sp_513': _zdCtrl.text,
        'sp_554': _zdAmtCtrl.text,
        'sp_553': _epCtrl.text,
        'sp_555': _epAmtCtrl.text,
        'sp_514': _pbCtrl.text,
        'sp_515': _kpCtrl.text,
        'sp_516': _paidDrvCtrl.text,
        'sp_517': _afterPdCtrl.text,
        'sp_600': _rtiCtrl.text,
        'sp_601': _rtiAmtCtrl.text,
        'sp_602': _cmCtrl.text,
        'sp_603': _cmAmtCtrl.text,
        'sp_556': _sgstCtrl.text,
        'sp_557': _cgstCtrl.text,
        'sp_518': _gstUnq ?? '',
        'sp_519': _gstAmtCtrl.text,
        'sp_539': _afterIdvCtrl.text,
        'sp_634': _cngPerCtrl.text,
        'sp_635': _cngAmtCtrl.text,
        'sp_540': _paAmtCtrl.text,
        'sp_544': _addLessCtrl.text,
        'sp_615': _ncbCtrl.text,
        'sp_560': _insExShowCtrl.text,
        'sp_533': _rtoCityId ?? '',
        'sp_534': _rtoFrom == 'In House'
            ? 'in'
            : (_rtoFrom == 'Out House' ? 'out' : 'bh'),
        'sp_492': _rtoRateCtrl.text,
        'sp_493': _rtoSurCtrl.text,
        'sp_494': _greenTaxCtrl.text,
        'sp_495': _regFeeCtrl.text,
        'sp_496': _hpnRtoCtrl.text,
        'sp_497': _dupCtrl.text,
        'sp_498': _smartCtrl.text,
        'sp_499': _otherRtoCtrl.text,
        'sp_500': _rtoAmtCtrl.text,
        'sp_614': _rtoTempCtrl.text,
        'sp_636': _bhPerCtrl.text,
        'sp_637': _bhYearCtrl.text,
        'sp_549': _rtoExShowCtrl.text,
        'sp_653': _scrappage ? '1' : '0',
        'sp_654': '0',
        'sp_617': _oth1Ctrl.text,
        'sp_620': _amt1Ctrl.text,
        'sp_618': _oth2Ctrl.text,
        'sp_621': _amt2Ctrl.text,
        'sp_619': _oth3Ctrl.text,
        'sp_622': _amt3Ctrl.text,
        'sp_623': _workshopInvNo.text,
        'sp_624': _workshopInvAmt.text,
        'sp_477': _trcCtrl.text,
        'sp_478': _compAccCtrl.text,
        'sp_573': _ownAccCtrl.text,
        'sp_479': _warrantyCtrl.text,
        'sp_480': _warrantyYrCtrl.text,
        'sp_481': _warrantyCtrl.text,
        'sp_474': _fastTagCtrl.text,
        'sp_476': _tcsCtrl.text,
        'sp_521': _totalCtrl.text,
        'sp_616': _remarkCtrl.text,
        'sp_585': _appRemarkCtrl.text,
        'sp_581': _rejRemarkCtrl.text,
        'sp_591': '0',
        'sp_592': '0',
        'sp_504': _subTotalCtrl.text,
      };

      if (_isEditing) {
        await ApiService.updateChallan(payload);
        if (!mounted) return;
        _snack('Challan updated — No. $_challanNo');
      } else {
        await ApiService.saveChallanNew(payload);
        if (!mounted) return;
        _snack('Challan saved — No. $_challanNo');
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m, {bool isError = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFE53935)
              : const Color(0xFF1B8A5A),
        ),
      );

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1422) : const Color(0xFFF4F7FC);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          _appBar(isDark),
          Expanded(
            child: _loading
                ? _loader()
                : _initError != null
                ? _errWidget()
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 150),
                        child: Column(
                          children: [
                            _pageTitleBar(),
                            const SizedBox(height: 16),
                            _pad(_secHeader()),
                            const SizedBox(height: 16),
                            _sectionDivider('Finance'),
                            _pad(_secFinance()),
                            const SizedBox(height: 16),
                            _sectionDivider('Discounts & Offers'),
                            _pad(_secDiscounts()),
                            const SizedBox(height: 16),
                            _sectionDivider('Insurance'),
                            _pad(_secInsurance()),
                            const SizedBox(height: 16),
                            _sectionDivider('RTO'),
                            _pad(_secRto()),
                            const SizedBox(height: 16),
                            _sectionDivider('Others'),
                            _pad(_secOthers()),
                            const SizedBox(height: 16),
                            _sectionDivider('Final Details'),
                            _pad(_secBottomAmounts()),
                            const SizedBox(height: 16),
                            _sectionDivider('Receipts'),
                            _pad(_secReceipts()),
                            const SizedBox(height: 16),
                            _sectionDivider('Balances'),
                            _pad(_secBalances()),
                            const SizedBox(height: 16),
                            _sectionDivider('Remarks'),
                            _pad(_secRemarks()),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(isDark),
    );
  }

  // ── Modern app bar ────────────────────────────────────────────────────────
  Widget _appBar(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [
                      Color(0xFF071B35),
                      Color(0xFF123E78),
                      Color(0xFF0D5BB5),
                    ]
                  : const [
                      Color(0xFF082B5C),
                      Color(0xFF0D55A7),
                      Color(0xFF1675D1),
                    ],
              stops: const [0.0, 0.52, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                mobile ? 8 : 12,
                12,
                mobile ? 9 : 14,
              ),
              child: mobile
                  ? Row(
                      children: [
                        _headerIconButton(
                          Icons.arrow_back_rounded,
                          () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isEditing ? 'Edit Challan' : 'New Challan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Customer • Vehicle • Finance',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 118),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'CHALLAN NO.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 7,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$_challanNo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _headerIconButton(
                          Icons.arrow_back_rounded,
                          () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New Challan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Create customer • vehicle • finance details',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.confirmation_number_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'CHALLAN NO.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.65,
                                      ),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_challanNo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    ),
  );

  Widget _pageTitleBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            mobile ? 14 : 18,
            mobile ? 12 : 14,
            mobile ? 14 : 18,
            mobile ? 12 : 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1B32), Color(0xFF1675D1), Color(0xFF69B5F6)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A1B32).withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: mobile ? 38 : 44,
                height: mobile ? 38 : 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: mobile ? 20 : 23,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHALLAN DETAILS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Customer, vehicle and financial information',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              if (!mobile) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Colors.white,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'CHALLAN NO.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_challanNo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _sectionDivider(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    switch (title) {
      case 'Finance':
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'Discounts & Offers':
        icon = Icons.local_offer_rounded;
        break;
      case 'Insurance':
        icon = Icons.verified_user_rounded;
        break;
      case 'RTO':
        icon = Icons.directions_car_filled_rounded;
        break;
      case 'Others':
        icon = Icons.widgets_rounded;
        break;
      case 'Final Details':
        icon = Icons.fact_check_rounded;
        break;
      case 'Receipts':
        icon = Icons.receipt_long_rounded;
        break;
      case 'Balances':
        icon = Icons.account_balance_rounded;
        break;
      default:
        icon = Icons.notes_rounded;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15253A) : const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFD3E3FA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF214D88) : const Color(0xFFDCEAFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : const Color(0xFF1F64C7),
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF174A88),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _sectionSubtitle(title),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF6B7D96),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isDark ? Colors.white54 : const Color(0xFF7E96B5),
            size: 21,
          ),
        ],
      ),
    );
  }

  String _sectionSubtitle(String title) {
    switch (title) {
      case 'Finance':
        return 'Funding and loan information';
      case 'Discounts & Offers':
        return 'Corporate, exchange and scheme adjustments';
      case 'Insurance':
        return 'Policy, coverage and premium details';
      case 'RTO':
        return 'Registration and road tax information';
      case 'Others':
        return 'Additional charges and descriptions';
      case 'Final Details':
        return 'Accessories, warranty and final amounts';
      case 'Receipts':
        return 'Payment collection details';
      case 'Balances':
        return 'Outstanding and received amounts';
      default:
        return 'Notes and approval information';
    }
  }

  Widget _pad(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF132033)
          : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFD8E4F3),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.10
                : 0.045,
          ),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );

  Widget _loader() => const Center(
    child: Padding(
      padding: EdgeInsets.all(60),
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Color(0xFF0D3F8A),
      ),
    ),
  );

  Widget _errWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: _pad(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFE53935),
            ),
            const SizedBox(height: 12),
            Text(
              _initError ?? 'Error loading form',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDropdowns,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _bottomBar(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        final badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                size: 17,
                color: isDark ? Colors.white70 : const Color(0xFF687588),
              ),
              const SizedBox(width: 7),
              Text(
                'Challan $_challanNo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF526074),
                ),
              ),
            ],
          ),
        );

        final saveButton = ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded, size: 19),
          label: Text(
            _saving
                ? 'Saving...'
                : (_isEditing ? 'Update Challan' : 'Save Challan'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: _primary.withValues(alpha: 0.28),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        );

        final exitButton = OutlinedButton.icon(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'ChallanGridScreen'),
                builder: (_) => const ChallanGridScreen(),
              ),
            );
          },
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text(
            'Exit',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: _accent,
            side: BorderSide(
              color: _accent.withValues(alpha: 0.45),
              width: 1.3,
            ),
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        );

        return Container(
          padding: EdgeInsets.fromLTRB(
            12,
            mobile ? 8 : 10,
            12,
            mobile ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B121C) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFE2E7EF),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 22,
                offset: const Offset(0, -7),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: mobile
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: badge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: saveButton),
                          const SizedBox(width: 8),
                          Expanded(child: exitButton),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      badge,
                      const SizedBox(width: 12),
                      Expanded(child: saveButton),
                      const SizedBox(width: 10),
                      SizedBox(width: 130, child: exitButton),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _secHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF162231) : const Color(0xFFF8FAFD);
    final valueColor = isDark ? Colors.white : const Color(0xFF253247);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE8EDF4),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mobile = constraints.maxWidth < 520;
              final title = Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1675D1).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF1675D1),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Customer & Vehicle Information',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: valueColor,
                      ),
                    ),
                  ),
                ],
              );
              if (mobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 4),
                    Text(
                      'Required details',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF8A95A5),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  const SizedBox(width: 8),
                  Text(
                    'Required details',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : const Color(0xFF8A95A5),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        _r3(
          _dropMapField('Branch', _branchId, _branches, _onBranchSelected),
          _dropStrField(
            'Challan Type',
            _challanType,
            _challanTypes
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: _s13),
                  ),
                )
                .toList(),
            _onChallanTypeSelected,
          ),
          _customerSelector(),
        ),
        _vg,
        _r3(
          _datePicker(),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1675D1).withValues(alpha: 0.08),
                  const Color(0xFF1675D1).withValues(alpha: 0.03),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF1675D1).withValues(alpha: 0.28),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tag_rounded,
                    color: const Color(0xFF1675D1),
                    size: 17,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CHALLAN NO.',
                      style: TextStyle(
                        fontSize: 8.5,
                        color: Color(0xFF8C5960),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$_challanNo',
                      style: const TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF0A1B32),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _txt('Address', _addressCtrl, maxLines: 1),
        ),
        _vg,
        _r3(
          _dropMapField('State', _stateId, _states, (v) {
            _onStateSelected(v);
          }),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropMapField('City', _cityId, _cities, (v) {
                  if (v == '__CLEAR__' || v == null) {
                    setState(() {
                      _cityId = null;
                      _cityName = '';
                      _areaId = null;
                      _areaName = '';
                    });
                    return;
                  }
                  final city = _cities.firstWhere(
                    (e) => (e['data'] ?? e['sp_572']).toString() == v,
                    orElse: () => {},
                  );
                  setState(() {
                    _cityId = v;
                    _cityName =
                        (city['value'] ?? city['sp_578'] ?? v).toString();
                    _areaId = null;
                    _areaName = '';
                  });
                }),
              ),
              const SizedBox(width: 7),
              _plusBtn(_openCitySheet),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _dropMapField('Area', _areaId, _areas, (v) {
                  if (v == '__CLEAR__' || v == null) {
                    setState(() {
                      _areaId = null;
                      _areaName = '';
                    });
                    return;
                  }
                  final area = _areas.firstWhere(
                    (e) => (e['data'] ?? e['sp_212']).toString() == v,
                    orElse: () => {},
                  );
                  setState(() {
                    _areaId = v;
                    _areaName =
                        (area['value'] ?? area['sp_217'] ?? v).toString();
                  });
                }),
              ),
              const SizedBox(width: 7),
              _plusBtn(_openAreaSheet),
            ],
          ),
        ),
        _vg,
        _r3(
          _txt('Location', _locationCtrl, readOnly: true),
          _txt('Mobile No.', _mobileCtrl, inputType: TextInputType.phone),
          Column(
            children: [
              _txt(
                'Email Id',
                _emailCtrl,
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 7),
              _txt('Aadhar No.', _aadharCtrl, inputType: TextInputType.number),
            ],
          ),
        ),
        _vg,
        _r3(
          _txt('PAN', _panCtrl, inputFormatters: [UpperCaseFormatter()]),
          _txt('Nominee Name', _nomineeCtrl),
          Column(
            children: [
              _txt('Age', _ageCtrl, inputType: TextInputType.number),
              const SizedBox(height: 7),
              _dropStrField(
                'Relation',
                _relation,
                [
                      'CHOOSE RELATIONSHIP',
                      'Son',
                      'Daughter',
                      'Spouse',
                      'Father',
                      'Mother',
                      'Other',
                    ]
                    .map(
                      (r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: _s13),
                      ),
                    )
                    .toList(),
                (v) => setState(() => _relation = v!),
              ),
            ],
          ),
        ),
        _vg,
        _r3(
          _txt('GST No.', _gstinCtrl, inputFormatters: [UpperCaseFormatter()]),
          _txt('SC Name', _scCtrl, readOnly: true),
          Column(
            children: [
              _txt('TL Name', _tlCtrl, readOnly: true),
              const SizedBox(height: 7),
              _txt('Manager', _managerCtrl, readOnly: true),
            ],
          ),
        ),
        _vg,
        _r3(
          _dropMapField('Model', _modelId, _models, _onModel,
              disabled: true),
          _loadingVar
              ? _loadBox()
              : _dropMapField('Variant', _variantId, _variants, _onVariant,
                  disabled: true),
          Column(
            children: [
              _loadingCol
                  ? _loadBox()
                  : _dropMapField('Color', _colorId, _colors, _onColor,
                      disabled: true),
              const SizedBox(height: 7),
              _loadingVin
                  ? _loadBox()
                  : _dropMapField(
                      'VIN',
                      _vinNo,
                      _vins,
                      _onVinSelected,
                      labelFn: (e) =>
                          '${e['value'] ?? ''} ${e['mfcyr'] ?? ''}'.trim(),
                      disabled: true,
                    ),
            ],
          ),
        ),
        _vg,
        _r3(
          _txt('Engine No.', _engineCtrl, readOnly: true),
          const SizedBox(),
          const SizedBox(),
        ),
      ],
    );
  }

  Widget _customerSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _custId == null
        ? 'SELECT CUSTOMER'
        : (_customers.firstWhere(
                    (e) => e['data'] == _custId,
                    orElse: () => {},
                  )['value']
                  as String? ??
              'SELECT CUSTOMER');
    return InkWell(
      onTap: _openCustomerSheet,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _dec('Customer Name'),
        child: Row(
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 18,
              color: _custId == null
                  ? (isDark ? Colors.white38 : const Color(0xFF9BA5B4))
                  : _accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _custId == null
                      ? (isDark ? Colors.white38 : const Color(0xFF9BA5B4))
                      : null,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 19,
              color: Color(0xFF8C97A7),
            ),
          ],
        ),
      ),
    );
  }

  // ── Finance section ───────────────────────────────────────────────────────
  Widget _secFinance() => Column(
    children: [
      // Row 1: Finance type + loan amount
      _r4(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _lbl('Finance Type'),
            const SizedBox(height: 4),
            Wrap(
              children: [
                _radio('In House', _finType, (v) {
                  if (v == null) return;
                  setState(() => _finType = v);
                  _recalculateAspNet();
                }),
                _radio('Out House', _finType, (v) {
                  if (v == null) return;
                  setState(() => _finType = v);
                  _recalculateAspNet();
                }),
                _radio('Cash', _finType, (v) => setState(() => _finType = v!)),
              ],
            ),
          ],
        ),
        _num('Loan Amount', _loanAmtCtrl),
        _num('Net Disbursed Amt', _netDisCtrl),
        _txt('Branch Name', _branchNameCtrl),
      ),
      _vg,
      // Row 2: HPN parent + child branch (only when In House / Out House)
      if (_finType != 'Cash') ...[
        _r4(
          // HPN parent dropdown
          _dropMapField('HPN / Financer', _hpnParentId, _hpnList, (v) {
            setState(() {
              _hpnParentId = v;
              _hpnChildId = null;
              _hpnBranches = [];
            });
            if (v != null && v.isNotEmpty) _loadHpnBranches(v);
          }),
          // HPN child branch dropdown — populated after parent is chosen
          _hpnBranches.isEmpty
              ? _txt('HPN Branch', _hypCtrl)
              : _dropMapField('HPN Branch', _hpnChildId, _hpnBranches, (v) {
                  setState(() => _hpnChildId = v);
                }),
          const SizedBox(),
          const SizedBox(),
        ),
      ],
    ],
  );

  // ── Discounts section ─────────────────────────────────────────────────────
  Widget _secDiscounts() => Column(
    children: [
      // header row
      Row(
        children: [
          const Expanded(flex: 5, child: SizedBox()),
          Expanded(flex: 2, child: Center(child: _lbl('Given'))),
          Expanded(flex: 3, child: Center(child: _lbl('Ex-Showroom'))),
        ],
      ),
      const SizedBox(height: 4),
      _discRow(
        'Corporate',
        _corpYn,
        (v) => setState(() => _corpYn = v!),
        _corpValCtrl,
        _corpGiven,
        (v) => setState(() => _corpGiven = v!),
        _exShowCtrl,
        'Ex-Showroom',
      ),
      _discRow(
        'Exchange',
        _exchYn,
        (v) => setState(() => _exchYn = v!),
        _exchValCtrl,
        _exchGiven,
        (v) => setState(() => _exchGiven = v!),
        _schemesCtrl,
        'Schemes Less',
      ),
      _discRow(
        'Dealer Discount',
        _dealYn,
        (v) => setState(() => _dealYn = v!),
        _dealValCtrl,
        _dealGiven,
        (v) => setState(() => _dealGiven = v!),
        _subTotalCtrl,
        'SubTotal',
        ro: true,
      ),
      _discRow(
        'Loyalty',
        _loyYn,
        (v) => setState(() => _loyYn = v!),
        _loyValCtrl,
        _loyGiven,
        (v) => setState(() => _loyGiven = v!),
        null,
        '',
      ),
    ],
  );

  Widget _discRow(
    String lbl,
    String yn,
    ValueChanged<String?> onYn,
    TextEditingController amtC,
    String given,
    ValueChanged<String?> onGiven,
    TextEditingController? rightC,
    String rightLbl, {
    bool ro = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 600;
      if (mobile) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lbl,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _radio('Yes', yn, onYn),
                  _radio('No', yn, onYn),
                ],
              ),
              const SizedBox(height: 7),
              _num('Amount', amtC),
              const SizedBox(height: 7),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Given',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _radio('Yes', given, onGiven),
                  _radio('No', given, onGiven),
                ],
              ),
              if (rightC != null) ...[
                const SizedBox(height: 7),
                _num(rightLbl, rightC, ro: ro),
              ],
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lbl,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _radio('Yes', yn, onYn),
                  _radio('No', yn, onYn),
                ],
              ),
            ),
            Expanded(flex: 2, child: _num('', amtC)),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _radio('Yes', given, onGiven),
                  _radio('No', given, onGiven),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: rightC != null
                  ? _num(rightLbl, rightC, ro: ro)
                  : const SizedBox(),
            ),
          ],
        ),
      );
    },
  );

  // ── Insurance section (4-column grid) ────────────────────────────────────
  Widget _secInsurance() => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 600;
          final typeRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Insurance',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 5),
              _radio('In House', _insType, (v) {
                if (v == null) return;
                setState(() => _insType = v);
                _recalculateAspNet();
              }),
              _radio('Out House', _insType, (v) {
                if (v == null) return;
                setState(() => _insType = v);
                _recalculateAspNet();
              }),
            ],
          );
          final right = mobile
              ? Column(
                  children: [
                    _num('Insurance Discount%', _insDisCtrl),
                    const SizedBox(height: 8),
                    _num('Insurance Ex-Showroom', _insExShowCtrl),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: _num('Insurance Discount%', _insDisCtrl),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _num('Insurance Ex-Showroom', _insExShowCtrl),
                    ),
                  ],
                );
          return mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [typeRow, const SizedBox(height: 9), right],
                )
              : Row(
                  children: [
                    Expanded(child: typeRow),
                    const SizedBox(width: 12),
                    SizedBox(width: 320, child: right),
                  ],
                );
        },
      ),
      _vg,
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          _chk(
            'EP Amount Add',
            _epAdd,
            (v) => setState(() => _epAdd = v ?? false),
          ),
          _chk(
            'RTI Amount Add',
            _rtiAdd,
            (v) => setState(() => _rtiAdd = v ?? false),
          ),
          _chk(
            'CM Amount Add',
            _cmAdd,
            (v) => setState(() => _cmAdd = v ?? false),
          ),
        ],
      ),
      _vg,
      _i4('CESS', _cessCtrl, 'IDV', _idvCtrl, 'IDV Amount', _idvAmtCtrl, ''),
      _vg,
      _i4(
        'After IDV',
        _afterIdvCtrl,
        'Amount',
        _insAmtCtrl,
        'Insurance %',
        _insPerCtrl,
        'Insurance Amount',
        c4: _finalInsCtrl,
      ),
      _vg,
      _i4(
        'Discount Amount',
        _disAmtCtrl,
        'After Discount',
        _afterDisCtrl,
        'CNG %',
        _cngPerCtrl,
        'CNG Amount',
        c4: _cngAmtCtrl,
      ),
      _vg,
      _i4(
        'PA Cover',
        _paCoverCtrl,
        'Amount',
        _paAmtCtrl,
        'ZD',
        _zdCtrl,
        'ZD Amount',
        c4: _zdAmtCtrl,
      ),
      _vg,
      _i4(
        'EP',
        _epCtrl,
        'EP Amount',
        _epAmtCtrl,
        'Third Party',
        _thirdPartyCtrl,
        'PB',
        c4: _pbCtrl,
      ),
      _vg,
      _i4(
        'KP',
        _kpCtrl,
        'Amount',
        _kpAmtCtrl,
        'Paid Driver',
        _paidDrvCtrl,
        'After PD',
        c4: _afterPdCtrl,
      ),
      _vg,
      _i4(
        'RTI',
        _rtiCtrl,
        'RTI Amount',
        _rtiAmtCtrl,
        'CM',
        _cmCtrl,
        'CM Amount',
        c4: _cmAmtCtrl,
      ),
      _vg,
      LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 600;
          final fields = [
            _dropStrField(
              'GST',
              _gstUnq ?? '',
              [
                const DropdownMenuItem(
                  value: '',
                  child: Text('--', style: TextStyle(fontSize: 13)),
                ),
                const DropdownMenuItem(
                  value: '18',
                  child: Text('18', style: TextStyle(fontSize: 13)),
                ),
                const DropdownMenuItem(
                  value: '28',
                  child: Text('28', style: TextStyle(fontSize: 13)),
                ),
              ],
              (v) {
                setState(() => _gstUnq = v);
                _recalculateAspNet();
              },
            ),
            _num('CGST', _cgstCtrl),
            _num('SGST', _sgstCtrl),
            _num('GST Amount', _gstAmtCtrl),
          ];
          return mobile
              ? Column(
                  children: fields
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: w,
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: [
                    for (int i = 0; i < fields.length; i++) ...[
                      Expanded(child: fields[i]),
                      if (i < fields.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                );
        },
      ),
      _vg,
      LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 600;
          final fields = [
            _num('Add / Less', _addLessCtrl),
            _num('NCB', _ncbCtrl),
            _num('Insurance Amount', _insAmtFinalCtrl),
          ];
          return mobile
              ? Column(
                  children: fields
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: w,
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 8),
                    Expanded(child: fields[1]),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: fields[2]),
                  ],
                );
        },
      ),
    ],
  );

  Widget _i4(
    String l1,
    TextEditingController c1,
    String l2,
    TextEditingController c2,
    String l3,
    TextEditingController c3,
    String l4, {
    TextEditingController? c4,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final fields = <Widget>[
        _num(l1, c1),
        _num(l2, c2),
        _num(l3, c3),
        if (c4 != null && l4.isNotEmpty) _num(l4, c4),
      ];
      if (constraints.maxWidth < 600) {
        return Column(
          children: fields
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: w,
                ),
              )
              .toList(),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            Expanded(child: fields[i]),
            if (i < fields.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    },
  );

  // ── RTO section ───────────────────────────────────────────────────────────
  Widget _secRto() => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 600;
          final radios = Wrap(
            spacing: 0,
            runSpacing: 2,
            children: [
              _radio('In House', _rtoFrom, (v) {
                if (v == null) return;
                setState(() => _rtoFrom = v);
                _recalculateAspNet();
              }),
              _radio('Out House', _rtoFrom, (v) {
                if (v == null) return;
                setState(() => _rtoFrom = v);
                _recalculateAspNet();
              }),
              _radio('BH', _rtoFrom, (v) => setState(() => _rtoFrom = v!)),
            ],
          );
          final scrap = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _scrappage,
                onChanged: (v) {
                  setState(() => _scrappage = v ?? false);
                  _recalculateAspNet();
                },
                activeColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -4,
                ),
              ),
              const Text('Scrappage', style: TextStyle(fontSize: 12)),
            ],
          );
          final exShow = _num('RTO Ex-Showroom', _rtoExShowCtrl);
          if (mobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'RTO',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                radios,
                const SizedBox(height: 6),
                scrap,
                const SizedBox(height: 7),
                exShow,
              ],
            );
          }
          return Row(
            children: [
              const SizedBox(
                width: 36,
                child: Text(
                  'RTO',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              radios,
              const Spacer(),
              scrap,
              const SizedBox(width: 12),
              SizedBox(width: 140, child: exShow),
            ],
          );
        },
      ),
      _vg,
      _r4(
        _num('RTO Rate', _rtoRateCtrl),
        _num('RTO Tax Surcharge', _rtoSurCtrl),
        _num('Green Tax', _greenTaxCtrl),
        _num('Reg Fee', _regFeeCtrl),
      ),
      _vg,
      _r4(
        _num('HPN', _hpnRtoCtrl),
        _num('Duplicate', _dupCtrl),
        _num('Smart Card', _smartCtrl),
        _num('Other', _otherRtoCtrl),
      ),
      _vg,
      _r4(
        _num('BH RTO %', _bhPerCtrl),
        _txt('BH Year', _bhYearCtrl),
        _num('RTO Temporary', _rtoTempCtrl),
        _num('RTO Amount', _rtoAmtCtrl, ro: true),
      ),
    ],
  );

  // ── Others section ────────────────────────────────────────────────────────
  Widget _secOthers() => Column(
    children: [
      _r2t('Other 1', _oth1Ctrl, 'Amount 1', _amt1Ctrl),
      _vg,
      _r2t('Other 2', _oth2Ctrl, 'Amount 2', _amt2Ctrl),
      _vg,
      _r2t('Other 3', _oth3Ctrl, 'Amount 3', _amt3Ctrl),
    ],
  );

  Widget _r2t(
    String l1,
    TextEditingController c1,
    String l2,
    TextEditingController c2,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(children: [_txt(l1, c1), _vg, _num(l2, c2)]);
      }
      return Row(
        children: [
          Expanded(child: _txt(l1, c1)),
          const SizedBox(width: 8),
          Expanded(child: _num(l2, c2)),
        ],
      );
    },
  );

  // ── Company Accessories Dialog ───────────────────────────────────────────
  void _showAccessoriesDialog() {
    final partNoCtrl = TextEditingController();
    final ownNameCtrl = TextEditingController();
    final issueQtyCtrl = TextEditingController(text: '0');
    final requiredQtyCtrl = TextEditingController(text: '0');
    final mrpCtrl = TextEditingController(text: '0.00');
    final qtyCtrl = TextEditingController(text: '0');
    final hmiAmountCtrl = TextEditingController(text: '0.00');
    final ownAmountCtrl = TextEditingController(text: '0.00');

    final hmiDiscountCtrl = TextEditingController(text: '0.00');
    final ownDiscountCtrl = TextEditingController(text: '0.00');

    double number(TextEditingController c) =>
        double.tryParse(c.text.trim()) ?? 0.0;

    void recalc(StateSetter setDlg) {
      final qty = number(qtyCtrl);
      final mrp = number(mrpCtrl);

      if (qty > 0 && mrp > 0) {
        hmiAmountCtrl.text = (qty * mrp).toStringAsFixed(2);
      }

      setDlg(() {});
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final hmiAmount = number(hmiAmountCtrl);
          final hmiDiscount = number(hmiDiscountCtrl);
          final ownAmount = number(ownAmountCtrl);
          final ownDiscount = number(ownDiscountCtrl);

          final hmiTotal = (hmiAmount - hmiDiscount).clamp(0, double.infinity);
          final ownTotal = (ownAmount - ownDiscount).clamp(0, double.infinity);

          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1050,
                maxHeight: MediaQuery.sizeOf(context).height * 0.90,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0A1B32), Color(0xFF0D5BB5)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Accessories Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mobile = constraints.maxWidth < 600;
                        final mobileFields = <Widget>[
                          _dialogField('Part No', partNoCtrl),
                          _dialogField('Own Accessories Name', ownNameCtrl),
                          _dialogField('Issue Qty', issueQtyCtrl, number: true),
                          _dialogField(
                            'Required Qty',
                            requiredQtyCtrl,
                            number: true,
                          ),
                          _dialogField(
                            'MRP',
                            mrpCtrl,
                            number: true,
                            onChanged: (_) => recalc(setDlg),
                          ),
                          _dialogField(
                            'Qty',
                            qtyCtrl,
                            number: true,
                            onChanged: (_) => recalc(setDlg),
                          ),
                          _dialogField(
                            'HMI Amount',
                            hmiAmountCtrl,
                            number: true,
                            onChanged: (_) => setDlg(() {}),
                          ),
                          _dialogField(
                            'Own Amount',
                            ownAmountCtrl,
                            number: true,
                            onChanged: (_) => setDlg(() {}),
                          ),
                        ];
                        if (mobile) {
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 390),
                            child: SingleChildScrollView(
                              child: Column(
                                children: mobileFields
                                    .map(
                                      (w) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: w,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          );
                        }
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 38,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 54,
                            columnSpacing: 10,
                            horizontalMargin: 4,
                            headingTextStyle: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0A1B32),
                            ),
                            columns: const [
                              DataColumn(label: Text('Part No')),
                              DataColumn(label: Text('Own Accessories Name')),
                              DataColumn(label: Text('Issue Qty')),
                              DataColumn(label: Text('Required Qty')),
                              DataColumn(label: Text('MRP')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('HMI Amount')),
                              DataColumn(label: Text('Own Amount')),
                            ],
                            rows: [
                              DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 150,
                                      child: _dialogField('', partNoCtrl),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: _dialogField('', ownNameCtrl),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 70,
                                      child: _dialogField(
                                        '',
                                        issueQtyCtrl,
                                        number: true,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 82,
                                      child: _dialogField(
                                        '',
                                        requiredQtyCtrl,
                                        number: true,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 100,
                                      child: _dialogField(
                                        '',
                                        mrpCtrl,
                                        number: true,
                                        onChanged: (_) => recalc(setDlg),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 70,
                                      child: _dialogField(
                                        '',
                                        qtyCtrl,
                                        number: true,
                                        onChanged: (_) => recalc(setDlg),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 110,
                                      child: _dialogField(
                                        '',
                                        hmiAmountCtrl,
                                        number: true,
                                        onChanged: (_) => setDlg(() {}),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 110,
                                      child: _dialogField(
                                        '',
                                        ownAmountCtrl,
                                        number: true,
                                        onChanged: (_) => setDlg(() {}),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mobile = constraints.maxWidth < 600;
                        final hmiFields = [
                          _dialogAmountField(
                            'HMI Amount',
                            hmiAmount.toStringAsFixed(2),
                          ),
                          _dialogEditableAmountField(
                            'HMI Discount Amount',
                            hmiDiscountCtrl,
                            setDlg,
                          ),
                          _dialogAmountField(
                            'HMI Total Amount',
                            hmiTotal.toStringAsFixed(2),
                          ),
                        ];
                        final ownFields = [
                          _dialogAmountField(
                            'OWN Amount',
                            ownAmount.toStringAsFixed(2),
                          ),
                          _dialogEditableAmountField(
                            'OWN Discount Amount',
                            ownDiscountCtrl,
                            setDlg,
                          ),
                          _dialogAmountField(
                            'OWN Total Amount',
                            ownTotal.toStringAsFixed(2),
                          ),
                        ];
                        Widget line(List<Widget> fields) {
                          if (mobile) {
                            return Column(
                              children: fields
                                  .map(
                                    (w) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: w,
                                    ),
                                  )
                                  .toList(),
                            );
                          }
                          return Row(
                            children: [
                              for (int i = 0; i < fields.length; i++) ...[
                                Expanded(child: fields[i]),
                                if (i < fields.length - 1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          );
                        }

                        return Column(
                          children: [
                            line(hmiFields),
                            const SizedBox(height: 10),
                            line(ownFields),
                          ],
                        );
                      },
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F8FC),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(8),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mobile = constraints.maxWidth < 380;
                        final cancel = OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC0392B),
                            side: const BorderSide(color: Color(0xFFC0392B)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text('Cancel'),
                        );
                        final save = ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _compAccCtrl.text = hmiTotal.toStringAsFixed(2);
                              _ownAccCtrl.text = ownTotal.toStringAsFixed(2);
                              _accAmtCtrl.text = (hmiTotal + ownTotal)
                                  .toStringAsFixed(2);
                            });
                            Navigator.pop(ctx);
                            _snack('Accessories details saved');
                          },
                          icon: const Icon(Icons.save_rounded, size: 17),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                        return mobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  cancel,
                                  const SizedBox(height: 8),
                                  save,
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  cancel,
                                  const SizedBox(width: 10),
                                  save,
                                ],
                              );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      partNoCtrl.dispose();
      ownNameCtrl.dispose();
      issueQtyCtrl.dispose();
      requiredQtyCtrl.dispose();
      mrpCtrl.dispose();
      qtyCtrl.dispose();
      hmiAmountCtrl.dispose();
      ownAmountCtrl.dispose();
      hmiDiscountCtrl.dispose();
      ownDiscountCtrl.dispose();
    });
  }

  Widget _dialogField(
    String label,
    TextEditingController controller, {
    bool number = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textAlign: number ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 12),
      onChanged: onChanged,
      decoration: _dlgDec().copyWith(labelText: label.isEmpty ? null : label),
    );
  }

  Widget _dialogAmountField(String label, String value) {
    return InputDecorator(
      decoration: _dlgDec().copyWith(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 10.5,
          color: Color(0xFF0D5BB5),
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF263238),
          ),
        ),
      ),
    );
  }

  Widget _dialogEditableAmountField(
    String label,
    TextEditingController controller,
    StateSetter setDlg,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 12),
      onChanged: (_) => setDlg(() {}),
      decoration: _dlgDec().copyWith(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 10.5,
          color: Color(0xFF0D5BB5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Bottom amounts ────────────────────────────────────────────────────────
  Widget _secBottomAmounts() => Column(
    children: [
      Row(
        children: [
          Expanded(child: _txt('Workshop INV No.', _workshopInvNo)),
          const SizedBox(width: 8),
          Expanded(child: _num('Workshop INV Amt', _workshopInvAmt)),
        ],
      ),
      _vg,
      Row(
        children: [
          Expanded(
            child: _dropMapField(
              'RTO City',
              _rtoCityId,
              _rtoCities,
              _onRtoCitySelected,
            ),
          ),
          const SizedBox(width: 4),
          _plusBtn(_showAddAccountDialog),
          const SizedBox(width: 12),
          Expanded(child: _txt('TRC', _trcCtrl)),
        ],
      ),
      _vg,
      _r3(
        Row(
          children: [
            Expanded(child: _num('Company Accessories', _compAccCtrl)),
            const SizedBox(width: 6),
            _plusBtn(_showAccessoriesDialog),
          ],
        ),
        _num('Own Accessories', _ownAccCtrl),
        _num('Accessories Amount', _accAmtCtrl, ro: true),
      ),
      _vg,
      _r3(
        _num('Warranty', _warrantyCtrl),
        _num('RSA', _rsaCtrl),
        Row(
          children: [
            SizedBox(
              width: 72,
              child: _dropStrField(
                '',
                _sotType,
                ['SOT', 'Accessories']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: _s13),
                      ),
                    )
                    .toList(),
                (v) => setState(() => _sotType = v!),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: _num('', _sotAmtCtrl)),
          ],
        ),
      ),
      _vg,
      _r3(
        _num('Fast Tag', _fastTagCtrl),
        _num('TCS', _tcsCtrl),
        _num('Total', _totalCtrl, ro: true),
      ),
    ],
  );

  // ── Receipts grid ─────────────────────────────────────────────────────────
  Widget _secReceipts() {
    final cols = [
      'RNo',
      'Date',
      'Mode',
      'Cheque No.',
      'Cash',
      'Cheque',
      'UPI',
      'RTGS',
      'Wallet',
      'Card',
      'Received',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _vg,
        if (_loadingReceipts)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: _border)),
              child: Column(
                children: [
                  // Header
                  Container(
                    color: _accent,
                    child: Row(children: cols.map((h) => _th(h)).toList()),
                  ),
                  // Data rows
                  if (_receiptRows.isEmpty)
                    Container(
                      color: Colors.grey.shade50,
                      child: Row(children: cols.map((_) => _td('-')).toList()),
                    )
                  else
                    ..._receiptRows.map((row) {
                      final rno =
                          row['rcl_9']?.toString() ??
                          row['Rcl_9']?.toString() ??
                          '';
                      final date =
                          row['rcl_7']?.toString() ??
                          row['Rcl_7']?.toString() ??
                          '';
                      final mode =
                          row['rcl_16']?.toString() ??
                          row['rcl_66']?.toString() ??
                          '';
                      final chqno = row['rcl_13']?.toString() ?? '';
                      final cash = row['rcl_40']?.toString() ?? '0';
                      final chqAmt = row['Cheque']?.toString() ?? '0';
                      final upi = row['upi']?.toString() ?? '0';
                      final rtgs = row['Rtgs']?.toString() ?? '0';
                      final wallet = row['rcl_41']?.toString() ?? '0';
                      final card = row['rcl_42']?.toString() ?? '0';
                      final recv =
                          row['rcl_58']?.toString() ??
                          row['RCL_58']?.toString() ??
                          '0';
                      return Container(
                        color: _receiptRows.indexOf(row).isEven
                            ? Colors.white
                            : const Color(0xFFF6F9FF),
                        child: Row(
                          children: [
                            _td(rno),
                            _td(date),
                            _td(mode),
                            _td(chqno),
                            _td(cash),
                            _td(chqAmt),
                            _td(upi),
                            _td(rtgs),
                            _td(wallet),
                            _td(card),
                            _td(recv),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Totals row
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _rcTotalChip('Total Received', _receiptTotal),
              _rcTotalChip('Finance Amt', _receiptFinanceAmt),
              _rcTotalChip('Customer Amt', _receiptCustAmt),
            ],
          ),
        ],
      ],
    );
  }

  Widget _rcTotalChip(String label, double value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFD3E3FA)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B5B88),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '₹ ${value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A3D91),
          ),
        ),
      ],
    ),
  );

  Widget _th(String t) => Container(
    width: 80,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: Colors.white24, width: 0.5)),
    ),
    child: Text(
      t,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
  Widget _td(String t) => Container(
    width: 80,
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: _border, width: 0.5)),
    ),
    child: Text(t, style: const TextStyle(fontSize: 10)),
  );

  // ── Balances ──────────────────────────────────────────────────────────────
  Widget _secBalances() => Column(
    children: [
      _vg,
      Row(
        children: [
          Expanded(
            child: _num('HPN Received Amt', _hpnReceivedCtrl, ro: false),
          ),
          const SizedBox(width: 12),
          Expanded(child: _num('HPN Balance', _hpnBalanceCtrl, ro: true)),
        ],
      ),
      _vg,
      Row(
        children: [
          Expanded(
            child: _num(
              'Customer Received Amt',
              _customerReceivedCtrl,
              ro: false,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _num('Customer Balance', _customerBalanceCtrl, ro: true),
          ),
        ],
      ),
      _vg,
      Row(
        children: [
          Expanded(child: _num('Received Amt', _receivedCtrl, ro: false)),
          const SizedBox(width: 12),
          Expanded(child: _num('Balance', _balanceCtrl, ro: true)),
        ],
      ),
    ],
  );

  // ── Remarks ───────────────────────────────────────────────────────────────
  Widget _secRemarks() => Column(
    children: [
      _vg,
      _txt('Remark', _remarkCtrl, maxLines: 3),
      _vg,
      _txt('Approval Remark', _appRemarkCtrl, maxLines: 2),
      _vg,
      _txt('Reject Remark', _rejRemarkCtrl, maxLines: 2),
    ],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //  SHARED FIELD BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Widget _vg = SizedBox(height: 10);
  static const TextStyle _s13 = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  Widget _lbl(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : const Color(0xFF465266),
      ),
    ),
  );

  InputDecoration _dec(String label, {bool ro = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : const Color(0xFFD3E1F2);
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      labelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white54 : const Color(0xFF61738C),
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1F64C7),
      ),
      filled: true,
      fillColor: ro
          ? (isDark ? const Color(0xFF18283D) : const Color(0xFFF1F6FD))
          : (isDark ? const Color(0xFF122033) : const Color(0xFFFAFCFF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF1675D1), width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide(color: border),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      isDense: true,
    );
  }

  Widget _txt(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType? inputType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: inputType,
    inputFormatters: inputFormatters,
    readOnly: readOnly,
    style: _s13,
    decoration: _dec(label, ro: readOnly),
  );

  Widget _num(
    String label,
    TextEditingController ctrl, {
    bool ro = false,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: ctrl,
    readOnly: ro,
    onChanged: (value) {
      onChanged?.call(value);
      if (!ro) _recalculateAspNet();
    },
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
    ],
    textAlign: TextAlign.right,
    style: _s13,
    decoration: _dec(label, ro: ro),
  );

  /// Searchable map-based dropdown — tapping opens a full search bottom sheet.
  Widget _dropMapField<T>(
    String label,
    T? value,
    List<Map<String, dynamic>> items,
    ValueChanged<T?> onChanged, {
    String Function(Map<String, dynamic>)? labelFn,
    bool disabled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayLabel = value == null
        ? null
        : () {
            final match = items.firstWhere(
              (e) => e['data'] == value,
              orElse: () => <String, dynamic>{},
            );
            if (match.isEmpty) return null;
            return labelFn != null
                ? labelFn(match)
                : (match['value'] as String? ??
                      match['data']?.toString() ??
                      '');
          }();

    final field = InputDecorator(
      decoration: _dec(label, ro: disabled),
      child: Row(
        children: [
          Expanded(
            child: Text(
              displayLabel ?? 'SELECT',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: displayLabel == null
                    ? (isDark ? Colors.white38 : const Color(0xFF9AA3AF))
                    : disabled
                        ? (isDark
                            ? Colors.white54
                            : const Color(0xFF6B7888))
                        : (isDark
                            ? Colors.white
                            : const Color(0xFF1A2740)),
              ),
            ),
          ),
          Icon(
            disabled ? Icons.lock_outline_rounded : Icons.search_rounded,
            size: disabled ? 15 : 18,
            color: disabled
                ? (isDark ? Colors.white24 : const Color(0xFFBBC5D1))
                : (isDark ? Colors.white38 : const Color(0xFF8A97AB)),
          ),
        ],
      ),
    );

    if (disabled) return field;

    return InkWell(
      onTap: () async {
        final strItems = items.map((e) {
          final lbl = labelFn != null
              ? labelFn(e)
              : (e['value'] as String? ?? e['data']?.toString() ?? '');
          return <String, dynamic>{'data': e['data'], 'value': lbl};
        }).toList();

        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SearchSheet(
            items: strItems,
            labelKey: 'value',
            valueKey: 'data',
            hint: 'Search $label...',
            selectedValue: value?.toString(),
            title: label,
          ),
        );
        if (result == '__CLEAR__') {
          onChanged(null);
        } else if (result != null) {
          onChanged(result as T?);
        }
      },
      borderRadius: BorderRadius.circular(11),
      child: field,
    );
  }

  /// Searchable string-based dropdown — tapping opens a full search bottom sheet.
  Widget _dropStrField(
    String label,
    String value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Convert DropdownMenuItems into the map format _SearchSheet expects
    final sheetItems = items.where((i) => i.value != null).map((i) {
      final txt = (i.child is Text)
          ? (i.child as Text).data ?? i.value!
          : i.value!;
      return <String, dynamic>{'data': i.value, 'value': txt};
    }).toList();

    return InkWell(
      onTap: () async {
        final result = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _SearchSheet(
            items: sheetItems,
            labelKey: 'value',
            valueKey: 'data',
            hint: 'Search $label...',
            selectedValue: value,
            title: label,
          ),
        );
        if (result != null && result != '__CLEAR__') onChanged(result);
      },
      borderRadius: BorderRadius.circular(11),
      child: InputDecorator(
        decoration: _dec(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A2740),
                ),
              ),
            ),
            Icon(
              Icons.search_rounded,
              size: 18,
              color: isDark ? Colors.white38 : const Color(0xFF8A97AB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePicker() => InkWell(
    onTap: _pickDate,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: _dec('Date'),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: const Color(0xFF1675D1).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: Color(0xFF0D5BB5),
            ),
          ),
          const SizedBox(width: 8),
          Text(DateFormat('dd/MM/yyyy').format(_challanDate), style: _s13),
          const Spacer(),
          const Icon(
            Icons.edit_calendar_rounded,
            size: 16,
            color: Color(0xFF9AA5B5),
          ),
        ],
      ),
    ),
  );

  Widget _radio(String val, String group, ValueChanged<String?> fn) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Radio<String>(
        value: val,
        groupValue: group,
        onChanged: fn,
        activeColor: _primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      ),
      Text(
        val,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
    ],
  );

  Widget _chk(String label, bool val, ValueChanged<bool?> fn) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Checkbox(
        value: val,
        onChanged: fn,
        activeColor: _primary,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      const SizedBox(width: 6),
    ],
  );

  Widget _plusBtn(VoidCallback onTap) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1B32), Color(0xFF1675D1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0A1B32).withValues(alpha: 0.18),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    ),
  );

  Widget _loadBox() => Container(
    height: 42,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1D2631)
          : const Color(0xFFF8FAFC),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white12
            : const Color(0xFFDCE2EA),
      ),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: LinearProgressIndicator(minHeight: 3),
    ),
  );

  Widget _r3(Widget a, Widget b, Widget c) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked = constraints.maxWidth < 800;
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [a, _vg, b, _vg, c],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
          const SizedBox(width: 12),
          Expanded(child: c),
        ],
      );
    },
  );

  Widget _r4(Widget a, Widget b, Widget c, Widget d) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 600) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [a, _vg, b, _vg, c, _vg, d],
        );
      }
      if (constraints.maxWidth < 900) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: a),
                const SizedBox(width: 10),
                Expanded(child: b),
              ],
            ),
            _vg,
            Row(
              children: [
                Expanded(child: c),
                const SizedBox(width: 10),
                Expanded(child: d),
              ],
            ),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
          const SizedBox(width: 10),
          Expanded(child: c),
          const SizedBox(width: 10),
          Expanded(child: d),
        ],
      );
    },
  );

  // ── Customer bottom sheet ─────────────────────────────────────────────────
  void _openCustomerSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(
        items: _customers,
        labelKey: 'value',
        valueKey: 'data',
        hint: 'Search customer name...',
        selectedValue: _custId,
        title: 'Customer Name',
      ),
    );
    if (result != null && result != '__CLEAR__') {
      _onCustomerSelected(result);
    } else if (result == '__CLEAR__') {
      setState(() {
        _custId = null;
        _addressCtrl.clear();
        _mobileCtrl.clear();
        _panCtrl.clear();
        _aadharCtrl.clear();
        _gstinCtrl.clear();
        _fatherCtrl.clear();
        _emailCtrl.clear();
        _ageCtrl.clear();
        _nomineeCtrl.clear();
        _scCtrl.clear();
        _tlCtrl.clear();
        _managerCtrl.clear();
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Searchable selection bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String labelKey, valueKey, hint;
  final String? selectedValue;
  final String title;

  const _SearchSheet({
    required this.items,
    required this.labelKey,
    required this.valueKey,
    required this.hint,
    required this.title,
    this.selectedValue,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late List<Map<String, dynamic>> _filtered;
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  static const Color _accent = Color(0xFF0D5BB5);
  static const Color _primary = Color(0xFF0A1B32);

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filter(String q) {
    final lq = q.toLowerCase().trim();
    setState(() {
      _filtered = lq.isEmpty
          ? widget.items
          : widget.items
                .where(
                  (e) => (e[widget.labelKey] as String? ?? '')
                      .toLowerCase()
                      .contains(lq),
                )
                .toList();
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF131E2D) : Colors.white;
    final surfaceBg = isDark
        ? const Color(0xFF1A2637)
        : const Color(0xFFF4F8FF);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFD3E1F2);
    final textColor = isDark ? Colors.white : const Color(0xFF1A2740);
    final subColor = isDark ? Colors.white38 : const Color(0xFF8A97AB);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, sc) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── drag handle ─────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCDD7E8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── header ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF082B5C), Color(0xFF1675D1)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_filtered.length} of ${widget.items.length} items',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Clear selection button
                  if (widget.selectedValue != null &&
                      widget.selectedValue!.isNotEmpty)
                    InkWell(
                      onTap: () => Navigator.pop(ctx, '__CLEAR__'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── search box ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: TextField(
                controller: _searchCtrl,
                focusNode: _focusNode,
                onChanged: _filter,
                autofocus: true,
                style: TextStyle(
                  fontSize: 13.5,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(fontSize: 13, color: subColor),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: _accent,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: 18,
                            color: subColor,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filter('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: surfaceBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  isDense: true,
                ),
              ),
            ),

            // ── divider ─────────────────────────────────────────────
            Divider(height: 1, color: borderColor),

            // ── list ────────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: isDark
                                ? Colors.white24
                                : const Color(0xFFBBC8DA),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No results found',
                            style: TextStyle(
                              fontSize: 13,
                              color: subColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different search term',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: borderColor),
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        final lbl = item[widget.labelKey] as String? ?? '';
                        final val = item[widget.valueKey]?.toString();
                        final isSelected = val == widget.selectedValue;

                        return InkWell(
                          onTap: () => Navigator.pop(ctx, val),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                        ? const Color(0xFF153358)
                                        : const Color(0xFFE8F0FE))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: isDark
                                          ? const Color(0xFF2A5BAD)
                                          : const Color(0xFFB8D0F8),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // index badge
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? _accent
                                        : (isDark
                                              ? const Color(0xFF1F3347)
                                              : const Color(0xFFEEF3FB)),
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF6B82A0),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    lbl,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? Colors.white : _primary)
                                          : textColor,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Selected',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase(), selection: n.selection);
}
