// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Авторизоваться';

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
  String get pleaseEnterUserId => 'Пожалуйста, введите идентификатор пользователя';

  @override
  String get pleaseEnterPassword => 'Пожалуйста, введите пароль';

  @override
  String get loginFailed => 'Ошибка входа';

  @override
  String get loginSuccess => 'Вход успешен';

  @override
  String get challan => 'Чаллан';

  @override
  String get pendingChallan => 'В ожидании Чаллана';

  @override
  String get retailIncentive => 'Розничная Стимулирование';

  @override
  String get loadingChallans => 'Загрузка шаланов...';

  @override
  String get failedToLoadChallans => 'Не удалось загрузить шаланы';

  @override
  String get noChallansFound => 'Чаланы не найдены';

  @override
  String get pullToRefresh => 'Потяните, чтобы обновить или зайдите позже.';

  @override
  String get date => 'Дата';

  @override
  String get challanDate => 'Дата Чалана';

  @override
  String get expectedDeliveryDate => 'Ожидаемая дата доставки';

  @override
  String get challanNo => 'Чаллан Нет';

  @override
  String get customerName => 'Имя клиента';

  @override
  String get action => 'Действие';

  @override
  String get edit => 'Редактировать';

  @override
  String get save => 'Сохранять';

  @override
  String get cancel => 'Отмена';

  @override
  String get retry => 'Повторить попытку';

  @override
  String get refresh => 'Обновить';

  @override
  String get showDate => 'Дата показа:';

  @override
  String get expectedDelivery => 'Ожидаемая доставка';

  @override
  String records(int count, String plural) {
    return '$count Запись$plural';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get languageChanged => 'Язык успешно изменен';

  @override
  String get home => 'Дом';

  @override
  String get notifications => 'Уведомления';

  @override
  String get profile => 'Профиль';

  @override
  String get logout => 'Выход из системы';

  @override
  String get confirmLogout => 'Вы уверены, что хотите выйти из системы?';

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
  String get networkError => 'Сетевая ошибка. Пожалуйста, проверьте ваше соединение.';
}
