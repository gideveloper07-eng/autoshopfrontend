// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Login';

  @override
  String get companyCode => 'Bedrijfscode';

  @override
  String get userId => 'Gebruikers-ID';

  @override
  String get password => 'Wachtwoord';

  @override
  String get invalidCompanyCode => 'Ongeldige bedrijfscode';

  @override
  String get pleaseEnterCompanyCode => 'Voer de bedrijfscode in';

  @override
  String get pleaseEnterUserId => 'Voer een gebruikers-ID in';

  @override
  String get pleaseEnterPassword => 'Voer het wachtwoord in';

  @override
  String get loginFailed => 'Inloggen mislukt';

  @override
  String get loginSuccess => 'Inloggen succesvol';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'In afwachting van Challan';

  @override
  String get retailIncentive => 'Detailhandelstimulans';

  @override
  String get loadingChallans => 'Challans laden...';

  @override
  String get failedToLoadChallans => 'Kan challans niet laden';

  @override
  String get noChallansFound => 'Geen challans gevonden';

  @override
  String get pullToRefresh => 'Trek om te vernieuwen of kom later terug';

  @override
  String get date => 'Datum';

  @override
  String get challanDate => 'Challan-datum';

  @override
  String get expectedDeliveryDate => 'Verwachte leverdatum';

  @override
  String get challanNo => 'Challan Nee';

  @override
  String get customerName => 'Klantnaam';

  @override
  String get action => 'Actie';

  @override
  String get edit => 'Bewerking';

  @override
  String get save => 'Redden';

  @override
  String get cancel => 'Annuleren';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get refresh => 'Vernieuwen';

  @override
  String get showDate => 'Showdatum:';

  @override
  String get expectedDelivery => 'Verwachte levering';

  @override
  String records(int count, String plural) {
    return '$count Opnemen$plural';
  }

  @override
  String get settings => 'Instellingen';

  @override
  String get language => 'Taal';

  @override
  String get selectLanguage => 'Selecteer Taal';

  @override
  String get languageChanged => 'Taal is succesvol gewijzigd';

  @override
  String get home => 'Thuis';

  @override
  String get notifications => 'Meldingen';

  @override
  String get profile => 'Profiel';

  @override
  String get logout => 'Uitloggen';

  @override
  String get confirmLogout => 'Weet u zeker dat u wilt uitloggen?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nee';

  @override
  String get error => 'Fout';

  @override
  String get success => 'Succes';

  @override
  String get loading => 'Laden...';

  @override
  String get serverError => 'Serverfout';

  @override
  String get networkError => 'Netwerkfout. Controleer uw verbinding.';
}
