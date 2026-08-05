import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

/// A simple cache service that stores API response data locally.
///
/// Strategy:
///   1. Screen opens → read cache → show UI immediately (if cache exists)
///   2. Fetch from backend in background
///   3. If data changed → update cache → refresh UI
class CacheService {
  static const String _prefix = 'cache_';
  static const String _tsPrefix = 'cache_ts_';

  static Box _getBox(String key) {
    // Chat
    if (key == keyChatList ||
        key == keyDirectChats ||
        key == keyGroups ||
        key.startsWith('chat_messages_') ||
        key.startsWith('direct_messages_') ||
        key.startsWith('group_messages_') ||
        key.startsWith('group_members_')) {
      return Hive.box('chatBox');
    }

    // Dashboard
    if (key == keyDashboardStats ||
        key == keyDashboardBranchwise ||
        key.startsWith('branchwise_')) {
      return Hive.box('dashboardBox');
    }

    // Challan
    if (key == keyChallanList || key.startsWith('challan')) {
      return Hive.box('challanBox');
    }

    // Notifications
    if (key == keyNotifications || key.startsWith('notification')) {
      return Hive.box('notificationBox');
    }

    // Users / Contacts
    if (key == keyContacts || key == keyMergedUsers) {
      return Hive.box('userBox');
    }

    // Default
    return Hive.box('settingsBox');
  }

  // ── TTL constants (milliseconds) ─────────────────────────────────────────

  /// No TTL
  static const int ttlNone = 0;

  /// 1 minute
  static const int ttlShort = 60 * 1000;

  /// 2 minutes
  static const int ttlMedium = 2 * 60 * 1000;

  /// 5 minutes
  static const int ttlDashboard = 5 * 60 * 1000;

  /// 10 minutes
  static const int ttlLong = 10 * 60 * 1000;

  // ── Cache keys ────────────────────────────────────────────────────────────

  static const String keyChallanList = 'challan_list';
  static const String keyChatList = 'chat_list';
  static const String keyDirectChats = 'direct_chats';
  static const String keyGroups = 'groups';
  static const String keyMergedUsers = 'merged_users';
  static const String keyContacts = 'contacts';
  static const String keyDashboardStats = 'dashboard_stats';
  static const String keyDashboardBranchwise = 'dashboard_branchwise';
  static const String keyNotifications = 'notifications';

  static String keyChatMessages(String chatId) => 'chat_messages_$chatId';

  static String keyDirectMessages(String receiverId, String propertyCode) =>
      'direct_messages_${receiverId}_$propertyCode';

  static String keyGroupMessages(String groupId) => 'group_messages_$groupId';

  static String keyGroupMembers(String groupId) => 'group_members_$groupId';

  static String keyBranchwise(String type, String period) =>
      'branchwise_${type}_$period';

  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> set(String key, dynamic data) async {
    try {
      final box = _getBox(key);

      await box.put('$_prefix$key', jsonEncode(data));

      await box.put('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print("Cache write error: $e");
    }
  }

  static Future<dynamic> get(String key, {int ttlMs = ttlNone}) async {
    try {
      final box = _getBox(key);
      final raw = box.get('$_prefix$key');

      if (raw == null) return null;

      if (ttlMs > 0) {
        final ts = box.get('$_tsPrefix$key');

        final age = DateTime.now().millisecondsSinceEpoch - ts;

        if (age > ttlMs) {
          return null;
        }
      }

      return jsonDecode(raw);
    } catch (e) {
      print("Cache read error: $e");
      return null;
    }
  }

  static Future<bool> has(String key, {int ttlMs = ttlNone}) async {
    return await get(key, ttlMs: ttlMs) != null;
  }

  static Future<void> delete(String key) async {
    final box = _getBox(key);

    await box.delete('$_prefix$key');
    await box.delete('$_tsPrefix$key');
  }

  static Future<void> clearAll() async {
    await Hive.box('chatBox').clear();
    await Hive.box('dashboardBox').clear();
    await Hive.box('challanBox').clear();
    await Hive.box('notificationBox').clear();
    await Hive.box('userBox').clear();
    await Hive.box('settingsBox').clear();
  }

  static Future<void> clearChatCache() async {
    await Hive.box('chatBox').clear();
  }

  // ── Typed helpers — List ──────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>?> getListMap(
    String key, {
    int ttlMs = ttlNone,
  }) async {
    final raw = await get(key, ttlMs: ttlMs);

    if (raw == null) return null;

    try {
      return List<Map<String, dynamic>>.from(
        (raw as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> setListMap(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    await set(key, data);
  }

  static Future<List<dynamic>?> getList(
    String key, {
    int ttlMs = ttlNone,
  }) async {
    final raw = await get(key, ttlMs: ttlMs);

    if (raw == null) return null;

    try {
      return List<dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setList(String key, List<dynamic> data) async {
    await set(key, data);
  }

  // ── Typed helpers — Map ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getMap(
    String key, {
    int ttlMs = ttlNone,
  }) async {
    final raw = await get(key, ttlMs: ttlMs);

    if (raw == null) return null;

    try {
      return Map<String, dynamic>.from(raw);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMap(String key, Map<String, dynamic> data) async {
    await set(key, data);
  }

  // ── Smart incremental chat update ─────────────────────────────────────────

  static Future<List<dynamic>> mergeNewMessages(
    String cacheKey,
    List<dynamic> freshMessages,
  ) async {
    final cached = await getList(cacheKey) ?? [];

    if (freshMessages.length <= cached.length) {
      return cached;
    }

    final merged = [...cached, ...freshMessages.skip(cached.length)];

    await setList(cacheKey, merged);

    return merged;
  }
}
