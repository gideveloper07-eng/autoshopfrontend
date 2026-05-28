// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MiAutoTienda';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get companyCode => 'Código de empresa';

  @override
  String get userId => 'ID de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get invalidCompanyCode => 'Código de empresa inválido';

  @override
  String get pleaseEnterCompanyCode => 'Por favor ingrese el código de empresa';

  @override
  String get pleaseEnterUserId => 'Por favor ingrese el ID de usuario';

  @override
  String get pleaseEnterPassword => 'Por favor ingrese la contraseña';

  @override
  String get loginFailed => 'Inicio de sesión fallido';

  @override
  String get loginSuccess => 'Inicio de sesión exitoso';

  @override
  String get challan => 'Factura';

  @override
  String get pendingChallan => 'Factura pendiente';

  @override
  String get retailIncentive => 'Incentivo minorista';

  @override
  String get loadingChallans => 'Cargando facturas...';

  @override
  String get failedToLoadChallans => 'Error al cargar facturas';

  @override
  String get noChallansFound => 'No se encontraron facturas';

  @override
  String get pullToRefresh => 'Desliza para actualizar o vuelve más tarde';

  @override
  String get date => 'Fecha';

  @override
  String get challanDate => 'Fecha de factura';

  @override
  String get expectedDeliveryDate => 'Fecha de entrega esperada';

  @override
  String get challanNo => 'Número de factura';

  @override
  String get customerName => 'Nombre del cliente';

  @override
  String get action => 'Acción';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Reintentar';

  @override
  String get refresh => 'Actualizar';

  @override
  String get showDate => 'Mostrar fecha:';

  @override
  String get expectedDelivery => 'Entrega esperada';

  @override
  String records(int count, String plural) {
    return '$count Registro$plural';
  }

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar idioma';

  @override
  String get languageChanged => 'Idioma cambiado exitosamente';

  @override
  String get home => 'Inicio';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get profile => 'Perfil';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get confirmLogout => '¿Estás seguro de que quieres cerrar sesión?';

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
  String get networkError => 'Error de red. Por favor verifica tu conexión.';
}
