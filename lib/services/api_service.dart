import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://api.myautoshop365.com";

  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'autoshop_db', publicKey: 'as_key_2024'),
  );

  // ───────────────── TOKEN ─────────────────

  static Future<void> saveToken(String t) =>
      _storage.write(key: "token", value: t);

  static Future<String?> getToken() => _storage.read(key: "token");

  static Future<void> clearToken() => _storage.delete(key: "token");

  // ───────────────── SESSION ─────────────────

  static Future<void> saveUserSession({
    required String token,
    required String userId,
    required String utg,
    required String userName,
    required String userEmail,
    required String databaseName,
    required String companyCode,
  }) async {
    await Future.wait([
      _storage.write(key: "token", value: token),
      _storage.write(key: "userId", value: userId),
      _storage.write(key: "utg", value: utg),
      _storage.write(key: "userName", value: userName),
      _storage.write(key: "userEmail", value: userEmail),
      _storage.write(key: "databaseName", value: databaseName),
      _storage.write(key: "companyCode", value: companyCode),
    ]);
  }

  static Future<String?> getUTG() async {
    return await _storage.read(key: "utg");
  }

  static Future<Map<String, String>?> getUserSession() async {
    final token = await _storage.read(key: "token");

    if (token == null || token.isEmpty) return null;

    return {
      "token": token,
      "userId": await _storage.read(key: "userId") ?? "",
      "utg": await _storage.read(key: "utg") ?? "",
      "userName": await _storage.read(key: "userName") ?? "",
      "userEmail": await _storage.read(key: "userEmail") ?? "",
      "databaseName": await _storage.read(key: "databaseName") ?? "",
      "companyCode": await _storage.read(key: "companyCode") ?? "",
    };
  }

  static Future<String?> getUserId() => _storage.read(key: "userId");

  static Future<String?> getUserName() => _storage.read(key: "userName");

  static Future<String> getClientIp() async {
    try {
      final res = await http
          .get(Uri.parse("https://api.ipify.org?format=json"))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body["ip"]?.toString() ?? "";
      }
    } catch (e) {
      print("CLIENT IP ERROR: $e");
    }

    return "";
  }

  static Future<Set<String>> getNotifiedPendingChallanIds() async {
    final raw = await _storage.read(key: "notifiedPendingChallanIds");
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      print("READ NOTIFIED CHALLAN IDS ERROR: $e");
    }

    return {};
  }

  static Future<void> saveNotifiedPendingChallanIds(Set<String> ids) => _storage
      .write(key: "notifiedPendingChallanIds", value: jsonEncode(ids.toList()));

  static Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: "token"),
      _storage.delete(key: "userId"),
      _storage.delete(key: "utg"),
      _storage.delete(key: "userName"),
      _storage.delete(key: "userEmail"),
      _storage.delete(key: "databaseName"),
      _storage.delete(key: "companyCode"),
      _storage.delete(key: "notifiedPendingChallanIds"),
    ]);
  }

  // ───────────────── DEVICE ID ─────────────────

  static Future<String> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        // For web: generate a persistent unique ID stored in secure storage
        String? storedId = await _storage.read(key: "device_id");
        if (storedId != null && storedId.isNotEmpty) {
          return storedId;
        }
        // Generate a new unique ID for this browser
        final newId =
            "web_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}";
        await _storage.write(key: "device_id", value: newId);
        return newId;
      }

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return "android_${androidInfo.id}";
      }

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return "ios_${iosInfo.identifierForVendor ?? DateTime.now().millisecondsSinceEpoch.toString()}";
      }

      if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        return "win_${windowsInfo.deviceId}";
      }

      return "device_${DateTime.now().millisecondsSinceEpoch}";
    } catch (e) {
      print("DEVICE ID ERROR: $e");
      return "fallback_${DateTime.now().millisecondsSinceEpoch}";
    }
  }
  // ───────────────── NOTIFICATIONS ─────────────────

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return [];
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/notifications"),

        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("NOTIFICATION RESPONSE:");
      print(res.body);
      print("NOTIFICATION STATUS:");
      print(res.statusCode);

      print("NOTIFICATION BODY:");
      print(res.body);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        if (body["success"] == true && body["data"] is List) {
          return List<Map<String, dynamic>>.from(body["data"]);
        }
      }

      return [];
    } catch (e) {
      print("GET NOTIFICATIONS ERROR: $e");

      return [];
    }
  }

  static String _randomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = DateTime.now().microsecondsSinceEpoch;
    return String.fromCharCodes(
      List.generate(8, (i) => chars.codeUnitAt((rand >> i) % chars.length)),
    );
  }

  // ───────────────── WAKE SERVER ─────────────────

  static Future<void> wakeServer() async {
    Future(() => ensureAwake());
  }

  static Future<void> ensureAwake() async {
    final urls = ["$baseUrl/ping", "$baseUrl/"];

    for (int i = 0; i < 10; i++) {
      for (final url in urls) {
        try {
          final res = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 12));

          final body = res.body.trim();

          if (res.statusCode == 200 &&
              !body.startsWith('<') &&
              !body.startsWith('<!')) {
            if (kIsWeb) {
              print("✅ Server awake (attempt ${i + 1})");
            }
            return;
          }
        } catch (_) {}
      }

      await Future.delayed(const Duration(seconds: 6));
    }
  }

  // ───────────────── VALIDATE COMPANY ─────────────────

  static Future<Map<String, dynamic>> validateCompany(
    String companyCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/validate-company'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'companyCode': companyCode}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      return <String, dynamic>{};
    } catch (e) {
      print("Validate Company Error: $e");
      return <String, dynamic>{};
    }
  }
  // ───────────────── CHALLAN ─────────────────

  /// Fetches Retail Incentive challans from the stored procedure.
  /// dateType: 'challan' (default) for Challan Date, 'expected' for Expected Delivery Date
  /// Returns a list of maps with keys: date or exdate, sp_468, sp_469
  static Future<List<Map<String, dynamic>>> getChallanRetailIncentive({
    String dateType = 'challan',
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/retail-incentive?dateType=$dateType",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map(
              (e) => Map<String, dynamic>.from(e as Map),
            ),
          );
        }
      }
      return [];
    } catch (e) {
      print("CHALLAN ERROR: $e");
      return [];
    }
  }

  /// Fetches complete challan details for editing
  /// Calls the stored procedure with @what = 'Edit' and @sp_462
  /// Returns a map with all challan fields
  static Future<Map<String, dynamic>?> getChallanEditDetails(
    String sp462,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        print("❌ CHALLAN EDIT: No token found");
        throw Exception("Authentication required. Please login again.");
      }

      final url = "$baseUrl/api/challan/edit/$sp462";
      print("🌐 CHALLAN EDIT: Calling $url");

      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("📡 CHALLAN EDIT: Status ${res.statusCode}");
      print("📦 CHALLAN EDIT: Body ${res.body}");

      if (res.statusCode == 404) {
        throw Exception("Challan not found. The record may have been deleted.");
      }

      if (res.statusCode == 401) {
        throw Exception("Unauthorized. Please login again.");
      }

      if (res.statusCode == 500) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final errorMsg = body['error'] ?? body['message'] ?? 'Server error';
        throw Exception("Server error: $errorMsg");
      }

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          print("✅ CHALLAN EDIT: Data received successfully");
          return Map<String, dynamic>.from(body['data'] as Map);
        } else {
          final errorMsg = body['message'] ?? 'Invalid response format';
          throw Exception(errorMsg);
        }
      }

      throw Exception("Unexpected response: HTTP ${res.statusCode}");
    } catch (e) {
      print("❌ CHALLAN EDIT ERROR: $e");
      rethrow;
    }
  }

  /// Approves a challan by calling the stored procedure with @what = 'approve'
  /// Returns success message
  static Future<Map<String, dynamic>> approveChallan(
    Map<String, dynamic> challanData,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final url = "$baseUrl/api/challan/approve";
      print("✅ CHALLAN APPROVE: Calling $url");
      print(
        "📦 CHALLAN APPROVE: Data keys: ${challanData.keys.take(10).toList()}",
      );

      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(challanData),
          )
          .timeout(const Duration(seconds: 30));

      print("📡 CHALLAN APPROVE: Status ${res.statusCode}");
      print("📦 CHALLAN APPROVE: Response ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          print("✅ CHALLAN APPROVE: Success");
          return body;
        } else {
          throw Exception(body['message'] ?? 'Approval failed');
        }
      }

      // Handle error responses
      if (res.statusCode == 400 || res.statusCode == 500) {
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final errorMsg = body['message'] ?? body['error'] ?? 'Request failed';
          throw Exception(errorMsg);
        } catch (e) {
          throw Exception("Server error: ${res.body}");
        }
      }

      throw Exception("Unexpected response: HTTP ${res.statusCode}");
    } catch (e) {
      print("❌ CHALLAN APPROVE ERROR: $e");
      rethrow;
    }
  }

  /// Rejects a challan by calling the stored procedure with @what = 'reject'
  /// Returns success message
  static Future<Map<String, dynamic>> rejectChallan(
    Map<String, dynamic> challanData,
    String rejectRemark,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      // Add the reject remark to the challan data
      final dataWithRemark = Map<String, dynamic>.from(challanData);
      dataWithRemark['sp_581'] = rejectRemark;

      final url = "$baseUrl/api/challan/reject";
      print("❌ CHALLAN REJECT: Calling $url");
      print(
        "📦 CHALLAN REJECT: Data keys: ${dataWithRemark.keys.take(10).toList()}",
      );

      final res = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(dataWithRemark),
          )
          .timeout(const Duration(seconds: 30));

      print("📡 CHALLAN REJECT: Status ${res.statusCode}");
      print("📦 CHALLAN REJECT: Response ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          print("✅ CHALLAN REJECT: Success");
          return body;
        } else {
          throw Exception(body['message'] ?? 'Rejection failed');
        }
      }

      // Handle error responses
      if (res.statusCode == 400 || res.statusCode == 500) {
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final errorMsg = body['message'] ?? body['error'] ?? 'Request failed';
          throw Exception(errorMsg);
        } catch (e) {
          throw Exception("Server error: ${res.body}");
        }
      }

      throw Exception("Unexpected response: HTTP ${res.statusCode}");
    } catch (e) {
      print("❌ CHALLAN REJECT ERROR: $e");
      rethrow;
    }
  }

  static Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/api/auth/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    } catch (e) {
      print("LOGOUT API ERROR: $e");
    }
  }
  // ───────────────── LOGIN ─────────────────

  static Future<Map?> login({
    required String databaseName,
    required String userId,
    required String password,
  }) async {
    try {
      await ensureAwake();

      // GET DEVICE ID
      final deviceId = await getDeviceId();

      if (kIsWeb) {
        print("DEVICE ID: $deviceId");
      }

      final res = await http
          .post(
            Uri.parse("$baseUrl/api/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "databaseName": databaseName,
              "userId": userId,
              "password": password,
              "deviceId": deviceId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (kIsWeb) {
        print("LOGIN STATUS: ${res.statusCode}");
        print("LOGIN BODY: ${res.body}");
      }

      // BLOCKED LOGIN
      if (res.statusCode == 403) {
        final data = jsonDecode(res.body);

        return {
          "success": false,
          "message":
              data['message'] ??
              "This account is already logged in on another device",
        };
      }

      // SUCCESS
      if (res.statusCode == 200 && !res.body.trim().startsWith('<')) {
        final data = jsonDecode(res.body);

        if (data['token'] != null) {
          await saveUserSession(
            token: data['token'],
            userId: data['userId']?.toString() ?? userId,
            utg: data['utg']?.toString() ?? "",
            userName: data['name']?.toString() ?? userId,
            userEmail: data['email']?.toString() ?? "",
            databaseName: data['databaseName']?.toString() ?? databaseName,
            companyCode: "",
          );
        }

        return data;
      }

      // INVALID LOGIN
      return {"success": false, "message": "Invalid User ID or Password"};
    } catch (e) {
      print("LOGIN ERROR: $e");

      return {"success": false, "message": e.toString()};
    }
  }

  static Future<int> getUnreadNotificationCount() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return 0;
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/notifications/unread-count"),

        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      print("UNREAD STATUS:");
      print(res.statusCode);

      print("UNREAD BODY:");
      print(res.body);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        return body["unread_count"] ?? 0;
      }

      return 0;
    } catch (e) {
      print("UNREAD COUNT ERROR: $e");

      return 0;
    }
  }

  static Future<void> markNotificationAsRead(String id) async {
    try {
      final token = await getToken();

      if (token == null) return;

      await http.post(
        Uri.parse("$baseUrl/api/notifications/read/$id"),

        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    } catch (e) {
      print("MARK READ ERROR: $e");
    }
  }

  static Future<void> saveFCMToken(String fcmToken) async {
    try {
      final token = await getToken();

      if (token == null) return;

      await http.post(
        Uri.parse("$baseUrl/api/auth/save-fcm-token"),

        headers: {
          "Content-Type": "application/json",

          "Authorization": "Bearer $token",
        },

        body: jsonEncode({"token": fcmToken}),
      );

      print("FCM TOKEN SAVED");
    } catch (e) {
      print("SAVE FCM TOKEN ERROR: $e");
    }
  }

  static Future<void> activityLog({
    required String activityType,
    required String activityName,
    String? userName,
    String? screenName,
  }) async {
    try {
      final token = await getToken();

      if (token == null) return;

      await http.post(
        Uri.parse("$baseUrl/api/auth/activity-log"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "activityType": activityType,
          "activityName": activityName,
          "userName": userName,
          "screenName": screenName,
        }),
      );
    } catch (e) {
      print("ACTIVITY LOG ERROR: $e");
    }
  }
}
