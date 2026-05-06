import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/data/repositories/activity_repository.dart';

/// In-memory stand-in for ActivityRepository.
/// Override only what each test needs; everything else is a safe no-op.
class FakeActivityRepository extends ActivityRepository {
  List<ActivityModel> activitiesForRange;
  List<ActivityModel> allActivities;
  List<ActivityModel> todayActivities;

  final List<String> deletedIds = [];
  final List<double> upsertedSteps = [];
  final List<Map<String, dynamic>> addedActivities = [];

  bool throwOnDelete = false;
  bool throwOnFetch = false;

  FakeActivityRepository({
    List<ActivityModel>? activitiesForRange,
    List<ActivityModel>? allActivities,
    List<ActivityModel>? todayActivities,
  })  : activitiesForRange = activitiesForRange ?? [],
        allActivities = allActivities ?? [],
        todayActivities = todayActivities ?? [];

  @override
  Future<List<ActivityModel>> fetchActivitiesForRange(
      DateTime start, DateTime end) async {
    if (throwOnFetch) throw Exception('fetch error');
    return activitiesForRange;
  }

  @override
  Future<List<ActivityModel>> fetchAllActivities() async {
    if (throwOnFetch) throw Exception('fetch error');
    return allActivities;
  }

  @override
  Future<List<ActivityModel>> fetchTodayActivities() async {
    if (throwOnFetch) throw Exception('fetch error');
    return todayActivities;
  }

  @override
  Future<void> deleteActivity(String id) async {
    if (throwOnDelete) throw Exception('delete error');
    deletedIds.add(id);
  }

  @override
  Future<void> upsertTodaySteps(double steps) async {
    upsertedSteps.add(steps);
  }

  @override
  Future<void> addActivity({
    required String type,
    required double value,
    String? note,
    DateTime? createdAt,
  }) async {
    addedActivities.add({'type': type, 'value': value, 'note': note});
  }
}
