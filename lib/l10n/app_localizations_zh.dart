// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => '登录';

  @override
  String get companyCode => '公司代码';

  @override
  String get userId => '用户身份';

  @override
  String get password => '密码';

  @override
  String get invalidCompanyCode => '公司代码无效';

  @override
  String get pleaseEnterCompanyCode => '请输入公司代码';

  @override
  String get pleaseEnterUserId => '请输入用户ID';

  @override
  String get pleaseEnterPassword => '请输入密码';

  @override
  String get loginFailed => '登录失败';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get challan => '查兰';

  @override
  String get pendingChallan => '待查兰';

  @override
  String get retailIncentive => '零售激励';

  @override
  String get loadingChallans => '加载中...';

  @override
  String get failedToLoadChallans => '加载查兰失败';

  @override
  String get noChallansFound => '没有找到查兰';

  @override
  String get pullToRefresh => '拉动刷新或稍后再回来查看';

  @override
  String get date => '日期';

  @override
  String get challanDate => '查兰伊达';

  @override
  String get expectedDeliveryDate => '预计交货日期';

  @override
  String get challanNo => '查兰诺';

  @override
  String get customerName => '客户名称';

  @override
  String get action => '行动';

  @override
  String get edit => '编辑';

  @override
  String get save => '节省';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get refresh => '刷新';

  @override
  String get showDate => '演出日期：';

  @override
  String get expectedDelivery => '预计交付';

  @override
  String records(int count, String plural) {
    return '$count 记录$plural';
  }

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get languageChanged => '语言更改成功';

  @override
  String get home => '家';

  @override
  String get notifications => '通知';

  @override
  String get profile => '轮廓';

  @override
  String get logout => '退出';

  @override
  String get confirmLogout => '您确定要退出吗？';

  @override
  String get yes => '是的';

  @override
  String get no => '不';

  @override
  String get error => '错误';

  @override
  String get success => '成功';

  @override
  String get loading => '加载中...';

  @override
  String get serverError => '服务器错误';

  @override
  String get networkError => '网络错误。请检查您的连接。';
}
