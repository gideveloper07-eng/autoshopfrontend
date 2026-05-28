// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'మైఆటోషాప్';

  @override
  String get login => 'లాగిన్';

  @override
  String get companyCode => 'కంపెనీ కోడ్';

  @override
  String get userId => 'యూజర్ ఐడి';

  @override
  String get password => 'పాస్‌వర్డ్';

  @override
  String get invalidCompanyCode => 'చెల్లని కంపెనీ కోడ్';

  @override
  String get pleaseEnterCompanyCode => 'దయచేసి కంపెనీ కోడ్‌ను నమోదు చేయండి';

  @override
  String get pleaseEnterUserId => 'దయచేసి యూజర్ ఐడిని నమోదు చేయండి';

  @override
  String get pleaseEnterPassword => 'దయచేసి పాస్‌వర్డ్‌ను నమోదు చేయండి';

  @override
  String get loginFailed => 'లాగిన్ విఫలమైంది';

  @override
  String get loginSuccess => 'లాగిన్ విజయవంతం';

  @override
  String get challan => 'చలాన్';

  @override
  String get pendingChallan => 'పెండింగ్ చలాన్';

  @override
  String get retailIncentive => 'రిటైల్ ప్రోత్సాహకం';

  @override
  String get loadingChallans => 'చలాన్‌లు లోడ్ అవుతున్నాయి...';

  @override
  String get failedToLoadChallans => 'చలాన్‌లను లోడ్ చేయడంలో విఫలమైంది';

  @override
  String get noChallansFound => 'చలాన్‌లు కనుగొనబడలేదు';

  @override
  String get pullToRefresh =>
      'రిఫ్రెష్ చేయడానికి లాగండి లేదా తర్వాత తనిఖీ చేయండి';

  @override
  String get date => 'తేదీ';

  @override
  String get challanDate => 'చలాన్ తేదీ';

  @override
  String get expectedDeliveryDate => 'ఆశించిన డెలివరీ తేదీ';

  @override
  String get challanNo => 'చలాన్ నంబర్';

  @override
  String get customerName => 'కస్టమర్ పేరు';

  @override
  String get action => 'చర్య';

  @override
  String get edit => 'సవరించు';

  @override
  String get save => 'సేవ్';

  @override
  String get cancel => 'రద్దు';

  @override
  String get retry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get refresh => 'రిఫ్రెష్';

  @override
  String get showDate => 'తేదీని చూపించు:';

  @override
  String get expectedDelivery => 'ఆశించిన డెలివరీ';

  @override
  String records(int count, String plural) {
    return '$count రికార్డు$plural';
  }

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get language => 'భాష';

  @override
  String get selectLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get languageChanged => 'భాష విజయవంతంగా మార్చబడింది';

  @override
  String get home => 'హోమ్';

  @override
  String get notifications => 'నోటిఫికేషన్‌లు';

  @override
  String get profile => 'ప్రొఫైల్';

  @override
  String get logout => 'లాగౌట్';

  @override
  String get confirmLogout => 'మీరు ఖచ్చితంగా లాగౌట్ చేయాలనుకుంటున్నారా?';

  @override
  String get yes => 'అవును';

  @override
  String get no => 'కాదు';

  @override
  String get error => 'లోపం';

  @override
  String get success => 'విజయం';

  @override
  String get loading => 'లోడ్ అవుతోంది...';

  @override
  String get serverError => 'సర్వర్ లోపం';

  @override
  String get networkError =>
      'నెట్‌వర్క్ లోపం. దయచేసి మీ కనెక్షన్‌ను తనిఖీ చేయండి.';
}
