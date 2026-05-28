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
}
