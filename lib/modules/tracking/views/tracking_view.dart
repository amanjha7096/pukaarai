import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/modules/tracking/controllers/tracking_controller.dart';

class TrackingView extends StatefulWidget {
  const TrackingView({super.key});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  late final TrackingController _ctrl;
  final _manualStepsCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _mealNoteCtrl = TextEditingController();
  final _sleepCtrl = TextEditingController();
  final _heartCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TrackingController>();
  }

  @override
  void dispose() {
    _manualStepsCtrl.dispose();
    _waterCtrl.dispose();
    _caloriesCtrl.dispose();
    _mealNoteCtrl.dispose();
    _sleepCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
          children: [
            _buildPageHeader(),
            const SizedBox(height: 24),
            _buildStepsCard(),
            const SizedBox(height: 16),
            _buildWaterCard(),
            const SizedBox(height: 16),
            _buildCaloriesCard(),
            const SizedBox(height: 16),
            _buildSleepCard(),
            const SizedBox(height: 16),
            _buildHeartCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Track Activity',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormat('MMM d').format(DateTime.now()),
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStepsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle(
                  'Steps', Icons.directions_walk_rounded, AppColors.primary),
              Obx(() => _streamBadge()),
            ],
          ),
          const SizedBox(height: 16),

          // ── Stream diagnostics panel ────────────────────────────────────
          Obx(() {
            final error = _ctrl.streamError.value;
            if (error.isNotEmpty) return _errorPanel(error);

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  // Permission row
                  _diagRow(
                    label: 'Permission',
                    value: _ctrl.permissionGranted.value
                        ? 'Granted ✓'
                        : 'Denied ✗',
                    valueColor: _ctrl.permissionGranted.value
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEF4444),
                  ),
                  const Divider(height: 18, thickness: 0.5),
                  // Pedestrian status row
                  _diagRow(
                    label: 'Status',
                    valueWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _pulsingDot(
                            _ctrl.pedestrianStatus.value == 'walking'),
                        const SizedBox(width: 6),
                        Text(
                          _ctrl.pedestrianStatus.value.capitalize ??
                              _ctrl.pedestrianStatus.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _ctrl.pedestrianStatus.value == 'walking'
                                ? const Color(0xFF22C55E)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 18, thickness: 0.5),
                  // Raw sensor count
                  // _diagRow(
                  //   label: 'Sensor (raw)',
                  //   value: _ctrl.rawSensorSteps.value == 0
                  //       ? 'Waiting for signal…'
                  //       : _ctrl.rawSensorSteps.value.toString(),
                  //   valueColor: AppColors.textPrimary,
                  // ),
                  // const Divider(height: 18, thickness: 0.5),
                  // Stream active
                  _diagRow(
                    label: 'Stream',
                    value: _ctrl.streamActive.value
                        ? '● Active'
                        : '○ Inactive',
                    valueColor: _ctrl.streamActive.value
                        ? const Color(0xFF22C55E)
                        : AppColors.textSecondary,
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // ── Big step count ───────────────────────────────────────────────
          Obx(() {
            if (_ctrl.streamError.value.isNotEmpty) {
              return TextButton.icon(
                onPressed: _ctrl.retryPermission,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry Permission'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _ctrl.liveSteps.value.toString(),
                      style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 8),
                      child: Text('steps today',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary)),

                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Auto-tracked · updates in real time from your device',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withAlpha(180)),
                ),
              ],
            );
          }),

          const SizedBox(height: 20),

          // ── Manual step entry ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _manualStepsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Add steps manually',
                    suffixText: 'steps',
                    prefixIcon: Icon(Icons.edit_rounded,
                        color: AppColors.textSecondary, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => _iconButton(
                    icon: Icons.add_rounded,
                    color: AppColors.primary,
                    isLoading: _ctrl.isLoading.value,
                    onPressed: () {
                      final v = int.tryParse(_manualStepsCtrl.text);
                      if (v != null && v > 0) {
                        _ctrl.addStepsManually(v);
                        _manualStepsCtrl.clear();
                      }
                    },
                  )),
            ],
          ),

          const SizedBox(height: 12),
          Obx(() => _primaryButton(
                label: 'Save Steps',
                isLoading: _ctrl.isLoading.value,
                icon: Icons.save_alt_rounded,
                color: AppColors.primary,
                onPressed: _ctrl.saveSteps,
              )),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Water Intake', Icons.water_drop_rounded, AppColors.waterBlue),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [100, 250, 500, 1000].map((ml) {
              return GestureDetector(
                onTap: () => _ctrl.addWater(ml.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.waterBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.waterBlue.withAlpha(77), width: 1),
                  ),
                  child: Text(
                    ml >= 1000 ? '+1 L' : '+$ml ml',
                    style: const TextStyle(
                        color: AppColors.waterBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _waterCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Custom amount (ml)',
                    suffixText: 'ml',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() => _iconButton(
                    icon: Icons.add_rounded,
                    color: AppColors.waterBlue,
                    isLoading: _ctrl.isLoading.value,
                    onPressed: () {
                      final v = double.tryParse(_waterCtrl.text);
                      if (v != null && v > 0) {
                        _ctrl.addWater(v);
                        _waterCtrl.clear();
                      }
                    },
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              'Calories', Icons.local_fire_department_rounded, AppColors.calorieOrange),
          const SizedBox(height: 16),
          TextField(
            controller: _caloriesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Amount (kcal)',
              suffixText: 'kcal',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mealNoteCtrl,
            decoration: InputDecoration(
              hintText: 'Meal note (optional)',
              prefixIcon: Icon(Icons.restaurant_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => _primaryButton(
                label: 'Add Calories',
                isLoading: _ctrl.isLoading.value,
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.calorieOrange,
                onPressed: () {
                  final v = double.tryParse(_caloriesCtrl.text);
                  if (v != null && v > 0) {
                    _ctrl.addCalories(v,
                        note: _mealNoteCtrl.text.trim().isEmpty
                            ? null
                            : _mealNoteCtrl.text.trim());
                    _caloriesCtrl.clear();
                    _mealNoteCtrl.clear();
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle(
                  'Sleep', Icons.bedtime_rounded, AppColors.sleepIndigo),
              Obx(() {
                if (!_ctrl.isSleeping) return const SizedBox.shrink();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.sleepIndigo.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.sleepIndigo,
                            shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      const Text('SLEEPING',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.sleepIndigo,
                              letterSpacing: 0.6)),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // ── Active session panel ─────────────────────────────────────────
          Obx(() {
            if (!_ctrl.isSleeping) return const SizedBox.shrink();
            final start = _ctrl.sleepStartTime.value!;
            final timeStr = DateFormat('hh:mm a').format(start);
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.sleepIndigo.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.sleepIndigo.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Text('💤', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sleeping since $timeStr',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Obx(() => Text(
                            _ctrl.sleepDurationText.value,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sleepIndigo),
                          )),
                    ],
                  ),
                ],
              ),
            );
          }),

          // ── Sleep / Wake toggle button ───────────────────────────────────
          Obx(() => _primaryButton(
                label:
                    _ctrl.isSleeping ? 'Wake Up ☀' : 'Going to Sleep',
                isLoading: _ctrl.isLoading.value,
                icon: _ctrl.isSleeping
                    ? Icons.wb_sunny_rounded
                    : Icons.bedtime_rounded,
                color: AppColors.sleepIndigo,
                onPressed:
                    _ctrl.isSleeping ? _ctrl.wakeUp : _ctrl.startSleep,
              )),

          // ── Manual entry separator ───────────────────────────────────────
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('or add manually',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withAlpha(160))),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sleepCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Hours (e.g. 7.5 = 7h 30m)',
              suffixText: 'hrs',
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => _primaryButton(
                label: 'Add Sleep',
                isLoading: _ctrl.isLoading.value,
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.sleepIndigo,
                onPressed: () {
                  final v = double.tryParse(_sleepCtrl.text);
                  if (v != null && v > 0) {
                    _ctrl.addSleep(v);
                    _sleepCtrl.clear();
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _buildHeartCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
              'Heart Rate', Icons.favorite_rounded, AppColors.heartPink),
          const SizedBox(height: 16),
          TextField(
            controller: _heartCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter BPM',
              suffixText: 'bpm',
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => _primaryButton(
                label: 'Add Heart Rate',
                isLoading: _ctrl.isLoading.value,
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.heartPink,
                onPressed: () {
                  final v = double.tryParse(_heartCtrl.text);
                  if (v != null && v > 0) {
                    _ctrl.addHeartRate(v);
                    _heartCtrl.clear();
                  }
                },
              )),
        ],
      ),
    );
  }

  Widget _streamBadge() {
    if (_ctrl.streamError.value.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('ERROR',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEF4444),
                letterSpacing: 0.8)),
      );
    }
    if (_ctrl.streamActive.value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E).withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('LIVE',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF22C55E),
                letterSpacing: 0.8)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('INACTIVE',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8)),
    );
  }

  Widget _diagRow({
    required String label,
    String? value,
    Color? valueColor,
    Widget? valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        valueWidget ??
            Text(value ?? '',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary)),
      ],
    );
  }

  Widget _pulsingDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF22C55E) : AppColors.textSecondary,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                    color: const Color(0xFF22C55E).withAlpha(100),
                    blurRadius: 6,
                    spreadRadius: 2),
              ]
            : null,
      ),
    );
  }

  Widget _errorPanel(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withAlpha(15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(error,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required bool isLoading,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
