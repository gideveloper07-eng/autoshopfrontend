// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'മൈഓട്ടോഷോപ്പ്';

  @override
  String get login => 'ലോഗിൻ';

  @override
  String get companyCode => 'കമ്പനി കോഡ്';

  @override
  String get userId => 'യൂസർ ഐഡി';

  @override
  String get password => 'പാസ്‌വേഡ്';

  @override
  String get invalidCompanyCode => 'അസാധുവായ കമ്പനി കോഡ്';

  @override
  String get pleaseEnterCompanyCode => 'ദയവായി കമ്പനി കോഡ് നൽകുക';

  @override
  String get pleaseEnterUserId => 'ദയവായി യൂസർ ഐഡി നൽകുക';

  @override
  String get pleaseEnterPassword => 'ദയവായി പാസ്‌വേഡ് നൽകുക';

  @override
  String get loginFailed => 'ലോഗിൻ പരാജയപ്പെട്ടു';

  @override
  String get loginSuccess => 'ലോഗിൻ വിജയിച്ചു';

  @override
  String get challan => 'ചലാൻ';

  @override
  String get pendingChallan => 'തീർപ്പാക്കാത്ത ചലാൻ';

  @override
  String get retailIncentive => 'റീട്ടെയിൽ പ്രോത്സാഹനം';

  @override
  String get loadingChallans => 'ചലാനുകൾ ലോഡ് ചെയ്യുന്നു...';

  @override
  String get failedToLoadChallans => 'ചലാനുകൾ ലോഡ് ചെയ്യുന്നതിൽ പരാജയപ്പെട്ടു';

  @override
  String get noChallansFound => 'ചലാനുകളൊന്നും കണ്ടെത്തിയില്ല';

  @override
  String get pullToRefresh =>
      'പുതുക്കാൻ വലിക്കുക അല്ലെങ്കിൽ പിന്നീട് പരിശോധിക്കുക';

  @override
  String get date => 'തീയതി';

  @override
  String get challanDate => 'ചലാൻ തീയതി';

  @override
  String get expectedDeliveryDate => 'പ്രതീക്ഷിക്കുന്ന ഡെലിവറി തീയതി';

  @override
  String get challanNo => 'ചലാൻ നമ്പർ';

  @override
  String get customerName => 'ഉപഭോക്താവിന്റെ പേര്';

  @override
  String get action => 'പ്രവർത്തനം';

  @override
  String get edit => 'എഡിറ്റ്';

  @override
  String get save => 'സേവ്';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get retry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get refresh => 'പുതുക്കുക';

  @override
  String get showDate => 'തീയതി കാണിക്കുക:';

  @override
  String get expectedDelivery => 'പ്രതീക്ഷിക്കുന്ന ഡെലിവറി';

  @override
  String records(int count, String plural) {
    return '$count റെക്കോർഡ്$plural';
  }

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get language => 'ഭാഷ';

  @override
  String get selectLanguage => 'ഭാഷ തിരഞ്ഞെടുക്കുക';

  @override
  String get languageChanged => 'ഭാഷ വിജയകരമായി മാറ്റി';

  @override
  String get home => 'ഹോം';

  @override
  String get notifications => 'അറിയിപ്പുകൾ';

  @override
  String get profile => 'പ്രൊഫൈൽ';

  @override
  String get logout => 'ലോഗൗട്ട്';

  @override
  String get confirmLogout => 'നിങ്ങൾക്ക് തീർച്ചയായും ലോഗൗട്ട് ചെയ്യണോ?';

  @override
  String get yes => 'അതെ';

  @override
  String get no => 'ഇല്ല';

  @override
  String get error => 'പിശക്';

  @override
  String get success => 'വിജയം';

  @override
  String get loading => 'ലോഡ് ചെയ്യുന്നു...';

  @override
  String get serverError => 'സെർവർ പിശക്';

  @override
  String get networkError =>
      'നെറ്റ്‌വർക്ക് പിശക്. ദയവായി നിങ്ങളുടെ കണക്ഷൻ പരിശോധിക്കുക.';
}
