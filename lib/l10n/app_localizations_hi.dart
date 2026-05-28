// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'माईऑटोशॉप';

  @override
  String get login => 'लॉगिन';

  @override
  String get companyCode => 'कंपनी कोड';

  @override
  String get userId => 'यूजर आईडी';

  @override
  String get password => 'पासवर्ड';

  @override
  String get invalidCompanyCode => 'अमान्य कंपनी कोड';

  @override
  String get pleaseEnterCompanyCode => 'कृपया कंपनी कोड दर्ज करें';

  @override
  String get pleaseEnterUserId => 'कृपया यूजर आईडी दर्ज करें';

  @override
  String get pleaseEnterPassword => 'कृपया पासवर्ड दर्ज करें';

  @override
  String get loginFailed => 'लॉगिन विफल';

  @override
  String get loginSuccess => 'लॉगिन सफल';

  @override
  String get challan => 'चालान';

  @override
  String get pendingChallan => 'लंबित चालान';

  @override
  String get retailIncentive => 'खुदरा प्रोत्साहन';

  @override
  String get loadingChallans => 'चालान लोड हो रहे हैं...';

  @override
  String get failedToLoadChallans => 'चालान लोड करने में विफल';

  @override
  String get noChallansFound => 'कोई चालान नहीं मिला';

  @override
  String get pullToRefresh => 'रीफ्रेश करने के लिए खींचें या बाद में जांचें';

  @override
  String get date => 'तारीख';

  @override
  String get challanDate => 'चालान तारीख';

  @override
  String get expectedDeliveryDate => 'अपेक्षित डिलीवरी तारीख';

  @override
  String get challanNo => 'चालान नंबर';

  @override
  String get customerName => 'ग्राहक का नाम';

  @override
  String get action => 'कार्रवाई';

  @override
  String get edit => 'संपादित करें';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get refresh => 'रीफ्रेश';

  @override
  String get showDate => 'तारीख दिखाएं:';

  @override
  String get expectedDelivery => 'अपेक्षित डिलीवरी';

  @override
  String records(int count, String plural) {
    return '$count रिकॉर्ड$plural';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get languageChanged => 'भाषा सफलतापूर्वक बदल गई';

  @override
  String get home => 'होम';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get confirmLogout => 'क्या आप वाकई लॉगआउट करना चाहते हैं?';

  @override
  String get yes => 'हां';

  @override
  String get no => 'नहीं';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get serverError => 'सर्वर त्रुटि';

  @override
  String get networkError => 'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।';
}
