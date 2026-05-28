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

  @override
  String get challanDetails => 'Dettagli Challan';

  @override
  String get challanNoLabel => 'Challan no';

  @override
  String get loadingChallanDetails => 'Caricamento dettagli sfida...';

  @override
  String get failedToLoadDetails => 'Impossibile caricare i dettagli';

  @override
  String get showSelectionCheckboxes => 'Mostra caselle di controllo di selezione';

  @override
  String get enableCheckboxesHelp => 'Abilita le caselle di controllo per selezionare i campi per i commenti di rifiuto';

  @override
  String get basicInformation => 'Informazioni di base';

  @override
  String get pricingDetails => 'Dettagli sui prezzi';

  @override
  String get discountsAndOffers => 'Sconti e offerte';

  @override
  String get discountTitle => 'Sconto';

  @override
  String get rtoDetails => 'Dettagli RTO';

  @override
  String get taxDetails => 'Dettagli fiscali';

  @override
  String get insuranceDetails => 'Dettagli dell\'assicurazione';

  @override
  String get financialDetails => 'Dettagli finanziari';

  @override
  String get customerInformation => 'Informazioni sul cliente';

  @override
  String get customerLabel => 'Cliente';

  @override
  String get exShowroomLabel => 'Ex Showroom';

  @override
  String get corporateLabel => 'Aziendale';

  @override
  String get subtotalLabel => 'Totale parziale';

  @override
  String get rtoAmountLabel => 'Importo RTO';

  @override
  String get insuranceAmtLabel => 'Amt. Assicurazione';

  @override
  String get netAmountLabel => 'Importo netto';

  @override
  String get mobileLabel => 'Mobile';

  @override
  String get rejectRemarkTitle => 'Rifiuta l\'osservazione';

  @override
  String get checkedFieldInfo => 'I campi selezionati vengono aggiunti di seguito. Puoi modificare prima di rifiutare:';

  @override
  String get rejectRemarkHint => 'Rifiuta commento (compilato automaticamente dai campi selezionati)...';

  @override
  String get rejectChallan => 'Rifiuta Challan';

  @override
  String get approve => 'Approvare';

  @override
  String get reject => 'Rifiutare';

  @override
  String get pleaseSelectFieldOrReason => 'Seleziona almeno un campo o inserisci il motivo del rifiuto';
}
