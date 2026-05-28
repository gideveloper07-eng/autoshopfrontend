// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'लॉग इन करें';

  @override
  String get companyCode => 'कंपनी कोड';

  @override
  String get userId => 'उपयोगकर्ता पहचान';

  @override
  String get password => 'पासवर्ड';

  @override
  String get invalidCompanyCode => 'अमान्य कंपनी कोड';

  @override
  String get pleaseEnterCompanyCode => 'कृपया कंपनी कोड दर्ज करें';

  @override
  String get pleaseEnterUserId => 'कृपया उपयोगकर्ता आईडी दर्ज करें';

  @override
  String get pleaseEnterPassword => 'कृपया पासवर्ड दर्ज करें';

  @override
  String get loginFailed => 'लॉगिन विफल';

  @override
  String get loginSuccess => 'लॉग इन सफल';

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
  String get pullToRefresh => 'ताज़ा करने के लिए खींचें या बाद में वापस जाँचें';

  @override
  String get date => 'तारीख';

  @override
  String get challanDate => 'चालान तिथि';

  @override
  String get expectedDeliveryDate => 'प्रप्त करने की अनुमानित तिथि';

  @override
  String get challanNo => 'चालान नं';

  @override
  String get customerName => 'ग्राहक का नाम';

  @override
  String get action => 'कार्रवाई';

  @override
  String get edit => 'संपादन करना';

  @override
  String get save => 'बचाना';

  @override
  String get cancel => 'रद्द करना';

  @override
  String get retry => 'पुन: प्रयास करें';

  @override
  String get refresh => 'ताज़ा करना';

  @override
  String get showDate => 'दिखाएँ दिनांक:';

  @override
  String get expectedDelivery => 'अपेक्षित सुपुर्दगी';

  @override
  String records(int count, String plural) {
    return '$count रिकॉर्ड$plural';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुने';

  @override
  String get languageChanged => 'भाषा सफलतापूर्वक बदली गई';

  @override
  String get home => 'घर';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get confirmLogout => 'क्या आप लॉग आउट करना चाहते हैं?';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get error => 'गलती';

  @override
  String get success => 'सफलता';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get serverError => 'सर्वर त्रुटि';

  @override
  String get networkError => 'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें.';
}
