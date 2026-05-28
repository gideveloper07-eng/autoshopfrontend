// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Login';

  @override
  String get companyCode => 'Firmencode';

  @override
  String get userId => 'Benutzer-ID';

  @override
  String get password => 'Passwort';

  @override
  String get invalidCompanyCode => 'Ungültiger Firmencode';

  @override
  String get pleaseEnterCompanyCode => 'Bitte geben Sie den Firmencode ein';

  @override
  String get pleaseEnterUserId => 'Bitte geben Sie die Benutzer-ID ein';

  @override
  String get pleaseEnterPassword => 'Bitte geben Sie das Passwort ein';

  @override
  String get loginFailed => 'Fehler bei der Anmeldung';

  @override
  String get loginSuccess => 'Anmeldung erfolgreich';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'Ausstehende Challan';

  @override
  String get retailIncentive => 'Anreiz für den Einzelhandel';

  @override
  String get loadingChallans => 'Lade Challans...';

  @override
  String get failedToLoadChallans => 'Challans konnten nicht geladen werden';

  @override
  String get noChallansFound => 'Keine Challans gefunden';

  @override
  String get pullToRefresh => 'Zum Aktualisieren ziehen oder später noch einmal vorbeischauen';

  @override
  String get date => 'Datum';

  @override
  String get challanDate => 'Challan-Datum';

  @override
  String get expectedDeliveryDate => 'Voraussichtlicher Liefertermin';

  @override
  String get challanNo => 'Challan Nr';

  @override
  String get customerName => 'Kundenname';

  @override
  String get action => 'Aktion';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Stornieren';

  @override
  String get retry => 'Wiederholen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get showDate => 'Showdatum:';

  @override
  String get expectedDelivery => 'Lieferung voraussichtlich';

  @override
  String records(int count, String plural) {
    return '$count Datensatz$plural';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Wählen Sie Sprache aus';

  @override
  String get languageChanged => 'Die Sprache wurde erfolgreich geändert';

  @override
  String get home => 'Heim';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Abmelden';

  @override
  String get confirmLogout => 'Sind Sie sicher, dass Sie sich abmelden möchten?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'NEIN';

  @override
  String get error => 'Fehler';

  @override
  String get success => 'Erfolg';

  @override
  String get loading => 'Laden...';

  @override
  String get serverError => 'Serverfehler';

  @override
  String get networkError => 'Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.';
}
