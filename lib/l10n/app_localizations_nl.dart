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

  @override
  String get challanDetails => 'Challan-details';

  @override
  String get challanNoLabel => 'Challan Nee';

  @override
  String get loadingChallanDetails => 'Challan-details laden...';

  @override
  String get failedToLoadDetails => 'Kan details niet laden';

  @override
  String get showSelectionCheckboxes => 'Selectievakjes tonen';

  @override
  String get enableCheckboxesHelp => 'Schakel selectievakjes in om velden voor afwijzingsopmerkingen te selecteren';

  @override
  String get basicInformation => 'Basisinformatie';

  @override
  String get pricingDetails => 'Prijsdetails';

  @override
  String get discountsAndOffers => 'Kortingen en aanbiedingen';

  @override
  String get discountTitle => 'Korting';

  @override
  String get rtoDetails => 'RTO-details';

  @override
  String get taxDetails => 'Belastinggegevens';

  @override
  String get insuranceDetails => 'Verzekeringsgegevens';

  @override
  String get financialDetails => 'Financiële details';

  @override
  String get customerInformation => 'Klantinformatie';

  @override
  String get customerLabel => 'Klant';

  @override
  String get exShowroomLabel => 'Ex-showroom';

  @override
  String get corporateLabel => 'Zakelijk';

  @override
  String get subtotalLabel => 'Subtotaal';

  @override
  String get rtoAmountLabel => 'RTO-bedrag';

  @override
  String get insuranceAmtLabel => 'Verzekering Amt';

  @override
  String get netAmountLabel => 'Netto bedrag';

  @override
  String get mobileLabel => 'Mobiel';

  @override
  String get rejectRemarkTitle => 'Opmerking afwijzen';

  @override
  String get checkedFieldInfo => 'Hieronder zijn de aangevinkte velden toegevoegd. U kunt het volgende bewerken voordat u het afwijst:';

  @override
  String get rejectRemarkHint => 'Opmerking afwijzen (automatisch ingevuld uit aangevinkte velden)...';

  @override
  String get rejectChallan => 'Challan afwijzen';

  @override
  String get approve => 'Goedkeuren';

  @override
  String get reject => 'Afwijzen';

  @override
  String get pleaseSelectFieldOrReason => 'Vink minimaal één veld aan of voer een afwijzingsreden in';
}
