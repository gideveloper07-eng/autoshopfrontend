// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'உள்நுழைக';

  @override
  String get companyCode => 'நிறுவனத்தின் குறியீடு';

  @override
  String get userId => 'பயனர் ஐடி';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get invalidCompanyCode => 'தவறான நிறுவனக் குறியீடு';

  @override
  String get pleaseEnterCompanyCode => 'நிறுவனத்தின் குறியீட்டை உள்ளிடவும்';

  @override
  String get pleaseEnterUserId => 'பயனர் ஐடியை உள்ளிடவும்';

  @override
  String get pleaseEnterPassword => 'கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get loginFailed => 'உள்நுழைவு தோல்வியடைந்தது';

  @override
  String get loginSuccess => 'உள்நுழைவு வெற்றி';

  @override
  String get challan => 'சலான்';

  @override
  String get pendingChallan => 'நிலுவையில் உள்ள சலான்';

  @override
  String get retailIncentive => 'சில்லறை ஊக்கத்தொகை';

  @override
  String get loadingChallans => 'சலான்களை ஏற்றுகிறது...';

  @override
  String get failedToLoadChallans => 'சலான்களை ஏற்ற முடியவில்லை';

  @override
  String get noChallansFound => 'சலான்கள் எதுவும் கிடைக்கவில்லை';

  @override
  String get pullToRefresh => 'புதுப்பிக்க இழுக்கவும் அல்லது பிறகு பார்க்கவும்';

  @override
  String get date => 'தேதி';

  @override
  String get challanDate => 'சலான் தேதி';

  @override
  String get expectedDeliveryDate => 'எதிர்பார்க்கப்படும் டெலிவரி தேதி';

  @override
  String get challanNo => 'சலான் எண்';

  @override
  String get customerName => 'வாடிக்கையாளர் பெயர்';

  @override
  String get action => 'செயல்';

  @override
  String get edit => 'திருத்தவும்';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get refresh => 'புதுப்பிக்கவும்';

  @override
  String get showDate => 'காட்சி தேதி:';

  @override
  String get expectedDelivery => 'எதிர்பார்த்த டெலிவரி';

  @override
  String records(int count, String plural) {
    return '$count பதிவு$plural';
  }

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get languageChanged => 'மொழி வெற்றிகரமாக மாற்றப்பட்டது';

  @override
  String get home => 'வீடு';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get confirmLogout => 'நிச்சயமாக வெளியேற விரும்புகிறீர்களா?';

  @override
  String get yes => 'ஆம்';

  @override
  String get no => 'இல்லை';

  @override
  String get error => 'பிழை';

  @override
  String get success => 'வெற்றி';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get serverError => 'சர்வர் பிழை';

  @override
  String get networkError => 'நெட்வொர்க் பிழை. உங்கள் இணைப்பைச் சரிபார்க்கவும்.';
}
