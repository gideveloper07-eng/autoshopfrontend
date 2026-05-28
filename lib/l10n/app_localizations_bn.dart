// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'মাইঅটোশপ';

  @override
  String get login => 'লগইন';

  @override
  String get companyCode => 'কোম্পানি কোড';

  @override
  String get userId => 'ইউজার আইডি';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get invalidCompanyCode => 'অবৈধ কোম্পানি কোড';

  @override
  String get pleaseEnterCompanyCode => 'অনুগ্রহ করে কোম্পানি কোড লিখুন';

  @override
  String get pleaseEnterUserId => 'অনুগ্রহ করে ইউজার আইডি লিখুন';

  @override
  String get pleaseEnterPassword => 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';

  @override
  String get loginFailed => 'লগইন ব্যর্থ';

  @override
  String get loginSuccess => 'লগইন সফল';

  @override
  String get challan => 'চালান';

  @override
  String get pendingChallan => 'মুলতুবি চালান';

  @override
  String get retailIncentive => 'খুচরা প্রণোদনা';

  @override
  String get loadingChallans => 'চালান লোড হচ্ছে...';

  @override
  String get failedToLoadChallans => 'চালান লোড করতে ব্যর্থ';

  @override
  String get noChallansFound => 'কোনো চালান পাওয়া যায়নি';

  @override
  String get pullToRefresh => 'রিফ্রেশ করতে টানুন বা পরে চেক করুন';

  @override
  String get date => 'তারিখ';

  @override
  String get challanDate => 'চালান তারিখ';

  @override
  String get expectedDeliveryDate => 'প্রত্যাশিত ডেলিভারি তারিখ';

  @override
  String get challanNo => 'চালান নম্বর';

  @override
  String get customerName => 'গ্রাহকের নাম';

  @override
  String get action => 'কর্ম';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get retry => 'পুনরায় চেষ্টা করুন';

  @override
  String get refresh => 'রিফ্রেশ';

  @override
  String get showDate => 'তারিখ দেখান:';

  @override
  String get expectedDelivery => 'প্রত্যাশিত ডেলিভারি';

  @override
  String records(int count, String plural) {
    return '$count রেকর্ড$plural';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get languageChanged => 'ভাষা সফলভাবে পরিবর্তিত হয়েছে';

  @override
  String get home => 'হোম';

  @override
  String get notifications => 'বিজ্ঞপ্তি';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get logout => 'লগআউট';

  @override
  String get confirmLogout => 'আপনি কি নিশ্চিত যে আপনি লগআউট করতে চান?';

  @override
  String get yes => 'হ্যাঁ';

  @override
  String get no => 'না';

  @override
  String get error => 'ত্রুটি';

  @override
  String get success => 'সফলতা';

  @override
  String get loading => 'লোড হচ্ছে...';

  @override
  String get serverError => 'সার্ভার ত্রুটি';

  @override
  String get networkError =>
      'নেটওয়ার্ক ত্রুটি। অনুগ্রহ করে আপনার সংযোগ পরীক্ষা করুন।';
}
