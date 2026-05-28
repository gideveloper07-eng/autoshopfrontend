// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'ログイン';

  @override
  String get companyCode => '会社コード';

  @override
  String get userId => 'ユーザーID';

  @override
  String get password => 'パスワード';

  @override
  String get invalidCompanyCode => '無効な会社コード';

  @override
  String get pleaseEnterCompanyCode => '会社コードを入力してください';

  @override
  String get pleaseEnterUserId => 'ユーザーIDを入力してください';

  @override
  String get pleaseEnterPassword => 'パスワードを入力してください';

  @override
  String get loginFailed => 'ログインに失敗しました';

  @override
  String get loginSuccess => 'ログイン成功';

  @override
  String get challan => 'シャラン';

  @override
  String get pendingChallan => '保留中のシャラン';

  @override
  String get retailIncentive => '小売インセンティブ';

  @override
  String get loadingChallans => 'シャランを読み込んでいます...';

  @override
  String get failedToLoadChallans => 'シャランのロードに失敗しました';

  @override
  String get noChallansFound => 'シャランが見つかりません';

  @override
  String get pullToRefresh => 'プルして更新するか、後でもう一度確認してください';

  @override
  String get date => '日付';

  @override
  String get challanDate => 'シャランデート';

  @override
  String get expectedDeliveryDate => '配達予定日';

  @override
  String get challanNo => 'チャラン・ノー';

  @override
  String get customerName => '顧客名';

  @override
  String get action => 'アクション';

  @override
  String get edit => '編集';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get retry => 'リトライ';

  @override
  String get refresh => 'リフレッシュ';

  @override
  String get showDate => 'ショーの日付:';

  @override
  String get expectedDelivery => '配達予定日';

  @override
  String records(int count, String plural) {
    return '$count 記録$plural';
  }

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get selectLanguage => '言語の選択';

  @override
  String get languageChanged => '言語が正常に変更されました';

  @override
  String get home => '家';

  @override
  String get notifications => '通知';

  @override
  String get profile => 'プロフィール';

  @override
  String get logout => 'ログアウト';

  @override
  String get confirmLogout => 'ログアウトしてもよろしいですか?';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get error => 'エラー';

  @override
  String get success => '成功';

  @override
  String get loading => '読み込み中...';

  @override
  String get serverError => 'サーバーエラー';

  @override
  String get networkError => 'ネットワークエラー。接続を確認してください。';
}
