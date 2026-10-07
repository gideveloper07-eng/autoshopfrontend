import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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
    try {
      _cachedToken ??= await _storage.read(key: "token");
      _cachedUserId ??= await _storage.read(key: "userId");
      _cachedUserName ??= await _storage.read(key: "userName");
      _cachedCompanyCode ??= await _storage.read(key: "companyCode");
      _cachedDatabaseName ??= await _storage.read(key: "databaseName");
    } on PlatformException catch (e) {
      print("Secure storage initialization failed: $e");

      await _storage.deleteAll();

      _cachedToken = null;
      _cachedUserId = null;
      _cachedUserName = null;
      _cachedCompanyCode = null;
      _cachedDatabaseName = null;
    }
  }

  static Future<void> saveToken(String t) =>
      _storage.write(key: "token", value: t);

  //static Future<String?> getToken() => _storage.read(key: "token");
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    try {
      _cachedToken = await _storage.read(key: "token");
      return _cachedToken;
    } on PlatformException catch (e) {
      print("SECURE STORAGE ERROR: $e");

      // Clear corrupted token
      await _storage.delete(key: "token");
      _cachedToken = null;

      return null;
    } catch (e) {
      print("TOKEN READ ERROR: $e");
      return null;
    }
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
  // ================================================================
  // ASP.NET CHALLAN GRID
  // Equivalent to:
  //   Getreceipt
  //   Getreceiptpage
  //   getsearch
  //   totalrow
  //   DeletegRecptData
  // ================================================================

  static Future<List<Map<String, dynamic>>> getChallanGrid({
    int page = 1,
    int pageSize = 10,
    String search = '',
  }) async {
    return getChallanGridPage(page: page, pageSize: pageSize, search: search);
  }

  static Future<List<Map<String, dynamic>>> getChallanGridPage({
    required int page,
    int pageSize = 10,
    String search = '',
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/api/challan/grid/page").replace(
        queryParameters: {
          "page": page.toString(),
          "pageSize": pageSize.toString(),
          if (search.trim().isNotEmpty) "search": search.trim(),
        },
      );

      print("========== CHALLAN GRID ==========");
      print("URL       : $uri");
      print("PAGE      : $page");
      print("PAGE SIZE : $pageSize");
      print("SEARCH    : $search");

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Challan grid failed: HTTP ${response.statusCode}\n"
          "${response.body}",
        );
      }

      final body = jsonDecode(response.body);

      if (body is Map && body["success"] == true && body["data"] is List) {
        return List<Map<String, dynamic>>.from(
          (body["data"] as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
      }

      throw Exception(
        body is Map
            ? body["message"]?.toString() ?? "Unable to load Challan grid"
            : "Invalid Challan grid response",
      );
    } catch (e) {
      print("❌ CHALLAN GRID ERROR: $e");
      rethrow;
    }
  }

  // ================================================================
  // ASP.NET: getsearch
  // ================================================================

  static Future<List<Map<String, dynamic>>> searchChallanGrid({
    required String search,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/api/challan/grid/search").replace(
        queryParameters: {
          "search": search.trim(),
          "page": page.toString(),
          "pageSize": pageSize.toString(),
        },
      );

      print("========== CHALLAN GRID SEARCH ==========");
      print("URL    : $uri");
      print("SEARCH : $search");

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");

      if (response.statusCode != 200) {
        throw Exception(
          "Challan search failed: HTTP ${response.statusCode}\n"
          "${response.body}",
        );
      }

      final body = jsonDecode(response.body);

      if (body is Map && body["success"] == true && body["data"] is List) {
        return List<Map<String, dynamic>>.from(
          (body["data"] as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
          ),
        );
      }

      throw Exception(
        body is Map
            ? body["message"]?.toString() ?? "Search failed"
            : "Invalid search response",
      );
    } catch (e) {
      print("❌ CHALLAN SEARCH ERROR: $e");
      rethrow;
    }
  }

  // ================================================================
  // ASP.NET: totalrow
  // ================================================================

  static Future<int> getChallanGridTotal({String search = ''}) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final uri = Uri.parse("$baseUrl/api/challan/grid/total").replace(
        queryParameters: {
          if (search.trim().isNotEmpty) "search": search.trim(),
        },
      );

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("CHALLAN TOTAL STATUS : ${response.statusCode}");
      print("CHALLAN TOTAL BODY   : ${response.body}");

      if (response.statusCode != 200) {
        throw Exception("Challan total failed: HTTP ${response.statusCode}");
      }

      final body = jsonDecode(response.body);

      if (body is Map) {
        final value =
            body["total"] ?? body["totalRows"] ?? body["count"] ?? body["data"];

        if (value is num) {
          return value.toInt();
        }

        return int.tryParse(value?.toString() ?? '') ?? 0;
      }

      return 0;
    } catch (e) {
      print("❌ CHALLAN TOTAL ERROR: $e");
      rethrow;
    }
  }

  // ================================================================
  // ASP.NET: DeletegRecptData
  // ================================================================

  static Future<Map<String, dynamic>> deleteChallanGridRecord({
    required String unqId,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final response = await http
          .post(
            Uri.parse("$baseUrl/api/challan/grid/delete"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({"unqid": unqId}),
          )
          .timeout(const Duration(seconds: 30));

      print("CHALLAN DELETE STATUS : ${response.statusCode}");
      print("CHALLAN DELETE BODY   : ${response.body}");

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body is Map<String, dynamic>) {
          return body;
        }

        return {"success": true, "message": "Record deleted successfully"};
      }

      throw Exception(
        body is Map
            ? body["message"]?.toString() ?? "Delete failed"
            : "Delete failed",
      );
    } catch (e) {
      print("❌ CHALLAN DELETE ERROR: $e");
      rethrow;
    }
  }

  // ================================================================
  // ASP.NET printbill equivalent
  // ================================================================

  static Future<void> printChallan(String sp462) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final uri = Uri.parse(
        "$baseUrl/api/challan/print",
      ).replace(queryParameters: {"sp_462": sp462});

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("CHALLAN PRINT STATUS : ${response.statusCode}");

      if (response.statusCode != 200) {
        throw Exception("Challan print failed: HTTP ${response.statusCode}");
      }

      print("CHALLAN PRINT RESPONSE: ${response.body}");
    } catch (e) {
      print("❌ CHALLAN PRINT ERROR: $e");
      rethrow;
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

  static Future<Map<String, dynamic>> getDashboardStats({
    String period = '7days',
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {};
      }

      final res = await http.get(
        Uri.parse("$baseUrl/api/challan/dashboard-stats?period=$period"),
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

  static Future<String> askAI(String message) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required.");
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/ai/chat"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode != 200) {
        throw Exception("Server Error (${response.statusCode})");
      }

      final body = jsonDecode(response.body);

      if (body["success"] == true) {
        return body["reply"] ?? "";
      }

      throw Exception(body["message"] ?? "Unable to get AI response.");
    } catch (e) {
      return "Unable to contact MyAutoShop AI.\n\n$e";
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

  static Future<bool> clearAllNotifications() async {
    try {
      final token = await getToken();

      if (token == null) return false;

      final res = await http.delete(
        Uri.parse("$baseUrl/api/notifications/clear-all"),

        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return res.statusCode == 200;
    } catch (e) {
      print("CLEAR ALL NOTIFICATIONS ERROR: $e");
      return false;
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
            headers: {"Authorization": "Bearer $token"},
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

  /// Non-admin: notify the admin that a task has been completed.
  /// Does NOT change the task status in the DB.
  /// Calls POST /api/chat/notify-task-complete
  static Future<bool> notifyTaskComplete({required String taskId}) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse("$baseUrl/api/chat/notify-task-complete"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"taskId": taskId}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("NOTIFY TASK COMPLETE ERROR: $e");
      return false;
    }
  }

  /// Creates a standalone task assigned to any user (admin only).
  /// Calls POST /api/chat/create-global-task
  static Future<bool> createGlobalTask({
    required String receiverId,
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
        Uri.parse("$baseUrl/api/chat/create-global-task"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "receiverId": receiverId,
          "taskTitle": taskTitle,
          "taskDescription": taskDescription,
          "priority": priority,
          if (startDate != null) "startDate": startDate,
          if (dueDate != null) "dueDate": dueDate,
        }),
      );
      print("CREATE GLOBAL TASK STATUS: ${response.statusCode}");
      print("CREATE GLOBAL TASK BODY  : ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("CREATE GLOBAL TASK ERROR: $e");
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

  static Future<Map<String, dynamic>> getSalesPerformance(String period) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return {};
      final uri = Uri.parse(
        "$baseUrl/api/challan/sales-performance",
      ).replace(queryParameters: {'period': period});
      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
      return {};
    } catch (e) {
      print("SALES PERFORMANCE ERROR: $e");
      return {};
    }
  }

  static Future<Map<String, dynamic>> getSalesComparison(String period) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return {};
      final uri = Uri.parse(
        "$baseUrl/api/challan/sales-comparison",
      ).replace(queryParameters: {'period': period});
      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
      return {};
    } catch (e) {
      print("SALES COMPARISON ERROR: $e");
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingDeliveryBranchDetails({
    required String branchId,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse(
        "$baseUrl/api/challan/dashboard-pending-delivery-branch-details",
      ).replace(queryParameters: {'branchId': branchId.trim()});

      final response = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

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
      print("PENDING DELIVERY BRANCH DETAILS ERROR: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getPendingDeliveryBranchwise() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {'total': 0, 'branches': <dynamic>[]};
      }
      final response = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/dashboard-pending-delivery-branchwise",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

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
      print("PENDING DELIVERY BRANCHWISE ERROR: $e");
      return {'total': 0, 'branches': <dynamic>[]};
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

  /// Fetches model-wise booking / sale counts for today or yesterday.
  /// [type]:   'booking' or 'sale'
  /// [period]: 'today'   or 'yesterday'
  /// Returns { 'total': int, 'models': List<{modelName, count}> }
  static Future<Map<String, dynamic>> getDashboardModelwise(
    String type,
    String period,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {'total': 0, 'models': <dynamic>[]};
      }

      final response = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/dashboard-modelwise"
              "?type=$type&period=$period",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("MODELWISE STATUS: ${response.statusCode}");
      print("MODELWISE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;

        if (body['success'] == true && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data']);

          return {
            'total': (data['total'] as num?)?.toInt() ?? 0,
            'models': data['models'] is List ? data['models'] : <dynamic>[],
          };
        }
      }

      return {'total': 0, 'models': <dynamic>[]};
    } catch (e) {
      print("DASHBOARD MODELWISE ERROR: $e");

      return {'total': 0, 'models': <dynamic>[]};
    }
  }

  /// Fetches SC (Sales Consultant) wise sale counts for today or yesterday.
  /// [period]: 'today' or 'yesterday'
  /// Returns { 'total': int, 'scs': List<{scName, count}> }
  static Future<Map<String, dynamic>> getDashboardSCwise(String period) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {'total': 0, 'scs': <dynamic>[]};
      }

      final response = await http
          .get(
            Uri.parse("$baseUrl/api/challan/dashboard-scwise?period=$period"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("SCWISE STATUS: ${response.statusCode}");
      print("SCWISE RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data']);
          return {
            'total': (data['total'] as num?)?.toInt() ?? 0,
            'scs': data['scs'] is List ? data['scs'] : <dynamic>[],
          };
        }
      }
      return {'total': 0, 'scs': <dynamic>[]};
    } catch (e) {
      print("DASHBOARD SCWISE ERROR: $e");
      return {'total': 0, 'scs': <dynamic>[]};
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
  // ======================================================
  // AI MORNING DEALERSHIP BRIEFING
  // ======================================================

  static Future<Map<String, dynamic>> getMorningBriefing() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final session = await getUserSession();

      final databaseName = session?['databaseName']?.toString() ?? '';

      if (databaseName.isEmpty) {
        throw Exception("No dealership database selected.");
      }

      final url =
          "$baseUrl/api/ai/morning-briefing"
          "?databaseName=${Uri.encodeComponent(databaseName)}";

      print("");
      print("==========================================");
      print("🤖 AI MORNING BRIEFING");
      print("==========================================");
      print("Database: $databaseName");
      print("URL: $url");

      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("📡 AI MORNING BRIEFING STATUS: ${res.statusCode}");

      print("📦 AI MORNING BRIEFING RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        if (body["success"] == true) {
          print("✅ AI MORNING BRIEFING SUCCESS");

          return body;
        }

        throw Exception(body["message"] ?? "Morning briefing failed.");
      }

      if (res.statusCode == 401) {
        throw Exception("Authentication expired. Please login again.");
      }

      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        throw Exception(
          body["message"] ??
              body["error"] ??
              "Morning briefing request failed.",
        );
      } catch (_) {
        throw Exception(
          "Morning briefing request failed. "
          "HTTP ${res.statusCode}",
        );
      }
    } catch (e) {
      print("❌ AI MORNING BRIEFING ERROR: $e");

      rethrow;
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

  static Future<List<Map<String, dynamic>>> getCombinedReceipts() async {
    try {
      // ==================================================
      // AUTHENTICATION
      // ==================================================

      final token = await getToken();

      if (token == null || token.isEmpty) {
        print("❌ COMBINED RECEIPT: NO TOKEN");
        throw Exception("Authentication token missing");
      }

      // ==================================================
      // API URL
      // ==================================================

      final url = "$baseUrl/api/challan/receipt/combined";

      print("");
      print("==============================================");
      print("       COMBINED RECEIPT API DEBUG");
      print("==============================================");
      print("URL        : $url");
      print("TOKEN      : ${token.substring(0, 20)}...");
      print("==============================================");

      // ==================================================
      // API REQUEST
      // ==================================================

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      // ==================================================
      // RESPONSE DEBUG
      // ==================================================

      print("");
      print("========== COMBINED RECEIPT RESPONSE ==========");
      print("STATUS CODE : ${response.statusCode}");
      print("BODY        : ${response.body}");
      print("===============================================");

      // ==================================================
      // HTTP ERROR
      // ==================================================

      if (response.statusCode != 200) {
        throw Exception(
          "Combined Receipt API failed: "
          "HTTP ${response.statusCode}\n"
          "${response.body}",
        );
      }

      // ==================================================
      // JSON PARSE
      // ==================================================

      final body = jsonDecode(response.body);

      print("SUCCESS     : ${body["success"]}");
      print("DATA TYPE   : ${body["data"].runtimeType}");
      print("DATA        : ${body["data"]}");

      // ==================================================
      // API SUCCESS CHECK
      // ==================================================

      if (body["success"] != true) {
        throw Exception(
          body["message"]?.toString() ?? "API returned success=false",
        );
      }

      // ==================================================
      // DATA TYPE CHECK
      // ==================================================

      if (body["data"] is! List) {
        throw Exception(
          "API data is not a List. "
          "Actual type: ${body["data"].runtimeType}",
        );
      }

      // ==================================================
      // CONVERT API DATA
      // ==================================================

      final List<dynamic> data = body["data"];

      print("ROW COUNT   : ${data.length}");

      final result = data.map<Map<String, dynamic>>((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      // ==================================================
      // FINAL DEBUG
      // ==================================================

      print("PARSED ROWS  : ${result.length}");

      if (result.isNotEmpty) {
        final first = result.first;

        print("");
        print("========== FIRST RECEIPT ==========");
        print("Receipt ID   : ${first["receipt_id"]}");
        print("Receipt No   : ${first["receipt_no"]}");
        print("Receipt Date : ${first["receipt_date"]}");
        print("Customer     : ${first["customer_name"]}");
        print("Request Date : ${first["request_date"]}");
        print("Request ID   : ${first["request_id"]}");
        print("Request Type : ${first["request_type"]}");
        print("Value From   : ${first["value_from"]}");
        print("Value To     : ${first["value_to"]}");
        print("Status       : ${first["Status"]}");
        print("Reason       : ${first["Reason"]}");
        print("==================================");
      }

      return result;
    } catch (e, stackTrace) {
      print("");
      print("❌❌❌ COMBINED RECEIPT ERROR ❌❌❌");
      print("ERROR: $e");
      print("");
      print("STACK TRACE:");
      print(stackTrace);
      print("==============================================");

      rethrow;
    }
  }
  // ==========================================================
  // TODAY COMPLETE RECEIPTS
  // ==========================================================

  static Future<List<Map<String, dynamic>>> getTodayCompletedReceipts() async {
    try {
      // ==================================================
      // AUTHENTICATION
      // ==================================================

      final token = await getToken();

      if (token == null || token.isEmpty) {
        print("❌ TODAY COMPLETE RECEIPT: NO TOKEN");
        throw Exception("Authentication token missing");
      }

      // ==================================================
      // API URL
      // ==================================================

      final url = "$baseUrl/api/challan/receipt/today-complete";

      print("");
      print("==============================================");
      print("       TODAY COMPLETE RECEIPT API");
      print("==============================================");
      print("URL        : $url");
      print("==============================================");

      // ==================================================
      // API REQUEST
      // ==================================================

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      // ==================================================
      // DEBUG
      // ==================================================

      print("");
      print("========== TODAY COMPLETE RESPONSE ==========");
      print("STATUS CODE : ${response.statusCode}");
      print("BODY        : ${response.body}");
      print("==============================================");

      // ==================================================
      // HTTP ERROR
      // ==================================================

      if (response.statusCode != 200) {
        throw Exception(
          "Today Complete Receipt API failed: "
          "HTTP ${response.statusCode}\n"
          "${response.body}",
        );
      }

      // ==================================================
      // JSON
      // ==================================================

      final body = jsonDecode(response.body);

      if (body["success"] != true) {
        throw Exception(
          body["message"]?.toString() ?? "API returned success=false",
        );
      }

      // ==================================================
      // DATA CHECK
      // ==================================================

      if (body["data"] is! List) {
        throw Exception(
          "API data is not a List. "
          "Actual type: ${body["data"].runtimeType}",
        );
      }

      // ==================================================
      // CONVERT DATA
      // ==================================================

      final List<dynamic> data = body["data"];

      final result = data
          .map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          )
          .toList();

      print("TODAY COMPLETE ROW COUNT: ${result.length}");

      return result;
    } catch (e, stackTrace) {
      print("");
      print("❌❌❌ TODAY COMPLETE RECEIPT ERROR ❌❌❌");
      print("ERROR: $e");
      print("STACK TRACE:");
      print(stackTrace);
      print("==============================================");

      rethrow;
    }
  }
  // ==========================================================
  // UPDATE RECEIPT REQUEST
  // ==========================================================

  static Future<Map<String, dynamic>> updateReceiptRequest({
    required String requestUnqid,
    required String recptUnqid,
    required String reqType,
    String? valTo,
  }) async {
    try {
      // ==================================================
      // GET TOKEN
      // ==================================================

      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication token missing");
      }

      // ==================================================
      // API URL
      // ==================================================

      final url = "$baseUrl/api/challan/receipt/update";

      // ==================================================
      // NORMALIZE REQUEST TYPE
      // ==================================================

      final normalizedReqType = reqType.trim().toLowerCase();

      // ==================================================
      // NORMALIZE VALUE TO
      // ==================================================

      String? finalValueTo;

      if (valTo != null && valTo.trim().isNotEmpty) {
        finalValueTo = valTo.trim();
      } else {
        finalValueTo = null;
      }

      // ==================================================
      // REQUEST BODY
      // ==================================================

      final body = {
        // app_receipt_request.unqid
        "request_unqid": requestUnqid.trim(),

        // rh_rcl.rcl_2
        "recpt_unqid": recptUnqid.trim(),

        // Request type
        "req_type": reqType.trim(),

        // New value
        // Cancel request can be NULL
        "val_to": finalValueTo,
      };

      // ==================================================
      // DEBUG
      // ==================================================

      print("");
      print("==============================================");
      print("       UPDATE RECEIPT API CALL");
      print("==============================================");
      print("URL           : $url");
      print("request_unqid : ${requestUnqid.trim()}");
      print("recpt_unqid   : ${recptUnqid.trim()}");
      print("req_type      : ${reqType.trim()}");
      print("normalized    : $normalizedReqType");
      print("val_to        : $finalValueTo");
      print("BODY          : ${jsonEncode(body)}");
      print("==============================================");

      // ==================================================
      // VALIDATION
      // ==================================================

      if (requestUnqid.trim().isEmpty) {
        throw Exception("requestUnqid is required");
      }

      if (recptUnqid.trim().isEmpty) {
        throw Exception("recptUnqid is required");
      }

      if (reqType.trim().isEmpty) {
        throw Exception("reqType is required");
      }

      // ==================================================
      // VALUE TO VALIDATION
      // ==================================================
      // Cancel does NOT require value_to.
      //
      // Other request types require value_to.
      // ==================================================

      if (normalizedReqType != "cancel") {
        if (finalValueTo == null || finalValueTo == "-") {
          throw Exception("Value To not found");
        }
      }

      // ==================================================
      // API CALL
      // ==================================================

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      // ==================================================
      // RESPONSE DEBUG
      // ==================================================

      print("");
      print("==============================================");
      print("       UPDATE RECEIPT API RESPONSE");
      print("==============================================");
      print("STATUS : ${response.statusCode}");
      print("BODY   : ${response.body}");
      print("==============================================");

      // ==================================================
      // HTTP ERROR
      // ==================================================

      if (response.statusCode != 200) {
        throw Exception(
          "Update Receipt API failed: "
          "HTTP ${response.statusCode}\n"
          "${response.body}",
        );
      }

      // ==================================================
      // DECODE RESPONSE
      // ==================================================

      final decodedResponse = jsonDecode(response.body);

      if (decodedResponse is! Map<String, dynamic>) {
        throw Exception("Invalid API response format");
      }

      final result = decodedResponse;

      // ==================================================
      // API SUCCESS CHECK
      // ==================================================

      if (result["success"] != true) {
        throw Exception(
          result["message"]?.toString() ?? "Receipt update failed",
        );
      }

      // ==================================================
      // SUCCESS DEBUG
      // ==================================================

      print("");
      print("==============================================");
      print("       RECEIPT UPDATE SUCCESS");
      print("==============================================");
      print("Request Unqid : ${requestUnqid.trim()}");
      print("Receipt Unqid : ${recptUnqid.trim()}");
      print("Request Type  : ${reqType.trim()}");
      print("Value To      : $finalValueTo");
      print("Status        : ${result["request_status"]}");
      print("Message       : ${result["message"]}");
      print("==============================================");

      return result;
    } catch (e) {
      // ==================================================
      // ERROR
      // ==================================================

      print("");
      print("==============================================");
      print("❌ UPDATE RECEIPT API ERROR");
      print("==============================================");
      print("ERROR : $e");
      print("==============================================");

      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayApproveChallans() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return [];
      }

      final uri = Uri.parse("$baseUrl/api/challan/today-approve");

      final res = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("TODAY APPROVE STATUS: ${res.statusCode}");
      print("TODAY APPROVE RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        if (body["success"] == true && body["data"] is List) {
          return List<Map<String, dynamic>>.from(
            (body["data"] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      return [];
    } catch (e) {
      print("TODAY APPROVE ERROR: $e");
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayRejectChallans() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return [];
      }

      final uri = Uri.parse("$baseUrl/api/challan/today-reject");

      final res = await http.get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print("TODAY REJECT STATUS: ${res.statusCode}");
      print("TODAY REJECT RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        if (body["success"] == true && body["data"] is List) {
          return List<Map<String, dynamic>>.from(
            (body["data"] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }

      return [];
    } catch (e) {
      print("TODAY REJECT ERROR: $e");
      return [];
    }
  }

  /// Fetches sale detail rows for a specific SC and period.
  /// Calls GET /api/challan/sc-sale-details
  /// [period]: 'today' or 'yesterday'
  /// [scId]: the sp_550 value (SC identifier)
  /// [scName]: display name for logging
  static Future<List<Map<String, dynamic>>> getSCSaleDetails({
    required String period,
    required String scId,
    String scName = '',
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse("$baseUrl/api/challan/sc-sale-details").replace(
        queryParameters: {
          'period': period,
          'scId': scId.trim(),
          if (scName.trim().isNotEmpty) 'scName': scName.trim(),
        },
      );

      print("========== SC SALE DETAIL API ==========");
      print("URI     : $uri");
      print("Period  : $period");
      print("SC Id   : $scId");
      print("SC Name : $scName");
      print("========================================");

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
      print("SC SALE DETAILS ERROR: $e");
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════
  // VEHICLE ALLOCATION
  // ═══════════════════════════════════════════════════════════

  /// Fetches the full vehicle allocation list (@what = 'grid').
  static Future<List<Map<String, dynamic>>> getVehicleAllocationList() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/vehicle-allocation/list"),
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
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return [];
    } catch (e) {
      print("VA LIST ERROR: $e");
      return [];
    }
  }

  /// Searches vehicle allocations by customer name or VIN.
  static Future<List<Map<String, dynamic>>> searchVehicleAllocation(
    String query,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse(
        "$baseUrl/api/vehicle-allocation/search",
      ).replace(queryParameters: {"q": query});

      final res = await http
          .get(
            uri,
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
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return [];
    } catch (e) {
      print("VA SEARCH ERROR: $e");
      return [];
    }
  }

  /// Fetches a single vehicle allocation for editing plus its VIN list.
  /// Returns a map with keys: [data] (record map) and [vinList] (list).
  static Future<Map<String, dynamic>?> getVehicleAllocationEdit(
    String va12,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/vehicle-allocation/edit/$va12"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return {
            "data": Map<String, dynamic>.from(
              body['data'] as Map<String, dynamic>,
            ),
            "vinList": List<Map<String, dynamic>>.from(
              ((body['vinList'] ?? []) as List).map(
                (e) => Map<String, dynamic>.from(e),
              ),
            ),
          };
        }
      }
      return null;
    } catch (e) {
      print("VA EDIT ERROR: $e");
      return null;
    }
  }

  /// Fetches all dropdown data: customers, models, variants, colours,
  /// locations, staff — in a single call.
  static Future<Map<String, List<Map<String, dynamic>>>>
  getVehicleAllocationDropdowns() async {
    final empty = <String, List<Map<String, dynamic>>>{
      "customers": [],
      "models": [],
      "variants": [],
      "colours": [],
      "locations": [],
      "staff": [],
    };
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return empty;

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/vehicle-allocation/dropdowns"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          final d = body['data'] as Map<String, dynamic>;
          return {
            "customers": _toMapList(d['customers']),
            "models": _toMapList(d['models']),
            "variants": _toMapList(d['variants']),
            "colours": _toMapList(d['colours']),
            "locations": _toMapList(d['locations']),
            "staff": _toMapList(d['staff']),
          };
        }
      }
      return empty;
    } catch (e) {
      print("VA DROPDOWNS ERROR: $e");
      return empty;
    }
  }

  /// Fetches booking + staff details after a customer is selected.
  static Future<Map<String, dynamic>?> getVehicleAllocationCustomerDetails(
    String custUnq,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/vehicle-allocation/customer-details/$custUnq",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(
            body['data'] as Map<String, dynamic>,
          );
        }
      }
      return null;
    } catch (e) {
      print("VA CUSTOMER DETAILS ERROR: $e");
      return null;
    }
  }

  /// Fetches available VIN numbers for a model/variant/colour combination.
  static Future<List<Map<String, dynamic>>> getVehicleAllocationVinList({
    required String model,
    required String variant,
    required String colour,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse("$baseUrl/api/vehicle-allocation/vinno").replace(
        queryParameters: {"model": model, "variant": variant, "colour": colour},
      );

      final res = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return _toMapList(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("VA VINNO ERROR: $e");
      return [];
    }
  }

  /// Fetches the full VIN details grid for a model/variant/colour combo.
  static Future<List<Map<String, dynamic>>> getVehicleAllocationVinDetails({
    required String model,
    required String variant,
    required String colour,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final uri = Uri.parse("$baseUrl/api/vehicle-allocation/all-vin-details")
          .replace(
            queryParameters: {
              "model": model,
              "variant": variant,
              "colour": colour,
            },
          );

      final res = await http
          .get(
            uri,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          return _toMapList(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("VA VIN DETAILS ERROR: $e");
      return [];
    }
  }

  /// Saves a new vehicle allocation record.
  static Future<Map<String, dynamic>> saveVehicleAllocation(
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .post(
            Uri.parse("$baseUrl/api/vehicle-allocation/save"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        return body;
      }

      throw Exception(body['message'] ?? "Save failed");
    } catch (e) {
      print("VA SAVE ERROR: $e");
      rethrow;
    }
  }

  /// Deletes a vehicle allocation record by its unique ID.
  static Future<Map<String, dynamic>> deleteVehicleAllocation(
    String va12,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .delete(
            Uri.parse("$baseUrl/api/vehicle-allocation/$va12"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        return body;
      }

      throw Exception(body['message'] ?? "Delete failed");
    } catch (e) {
      print("VA DELETE ERROR: $e");
      rethrow;
    }
  }

  /// Cancels a vehicle allocation record with a reason.
  static Future<Map<String, dynamic>> cancelVehicleAllocation({
    required String va12,
    required String reason,
    required String cancellationDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .post(
            Uri.parse("$baseUrl/api/vehicle-allocation/cancel"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              "va_12": va12,
              "va_31": reason,
              "va_32": cancellationDate,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        return body;
      }

      throw Exception(body['message'] ?? "Cancel failed");
    } catch (e) {
      print("VA CANCEL ERROR: $e");
      rethrow;
    }
  }

  // ── Private helper: safely cast a dynamic list to List<Map<String,dynamic>> ──
  static List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{};
    }).toList();
  }

  // BOOKING FORM DROPDOWNS
  // GET /api/booking/dropdowns
  // Returns: states, cities, areas, models, colours, scNames
  static Future<Map<String, List<Map<String, dynamic>>>>
  getBookingFormDropdowns() async {
    final empty = <String, List<Map<String, dynamic>>>{
      'states': [],
      'cities': [],
      'areas': [],
      'models': [],
      'colours': [],
      'scNames': [],
    };
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return empty;

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/booking/dropdowns"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is Map) {
          final d = body['data'] as Map<String, dynamic>;
          return {
            'states': _toMapList(d['states']),
            'cities': _toMapList(d['cities']),
            'areas': _toMapList(d['areas']),
            'models': _toMapList(d['models']),
            'colours': _toMapList(d['colours']),
            'scNames': _toMapList(d['scNames']),
          };
        }
      }
      print("BOOKING DROPDOWNS HTTP ${res.statusCode}: ${res.body}");
      return empty;
    } catch (e) {
      print("BOOKING DROPDOWNS ERROR: $e");
      return empty;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING VARIANTS by model
  // GET /api/booking/variants/
  // @what = 'vardata' with @Rcl_71 = modelUnq
  // Returns: [ { value, data, sp_20_4 }, ... ]
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getBookingVariants(
    String modelUnq,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/booking/variants/${Uri.encodeComponent(modelUnq)}",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }
      print("BOOKING VARIANTS HTTP ${res.statusCode}");
      return [];
    } catch (e) {
      print("BOOKING VARIANTS ERROR: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  // SAVE BOOKING REQUEST
  // POST /api/booking/save
  // Step 1: inserts into rh_m1 via A_SP_FOR_ACCOUNTMASTER @what='insert'
  // Step 2: inserts docket row into rh_sp_73 with all 18 mapped fields
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> saveBookingRequest({
    required String title,
    required String name,
    required String fatherName,
    required String emailId,
    required String address,
    required String state,
    required String cityUnq,
    required String areaUnq,
    required String zip,
    required String mobileNo,
    required String gstin,
    required String birthAnniversary,
    required String marriageAnniversary,
    required String aadharNo,
    required String modelUnq,
    required String variantUnq,
    required String colourUnq,
    required String scUnq,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .post(
            Uri.parse("$baseUrl/api/booking/save"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              'title': title,
              'name': name,
              'fatherName': fatherName,
              'emailId': emailId,
              'address': address,
              'state': state,
              'cityUnq': cityUnq,
              'areaUnq': areaUnq,
              'zip': zip,
              'mobileNo': mobileNo,
              'gstin': gstin,
              'birthAnniversary': birthAnniversary,
              'marriageAnniversary': marriageAnniversary,
              'aadharNo': aadharNo,
              'modelUnq': modelUnq,
              'variantUnq': variantUnq,
              'colourUnq': colourUnq,
              'scUnq': scUnq,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        return body;
      }

      throw Exception(body['message'] ?? "Save failed");
    } catch (e) {
      print("BOOKING SAVE ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEW BOOKING REQUEST API
  // POST /api/booking/save-new
  // This is a separate API and does NOT modify the existing save API.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> saveNewBookingRequest({
    required String title,
    required String name,
    required String fatherName,
    required String emailId,
    required String address,
    required String state,
    required String cityUnq,
    required String areaUnq,
    required String zip,
    required String mobileNo,
    required String gstin,
    required String birthAnniversary,
    required String marriageAnniversary,
    required String aadharNo,
    required String panNo, // ADD
    required String modelUnq,
    required String variantUnq,
    required String colourUnq,
    required String scUnq,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .post(
            Uri.parse("$baseUrl/api/booking/save-new"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode({
              'title': title,
              'name': name,
              'fatherName': fatherName,
              'emailId': emailId,
              'address': address,
              'state': state,
              'cityUnq': cityUnq,
              'areaUnq': areaUnq,
              'zip': zip,
              'mobileNo': mobileNo,
              'gstin': gstin,
              'birthAnniversary': birthAnniversary,
              'marriageAnniversary': marriageAnniversary,
              'aadharNo': aadharNo,
              'panNo': panNo, // ADD
              'modelUnq': modelUnq,
              'variantUnq': variantUnq,
              'colourUnq': colourUnq,
              'scUnq': scUnq,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && body['success'] == true) {
        return body;
      }

      throw Exception(body['message'] ?? "Save failed");
    } catch (e) {
      print("NEW BOOKING SAVE ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING CITIES by STATE
  // GET /api/booking/cities/:stateUnq
  // `stateUnq` must be the internal State UNQID (`value`), not the display name.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getBookingCities(
    String stateUnq,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        print("BOOKING CITIES: No authentication token.");
        return [];
      }

      final cleanStateUnq = stateUnq.trim();

      if (cleanStateUnq.isEmpty) {
        print("BOOKING CITIES: State UNQID is empty.");
        return [];
      }

      final url =
          "$baseUrl/api/booking/cities/${Uri.encodeComponent(cleanStateUnq)}";

      print("BOOKING CITIES URL: $url");

      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("BOOKING CITIES STATUS: ${res.statusCode}");
      print("BOOKING CITIES RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }

      return [];
    } catch (e) {
      print("BOOKING CITIES ERROR: $e");
      return [];
    }
  }
  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING REQUEST GRID
  // GET /api/booking/request-grid
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getBookingRequestGrid() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/booking/request-grid"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("BOOKING REQUEST GRID STATUS: ${res.statusCode}");
      print("BOOKING REQUEST GRID RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }

      print("BOOKING REQUEST GRID HTTP ${res.statusCode}: ${res.body}");

      return [];
    } catch (e) {
      print("BOOKING REQUEST GRID ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOOKING AREAS by CITY
  // GET /api/booking/areas/:cityUnq
  // `cityUnq` must be the internal City UNQID (`value`), not the display name.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getBookingAreas(
    String cityUnq,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        print("BOOKING AREAS: No authentication token.");
        return [];
      }

      final cleanCityUnq = cityUnq.trim();

      if (cleanCityUnq.isEmpty) {
        print("BOOKING AREAS: City UNQID is empty.");
        return [];
      }

      final url =
          "$baseUrl/api/booking/areas/${Uri.encodeComponent(cleanCityUnq)}";

      print("BOOKING AREAS URL: $url");

      final res = await http
          .get(
            Uri.parse(url),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("BOOKING AREAS STATUS: ${res.statusCode}");
      print("BOOKING AREAS RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }

      return [];
    } catch (e) {
      print("BOOKING AREAS ERROR: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACC CANCEL — SLIP HEADER
  // GET /api/booking/acc-cancel-slip/:unqid
  // Returns the header record for one requisition slip (SP what='Edit').
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getAccCancelSlipHeader(
    String unqid,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/booking/acc-cancel-slip/${Uri.encodeComponent(unqid)}",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("ACC CANCEL SLIP HEADER STATUS: ${res.statusCode}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(
            body['data'] as Map<String, dynamic>,
          );
        }
      }

      print("ACC CANCEL SLIP HEADER HTTP ${res.statusCode}: ${res.body}");
      return null;
    } catch (e) {
      print("ACC CANCEL SLIP HEADER ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACC CANCEL — CHILD ACCESSORY DETAILS
  // GET /api/booking/acc-cancel-details/:unqid
  // Returns cancelled-but-not-yet-approved rows from rh_sp_43_c.
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAccCancelDetails(
    String unqid,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/booking/acc-cancel-details/${Uri.encodeComponent(unqid)}",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("ACC CANCEL DETAILS STATUS: ${res.statusCode}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }

      print("ACC CANCEL DETAILS HTTP ${res.statusCode}: ${res.body}");
      return [];
    } catch (e) {
      print("ACC CANCEL DETAILS ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACC CANCEL — DOCKET GRID
  // GET /api/booking/acc-cancel-docket/:custUnq
  // Returns docket/package rows for the customer (SP what='Docket_details').
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAccCancelDocket(
    String custUnq,
  ) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/booking/acc-cancel-docket/${Uri.encodeComponent(custUnq)}",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("ACC CANCEL DOCKET STATUS: ${res.statusCode}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }

      print("ACC CANCEL DOCKET HTTP ${res.statusCode}: ${res.body}");
      return [];
    } catch (e) {
      print("ACC CANCEL DOCKET ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACCESSORIES CANCELLATION APPROVAL GRID
  // GET /api/booking/acc-cancel-approve-grid
  // Returns requisition slips that have pending accessory cancellation
  // approvals (sp_what = 'gridcancelapprove').
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAccCancelApproveGrid() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .get(
            Uri.parse("$baseUrl/api/booking/acc-cancel-approve-grid"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("ACC CANCEL APPROVE GRID STATUS: ${res.statusCode}");
      print("ACC CANCEL APPROVE GRID RESPONSE: ${res.body}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;

        if (body['success'] == true) {
          return _toMapList(body['data']);
        }
      }

      print("ACC CANCEL APPROVE GRID HTTP ${res.statusCode}: ${res.body}");

      return [];
    } catch (e) {
      print("ACC CANCEL APPROVE GRID ERROR: $e");
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACC CANCEL — ACCESSORIES TOTAL
  // GET /api/booking/acc-cancel-acc-total/:unqid
  // Returns the sum of MRP × Qty for ALL rh_sp_43_c rows for the slip,
  // regardless of cancellation/approval status — used for the totals bar.
  // ─────────────────────────────────────────────────────────────────────────

  static Future<double> getAccCancelAccTotal(String unqid) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception("Authentication required. Please login again.");
      }

      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/booking/acc-cancel-acc-total/${Uri.encodeComponent(unqid)}",
            ),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 30));

      print("ACC CANCEL ACC TOTAL STATUS: ${res.statusCode}");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          final v = body['data']?['accessories_total'];
          return (v is num)
              ? v.toDouble()
              : double.tryParse(v?.toString() ?? '') ?? 0;
        }
      }

      print("ACC CANCEL ACC TOTAL HTTP ${res.statusCode}: ${res.body}");
      return 0;
    } catch (e) {
      print("ACC CANCEL ACC TOTAL ERROR: $e");
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACC CANCEL — APPROVE
  // POST /api/booking/acc-cancel-approve/:childUnq
  // Stamps sp_43_15 = GETDATE() on the child row and recalculates sp_46.
  // :childUnq = sp_43_2 (primary key of rh_sp_43_c)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> approveAccCancel(String childUnq) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authentication required. Please login again.");
    }

    final res = await http
        .post(
          Uri.parse(
            "$baseUrl/api/booking/acc-cancel-approve/${Uri.encodeComponent(childUnq)}",
          ),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        )
        .timeout(const Duration(seconds: 30));

    print("ACC CANCEL APPROVE STATUS: ${res.statusCode}");
    print("ACC CANCEL APPROVE RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) return;
      throw Exception(body['message'] ?? 'Approve failed');
    }

    // surface server-side error message when possible
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Approve failed (${res.statusCode})');
    } catch (_) {
      throw Exception('Approve failed (${res.statusCode})');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ACC CANCEL — REJECT
  // POST /api/booking/acc-cancel-reject/:childUnq
  // Body: { "reason": "<rejection reason text>" }
  // Sets sp_43_18 = timestamp|reason, sp_43_19 = userid, sp_43_20 = ipadd.
  // sp_43_7 (cancel request date) is intentionally left unchanged.
  // :childUnq = sp_43_2 (primary key of rh_sp_43_c)
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> rejectAccCancel(String childUnq, String reason) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception("Authentication required. Please login again.");
    }

    final res = await http
        .post(
          Uri.parse(
            "$baseUrl/api/booking/acc-cancel-reject/${Uri.encodeComponent(childUnq)}",
          ),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"reason": reason}),
        )
        .timeout(const Duration(seconds: 30));

    print("ACC CANCEL REJECT STATUS: ${res.statusCode}");
    print("ACC CANCEL REJECT RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) return;
      throw Exception(body['message'] ?? 'Reject failed');
    }

    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Reject failed (${res.statusCode})');
    } catch (_) {
      throw Exception('Reject failed (${res.statusCode})');
    }
  }

  static Future<List<dynamic>> getAppPermissions() async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/app-permissions'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return data['screens'] ?? [];
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Returns booking customers available for a new challan.
  static Future<List<Map<String, dynamic>>> getChallanNewCustomers() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/customers"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanNewCustomers ERROR: $e");
      return [];
    }
  }

  /// Returns all vehicle models.
  static Future<List<Map<String, dynamic>>> getChallanModels() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/models"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanModels ERROR: $e");
      return [];
    }
  }

  /// Returns variants for a given model id.
  static Future<List<Map<String, dynamic>>> getChallanVariants(
    String modelId,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/new/variants?modelId=${Uri.encodeComponent(modelId)}",
            ),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanVariants ERROR: $e");
      return [];
    }
  }

  /// Returns available stock colors for a variant.
  static Future<List<Map<String, dynamic>>> getChallanColors(
    String variantId,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/new/colors?variantId=${Uri.encodeComponent(variantId)}",
            ),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanColors ERROR: $e");
      return [];
    }
  }

  /// Returns VINs available for the selected variant + color.
  static Future<List<Map<String, dynamic>>> getChallanVins({
    required String variantId,
    String colorId = '',
    String challanType = 'Customer Challan',
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final params = <String, String>{
        'variantId': variantId,
        if (colorId.isNotEmpty) 'colorId': colorId,
        'challanType': challanType,
      };
      final uri = Uri.parse(
        "$baseUrl/api/challan/new/vins",
      ).replace(queryParameters: params);
      final res = await http
          .get(uri, headers: {"Authorization": "Bearer $token"})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanVins ERROR: $e");
      return [];
    }
  }

  /// Returns variant pricing details (ex-showroom, charges, taxes) from rh_sp_37_c.
  static Future<Map<String, dynamic>?> getChallanVariantDetails({
    required String variantId,
    String challanDate = '',
    String stateId = '',
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;
      final params = <String, String>{
        'variantId': variantId,
        if (challanDate.isNotEmpty) 'challanDate': challanDate,
        if (stateId.isNotEmpty) 'stateId': stateId,
      };
      final uri = Uri.parse(
        "$baseUrl/api/challan/new/variant-details",
      ).replace(queryParameters: params);
      final res = await http
          .get(uri, headers: {"Authorization": "Bearer $token"})
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
      return null;
    } catch (e) {
      print("getChallanVariantDetails ERROR: $e");
      return null;
    }
  }

  /// Returns all RTO cities.
  static Future<List<Map<String, dynamic>>> getChallanRtoCities() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/rto-cities"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanRtoCities ERROR: $e");
      return [];
    }
  }

  /// Returns hypothecation (HPN / bank) list.
  static Future<List<Map<String, dynamic>>> getChallanHpnList() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/hpn-list"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanHpnList ERROR: $e");
      return [];
    }
  }

  /// Returns states list.
  static Future<List<Map<String, dynamic>>> getChallanStates() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/states"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanStates ERROR: $e");
      return [];
    }
  }

  /// Returns branch list.
  static Future<List<Map<String, dynamic>>> getChallanBranches() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/branches"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanBranches ERROR: $e");
      return [];
    }
  }

  /// Returns insurance companies.
  static Future<List<Map<String, dynamic>>>
  getChallanInsuranceCompanies() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/insurance-companies"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] is List) {
          return List<Map<String, dynamic>>.from(body['data']);
        }
      }
      return [];
    } catch (e) {
      print("getChallanInsuranceCompanies ERROR: $e");
      return [];
    }
  }

  /// Returns the next auto-incremented challan number.
  static Future<int> getChallanNextNo() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return 1;
      final res = await http
          .get(
            Uri.parse("$baseUrl/api/challan/new/next-challan-no"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true) {
          return (body['nextNo'] as num?)?.toInt() ?? 1;
        }
      }
      return 1;
    } catch (e) {
      print("getChallanNextNo ERROR: $e");
      return 1;
    }
  }

  /// Returns receipt amounts already collected for a customer.
  static Future<Map<String, dynamic>> getChallanReceiptAmounts(
    String customerId,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return {};
      final res = await http
          .get(
            Uri.parse(
              "$baseUrl/api/challan/new/receipt-amounts?customerId=${Uri.encodeComponent(customerId)}",
            ),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
      return {};
    } catch (e) {
      print("getChallanReceiptAmounts ERROR: $e");
      return {};
    }
  }

  /// Saves a new challan.
  /// [formData] should contain all sp_xxx fields + prefix, pageno.
  static Future<Map<String, dynamic>> saveChallanNew(
    Map<String, dynamic> formData,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        throw Exception("Not authenticated");
      }
      print("ðŸš— saveChallanNew: Sending ${formData.keys.length} fields");
      final res = await http
          .post(
            Uri.parse("$baseUrl/api/challan/new/save"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(formData),
          )
          .timeout(const Duration(seconds: 45));

      print("saveChallanNew status: ${res.statusCode}");
      print("saveChallanNew body: ${res.body}");

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return body;
      }
      throw Exception(body['message'] ?? "Save failed");
    } catch (e) {
      print("saveChallanNew ERROR: $e");
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW CHALLAN – ADDITIONAL FORM SUPPORT METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Returns receipt rows for a customer (payments received).
  /// Maps to A_SP_FOR_Challan @what='griddata11'
  static Future<Map<String, dynamic>> getChallanReceiptGrid(
    String customerId,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return {'rows': [], 'rcTotal': 0};
      final uri = Uri.parse(
        '$baseUrl/api/challan/new/receipt-grid',
      ).replace(queryParameters: {'customerId': customerId});
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) return body;
      }
      return {'rows': [], 'rcTotal': 0};
    } catch (e) {
      print('getChallanReceiptGrid ERROR: $e');
      return {'rows': [], 'rcTotal': 0};
    }
  }

  /// Loads an existing challan for editing.
  /// Maps to A_SP_FOR_Challan @what='Edit'
  static Future<Map<String, dynamic>?> loadChallanForEdit(String sp462) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;
      final res = await http
          .get(
            Uri.parse(
              '$baseUrl/api/challan/new/load/${Uri.encodeComponent(sp462)}',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true)
          return body['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('loadChallanForEdit ERROR: $e');
      return null;
    }
  }

  /// Updates an existing challan.
  /// Maps to A_SP_FOR_Challan @what='update'
  static Future<Map<String, dynamic>> updateChallan(
    Map<String, dynamic> formData,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');
      final res = await http
          .post(
            Uri.parse('$baseUrl/api/challan/new/update'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(formData),
          )
          .timeout(const Duration(seconds: 45));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return body;
      throw Exception(body['message'] ?? 'Update failed');
    } catch (e) {
      print('updateChallan ERROR: $e');
      rethrow;
    }
  }

  /// Returns customer list by challan type.
  /// type: 'booking' | 'csd' | 'dealer' | 'stb' | 'usedcar'
  static Future<List<Map<String, dynamic>>> getChallanCustomersByType(
    String type,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final uri = Uri.parse(
        '$baseUrl/api/challan/new/customers-by-type',
      ).replace(queryParameters: {'type': type});
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return [];
    } catch (e) {
      print('getChallanCustomersByType ERROR: $e');
      return [];
    }
  }

  /// Returns city list (for Add City dialog).
  static Future<List<Map<String, dynamic>>> getChallanCities() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/challan/new/cities'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return [];
    } catch (e) {
      print('getChallanCities ERROR: $e');
      return [];
    }
  }

  /// Saves a new city via A_SP_FOR_ACCOUNTMASTER @what='insert'.
  /// Returns the refreshed city list on success, or throws on error.
  static Future<List<Map<String, dynamic>>> saveChallanCity({
    required String cityName,
    required String stateName,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/challan/new/add-city'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'cityName': cityName, 'stateName': stateName}),
        )
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(
        (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    throw Exception(body['message'] ?? 'Failed to save city');
  }

  /// Returns TCS percentage for a given date.
  /// Maps to A_SP_FOR_Challan @what='tcsdata'
  static Future<double> getChallanTcsData(String date) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return 0.0;
      final uri = Uri.parse(
        '$baseUrl/api/challan/new/tcs-data',
      ).replace(queryParameters: {'date': date});
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return double.tryParse(body['tcs']?.toString() ?? '0') ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      print('getChallanTcsData ERROR: $e');
      return 0.0;
    }
  }

  /// Returns own RTO city for a branch.
  /// Maps to A_SP_FOR_Challan @what='ownrto'
  static Future<Map<String, dynamic>?> getChallanOwnRto(String branchId) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return null;
      final uri = Uri.parse(
        '$baseUrl/api/challan/new/own-rto',
      ).replace(queryParameters: {'branchId': branchId});
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] != null) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
      return null;
    } catch (e) {
      print('getChallanOwnRto ERROR: $e');
      return null;
    }
  }

  /// Returns HPN child branches for a parent HPN.
  /// Maps to A_SP_FOR_Challan @what='branchhpndata'
  static Future<List<Map<String, dynamic>>> getChallanHpnBranches(
    String hpnId,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final uri = Uri.parse(
        '$baseUrl/api/challan/new/hpn-branches',
      ).replace(queryParameters: {'hpnId': hpnId});
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return [];
    } catch (e) {
      print('getChallanHpnBranches ERROR: $e');
      return [];
    }
  }

  /// Deletes a challan (admin only, checks SI + STB).
  static Future<Map<String, dynamic>> deleteChallanById(
    String sp462,
    String custId,
  ) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) throw Exception('Not authenticated');
      final uri = Uri.parse(
        '$baseUrl/api/challan/new/${Uri.encodeComponent(sp462)}',
      ).replace(queryParameters: {'custId': custId});
      final res = await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 30));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body;
    } catch (e) {
      print('deleteChallanById ERROR: $e');
      rethrow;
    }
  }

  /// Returns retail support (scheme amounts from booking).
  /// Maps to A_SP_FOR_Challan @what='Retail_support'
  static Future<Map<String, dynamic>> getChallanRetailSupport({
    required String variantId,
    required String modelId,
    required String vinNo,
    required String challanDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return {};
      final uri = Uri.parse('$baseUrl/api/challan/new/retail-support').replace(
        queryParameters: {
          'variant': variantId,
          'model': modelId,
          'vinno': vinNo,
          'challandate': challanDate,
        },
      );
      final res = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return Map<String, dynamic>.from(body['data'] as Map? ?? {});
        }
      }
      return {};
    } catch (e) {
      print('getChallanRetailSupport ERROR: $e');
      return {};
    }
  }

  /// Returns area list.
  static Future<List<Map<String, dynamic>>> getChallanAreas() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) return [];
      final res = await http
          .get(
            Uri.parse('$baseUrl/api/challan/new/areas'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          return List<Map<String, dynamic>>.from(
            (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
      return [];
    } catch (e) {
      print('getChallanAreas ERROR: $e');
      return [];
    }
  }

  /// Saves a new area via A_SP_FOR_AreaMaster @what='insert'.
  /// Returns the refreshed area list on success, or throws on error.
  static Future<List<Map<String, dynamic>>> saveChallanArea({
    required String areaName,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated');
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/challan/new/add-area'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'areaName': areaName}),
        )
        .timeout(const Duration(seconds: 20));
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['success'] == true) {
      return List<Map<String, dynamic>>.from(
        (body['data'] as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    throw Exception(body['message'] ?? 'Failed to save area');
  }
}

class SendMessageResponse {
  final bool success;
  final String? chatId;

  SendMessageResponse({required this.success, this.chatId});

  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      success: json["success"] == true,
      chatId: json["data"]?["chatId"]?.toString(),
    );
  }
}
