// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'Đăng nhập';

  @override
  String get companyCode => 'Mã công ty';

  @override
  String get userId => 'ID người dùng';

  @override
  String get password => 'Mật khẩu';

  @override
  String get invalidCompanyCode => 'Mã công ty không hợp lệ';

  @override
  String get pleaseEnterCompanyCode => 'Vui lòng nhập mã công ty';

  @override
  String get pleaseEnterUserId => 'Vui lòng nhập ID người dùng';

  @override
  String get pleaseEnterPassword => 'Vui lòng nhập mật khẩu';

  @override
  String get loginFailed => 'Đăng nhập không thành công';

  @override
  String get loginSuccess => 'Đăng nhập thành công';

  @override
  String get challan => 'challan';

  @override
  String get pendingChallan => 'Đang chờ xử lý';

  @override
  String get retailIncentive => 'Khuyến khích bán lẻ';

  @override
  String get loadingChallans => 'Đang tải challans...';

  @override
  String get failedToLoadChallans => 'Không tải được challans';

  @override
  String get noChallansFound => 'Không tìm thấy challans';

  @override
  String get pullToRefresh => 'Kéo để làm mới hoặc kiểm tra lại sau';

  @override
  String get date => 'Ngày';

  @override
  String get challanDate => 'Ngày Challan';

  @override
  String get expectedDeliveryDate => 'Ngày giao hàng dự kiến';

  @override
  String get challanNo => 'Challan Không';

  @override
  String get customerName => 'Tên khách hàng';

  @override
  String get action => 'Hoạt động';

  @override
  String get edit => 'Biên tập';

  @override
  String get save => 'Cứu';

  @override
  String get cancel => 'Hủy bỏ';

  @override
  String get retry => 'Thử lại';

  @override
  String get refresh => 'Làm cho khỏe lại';

  @override
  String get showDate => 'Ngày hiển thị:';

  @override
  String get expectedDelivery => 'Dự kiến ​​giao hàng';

  @override
  String records(int count, String plural) {
    return '$count Bản ghi$plural';
  }

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get languageChanged => 'Đã thay đổi ngôn ngữ thành công';

  @override
  String get home => 'Trang chủ';

  @override
  String get notifications => 'Thông báo';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get confirmLogout => 'Bạn có chắc chắn muốn đăng xuất không?';

  @override
  String get yes => 'Đúng';

  @override
  String get no => 'KHÔNG';

  @override
  String get error => 'Lỗi';

  @override
  String get success => 'Thành công';

  @override
  String get loading => 'Đang tải...';

  @override
  String get serverError => 'Lỗi máy chủ';

  @override
  String get networkError => 'Lỗi mạng. Vui lòng kiểm tra kết nối của bạn.';
}
