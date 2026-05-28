// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get companyCode => 'رمز الشركة';

  @override
  String get userId => 'معرف المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get invalidCompanyCode => 'رمز الشركة غير صالح';

  @override
  String get pleaseEnterCompanyCode => 'الرجاء إدخال رمز الشركة';

  @override
  String get pleaseEnterUserId => 'الرجاء إدخال معرف المستخدم';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get loginSuccess => 'تم تسجيل الدخول بنجاح';

  @override
  String get challan => 'تشالان';

  @override
  String get pendingChallan => 'في انتظار تشالان';

  @override
  String get retailIncentive => 'حوافز التجزئة';

  @override
  String get loadingChallans => 'جارٍ تحميل المسابقات...';

  @override
  String get failedToLoadChallans => 'فشل تحميل التحدي';

  @override
  String get noChallansFound => 'لم يتم العثور على شالانس';

  @override
  String get pullToRefresh => 'اسحب للتحديث أو تحقق مرة أخرى لاحقًا';

  @override
  String get date => 'تاريخ';

  @override
  String get challanDate => 'تاريخ تشالان';

  @override
  String get expectedDeliveryDate => 'تاريخ التسليم المتوقع';

  @override
  String get challanNo => 'رقم تشالان';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get action => 'فعل';

  @override
  String get edit => 'يحرر';

  @override
  String get save => 'يحفظ';

  @override
  String get cancel => 'يلغي';

  @override
  String get retry => 'أعد المحاولة';

  @override
  String get refresh => 'ينعش';

  @override
  String get showDate => 'تاريخ العرض:';

  @override
  String get expectedDelivery => 'التسليم المتوقع';

  @override
  String records(int count, String plural) {
    return '$count سجل$plural';
  }

  @override
  String get settings => 'إعدادات';

  @override
  String get language => 'لغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get languageChanged => 'تم تغيير اللغة بنجاح';

  @override
  String get home => 'بيت';

  @override
  String get notifications => 'إشعارات';

  @override
  String get profile => 'حساب تعريفي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get confirmLogout => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get error => 'خطأ';

  @override
  String get success => 'نجاح';

  @override
  String get loading => 'تحميل...';

  @override
  String get serverError => 'خطأ في الخادم';

  @override
  String get networkError => 'خطأ في الشبكة. يرجى التحقق من الاتصال الخاص بك.';
}
