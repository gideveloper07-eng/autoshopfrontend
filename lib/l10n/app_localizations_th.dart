// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'MyAutoShop';

  @override
  String get login => 'เข้าสู่ระบบ';

  @override
  String get companyCode => 'รหัสบริษัท';

  @override
  String get userId => 'รหัสผู้ใช้';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get invalidCompanyCode => 'รหัสบริษัทไม่ถูกต้อง';

  @override
  String get pleaseEnterCompanyCode => 'กรุณากรอกรหัสบริษัท';

  @override
  String get pleaseEnterUserId => 'กรุณากรอกรหัสผู้ใช้';

  @override
  String get pleaseEnterPassword => 'กรุณากรอกรหัสผ่าน';

  @override
  String get loginFailed => 'การเข้าสู่ระบบล้มเหลว';

  @override
  String get loginSuccess => 'เข้าสู่ระบบสำเร็จ';

  @override
  String get challan => 'ชาลัน';

  @override
  String get pendingChallan => 'อยู่ระหว่างการพิจารณาชาลัน';

  @override
  String get retailIncentive => 'แรงจูงใจในการค้าปลีก';

  @override
  String get loadingChallans => 'กำลังโหลดชาเลนจ์...';

  @override
  String get failedToLoadChallans => 'ไม่สามารถโหลด Challans';

  @override
  String get noChallansFound => 'ไม่พบผู้ท้าชิง';

  @override
  String get pullToRefresh => 'ดึงเพื่อรีเฟรชหรือกลับมาตรวจสอบในภายหลัง';

  @override
  String get date => 'วันที่';

  @override
  String get challanDate => 'ชาลลัน เดท';

  @override
  String get expectedDeliveryDate => 'วันที่คาดว่าจะจัดส่ง';

  @override
  String get challanNo => 'ชาลัน เลขที่';

  @override
  String get customerName => 'ชื่อลูกค้า';

  @override
  String get action => 'การกระทำ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get refresh => 'รีเฟรช';

  @override
  String get showDate => 'แสดงวันที่:';

  @override
  String get expectedDelivery => 'คาดว่าจะจัดส่ง';

  @override
  String records(int count, String plural) {
    return '$count บันทึก$plural';
  }

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get language => 'ภาษา';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get languageChanged => 'เปลี่ยนภาษาเรียบร้อยแล้ว';

  @override
  String get home => 'บ้าน';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get profile => 'ประวัติโดยย่อ';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get confirmLogout => 'คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'เลขที่';

  @override
  String get error => 'ข้อผิดพลาด';

  @override
  String get success => 'ความสำเร็จ';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get serverError => 'ข้อผิดพลาดของเซิร์ฟเวอร์';

  @override
  String get networkError => 'ข้อผิดพลาดของเครือข่าย กรุณาตรวจสอบการเชื่อมต่อของคุณ';
}
