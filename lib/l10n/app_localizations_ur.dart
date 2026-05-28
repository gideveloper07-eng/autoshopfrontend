// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'لاگ ان';

  @override
  String get companyCode => 'کمپنی کا کوڈ';

  @override
  String get userId => 'یوزر آئی ڈی';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get invalidCompanyCode => 'غلط کمپنی کوڈ';

  @override
  String get pleaseEnterCompanyCode => 'براہ کرم کمپنی کا کوڈ درج کریں۔';

  @override
  String get pleaseEnterUserId => 'براہ کرم صارف کی شناخت درج کریں۔';

  @override
  String get pleaseEnterPassword => 'براہ کرم پاس ورڈ درج کریں۔';

  @override
  String get loginFailed => 'لاگ ان ناکام ہو گیا۔';

  @override
  String get loginSuccess => 'لاگ ان کامیاب';

  @override
  String get challan => 'چالان';

  @override
  String get pendingChallan => 'زیر التواء چالان';

  @override
  String get retailIncentive => 'خوردہ ترغیب';

  @override
  String get loadingChallans => 'چالان لوڈ ہو رہے ہیں...';

  @override
  String get failedToLoadChallans => 'چالان لوڈ کرنے میں ناکام';

  @override
  String get noChallansFound => 'کوئی چالان نہیں ملا';

  @override
  String get pullToRefresh => 'ریفریش کرنے کے لیے کھینچیں یا بعد میں دوبارہ چیک کریں۔';

  @override
  String get date => 'تاریخ';

  @override
  String get challanDate => 'چالان کی تاریخ';

  @override
  String get expectedDeliveryDate => 'متوقع ترسیل کی تاریخ';

  @override
  String get challanNo => 'چالان نمبر';

  @override
  String get customerName => 'گاہک کا نام';

  @override
  String get action => 'ایکشن';

  @override
  String get edit => 'ترمیم کریں۔';

  @override
  String get save => 'محفوظ کریں۔';

  @override
  String get cancel => 'منسوخ کریں۔';

  @override
  String get retry => 'دوبارہ کوشش کریں۔';

  @override
  String get refresh => 'ریفریش کریں۔';

  @override
  String get showDate => 'تاریخ دکھائیں:';

  @override
  String get expectedDelivery => 'متوقع ترسیل';

  @override
  String records(int count, String plural) {
    return '$count ریکارڈ$plural';
  }

  @override
  String get settings => 'ترتیبات';

  @override
  String get language => 'زبان';

  @override
  String get selectLanguage => 'زبان منتخب کریں۔';

  @override
  String get languageChanged => 'زبان کامیابی سے تبدیل ہو گئی۔';

  @override
  String get home => 'گھر';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get profile => 'پروفائل';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get confirmLogout => 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟';

  @override
  String get yes => 'جی ہاں';

  @override
  String get no => 'نہیں';

  @override
  String get error => 'خرابی';

  @override
  String get success => 'کامیابی';

  @override
  String get loading => 'لوڈ ہو رہا ہے...';

  @override
  String get serverError => 'سرور کی خرابی۔';

  @override
  String get networkError => 'نیٹ ورک کی خرابی۔ براہ کرم اپنا کنکشن چیک کریں۔';
}
