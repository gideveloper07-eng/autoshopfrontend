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

  @override
  String get challanDetails => 'Chi tiết Challan';

  @override
  String get challanNoLabel => 'Challan Không';

  @override
  String get loadingChallanDetails => 'Đang tải chi tiết challan...';

  @override
  String get failedToLoadDetails => 'Không thể tải chi tiết';

  @override
  String get showSelectionCheckboxes => 'Hiển thị hộp kiểm lựa chọn';

  @override
  String get enableCheckboxesHelp => 'Bật hộp kiểm để chọn các trường cho nhận xét từ chối';

  @override
  String get basicInformation => 'Thông tin cơ bản';

  @override
  String get pricingDetails => 'Chi tiết giá cả';

  @override
  String get discountsAndOffers => 'Giảm giá & Ưu đãi';

  @override
  String get discountTitle => 'Giảm giá';

  @override
  String get rtoDetails => 'Chi tiết RTO';

  @override
  String get taxDetails => 'Chi tiết thuế';

  @override
  String get insuranceDetails => 'Chi tiết bảo hiểm';

  @override
  String get financialDetails => 'Chi tiết tài chính';

  @override
  String get customerInformation => 'Thông tin khách hàng';

  @override
  String get customerLabel => 'Khách hàng';

  @override
  String get exShowroomLabel => 'Phòng trưng bày cũ';

  @override
  String get corporateLabel => 'Công ty';

  @override
  String get subtotalLabel => 'Tổng phụ';

  @override
  String get rtoAmountLabel => 'Số tiền RTO';

  @override
  String get insuranceAmtLabel => 'Số tiền bảo hiểm';

  @override
  String get netAmountLabel => 'Số tiền ròng';

  @override
  String get mobileLabel => 'Điện thoại di động';

  @override
  String get rejectRemarkTitle => 'Từ chối nhận xét';

  @override
  String get checkedFieldInfo => 'Các trường được kiểm tra sẽ được thêm vào bên dưới. Bạn có thể chỉnh sửa trước khi từ chối:';

  @override
  String get rejectRemarkHint => 'Từ chối nhận xét (tự động điền từ các trường đã chọn)...';

  @override
  String get rejectChallan => 'Từ chối Challan';

  @override
  String get approve => 'Chấp thuận';

  @override
  String get reject => 'Từ chối';

  @override
  String get pleaseSelectFieldOrReason => 'Vui lòng chọn ít nhất một trường hoặc nhập lý do từ chối';
}
