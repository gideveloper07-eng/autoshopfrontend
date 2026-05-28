// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Acceso';

  @override
  String get companyCode => 'Código de empresa';

  @override
  String get userId => 'ID de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get invalidCompanyCode => 'Código de empresa no válido';

  @override
  String get pleaseEnterCompanyCode => 'Por favor introduzca el código de la empresa';

  @override
  String get pleaseEnterUserId => 'Por favor ingrese el ID de usuario';

  @override
  String get pleaseEnterPassword => 'Por favor ingrese la contraseña';

  @override
  String get loginFailed => 'Error de inicio de sesion';

  @override
  String get loginSuccess => 'Iniciar sesión exitosamente';

  @override
  String get challan => 'Chalán';

  @override
  String get pendingChallan => 'Pendiente Challan';

  @override
  String get retailIncentive => 'Incentivo al por menor';

  @override
  String get loadingChallans => 'Cargando challans...';

  @override
  String get failedToLoadChallans => 'No se pudo cargar challans';

  @override
  String get noChallansFound => 'No se encontró challan';

  @override
  String get pullToRefresh => 'Tira para actualizar o vuelve a consultar más tarde';

  @override
  String get date => 'Fecha';

  @override
  String get challanDate => 'Fecha Challan';

  @override
  String get expectedDeliveryDate => 'Fecha de entrega prevista';

  @override
  String get challanNo => 'Challan No';

  @override
  String get customerName => 'Nombre del cliente';

  @override
  String get action => 'Acción';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Ahorrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Rever';

  @override
  String get refresh => 'Refrescar';

  @override
  String get showDate => 'Mostrar fecha:';

  @override
  String get expectedDelivery => 'Entrega esperada';

  @override
  String records(int count, String plural) {
    return '$count Registro$plural';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get languageChanged => 'El idioma cambió exitosamente';

  @override
  String get home => 'Hogar';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get profile => 'Perfil';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get confirmLogout => '¿Está seguro de que desea cerrar sesión?';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get error => 'Error';

  @override
  String get success => 'Éxito';

  @override
  String get loading => 'Cargando...';

  @override
  String get serverError => 'Error del servidor';

  @override
  String get networkError => 'Error de red. Por favor verifique su conexión.';
}
