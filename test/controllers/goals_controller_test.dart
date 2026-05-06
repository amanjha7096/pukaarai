import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tracking/modules/goals/controllers/goals_controller.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _dk(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  late GoalsController ctrl;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  String daysAgo(int n) => _dk(DateTime(now.year, now.month, now.day - n));

  late Directory _tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _tempDir = await Directory.systemTemp.createTemp('gs_goals_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => _tempDir.path,
    );
    await GetStorage.init();
  });

  tearDownAll(() async {
    try { await _tempDir.delete(recursive: true); } catch (_) {}
  });

  setUp(() {
    Get.testMode = true;
    GetStorage().erase();
    // Create controller without Get.put() — onInit() is not called, so no
    // Firestore calls are triggered. We set stepsByDate / waterByDate manually.
    ctrl = GoalsController();
    ctrl.stepsGoal.value = 10000;
    ctrl.waterGoal.value = 3000;
  });

  tearDown(Get.reset);

  // ── Steps streak ──────────────────────────────────────────────────────────

  group('stepsStreak', () {
    test('is 0 when stepsByDate is empty', () {
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 0);
    });

    test('counts consecutive days from today backwards', () {
      ctrl.stepsByDate.assignAll({
        _dk(today): 9000.0,              // 90% of 10000 ≥ 80% ✓
        daysAgo(1): 8500.0,              // 85% ✓
        daysAgo(2): 8000.0,              // 80% exactly ✓
        // day 3 missing → streak breaks
      });
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 3);
    });

    test('breaks immediately when today is below threshold', () {
      ctrl.stepsByDate.assignAll({
        _dk(today): 7000.0,  // 70% — below 80% threshold
        daysAgo(1): 10000.0,
        daysAgo(2): 10000.0,
      });
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 0);
    });

    test('streak is 1 when only today meets threshold', () {
      ctrl.stepsByDate.assignAll({
        _dk(today): 9000.0,  // ✓
        daysAgo(1): 5000.0,  // ✗
      });
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 1);
    });

    test('80% boundary: exactly 8000 of 10000 counts', () {
      ctrl.stepsByDate.assignAll({_dk(today): 8000.0});
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 1);
    });

    test('79.9% does not count (below 80% threshold)', () {
      ctrl.stepsByDate.assignAll({_dk(today): 7999.0});
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 0);
    });

    test('streak adjusts when goal changes', () {
      ctrl.stepsByDate.assignAll({
        _dk(today): 5000.0,
        daysAgo(1): 5000.0,
      });
      // At goal=10000, 5000 = 50% → no streak
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsStreak.value, 0);

      // At goal=6000, 5000 = 83% → 2-day streak
      ctrl.setStepsGoal(6000);
      expect(ctrl.stepsStreak.value, 2);
    });
  });

  // ── Steps longest streak ──────────────────────────────────────────────────

  group('stepsLongestStreak', () {
    test('is 0 when no data', () {
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsLongestStreak.value, 0);
    });

    test('finds the longest run in a broken sequence', () {
      // days: 29..0 (oldest→today)
      // indices: 29 days ago → today
      // 3-day run at days 5-3, 2-day run at days 1-0
      ctrl.stepsByDate.assignAll({
        daysAgo(5): 9000.0,
        daysAgo(4): 9000.0,
        daysAgo(3): 9000.0,
        // gap at daysAgo(2)
        daysAgo(1): 9000.0,
        _dk(today): 9000.0,
      });
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsLongestStreak.value, 3);
    });

    test('equals stepsStreak when best run includes today', () {
      ctrl.stepsByDate.assignAll({
        _dk(today): 9000.0,
        daysAgo(1): 9000.0,
        daysAgo(2): 9000.0,
      });
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsLongestStreak.value, ctrl.stepsStreak.value);
    });
  });

  // ── Steps week days ───────────────────────────────────────────────────────

  group('stepsWeekDays', () {
    test('is 0 when no data', () {
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsWeekDays.value, 0);
    });

    test('counts only the last 7 days', () {
      ctrl.stepsByDate.assignAll({
        _dk(today): 9000.0,
        daysAgo(1): 9000.0,
        daysAgo(6): 9000.0,   // still within 7-day window
        daysAgo(7): 9000.0,   // just outside 7-day window
        daysAgo(20): 9000.0,  // far outside
      });
      ctrl.setStepsGoal(10000);
      expect(ctrl.stepsWeekDays.value, 3); // today, 1 ago, 6 ago
    });
  });

  // ── Water streak ─────────────────────────────────────────────────────────

  group('waterStreak', () {
    test('is 0 when waterByDate is empty', () {
      ctrl.setWaterGoal(3000);
      expect(ctrl.waterStreak.value, 0);
    });

    test('counts consecutive days meeting 80% water goal', () {
      ctrl.waterByDate.assignAll({
        _dk(today): 2500.0,   // 83% of 3000 ✓
        daysAgo(1): 2400.0,   // 80% ✓
        daysAgo(2): 2399.0,   // 79.9% ✗ → streak breaks
      });
      ctrl.setWaterGoal(3000);
      expect(ctrl.waterStreak.value, 2);
    });

    test('waterLongestStreak tracks best run', () {
      ctrl.waterByDate.assignAll({
        daysAgo(10): 3000.0,
        daysAgo(9): 3000.0,
        daysAgo(8): 3000.0,
        daysAgo(7): 3000.0,  // 4-day run
        // gap
        _dk(today): 3000.0,
        daysAgo(1): 3000.0,  // 2-day run
      });
      ctrl.setWaterGoal(3000);
      expect(ctrl.waterLongestStreak.value, 4);
    });
  });

  // ── setStepsGoal / setWaterGoal ───────────────────────────────────────────

  group('setStepsGoal', () {
    test('updates stepsGoal observable', () {
      ctrl.setStepsGoal(8000);
      expect(ctrl.stepsGoal.value, 8000);
    });

    test('persists to GetStorage', () {
      ctrl.setStepsGoal(7500);
      expect(GetStorage().read<double>('custom_steps_goal'), 7500);
    });

    test('rejects goal of 0', () {
      ctrl.setStepsGoal(0);
      expect(ctrl.stepsGoal.value, 10000); // unchanged
    });

    test('rejects negative goal', () {
      ctrl.setStepsGoal(-100);
      expect(ctrl.stepsGoal.value, 10000); // unchanged
    });
  });

  group('setWaterGoal', () {
    test('updates waterGoal observable', () {
      ctrl.setWaterGoal(2500);
      expect(ctrl.waterGoal.value, 2500);
    });

    test('persists to GetStorage', () {
      ctrl.setWaterGoal(2500);
      expect(GetStorage().read<double>('custom_water_goal'), 2500);
    });

    test('rejects goal of 0', () {
      ctrl.setWaterGoal(0);
      expect(ctrl.waterGoal.value, 3000); // unchanged
    });
  });
}
