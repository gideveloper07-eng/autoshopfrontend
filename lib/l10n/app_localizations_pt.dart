// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Conecte-se';

  @override
  String get companyCode => 'Código da Empresa';

  @override
  String get userId => 'ID do usuário';

  @override
  String get password => 'Senha';

  @override
  String get invalidCompanyCode => 'Código da empresa inválido';

  @override
  String get pleaseEnterCompanyCode => 'Por favor insira o código da empresa';

  @override
  String get pleaseEnterUserId => 'Por favor insira o ID do usuário';

  @override
  String get pleaseEnterPassword => 'Por favor insira a senha';

  @override
  String get loginFailed => 'Falha no login';

  @override
  String get loginSuccess => 'Login bem-sucedido';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'Challan pendente';

  @override
  String get retailIncentive => 'Incentivo ao Varejo';

  @override
  String get loadingChallans => 'Carregando desafios...';

  @override
  String get failedToLoadChallans => 'Falha ao carregar desafios';

  @override
  String get noChallansFound => 'Nenhum desafio encontrado';

  @override
  String get pullToRefresh => 'Puxe para atualizar ou verifique novamente mais tarde';

  @override
  String get date => 'Data';

  @override
  String get challanDate => 'Data do Challan';

  @override
  String get expectedDeliveryDate => 'Data de entrega prevista';

  @override
  String get challanNo => 'Challan Não';

  @override
  String get customerName => 'Nome do cliente';

  @override
  String get action => 'Ação';

  @override
  String get edit => 'Editar';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get refresh => 'Atualizar';

  @override
  String get showDate => 'Data de exibição:';

  @override
  String get expectedDelivery => 'Entrega Esperada';

  @override
  String records(int count, String plural) {
    return '$count Registro$plural';
  }

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Linguagem';

  @override
  String get selectLanguage => 'Selecione o idioma';

  @override
  String get languageChanged => 'Idioma alterado com sucesso';

  @override
  String get home => 'Lar';

  @override
  String get notifications => 'Notificações';

  @override
  String get profile => 'Perfil';

  @override
  String get logout => 'Sair';

  @override
  String get confirmLogout => 'Tem certeza de que deseja sair?';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get error => 'Erro';

  @override
  String get success => 'Sucesso';

  @override
  String get loading => 'Carregando...';

  @override
  String get serverError => 'Erro no servidor';

  @override
  String get networkError => 'Erro de rede. Por favor, verifique sua conexão.';
}
