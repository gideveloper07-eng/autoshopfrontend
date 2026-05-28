// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Giriş yapmak';

  @override
  String get companyCode => 'Şirket Kodu';

  @override
  String get userId => 'Kullanıcı kimliği';

  @override
  String get password => 'Şifre';

  @override
  String get invalidCompanyCode => 'Geçersiz Şirket Kodu';

  @override
  String get pleaseEnterCompanyCode => 'Lütfen şirket kodunu girin';

  @override
  String get pleaseEnterUserId => 'Lütfen kullanıcı kimliğini girin';

  @override
  String get pleaseEnterPassword => 'Lütfen şifreyi girin';

  @override
  String get loginFailed => 'Giriş başarısız oldu';

  @override
  String get loginSuccess => 'Giriş Başarılı';

  @override
  String get challan => 'Challan';

  @override
  String get pendingChallan => 'Bekleyen Challan';

  @override
  String get retailIncentive => 'Perakende Teşviki';

  @override
  String get loadingChallans => 'Challanlar yükleniyor...';

  @override
  String get failedToLoadChallans => 'Challan\'lar yüklenemedi';

  @override
  String get noChallansFound => 'Challan bulunamadı';

  @override
  String get pullToRefresh => 'Yenilemek veya daha sonra tekrar kontrol etmek için çekin';

  @override
  String get date => 'Tarih';

  @override
  String get challanDate => 'Challan Tarihi';

  @override
  String get expectedDeliveryDate => 'Beklenen Teslimat Tarihi';

  @override
  String get challanNo => 'Hayır';

  @override
  String get customerName => 'Müşteri Adı';

  @override
  String get action => 'Aksiyon';

  @override
  String get edit => 'Düzenlemek';

  @override
  String get save => 'Kaydetmek';

  @override
  String get cancel => 'İptal etmek';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get refresh => 'Yenile';

  @override
  String get showDate => 'Tarihi Göster:';

  @override
  String get expectedDelivery => 'Beklenen Teslimat';

  @override
  String records(int count, String plural) {
    return '$count Kayıt$plural';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Seçiniz';

  @override
  String get languageChanged => 'Dil başarıyla değiştirildi';

  @override
  String get home => 'Ev';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Oturumu kapat';

  @override
  String get confirmLogout => 'Oturumu kapatmak istediğinizden emin misiniz?';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'HAYIR';

  @override
  String get error => 'Hata';

  @override
  String get success => 'Başarı';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get serverError => 'Sunucu Hatası';

  @override
  String get networkError => 'Ağ Hatası. Lütfen bağlantınızı kontrol edin.';
}
