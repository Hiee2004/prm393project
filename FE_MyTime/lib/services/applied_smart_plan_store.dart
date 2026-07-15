import 'dart:convert';

import 'package:project/models/focus_task.dart';
import 'package:project/models/smart_task_plan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppliedSmartPlanStore {
  AppliedSmartPlanStore._();

  static final AppliedSmartPlanStore instance = AppliedSmartPlanStore._();

  static const _keyPrefix = 'applied_smart_plan_task_';
  static const _snapshotKeyPrefix = 'applied_smart_plan_snapshot_task_';

  Future<void> savePlan({
    required String taskId,
    required SmartTaskPlan plan,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_keyPrefix$taskId',
      jsonEncode(plan.toJson()),
    );
  }

  Future<SmartTaskPlan?> getPlan(String taskId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_keyPrefix$taskId');
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return SmartTaskPlan.fromJson(decoded);
  }

  Future<Map<String, SmartTaskPlan>> getPlansForTasks(
    Iterable<String> taskIds,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final plans = <String, SmartTaskPlan>{};

    for (final taskId in taskIds) {
      final raw = preferences.getString('$_keyPrefix$taskId');
      if (raw == null || raw.trim().isEmpty) continue;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) continue;
      plans[taskId] = SmartTaskPlan.fromJson(decoded);
    }

    return plans;
  }

  Future<void> clearPlan(String taskId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_keyPrefix$taskId');
  }

  Future<void> saveOriginalTask({
    required String taskId,
    required FocusTask task,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey('$_snapshotKeyPrefix$taskId')) {
      return;
    }
    await preferences.setString(
      '$_snapshotKeyPrefix$taskId',
      jsonEncode(task.toSnapshotJson()),
    );
  }

  Future<FocusTask?> getOriginalTask(String taskId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_snapshotKeyPrefix$taskId');
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return FocusTask.fromJson(decoded);
  }

  Future<void> clearOriginalTask(String taskId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_snapshotKeyPrefix$taskId');
  }
}
