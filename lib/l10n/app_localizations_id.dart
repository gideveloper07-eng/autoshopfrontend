// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Login';

  @override
  String get companyCode => 'Kode Perusahaan';

  @override
  String get userId => 'ID Pengguna';

  @override
  String get password => 'Kata sandi';

  @override
  String get invalidCompanyCode => 'Kode Perusahaan Tidak Valid';

  @override
  String get pleaseEnterCompanyCode => 'Silakan masukkan kode perusahaan';

  @override
  String get pleaseEnterUserId => 'Silakan masukkan ID pengguna';

  @override
  String get pleaseEnterPassword => 'Silakan masukkan kata sandi';

  @override
  String get loginFailed => 'Gagal Masuk';

  @override
  String get loginSuccess => 'Masuk Berhasil';

  @override
  String get challan => 'tantangan';

  @override
  String get pendingChallan => 'Challan yang tertunda';

  @override
  String get retailIncentive => 'Insentif Ritel';

  @override
  String get loadingChallans => 'Memuat tantangan...';

  @override
  String get failedToLoadChallans => 'Gagal memuat tantangan';

  @override
  String get noChallansFound => 'Tidak ada tantangan yang ditemukan';

  @override
  String get pullToRefresh => 'Tarik untuk menyegarkan atau memeriksa kembali nanti';

  @override
  String get date => 'Tanggal';

  @override
  String get challanDate => 'Tanggal Challan';

  @override
  String get expectedDeliveryDate => 'Tanggal Pengiriman yang Diharapkan';

  @override
  String get challanNo => 'Challan No';

  @override
  String get customerName => 'Nama Pelanggan';

  @override
  String get action => 'Tindakan';

  @override
  String get edit => 'Sunting';

  @override
  String get save => 'Menyimpan';

  @override
  String get cancel => 'Membatalkan';

  @override
  String get retry => 'Mencoba kembali';

  @override
  String get refresh => 'Menyegarkan';

  @override
  String get showDate => 'Tanggal Tayang:';

  @override
  String get expectedDelivery => 'Pengiriman yang Diharapkan';

  @override
  String records(int count, String plural) {
    return '$count Rekam$plural';
  }

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get languageChanged => 'Bahasa berhasil diubah';

  @override
  String get home => 'Rumah';

  @override
  String get notifications => 'Pemberitahuan';

  @override
  String get profile => 'Profil';

  @override
  String get logout => 'Keluar';

  @override
  String get confirmLogout => 'Apakah Anda yakin ingin logout?';

  @override
  String get yes => 'Ya';

  @override
  String get no => 'TIDAK';

  @override
  String get error => 'Kesalahan';

  @override
  String get success => 'Kesuksesan';

  @override
  String get loading => 'Memuat...';

  @override
  String get serverError => 'Kesalahan Server';

  @override
  String get networkError => 'Kesalahan Jaringan. Silakan periksa koneksi Anda.';
}
