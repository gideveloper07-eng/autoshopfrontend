// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '我的汽车店';

  @override
  String get login => '登录';

  @override
  String get companyCode => '公司代码';

  @override
  String get userId => '用户ID';

  @override
  String get password => '密码';

  @override
  String get invalidCompanyCode => '无效的公司代码';

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
  String get challan => '送货单';

  @override
  String get pendingChallan => '待处理送货单';

  @override
  String get retailIncentive => '零售激励';

  @override
  String get loadingChallans => '正在加载送货单...';

  @override
  String get failedToLoadChallans => '加载送货单失败';

  @override
  String get noChallansFound => '未找到送货单';

  @override
  String get pullToRefresh => '下拉刷新或稍后查看';

  @override
  String get date => '日期';

  @override
  String get challanDate => '送货单日期';

  @override
  String get expectedDeliveryDate => '预计交货日期';

  @override
  String get challanNo => '送货单号';

  @override
  String get customerName => '客户姓名';

  @override
  String get action => '操作';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get refresh => '刷新';

  @override
  String get showDate => '显示日期：';

  @override
  String get expectedDelivery => '预计交货';

  @override
  String records(int count, String plural) {
    return '$count条记录$plural';
  }

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get languageChanged => '语言已成功更改';

  @override
  String get home => '主页';

  @override
  String get notifications => '通知';

  @override
  String get profile => '个人资料';

  @override
  String get logout => '登出';

  @override
  String get confirmLogout => '您确定要登出吗？';

  @override
  String get yes => '是';

  @override
  String get no => '否';

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
