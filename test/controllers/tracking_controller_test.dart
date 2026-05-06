import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tracking/modules/tracking/controllers/tracking_controller.dart';

import '../helpers/fake_repository.dart';

void main() {
  late FakeActivityRepository repo;
  late TrackingController ctrl;

  late Directory _tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _tempDir = await Directory.systemTemp.createTemp('gs_tracking_');
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
    repo = FakeActivityRepository();
    // Creating without Get.put() → onInit() is NOT called.
    // No pedometer subscription is started; Firestore is never touched.
    ctrl = TrackingController(repo: repo);
  });

  tearDown(Get.reset);

  // ── addStepsManually ──────────────────────────────────────────────────────

  group('addStepsManually', () {
    test('increases liveSteps by the given amount', () async {
      await ctrl.addStepsManually(500);
      expect(ctrl.liveSteps.value, 500);
    });

    test('accumulates across multiple calls', () async {
      await ctrl.addStepsManually(500);
      await ctrl.addStepsManually(300);
      expect(ctrl.liveSteps.value, 800);
    });

    test('rejects 0 — liveSteps unchanged', () async {
      await ctrl.addStepsManually(0);
      expect(ctrl.liveSteps.value, 0);
    });

    test('rejects negative value — liveSteps unchanged', () async {
      await ctrl.addStepsManually(-100);
      expect(ctrl.liveSteps.value, 0);
    });

    test('calls upsertTodaySteps with the new total', () async {
      await ctrl.addStepsManually(1000);
      expect(repo.upsertedSteps, contains(1000.0));
    });

    test('persists manual steps to GetStorage', () async {
      await ctrl.addStepsManually(600);
      // The manualKey format: 'manual_steps_YYYY-MM-DD'
      final n = DateTime.now();
      final key = 'manual_steps_${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      expect(GetStorage().read<int>(key), 600);
    });

    test('isLoading is false after completion', () async {
      await ctrl.addStepsManually(200);
      expect(ctrl.isLoading.value, isFalse);
    });
  });

  // ── saveSteps ─────────────────────────────────────────────────────────────

  group('saveSteps', () {
    test('does not call repo when liveSteps is 0', () async {
      await ctrl.saveSteps();
      expect(repo.upsertedSteps, isEmpty);
    });

    test('calls upsertTodaySteps when liveSteps > 0', () async {
      ctrl.liveSteps.value = 3000;
      await ctrl.saveSteps();
      expect(repo.upsertedSteps, contains(3000.0));
    });

    test('isLoading is false after save completes', () async {
      ctrl.liveSteps.value = 1000;
      await ctrl.saveSteps();
      expect(ctrl.isLoading.value, isFalse);
    });
  });

  // ── addWater / addCalories / addSleep / addHeartRate ─────────────────────

  group('activity logging', () {
    test('addWater calls repo.addActivity with type "water"', () async {
      await ctrl.addWater(250);
      expect(repo.addedActivities.any((a) => a['type'] == 'water'), isTrue);
      expect(repo.addedActivities.first['value'], 250.0);
    });

    test('addCalories calls repo.addActivity with type "calories"', () async {
      await ctrl.addCalories(350, note: 'lunch');
      final entry = repo.addedActivities.first;
      expect(entry['type'], 'calories');
      expect(entry['value'], 350.0);
      expect(entry['note'], 'lunch');
    });

    test('addSleep calls repo.addActivity with type "sleep"', () async {
      await ctrl.addSleep(7.5);
      expect(repo.addedActivities.first['type'], 'sleep');
    });

    test('addHeartRate calls repo.addActivity with type "heart"', () async {
      await ctrl.addHeartRate(72);
      expect(repo.addedActivities.first['type'], 'heart');
      expect(repo.addedActivities.first['value'], 72.0);
    });
  });

  // ── Sleep session ─────────────────────────────────────────────────────────

  group('sleep session', () {
    test('isSleeping is false by default', () {
      expect(ctrl.isSleeping, isFalse);
    });

    test('startSleep sets isSleeping to true', () async {
      await ctrl.startSleep();
      expect(ctrl.isSleeping, isTrue);
    });

    test('startSleep persists start time to GetStorage', () async {
      await ctrl.startSleep();
      expect(GetStorage().read<String>('sleep_start'), isNotNull);
    });

    test('startSleep sets sleepStartTime near now', () async {
      final before = DateTime.now();
      await ctrl.startSleep();
      final after = DateTime.now();
      final start = ctrl.sleepStartTime.value!;
      expect(start.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(start.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('wakeUp does nothing when no sleep session is active', () async {
      // Should not throw; isSleeping remains false
      await ctrl.wakeUp();
      expect(ctrl.isSleeping, isFalse);
    });

    test('wakeUp rejects sessions shorter than 5 minutes', () async {
      await ctrl.startSleep();
      // The session just started (< 5 min) → wakeUp should reject it
      await ctrl.wakeUp();
      // Sleep session should still be active because it was too short
      expect(ctrl.isSleeping, isTrue);
    });

    test('wakeUp ends a valid session and calls addSleep', () async {
      // Simulate a session that started 8 hours ago
      final eightHoursAgo = DateTime.now().subtract(const Duration(hours: 8));
      GetStorage().write('sleep_start', eightHoursAgo.toIso8601String());
      ctrl.sleepStartTime.value = eightHoursAgo;

      await ctrl.wakeUp();

      expect(ctrl.isSleeping, isFalse);
      expect(repo.addedActivities.any((a) => a['type'] == 'sleep'), isTrue);
    });
  });

  // ── onClose flush ─────────────────────────────────────────────────────────

  group('onClose', () {
    test('fires upsertTodaySteps with current liveSteps', () {
      ctrl.liveSteps.value = 4500;
      ctrl.onClose();
      expect(repo.upsertedSteps, contains(4500.0));
    });

    test('does not call upsertTodaySteps when liveSteps is 0', () {
      ctrl.liveSteps.value = 0;
      ctrl.onClose();
      expect(repo.upsertedSteps, isEmpty);
    });

    test('persists prevSessionSteps to GetStorage', () {
      ctrl.liveSteps.value = 2000;
      ctrl.onClose();
      final n = DateTime.now();
      final key = 'prev_steps_${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
      expect(GetStorage().read<int>(key), 2000);
    });
  });
}
