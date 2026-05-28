// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MeinAutoShop';

  @override
  String get login => 'Anmelden';

  @override
  String get companyCode => 'Firmencode';

  @override
  String get userId => 'Benutzer-ID';

  @override
  String get password => 'Passwort';

  @override
  String get invalidCompanyCode => 'Ungültiger Firmencode';

  @override
  String get pleaseEnterCompanyCode => 'Bitte Firmencode eingeben';

  @override
  String get pleaseEnterUserId => 'Bitte Benutzer-ID eingeben';

  @override
  String get pleaseEnterPassword => 'Bitte Passwort eingeben';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get loginSuccess => 'Anmeldung erfolgreich';

  @override
  String get challan => 'Lieferschein';

  @override
  String get pendingChallan => 'Ausstehender Lieferschein';

  @override
  String get retailIncentive => 'Einzelhandelsanreiz';

  @override
  String get loadingChallans => 'Lieferscheine werden geladen...';

  @override
  String get failedToLoadChallans => 'Laden der Lieferscheine fehlgeschlagen';

  @override
  String get noChallansFound => 'Keine Lieferscheine gefunden';

  @override
  String get pullToRefresh => 'Zum Aktualisieren ziehen oder später überprüfen';

  @override
  String get date => 'Datum';

  @override
  String get challanDate => 'Lieferscheindatum';

  @override
  String get expectedDeliveryDate => 'Voraussichtliches Lieferdatum';

  @override
  String get challanNo => 'Lieferscheinnummer';

  @override
  String get customerName => 'Kundenname';

  @override
  String get action => 'Aktion';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get retry => 'Wiederholen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get showDate => 'Datum anzeigen:';

  @override
  String get expectedDelivery => 'Voraussichtliche Lieferung';

  @override
  String records(int count, String plural) {
    return '$count Datensatz$plural';
  }

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get languageChanged => 'Sprache erfolgreich geändert';

  @override
  String get home => 'Startseite';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Abmelden';

  @override
  String get confirmLogout => 'Möchten Sie sich wirklich abmelden?';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get error => 'Fehler';

  @override
  String get success => 'Erfolg';

  @override
  String get loading => 'Wird geladen...';

  @override
  String get serverError => 'Serverfehler';

  @override
  String get networkError =>
      'Netzwerkfehler. Bitte überprüfen Sie Ihre Verbindung.';
}
