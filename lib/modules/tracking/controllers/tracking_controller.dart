import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tracking/core/utils/app_utils.dart';
import 'package:tracking/data/repositories/activity_repository.dart';

class TrackingController extends GetxController {
  final ActivityRepository _repo;
  final _storage = GetStorage();

  TrackingController({ActivityRepository? repo})
      : _repo = repo ?? ActivityRepository();

  final isLoading = false.obs;

  // ── Pedometer stream observables ──────────────────────────────────────────
  final liveSteps = 0.obs;
  final rawSensorSteps = 0.obs;
  final pedestrianStatus = 'unknown'.obs;
  final permissionGranted = false.obs;
  final streamActive = false.obs;
  final streamError = ''.obs;

  // ── Sleep session observables ─────────────────────────────────────────────
  final sleepStartTime = Rxn<DateTime>();
  final sleepDurationText = ''.obs;

  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  Timer? _autoSaveTimer;
  Timer? _sleepDisplayTimer;
  int _lastAutoSavedSteps = -1;

  // Session baseline: reset to current sensor value at each fresh login so
  // steps walked while logged out are never counted in the new session.
  static const _baseKey = 'step_base_';
  static const _manualKey = 'manual_steps_';
  // Accumulated pedometer steps from previous sessions today (not manual).
  static const _prevKey = 'prev_steps_';

  bool _freshSession = false;

  bool get isSleeping => sleepStartTime.value != null;

  @override
  void onInit() {
    super.onInit();
    _freshSession = true; // force baseline reset on first step event
    liveSteps.value = _manualStepsToday + _prevSessionSteps;
    _restoreSleepState();
    _requestPermissionThenStart();
  }

  void _restoreSleepState() {
    final stored = _storage.read<String>('sleep_start');
    if (stored == null) return;
    try {
      sleepStartTime.value = DateTime.parse(stored);
      _startSleepDisplayTimer();
    } catch (_) {
      _storage.remove('sleep_start');
    }
  }

  void _startSleepDisplayTimer() {
    _updateSleepDuration();
    _sleepDisplayTimer?.cancel();
    _sleepDisplayTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _updateSleepDuration(),
    );
  }

  void _updateSleepDuration() {
    final start = sleepStartTime.value;
    if (start == null) { sleepDurationText.value = ''; return; }
    final diff = DateTime.now().difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    sleepDurationText.value = '${h}h ${m}m';
  }

  Future<void> startSleep() async {
    final now = DateTime.now();
    _storage.write('sleep_start', now.toIso8601String());
    sleepStartTime.value = now;
    _startSleepDisplayTimer();
    AppUtils.showSuccess('Sleep tracking started · Good night!');
  }

  Future<void> wakeUp() async {
    final start = sleepStartTime.value;
    if (start == null) { AppUtils.showError('No sleep session in progress'); return; }
    final diff = DateTime.now().difference(start);
    if (diff.inMinutes < 5) { AppUtils.showError('Session too short (< 5 min)'); return; }
    _sleepDisplayTimer?.cancel();
    _storage.remove('sleep_start');
    sleepStartTime.value = null;
    sleepDurationText.value = '';
    final hours = diff.inMinutes / 60.0;
    await addSleep(hours);
  }

  int get _manualStepsToday =>
      _storage.read<int>('$_manualKey${_todayKey()}') ?? 0;

  // Pedometer steps accumulated from all earlier sessions today.
  int get _prevSessionSteps =>
      _storage.read<int>('$_prevKey${_todayKey()}') ?? 0;

  // ── Permission + stream init ───────────────────────────────────────────────

  Future<void> _requestPermissionThenStart() async {
    if (Platform.isAndroid) {
      final status = await Permission.activityRecognition.request();
      permissionGranted.value = status.isGranted;
      if (!status.isGranted) {
        streamError.value = status.isPermanentlyDenied
            ? 'Permission permanently denied. Enable in Settings → App → Permissions.'
            : 'Activity Recognition permission denied.';
        return;
      }
    } else {
      permissionGranted.value = true;
    }
    _startStream();
  }

  void _startStream() {
    streamActive.value = true;
    streamError.value = '';

    _stepSub = Pedometer.stepCountStream.listen(
      _onStep,
      onError: (dynamic e) {
        streamActive.value = false;
        streamError.value = e.toString();
      },
      cancelOnError: false,
    );

    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (PedestrianStatus e) => pedestrianStatus.value = e.status,
      onError: (dynamic _) => pedestrianStatus.value = 'unavailable',
      cancelOnError: false,
    );
  }

  void _onStep(StepCount event) {
    rawSensorSteps.value = event.steps;
    final key = _todayKey();
    var stored = _storage.read<int>('$_baseKey$key');

    // Reset baseline when: fresh login session, no baseline yet, or sensor
    // rolled back (device reboot). This prevents steps walked while logged out
    // from leaking into the new session's count.
    if (_freshSession || stored == null || event.steps < stored) {
      _storage.write('$_baseKey$key', event.steps);
      stored = event.steps;
      _freshSession = false;
    }

    // Total = steps since session start + steps from prior sessions + manual
    final pedometerDelta = event.steps - stored;
    liveSteps.value = pedometerDelta + _prevSessionSteps + _manualStepsToday;
    _scheduleAutoSave();
  }

  // ── Auto-save: debounce 90 s after last step event ────────────────────────

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 90), _autoSave);
  }

  Future<void> _autoSave() async {
    final current = liveSteps.value;
    if (current > 0 && current != _lastAutoSavedSteps) {
      _lastAutoSavedSteps = current;
      try {
        await _repo.upsertTodaySteps(current.toDouble());
      } catch (_) {}
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> retryPermission() async {
    _stepSub?.cancel();
    _statusSub?.cancel();
    liveSteps.value = 0;
    rawSensorSteps.value = 0;
    pedestrianStatus.value = 'unknown';
    streamActive.value = false;
    streamError.value = '';
    _freshSession = true;
    await _requestPermissionThenStart();
  }

  // ── Explicit save (also used by manual entry) ─────────────────────────────

  Future<void> saveSteps() async {
    if (liveSteps.value <= 0) {
      AppUtils.showError('No steps recorded yet');
      return;
    }
    _autoSaveTimer?.cancel();
    _lastAutoSavedSteps = liveSteps.value;
    try {
      isLoading.value = true;
      await _repo.upsertTodaySteps(liveSteps.value.toDouble());
      AppUtils.showSuccess('Steps saved!');
    } catch (e) {
      AppUtils.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Manual step entry ─────────────────────────────────────────────────────
  // Persists in a separate GetStorage key so pedometer events never overwrite
  // the manual count. liveSteps = pedometerDelta + manualStepsToday.

  Future<void> addStepsManually(int steps) async {
    if (steps <= 0) {
      AppUtils.showError('Enter a valid step count');
      return;
    }
    isLoading.value = true;
    try {
      final manualKey = '$_manualKey${_todayKey()}';
      final newManual = _manualStepsToday + steps;
      _storage.write(manualKey, newManual);
      liveSteps.value += steps; // reflect in UI immediately
      _lastAutoSavedSteps = liveSteps.value;
      await _repo.upsertTodaySteps(liveSteps.value.toDouble());
      AppUtils.showSuccess('$steps steps added!');
    } catch (e) {
      AppUtils.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ── Other activity actions ─────────────────────────────────────────────────

  Future<void> addWater(double ml) => _save(type: 'water', value: ml);

  Future<void> addCalories(double kcal, {String? note}) =>
      _save(type: 'calories', value: kcal, note: note);

  Future<void> addSleep(double hours) => _save(type: 'sleep', value: hours);

  Future<void> addHeartRate(double bpm) => _save(type: 'heart', value: bpm);

  Future<void> _save(
      {required String type, required double value, String? note}) async {
    try {
      isLoading.value = true;
      await _repo.addActivity(type: type, value: value, note: note);
      AppUtils.showSuccess(_label(type));
    } catch (e) {
      AppUtils.showError(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  String _label(String type) {
    switch (type) {
      case 'water':
        return 'Water intake saved!';
      case 'calories':
        return 'Calories saved!';
      case 'sleep':
        return 'Sleep saved!';
      case 'heart':
        return 'Heart rate saved!';
      default:
        return 'Saved!';
    }
  }

  @override
  void onClose() {
    _autoSaveTimer?.cancel();

    // Persist pedometer-only steps so the next session can add on top.
    // Excludes manual steps (they survive in their own key).
    final current = liveSteps.value;
    final pedoOnly = current - _manualStepsToday;
    if (pedoOnly > 0) {
      _storage.write('$_prevKey${_todayKey()}', pedoOnly);
    }

    // Fire-and-forget flush: saves any steps the debounce timer didn't catch
    // (e.g. user logs out within 90 s of last step).
    if (current > 0 && current != _lastAutoSavedSteps) {
      _repo.upsertTodaySteps(current.toDouble());
    }

    _sleepDisplayTimer?.cancel();
    _stepSub?.cancel();
    _statusSub?.cancel();
    super.onClose();
  }
}
