// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Login';

  @override
  String get companyCode => 'Kodeks firmy';

  @override
  String get userId => 'Identyfikator użytkownika';

  @override
  String get password => 'Hasło';

  @override
  String get invalidCompanyCode => 'Nieprawidłowy kod firmy';

  @override
  String get pleaseEnterCompanyCode => 'Proszę wpisać kod firmy';

  @override
  String get pleaseEnterUserId => 'Proszę wprowadzić identyfikator użytkownika';

  @override
  String get pleaseEnterPassword => 'Proszę wprowadzić hasło';

  @override
  String get loginFailed => 'Logowanie nie powiodło się';

  @override
  String get loginSuccess => 'Logowanie powiodło się';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'W oczekiwaniu na Challana';

  @override
  String get retailIncentive => 'Zachęta detaliczna';

  @override
  String get loadingChallans => 'Ładowanie wyzwań...';

  @override
  String get failedToLoadChallans => 'Nie udało się załadować challans';

  @override
  String get noChallansFound => 'Nie znaleziono żadnych challanów';

  @override
  String get pullToRefresh => 'Pociągnij, aby odświeżyć, lub sprawdź później';

  @override
  String get date => 'Data';

  @override
  String get challanDate => 'Data Challana';

  @override
  String get expectedDeliveryDate => 'Oczekiwana data dostawy';

  @override
  String get challanNo => 'Chalan nr';

  @override
  String get customerName => 'Nazwa klienta';

  @override
  String get action => 'Działanie';

  @override
  String get edit => 'Redagować';

  @override
  String get save => 'Ratować';

  @override
  String get cancel => 'Anulować';

  @override
  String get retry => 'Spróbować ponownie';

  @override
  String get refresh => 'Odświeżać';

  @override
  String get showDate => 'Data pokazu:';

  @override
  String get expectedDelivery => 'Oczekiwana dostawa';

  @override
  String records(int count, String plural) {
    return '$count Nagraj$plural';
  }

  @override
  String get settings => 'Ustawienia';

  @override
  String get language => 'Język';

  @override
  String get selectLanguage => 'Wybierz Język';

  @override
  String get languageChanged => 'Język został pomyślnie zmieniony';

  @override
  String get home => 'Dom';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Wyloguj się';

  @override
  String get confirmLogout => 'Czy na pewno chcesz się wylogować?';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'NIE';

  @override
  String get error => 'Błąd';

  @override
  String get success => 'Sukces';

  @override
  String get loading => 'Załadunek...';

  @override
  String get serverError => 'Błąd serwera';

  @override
  String get networkError => 'Błąd sieci. Sprawdź swoje połączenie.';

  @override
  String get challanDetails => 'Szczegóły Challana';

  @override
  String get challanNoLabel => 'Chalan nr';

  @override
  String get loadingChallanDetails => 'Ładowanie szczegółów challanu...';

  @override
  String get failedToLoadDetails => 'Nie udało się załadować szczegółów';

  @override
  String get showSelectionCheckboxes => 'Pokaż pola wyboru';

  @override
  String get enableCheckboxesHelp => 'Włącz pola wyboru, aby wybrać pola dla uwag o odrzuceniu';

  @override
  String get basicInformation => 'Podstawowe informacje';

  @override
  String get pricingDetails => 'Szczegóły cenowe';

  @override
  String get discountsAndOffers => 'Rabaty i oferty';

  @override
  String get discountTitle => 'Rabat';

  @override
  String get rtoDetails => 'Szczegóły RTO';

  @override
  String get taxDetails => 'Szczegóły podatku';

  @override
  String get insuranceDetails => 'Szczegóły ubezpieczenia';

  @override
  String get financialDetails => 'Szczegóły finansowe';

  @override
  String get customerInformation => 'Informacje o kliencie';

  @override
  String get customerLabel => 'Klient';

  @override
  String get exShowroomLabel => 'Były salon';

  @override
  String get corporateLabel => 'Zbiorowy';

  @override
  String get subtotalLabel => 'Suma częściowa';

  @override
  String get rtoAmountLabel => 'Kwota RTO';

  @override
  String get insuranceAmtLabel => 'Wysokość ubezpieczenia';

  @override
  String get netAmountLabel => 'Kwota netto';

  @override
  String get mobileLabel => 'Przenośny';

  @override
  String get rejectRemarkTitle => 'Odrzuć uwagę';

  @override
  String get checkedFieldInfo => 'Zaznaczone pola zostały dodane poniżej. Możesz edytować przed odrzuceniem:';

  @override
  String get rejectRemarkHint => 'Odrzuć uwagę (uzupełniana automatycznie z zaznaczonych pól)...';

  @override
  String get rejectChallan => 'Odrzuć Challana';

  @override
  String get approve => 'Zatwierdzić';

  @override
  String get reject => 'Odrzucić';

  @override
  String get pleaseSelectFieldOrReason => 'Proszę zaznaczyć przynajmniej jedno pole lub podać powód odrzucenia';
}
