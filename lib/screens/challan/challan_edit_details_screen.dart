import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../l10n/app_localizations.dart';

class ChallanEditDetailsScreen extends StatefulWidget {
  final String sp462;
  final String challanNo;

  const ChallanEditDetailsScreen({
    super.key,
    required this.sp462,
    required this.challanNo,
  });

  @override
  State<ChallanEditDetailsScreen> createState() =>
      _ChallanEditDetailsScreenState();
}

class _ChallanScreenStateCache {
  final Set<String> expandedSections;
  final Set<String> checkedRejectFields;
  final bool isRadioSelected;
  final String rejectRemark;

  const _ChallanScreenStateCache({
    required this.expandedSections,
    required this.checkedRejectFields,
    required this.isRadioSelected,
    required this.rejectRemark,
  });
}

class _ChallanEditDetailsScreenState extends State<ChallanEditDetailsScreen> {
  static final Map<String, _ChallanScreenStateCache> _pageStateCache = {};
  static const Map<String, Map<String, String>> _uiText = {
    'en': {
      'customerLabel': 'Customer',
      'exShowroomLabel': 'Ex-Showroom',
      'corporateLabel': 'Corporate',
      'subtotalLabel': 'Subtotal',
      'rtoAmountLabel': 'RTO Amount',
      'insuranceAmtLabel': 'Insurance Amt',
      'netAmountLabel': 'Net Amount',
      'mobileLabel': 'Mobile',
      'challanDetails': 'Challan Details',
      'challanNoLabel': 'Challan No',
      'loadingChallanDetails': 'Loading challan details...',
      'failedToLoadDetails': 'Failed to load details',
      'showSelectionCheckboxes': 'Show Selection Checkboxes',
      'enableCheckboxesHelp': 'Enable checkboxes to select fields for rejection remarks',
      'rejectRemarkTitle': 'Reject remark',
      'reject': 'Reject',
      'approve': 'Approve',
      'pleaseSelectFieldOrReason': 'Please check at least one field or enter a rejection reason',
      'basicInformation': 'Basic Information',
      'pricingDetails': 'Pricing Details',
      'discountsAndOffers': 'Discounts & Offers',
      'discountTitle': 'Discount',
      'rtoDetails': 'RTO Details',
      'taxDetails': 'Tax Details',
      'insuranceDetails': 'Insurance Details',
      'financialDetails': 'Financial Details',
      'customerInformation': 'Customer Information',
      'rejectChallan': 'Reject Challan',
      'checkedFieldInfo': 'Checked fields are added below. You can edit before rejecting:',
      'rejectRemarkHint': 'Reject remark (auto-filled from checked fields)...',
    },
    'de': {
      'customerLabel': 'Kunde',
      'exShowroomLabel': 'Ex-Showroom',
      'corporateLabel': 'Firmenkunde',
      'subtotalLabel': 'Zwischensumme',
      'rtoAmountLabel': 'RTO-Betrag',
      'insuranceAmtLabel': 'Versicherungsbetrag',
      'netAmountLabel': 'Nettobetrag',
      'mobileLabel': 'Handy',
      'challanDetails': 'Lieferscheindetails',
      'challanNoLabel': 'Lieferschein-Nr.',
      'loadingChallanDetails': 'Lieferscheindetails werden geladen...',
      'failedToLoadDetails': 'Details konnten nicht geladen werden',
      'showSelectionCheckboxes': 'Auswahl-Checkboxen anzeigen',
      'enableCheckboxesHelp': 'Checkboxen aktivieren, um Felder fuer Ablehnungsgruende auszuwaehlen',
      'rejectRemarkTitle': 'Ablehnungsgrund',
      'reject': 'Ablehnen',
      'approve': 'Genehmigen',
      'pleaseSelectFieldOrReason': 'Bitte mindestens ein Feld waehlen oder einen Ablehnungsgrund eingeben',
      'basicInformation': 'Grundinformationen',
      'pricingDetails': 'Preisdetails',
      'discountsAndOffers': 'Rabatte & Angebote',
      'discountTitle': 'Rabatt',
      'rtoDetails': 'RTO-Details',
      'taxDetails': 'Steuerdetails',
      'insuranceDetails': 'Versicherungsdetails',
      'financialDetails': 'Finanzdetails',
      'customerInformation': 'Kundeninformationen',
      'rejectChallan': 'Lieferschein ablehnen',
      'checkedFieldInfo': 'Markierte Felder werden unten hinzugefuegt. Sie koennen vor dem Ablehnen bearbeiten:',
      'rejectRemarkHint': 'Ablehnungsgrund (automatisch aus markierten Feldern)...',
    },
  };
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _processing = false;
  String loggedInUserId = '';
  Set<String> _expandedSections = {'Basic Information'};
  final Set<String> _checkedRejectFields = {};
  final List<String> _rejectFieldOrder = [];
  final Map<String, String> _fieldKeyToLabel = {};
  final TextEditingController _rejectRemarkController = TextEditingController();
  bool _isRadioSelected = false;

  static const Color _primary = Color(0xFF1A56DB);
  static const Color _secondary = Color(0xFF3B82F6);
  static const Color _bg = Color(0xFFF0F4FF);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMid = Color(0xFF64748B);
  static const Color _rowBorder = Color(0xFFC7D2FE);

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _savePageState();
    _rejectRemarkController.dispose();
    super.dispose();
  }

  void _initRejectFieldKeys(List<_SectionDef> sections) {
    _rejectFieldOrder.clear();
    _fieldKeyToLabel.clear();
    for (final section in sections) {
      for (final field in section.fields) {
        _rejectFieldOrder.add(field.fieldKey);
        _fieldKeyToLabel[field.fieldKey] = field.label;
      }
    }
  }

  void _toggleRejectField(String fieldKey, bool? checked) {
    setState(() {
      if (checked == true) {
        _checkedRejectFields.add(fieldKey);
      } else {
        _checkedRejectFields.remove(fieldKey);
      }
      _syncRejectRemark();
      _savePageState();
    });
  }

  void _syncRejectRemark() {
    final labels = <String>[];
    for (final key in _rejectFieldOrder) {
      if (_checkedRejectFields.contains(key)) {
        labels.add(_fieldKeyToLabel[key] ?? key);
      }
    }
    _rejectRemarkController.text = labels.join('\n');
  }

  String _remarkToSave() {
    if (_checkedRejectFields.isNotEmpty) {
      _syncRejectRemark();
    }
    return _rejectRemarkController.text.trim();
  }

  void _restorePageState() {
    final cached = _pageStateCache[widget.sp462];

    if (cached != null) {
      _expandedSections = Set<String>.from(cached.expandedSections);
      _checkedRejectFields.addAll(cached.checkedRejectFields);
      _isRadioSelected = cached.isRadioSelected;
      _rejectRemarkController.text = cached.rejectRemark;
    }
  }

  void _savePageState() {
    _pageStateCache[widget.sp462] = _ChallanScreenStateCache(
      expandedSections: Set<String>.from(_expandedSections),
      checkedRejectFields: Set<String>.from(_checkedRejectFields),
      isRadioSelected: _isRadioSelected,
      rejectRemark: _rejectRemarkController.text,
    );
  }

  Future<void> _initializePage() async {
    final uid = await ApiService.getUserId();
    loggedInUserId = uid ?? '';
    _restorePageState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getChallanEditDetails(widget.sp462);
      if (data == null) {
        throw Exception("No data returned for this challan.");
      }
      final l10n = AppLocalizations.of(context)!;
      final sections = _buildSectionsFromData(data, l10n);
      setState(() {
        _data = data;
        _loading = false;

        _initRejectFieldKeys(sections);
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is String && value.isEmpty) return '-';
    return value.toString();
  }

  String? _summary(String template) {
    final text = template.trim();
    if (text.isEmpty || text.endsWith(': -') || text.endsWith(':-')) {
      return null;
    }
    return text;
  }

  List<_SectionDef> _buildSections() {
    final l10n = AppLocalizations.of(context)!;
    return _buildSectionsFromData(_data!, l10n);
  }

  String _t(String key) {
    final code = Localizations.localeOf(context).languageCode;
    return _uiText[code]?[key] ?? _uiText['en']![key] ?? key;
  }

  List<_SectionDef> _buildSectionsFromData(
    Map<String, dynamic> d,
    AppLocalizations l10n,
  ) {
    const basic = 'Basic Information';
    const pricing = 'Pricing Details';
    const discounts = 'Discounts & Offers';
    const discount = 'Discount';
    const rto = 'RTO Details';
    const tax = 'Tax Details';
    const insurance = 'Insurance Details';
    const financial = 'Financial Details';
    const customer = 'Customer Information';

    return [
      _SectionDef(
        title: basic,
        summary: _summary('${_t('customerLabel')}: ${_formatValue(d['customername'])}'),
        icon: Icons.info_outline_rounded,
        iconColor: const Color(0xFF3B82F6),
        fields: [
          _FieldData(basic, 'Date', _formatValue(d['cdate'])),
          _FieldData(
            basic,
            'Challan No',
            _formatValue(d['challanno']),
            highlight: true,
          ),
          _FieldData(basic, 'Customer Name', _formatValue(d['customername'])),
          _FieldData(basic, 'Model Name', _formatValue(d['modelname'])),
          _FieldData(basic, 'Variant Name', _formatValue(d['variantname'])),
          _FieldData(basic, 'Color Name', _formatValue(d['colorname'])),
          _FieldData(basic, 'Sales Consultant', _formatValue(d['scname'])),
          _FieldData(basic, 'Team Leader', _formatValue(d['tlname'])),
          _FieldData(basic, 'VIN No', _formatValue(d['vinno'])),
          _FieldData(basic, 'Engine No', _formatValue(d['engineno'])),
        ],
      ),
      _SectionDef(
        title: pricing,
        summary: _summary('${_t('exShowroomLabel')}: ${_formatValue(d['ExshowRoomPrice'])}'),
        icon: Icons.attach_money_rounded,
        iconColor: const Color(0xFF10B981),
        fields: [
          _FieldData(
            pricing,
            'Ex-Showroom Price',
            _formatValue(d['ExshowRoomPrice']),
          ),
          _FieldData(pricing, 'Fasttag', _formatValue(d['fasttag'])),
          _FieldData(
            pricing,
            'Handling Charge',
            _formatValue(d['handlingchrg']),
          ),
          _FieldData(pricing, 'TCS', _formatValue(d['tcs'])),
          _FieldData(pricing, 'TRC', _formatValue(d['trc'])),
          _FieldData(pricing, 'Accessories', _formatValue(d['Accessories'])),
          _FieldData(
            pricing,
            'Additional Warranty',
            _formatValue(d['AdditionalWarranty']),
          ),
          _FieldData(pricing, 'Warranty Year', _formatValue(d['WarrantyYear'])),
          _FieldData(
            pricing,
            'Warranty Amount',
            _formatValue(d['WarrantyAmount']),
          ),
        ],
      ),
      _SectionDef(
        title: discounts,
        summary: _summary('${_t('corporateLabel')}: ${_formatValue(d['Corporateyn'])}'),
        icon: Icons.local_offer_rounded,
        iconColor: const Color(0xFFF59E0B),
        fields: [
          _FieldData(
            discounts,
            'Corporate Y/N',
            _formatValue(d['Corporateyn']),
          ),
          _FieldData(
            discounts,
            'Corporate Amount',
            _formatValue(d['Corporateamount']),
          ),
          _FieldData(
            discounts,
            'Corporate Given',
            _formatValue(d['Corporategiven']),
          ),
          _FieldData(discounts, 'Exchange Y/N', _formatValue(d['Exchangeyn'])),
          _FieldData(
            discounts,
            'Exchange Amount',
            _formatValue(d['Exchangeamount']),
          ),
          _FieldData(
            discounts,
            'Exchange Given',
            _formatValue(d['Exchangegiven']),
          ),
          _FieldData(discounts, 'Loyalty Y/N', _formatValue(d['Loyalityyn'])),
          _FieldData(
            discounts,
            'Loyalty Amount',
            _formatValue(d['Loyalityamount']),
          ),
          _FieldData(
            discounts,
            'Loyalty Given',
            _formatValue(d['Loyalitygiven']),
          ),
          _FieldData(discounts, 'Dealer Y/N', _formatValue(d['dealeryn'])),
          _FieldData(
            discounts,
            'Dealer Amount',
            _formatValue(d['dealeramount']),
          ),
          _FieldData(discounts, 'Dealer Given', _formatValue(d['dealergiven'])),
        ],
      ),
      _SectionDef(
        title: discount,
        summary: _summary('${_t('subtotalLabel')}: ${_formatValue(d['subtotal'])}'),
        icon: Icons.discount_rounded,
        iconColor: const Color(0xFFEC4899),
        fields: [
          _FieldData(
            discount,
            'Ex-Showroom Price',
            _formatValue(d['ExshowRoomPrice']),
          ),
          _FieldData(
            discount,
            'Less of All Encashment Scheme',
            _formatValue(d['lessofallencashmentschemne']),
            critical: true,
          ),
          _FieldData(discount, 'Subtotal', _formatValue(d['subtotal'])),
        ],
      ),
      _SectionDef(
        title: rto,
        summary: _summary('${_t('rtoAmountLabel')}: ${_formatValue(d['RTOAmount'])}'),
        icon: Icons.directions_car_rounded,
        iconColor: const Color(0xFF8B5CF6),
        fields: [
          _FieldData(rto, 'RTO Rate', _formatValue(d['RTORate'])),
          _FieldData(
            rto,
            'RTO Tax Surcharge',
            _formatValue(d['RTOTaxSurcharge']),
          ),
          _FieldData(rto, 'Green Tax', _formatValue(d['GreenTax'])),
          _FieldData(rto, 'Reg Fee', _formatValue(d['RegFee'])),
          _FieldData(rto, 'HPN', _formatValue(d['HPN']), critical: true),
          _FieldData(rto, 'Duplicate', _formatValue(d['Duplicate'])),
          _FieldData(rto, 'Smart Card', _formatValue(d['SmartCard'])),
          _FieldData(rto, 'Other', _formatValue(d['Other'])),
          _FieldData(rto, 'RTO Amount', _formatValue(d['RTOAmount'])),
          _FieldData(rto, 'RTO City', _formatValue(d['rtocity'])),
          _FieldData(rto, 'RTO From', _formatValue(d['rtofrom'])),
          _FieldData(rto, 'RTO Temp', _formatValue(d['RTO TEMP'])),
        ],
      ),
      _SectionDef(
        title: tax,
        summary: _summary('${_t('subtotalLabel')}: ${_formatValue(d['subtotal'])}'),
        icon: Icons.receipt_rounded,
        iconColor: const Color(0xFFEC4899),
        fields: [
          _FieldData(tax, 'GST', _formatValue(d['GST'])),
          _FieldData(tax, 'CESS', _formatValue(d['CESS'])),
          _FieldData(tax, 'SGST', _formatValue(d['sgst'])),
          _FieldData(tax, 'CGST', _formatValue(d['cgst'])),
          _FieldData(tax, 'GST Percentage', _formatValue(d['GSTPercentage'])),
          _FieldData(tax, 'GST Amount', _formatValue(d['GSTAmount'])),
          _FieldData(tax, 'Subtotal', _formatValue(d['subtotal'])),
          _FieldData(tax, 'Amount', _formatValue(d['Amount'])),
        ],
      ),
      _SectionDef(
        title: insurance,
        summary: _summary('${_t('insuranceAmtLabel')}: ${_formatValue(d['insamt'])}'),
        icon: Icons.security_rounded,
        iconColor: const Color(0xFF06B6D4),
        fields: [
          _FieldData(insurance, 'IDV', _formatValue(d['Idv'])),
          _FieldData(insurance, 'IDV Amount', _formatValue(d['IdvAmount'])),
          _FieldData(
            insurance,
            'Insurance Percentage',
            _formatValue(d['InsurancePercentage']),
          ),
          _FieldData(
            insurance,
            'Insurance Per Amount',
            _formatValue(d['InsperAmount']),
          ),
          _FieldData(
            insurance,
            'Discount Percentage',
            _formatValue(d['DiscountPrecentage']),
          ),
          _FieldData(
            insurance,
            'Discount Amount',
            _formatValue(d['DiscountAmount']),
            critical: true,
          ),
          _FieldData(insurance, 'Third Party', _formatValue(d['ThirdParty'])),
          _FieldData(insurance, 'PA Cover', _formatValue(d['PACover'])),
          _FieldData(insurance, 'ZD', _formatValue(d['ZD'])),
          _FieldData(insurance, 'PB', _formatValue(d['PB'])),
          _FieldData(insurance, 'KP', _formatValue(d['KP'])),
          _FieldData(insurance, 'Paid Driver', _formatValue(d['PaidDriver'])),
          _FieldData(
            insurance,
            'Insurance Amount',
            _formatValue(d['InsuranceAmount']),
          ),
          _FieldData(
            insurance,
            'Insurance Company',
            _formatValue(d['inscmpy']),
          ),
          _FieldData(insurance, 'Policy', _formatValue(d['policy'])),
          _FieldData(
            insurance,
            'Insurance Issue Date',
            _formatValue(d['insissuedate']),
          ),
          _FieldData(insurance, 'Insurance Amt', _formatValue(d['insamt'])),
          _FieldData(insurance, 'Insurance Type', _formatValue(d['instype'])),
          _FieldData(
            insurance,
            'Insurance Showroom',
            _formatValue(d['insshowroom']),
          ),
          _FieldData(
            insurance,
            'Previous Insurance Amt',
            _formatValue(d['preinsamt']),
          ),
          _FieldData(insurance, 'NCB', _formatValue(d['NCB'])),
        ],
      ),
      _SectionDef(
        title: financial,
        summary: _summary('${_t('netAmountLabel')}: ${_formatValue(d['netamount'])}'),
        icon: Icons.account_balance_rounded,
        iconColor: const Color(0xFFEF4444),
        fields: [
          _FieldData(
            financial,
            'Net Amount',
            _formatValue(d['netamount']),
            critical: true,
          ),
          _FieldData(
            financial,
            'Less of All Encashment Scheme',
            _formatValue(d['lessofallencashmentschemne']),
            critical: true,
          ),
          _FieldData(
            financial,
            'Hypothecation',
            _formatValue(d['hypothecationname']),
          ),
          _FieldData(financial, 'Bank Name', _formatValue(d['bankname'])),
          _FieldData(
            financial,
            'Bank Amount',
            _formatValue(d['bankamt']),
            critical: true,
          ),
          _FieldData(
            financial,
            'Finance Amount',
            _formatValue(d['financeamt']),
            critical: true,
          ),
          _FieldData(financial, 'Finance Type', _formatValue(d['financetype'])),
          _FieldData(financial, 'Bank Due', _formatValue(d['bankdue'])),
          _FieldData(financial, 'Customer Due', _formatValue(d['custdue'])),
          _FieldData(financial, 'Customer Receive', _formatValue(d['crecive'])),
          _FieldData(financial, 'Finance Receive', _formatValue(d['freceive'])),
          _FieldData(financial, 'RC Amount', _formatValue(d['rcamt'])),
          _FieldData(financial, 'Balance', _formatValue(d['bal'])),
        ],
      ),
      _SectionDef(
        title: customer,
        summary: _summary('${_t('mobileLabel')}: ${_formatValue(d['mobileno'])}'),
        icon: Icons.person_rounded,
        iconColor: const Color(0xFF6366F1),
        fields: [
          _FieldData(customer, 'Address', _formatValue(d['address'])),
          _FieldData(customer, 'Father Name', _formatValue(d['fathername'])),
          _FieldData(customer, 'Mobile No', _formatValue(d['mobileno'])),
          _FieldData(customer, 'Aadhar Card', _formatValue(d['aadharcard'])),
          _FieldData(customer, 'PAN No', _formatValue(d['panno'])),
          _FieldData(customer, 'Nominee Name', _formatValue(d['nomineename'])),
          _FieldData(customer, 'Age', _formatValue(d['age'])),
          _FieldData(customer, 'Relation', _formatValue(d['relation'])),
          _FieldData(customer, 'GSTIN', _formatValue(d['gstin'])),
          _FieldData(customer, 'Title', _formatValue(d['title'])),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: _loading
                ? _buildLoader(l10n)
                : _error != null
                ? _buildError(l10n)
                : _buildContent(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A8F), _primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x551A56DB),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 18),
          child: Row(
            children: [
              _headerIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
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
                  Icons.description_rounded,
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
                      _t('challanDetails'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      '${_t('challanNoLabel')}: ${widget.challanNo}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              _headerIconButton(icon: Icons.refresh_rounded, onTap: _loadData),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildLoader(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: CircularProgressIndicator(strokeWidth: 3.5, color: _primary),
          ),
          SizedBox(height: 18),
          Text(
            _t('loadingChallanDetails'),
            style: TextStyle(
              fontSize: 14,
              color: _textMid,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n) {
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
                color: Color(0xFFFFEBEE),
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
              _t('failedToLoadDetails'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: _textMid),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsCard(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _rowBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _isRadioSelected = !_isRadioSelected;
            if (!_isRadioSelected) {
              _checkedRejectFields.clear();
              _rejectRemarkController.clear();
            }
            _savePageState();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRadioSelected
                        ? _primary
                        : _textMid.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width: _isRadioSelected ? 10 : 0,
                    height: _isRadioSelected ? 10 : 0,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('showSelectionCheckboxes'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      _t('enableCheckboxesHelp'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textMid,
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

  Widget _buildContent(AppLocalizations l10n) {
    if (_data == null) return const SizedBox.shrink();

    final sections = _buildSections();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              children: [
                _buildControlsCard(l10n),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _rowBorder, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < sections.length; i++)
                        _buildSection(
                          section: sections[i],
                          showDivider: i < sections.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_checkedRejectFields.isNotEmpty) _buildRejectRemarkPreview(l10n),
        _buildActionButtons(l10n),
      ],
    );
  }

  Widget _buildRejectRemarkPreview(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(width: 6),
              Text(
                '${_t('rejectRemarkTitle')} (${_checkedRejectFields.length} field${_checkedRejectFields.length == 1 ? '' : 's'})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _rejectRemarkController.text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required _SectionDef section,
    required bool showDivider,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedSections.contains(section.title);

    final hasCriticalField = section.fields.any((f) => f.critical);
    final summaryMaxWidth = MediaQuery.of(context).size.width < 700
        ? 130.0
        : 460.0;

    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey('${section.title}-$isExpanded'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: EdgeInsets.zero,
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasCriticalField
                        ? const Color(0xFFFFE5E5)
                        : section.iconColor.withValues(alpha: 0.1),

                    borderRadius: BorderRadius.circular(8),

                    border: hasCriticalField
                        ? Border.all(color: const Color(0xFFFF6B6B), width: 1.2)
                        : null,
                  ),

                  child: Icon(
                    section.icon,
                    color: hasCriticalField
                        ? const Color(0xFFDC2626)
                        : section.iconColor,
                    size: 20,
                  ),
                ),

                if (hasCriticalField)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),

                      child: const Icon(
                        Icons.priority_high,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              _localizedSectionTitle(l10n, section.title),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,

                color: hasCriticalField ? const Color(0xFFB91C1C) : _textDark,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (section.summary != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: summaryMaxWidth),
                    child: Text(
                      section.summary!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                  ),
                if (section.summary != null) const SizedBox(width: 6),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                if (expanded) {
                  _expandedSections.add(section.title);
                } else {
                  _expandedSections.remove(section.title);
                }

                _savePageState();
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: _rowBorder, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < section.fields.length; i++)
                        _SectionFieldRow(
                          field: section.fields[i],
                          isEven: i % 2 == 0,
                          isLast: i == section.fields.length - 1,
                          isChecked: _checkedRejectFields.contains(
                            section.fields[i].fieldKey,
                          ),
                          onCheckChanged: (v) =>
                              _toggleRejectField(section.fields[i].fieldKey, v),
                          showCheckbox: _isRadioSelected,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: _rowBorder),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _onReject,
                icon: const Icon(Icons.close_rounded, size: 20),
                label: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_t('reject')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _processing ? null : _onApprove,
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: _processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_t('approve')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApprove() async {
    if (_data == null) return;

    setState(() => _processing = true);

    try {
      final approvalData = _prepareDataForSubmission(_data!);
      approvalData['loginUserId'] = loggedInUserId;
      approvalData['sp_583'] = loggedInUserId;
      approvalData['sp_584'] = await ApiService.getClientIp();

      final result = await ApiService.approveChallan(approvalData);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          content: Text(result['message'] ?? 'Challan approved successfully'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _onReject() async {
    if (_data == null) return;
    final l10n = AppLocalizations.of(context)!;

    _syncRejectRemark();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _RejectDialog(
        remarkController: _rejectRemarkController,
        onSyncFromChecks: _syncRejectRemark,
        hasCheckedFields: _checkedRejectFields.isNotEmpty,
        rejectChallanText: _t('rejectChallan'),
        checkedFieldInfoText: _t('checkedFieldInfo'),
        rejectRemarkHintText: _t('rejectRemarkHint'),
        rejectText: _t('reject'),
        pleaseSelectFieldOrReasonText: _t('pleaseSelectFieldOrReason'),
        cancelText: l10n.cancel,
      ),
    );

    if (confirmed != true) return;

    final remark = _remarkToSave();

    if (remark.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('pleaseSelectFieldOrReason'),
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _processing = true);

    try {
      final rejectionData = _prepareDataForSubmission(_data!);
      rejectionData['loginUserId'] = loggedInUserId;
      rejectionData['sp_587'] = loggedInUserId;
      rejectionData['sp_588'] = await ApiService.getClientIp();
      rejectionData['sp_581'] = remark;

      final result = await ApiService.rejectChallan(rejectionData, remark);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(result['message'] ?? 'Challan rejected successfully'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Map<String, dynamic> _prepareDataForSubmission(Map<String, dynamic> data) {
    final prepared = Map<String, dynamic>.from(data);
    if (prepared['sp_462'] == null && prepared['unq'] != null) {
      prepared['sp_462'] = prepared['unq'];
    }
    return prepared;
  }

  String _localizedSectionTitle(AppLocalizations l10n, String titleKey) {
    switch (titleKey) {
      case 'Basic Information':
        return _t('basicInformation');
      case 'Pricing Details':
        return _t('pricingDetails');
      case 'Discounts & Offers':
        return _t('discountsAndOffers');
      case 'Discount':
        return _t('discountTitle');
      case 'RTO Details':
        return _t('rtoDetails');
      case 'Tax Details':
        return _t('taxDetails');
      case 'Insurance Details':
        return _t('insuranceDetails');
      case 'Financial Details':
        return _t('financialDetails');
      case 'Customer Information':
        return _t('customerInformation');
      default:
        return titleKey;
    }
  }
}

class _SectionDef {
  final String title;
  final String? summary;
  final IconData icon;
  final Color iconColor;
  final List<_FieldData> fields;

  const _SectionDef({
    required this.title,
    this.summary,
    required this.icon,
    required this.iconColor,
    required this.fields,
  });
}

class _FieldData {
  final String sectionTitle;
  final String label;
  final String value;
  final bool highlight;
  final bool critical;

  String get fieldKey => '$sectionTitle::$label';

  const _FieldData(
    this.sectionTitle,
    this.label,
    this.value, {
    this.highlight = false,
    this.critical = false,
  });
}

class _SectionFieldRow extends StatelessWidget {
  static const Color _borderColor = Color(0xFFC7D2FE);
  static const Color _evenRowColor = Colors.white;
  static const Color _oddRowColor = Color(0xFFEAF1FF);
  static const Color _textDark = Color(0xFF1E293B);
  static const Color _textMid = Color(0xFF64748B);
  static const Color _primary = Color(0xFF1A56DB);

  final _FieldData field;
  final bool isEven;
  final bool isLast;
  final bool isChecked;
  final ValueChanged<bool?> onCheckChanged;
  final bool showCheckbox;

  const _SectionFieldRow({
    required this.field,
    required this.isEven,
    required this.isLast,
    required this.isChecked,
    required this.onCheckChanged,
    required this.showCheckbox,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? _evenRowColor : _oddRowColor,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : const BorderSide(color: _borderColor, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showCheckbox)
            SizedBox(
              width: 44,
              child: Checkbox(
                value: isChecked,
                onChanged: onCheckChanged,
                activeColor: _primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: _borderColor, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Text(
                field.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _textMid,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: field.highlight
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          field.value,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  : field.critical
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFFFE5E5), Color(0xFFFFF3E0)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFFFF6B6B),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),

                            const SizedBox(width: 4),

                            Text(
                              field.value,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Text(
                      field.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  final TextEditingController remarkController;
  final VoidCallback onSyncFromChecks;
  final bool hasCheckedFields;
  final String rejectChallanText;
  final String checkedFieldInfoText;
  final String rejectRemarkHintText;
  final String rejectText;
  final String pleaseSelectFieldOrReasonText;
  final String cancelText;

  const _RejectDialog({
    required this.remarkController,
    required this.onSyncFromChecks,
    required this.hasCheckedFields,
    required this.rejectChallanText,
    required this.checkedFieldInfoText,
    required this.rejectRemarkHintText,
    required this.rejectText,
    required this.pleaseSelectFieldOrReasonText,
    required this.cancelText,
  });

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.hasCheckedFields) {
        widget.onSyncFromChecks();
      }
      setState(() {});
    });
  }

  void _submit() {
    if (widget.hasCheckedFields) {
      widget.onSyncFromChecks();
    }

    final remark = widget.remarkController.text.trim();
    if (remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.pleaseSelectFieldOrReasonText,
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.warning_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Text(
            widget.rejectChallanText,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.checkedFieldInfoText,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.remarkController,
            maxLines: 5,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.rejectRemarkHintText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(widget.cancelText),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text(widget.rejectText),
        ),
      ],
    );
  }
}
