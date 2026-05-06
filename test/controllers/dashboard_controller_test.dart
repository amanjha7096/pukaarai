import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/modules/dashboard/controllers/dashboard_controller.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

ActivityModel _act({
  required String type,
  required double value,
  String id = '',
  DateTime? createdAt,
  String? note,
}) =>
    ActivityModel(
      id: id.isEmpty ? '${type}_${value.toInt()}' : id,
      type: type,
      value: value,
      note: note,
      createdAt: createdAt ?? DateTime.now(),
    );

void main() {
  late DashboardController ctrl;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 10);

  setUp(() {
    Get.testMode = true;
    // Created without Get.put() → onInit() not called → no Firestore calls.
    ctrl = DashboardController();
    ctrl.selectedPeriod.value = 'today';
  });

  tearDown(Get.reset);

  void seed(List<ActivityModel> items) =>
      ctrl.activities.assignAll(items);

  // ── Computed sums ─────────────────────────────────────────────────────────

  group('waterMl / caloriesKcal', () {
    test('waterMl sums all water entries', () {
      seed([
        _act(type: 'water', value: 300),
        _act(type: 'water', value: 700),
        _act(type: 'steps', value: 5000), // ignored
      ]);
      expect(ctrl.waterMl, 1000);
    });

    test('caloriesKcal sums all calorie entries', () {
      seed([
        _act(type: 'calories', value: 350),
        _act(type: 'calories', value: 150),
      ]);
      expect(ctrl.caloriesKcal, 500);
    });

    test('returns 0 when no matching entries', () {
      seed([_act(type: 'steps', value: 3000)]);
      expect(ctrl.waterMl, 0);
      expect(ctrl.caloriesKcal, 0);
    });
  });

  // ── sleepValue ────────────────────────────────────────────────────────────

  group('sleepValue', () {
    test('returns sum when period is today', () {
      ctrl.selectedPeriod.value = 'today';
      seed([
        _act(type: 'sleep', value: 4),
        _act(type: 'sleep', value: 3),
      ]);
      expect(ctrl.sleepValue, 7);
    });

    test('returns average when period is week', () {
      ctrl.selectedPeriod.value = 'week';
      seed([
        _act(type: 'sleep', value: 8),
        _act(type: 'sleep', value: 6),
      ]);
      expect(ctrl.sleepValue, 7); // (8+6)/2
    });

    test('returns 0 when no sleep entries', () {
      expect(ctrl.sleepValue, 0);
    });
  });

  // ── heartBpm ──────────────────────────────────────────────────────────────

  group('heartBpm', () {
    test('today: returns the most recent reading', () {
      ctrl.selectedPeriod.value = 'today';
      seed([
        _act(type: 'heart', value: 65,
            createdAt: today.subtract(const Duration(hours: 2))),
        _act(type: 'heart', value: 80,
            createdAt: today),                            // most recent
        _act(type: 'heart', value: 70,
            createdAt: today.subtract(const Duration(hours: 1))),
      ]);
      expect(ctrl.heartBpm, 80);
    });

    test('week: returns average of all readings', () {
      ctrl.selectedPeriod.value = 'week';
      seed([
        _act(type: 'heart', value: 70),
        _act(type: 'heart', value: 80),
        _act(type: 'heart', value: 90),
      ]);
      expect(ctrl.heartBpm, 80); // (70+80+90)/3
    });

    test('returns 0 when no heart entries', () {
      expect(ctrl.heartBpm, 0);
    });
  });

  // ── Progress ratios ───────────────────────────────────────────────────────

  group('progress getters', () {
    test('waterProgress = 0 when no water', () {
      expect(ctrl.waterProgress, 0);
    });

    test('waterProgress = 1.0 when water equals goal', () {
      seed([_act(type: 'water', value: AppGoals.water)]);
      expect(ctrl.waterProgress, 1.0);
    });

    test('waterProgress clamps at 1.0 when over goal', () {
      seed([_act(type: 'water', value: AppGoals.water * 2)]);
      expect(ctrl.waterProgress, 1.0);
    });

    test('caloriesProgress is proportional to AppGoals.calories', () {
      seed([_act(type: 'calories', value: AppGoals.calories / 2)]);
      expect(ctrl.caloriesProgress, closeTo(0.5, 0.001));
    });

    test('sleepProgress clamps at 1.0 when over goal', () {
      seed([_act(type: 'sleep', value: AppGoals.sleep * 3)]);
      expect(ctrl.sleepProgress, 1.0);
    });
  });

  // ── isToday / daysElapsed ─────────────────────────────────────────────────

  group('isToday / daysElapsed', () {
    test('isToday is true for "today" period', () {
      ctrl.selectedPeriod.value = 'today';
      expect(ctrl.isToday, isTrue);
    });

    test('isToday is false for "week" period', () {
      ctrl.selectedPeriod.value = 'week';
      expect(ctrl.isToday, isFalse);
    });

    test('daysElapsed is 1 for today', () {
      ctrl.selectedPeriod.value = 'today';
      expect(ctrl.daysElapsed, 1);
    });

    test('daysElapsed is 7 for week', () {
      ctrl.selectedPeriod.value = 'week';
      expect(ctrl.daysElapsed, 7);
    });

    test('daysElapsed is current day-of-month for month', () {
      ctrl.selectedPeriod.value = 'month';
      expect(ctrl.daysElapsed, DateTime.now().day);
    });
  });

  // ── stepsCenterLabel ──────────────────────────────────────────────────────

  group('stepsCenterLabel (_tracking is null)', () {
    test('formats steps below 1000 as integer string', () {
      seed([_act(type: 'steps', value: 800)]);
      expect(ctrl.stepsCenterLabel, '800');
    });

    test('formats 1000+ steps with "k" suffix', () {
      seed([_act(type: 'steps', value: 5500)]);
      expect(ctrl.stepsCenterLabel, '5.5k');
    });

    test('stepsCenterUnit is "steps" when today', () {
      ctrl.selectedPeriod.value = 'today';
      expect(ctrl.stepsCenterUnit, 'steps');
    });

    test('stepsCenterUnit is "avg/day" when week', () {
      ctrl.selectedPeriod.value = 'week';
      expect(ctrl.stepsCenterUnit, 'avg/day');
    });
  });

  // ── waterChartBuckets ─────────────────────────────────────────────────────

  group('waterChartBuckets', () {
    test('today: returns 8 hourly buckets', () {
      ctrl.selectedPeriod.value = 'today';
      expect(ctrl.waterChartBuckets.length, 8);
    });

    test('week: returns 7 daily buckets', () {
      ctrl.selectedPeriod.value = 'week';
      expect(ctrl.waterChartBuckets.length, 7);
    });

    test('month: returns 5 weekly buckets', () {
      ctrl.selectedPeriod.value = 'month';
      expect(ctrl.waterChartBuckets.length, 5);
    });

    test('today: water logged within last 8 hours appears in the last bucket', () {
      ctrl.selectedPeriod.value = 'today';
      final justNow = DateTime.now();
      seed([_act(type: 'water', value: 500, createdAt: justNow)]);
      final buckets = ctrl.waterChartBuckets;
      // Last bucket (index 7) = current hour; value is in litres
      expect(buckets.last, closeTo(0.5, 0.01));
    });

    test('today: all buckets are 0 when no water logged', () {
      ctrl.selectedPeriod.value = 'today';
      seed([_act(type: 'steps', value: 5000, createdAt: today)]);
      expect(ctrl.waterChartBuckets.every((v) => v == 0), isTrue);
    });

    test('week: water logged today appears in last daily bucket', () {
      ctrl.selectedPeriod.value = 'week';
      seed([_act(type: 'water', value: 2000, createdAt: today)]);
      final buckets = ctrl.waterChartBuckets; // in litres
      expect(buckets.last, closeTo(2.0, 0.01));
    });
  });

  // ── heartRatePoints ───────────────────────────────────────────────────────

  group('heartRatePoints', () {
    test('returns static placeholder when no heart entries', () {
      final pts = ctrl.heartRatePoints;
      expect(pts, isNotEmpty);
      expect(pts, [68, 72, 70, 76, 74, 73, 75, 71]);
    });

    test('returns actual values sorted chronologically', () {
      seed([
        _act(type: 'heart', value: 80,
            createdAt: today.subtract(const Duration(hours: 2))),
        _act(type: 'heart', value: 70, createdAt: today),
      ]);
      final pts = ctrl.heartRatePoints;
      expect(pts, [80, 70]); // chronological order
    });
  });
}
