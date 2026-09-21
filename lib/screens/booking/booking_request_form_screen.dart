import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../services/activity_service.dart';
import '../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Booking Request Form Screen
//
// Location flow:
//
//   1. State
//   2. City   -> appears after State selection
//   3. Area   -> appears after City selection
//
// IMPORTANT:
// State / City / Area send internal `value` IDs to the API.
// The visible text comes from `data`.
// ─────────────────────────────────────────────────────────────────────────────

class BookingRequestFormScreen extends StatefulWidget {
  const BookingRequestFormScreen({super.key});

  @override
  State<BookingRequestFormScreen> createState() =>
      _BookingRequestFormScreenState();
}

class _BookingRequestFormScreenState extends State<BookingRequestFormScreen> {
  // ── Theme ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0D3F8A);
  static const Color _accent = Color(0xFF2C6CE0);
  static const Color _reqStar = Color(0xFFD32F2F);

  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  bool _loadingDropdowns = true;
  bool _loadingCities = false;
  bool _loadingAreas = false;
  bool _loadingVariants = false;
  bool _saving = false;

  String? _initError;

  // ── Controllers ───────────────────────────────────────────────────────────
  final _nameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _birthAnniversaryCtrl = TextEditingController();
  final _marriageAnniversaryCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  // ── Selected values ───────────────────────────────────────────────────────
  String _selectedTitle = 'MR';

  String? _selectedStateVal;
  String? _selectedCityVal;
  String? _selectedAreaVal;

  String? _selectedModelData;
  String? _selectedVariantData;
  String? _selectedColourData;
  String? _selectedSCData;

  // ── Dropdown data ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _stateList = [];
  List<Map<String, dynamic>> _cityList = [];
  List<Map<String, dynamic>> _areaList = [];

  List<Map<String, dynamic>> _modelList = [];
  List<Map<String, dynamic>> _variantList = [];
  List<Map<String, dynamic>> _colourList = [];
  List<Map<String, dynamic>> _scList = [];

  final List<String> _titles = ['MR', 'MRS', 'MS', 'DR', 'PROF'];

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    ActivityService.logActivity(
      activityType: 'SCREEN',
      activityName: 'BookingRequestFormScreen',
      screenName: 'BookingRequestFormScreen',
    );

    _loadDropdowns();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _mobileCtrl.dispose();
    _gstinCtrl.dispose();
    _birthAnniversaryCtrl.dispose();
    _marriageAnniversaryCtrl.dispose();
    _aadharCtrl.dispose();
    _zipCtrl.dispose();
    _panCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Initial dropdown loading
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadDropdowns() async {
    setState(() {
      _loadingDropdowns = true;
      _initError = null;
    });

    try {
      final dd = await ApiService.getBookingFormDropdowns();

      if (!mounted) return;

      setState(() {
        _stateList = List<Map<String, dynamic>>.from(dd['states'] ?? const []);

        // IMPORTANT:
        // Do not load City or Area initially.
        _cityList = [];
        _areaList = [];

        _modelList = List<Map<String, dynamic>>.from(dd['models'] ?? const []);

        _colourList = List<Map<String, dynamic>>.from(
          dd['colours'] ?? const [],
        );

        _scList = List<Map<String, dynamic>>.from(dd['scNames'] ?? const []);

        _loadingDropdowns = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _initError = e.toString();
        _loadingDropdowns = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // State -> City
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadCities(String stateUnq) async {
    setState(() {
      _loadingCities = true;

      _cityList = [];
      _areaList = [];

      _selectedCityVal = null;
      _selectedAreaVal = null;
    });

    try {
      print('BOOKING: Loading cities for state UNQID = $stateUnq');

      final list = await ApiService.getBookingCities(stateUnq);

      if (!mounted) return;

      setState(() {
        _cityList = list;
        _loadingCities = false;
      });

      print('BOOKING: Cities loaded = ${list.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCities = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load cities: '
            '${e.toString().replaceFirst("Exception: ", "")}',
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // City -> Area
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadAreas(String cityUnq) async {
    setState(() {
      _loadingAreas = true;

      _areaList = [];
      _selectedAreaVal = null;
    });

    try {
      print('BOOKING: Loading areas for city UNQID = $cityUnq');

      final list = await ApiService.getBookingAreas(cityUnq);

      if (!mounted) return;

      setState(() {
        _areaList = list;
        _loadingAreas = false;
      });

      print('BOOKING: Areas loaded = ${list.length}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingAreas = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load areas: '
            '${e.toString().replaceFirst("Exception: ", "")}',
          ),
        ),
      );
    }
  }
  // ─────────────────────────────────────────────────────────────────────────
  // Area -> ZIP Code
  // ─────────────────────────────────────────────────────────────────────────

  // Model -> Variant
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadVariants(String modelUnq) async {
    setState(() {
      _loadingVariants = true;
      _variantList = [];
      _selectedVariantData = null;
    });

    try {
      final list = await ApiService.getBookingVariants(modelUnq);

      if (!mounted) return;

      setState(() {
        _variantList = list;
        _loadingVariants = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingVariants = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load variants: '
            '${e.toString().replaceFirst("Exception: ", "")}',
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Validators
  // ─────────────────────────────────────────────────────────────────────────

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    return null;
  }

  String? _nameValidator(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return 'Name is required';
    }

    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(v)) {
      return 'Name can contain only letters and spaces';
    }

    return null;
  }

  String? _fatherNameValidator(String? value) {
    final v = value?.trim() ?? '';

    // Father's Name is optional.
    if (v.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(v)) {
      return "Father's Name can contain only letters and spaces";
    }

    return null;
  }

  String? _mobileValidator(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) {
      return 'Mobile No. is required';
    }

    if (!RegExp(r'^\d{10}$').hasMatch(v)) {
      return 'Enter a valid 10-digit mobile number';
    }

    return null;
  }

  String? _emailValidator(String? value) {
    final v = value?.trim() ?? '';

    // Email is optional.
    if (v.isEmpty) {
      return null;
    }

    if (!RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    ).hasMatch(v)) {
      return 'Enter a valid email ID';
    }

    return null;
  }

  String? _aadhaarValidator(String? value) {
    final v = value?.replaceAll(' ', '').trim() ?? '';

    // Aadhaar is optional.
    if (v.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(v)) {
      return 'Aadhaar Card No. must be exactly 12 digits';
    }

    return null;
  }

  String? _panValidator(String? value) {
    final v = value?.trim().toUpperCase() ?? '';

    // PAN is optional.
    if (v.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v)) {
      return 'Enter a valid PAN number';
    }

    return null;
  }
  // ─────────────────────────────────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct all required fields before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await ApiService.saveNewBookingRequest(
        title: _selectedTitle,
        name: _nameCtrl.text.trim(),
        fatherName: _fatherNameCtrl.text.trim(),
        emailId: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),

        // Internal IDs.
        state: _selectedStateVal ?? '',
        cityUnq: _selectedCityVal ?? '',
        areaUnq: _selectedAreaVal ?? '',

        // ZIP entered manually by user.
        zip: _zipCtrl.text.trim(),

        mobileNo: _mobileCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim(),
        birthAnniversary: _birthAnniversaryCtrl.text.trim(),
        marriageAnniversary: _marriageAnniversaryCtrl.text.trim(),
        aadharNo: _aadharCtrl.text.trim(),
        panNo: _panCtrl.text.trim(),
        modelUnq: _selectedModelData ?? '',
        variantUnq: _selectedVariantData ?? '',
        colourUnq: _selectedColourData ?? '',
        scUnq: _selectedSCData ?? '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request saved successfully!'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: '
            '${e.toString().replaceFirst("Exception: ", "")}',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Date Picker
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;

    final labelColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: AppColors.bg(context),

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Booking Request Form',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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
      ),

      body: _buildBody(cardBg, labelColor),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Body
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildBody(Color cardBg, Color labelColor) {
    if (_loadingDropdowns) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading form data…', style: TextStyle(fontSize: 14)),
          ],
        ),
      );
    }

    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),

              const SizedBox(height: 12),

              Text(
                'Failed to load form data.\n$_initError',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _loadDropdowns,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,

      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ── Customer Information ──────────────────────────────────
                  _sectionHeader('Customer Information'),

                  const SizedBox(height: 14),

                  _buildStaticDropdown(
                    label: 'Title',
                    requiredField: true,
                    value: _selectedTitle,

                    items: _titles
                        .map(
                          (title) => DropdownMenuItem<String>(
                            value: title,
                            child: Text(title),
                          ),
                        )
                        .toList(),

                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedTitle = value;
                      });
                    },

                    labelColor: labelColor,
                  ),

                  const SizedBox(height: 14),

                  _buildTextField(
                    ctrl: _nameCtrl,
                    label: 'Name',
                    requiredField: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                    ],
                    labelColor: labelColor,
                    validator: _nameValidator,
                  ),

                  const SizedBox(height: 14),

                  _buildTextField(
                    ctrl: _fatherNameCtrl,
                    label: "Father's Name",
                    requiredField: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z ]')),
                    ],
                    labelColor: labelColor,
                    validator: _fatherNameValidator,
                  ),

                  const SizedBox(height: 14),

                  _buildTextField(
                    ctrl: _emailCtrl,
                    label: 'Email ID',
                    requiredField: false,
                    keyboardType: TextInputType.emailAddress,
                    textCapitalization: TextCapitalization.none,
                    labelColor: labelColor,
                    validator: _emailValidator,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),

                  const SizedBox(height: 14),

                  _buildTextField(
                    ctrl: _addressCtrl,
                    label: 'Address',
                    requiredField: true,
                    maxLines: 2,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9 ,./#-]'),
                      ),
                    ],
                    labelColor: labelColor,
                    validator: (value) => _requiredValidator(value, 'Address'),
                  ),

                  const SizedBox(height: 14),

                  // ───────────────── LOCATION ───────────────────────────────
                  _buildSpDropdown(
                    label: 'State',
                    requiredField: true,
                    value: _selectedStateVal,

                    // Internal State UNQID
                    dataKey: 'value',

                    // Visible State name
                    valueKey: 'data',

                    items: _stateList,

                    placeholder: 'Select State',

                    labelColor: labelColor,

                    validator: (value) => _requiredValidator(value, 'State'),

                    onChanged: (value) {
                      if (value == null || value.isEmpty) {
                        return;
                      }

                      setState(() {
                        _selectedStateVal = value;

                        // Reset City
                        _selectedCityVal = null;

                        // Reset Area
                        _selectedAreaVal = null;

                        _cityList = [];
                        _areaList = [];
                      });

                      // Load cities for selected state
                      _loadCities(value);
                    },
                  ),

                  const SizedBox(height: 14),

                  // ───────────────── CITY ──────────────────────────────────
                  _loadingCities
                      ? _loadingRow('Loading cities…')
                      : _buildSpDropdown(
                          label: 'City',
                          requiredField: true,
                          value: _selectedCityVal,

                          // City UNQID
                          dataKey: 'data',

                          // City Name
                          valueKey: 'value',

                          items: _cityList,

                          placeholder: 'Select City',

                          labelColor: labelColor,

                          validator: (value) =>
                              _requiredValidator(value, 'City'),

                          onChanged: (value) {
                            if (value == null || value.isEmpty) {
                              return;
                            }

                            setState(() {
                              _selectedCityVal = value;

                              _selectedAreaVal = null;
                              _areaList = [];
                            });

                            _loadAreas(value);
                          },
                        ),

                  const SizedBox(height: 14),

                  // ───────────────── AREA ──────────────────────────────────
                  _loadingAreas
                      ? _loadingRow('Loading areas…')
                      : _buildSpDropdown(
                          label: 'Area',
                          requiredField: true,
                          value: _selectedAreaVal,

                          // Internal Area UNQID
                          dataKey: 'data',

                          // Visible Area Name
                          valueKey: 'value',

                          items: _areaList,

                          placeholder: _selectedCityVal == null
                              ? 'Select City first'
                              : 'Select Area',

                          labelColor: labelColor,

                          validator: (value) =>
                              _requiredValidator(value, 'Area'),

                          onChanged: (value) {
                            if (value == null || value.isEmpty) {
                              return;
                            }

                            setState(() {
                              _selectedAreaVal = value;
                              _zipCtrl.clear();
                            });
                          },
                        ),

                  const SizedBox(height: 14),
                  // ── ZIP Code ───────────────────────────────────────────────
                  _buildTextField(
                    ctrl: _zipCtrl,
                    label: 'ZIP Code',
                    requiredField: false,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    labelColor: labelColor,
                  ),

                  const SizedBox(height: 14),
                  // ── Mobile ────────────────────────────────────────────────
                  _buildTextField(
                    ctrl: _mobileCtrl,
                    label: 'Mobile No',
                    requiredField: true,
                    keyboardType: TextInputType.phone,

                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],

                    labelColor: labelColor,
                    validator: _mobileValidator,
                  ),

                  const SizedBox(height: 14),

                  // ── GSTIN ─────────────────────────────────────────────────
                  _buildTextField(
                    ctrl: _gstinCtrl,
                    label: 'GSTIN',
                    requiredField: false,
                    textCapitalization: TextCapitalization.characters,
                    labelColor: labelColor,
                  ),

                  const SizedBox(height: 14),

                  // ── Birth Anniversary ────────────────────────────────────
                  _buildDateField(
                    ctrl: _birthAnniversaryCtrl,
                    label: 'Birth Anniversary',
                    requiredField: false,
                    labelColor: labelColor,
                  ),

                  // ── Aadhaar ───────────────────────────────────────────────
                  _buildTextField(
                    ctrl: _aadharCtrl,
                    label: 'Aadhar No',
                    requiredField: false,
                    keyboardType: TextInputType.number,

                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],

                    labelColor: labelColor,
                    validator: _aadhaarValidator,
                  ),
                  const SizedBox(height: 14),

                  // ── PAN Card ─────────────────────────────────
                  _buildTextField(
                    ctrl: _panCtrl,
                    label: 'PAN Card',
                    requiredField: false,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(10),
                    ],
                    labelColor: labelColor,
                    validator: _panValidator,
                  ),
                  const SizedBox(height: 24),

                  // ── Vehicle Information ──────────────────────────────────
                  _sectionHeader('Vehicle Information'),

                  const SizedBox(height: 14),

                  // Model
                  _buildSpDropdown(
                    label: 'Model',
                    requiredField: true,
                    value: _selectedModelData,
                    items: _modelList,

                    dataKey: 'data',
                    valueKey: 'value',

                    placeholder: 'Select Model',

                    labelColor: labelColor,

                    validator: (value) => _requiredValidator(value, 'Model'),

                    onChanged: (value) {
                      setState(() {
                        _selectedModelData = value;

                        _selectedVariantData = null;

                        _variantList = [];
                      });

                      if (value != null && value.isNotEmpty) {
                        _loadVariants(value);
                      }
                    },
                  ),

                  const SizedBox(height: 14),

                  // Variant
                  _loadingVariants
                      ? _loadingRow('Loading variants…')
                      : _buildSpDropdown(
                          label: 'Variant',
                          requiredField: true,
                          value: _selectedVariantData,
                          items: _variantList,

                          dataKey: 'data',
                          valueKey: 'value',

                          placeholder: _selectedModelData == null
                              ? 'Select Model first'
                              : 'Select Variant',

                          labelColor: labelColor,

                          validator: (value) =>
                              _requiredValidator(value, 'Variant'),

                          onChanged: (value) {
                            setState(() {
                              _selectedVariantData = value;
                            });
                          },
                        ),

                  const SizedBox(height: 14),

                  // Colour
                  _buildSpDropdown(
                    label: 'Color',
                    requiredField: true,
                    value: _selectedColourData,
                    items: _colourList,

                    dataKey: 'data',
                    valueKey: 'value',

                    placeholder: 'Select Color',

                    labelColor: labelColor,

                    validator: (value) => _requiredValidator(value, 'Color'),

                    onChanged: (value) {
                      setState(() {
                        _selectedColourData = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // SC Name
                  _buildSpDropdown(
                    label: 'SC Name',
                    requiredField: true,
                    value: _selectedSCData,
                    items: _scList,

                    dataKey: 'data',
                    valueKey: 'value',

                    placeholder: 'Select SC Name',

                    labelColor: labelColor,

                    validator: (value) => _requiredValidator(value, 'SC Name'),

                    onChanged: (value) {
                      setState(() {
                        _selectedSCData = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Buttons ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _onSave,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),

                const SizedBox(width: 16),

                SizedBox(
                  width: 120,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),

                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Loading row
  // ─────────────────────────────────────────────────────────────────────────

  Widget _loadingRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

          const SizedBox(width: 10),

          Text(message),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Section Header
  // ─────────────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _accent,
            letterSpacing: 0.3,
          ),
        ),

        const SizedBox(height: 6),

        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _accent.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Text Field
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController ctrl,
    required String label,
    required bool requiredField,
    required Color labelColor,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
    AutovalidateMode? autovalidateMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, requiredField, labelColor),

        const SizedBox(height: 5),

        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          autovalidateMode: autovalidateMode,
          decoration: _inputDecoration(),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Date Field
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDateField({
    required TextEditingController ctrl,
    required String label,
    required bool requiredField,
    required Color labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, requiredField, labelColor),

        const SizedBox(height: 5),

        TextFormField(
          controller: ctrl,
          readOnly: true,
          onTap: () => _pickDate(ctrl),
          decoration: _inputDecoration().copyWith(
            hintText: 'DD/MM/YYYY',
            suffixIcon: const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: _accent,
            ),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Searchable SP Dropdown
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildSpDropdown({
    required String label,
    required List<dynamic> items,
    required String dataKey,
    required String valueKey,
    required String? value,
    required ValueChanged<String?> onChanged,
    required Color labelColor,
    bool requiredField = true,
    String? Function(String?)? validator,
    String placeholder = '',
  }) {
    // Internal ID -> display text.
    final Map<String, String> uniqueItems = {};

    for (final rawItem in items) {
      if (rawItem is! Map) {
        continue;
      }

      final actualValue = (rawItem[dataKey] ?? '').toString().trim();

      final displayValue = (rawItem[valueKey] ?? '').toString().trim();

      if (actualValue.isEmpty || displayValue.isEmpty) {
        continue;
      }

      // Remove duplicate visible State names.
      if (label.toLowerCase() == 'state') {
        final alreadyExists = uniqueItems.values.any(
          (existing) => existing.toLowerCase() == displayValue.toLowerCase(),
        );

        if (!alreadyExists) {
          uniqueItems[actualValue] = displayValue;
        }
      } else {
        uniqueItems.putIfAbsent(actualValue, () => displayValue);
      }
    }

    final effectiveValue = value != null && uniqueItems.containsKey(value)
        ? value
        : null;

    return FormField<String>(
      key: ValueKey('${label}_$effectiveValue'),

      initialValue: effectiveValue,

      validator:
          validator ??
          (fieldValue) {
            if (!requiredField) {
              return null;
            }

            if (fieldValue == null || fieldValue.trim().isEmpty) {
              return '$label is required';
            }

            return null;
          },

      builder: (field) {
        final displayText = effectiveValue == null
            ? (placeholder.isEmpty ? 'Select $label' : placeholder)
            : (uniqueItems[effectiveValue] ?? effectiveValue);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _label(label, requiredField, labelColor),

            const SizedBox(height: 5),

            InkWell(
              borderRadius: BorderRadius.circular(12),

              onTap: uniqueItems.isEmpty
                  ? null
                  : () async {
                      final searchController = TextEditingController();

                      final result = await showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,

                        builder: (sheetContext) {
                          return StatefulBuilder(
                            builder: (context, setSheetState) {
                              final query = searchController.text
                                  .trim()
                                  .toLowerCase();

                              final filtered = uniqueItems.entries.where((
                                entry,
                              ) {
                                return entry.value.toLowerCase().contains(
                                      query,
                                    ) ||
                                    entry.key.toLowerCase().contains(query);
                              }).toList();

                              return SafeArea(
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height * 0.78,

                                  decoration: const BoxDecoration(
                                    color: Colors.white,

                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                  ),

                                  child: Column(
                                    children: [
                                      const SizedBox(height: 10),

                                      Container(
                                        width: 45,
                                        height: 5,

                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          16,
                                          18,
                                          10,
                                        ),

                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Select $label',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),

                                            IconButton(
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

                                          autofocus: true,

                                          onChanged: (_) =>
                                              setSheetState(() {}),

                                          decoration: InputDecoration(
                                            hintText: 'Search $label...',

                                            prefixIcon: const Icon(
                                              Icons.search,
                                            ),

                                            suffixIcon:
                                                searchController.text.isEmpty
                                                ? null
                                                : IconButton(
                                                    onPressed: () {
                                                      searchController.clear();

                                                      setSheetState(() {});
                                                    },

                                                    icon: const Icon(
                                                      Icons.clear,
                                                    ),
                                                  ),

                                            filled: true,

                                            fillColor: Colors.grey.shade100,

                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          10,
                                          20,
                                          8,
                                        ),

                                        child: Align(
                                          alignment: Alignment.centerLeft,

                                          child: Text(
                                            '${filtered.length} result${filtered.length == 1 ? '' : 's'}',

                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: filtered.isEmpty
                                            ? Center(
                                                child: Text(
                                                  'No $label found\nTry a different search',

                                                  textAlign: TextAlign.center,

                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),

                                                itemCount: filtered.length,

                                                separatorBuilder: (_, __) =>
                                                    const Divider(height: 1),

                                                itemBuilder: (context, index) {
                                                  final entry = filtered[index];

                                                  final isSelected =
                                                      entry.key ==
                                                      effectiveValue;

                                                  return Material(
                                                    color: Colors.transparent,
                                                    child: ListTile(
                                                      title: Text(
                                                        entry.value,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),

                                                      trailing: isSelected
                                                          ? const Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.green,
                                                            )
                                                          : null,

                                                      onTap: () =>
                                                          Navigator.pop(
                                                            sheetContext,
                                                            entry.key,
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
                            },
                          );
                        },
                      );

                      searchController.dispose();

                      if (result != null) {
                        onChanged(result);
                        field.didChange(result);
                        field.validate();
                      }
                    },

              child: InputDecorator(
                decoration: _inputDecoration(errorText: field.errorText),

                isEmpty: effectiveValue == null,

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 14,

                          color: effectiveValue == null
                              ? Colors.grey.shade600
                              : Colors.black87,
                        ),
                      ),
                    ),

                    const Icon(Icons.arrow_drop_down, color: _accent),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Static Dropdown
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildStaticDropdown({
    required String label,
    required bool requiredField,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required Color labelColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label, requiredField, labelColor),

        const SizedBox(height: 5),

        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: _inputDecoration(),
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Label
  // ─────────────────────────────────────────────────────────────────────────

  Widget _label(String text, bool requiredField, Color labelColor) {
    return RichText(
      text: TextSpan(
        text: text,

        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),

        children: requiredField
            ? const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: _reqStar),
                ),
              ]
            : const [],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared Input Decoration
  // ─────────────────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration({String? errorText}) {
    return InputDecoration(
      isDense: true,

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),

      filled: true,

      fillColor: Colors.white,

      errorText: errorText,

      errorStyle: const TextStyle(fontSize: 10),
    );
  }
}
