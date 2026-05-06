import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/data/services/firebase_service.dart';

class ActivityRepository {
  Future<void> addActivity({
    required String type,
    required double value,
    String? note,
    DateTime? createdAt,
  }) async {
    final user = FirebaseService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final ref = FirebaseService.userActivitiesRef(user.uid).doc();
    final activity = ActivityModel(
      id: ref.id,
      type: type,
      value: value,
      note: note,
      createdAt: createdAt ?? DateTime.now(),
    );
    await ref.set(activity.toJson());
  }

  Future<List<ActivityModel>> fetchTodayActivities() async {
    final user = FirebaseService.currentUser;
    if (user == null) return [];

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    final snap = await FirebaseService.userActivitiesRef(user.uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => ActivityModel.fromJson(d.data())).toList();
  }

  Future<List<ActivityModel>> fetchAllActivities() async {
    final user = FirebaseService.currentUser;
    if (user == null) return [];

    final snap = await FirebaseService.userActivitiesRef(user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => ActivityModel.fromJson(d.data())).toList();
  }

  Future<List<ActivityModel>> fetchActivitiesForRange(
      DateTime start, DateTime end) async {
    final user = FirebaseService.currentUser;
    if (user == null) return [];

    final snap = await FirebaseService.userActivitiesRef(user.uid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('createdAt', descending: false)
        .get();

    return snap.docs.map((d) => ActivityModel.fromJson(d.data())).toList();
  }

  // One document per day for steps — overwrites instead of appending.
  // Uses a deterministic ID so weekly/monthly sums stay correct.
  Future<void> upsertTodaySteps(double steps) async {
    final user = FirebaseService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final docId = 'steps_$dateKey';
    // Noon timestamp: always within day range queries regardless of save time
    final activity = ActivityModel(
      id: docId,
      type: 'steps',
      value: steps,
      createdAt: DateTime(now.year, now.month, now.day, 12),
    );
    await FirebaseService.userActivitiesRef(user.uid)
        .doc(docId)
        .set(activity.toJson());
  }

  // Reads the single steps document for today without a collection scan.
  Future<double?> fetchTodaySteps() async {
    final user = FirebaseService.currentUser;
    if (user == null) return null;
    final now = DateTime.now();
    final dateKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final doc = await FirebaseService.userActivitiesRef(user.uid)
          .doc('steps_$dateKey')
          .get();
      if (!doc.exists) return null;
      return (doc.data()?['value'] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteActivity(String id) async {
    final user = FirebaseService.currentUser;
    if (user == null) return;
    await FirebaseService.userActivitiesRef(user.uid).doc(id).delete();
  }
}
