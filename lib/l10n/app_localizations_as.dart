// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Assamese (`as`).
class AppLocalizationsAs extends AppLocalizations {
  AppLocalizationsAs([String locale = 'as']) : super(locale);

  @override
  String get appTitle => 'মাইঅটোশ্বপ';

  @override
  String get login => 'লগইন';

  @override
  String get companyCode => 'কোম্পানী ক\'ড';

  @override
  String get userId => 'ব্যৱহাৰকাৰী আইডি';

  @override
  String get password => 'পাছৱৰ্ড';

  @override
  String get invalidCompanyCode => 'অবৈধ কোম্পানী ক\'ড';

  @override
  String get pleaseEnterCompanyCode => 'অনুগ্ৰহ কৰি কোম্পানী ক\'ড দিয়ক';

  @override
  String get pleaseEnterUserId => 'অনুগ্ৰহ কৰি ব্যৱহাৰকাৰী আইডি দিয়ক';

  @override
  String get pleaseEnterPassword => 'অনুগ্ৰহ কৰি পাছৱৰ্ড দিয়ক';

  @override
  String get loginFailed => 'লগইন বিফল';

  @override
  String get loginSuccess => 'লগইন সফল';

  @override
  String get challan => 'চালান';

  @override
  String get pendingChallan => 'বিচাৰাধীন চালান';

  @override
  String get retailIncentive => 'খুচুৰা প্ৰৰোচনা';

  @override
  String get loadingChallans => 'চালান ল\'ড হৈ আছে...';

  @override
  String get failedToLoadChallans => 'চালান ল\'ড কৰিবলৈ বিফল';

  @override
  String get noChallansFound => 'কোনো চালান পোৱা নগ\'ল';

  @override
  String get pullToRefresh => 'সতেজ কৰিবলৈ টানক বা পিছত পৰীক্ষা কৰক';

  @override
  String get date => 'তাৰিখ';

  @override
  String get challanDate => 'চালান তাৰিখ';

  @override
  String get expectedDeliveryDate => 'প্ৰত্যাশিত ডেলিভাৰী তাৰিখ';

  @override
  String get challanNo => 'চালান নম্বৰ';

  @override
  String get customerName => 'গ্ৰাহকৰ নাম';

  @override
  String get action => 'কাৰ্য';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get save => 'সংৰক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get retry => 'পুনৰ চেষ্টা কৰক';

  @override
  String get refresh => 'সতেজ কৰক';

  @override
  String get showDate => 'তাৰিখ দেখুৱাওক:';

  @override
  String get expectedDelivery => 'প্ৰত্যাশিত ডেলিভাৰী';

  @override
  String records(int count, String plural) {
    return '$count ৰেকৰ্ড$plural';
  }

  @override
  String get settings => 'ছেটিংছ';

  @override
  String get language => 'ভাষা';

  @override
  String get selectLanguage => 'ভাষা নিৰ্বাচন কৰক';

  @override
  String get languageChanged => 'ভাষা সফলতাৰে সলনি কৰা হৈছে';

  @override
  String get home => 'হ\'ম';

  @override
  String get notifications => 'জাননী';

  @override
  String get profile => 'প্ৰ\'ফাইল';

  @override
  String get logout => 'লগআউট';

  @override
  String get confirmLogout => 'আপুনি নিশ্চিতভাৱে লগআউট কৰিব বিচাৰে নেকি?';

  @override
  String get yes => 'হয়';

  @override
  String get no => 'নহয়';

  @override
  String get error => 'ত্ৰুটি';

  @override
  String get success => 'সফলতা';

  @override
  String get loading => 'ল\'ড হৈ আছে...';

  @override
  String get serverError => 'চাৰ্ভাৰ ত্ৰুটি';

  @override
  String get networkError =>
      'নেটৱৰ্ক ত্ৰুটি। অনুগ্ৰহ কৰি আপোনাৰ সংযোগ পৰীক্ষা কৰক।';
}
