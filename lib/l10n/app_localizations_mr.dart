// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'माईऑटोशॉप';

  @override
  String get login => 'लॉगिन';

  @override
  String get companyCode => 'कंपनी कोड';

  @override
  String get userId => 'यूजर आयडी';

  @override
  String get password => 'पासवर्ड';

  @override
  String get invalidCompanyCode => 'अवैध कंपनी कोड';

  @override
  String get pleaseEnterCompanyCode => 'कृपया कंपनी कोड प्रविष्ट करा';

  @override
  String get pleaseEnterUserId => 'कृपया यूजर आयडी प्रविष्ट करा';

  @override
  String get pleaseEnterPassword => 'कृपया पासवर्ड प्रविष्ट करा';

  @override
  String get loginFailed => 'लॉगिन अयशस्वी';

  @override
  String get loginSuccess => 'लॉगिन यशस्वी';

  @override
  String get challan => 'चलन';

  @override
  String get pendingChallan => 'प्रलंबित चलन';

  @override
  String get retailIncentive => 'किरकोळ प्रोत्साहन';

  @override
  String get loadingChallans => 'चलन लोड होत आहेत...';

  @override
  String get failedToLoadChallans => 'चलन लोड करण्यात अयशस्वी';

  @override
  String get noChallansFound => 'चलन सापडले नाहीत';

  @override
  String get pullToRefresh => 'रिफ्रेश करण्यासाठी खेचा किंवा नंतर तपासा';

  @override
  String get date => 'तारीख';

  @override
  String get challanDate => 'चलन तारीख';

  @override
  String get expectedDeliveryDate => 'अपेक्षित वितरण तारीख';

  @override
  String get challanNo => 'चलन क्रमांक';

  @override
  String get customerName => 'ग्राहकाचे नाव';

  @override
  String get action => 'कृती';

  @override
  String get edit => 'संपादित करा';

  @override
  String get save => 'जतन करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get refresh => 'रिफ्रेश';

  @override
  String get showDate => 'तारीख दाखवा:';

  @override
  String get expectedDelivery => 'अपेक्षित वितरण';

  @override
  String records(int count, String plural) {
    return '$count रेकॉर्ड$plural';
  }

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get languageChanged => 'भाषा यशस्वीरित्या बदलली';

  @override
  String get home => 'होम';

  @override
  String get notifications => 'सूचना';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get confirmLogout =>
      'तुम्हाला खात्री आहे की तुम्ही लॉगआउट करू इच्छिता?';

  @override
  String get yes => 'होय';

  @override
  String get no => 'नाही';

  @override
  String get error => 'त्रुटी';

  @override
  String get success => 'यश';

  @override
  String get loading => 'लोड होत आहे...';

  @override
  String get serverError => 'सर्व्हर त्रुटी';

  @override
  String get networkError => 'नेटवर्क त्रुटी. कृपया तुमचे कनेक्शन तपासा.';
}
