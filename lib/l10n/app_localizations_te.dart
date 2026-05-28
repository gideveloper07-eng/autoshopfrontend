// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'లాగిన్ చేయండి';

  @override
  String get companyCode => 'కంపెనీ కోడ్';

  @override
  String get userId => 'వినియోగదారు ID';

  @override
  String get password => 'పాస్వర్డ్';

  @override
  String get invalidCompanyCode => 'చెల్లని కంపెనీ కోడ్';

  @override
  String get pleaseEnterCompanyCode => 'దయచేసి కంపెనీ కోడ్‌ని నమోదు చేయండి';

  @override
  String get pleaseEnterUserId => 'దయచేసి వినియోగదారు IDని నమోదు చేయండి';

  @override
  String get pleaseEnterPassword => 'దయచేసి పాస్‌వర్డ్‌ని నమోదు చేయండి';

  @override
  String get loginFailed => 'లాగిన్ విఫలమైంది';

  @override
  String get loginSuccess => 'లాగిన్ విజయవంతమైంది';

  @override
  String get challan => 'చలాన్';

  @override
  String get pendingChallan => 'పెండింగ్ చలాన్';

  @override
  String get retailIncentive => 'రిటైల్ ప్రోత్సాహకం';

  @override
  String get loadingChallans => 'చలాన్లు లోడ్ అవుతోంది...';

  @override
  String get failedToLoadChallans => 'చలాన్‌లను లోడ్ చేయడంలో విఫలమైంది';

  @override
  String get noChallansFound => 'చలాన్లు ఏవీ కనుగొనబడలేదు';

  @override
  String get pullToRefresh => 'రిఫ్రెష్ చేయడానికి లాగండి లేదా తర్వాత మళ్లీ తనిఖీ చేయండి';

  @override
  String get date => 'తేదీ';

  @override
  String get challanDate => 'చలాన్ తేదీ';

  @override
  String get expectedDeliveryDate => 'ఊహించిన డెలివరీ తేదీ';

  @override
  String get challanNo => 'చలాన్ నం';

  @override
  String get customerName => 'కస్టమర్ పేరు';

  @override
  String get action => 'చర్య';

  @override
  String get edit => 'సవరించు';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get cancel => 'రద్దు చేయి';

  @override
  String get retry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get refresh => 'రిఫ్రెష్ చేయండి';

  @override
  String get showDate => 'తేదీని చూపు:';

  @override
  String get expectedDelivery => 'ఆశించిన డెలివరీ';

  @override
  String records(int count, String plural) {
    return '$count రికార్డ్$plural';
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
  String get logout => 'లాగ్అవుట్';

  @override
  String get confirmLogout => 'మీరు ఖచ్చితంగా లాగ్ అవుట్ చేయాలనుకుంటున్నారా?';

  @override
  String get yes => 'అవును';

  @override
  String get no => 'నం';

  @override
  String get error => 'లోపం';

  @override
  String get success => 'విజయం';

  @override
  String get loading => 'లోడ్ అవుతోంది...';

  @override
  String get serverError => 'సర్వర్ లోపం';

  @override
  String get networkError => 'నెట్‌వర్క్ లోపం. దయచేసి మీ కనెక్షన్‌ని తనిఖీ చేయండి.';
}
