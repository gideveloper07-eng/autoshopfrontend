import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Stores future recurring task slots in SharedPreferences and creates them
/// via the API when their start date arrives.
///
/// Supports three task types:
///  - "individual" : ApiService.createIndividualTask  (direct chat)
///  - "group"      : ApiService.createTask            (group chat)
///  - "global"     : ApiService.createGlobalTask      (home assign-task card)
class RecurringTaskScheduler {
  static const _key = 'recurring_task_pending_slots';

  // ── Individual (direct-chat) ────────────────────────────────────────────────
  static Future<void> addIndividualPendingSlots({
    required String receiverId,
    required String receiverPropertyCode,
    required String taskTitle,
    required String taskDescription,
    required String priority,
    required List<(DateTime, DateTime)> futureSlots,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _load(prefs);
    for (final slot in futureSlots) {
      existing.add({
        'taskType': 'individual',
        'receiverId': receiverId,
        'receiverPropertyCode': receiverPropertyCode,
        'taskTitle': taskTitle,
        'taskDescription': taskDescription,
        'priority': priority,
        'startDate': slot.$1.toIso8601String(),
        'dueDate': slot.$2.toIso8601String(),
      });
    }
    await prefs.setString(_key, jsonEncode(existing));
  }

  // ── Group chat ──────────────────────────────────────────────────────────────
  static Future<void> addGroupPendingSlots({
    required String groupId,
    required String assignedTo,
    required String taskTitle,
    required String taskDescription,
    required String priority,
    required List<(DateTime, DateTime)> futureSlots,
    String? assignedToDatabase,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _load(prefs);
    for (final slot in futureSlots) {
      existing.add({
        'taskType': 'group',
        'groupId': groupId,
        'assignedTo': assignedTo,
        'assignedToDatabase': assignedToDatabase ?? '',
        'taskTitle': taskTitle,
        'taskDescription': taskDescription,
        'priority': priority,
        'startDate': slot.$1.toIso8601String(),
        'dueDate': slot.$2.toIso8601String(),
      });
    }
    await prefs.setString(_key, jsonEncode(existing));
  }

  // ── Global (home assign-task card) ──────────────────────────────────────────
  static Future<void> addGlobalPendingSlots({
    required String receiverId,
    required String taskTitle,
    required String taskDescription,
    required String priority,
    required List<(DateTime, DateTime)> futureSlots,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = _load(prefs);
    for (final slot in futureSlots) {
      existing.add({
        'taskType': 'global',
        'receiverId': receiverId,
        'taskTitle': taskTitle,
        'taskDescription': taskDescription,
        'priority': priority,
        'startDate': slot.$1.toIso8601String(),
        'dueDate': slot.$2.toIso8601String(),
      });
    }
    await prefs.setString(_key, jsonEncode(existing));
  }

  // ── Process due slots ───────────────────────────────────────────────────────
  /// Creates any stored tasks whose startDate has arrived. Returns count created.
  static Future<int> processDueSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final all = _load(prefs);
    if (all.isEmpty) return 0;

    final now = DateTime.now();
    final stillPending = <Map<String, dynamic>>[];
    int created = 0;

    for (final slot in all) {
      final startDate = DateTime.tryParse(slot['startDate'] as String? ?? '');
      if (startDate == null) continue; // malformed — drop it

      if (!startDate.isAfter(now)) {
        final type = slot['taskType'] as String? ?? 'individual';
        bool ok = false;

        if (type == 'group') {
          ok = await ApiService.createTask(
            groupId: slot['groupId'] as String,
            taskTitle: slot['taskTitle'] as String,
            taskDescription: slot['taskDescription'] as String,
            assignedTo: slot['assignedTo'] as String,
            priority: slot['priority'] as String,
            startDate: slot['startDate'] as String?,
            dueDate: slot['dueDate'] as String?,
            assignedToDatabase:
                (slot['assignedToDatabase'] as String?)?.isNotEmpty == true
                    ? slot['assignedToDatabase'] as String
                    : null,
          );
        } else if (type == 'global') {
          ok = await ApiService.createGlobalTask(
            receiverId: slot['receiverId'] as String,
            taskTitle: slot['taskTitle'] as String,
            taskDescription: slot['taskDescription'] as String,
            priority: slot['priority'] as String,
            startDate: slot['startDate'] as String?,
            dueDate: slot['dueDate'] as String?,
          );
        } else {
          // individual
          ok = await ApiService.createIndividualTask(
            receiverId: slot['receiverId'] as String,
            receiverPropertyCode: slot['receiverPropertyCode'] as String,
            taskTitle: slot['taskTitle'] as String,
            taskDescription: slot['taskDescription'] as String,
            priority: slot['priority'] as String,
            startDate: slot['startDate'] as String?,
            dueDate: slot['dueDate'] as String?,
          );
        }

        if (ok) {
          created++;
        } else {
          stillPending.add(slot); // retry next time
        }
      } else {
        stillPending.add(slot); // not due yet
      }
    }

    await prefs.setString(_key, jsonEncode(stillPending));
    return created;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _load(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(raw) as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return [];
    }
  }

  static Future<int> pendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    return _load(prefs).length;
  }
}
