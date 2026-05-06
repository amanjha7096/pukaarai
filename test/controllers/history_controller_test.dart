import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/modules/history/controllers/history_controller.dart';

import '../helpers/fake_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ActivityModel _act({
  required String id,
  required String type,
  required double value,
  required DateTime createdAt,
  String? note,
}) =>
    ActivityModel(
        id: id, type: type, value: value, createdAt: createdAt, note: note);

String _dk(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  late FakeActivityRepository repo;
  late HistoryController ctrl;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 10);
  final yesterday = DateTime(now.year, now.month, now.day - 1, 10);
  final twoDaysAgo = DateTime(now.year, now.month, now.day - 2, 10);
  final sixDaysAgo = DateTime(now.year, now.month, now.day - 6, 10);
  final eightDaysAgo = DateTime(now.year, now.month, now.day - 8, 10);

  setUp(() {
    Get.testMode = true;
    repo = FakeActivityRepository();
    ctrl = HistoryController(repo: repo);
    // onInit() is not called — populate allActivities manually in tests
  });

  tearDown(Get.reset);

  void seed(List<ActivityModel> items) =>
      ctrl.allActivities.assignAll(items);

  // ── Filter ────────────────────────────────────────────────────────────────

  group('setFilter / filtered', () {
    setUp(() => seed([
          _act(id: '1', type: 'steps', value: 5000, createdAt: today),
          _act(id: '2', type: 'water', value: 300, createdAt: today),
          _act(id: '3', type: 'steps', value: 3000, createdAt: yesterday),
        ]));

    test('default filter is "all"', () {
      expect(ctrl.selectedFilter.value, 'all');
      expect(ctrl.filtered.length, 3);
    });

    test('filter "steps" returns only steps entries', () {
      ctrl.setFilter('steps');
      final result = ctrl.filtered;
      expect(result.every((a) => a.type == 'steps'), isTrue);
      expect(result.length, 2);
    });

    test('filter "water" returns only water entry', () {
      ctrl.setFilter('water');
      expect(ctrl.filtered.length, 1);
      expect(ctrl.filtered.first.id, '2');
    });

    test('filter with no matches returns empty list', () {
      ctrl.setFilter('sleep');
      expect(ctrl.filtered, isEmpty);
    });

    test('resetting to "all" restores full list', () {
      ctrl.setFilter('steps');
      ctrl.setFilter('all');
      expect(ctrl.filtered.length, 3);
    });
  });

  // ── groupedByDate ─────────────────────────────────────────────────────────

  group('groupedByDate', () {
    test('groups activities under the correct date key', () {
      seed([
        _act(id: '1', type: 'steps', value: 5000, createdAt: today),
        _act(id: '2', type: 'water', value: 300, createdAt: today),
        _act(id: '3', type: 'steps', value: 3000, createdAt: yesterday),
      ]);
      final grouped = ctrl.groupedByDate;
      expect(grouped.length, 2);
      expect(grouped[_dk(today)]?.length, 2);
      expect(grouped[_dk(yesterday)]?.length, 1);
    });

    test('respects active filter when grouping', () {
      seed([
        _act(id: '1', type: 'steps', value: 5000, createdAt: today),
        _act(id: '2', type: 'water', value: 300, createdAt: today),
      ]);
      ctrl.setFilter('steps');
      final grouped = ctrl.groupedByDate;
      expect(grouped[_dk(today)]?.length, 1);
    });

    test('returns empty map when no activities', () {
      expect(ctrl.groupedByDate, isEmpty);
    });
  });

  // ── deleteActivity ────────────────────────────────────────────────────────

  group('deleteActivity', () {
    test('removes the entry from allActivities', () async {
      seed([
        _act(id: 'del1', type: 'water', value: 100, createdAt: today),
        _act(id: 'del2', type: 'sleep', value: 7, createdAt: today),
      ]);
      await ctrl.deleteActivity('del1');
      expect(ctrl.allActivities.any((a) => a.id == 'del1'), isFalse);
      expect(ctrl.allActivities.length, 1);
    });

    test('calls repo.deleteActivity with correct id', () async {
      seed([_act(id: 'x1', type: 'heart', value: 80, createdAt: today)]);
      await ctrl.deleteActivity('x1');
      expect(repo.deletedIds, contains('x1'));
    });

    test('does not remove entry when repo throws', () async {
      repo.throwOnDelete = true;
      seed([_act(id: 'y1', type: 'water', value: 100, createdAt: today)]);
      await ctrl.deleteActivity('y1');
      expect(ctrl.allActivities.length, 1); // still there
    });
  });

  // ── loadHistory ───────────────────────────────────────────────────────────

  group('loadHistory', () {
    test('populates allActivities from repo', () async {
      repo.allActivities = [
        _act(id: 'r1', type: 'sleep', value: 8, createdAt: today),
        _act(id: 'r2', type: 'water', value: 500, createdAt: today),
      ];
      await ctrl.loadHistory();
      expect(ctrl.allActivities.length, 2);
    });

    test('isLoading is false after successful load', () async {
      await ctrl.loadHistory();
      expect(ctrl.isLoading.value, isFalse);
    });

    test('isLoading is false even after repo error', () async {
      repo.throwOnFetch = true;
      try { await ctrl.loadHistory(); } catch (_) {}
      expect(ctrl.isLoading.value, isFalse);
    });
  });

  // ── Chart data ────────────────────────────────────────────────────────────

  group('chart data — last 7 days', () {
    test('stepsLast7 always returns 7 values', () {
      expect(ctrl.stepsLast7.length, 7);
    });

    test('waterLast7 always returns 7 values', () {
      expect(ctrl.waterLast7.length, 7);
    });

    test('all zeros when no matching activities', () {
      seed([_act(id: '1', type: 'steps', value: 5000, createdAt: today)]);
      expect(ctrl.waterLast7.every((v) => v == 0), isTrue);
    });

    test('stepsLast7 uses MAX per day (not sum)', () {
      seed([
        _act(id: '1', type: 'steps', value: 3000, createdAt: today),
        _act(id: '2', type: 'steps', value: 8000, createdAt: today),
      ]);
      expect(ctrl.stepsLast7.last, 8000);
    });

    test('waterLast7 SUMs values for the same day', () {
      seed([
        _act(id: '1', type: 'water', value: 300, createdAt: today),
        _act(id: '2', type: 'water', value: 700, createdAt: today),
      ]);
      expect(ctrl.waterLast7.last, 1000);
    });

    test('caloriesLast7 sums values for the same day', () {
      seed([
        _act(id: '1', type: 'calories', value: 500, createdAt: today),
        _act(id: '2', type: 'calories', value: 300, createdAt: today),
      ]);
      expect(ctrl.caloriesLast7.last, 800);
    });

    test('today maps to index 6 (last element)', () {
      seed([_act(id: '1', type: 'water', value: 2000, createdAt: today)]);
      expect(ctrl.waterLast7[6], 2000);
    });

    test('yesterday maps to index 5', () {
      seed([_act(id: '1', type: 'water', value: 1500, createdAt: yesterday)]);
      expect(ctrl.waterLast7[5], 1500);
    });

    test('6 days ago maps to index 0', () {
      seed([_act(id: '1', type: 'sleep', value: 7.5, createdAt: sixDaysAgo)]);
      expect(ctrl.sleepLast7.first, 7.5);
    });

    test('data older than 7 days does not appear', () {
      seed([_act(id: '1', type: 'water', value: 3000, createdAt: eightDaysAgo)]);
      expect(ctrl.waterLast7.every((v) => v == 0), isTrue);
    });

    test('data from multiple days is placed correctly', () {
      seed([
        _act(id: '1', type: 'calories', value: 1800, createdAt: today),
        _act(id: '2', type: 'calories', value: 2100, createdAt: twoDaysAgo),
      ]);
      final cal = ctrl.caloriesLast7;
      expect(cal[6], 1800);   // today
      expect(cal[4], 2100);   // 2 days ago
      expect(cal[5], 0);      // yesterday — no data
    });
  });
}
