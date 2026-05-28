// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'માયઓટોશોપ';

  @override
  String get login => 'લોગિન';

  @override
  String get companyCode => 'કંપની કોડ';

  @override
  String get userId => 'યુઝર આઈડી';

  @override
  String get password => 'પાસવર્ડ';

  @override
  String get invalidCompanyCode => 'અમાન્ય કંપની કોડ';

  @override
  String get pleaseEnterCompanyCode => 'કૃપા કરીને કંપની કોડ દાખલ કરો';

  @override
  String get pleaseEnterUserId => 'કૃપા કરીને યુઝર આઈડી દાખલ કરો';

  @override
  String get pleaseEnterPassword => 'કૃપા કરીને પાસવર્ડ દાખલ કરો';

  @override
  String get loginFailed => 'લોગિન નિષ્ફળ';

  @override
  String get loginSuccess => 'લોગિન સફળ';

  @override
  String get challan => 'ચલણ';

  @override
  String get pendingChallan => 'બાકી ચલણ';

  @override
  String get retailIncentive => 'રિટેલ પ્રોત્સાહન';

  @override
  String get loadingChallans => 'ચલણ લોડ થઈ રહ્યા છે...';

  @override
  String get failedToLoadChallans => 'ચલણ લોડ કરવામાં નિષ્ફળ';

  @override
  String get noChallansFound => 'કોઈ ચલણ મળ્યા નથી';

  @override
  String get pullToRefresh => 'રિફ્રેશ કરવા માટે ખેંચો અથવા પછીથી તપાસો';

  @override
  String get date => 'તારીખ';

  @override
  String get challanDate => 'ચલણ તારીખ';

  @override
  String get expectedDeliveryDate => 'અપેક્ષિત ડિલિવરી તારીખ';

  @override
  String get challanNo => 'ચલણ નંબર';

  @override
  String get customerName => 'ગ્રાહકનું નામ';

  @override
  String get action => 'ક્રિયા';

  @override
  String get edit => 'સંપાદિત કરો';

  @override
  String get save => 'સાચવો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get retry => 'ફરી પ્રયાસ કરો';

  @override
  String get refresh => 'રિફ્રેશ';

  @override
  String get showDate => 'તારીખ બતાવો:';

  @override
  String get expectedDelivery => 'અપેક્ષિત ડિલિવરી';

  @override
  String records(int count, String plural) {
    return '$count રેકોર્ડ$plural';
  }

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get language => 'ભાષા';

  @override
  String get selectLanguage => 'ભાષા પસંદ કરો';

  @override
  String get languageChanged => 'ભાષા સફળતાપૂર્વક બદલાઈ';

  @override
  String get home => 'હોમ';

  @override
  String get notifications => 'સૂચનાઓ';

  @override
  String get profile => 'પ્રોફાઇલ';

  @override
  String get logout => 'લોગઆઉટ';

  @override
  String get confirmLogout => 'શું તમે ખરેખર લોગઆઉટ કરવા માંગો છો?';

  @override
  String get yes => 'હા';

  @override
  String get no => 'ના';

  @override
  String get error => 'ભૂલ';

  @override
  String get success => 'સફળતા';

  @override
  String get loading => 'લોડ થઈ રહ્યું છે...';

  @override
  String get serverError => 'સર્વર ભૂલ';

  @override
  String get networkError => 'નેટવર્ક ભૂલ. કૃપા કરીને તમારું કનેક્શન તપાસો.';
}
