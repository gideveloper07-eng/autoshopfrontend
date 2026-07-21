import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A simple cache service that stores API response data locally.
///
/// Strategy:
///   1. Screen opens → read cache → show UI immediately (if cache exists)
///   2. Fetch from backend in background
///   3. If data changed → update cache → refresh UI
///
/// TTL guide:
///   - Chat messages:   no expiry — always refresh in background but show cached
///   - Chat list:       no expiry — always refresh in background
///   - Notifications:   60 seconds hard TTL
///   - Dashboard:       5 minutes hard TTL
///   - Challan list:    2 minutes hard TTL
///   - Users/contacts:  10 minutes hard TTL
class CacheService {
  static SharedPreferences? _prefs;

  static const String _prefix = 'cache_';
  static const String _tsPrefix = 'cache_ts_';

  // ── TTL constants (milliseconds) ─────────────────────────────────────────
  /// No TTL — always return cached data and refresh in background
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

  /// Returns a cache key for chat messages of a specific chat ID
  static String keyChatMessages(String chatId) => 'chat_messages_$chatId';

  /// Returns a cache key for direct chat messages (receiverId + propertyCode)
  static String keyDirectMessages(String receiverId, String propertyCode) =>
      'direct_messages_${receiverId}_$propertyCode';

  /// Returns a cache key for group messages of a specific group
  static String keyGroupMessages(String groupId) => 'group_messages_$groupId';

  /// Returns a cache key for group members
  static String keyGroupMembers(String groupId) => 'group_members_$groupId';

  /// Returns a cache key for branchwise dashboard data
  static String keyBranchwise(String type, String period) =>
      'branchwise_${type}_$period';

  // ── Internals ─────────────────────────────────────────────────────────────

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Stores [data] under [key] with the current timestamp.
  static Future<void> set(String key, dynamic data) async {
    try {
      final prefs = await _getPrefs();
      final encoded = jsonEncode(data);
      await prefs.setString('$_prefix$key', encoded);
      await prefs.setInt('$_tsPrefix$key', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Never crash the app because of cache write failure
    }
  }

  /// Reads cached data for [key].
  ///
  /// Returns `null` if:
  ///   - Nothing is cached yet
  ///   - [ttlMs] > 0 and the entry has expired
  static Future<dynamic> get(String key, {int ttlMs = ttlNone}) async {
    try {
      final prefs = await _getPrefs();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;

      if (ttlMs > 0) {
        final ts = prefs.getInt('$_tsPrefix$key') ?? 0;
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age > ttlMs) return null; // expired
      }

      return jsonDecode(raw);
    } catch (e) {
      return null;
    }
  }

  /// Returns `true` if [key] has a valid non-expired cache entry.
  static Future<bool> has(String key, {int ttlMs = ttlNone}) async {
    final data = await get(key, ttlMs: ttlMs);
    return data != null;
  }

  /// Deletes cache entry for [key].
  static Future<void> delete(String key) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove('$_prefix$key');
      await prefs.remove('$_tsPrefix$key');
    } catch (e) {
      // Ignore
    }
  }

  /// Deletes all cache entries (e.g. on logout).
  static Future<void> clearAll() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys().where(
        (k) => k.startsWith(_prefix) || k.startsWith(_tsPrefix),
      ).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Deletes all chat-related cache entries (e.g. on switch-database).
  static Future<void> clearChatCache() async {
    try {
      final prefs = await _getPrefs();
      final keys = prefs.getKeys().where((k) =>
        k.startsWith('${_prefix}chat') ||
        k.startsWith('${_prefix}direct') ||
        k.startsWith('${_prefix}group') ||
        k.startsWith('${_tsPrefix}chat') ||
        k.startsWith('${_tsPrefix}direct') ||
        k.startsWith('${_tsPrefix}group'),
      ).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      // Ignore
    }
  }

  // ── Typed helpers — List ──────────────────────────────────────────────────

  /// Returns cached `List<Map<String,dynamic>>` or `null`.
  static Future<List<Map<String, dynamic>>?> getListMap(
    String key, {
    int ttlMs = ttlNone,
  }) async {
    final raw = await get(key, ttlMs: ttlMs);
    if (raw == null) return null;
    try {
      return List<Map<String, dynamic>>.from(
        (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves `List<Map<String,dynamic>>`.
  static Future<void> setListMap(
    String key,
    List<Map<String, dynamic>> data,
  ) => set(key, data);

  /// Returns cached `List<dynamic>` or `null`.
  static Future<List<dynamic>?> getList(
    String key, {
    int ttlMs = ttlNone,
  }) async {
    final raw = await get(key, ttlMs: ttlMs);
    if (raw == null) return null;
    try {
      return List<dynamic>.from(raw as List);
    } catch (_) {
      return null;
    }
  }

  /// Saves `List<dynamic>`.
  static Future<void> setList(String key, List<dynamic> data) =>
      set(key, data);

  // ── Typed helpers — Map ───────────────────────────────────────────────────

  /// Returns cached `Map<String,dynamic>` or `null`.
  static Future<Map<String, dynamic>?> getMap(
    String key, {
    int ttlMs = ttlNone,
  }) async {
    final raw = await get(key, ttlMs: ttlMs);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(raw as Map);
    } catch (_) {
      return null;
    }
  }

  /// Saves `Map<String,dynamic>`.
  static Future<void> setMap(String key, Map<String, dynamic> data) =>
      set(key, data);

  // ── Smart incremental chat update ─────────────────────────────────────────

  /// Appends only new messages to the cached list.
  ///
  /// New messages are those where their index is >= [cachedCount].
  /// This avoids re-writing the full list on every poll.
  static Future<List<dynamic>> mergeNewMessages(
    String cacheKey,
    List<dynamic> freshMessages,
  ) async {
    final cached = await getList(cacheKey) ?? [];
    if (freshMessages.length <= cached.length) {
      // Nothing new — return what we have cached
      return cached;
    }
    // Append only the new tail
    final merged = [...cached, ...freshMessages.skip(cached.length)];
    await setList(cacheKey, merged);
    return merged;
  }
}
