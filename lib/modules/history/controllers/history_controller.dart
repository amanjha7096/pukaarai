import 'dart:math' show max;

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tracking/core/utils/app_utils.dart';
import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/data/repositories/activity_repository.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';

class HistoryController extends GetxController {
  final ActivityRepository _repo;

  HistoryController({ActivityRepository? repo})
      : _repo = repo ?? ActivityRepository();

  final isLoading = false.obs;
  final allActivities = <ActivityModel>[].obs;
  final selectedFilter = 'all'.obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onReady() {
    super.onReady();
    ever(Get.find<MainNavController>().currentIndex, (int i) {
      if (i == 3) _silentRefresh(); // History is at index 3
    });
  }

  Future<void> _silentRefresh() async {
    try {
      allActivities.assignAll(await _repo.fetchAllActivities());
    } catch (_) {}
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      allActivities.assignAll(await _repo.fetchAllActivities());
    } finally {
      isLoading.value = false;
    }
  }

  List<ActivityModel> get filtered {
    if (selectedFilter.value == 'all') return allActivities;
    return allActivities
        .where((a) => a.type == selectedFilter.value)
        .toList();
  }

  Map<String, List<ActivityModel>> get groupedByDate {
    final map = <String, List<ActivityModel>>{};
    for (final item in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(item.createdAt);
      (map[key] ??= []).add(item);
    }
    return map;
  }

  void setFilter(String f) => selectedFilter.value = f;

  Future<void> deleteActivity(String id) async {
    try {
      await _repo.deleteActivity(id);
      allActivities.removeWhere((a) => a.id == id);
    } catch (_) {
      AppUtils.showError('Could not delete entry');
    }
  }

  // ── Chart data: last 7 days, index 0 = oldest ──────────────────────────────
  List<double> get stepsLast7 => _dailyTotals('steps', 7, useMax: true);
  List<double> get waterLast7 => _dailyTotals('water', 7);
  List<double> get caloriesLast7 => _dailyTotals('calories', 7);
  List<double> get sleepLast7 => _dailyTotals('sleep', 7);

  List<double> _dailyTotals(String type, int days, {bool useMax = false}) {
    final now = DateTime.now();
    final fmt = DateFormat('yyyy-MM-dd');
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, now.day - (days - 1 - i));
      final key = fmt.format(day);
      final items = allActivities
          .where((a) => a.type == type && fmt.format(a.createdAt) == key)
          .toList();
      if (items.isEmpty) return 0.0;
      if (useMax) return items.map((a) => a.value).reduce(max);
      return items.fold(0.0, (s, a) => s + a.value);
    });
  }
}
