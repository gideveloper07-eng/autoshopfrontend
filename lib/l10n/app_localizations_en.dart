// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Login';

  @override
  String get companyCode => 'Company Code';

  @override
  String get userId => 'User ID';

  @override
  String get password => 'Password';

  @override
  String get invalidCompanyCode => 'Invalid Company Code';

  @override
  String get pleaseEnterCompanyCode => 'Please enter company code';

  @override
  String get pleaseEnterUserId => 'Please enter user ID';

  @override
  String get pleaseEnterPassword => 'Please enter password';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get loginSuccess => 'Login Successful';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'Pending Challan';

  @override
  String get retailIncentive => 'Retail Incentive';

  @override
  String get loadingChallans => 'Loading challans...';

  @override
  String get failedToLoadChallans => 'Failed to load challans';

  @override
  String get noChallansFound => 'No challans found';

  @override
  String get pullToRefresh => 'Pull to refresh or check back later';

  @override
  String get date => 'Date';

  @override
  String get challanDate => 'Challan Date';

  @override
  String get expectedDeliveryDate => 'Expected Delivery Date';

  @override
  String get challanNo => 'Challan No';

  @override
  String get customerName => 'Customer Name';

  @override
  String get action => 'Action';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get showDate => 'Show Date:';

  @override
  String get expectedDelivery => 'Expected Delivery';

  @override
  String records(int count, String plural) {
    return '$count Record$plural';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get home => 'Home';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Are you sure you want to logout?';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get serverError => 'Server Error';

  @override
  String get networkError => 'Network Error. Please check your connection.';
}
