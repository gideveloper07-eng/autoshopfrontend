import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class FinanceDetailsScreen extends StatefulWidget {
  const FinanceDetailsScreen({super.key, this.financeId});

  final String? financeId;

  @override
  State<FinanceDetailsScreen> createState() => _FinanceDetailsScreenState();
}

class _FinanceDetailsScreenState extends State<FinanceDetailsScreen> {
  static const _primary = Color(0xFF2468D7);
  static const _navy = Color(0xFF164A96);
  static const _blueLight = Color(0xFF3478EA);

  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _entryDate = TextEditingController();
  final _contact = TextEditingController();
  final _address = TextEditingController();
  final _tl = TextEditingController();
  final _sc = TextEditingController();
  final _model = TextEditingController();
  final _variant = TextEditingController();
  final _colour = TextEditingController();
  final _bookingDate = TextEditingController();
  final _loanAmount = TextEditingController(text: '0');
  final _concerningName = TextEditingController();
  final _concerningMobile = TextEditingController(text: '0');
  final _financeDate = TextEditingController();
  final _expectedDelivery = TextEditingController();
  final _remark = TextEditingController();
  final _companyBranch = TextEditingController();
  final _disbursedAmount = TextEditingController(text: '0');
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _showCustomerMatches = false;

  String? _error;
  String? _selectedCustomerId;
  String? _financeId;
  String? _receiptId;
  String? _tlId;
  String? _scId;
  String? _modelId;
  String? _variantId;
  String? _colourId;
  String? _selectedBankId;
  String? _selectedBranchId;
  String? _companyBranchId;

  String _financeArrangement = 'In';
  String _status = 'Pending';
  String _doUpload = '';
  String? _pickedFileName;
  String? _uploadStatus;
  bool _uploadFailed = false;

  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _history = [];

  String _read(Map<String, dynamic>? row, String key, [String fallback = '']) {
    if (row == null) return fallback;

    for (final entry in row.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        final value = entry.value;

        if (value == null) return fallback;

        final text = value.toString().trim();

        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
    }

    return fallback;
  }

  String _first(
    Map<String, dynamic>? row,
    List<String> keys, [
    String fallback = '',
  ]) {
    for (final key in keys) {
      final value = _read(row, key);

      if (value.isNotEmpty) return value;
    }

    return fallback;
  }

  String _normaliseId(String value) =>
      value.trim().replaceAll('{', '').replaceAll('}', '').toLowerCase();

  bool _sameOption(String a, String b) {
    if (a.trim().isEmpty || b.trim().isEmpty) return false;
    return _normaliseId(a) == _normaliseId(b);
  }

  // The finance API can return either the stored ID or its display label in
  // an edit row. Resolve either form to the ID used by the dropdown.
  String? _resolveOptionId(
    List<Map<String, dynamic>> rows,
    String suppliedValue, {
    List<String> idKeys = const ['data', 'id', 'value'],
    List<String> labelKeys = const ['value', 'name', 'label'],
  }) {
    if (suppliedValue.trim().isEmpty) return null;
    for (final row in rows) {
      final id = _first(row, idKeys);
      final label = _first(row, labelKeys);
      if (_sameOption(suppliedValue, id) || _sameOption(suppliedValue, label)) {
        return id.isNotEmpty ? id : label;
      }
    }
    return suppliedValue;
  }

  Future<Map<String, dynamic>> _requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final token = await ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing. Please sign in again.');
    }

    final uri = Uri.parse('${ApiService.baseUrl}/api/finance$path');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    late http.Response response;

    if (method == 'POST') {
      response = await http
          .post(uri, headers: headers, body: jsonEncode(body ?? {}))
          .timeout(const Duration(seconds: 45));
    } else {
      response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 45));
    }

    Map<String, dynamic> decoded;

    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Server returned an invalid response '
        '(${response.statusCode}).',
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Request failed (${response.statusCode}).',
      );
    }

    return decoded;
  }

  List<Map<String, dynamic>> _asRows(dynamic value) {
    // Supports Express/MSSQL payloads such as:
    // [...], {recordset:[...]}, {recordsets:[[...]]},
    // {rows:[...]}, {data:[...]}, and nested {data:{recordset:[...]}}.
    dynamic source = value;
    for (var depth = 0; depth < 5; depth++) {
      if (source is List) {
        // node-mssql `recordsets` is a list of result sets. Use the first
        // result set when the response wraps that list one level deeper.
        if (source.isNotEmpty && source.first is List) {
          source = source.first;
          continue;
        }
        break;
      }
      if (source is Map) {
        dynamic next;
        for (final key in [
          'recordset',
          'recordSet',
          'recordsets',
          'rows',
          'items',
          'result',
          'data',
          'results',
        ]) {
          for (final entry in source.entries) {
            if (entry.key.toString().toLowerCase() == key.toLowerCase() &&
                entry.value != null) {
              next = entry.value;
              break;
            }
          }
          if (next != null) break;
        }
        if (next == null || identical(next, source)) break;
        source = next;
        continue;
      }
      break;
    }
    if (source is! List) return [];
    return source
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String _bankId(Map<String, dynamic> row) => _first(row, [
    'data',
    'valueId',
    'bankId',
    'financerId',
    'hp_2',
    'sp_602',
    'id',
    'value',
    'code',
  ]);

  String _bankLabel(Map<String, dynamic> row) => _first(row, [
    'value',
    'label',
    'name',
    'bankName',
    'financerName',
    'financer',
    'hpn',
    'hp_7',
    'sp_607',
    'description',
    'data',
  ], 'Unnamed financer');

  String _branchId(Map<String, dynamic> row) => _first(row, [
    'data',
    'branchId',
    'financerBranchId',
    'hp_c_2',
    'sp_602',
    'id',
    'value',
    'code',
  ]);

  String _branchLabel(Map<String, dynamic> row) => _first(row, [
    'value',
    'label',
    'name',
    'branchName',
    'branch_name',
    'branch',
    'hp_c_3',
    'sp_607',
    'description',
    'data',
  ], 'Unnamed branch');

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _entryDate.text =
        '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    _financeDate.text = _formatDate(now);
    _expectedDelivery.text = _formatDate(now);
    _financeId = widget.financeId;

    _loadInitial();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Load each list independently. A customer-list failure must not stop
      // the financer dropdown from loading (and vice versa).
      Object? customerError;
      Object? bankError;
      try {
        final response = await _requestJson('/customers');
        _customers = _asRows(response['data']);
        debugPrint('FINANCE /customers rows: ${_customers.length}');
      } catch (e) {
        customerError = e;
        debugPrint('FINANCE /customers ERROR: $e');
      }
      try {
        final response = await _requestJson('/banks');
        _banks = _asRows(response['data']);
        debugPrint('FINANCE /banks rows: ${_banks.length}');
        if (_banks.isNotEmpty) {
          debugPrint('FINANCE /banks first row: ${_banks.first}');
        }
      } catch (e) {
        bankError = e;
        debugPrint('FINANCE /banks ERROR: $e');
      }
      if (_customers.isEmpty && customerError != null) {
        throw Exception('Unable to load customers: $customerError');
      }
      if (_banks.isEmpty && bankError != null) {
        // Keep the screen usable to inspect customer data; show the actual
        // financer API error in the console and in the empty dropdown label.
        debugPrint('Financer list unavailable: $bankError');
      }

      if (_financeId != null && _financeId!.isNotEmpty) {
        final edit = await _requestJson(
          '/edit/${Uri.encodeComponent(_financeId!)}',
        );

        final row = edit['data'] is Map
            ? Map<String, dynamic>.from(edit['data'])
            : null;

        if (row != null) _applyEditRow(row);
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _applyEditRow(Map<String, dynamic> row) {
    _financeId = _first(row, ['sp_672', 'financeId'], _financeId ?? '');

    _selectedCustomerId = _first(row, ['sp_678', 'customerId']);

    _customerController.text = _customerName(row);

    _entryDate.text = _first(row, ['sp_677', 'entryDate'], _entryDate.text);

    _contact.text = _first(row, ['sp_679', 'contact', 'contactno']);

    _address.text = _first(row, ['sp_680', 'address']);

    _tl.text = _first(row, ['tl', 'TLName', 'sp_681']);

    _sc.text = _first(row, ['sc', 'SCName', 'sp_682']);

    _model.text = _first(row, ['model', 'modelname', 'sp_683']);

    _variant.text = _first(row, ['variant', 'varname', 'sp_684']);

    _colour.text = _first(row, ['color', 'colorname', 'sp_685']);

    _bookingDate.text = _first(row, ['bookingdate', 'sp_686']);

    _financeArrangement = _first(row, ['sp_687', 'financeArrangement'], 'In');

    final savedFinancer = _first(row, [
      'sp_688',
      'financerId',
      'bankId',
      'financer',
      'bankName',
    ]);
    _selectedBankId = _resolveOptionId(
      _banks,
      savedFinancer,
      idKeys: const ['data', 'hp_2', 'id', 'value'],
      labelKeys: const ['value', 'hp_7', 'name', 'bankName'],
    );

    _selectedBranchId = _first(row, [
      'sp_689',
      'branchId',
      'financerBranchId',
      'financerBranch',
      'branchName',
    ]);

    _concerningName.text = _first(row, ['sp_690', 'concerningName']);

    _concerningMobile.text = _first(row, ['sp_691', 'concerningMobile'], '0');

    _status = _first(row, ['sp_692', 'status'], 'Pending');

    _financeDate.text = _first(row, [
      'sp_693',
      'financeDate',
    ], _financeDate.text);

    _remark.text = _first(row, ['sp_694', 'remark']);

    _receiptId = _first(row, ['sp_695', 'receiptId']);

    _loanAmount.text = _first(row, ['sp_696', 'loanAmount'], '0');

    _expectedDelivery.text = _first(row, [
      'sp_697',
      'expectedDelivery',
    ], _expectedDelivery.text);

    _doUpload = _first(row, ['sp_698', 'DOUPLOAD']);

    _companyBranchId = _first(row, ['sp_699', 'companyBranchId']);

    // Prefer an actual branch name returned by the edit API. If only the
    // stored branch ID is present, resolve its display name through the
    // company-branch endpoint below.
    _companyBranch.text = _first(row, [
      'companyBranchName',
      'company_branch_name',
      'branchOfCompanyName',
      'branchName',
      'branch_name',
      'companyBranch',
      'branchOfCompany',
      'sp_607',
    ]);

    if (_selectedCustomerId != null && _selectedCustomerId!.isNotEmpty) {
      _loadCompanyBranch(
        _selectedCustomerId!,
        preferredBranchId: _companyBranchId,
      );
    }

    _disbursedAmount.text = _first(row, ['sp_700', 'disbursedAmount'], '0');

    _loadBranches(
      _selectedBankId,
      selectedBranchId: _selectedBranchId,
      reloadHistory: false,
    );

    if (_financeId != null && _financeId!.isNotEmpty) {
      _loadHistory(_financeId!);
    }
  }

  Future<void> _selectCustomer(Map<String, dynamic> row) async {
    final customerId = _first(row, [
      'data',
      'customerId',
      'customerid',
      'sp_678',
      'id',
    ]);
    if (customerId.isEmpty) {
      _showMessage(
        'The selected customer response does not contain a customer ID.',
        error: true,
      );
      return;
    }
    _selectedCustomerId = customerId;

    // Clear the previous customer's company branch immediately. This avoids
    // displaying or saving stale branch information while the new branch is
    // being loaded.
    _companyBranchId = null;
    _companyBranch.clear();

    _financeId = _first(row, ['sp_672', 'financeId', 'financeid']);

    _customerController.text = _customerName(row);

    _contact.text = _first(row, ['bo_24', 'contact', 'contactno']);

    _address.text = _first(row, ['bo_25', 'address']);

    _tl.text = _first(row, ['tl', 'teamLeader']);
    _sc.text = _first(row, ['sc', 'salesConsultant']);

    _tlId = _first(row, ['bo_21', 'tlId']);
    _scId = _first(row, ['bo_20', 'scId']);

    _model.text = _first(row, ['model']);
    _modelId = _first(row, ['bo_26', 'modelId']);

    _variant.text = _first(row, ['variant']);
    _variantId = _first(row, ['bo_27', 'variantId']);

    _colour.text = _first(row, ['color']);
    _colourId = _first(row, ['bo_28', 'colorId']);

    _bookingDate.text = _first(row, ['bo_17', 'bookingDate']);
    _receiptId = _first(row, ['bo_18', 'receiptId']);

    _financeArrangement = _first(row, ['sp_687'], 'In');
    // The @what='customer' stored procedure returns the selected financer as
    // sp_688 (ID) + hpn (display name), and branch as sp_689 (ID) + branch
    // (display name). Preserve these options even if the separate dropdown
    // endpoints do not include the currently saved financer/branch.
    _selectedBankId = _first(row, ['sp_688']);
    _selectedBranchId = _first(row, ['sp_689']);
    final customerFinancerName = _first(row, ['hpn', 'hp_7', 'financerName']);
    final customerBranchName = _first(row, ['branch', 'hp_c_3', 'branchName']);
    debugPrint(
      'FINANCE selected customer=$customerId, financerId=$_selectedBankId, branchId=$_selectedBranchId, financerName=$customerFinancerName, branchName=$customerBranchName',
    );

    if (_selectedBankId != null && _selectedBankId!.isNotEmpty) {
      final bankExists = _banks.any(
        (bank) => _sameOption(_bankId(bank), _selectedBankId!),
      );
      if (!bankExists) {
        _banks = [
          ..._banks,
          {
            'hp_2': _selectedBankId,
            'hp_7': customerFinancerName.isEmpty
                ? _selectedBankId!
                : customerFinancerName,
          },
        ];
      }
    }
    if (_selectedBranchId != null && _selectedBranchId!.isNotEmpty) {
      final branchExists = _branches.any(
        (branchRow) => _sameOption(_branchId(branchRow), _selectedBranchId!),
      );
      if (!branchExists) {
        _branches = [
          {
            'hp_c_2': _selectedBranchId,
            'hp_c_3': customerBranchName.isEmpty
                ? _selectedBranchId!
                : customerBranchName,
          },
        ];
      }
    }

    _concerningName.text = _first(row, ['sp_690']);
    _concerningMobile.text = _first(row, ['sp_691'], '0');

    _status = _first(row, ['sp_692'], 'Pending');

    _financeDate.text = _first(row, ['sp_693'], _formatDate(DateTime.now()));

    _remark.text = _first(row, ['sp_694']);

    _loanAmount.text = _first(row, ['sp_696'], '0');

    _expectedDelivery.text = _first(row, [
      'sp_697',
    ], _formatDate(DateTime.now()));

    _doUpload = _first(row, ['sp_698']);

    _disbursedAmount.text = _first(row, ['sp_700'], '0');

    setState(() => _showCustomerMatches = false);

    try {
      await _loadCompanyBranch(customerId);

      await _loadBranches(
        _selectedBankId,
        selectedBranchId: _selectedBranchId,
        reloadHistory: false,
      );

      if (_financeId != null && _financeId!.isNotEmpty) {
        await _loadHistory(_financeId!);
      } else if (mounted) {
        setState(() => _history = []);
      }
    } catch (e) {
      _showMessage(
        'Customer selected, but related dropdown data '
        'could not be loaded: $e',
        error: true,
      );
    }
  }

  Future<void> _loadCompanyBranch(
    String customerId, {
    String? preferredBranchId,
  }) async {
    try {
      final response = await _requestJson(
        '/company-branch/${Uri.encodeComponent(customerId)}',
      );
      final rows = _asRows(response['data']);

      if (!mounted) return;

      if (rows.isEmpty) {
        setState(() {
          _companyBranchId = preferredBranchId;
          // Preserve a readable name already returned by the edit endpoint.
          // For a newly selected customer this field was cleared before the
          // request, so a previous customer's branch cannot remain visible.
          if (_companyBranch.text.trim().isEmpty ||
              _companyBranch.text.trim() == preferredBranchId) {
            _companyBranch.clear();
          }
        });
        return;
      }

      // Stored procedure mapping: sp_607 is the display label (`data`)
      // and sp_602 is the stored branch ID (`value`).
      Map<String, dynamic> chosen = rows.first;
      if (preferredBranchId != null && preferredBranchId.isNotEmpty) {
        for (final candidate in rows) {
          final candidateId = _first(candidate, [
            'value',
            'sp_602',
            'companyBranchId',
            'id',
          ]);
          final candidateName = _first(candidate, [
            'data',
            'sp_607',
            'name',
            'branchName',
            'branch_name',
          ]);
          if (_sameOption(candidateId, preferredBranchId) ||
              _sameOption(candidateName, preferredBranchId)) {
            chosen = candidate;
            break;
          }
        }
      }

      final branchId = _first(chosen, [
        'value',
        'sp_602',
        'companyBranchId',
        'id',
        'data',
      ], preferredBranchId ?? '');

      // The stored procedure returns sp_607 AS data (display name) and
      // sp_602 AS value (branch ID). Prefer the display-name aliases first.
      final branchName = _first(chosen, [
        'data',
        'sp_607',
        'companyBranchName',
        'company_branch_name',
        'branchName',
        'branch_name',
        'name',
        'value',
      ], branchId);

      setState(() {
        _companyBranchId = branchId.isEmpty ? preferredBranchId : branchId;
        _companyBranch.text = branchName;
      });
    } catch (e) {
      // Keep any readable name already supplied by the edit/customer API.
      debugPrint('Unable to resolve company branch name: $e');
    }
  }

  Future<void> _loadBranches(
    String? bankId, {
    String? selectedBranchId,
    bool reloadHistory = true,
  }) async {
    if (bankId == null || bankId.isEmpty) {
      if (mounted) {
        setState(() {
          _branches = [];
          _selectedBankId = null;
          _selectedBranchId = null;
        });
      }
      return;
    }

    try {
      final response = await _requestJson(
        '/banks/${Uri.encodeComponent(bankId)}/branches',
      );

      final rows = _asRows(response['data']);
      debugPrint('FINANCE branches for bank $bankId rows: ${rows.length}');
      if (rows.isNotEmpty)
        debugPrint('FINANCE first branch row: ${rows.first}');
      final wanted = (selectedBranchId ?? _selectedBranchId ?? '').trim();
      String? resolvedBranchId;
      Map<String, dynamic>? existingSelectedBranch;
      for (final row in rows) {
        final id = _branchId(row);
        final label = _branchLabel(row);
        if (_sameOption(wanted, id) || _sameOption(wanted, label)) {
          resolvedBranchId = id.isNotEmpty ? id : label;
          existingSelectedBranch = row;
          break;
        }
      }

      // The customer stored procedure may already have returned the selected
      // branch even when the branch-list endpoint omits it. Keep that option
      // in the dropdown instead of clearing the saved branch selection.
      final mergedRows = List<Map<String, dynamic>>.from(rows);
      if (wanted.isNotEmpty && existingSelectedBranch == null) {
        final fallback = _branches.where(
          (item) => _sameOption(_branchId(item), wanted),
        );
        if (fallback.isNotEmpty) {
          mergedRows.add(fallback.first);
          resolvedBranchId = _branchId(fallback.first);
        }
      }

      if (mounted) {
        setState(() {
          _branches = mergedRows;
          _selectedBankId = bankId;
          _selectedBranchId = resolvedBranchId;
        });
      }

      if (reloadHistory && _financeId != null && _financeId!.isNotEmpty) {
        await _loadHistory(_financeId!);
      }
    } catch (e) {
      _showMessage('Unable to load branches: $e', error: true);
    }
  }

  Future<void> _loadHistory(String financeId) async {
    try {
      final response = await _requestJson(
        '/history/${Uri.encodeComponent(financeId)}',
      );

      if (mounted) {
        setState(() => _history = _asRows(response['data']));
      }
    } catch (e) {
      if (mounted) setState(() => _history = []);

      _showMessage('Unable to load finance history: $e', error: true);
    }
  }

  Future<void> _pickAndUploadDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _uploading = true;
        _uploadFailed = false;
        _pickedFileName = image.name;
        _uploadStatus = 'Preparing image for upload…';
      });

      final bytes = await image.readAsBytes();

      if (mounted) {
        setState(() => _uploadStatus = 'Uploading image to server…');
      }

      final token = await ApiService.getToken();

      final uri = Uri.parse('${ApiService.baseUrl}/api/finance/upload');

      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
        throw Exception('Please select a customer before uploading.');
      }

      request.fields['customerId'] = _selectedCustomerId!;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      final result = jsonDecode(response.body);

      debugPrint('FINANCE UPLOAD STATUS: ${response.statusCode}');
      debugPrint('FINANCE UPLOAD RESPONSE: ${response.body}');

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          result is! Map ||
          result['success'] != true) {
        throw Exception(
          result is Map
              ? result['message']?.toString() ?? 'Image upload failed.'
              : 'Invalid upload response from server.',
        );
      }

      final data = result['data'];

      String? serverPath;

      if (data is Map) {
        serverPath =
            (data['doUpload'] ??
                    data['path'] ??
                    data['DOUPLOAD'] ??
                    data['filePath'])
                ?.toString();
      }

      serverPath ??=
          (result['doUpload'] ??
                  result['path'] ??
                  result['DOUPLOAD'] ??
                  result['filePath'])
              ?.toString();

      if (serverPath == null ||
          serverPath.trim().isEmpty ||
          serverPath == 'null') {
        throw Exception(
          'Upload response did not contain a file path. '
          'Check the browser console for FINANCE UPLOAD RESPONSE.',
        );
      }

      if (!mounted) return;

      setState(() {
        _doUpload = serverPath!;
        _pickedFileName = image.name;
        _uploadStatus = 'Image uploaded successfully';
        _uploadFailed = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DO image uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _uploadFailed = true;
        _uploadStatus = 'Upload failed. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          if (_uploadStatus == null && _doUpload.isNotEmpty) {
            _uploadStatus = 'Image uploaded successfully';
          }
        });
      }
    }
  }

  Future<void> _save({bool exitAfterSave = false}) async {
    setState(() => _saving = true);

    try {
      final response = await _requestJson(
        '/save',
        method: 'POST',
        body: {
          'financeId': _financeId ?? '',
          'customerId': _selectedCustomerId ?? '',
          'entryDate': _entryDate.text.trim(),
          'contact': _contact.text.trim(),
          'address': _address.text.trim(),
          'tlId': _tlId ?? '',
          'scId': _scId ?? '',
          'modelId': _modelId ?? '',
          'variantId': _variantId ?? '',
          'colorId': _colourId ?? '',
          'bookingDate': _bookingDate.text.trim(),
          'financeArrangement': _financeArrangement,
          'financerId': _selectedBankId ?? '',
          'branchId': _selectedBranchId ?? '',
          'concerningName': _concerningName.text.trim(),
          'concerningMobile': _concerningMobile.text.trim().isEmpty
              ? '0'
              : _concerningMobile.text.trim(),

          'status': _status,
          'financeDate': _financeDate.text.trim(),
          'remark': _remark.text.trim(),
          'receiptId': _receiptId ?? '',
          'loanAmount': _loanAmount.text.trim().isEmpty
              ? '0'
              : _loanAmount.text.trim(),
          'expectedDelivery': _expectedDelivery.text.trim(),
          'doUpload': _doUpload,
          'companyBranchId': (_companyBranchId ?? '').trim(),
          'disbursedAmount': _disbursedAmount.text.trim().isEmpty
              ? '0'
              : _disbursedAmount.text.trim(),
        },
      );

      _showMessage(response['message']?.toString() ?? 'Finance details saved.');

      final returnedId = response['financeId']?.toString();

      if (returnedId != null && returnedId.isNotEmpty && returnedId != 'null') {
        _financeId = returnedId;
        await _loadHistory(returnedId);
      }

      // Return to the Finance Grid only after the save request succeeds.
      if (exitAfterSave && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _showMessage('Save failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _chooseDate(TextEditingController controller) async {
    final now = DateTime.now();
    DateTime initial = now;

    final parts = controller.text.split('/');

    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);

      if (d != null && m != null && y != null) {
        initial = DateTime(y, m, d);
      }
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
    );

    if (selected != null) {
      controller.text = _formatDate(selected);
    }

    if (mounted) setState(() {});
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fieldWidth = screenWidth < 600 ? double.infinity : 300.0;

    return SizedBox(
      width: fieldWidth,
      child: TextFormField(
        controller: controller,
        readOnly: readOnly || onTap != null,
        onTap: onTap,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? '$label is required'
                  : null
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.38
                    : 0.55,
              ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: .75),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          suffixIcon: onTap == null
              ? null
              : const Icon(Icons.calendar_month_outlined, size: 19),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .7 : .35,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = MediaQuery.sizeOf(context).width < 600;
              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i != children.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Wrap(spacing: 12, runSpacing: 12, children: children);
            },
          ),
        ],
      ),
    );
  }

  String _customerName(Map<String, dynamic> row) {
    // The stored procedure returns the customer name as `value` and the
    // customer GUID as `data`. Prefer name fields and never show the GUID as
    // the customer's display name unless the API truly has no name field.
    final name = _first(row, [
      'value',
      'customerName',
      'CustomerName',
      'customer',
      'Customer',
      'custname',
      'cust',
      'm1_7',
      'name',
      'sp_678_name',
    ]).trim();
    if (name.isNotEmpty) return name.replaceFirst(RegExp(r'^\s*[.·]+\s*'), '');
    return 'Customer name unavailable';
  }

  String _customerSearchText(Map<String, dynamic> row) => row.entries
      .map((e) => '${e.key} ${e.value ?? ''}')
      .join(' ')
      .toLowerCase();

  Future<void> _openCustomerPicker() async {
    final searchController = TextEditingController();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final matches = _customers.where((row) {
              if (query.isEmpty) return true;
              return _customerSearchText(row).contains(query) ||
                  _customerName(row).toLowerCase().contains(query);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 64,
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: MediaQuery.sizeOf(context).height * .78,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF172235) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select Customer',
                                style: TextStyle(
                                  color: isDark ? Colors.white : _navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          onChanged: (_) => setSheetState(() {}),
                          decoration: InputDecoration(
                            hintText:
                                'Search customer name, booking, model, mobile…',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF222F43)
                                : const Color(0xFFF5F6F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${matches.length} of ${_customers.length} customers',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: matches.isEmpty
                            ? const Center(child: Text('No matching customers'))
                            : ListView.separated(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: matches.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  indent: 18,
                                  endIndent: 18,
                                ),
                                itemBuilder: (context, index) {
                                  final row = matches[index];
                                  final name = _customerName(row);
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 4,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: _primary.withValues(
                                        alpha: .12,
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: _primary,
                                      ),
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    onTap: () =>
                                        Navigator.pop(sheetContext, row),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    // Let the bottom-sheet reverse animation finish before updating the
    // parent form. Rebuilding the parent while the modal route is still
    // deactivating can trigger Flutter's InheritedElement dependents assertion.
    if (selected != null && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    searchController.dispose();
    if (selected != null && mounted) {
      await _selectCustomer(selected);
    }
  }

  Widget _customerPicker() {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width < 600 ? double.infinity : 340,
      child: TextFormField(
        controller: _customerController,
        readOnly: true,
        onTap: _openCustomerPicker,
        decoration: InputDecoration(
          labelText: 'Customer Name',
          hintText: 'Tap to search and select customer',
          prefixIcon: const Icon(Icons.person_search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Choose customer',
                onPressed: _openCustomerPicker,
                icon: const Icon(Icons.search),
              ),
              if (_customerController.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear customer',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _customerController.clear();
                    _selectedCustomerId = null;
                    _financeId = null;
                    _receiptId = null;
                  }),
                ),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? .38
                    : .55,
              ),
        ),
      ),
    );
  }

  String _dropdownItemLabel(DropdownMenuItem<String> item) {
    final child = item.child;
    if (child is Text) return child.data ?? item.value ?? '';
    return item.value ?? '';
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final selectedItem = value == null
        ? null
        : items.cast<DropdownMenuItem<String>?>().firstWhere(
            (item) => item?.value != null && _sameOption(item!.value!, value),
            orElse: () => null,
          );
    final validValue = selectedItem?.value;
    final selectedLabel = selectedItem == null
        ? ''
        : _dropdownItemLabel(selectedItem);

    return SizedBox(
      width: screenWidth < 600 ? double.infinity : 300,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: items.isEmpty
            ? null
            : () async {
                final searchController = TextEditingController();
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (sheetContext) {
                    final isDark =
                        Theme.of(sheetContext).brightness == Brightness.dark;
                    return StatefulBuilder(
                      builder: (context, setSheetState) {
                        final query = searchController.text
                            .trim()
                            .toLowerCase();
                        final filteredItems = items.where((item) {
                          return _dropdownItemLabel(
                            item,
                          ).toLowerCase().contains(query);
                        }).toList();

                        return SafeArea(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: 70,
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: Container(
                              height: MediaQuery.sizeOf(context).height * .72,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF172235)
                                    : Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 10),
                                  Container(
                                    width: 42,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      16,
                                      12,
                                      10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Select $label',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF164A96),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Close',
                                          onPressed: () =>
                                              Navigator.pop(sheetContext),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    child: TextField(
                                      controller: searchController,
                                      autofocus: false,
                                      onChanged: (_) => setSheetState(() {}),
                                      decoration: InputDecoration(
                                        hintText: 'Search $label...',
                                        prefixIcon: const Icon(Icons.search),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF222F43)
                                            : const Color(0xFFF5F6F8),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 12,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      10,
                                      18,
                                      8,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '${filteredItems.length} results',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Divider(height: 1),
                                  Expanded(
                                    child: filteredItems.isEmpty
                                        ? const Center(
                                            child: Text('No matching results'),
                                          )
                                        : ListView.separated(
                                            itemCount: filteredItems.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                                  height: 1,
                                                  indent: 18,
                                                  endIndent: 18,
                                                ),
                                            itemBuilder: (context, index) {
                                              final item = filteredItems[index];
                                              final itemLabel =
                                                  _dropdownItemLabel(item);
                                              final isSelected =
                                                  item.value == validValue;
                                              return ListTile(
                                                title: Text(itemLabel),
                                                trailing: isSelected
                                                    ? const Icon(
                                                        Icons.check,
                                                        color: Color(
                                                          0xFF2468D7,
                                                        ),
                                                      )
                                                    : null,
                                                onTap: () => Navigator.pop(
                                                  sheetContext,
                                                  item.value,
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
                searchController.dispose();
                if (selected != null) onChanged(selected);
              },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
                .withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? .38
                      : .55,
                ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 15,
            ),
            suffixIcon: const Icon(Icons.keyboard_arrow_down),
          ),
          child: Text(
            selectedLabel.isEmpty ? 'Select $label' : selectedLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selectedLabel.isEmpty
                  ? Theme.of(context).hintColor
                  : Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _customerController,
      _entryDate,
      _contact,
      _address,
      _tl,
      _sc,
      _model,
      _variant,
      _colour,
      _bookingDate,
      _loanAmount,
      _concerningName,
      _concerningMobile,
      _financeDate,
      _expectedDelivery,
      _remark,
      _companyBranch,
      _disbursedAmount,
    ]) {
      c.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101722)
          : const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text(
          'Finance Details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_navy, _blueLight],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadInitial,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 10),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _loadInitial,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [_navy, Color(0xFF243D59)]
                            : const [_primary, Color(0xFF74171B)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.account_balance,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FINANCE STATUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                _financeId == null || _financeId!.isEmpty
                                    ? 'Create finance details after booking'
                                    : 'Editing finance record',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_customers.length} customers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  _section('Booking & Customer', Icons.person_outline, [
                    _customerPicker(),
                    _field('Entry Date', _entryDate, readOnly: true),
                    _field('Contact No', _contact, readOnly: true),
                    _field('Address', _address, readOnly: true),
                    _field('TL Name', _tl, readOnly: true),
                    _field('SC Name', _sc, readOnly: true),
                    _field('Model', _model, readOnly: true),
                    _field('Variant', _variant, readOnly: true),
                    _field('Colour', _colour, readOnly: true),
                    _field('Booking Date', _bookingDate, readOnly: true),
                    _field('Branch of Company', _companyBranch, readOnly: true),
                  ]),

                  _section(
                    'Finance Details',
                    Icons.account_balance_wallet_outlined,
                    [
                      _dropdown(
                        label: 'Finance Arrangement By',
                        value: _financeArrangement,
                        items: const [
                          DropdownMenuItem(
                            value: 'In',
                            child: Text('In-House'),
                          ),
                          DropdownMenuItem(
                            value: 'Out',
                            child: Text('Out-House'),
                          ),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        ],
                        onChanged: (v) => setState(() {
                          _financeArrangement = v ?? 'In';

                          if (_financeArrangement == 'Cash') {
                            _selectedBankId = null;
                            _selectedBranchId = null;
                            _branches = [];
                          }
                        }),
                      ),
                      _field(
                        'Loan Amount',
                        _loanAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      if (_financeArrangement != 'Cash') ...[
                        _dropdown(
                          label: _banks.isEmpty
                              ? 'Financer — no options loaded'
                              : 'Financer',
                          value: _selectedBankId,
                          items: _banks
                              .map(
                                (r) => DropdownMenuItem<String>(
                                  value: _bankId(r),
                                  child: Text(
                                    _bankLabel(r),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .where((e) => e.value?.isNotEmpty == true)
                              .toList(),
                          onChanged: (v) async {
                            setState(() {
                              _selectedBankId = v;
                              _selectedBranchId = null;
                              _branches = [];
                              _concerningName.clear();
                              _concerningMobile.clear();
                            });

                            await _loadBranches(
                              v,
                              selectedBranchId: null,
                              reloadHistory: false,
                            );
                          },
                        ),
                        _dropdown(
                          label: 'Branch',
                          value: _selectedBranchId,
                          items: _branches
                              .map(
                                (r) => DropdownMenuItem<String>(
                                  value: _branchId(r),
                                  child: Text(
                                    _branchLabel(r),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .where((e) => e.value?.isNotEmpty == true)
                              .toList(),
                          onChanged: (v) {
                            final matched = _branches
                                .where(
                                  (r) =>
                                      v != null && _sameOption(_branchId(r), v),
                                )
                                .toList();

                            final row = matched.isEmpty ? null : matched.first;

                            setState(() {
                              _selectedBranchId = v;
                              _concerningName.text = _first(row, [
                                'name',
                                'hp_c_7',
                                'concerningName',
                              ]);
                              _concerningMobile.text = _first(row, [
                                'mob',
                                'hp_c_13',
                                'concerningMobile',
                              ]);
                            });
                          },
                        ),
                        _field('Concerning Name', _concerningName),
                        _field(
                          'Concerning Mobile No',
                          _concerningMobile,
                          keyboardType: TextInputType.phone,
                        ),
                      ],

                      _dropdown(
                        label: 'Present Status',
                        value: _status,
                        items: const [
                          DropdownMenuItem(
                            value: 'Approve',
                            child: Text('Approve'),
                          ),
                          DropdownMenuItem(
                            value: 'Reject',
                            child: Text('Reject'),
                          ),
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(value: 'Hold', child: Text('Hold')),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? 'Pending'),
                      ),
                      _field(
                        'Finance Date',
                        _financeDate,
                        onTap: () => _chooseDate(_financeDate),
                      ),
                      _field(
                        'Expected Delivery Date',
                        _expectedDelivery,
                        onTap: () => _chooseDate(_expectedDelivery),
                      ),
                      _field(
                        'Disbursed Amount',
                        _disbursedAmount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),

                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _uploading
                                  ? null
                                  : _pickAndUploadDocument,
                              icon: _uploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file),
                              label: Text(
                                _uploading
                                    ? 'Uploading…'
                                    : 'Upload DO Document',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _uploading
                                    ? const Color(
                                        0xFF2468D7,
                                      ).withValues(alpha: .08)
                                    : _uploadFailed
                                    ? Colors.red.withValues(alpha: .08)
                                    : _doUpload.isNotEmpty
                                    ? Colors.green.withValues(alpha: .08)
                                    : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: .45),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _uploading
                                      ? const Color(
                                          0xFF2468D7,
                                        ).withValues(alpha: .35)
                                      : _uploadFailed
                                      ? Colors.red.withValues(alpha: .35)
                                      : _doUpload.isNotEmpty
                                      ? Colors.green.withValues(alpha: .35)
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _uploading
                                            ? Icons.cloud_upload_outlined
                                            : _uploadFailed
                                            ? Icons.error_outline
                                            : _doUpload.isNotEmpty
                                            ? Icons.check_circle_outline
                                            : Icons.insert_drive_file_outlined,
                                        size: 20,
                                        color: _uploading
                                            ? const Color(0xFF2468D7)
                                            : _uploadFailed
                                            ? Colors.red
                                            : _doUpload.isNotEmpty
                                            ? Colors.green
                                            : Theme.of(context).hintColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _pickedFileName ??
                                              (_doUpload.isEmpty
                                                  ? 'No document selected'
                                                  : _doUpload.split('/').last),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _uploadStatus ??
                                        (_doUpload.isNotEmpty
                                            ? 'Image uploaded successfully'
                                            : 'Select an image to upload'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _uploadFailed
                                          ? Colors.red
                                          : _doUpload.isNotEmpty && !_uploading
                                          ? Colors.green
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  if (_uploading) ...[
                                    const SizedBox(height: 10),
                                    const LinearProgressIndicator(minHeight: 4),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Please wait while the image is being uploaded…',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 600
                            ? double.infinity
                            : 530,
                        child: TextFormField(
                          controller: _remark,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Remark',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(
                                  alpha:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? .38
                                      : .55,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  _section('Finance Status History', Icons.history, [
                    if (_financeId == null || _financeId!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Save the finance record first to see status history.',
                        ),
                      )
                    else if (_history.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No finance status history found.'),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                            dataRowColor: WidgetStatePropertyAll(
                              Theme.of(context).colorScheme.surface,
                            ),
                            headingTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            dataTextStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            dividerThickness: 0.7,
                            columns: const [
                              DataColumn(label: Text('#')),
                              DataColumn(label: Text('Entry Date')),
                              DataColumn(label: Text('Status Date')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Remark')),
                            ],
                            rows: _history.asMap().entries.map((entry) {
                              final r = entry.value;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      _first(r, ['rno'], '${entry.key + 1}'),
                                    ),
                                  ),
                                  DataCell(Text(_first(r, ['sp_1_3']))),
                                  DataCell(Text(_first(r, ['sp_1_4']))),
                                  DataCell(Text(_first(r, ['sp_1_5']))),
                                  DataCell(
                                    SizedBox(
                                      width: 280,
                                      child: Text(
                                        _first(r, ['sp_1_6']),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                  ]),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.close),
                        label: const Text('Exit'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                        ),
                        onPressed: _saving
                            ? null
                            : () => _save(exitAfterSave: true),
                        icon: _saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving…' : 'Save '),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
    );
  }
}
