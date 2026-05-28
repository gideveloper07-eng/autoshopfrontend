// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'МойАвтоМагазин';

  @override
  String get login => 'Войти';

  @override
  String get companyCode => 'Код компании';

  @override
  String get userId => 'ID пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get invalidCompanyCode => 'Неверный код компании';

  @override
  String get pleaseEnterCompanyCode => 'Пожалуйста, введите код компании';

  @override
  String get pleaseEnterUserId => 'Пожалуйста, введите ID пользователя';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get loginFailed => 'Ошибка входа';

  @override
  String get loginSuccess => 'Вход выполнен успешно';

  @override
  String get challan => 'Накладная';

  @override
  String get pendingChallan => 'Ожидающая накладная';

  @override
  String get retailIncentive => 'Розничное поощрение';

  @override
  String get loadingChallans => 'Загрузка накладных...';

  @override
  String get failedToLoadChallans => 'Не удалось загрузить накладные';

  @override
  String get noChallansFound => 'Накладные не найдены';

  @override
  String get pullToRefresh => 'Потяните для обновления или проверьте позже';

  @override
  String get date => 'Дата';

  @override
  String get challanDate => 'Дата накладной';

  @override
  String get expectedDeliveryDate => 'Ожидаемая дата доставки';

  @override
  String get challanNo => 'Номер накладной';

  @override
  String get customerName => 'Имя клиента';

  @override
  String get action => 'Действие';

  @override
  String get edit => 'Редактировать';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить';

  @override
  String get refresh => 'Обновить';

  @override
  String get showDate => 'Показать дату:';

  @override
  String get expectedDelivery => 'Ожидаемая доставка';

  @override
  String records(int count, String plural) {
    return '$count запись$plural';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выбрать язык';

  @override
  String get languageChanged => 'Язык успешно изменен';

  @override
  String get home => 'Главная';

  @override
  String get notifications => 'Уведомления';

  @override
  String get profile => 'Профиль';

  @override
  String get logout => 'Выйти';

  @override
  String get confirmLogout => 'Вы уверены, что хотите выйти?';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успех';

  @override
  String get loading => 'Загрузка...';

  @override
  String get serverError => 'Ошибка сервера';

  @override
  String get networkError =>
      'Ошибка сети. Пожалуйста, проверьте ваше соединение.';
}
