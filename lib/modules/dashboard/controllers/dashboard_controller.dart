import 'package:get/get.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/data/repositories/activity_repository.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';
import 'package:tracking/modules/tracking/controllers/tracking_controller.dart';

class DashboardController extends GetxController {
  final _repo = ActivityRepository();

  final isLoading = false.obs;
  final activities = <ActivityModel>[].obs;
  final selectedPeriod = 'today'.obs;
  final streakDays = 0.obs;

  TrackingController? _tracking;

  @override
  void onInit() {
    super.onInit();
    loadData();
    _loadStreak();
  }

  @override
  void onReady() {
    super.onReady();
    ever(Get.find<MainNavController>().currentIndex, (int i) {
      if (i == 0) _silentRefresh();
    });
    try {
      _tracking = Get.find<TrackingController>();
    } catch (_) {}
  }

  void setPeriod(String period) {
    if (selectedPeriod.value == period) return;
    selectedPeriod.value = period;
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      activities.assignAll(await _fetchForPeriod());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _silentRefresh() async {
    try {
      activities.assignAll(await _fetchForPeriod());
      _loadStreak();
    } catch (_) {}
  }

  // Query last 30 days and count consecutive days with ≥80% step goal.
  Future<void> _loadStreak() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day - 29);
      final end = DateTime(now.year, now.month, now.day + 1);
      final recent = await _repo.fetchActivitiesForRange(start, end);

      // max per day (upsert pattern: one steps doc per day)
      final stepsByDate = <String, double>{};
      for (final a in recent.where((e) => e.type == 'steps')) {
        final k = _dateKey(a.createdAt);
        if ((stepsByDate[k] ?? 0) < a.value) stepsByDate[k] = a.value;
      }

      // Override today's Firestore value with live pedometer reading
      if (_tracking != null) {
        stepsByDate[_dateKey(now)] = _tracking!.liveSteps.value.toDouble();
      }

      int streak = 0;
      for (int i = 0; i < 30; i++) {
        final day = DateTime(now.year, now.month, now.day - i);
        final steps = stepsByDate[_dateKey(day)] ?? 0;
        if (steps >= AppGoals.steps * 0.8) {
          streak++;
        } else {
          break;
        }
      }
      streakDays.value = streak;
    } catch (_) {}
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<ActivityModel>> _fetchForPeriod() {
    final now = DateTime.now();
    switch (selectedPeriod.value) {
      case 'week':
        final start = DateTime(now.year, now.month, now.day - 6);
        final end = DateTime(now.year, now.month, now.day + 1);
        return _repo.fetchActivitiesForRange(start, end);
      case 'month':
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return _repo.fetchActivitiesForRange(start, end);
      default:
        return _repo.fetchTodayActivities();
    }
  }

  bool get isToday => selectedPeriod.value == 'today';

  int get daysElapsed {
    switch (selectedPeriod.value) {
      case 'week':
        return 7;
      case 'month':
        return DateTime.now().day;
      default:
        return 1;
    }
  }

  double _sum(String type) => activities
      .where((e) => e.type == type)
      .fold(0.0, (s, e) => s + e.value);

  double get stepsTotal {
    if (isToday && _tracking != null) {
      return _tracking!.liveSteps.value.toDouble();
    }
    return _sum('steps');
  }

  String get walkingStatus => _tracking?.pedestrianStatus.value ?? 'unknown';

  double get waterMl => _sum('water');
  double get caloriesKcal => _sum('calories');

  double get sleepValue {
    if (isToday) return _sum('sleep');
    final entries = activities.where((e) => e.type == 'sleep').length;
    return entries == 0 ? 0 : _sum('sleep') / entries;
  }

  double get heartBpm {
    final entries = activities.where((e) => e.type == 'heart').toList();
    if (entries.isEmpty) return 0;
    if (isToday) {
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries.first.value;
    }
    return _sum('heart') / entries.length;
  }

  double get stepsProgress {
    if (isToday) return (stepsTotal / AppGoals.steps).clamp(0.0, 1.0);
    final avg = daysElapsed > 0 ? stepsTotal / daysElapsed : 0;
    return (avg / AppGoals.steps).clamp(0.0, 1.0);
  }

  double get waterProgress => (waterMl / AppGoals.water).clamp(0.0, 1.0);
  double get caloriesProgress =>
      (caloriesKcal / AppGoals.calories).clamp(0.0, 1.0);
  double get sleepProgress => (sleepValue / AppGoals.sleep).clamp(0.0, 1.0);

  String get stepsCenterLabel {
    if (isToday) return _fmtSteps(stepsTotal);
    final avg = daysElapsed > 0 ? stepsTotal / daysElapsed : 0.0;
    return _fmtSteps(avg);
  }

  String get stepsCenterUnit => isToday ? 'steps' : 'avg/day';

  String _fmtSteps(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toInt().toString();
  }

  String get waterUnit {
    if (isToday) return 'liters';
    final avg = daysElapsed > 0 ? waterMl / daysElapsed / 1000 : 0;
    return 'L · ~${avg.toStringAsFixed(2)}/day';
  }

  String get caloriesUnit {
    if (isToday) return 'kcal';
    final avg = daysElapsed > 0 ? caloriesKcal / daysElapsed : 0;
    return 'kcal · ~${avg.toStringAsFixed(0)}/day';
  }

  String get sleepUnit => isToday ? 'hours' : 'avg hrs/night';
  String get heartUnit => isToday ? 'bpm' : 'avg bpm';

  List<double> get waterChartBuckets {
    if (isToday) {
      return _hourlyBuckets('water', 8).map((v) => v / 1000).toList();
    }
    if (selectedPeriod.value == 'week') {
      return _dailyBuckets('water', 7).map((v) => v / 1000).toList();
    }
    return _weeklyBuckets('water', 5).map((v) => v / 1000).toList();
  }

  List<double> _hourlyBuckets(String type, int count) {
    final now = DateTime.now();
    final b = List<double>.filled(count, 0);
    for (final a in activities.where((e) => e.type == type)) {
      final h = now.difference(a.createdAt).inHours;
      if (h < count) b[count - 1 - h] += a.value;
    }
    return b;
  }

  List<double> _dailyBuckets(String type, int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final b = List<double>.filled(days, 0);
    for (final a in activities.where((e) => e.type == type)) {
      final d =
          DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
      final ago = today.difference(d).inDays;
      if (ago >= 0 && ago < days) b[days - 1 - ago] += a.value;
    }
    return b;
  }

  List<double> _weeklyBuckets(String type, int weeks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final b = List<double>.filled(weeks, 0);
    for (final a in activities.where((e) => e.type == type)) {
      final d =
          DateTime(a.createdAt.year, a.createdAt.month, a.createdAt.day);
      final ago = today.difference(d).inDays;
      final wi = ago ~/ 7;
      if (wi >= 0 && wi < weeks) b[weeks - 1 - wi] += a.value;
    }
    return b;
  }

  List<double> get heartRatePoints {
    final entries = activities
        .where((e) => e.type == 'heart')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (entries.isEmpty) return [68, 72, 70, 76, 74, 73, 75, 71];
    return entries.map((e) => e.value).toList();
  }
}
