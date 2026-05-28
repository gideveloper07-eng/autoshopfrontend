// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'ماي أوتو شوب';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get companyCode => 'رمز الشركة';

  @override
  String get userId => 'معرف المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get invalidCompanyCode => 'رمز شركة غير صالح';

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
  String get challan => 'فاتورة';

  @override
  String get pendingChallan => 'فاتورة معلقة';

  @override
  String get retailIncentive => 'حافز التجزئة';

  @override
  String get loadingChallans => 'جاري تحميل الفواتير...';

  @override
  String get failedToLoadChallans => 'فشل تحميل الفواتير';

  @override
  String get noChallansFound => 'لم يتم العثور على فواتير';

  @override
  String get pullToRefresh => 'اسحب للتحديث أو تحقق لاحقًا';

  @override
  String get date => 'التاريخ';

  @override
  String get challanDate => 'تاريخ الفاتورة';

  @override
  String get expectedDeliveryDate => 'تاريخ التسليم المتوقع';

  @override
  String get challanNo => 'رقم الفاتورة';

  @override
  String get customerName => 'اسم العميل';

  @override
  String get action => 'إجراء';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refresh => 'تحديث';

  @override
  String get showDate => 'إظهار التاريخ:';

  @override
  String get expectedDelivery => 'التسليم المتوقع';

  @override
  String records(int count, String plural) {
    return '$count سجل$plural';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get languageChanged => 'تم تغيير اللغة بنجاح';

  @override
  String get home => 'الرئيسية';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get profile => 'الملف الشخصي';

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
  String get loading => 'جاري التحميل...';

  @override
  String get serverError => 'خطأ في الخادم';

  @override
  String get networkError => 'خطأ في الشبكة. يرجى التحقق من اتصالك.';
}
