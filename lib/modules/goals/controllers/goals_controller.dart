import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/data/repositories/activity_repository.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';
import 'package:tracking/modules/tracking/controllers/tracking_controller.dart';

class GoalsController extends GetxController {
  static const _stepsGoalKey = 'custom_steps_goal';
  static const _waterGoalKey = 'custom_water_goal';

  final _repo = ActivityRepository();
  final _storage = GetStorage();

  final isLoading = false.obs;

  // Configurable goals (persisted in GetStorage)
  final stepsGoal = AppGoals.steps.obs;
  final waterGoal = AppGoals.water.obs;

  // Streaks
  final stepsStreak = 0.obs;
  final waterStreak = 0.obs;
  final stepsLongestStreak = 0.obs;
  final waterLongestStreak = 0.obs;

  // This-week consistency (0–7)
  final stepsWeekDays = 0.obs;
  final waterWeekDays = 0.obs;

  // Last 28 days of data for heatmap (dateKey → value)
  final stepsByDate = <String, double>{}.obs;
  final waterByDate = <String, double>{}.obs;

  TrackingController? _tracking;

  @override
  void onInit() {
    super.onInit();
    stepsGoal.value = _storage.read<double>(_stepsGoalKey) ?? AppGoals.steps;
    waterGoal.value = _storage.read<double>(_waterGoalKey) ?? AppGoals.water;
    loadData();
  }

  @override
  void onReady() {
    super.onReady();
    // Refresh data whenever Goals tab becomes active (index 1)
    ever(Get.find<MainNavController>().currentIndex, (int i) {
      if (i == 1) loadData();
    });
    try {
      _tracking = Get.find<TrackingController>();
    } catch (_) {}
  }

  void setStepsGoal(double goal) {
    if (goal <= 0) return;
    stepsGoal.value = goal;
    _storage.write(_stepsGoalKey, goal);
    _computeStreaks();
  }

  void setWaterGoal(double goal) {
    if (goal <= 0) return;
    waterGoal.value = goal;
    _storage.write(_waterGoalKey, goal);
    _computeStreaks();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 29);
      final end = DateTime(now.year, now.month, now.day + 1);
      final activities = await _repo.fetchActivitiesForRange(start, end);

      final sByDate = <String, double>{};
      final wByDate = <String, double>{};

      for (final a in activities) {
        final key = _dateKey(a.createdAt);
        if (a.type == 'steps') {
          // upsert pattern: take max per day
          if ((sByDate[key] ?? 0) < a.value) sByDate[key] = a.value;
        } else if (a.type == 'water') {
          wByDate[key] = (wByDate[key] ?? 0) + a.value;
        }
      }

      // Override today's steps with live pedometer reading
      if (_tracking != null) {
        final live = _tracking!.liveSteps.value.toDouble();
        if (live > 0) sByDate[_dateKey(now)] = live;
      }

      stepsByDate.assignAll(sByDate);
      waterByDate.assignAll(wByDate);
      _computeStreaks();
    } finally {
      isLoading.value = false;
    }
  }

  void _computeStreaks() {
    final now = DateTime.now();

    // ── Steps ──────────────────────────────────────────────────────────────
    int sStreak = 0;
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if ((stepsByDate[_dateKey(day)] ?? 0) >= stepsGoal.value * 0.8) {
        sStreak++;
      } else {
        break;
      }
    }

    int sLongest = 0, sTmp = 0;
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      if ((stepsByDate[_dateKey(day)] ?? 0) >= stepsGoal.value * 0.8) {
        sTmp++;
        if (sTmp > sLongest) sLongest = sTmp;
      } else {
        sTmp = 0;
      }
    }

    int sWeek = 0;
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if ((stepsByDate[_dateKey(day)] ?? 0) >= stepsGoal.value * 0.8) sWeek++;
    }

    stepsStreak.value = sStreak;
    stepsLongestStreak.value = sLongest;
    stepsWeekDays.value = sWeek;

    // ── Water ──────────────────────────────────────────────────────────────
    int wStreak = 0;
    for (int i = 0; i < 30; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if ((waterByDate[_dateKey(day)] ?? 0) >= waterGoal.value * 0.8) {
        wStreak++;
      } else {
        break;
      }
    }

    int wLongest = 0, wTmp = 0;
    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      if ((waterByDate[_dateKey(day)] ?? 0) >= waterGoal.value * 0.8) {
        wTmp++;
        if (wTmp > wLongest) wLongest = wTmp;
      } else {
        wTmp = 0;
      }
    }

    int wWeek = 0;
    for (int i = 0; i < 7; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if ((waterByDate[_dateKey(day)] ?? 0) >= waterGoal.value * 0.8) wWeek++;
    }

    waterStreak.value = wStreak;
    waterLongestStreak.value = wLongest;
    waterWeekDays.value = wWeek;
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
