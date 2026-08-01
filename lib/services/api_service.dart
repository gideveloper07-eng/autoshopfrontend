import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

class ApiService {
  static const String baseUrl = "http://api.myautoshop365.com";

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    webOptions: WebOptions(dbName: 'autoshop_db', publicKey: 'as_key_2024'),
  );
static String? _cachedToken;
static String? _cachedUserId;
static String? _cachedUserName;
static String? _cachedCompanyCode;
static String? _cachedDatabaseName;
  // ───────────────── TOKEN ─────────────────
static Future<void> initializeCache() async {
  _cachedToken ??= await _storage.read(key: "token");
  _cachedUserId ??= await _storage.read(key: "userId");
  _cachedUserName ??= await _storage.read(key: "userName");
  _cachedCompanyCode ??= await _storage.read(key: "companyCode");
  _cachedDatabaseName ??= await _storage.read(key: "databaseName");
}

  static Future<void> saveToken(String t) =>
      _storage.write(key: "token", value: t);

  //static Future<String?> getToken() => _storage.read(key: "token");
static Future<String?> getToken() async {
  if (_cachedToken != null) return _cachedToken;

  _cachedToken = await _storage.read(key: "token");
  return _cachedToken;
}

  static Future<void> clearToken() => _storage.delete(key: "token");
  static Future<bool> isAdmin() async {
    return (await _storage.read(key: "isAdmin")) == "true";
  }
  // ───────────────── SESSION ─────────────────

  static Future<void> saveUserSession({
    required String token,
    required String userId,
    required bool isAdmin,
    required String utg,
    required String userName,
    required String userEmail,
    required String databaseName,
    required String companyCode,
    String? clientId,
    String? userGuid,
    String? accessibleDatabases,
  }) async {
    await Future.wait([
      _storage.write(key: "token", value: token),
      _storage.write(key: "userId", value: userId),
      _storage.write(key: "isAdmin", value: isAdmin.toString()),
      _storage.write(key: "utg", value: utg),
      _storage.write(key: "userName", value: userName),
      _storage.write(key: "userEmail", value: userEmail),
      _storage.write(key: "databaseName", value: databaseName),
      _storage.write(key: "companyCode", value: companyCode),
      _storage.write(key: "clientId", value: clientId ?? ""),
      _storage.write(key: "userGuid", value: userGuid ?? ""),
      _storage.write(
        key: "accessibleDatabases",
        value: accessibleDatabases ?? "[]",
      ),
    ]);
await ApiService.initializeCache();
_cachedToken = token;
_cachedUserId = userId;
_cachedUserName = userName;
_cachedCompanyCode = companyCode;
_cachedDatabaseName = databaseName;
  }

  static Future<void> updateCurrentDatabase({
    required String token,
    required String databaseName,
    required String companyCode,
    required String clientId,
  }) async {
    await _storage.write(key: "token", value: token);
    await _storage.write(key: "databaseName", value: databaseName);
    await _storage.write(key: "companyCode", value: companyCode);
    await _storage.write(key: "clientId", value: clientId);
_cachedToken = token;
_cachedDatabaseName = databaseName;
_cachedCompanyCode = companyCode;
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>?> switchDatabase(String clientId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/switch-database'),
      headers: await _getHeaders(),
      body: jsonEncode({'clientId': clientId}),
    );

    return jsonDecode(response.body);
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
      "isAdmin": await _storage.read(key: "isAdmin") ?? "false",
      "utg": await _storage.read(key: "utg") ?? "",
      "userName": await _storage.read(key: "userName") ?? "",
      "userEmail": await _storage.read(key: "userEmail") ?? "",
      "databaseName": await _storage.read(key: "databaseName") ?? "",
      "companyCode": await _storage.read(key: "companyCode") ?? "",
    };
  }

  static Future<List<dynamic>> getAccessibleDatabases() async {
    final raw = await _storage.read(key: "accessibleDatabases");

    print("RAW ACCESSIBLE DATABASES:");
    print(raw);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);

    print("DECODED ACCESSIBLE DATABASES:");
    print(decoded);
    print("DECODED LENGTH:");
    print(decoded.length);

    return List<dynamic>.from(decoded);
  }

 // static Future<String?> getUserId() => _storage.read(key: "userId");

 // static Future<String?> getUserName() => _storage.read(key: "userName");

static Future<String?> getUserId() async {
  if (_cachedUserId != null) return _cachedUserId;

  _cachedUserId = await _storage.read(key: "userId");
  return _cachedUserId;
}

static Future<String?> getUserName() async {
  if (_cachedUserName != null) return _cachedUserName;

  _cachedUserName = await _storage.read(key: "userName");
  return _cachedUserName;
}

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
      _storage.delete(key: "isAdmin"),
      _storage.delete(key: "utg"),
      _storage.delete(key: "userName"),
      _storage.delete(key: "userEmail"),
      _storage.delete(key: "databaseName"),
      _storage.delete(key: "companyCode"),
      _storage.delete(key: "notifiedPendingChallanIds"),
    ]);
_cachedToken = null;
_cachedUserId = null;
_cachedUserName = null;
_cachedCompanyCode = null;
_cachedDatabaseName = null;
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
    // Run in separate microtask to avoid blocking UI thread
    Future.microtask(() => ensureAwake());
  }

  static Future<void> ensureAwake() async {
    final urls = ["$baseUrl/ping", "$baseUrl/"];

    // Reduced to 5 attempts with shorter timeouts to prevent violations
    for (int i = 0; i < 5; i++) {
      for (final url in urls) {
        try {
          final res = await http
              .get(Uri.parse(url))
              .timeout(const Duration(seconds: 5)); // Reduced from 12s

          final body = res.body.trim();

          if (res.statusCode == 200 &&
              !body.startsWith('<') &&
              !body.startsWith('<!')) {
            if (kIsWeb) {
              print("✅ Server awake (attempt ${i + 1})");
            }
            return;
          }
        } catch (_) {
          // Silently continue to next attempt
        }
      }

      // Add delay between attempts, but shorter to reduce wait time
      if (i < 4) {
        await Future.delayed(const Duration(seconds: 3)); // Reduced from 6s
      }
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
        return null;
      }

      final companyCode = _storage.read(key: "companyCode");

      final cacheKey = "challan_edit_${companyCode}_$sp462";

      // Read cached data
      final cached = await CacheService.getMap(cacheKey);

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

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        if (body["success"] == true && body["data"] is Map) {
          final data = Map<String, dynamic>.from(body["data"]);

          // Update cache
          await CacheService.setMap(cacheKey, data);

          return data;
        }
      }

      if (res.statusCode == 404) {
        print("Challan not found.");
      } else if (res.statusCode == 401) {
        print("Unauthorized.");
      } else if (res.statusCode == 500) {
        final body = jsonDecode(res.body);
        print(body["error"] ?? body["message"]);
      }

      // API failed, return cached data
      return cached;
    } catch (e) {
      print("❌ CHALLAN EDIT ERROR: $e");
      final companyCode = _storage.read(key: "companyCode");
      final cacheKey = "challan_edit_${companyCode}_$sp462";

      return await CacheService.getMap(cacheKey);
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

  /// Fetches today's booking and sale counts for the dashboard
  /* static Future<Map<String, int>> getDashboardStats() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty)
        return {'todayBooking': 0, 'todaySale': 0};

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/dashboard-stats"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          final data = body['data'] as Map<String, dynamic>;
          return {
            'todayBooking': (data['todayBooking'] as num?)?.toInt() ?? 0,
            'todaySale': (data['todaySale'] as num?)?.toInt() ?? 0,
          };
        }
      }
      return {'todayBooking': 0, 'todaySale': 0};
    } catch (e) {
      print("DASHBOARD STATS ERROR: $e");
      return {'todayBooking': 0, 'todaySale': 0};
    }
  }*/

  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {};
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/challan/dashboard-stats"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        if (body["success"] == true) {
          return Map<String, dynamic>.from(body["data"]);
        }
      }

      return {};
    } catch (e) {
      print(e);
      return {};
    }
  }

  static Future<void> logout(String token) async {
    try {
      // Get the FCM token so the backend can deactivate this specific device
      String? fcmToken;
      if (!kIsWeb) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (_) {}
      }

      await http.post(
        Uri.parse("$baseUrl/api/auth/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"fcmToken": fcmToken ?? ""}),
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
        print("ACCESSIBLE DATABASES:");
        print(data['accessibleDatabases']);
        if (data['token'] != null) {
          await saveUserSession(
            token: data['token'],
            isAdmin: data["isAdmin"] ?? false,
            userId: data['userId']?.toString() ?? userId,
            utg: data['utg']?.toString() ?? "",
            userName: data['name']?.toString() ?? userId,
            userEmail: data['email']?.toString() ?? "",
            databaseName: data['databaseName']?.toString() ?? databaseName,
            companyCode: "",
            clientId: data['clientId']?.toString(),
            userGuid: data['userGuid']?.toString(),
            accessibleDatabases: jsonEncode(data['accessibleDatabases'] ?? []),
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

      // Collect device info to send alongside the token
      String platform = 'android';
      String deviceModel = '';
      String appVersion = '1.0.0';

      try {
        final deviceInfo = DeviceInfoPlugin();
        if (kIsWeb) {
          platform = 'web';
          final webInfo = await deviceInfo.webBrowserInfo;
          deviceModel = webInfo.browserName.name;
        } else if (!kIsWeb) {
          if (Platform.isAndroid) {
            platform = 'android';
            final androidInfo = await deviceInfo.androidInfo;
            deviceModel = androidInfo.model;
          } else if (Platform.isIOS) {
            platform = 'ios';
            final iosInfo = await deviceInfo.iosInfo;
            deviceModel = iosInfo.utsname.machine ?? iosInfo.model ?? '';
          }
        }
      } catch (e) {
        print("DEVICE INFO ERROR: $e");
      }

      await http.post(
        Uri.parse("$baseUrl/api/auth/save-fcm-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "token": fcmToken,
          "platform": platform,
          "deviceModel": deviceModel,
          "appVersion": appVersion,
        }),
      );

      print("FCM TOKEN SAVED (platform: $platform, model: $deviceModel)");
    } catch (e) {
      print("SAVE FCM TOKEN ERROR: $e");
    }
  }

  static Future<List<dynamic>> getChatMessages(String challanId) async {
    try {
      final token = await getToken();

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/api/chat/$challanId"),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = jsonDecode(response.body);

      return body["data"] ?? [];
    } catch (e) {
      print("GET CHAT ERROR: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getDirectChatMessages(
    String receiverId,
    String receiverPropertyCode,
  ) async {
    final sw = Stopwatch()..start();

    try {
      final token = await getToken();

      if (token == null) {
        return {"data": <dynamic>[], "time": 0};
      }

      final cleanReceiverId = receiverId.trim();
      final cleanPropertyCode = receiverPropertyCode.trim();

      if (cleanReceiverId.isEmpty || cleanPropertyCode.isEmpty) {
        return {"data": <dynamic>[], "time": 0};
      }

      // If using FlutterSecureStorage:
      // final companyCode = await _storage.read(key: "companyCode") ?? "";

      // If using GetStorage:
      final companyCode = _storage.read(key: "companyCode") ?? "";

      final cacheKey = CacheService.keyDirectMessages(
        "${companyCode}_$cleanReceiverId",
        cleanPropertyCode,
      );

      // Read cached data
      final cached = await CacheService.getList(cacheKey);

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/chat/direct-messages/$cleanReceiverId/$cleanPropertyCode",
        ),
        headers: {"Authorization": "Bearer $token"},
      );

      sw.stop();

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = List<dynamic>.from(body["data"] ?? []);

        // Update cache
        await CacheService.setList(cacheKey, data);

        return {"data": data, "time": sw.elapsedMilliseconds};
      }

      print("GET DIRECT CHAT ERROR:");
      print(response.statusCode);
      print(response.body);

      // Return cached data if API fails
      return {"data": cached ?? <dynamic>[], "time": sw.elapsedMilliseconds};
    } catch (e) {
      sw.stop();

      print("GET DIRECT CHAT ERROR: $e");

      // If using FlutterSecureStorage:
      // final companyCode = await _storage.read(key: "companyCode") ?? "";

      // If using GetStorage:
      final companyCode = _storage.read(key: "companyCode") ?? "";

      final cached =
          await CacheService.getList(
            CacheService.keyDirectMessages(
              "${companyCode}_$receiverId",
              receiverPropertyCode,
            ),
          ) ??
          <dynamic>[];

      return {"data": cached, "time": sw.elapsedMilliseconds};
    }
  }

static Future<List<dynamic>> syncDirectChatMessages(
  String receiverId,
  String receiverPropertyCode,
) async {
  try {
    final token = await getToken();

    if (token == null) {
      return [];
    }

    final response = await http
        .get(
          Uri.parse(
            "$baseUrl/api/chat/direct-messages/$receiverId/$receiverPropertyCode",
          ),
          headers: {
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      return [];
    }

    final body = jsonDecode(response.body);

    return List<dynamic>.from(body["data"] ?? []);
  } catch (_) {
    return [];
  }
}

  static Future<SendMessageResponse> sendChatMessage({
    required String chatId,
    required String challanId,
    required String messageText,
    required String senderName,
    required String challanNo,
    String? databaseName,
    String? receiverDbName,
    String? receiverUserId,
    String? receiverName,
    String? messageType,
    String? documentId,
    String? receiverPropertyCode,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        print("❌ SEND CHAT: Token not found");
        return SendMessageResponse(success: false);
      }

      final requestBody = {
	"chatId": chatId,
        "challanId": challanId,
        "messageText": messageText,
        "senderName": senderName,
        "challanNo": challanNo,

        // Sender/current database
        "databaseName": databaseName,

        // Receiver information — trim to remove any trailing spaces from DB values
        "receiverUserId": receiverUserId?.trim(),
        "receiverName": receiverName?.trim(),
        "receiverDatabase": receiverDbName,
        "receiverPropertyCode": receiverPropertyCode?.trim(),

        "messageType": messageType ?? "TEXT",
        "documentId": documentId,
      };

      print("════════ SEND CHAT REQUEST ════════");
      print(jsonEncode(requestBody));
print("BEFORE HTTP");
      final response = await http
    .post(
      Uri.parse("$baseUrl/api/chat/send-message"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(requestBody),
    )
    .timeout(const Duration(seconds: 15));
print("AFTER HTTP");
      print("SEND CHAT STATUS: ${response.statusCode}");
      print("SEND CHAT RESPONSE: ${response.body}");

      if (response.statusCode != 200) {
  return SendMessageResponse(success: false);
}

final json = jsonDecode(response.body);

return SendMessageResponse.fromJson(json);
    } catch (e) {
      print("❌ SEND CHAT ERROR: $e");
      return SendMessageResponse(success: false);
    }
  }

  static Future<Map<String, dynamic>?> getDocument(String documentId) async {
    try {
      final token = await getToken();

      if (token == null) return null;

      final response = await http.get(
        Uri.parse("$baseUrl/api/chat/document/$documentId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body["success"] == true) {
          return body["data"];
        }
      }

      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  /// Marks all messages in a challan as read for the current user.
  /// Should be called whenever the chat dialog is opened.
  static Future<void> markChatRead(String challanId) async {
    try {
      final token = await getToken();
      if (token == null) return;

      await http.post(
        Uri.parse("$baseUrl/api/chat/mark-read/$challanId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
    } catch (e) {
      print("MARK CHAT READ ERROR: $e");
    }
  }

  /// Returns the number of unread messages sent by others for a given challan.
  static Future<int> getUnreadChatCount(
    String receiverId,
    String receiverPropertyCode,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return 0;

      final cleanReceiverId = receiverId.trim();
      final cleanPropertyCode = receiverPropertyCode.trim();

      if (cleanReceiverId.isEmpty || cleanPropertyCode.isEmpty) return 0;

      final response = await http.get(
        Uri.parse(
          "$baseUrl/api/chat/unread-count/$cleanReceiverId/$cleanPropertyCode",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return (body["count"] as num?)?.toInt() ?? 0;
      }

      return 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getChatDocuments({
    required String receiverPropertyCode,
    required String receiverCompanyName,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {"success": false, "data": []};
      }

      final uri = Uri.parse("$baseUrl/api/chat/documents").replace(
        queryParameters: {
          "receiverPropertyCode": receiverPropertyCode,
          "receiverCompanyName": receiverCompanyName,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return {"success": false, "data": []};
    } catch (e) {
      print("GET DOCUMENTS ERROR: $e");

      return {"success": false, "data": []};
    }
  }

  static Future<void> activityLog({
    required String activityType,
    required String activityName,
    String? userName,
    String? screenName,
    String? deviceInfo,
    String? appVersion,
  }) async {
    try {
      final token = await getToken();

      if (token == null) return;

      final response = await http.post(
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
          "deviceInfo": deviceInfo,
          "appVersion": appVersion,
        }),
      );
      // Silently ignore if endpoint not available on server yet
      if (response.statusCode == 404) return;
    } catch (e) {
      // Silently ignore activity log errors to avoid breaking main flow
    }
  }

  // ───────────────── CHAT MEMBERS ─────────────────

  /// Returns all active members of a challan chat group.
  static Future<List<Map<String, dynamic>>> getChatMembers(
    String challanId,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse("$baseUrl/api/chat/members/$challanId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("GET CHAT MEMBERS ERROR: $e");
      return [];
    }
  }

  /// Returns all company employees (for the Add Member picker).
  /// Calls GET /api/group/users — served from groupRoutes.js
  static Future<List<Map<String, dynamic>>> getCompanyUsers() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse("$baseUrl/api/group/users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("GET COMPANY USERS ERROR: $e");
      return [];
    }
  }

  /// Calls GET /api/group/merged-users — returns users from all accessible
  /// dealerships. Each user may include { companyName, companyCode, database }.
  /// Falls back to [getCompanyUsers] if the endpoint fails.
  static Future<List<Map<String, dynamic>>> getMergedUsers() async {
    try {
      final token = await getToken();
      if (token == null) return getCompanyUsers();
      final response = await http.get(
        Uri.parse("$baseUrl/api/group/merged-users"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      // Fallback to single-company list
      return getCompanyUsers();
    } catch (e) {
      print("GET MERGED USERS ERROR: $e");
      return getCompanyUsers();
    }
  }

  /// Adds a user as a member of a challan chat group.
  static Future<bool> addChatMember({
    required String challanId,
    required String userId,
    required String userName,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/members/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "challanId": challanId,
          "userId": userId,
          "userName": userName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("ADD CHAT MEMBER ERROR: $e");
      return false;
    }
  }

  /// Removes a member from a challan chat group (soft-delete).
  static Future<bool> removeChatMember({
    required String challanId,
    required String userId,
    required String userName,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.delete(
        Uri.parse("$baseUrl/api/chat/members/remove"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "challanId": challanId,
          "userId": userId,
          "userName": userName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("REMOVE CHAT MEMBER ERROR: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>> createGroup({
    required String groupName,
    required List<String> memberIds,
    String? databaseName, // the dealership DB this group belongs to
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {'success': false};
      final response = await http.post(
        Uri.parse("$baseUrl/api/group/create"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "groupName": groupName,
          "members": memberIds,
          if (databaseName != null && databaseName.isNotEmpty)
            "databaseName": databaseName,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'success': false};
    } catch (e) {
      print("CREATE GROUP ERROR: $e");
      return {'success': false};
    }
  }

  static Future<List<Map<String, dynamic>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse("$baseUrl/api/group/members/$groupId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("GET GROUP MEMBERS ERROR: $e");
      return [];
    }
  }

  static Future<bool> addGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/api/group/add-member"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"groupId": groupId, "userId": userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("ADD GROUP MEMBER ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteGroup({
    required String groupId,
    String? databaseName,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/api/group/delete-group"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "groupId": groupId,
          if (databaseName != null && databaseName.isNotEmpty)
            "databaseName": databaseName,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("DELETE GROUP ERROR: $e");
      return false;
    }
  }

  static Future<bool> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse("$baseUrl/api/group/remove-member"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"groupId": groupId, "userId": userId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("REMOVE GROUP MEMBER ERROR: $e");
      return false;
    }
  }

  /* static Future<List<dynamic>> getMyDirectChats() async {
    try {
      final token = await getToken();

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/api/group/my-direct-chats"),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = jsonDecode(response.body);
      print(response.body);
      return body["data"] ?? [];
    } catch (e) {
      print("GET DIRECT CHATS ERROR: $e");
      return [];
    }
  }*/
  /*static Future<List<dynamic>> getMyDirectChats({bool allChats = false}) async {
    final token = await getToken();

    if (token == null) return [];

    final scope = allChats ? "all" : "property";

    // Different cache key for each scope
    final cacheKey =
        "${CacheService.keyDirectChats}_${_storage.read(key: "companyCode")}_$scope";

    // 1. Return cache immediately if available
    final cached = await CacheService.getList(cacheKey);
    if (cached != null) {
      return cached;
    }

    // 2. Fetch from API
    final res = await http.get(
      Uri.parse("$baseUrl/api/group/my-direct-chats?scope=$scope"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      return [];
    }

    final body = jsonDecode(res.body);
    final data = List<dynamic>.from(body["data"] ?? []);

    // 3. Save cache
    await CacheService.setList(cacheKey, data);

    return data;
  }*/
static Future<List<dynamic>> getMyDirectChats({bool allChats = false}) async {
  final token = await getToken();

  if (token == null) return [];

  final scope = allChats ? "all" : "property";

  final cacheKey =
      "${CacheService.keyDirectChats}_${_storage.read(key: "companyCode")}_$scope";

  // Read cache (used only if API fails)
  final cached = await CacheService.getList(cacheKey);

  try {
    final res = await http.get(
      Uri.parse("$baseUrl/api/group/my-direct-chats?scope=$scope"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final data = List<dynamic>.from(body["data"] ?? []);

      await CacheService.setList(cacheKey, data);

      return data;
    }
  } catch (_) {}

  return cached ?? [];
}
  // static Future<List<dynamic>> getMyDirectChats({bool allChats = false}) async {
  //   final token = await getToken();

  //   if (token == null) return [];
  //   final scope = allChats ? "all" : "property";

  //   final res = await http.get(
  //     Uri.parse("$baseUrl/api/group/my-direct-chats?scope=$scope"),
  //     headers: {"Authorization": "Bearer $token"},
  //   );
  //   final body = jsonDecode(res.body);
  //   return List<dynamic>.from(body["data"] ?? []);
  // }

  static Future<List<dynamic>> getMyGroups() async {
    try {
      final token = await getToken();

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/api/group/my-groups"),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = jsonDecode(response.body);

      return body["data"] ?? [];
    } catch (e) {
      print("GET GROUPS ERROR: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getGroupMessages(String groupId) async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final cleanGroupId = groupId.trim();
      if (cleanGroupId.isEmpty) return [];

      final companyCode = await _storage.read(key: "companyCode") ?? "default";

      final cacheKey = CacheService.keyGroupMessages(
        "${companyCode}_$cleanGroupId",
      );

      // Read cached messages
      final cached = await CacheService.getList(cacheKey);

      final response = await http.get(
        Uri.parse("$baseUrl/api/group/messages/$cleanGroupId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = List<dynamic>.from(body["data"] ?? []);

        // Update cache
        await CacheService.setList(cacheKey, data);

        return data;
      }

      print("GET GROUP MESSAGES ERROR:");
      print(response.statusCode);
      print(response.body);

      return cached ?? [];
    } catch (e) {
      print("GET GROUP MESSAGES ERROR: $e");
      return [];
    }
  }

  static Future<bool> createTask({
    required String groupId,
    required String taskTitle,
    required String taskDescription,
    required String assignedTo,
    required String priority,
    String? startDate,
    String? dueDate,
    String? assignedToDatabase, // the DB where the assigned user belongs
  }) async {
    try {
      final token = await getToken();

      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/group/create-task"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "groupId": groupId,
          "taskTitle": taskTitle,
          "taskDescription": taskDescription,
          "assignedTo": assignedTo,
          "priority": priority,
          if (startDate != null) "startDate": startDate,
          if (dueDate != null) "dueDate": dueDate,
          if (assignedToDatabase != null && assignedToDatabase.isNotEmpty)
            "assignedToDatabase": assignedToDatabase,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("CREATE TASK ERROR: $e");
      return false;
    }
  }

  static Future<bool> updateTaskStatus({
    required String taskId,
    required String status,
    String? groupId,
    String?
    taskDatabase, // the DB where the task was saved (assigned user's company DB)
  }) async {
    try {
      final token = await getToken();

      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/group/update-task-status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "taskId": taskId,
          "status": status,
          if (groupId != null && groupId.isNotEmpty) "groupId": groupId,
          if (taskDatabase != null && taskDatabase.isNotEmpty)
            "taskDatabase": taskDatabase,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE TASK ERROR: $e");
      return false;
    }
  }

  static Future<bool> createChatTask({
    required String challanId,
    required String taskTitle,
    required String taskDescription,
    required String priority,
    String? startDate,
    String? dueDate,
  }) async {
    try {
      final token = await getToken();

      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/create-task"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "challanId": challanId,
          "taskTitle": taskTitle,
          "taskDescription": taskDescription,
          "priority": priority,
          if (startDate != null) "startDate": startDate,
          if (dueDate != null) "dueDate": dueDate,
        }),
      );

      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("CREATE CHAT TASK ERROR: $e");
      return false;
    }
  }

  /// Creates an individual (direct-chat) task.
  /// Stores in MA_ChatTasks with GroupId=NULL, ChallanId=NULL in the
  /// communication DB. Also posts a TASK message into MA_ChallanChat.
  static Future<bool> createIndividualTask({
    required String receiverId,
    required String receiverPropertyCode,
    required String taskTitle,
    required String taskDescription,
    required String priority,
    String? startDate,
    String? dueDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/create-individual-task"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "receiverId": receiverId,
          "receiverPropertyCode": receiverPropertyCode,
          "taskTitle": taskTitle,
          "taskDescription": taskDescription,
          "priority": priority,
          if (startDate != null) "startDate": startDate,
          if (dueDate != null) "dueDate": dueDate,
        }),
      );

      print("INDIVIDUAL TASK STATUS : ${response.statusCode}");
      print("INDIVIDUAL TASK BODY   : ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("CREATE INDIVIDUAL TASK ERROR: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getTasks() async {
    try {
      final token = await getToken();

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/api/chat/get-tasks"),
        headers: {"Authorization": "Bearer $token"},
      );

      final body = jsonDecode(response.body);

      return body["data"] ?? [];
    } catch (e) {
      print(e);
      return [];
    }
  }

  /// Fetches individual (direct-chat) tasks from the communication DB.
  /// These are tasks with GroupId=NULL created via create-individual-task.
  static Future<List<dynamic>> getIndividualTasks() async {
    try {
      final token = await getToken();

      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/api/chat/individual-tasks"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("INDIVIDUAL TASK STATUS: ${response.statusCode}");
      print("INDIVIDUAL TASK BODY: ${response.body}");

      final body = jsonDecode(response.body);

      return body["data"] ?? [];
    } catch (e) {
      print("GET INDIVIDUAL TASKS ERROR: $e");
      return [];
    }
  }

  /// Fetches group tasks assigned via group chat (stored in company DBs).
  /// Calls GET /api/group/tasks
  static Future<List<dynamic>> getGroupTasks() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse("$baseUrl/api/group/tasks"),
        headers: {"Authorization": "Bearer $token"},
      );

      print("GROUP TASK STATUS: ${response.statusCode}");
      print("GROUP TASK BODY: ${response.body}");

      final body = jsonDecode(response.body);
      return body["data"] ?? [];
    } catch (e) {
      print("GET GROUP TASKS ERROR: $e");
      return [];
    }
  }

  /// Updates the status of any task (challan, individual, or group).
  /// Calls POST /api/chat/update-task-status
  static Future<bool> updateChatTaskStatus({
    required String taskId,
    required String status,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/update-task-status"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"taskId": taskId, "status": status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("UPDATE CHAT TASK STATUS ERROR: $e");
      return false;
    }
  }

  static Future<bool> sendGroupMessage({
    required String groupId,
    required String messageText,
    String? messageType,
    String? documentId,
    String?
    databaseName, // the DB where this group belongs (employee's company)
  }) async {
    try {
      final token = await getToken();

      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/group/send-message"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "groupId": groupId,
          "messageText": messageText,
          "messageType": messageType ?? "TEXT",
          "documentId": documentId,
          if (databaseName != null && databaseName.isNotEmpty)
            "databaseName": databaseName,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("SEND GROUP MESSAGE ERROR: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getChatRequests() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("$baseUrl/api/group/chat/requests"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final body = jsonDecode(response.body);

    if (body["success"] == true) {
      return body["data"];
    }

    return [];
  }

  static Future<Map<String, dynamic>> sendChatRequest({
    required String toUserGuid,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {"success": false, "message": "No token"};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/group/sendrequest"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"toUserGuid": toUserGuid}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> acceptContactRequest({
    required String fromUserGuid,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {"success": false};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/group/contact-request/accept"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"fromUserGuid": fromUserGuid}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> rejectContactRequest({
    required String fromUserGuid,
  }) async {
    try {
      final token = await getToken();

      if (token == null) {
        return {"success": false};
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/group/contact-request/reject"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"fromUserGuid": fromUserGuid}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Accept a chat request by its [requestGuid].
  /// Uses the correct backend route: POST /api/group/chat/request/accept
  static Future<Map<String, dynamic>> acceptChatRequestByGuid({
    required String requestGuid,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {"success": false};
      final response = await http.post(
        Uri.parse("$baseUrl/api/group/chat/request/accept"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"requestGuid": requestGuid}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Reject a chat request by its [requestGuid].
  /// Uses the correct backend route: POST /api/group/chat/request/reject
  static Future<Map<String, dynamic>> rejectChatRequestByGuid({
    required String requestGuid,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return {"success": false};
      final response = await http.post(
        Uri.parse("$baseUrl/api/group/chat/request/reject"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"requestGuid": requestGuid}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Returns all ACTIVE contacts for the current user.
  /// Used to populate the chat list with accepted contacts even if no
  /// messages have been sent yet.
  static Future<List<dynamic>> getMyContacts() async {
    try {
      final token = await getToken();
      if (token == null) return [];
      final response = await http.get(
        Uri.parse("$baseUrl/api/group/my-contacts"),
        headers: {"Authorization": "Bearer $token"},
      );
      final body = jsonDecode(response.body);
      return List<dynamic>.from(body["data"] ?? []);
    } catch (e) {
      print("GET MY-CONTACTS ERROR: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getMyContactRequests() async {
    try {
      final token = await getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/api/group/my-contact-requests"),

        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final body = jsonDecode(response.body);

      if (body["success"] == true) {
        return List<dynamic>.from(body["data"]);
      }

      return [];
    } catch (e) {
      print(e);

      return [];
    }
  }

  static Future<Map<String, dynamic>> getDashboardBranchwise(
    String reportType,
    String period,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {'total': 0, 'branches': <dynamic>[]};
      }

      final response = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/dashboard-branchwise"
              "?type=$reportType&period=$period",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("BRANCHWISE STATUS: ${response.statusCode}");

      print("BRANCHWISE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (body['success'] == true && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data']);

          return {
            'total': (data['total'] as num?)?.toInt() ?? 0,

            'branches': data['branches'] is List
                ? data['branches']
                : <dynamic>[],
          };
        }
      }

      return {'total': 0, 'branches': <dynamic>[]};
    } catch (e) {
      print("DASHBOARD BRANCHWISE ERROR: $e");

      return {'total': 0, 'branches': <dynamic>[]};
    }
  }

  /// Fetches full booking detail rows for a specific branch and period.
  /// [period]: 'today' or 'yesterday'
  /// [branchName]: branch display name (sp_607) — used to filter results
  static Future<List<Map<String, dynamic>>> getBranchBookingDetails({
    required String period,
    String branchId = '',
    String branchName = '',
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final params = <String, String>{'period': period};

      if (branchId.trim().isNotEmpty) {
        params['branchId'] = branchId.trim();
      }

      if (branchName.trim().isNotEmpty) {
        params['branchName'] = branchName.trim();
      }

      final uri = Uri.parse(
        "$baseUrl/api/challan/branch-booking-details",
      ).replace(queryParameters: params);

      print("========== BRANCH DETAIL API ==========");
      print("URI        : $uri");
      print("Period     : $period");
      print("BranchId   : $branchId");
      print("BranchName : $branchName");
      print("======================================");

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("Status Code : ${response.statusCode}");
      print("Response    : ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      return [];
    } catch (e) {
      print("BRANCH BOOKING DETAILS ERROR: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getBranchSaleDetails({
    required String period,
    String branchId = '',
    String branchName = '',
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final params = <String, String>{'period': period};

      if (branchId.trim().isNotEmpty) {
        params['branchId'] = branchId.trim();
      }

      if (branchName.trim().isNotEmpty) {
        params['branchName'] = branchName.trim();
      }

      final uri = Uri.parse(
        "$baseUrl/api/challan/branch-sale-details",
      ).replace(queryParameters: params);

      print("========== SALE DETAIL API ==========");
      print("URI        : $uri");
      print("Period     : $period");
      print("BranchId   : $branchId");
      print("BranchName : $branchName");
      print("====================================");

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("Status Code : ${response.statusCode}");
      print("Response    : ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      return [];
    } catch (e) {
      print("BRANCH SALE DETAILS ERROR: $e");
      return [];
    }
  }
}

class SendMessageResponse {
  final bool success;
  final String? chatId;

  SendMessageResponse({
    required this.success,
    this.chatId,
  });

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      success: json["success"] == true,
      chatId: json["data"]?["chatId"]?.toString(),
    );
  }
}