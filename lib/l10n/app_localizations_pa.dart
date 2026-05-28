// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get appTitle => 'ਮਾਈਆਟੋਸ਼ਾਪ';

  @override
  String get login => 'ਲਾਗਇਨ';

  @override
  String get companyCode => 'ਕੰਪਨੀ ਕੋਡ';

  @override
  String get userId => 'ਯੂਜ਼ਰ ਆਈਡੀ';

  @override
  String get password => 'ਪਾਸਵਰਡ';

  @override
  String get invalidCompanyCode => 'ਗਲਤ ਕੰਪਨੀ ਕੋਡ';

  @override
  String get pleaseEnterCompanyCode => 'ਕਿਰਪਾ ਕਰਕੇ ਕੰਪਨੀ ਕੋਡ ਦਾਖਲ ਕਰੋ';

  @override
  String get pleaseEnterUserId => 'ਕਿਰਪਾ ਕਰਕੇ ਯੂਜ਼ਰ ਆਈਡੀ ਦਾਖਲ ਕਰੋ';

  @override
  String get pleaseEnterPassword => 'ਕਿਰਪਾ ਕਰਕੇ ਪਾਸਵਰਡ ਦਾਖਲ ਕਰੋ';

  @override
  String get loginFailed => 'ਲਾਗਇਨ ਅਸਫਲ';

  @override
  String get loginSuccess => 'ਲਾਗਇਨ ਸਫਲ';

  @override
  String get challan => 'ਚਲਾਨ';

  @override
  String get pendingChallan => 'ਬਕਾਇਆ ਚਲਾਨ';

  @override
  String get retailIncentive => 'ਰਿਟੇਲ ਪ੍ਰੋਤਸਾਹਨ';

  @override
  String get loadingChallans => 'ਚਲਾਨ ਲੋਡ ਹੋ ਰਹੇ ਹਨ...';

  @override
  String get failedToLoadChallans => 'ਚਲਾਨ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਫਲ';

  @override
  String get noChallansFound => 'ਕੋਈ ਚਲਾਨ ਨਹੀਂ ਮਿਲਿਆ';

  @override
  String get pullToRefresh => 'ਤਾਜ਼ਾ ਕਰਨ ਲਈ ਖਿੱਚੋ ਜਾਂ ਬਾਅਦ ਵਿੱਚ ਜਾਂਚ ਕਰੋ';

  @override
  String get date => 'ਤਾਰੀਖ';

  @override
  String get challanDate => 'ਚਲਾਨ ਤਾਰੀਖ';

  @override
  String get expectedDeliveryDate => 'ਅਨੁਮਾਨਿਤ ਡਿਲੀਵਰੀ ਤਾਰੀਖ';

  @override
  String get challanNo => 'ਚਲਾਨ ਨੰਬਰ';

  @override
  String get customerName => 'ਗਾਹਕ ਦਾ ਨਾਮ';

  @override
  String get action => 'ਕਾਰਵਾਈ';

  @override
  String get edit => 'ਸੰਪਾਦਿਤ ਕਰੋ';

  @override
  String get save => 'ਸੇਵ ਕਰੋ';

  @override
  String get cancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get retry => 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get refresh => 'ਤਾਜ਼ਾ ਕਰੋ';

  @override
  String get showDate => 'ਤਾਰੀਖ ਦਿਖਾਓ:';

  @override
  String get expectedDelivery => 'ਅਨੁਮਾਨਿਤ ਡਿਲੀਵਰੀ';

  @override
  String records(int count, String plural) {
    return '$count ਰਿਕਾਰਡ$plural';
  }

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get selectLanguage => 'ਭਾਸ਼ਾ ਚੁਣੋ';

  @override
  String get languageChanged => 'ਭਾਸ਼ਾ ਸਫਲਤਾਪੂਰਵਕ ਬਦਲੀ ਗਈ';

  @override
  String get home => 'ਹੋਮ';

  @override
  String get notifications => 'ਸੂਚਨਾਵਾਂ';

  @override
  String get profile => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get logout => 'ਲਾਗਆਉਟ';

  @override
  String get confirmLogout => 'ਕੀ ਤੁਸੀਂ ਯਕੀਨੀ ਤੌਰ \'ਤੇ ਲਾਗਆਉਟ ਕਰਨਾ ਚਾਹੁੰਦੇ ਹੋ?';

  @override
  String get yes => 'ਹਾਂ';

  @override
  String get no => 'ਨਹੀਂ';

  @override
  String get error => 'ਗਲਤੀ';

  @override
  String get success => 'ਸਫਲਤਾ';

  @override
  String get loading => 'ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...';

  @override
  String get serverError => 'ਸਰਵਰ ਗਲਤੀ';

  @override
  String get networkError => 'ਨੈੱਟਵਰਕ ਗਲਤੀ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਕਨੈਕਸ਼ਨ ਜਾਂਚੋ।';
}
