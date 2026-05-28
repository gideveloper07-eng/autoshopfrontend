// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Login';

  @override
  String get companyCode => 'Codice Aziendale';

  @override
  String get userId => 'ID utente';

  @override
  String get password => 'Password';

  @override
  String get invalidCompanyCode => 'Codice azienda non valido';

  @override
  String get pleaseEnterCompanyCode => 'Inserisci il codice azienda';

  @override
  String get pleaseEnterUserId => 'Inserisci l\'ID utente';

  @override
  String get pleaseEnterPassword => 'Inserisci la password';

  @override
  String get loginFailed => 'Accesso non riuscito';

  @override
  String get loginSuccess => 'Accesso riuscito';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'In attesa di Challan';

  @override
  String get retailIncentive => 'Incentivo al dettaglio';

  @override
  String get loadingChallans => 'Caricamento sfide...';

  @override
  String get failedToLoadChallans => 'Impossibile caricare le sfide';

  @override
  String get noChallansFound => 'Nessun sfidante trovato';

  @override
  String get pullToRefresh => 'Tira per aggiornare o controlla più tardi';

  @override
  String get date => 'Data';

  @override
  String get challanDate => 'Data di Challan';

  @override
  String get expectedDeliveryDate => 'Data di consegna prevista';

  @override
  String get challanNo => 'Challan no';

  @override
  String get customerName => 'Nome del cliente';

  @override
  String get action => 'Azione';

  @override
  String get edit => 'Modificare';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Cancellare';

  @override
  String get retry => 'Riprova';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get showDate => 'Mostra data:';

  @override
  String get expectedDelivery => 'Consegna prevista';

  @override
  String records(int count, String plural) {
    return '$count Registra$plural';
  }

  @override
  String get settings => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get languageChanged => 'La lingua è stata modificata con successo';

  @override
  String get home => 'Casa';

  @override
  String get notifications => 'Notifiche';

  @override
  String get profile => 'Profilo';

  @override
  String get logout => 'Esci';

  @override
  String get confirmLogout => 'Sei sicuro di voler uscire?';

  @override
  String get yes => 'SÌ';

  @override
  String get no => 'NO';

  @override
  String get error => 'Errore';

  @override
  String get success => 'Successo';

  @override
  String get loading => 'Caricamento...';

  @override
  String get serverError => 'Errore del server';

  @override
  String get networkError => 'Errore di rete. Per favore controlla la tua connessione.';
}
