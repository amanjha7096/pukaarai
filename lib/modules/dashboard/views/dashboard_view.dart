import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/core/widgets/circular_progress_painter.dart';
import 'package:tracking/core/widgets/mini_bar_chart.dart';
import 'package:tracking/data/services/firebase_service.dart';
import 'package:tracking/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';
import 'package:tracking/modules/tracking/controllers/tracking_controller.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  late final DashboardController _ctrl;
  late final AnimationController _entry;
  // Drives the steps ring from 0 → current value on first load
  late final Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<DashboardController>();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..forward();
    _ringAnim = CurvedAnimation(
      parent: _entry,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  // ── Staggered entry helpers ──────────────────────────────────────────────

  Widget _animated(
    Widget child, {
    double fadeStart = 0.0,
    double fadeEnd = 0.5,
  }) {
    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entry,
          curve: Interval(fadeStart, fadeEnd, curve: Curves.easeOut)),
    );
    final slide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entry,
          curve: Interval(fadeStart, fadeEnd, curve: Curves.easeOut)),
    );
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }

  // ── Main build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (_ctrl.isLoading.value && _ctrl.activities.isEmpty) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return RefreshIndicator(
            onRefresh: _ctrl.loadData,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
              children: [
                _animated(_buildHeader(), fadeStart: 0.0, fadeEnd: 0.4),
                const SizedBox(height: 16),
                _animated(_buildPeriodSelector(),
                    fadeStart: 0.05, fadeEnd: 0.45),
                const SizedBox(height: 20),
                if (_ctrl.isLoading.value)
                  const LinearProgressIndicator(
                    color: AppColors.primary,
                    backgroundColor: Colors.transparent,
                  ),
                const SizedBox(height: 4),
                _buildSleepBanner(),
                _animated(_buildGoalsSummary(),
                    fadeStart: 0.1, fadeEnd: 0.5),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _animated(_buildStepsCard(),
                              fadeStart: 0.15, fadeEnd: 0.6),
                          const SizedBox(height: 12),
                          _animated(_buildCaloriesCard(),
                              fadeStart: 0.25, fadeEnd: 0.7),
                          const SizedBox(height: 12),
                          _animated(_buildSleepCard(),
                              fadeStart: 0.35, fadeEnd: 0.8),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        children: [
                          _animated(_buildWaterCard(),
                              fadeStart: 0.2, fadeEnd: 0.65),
                          const SizedBox(height: 12),
                          _animated(_buildHeartCard(),
                              fadeStart: 0.3, fadeEnd: 0.75),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final raw = FirebaseService.currentUser?.displayName ?? '';
    final firstName =
        raw.trim().isEmpty ? 'there' : raw.trim().split(' ').first;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For today',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('$greeting, $firstName!',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        Obx(() => _ctrl.streakDays.value > 0
            ? _StreakChip(days: _ctrl.streakDays.value)
            : const SizedBox(
                width: 12,
                height: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentDot,
                    shape: BoxShape.circle,
                  ),
                ),
              )),
      ],
    );
  }

  // ── Goals summary row ────────────────────────────────────────────────────

  Widget _buildGoalsSummary() {
    return Obx(() {
      if (!_ctrl.isToday) return const SizedBox.shrink();
      final goals = [
        (
          AppColors.primary,
          _ctrl.stepsProgress,
          Icons.directions_walk_rounded,
          'Steps'
        ),
        (
          AppColors.waterBlue,
          _ctrl.waterProgress,
          Icons.water_drop_rounded,
          'Water'
        ),
        (
          AppColors.calorieOrange,
          _ctrl.caloriesProgress,
          Icons.local_fire_department_rounded,
          'Cals'
        ),
        (
          AppColors.sleepIndigo,
          _ctrl.sleepProgress,
          Icons.bedtime_rounded,
          'Sleep'
        ),
      ];
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: goals
              .map((g) => _GoalMiniRing(
                    color: g.$1,
                    progress: g.$2,
                    icon: g.$3,
                    label: g.$4,
                  ))
              .toList(),
        ),
      );
    });
  }

  // ── Sleep active banner ──────────────────────────────────────────────────

  Widget _buildSleepBanner() {
    TrackingController? tracking;
    try {
      tracking = Get.find<TrackingController>();
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Obx(() {
      if (tracking!.sleepStartTime.value == null) {
        return const SizedBox.shrink();
      }
      return GestureDetector(
        onTap: () => Get.find<MainNavController>().currentIndex.value = 2,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sleepIndigo.withAlpha(18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.sleepIndigo.withAlpha(55)),
          ),
          child: Row(
            children: [
              const Text('💤', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => Text(
                          'Sleeping · ${tracking!.sleepDurationText.value}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sleepIndigo),
                        )),
                    Text('Tap to manage sleep',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: tracking.wakeUp,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.sleepIndigo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wb_sunny_rounded,
                          color: Colors.white, size: 13),
                      SizedBox(width: 5),
                      Text('Wake Up',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Period selector ──────────────────────────────────────────────────────

  Widget _buildPeriodSelector() {
    const periods = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
    ];
    return Obx(() => Row(
          children: periods.map((p) {
            final selected = _ctrl.selectedPeriod.value == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () => _ctrl.setPeriod(p.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary
                        : AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(77),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                  ),
                  child: Center(
                    child: Text(p.$2,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 12,
                        )),
                  ),
                ),
              ),
            );
          }).toList(),
        ));
  }

  // ── Steps card ───────────────────────────────────────────────────────────

  Widget _buildStepsCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C55E8), Color(0xFF7B74FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => Text(
                    _ctrl.isToday ? 'Walk' : 'Steps',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  )),
              Obx(() {
                if (!_ctrl.isToday) {
                  return const Icon(Icons.directions_walk_rounded,
                      color: Colors.white70, size: 20);
                }
                final status = _ctrl.walkingStatus;
                final isWalking = status == 'walking';
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isWalking
                            ? const Color(0xFF4ADE80)
                            : Colors.white38,
                        shape: BoxShape.circle,
                        boxShadow: isWalking
                            ? [
                                BoxShadow(
                                    color:
                                        const Color(0xFF4ADE80).withAlpha(160),
                                    blurRadius: 6,
                                    spreadRadius: 1)
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isWalking
                          ? 'Walking'
                          : status == 'stopped'
                              ? 'Stopped'
                              : 'Detecting…',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                );
              }),
            ],
          ),
          Expanded(
            child: Center(
              // AnimatedBuilder uses _ringAnim to sweep the arc from 0 → progress
              child: Obx(() {
                final progress = _ctrl.stepsProgress;
                return SizedBox(
                  width: 112,
                  height: 112,
                  child: AnimatedBuilder(
                    animation: _ringAnim,
                    builder: (context, _) => CustomPaint(
                      painter: CircularProgressPainter(
                        progress: progress * _ringAnim.value,
                        trackColor: Colors.white24,
                        progressColor: Colors.white,
                        strokeWidth: 10,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _ctrl.stepsCenterLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _ctrl.stepsCenterUnit,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Water card ───────────────────────────────────────────────────────────

  Widget _buildWaterCard() {
    return Container(
      height: 172,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Water', style: _titleStyle),
              const Icon(Icons.water_drop_rounded,
                  color: AppColors.waterBlue, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Obx(() => MiniBarChart(
                  values: _ctrl.waterChartBuckets,
                  barColor: AppColors.waterBlue,
                )),
          ),
          const SizedBox(height: 6),
          Obx(() => Text(
                (_ctrl.waterMl / 1000).toStringAsFixed(2),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              )),
          Obx(() => Text(_ctrl.waterUnit,
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          const SizedBox(height: 6),
          Obx(() => _GoalBar(
                progress: _ctrl.waterProgress,
                color: AppColors.waterBlue,
              )),
        ],
      ),
    );
  }

  // ── Calories card ────────────────────────────────────────────────────────

  Widget _buildCaloriesCard() {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calories', style: _titleStyle),
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.calorieOrange, size: 20),
            ],
          ),
          const Spacer(),
          Obx(() => Text(
                _ctrl.caloriesKcal.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              )),
          const SizedBox(height: 2),
          Obx(() => Text(_ctrl.caloriesUnit,
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          const SizedBox(height: 6),
          Obx(() => _GoalBar(
                progress: _ctrl.caloriesProgress,
                color: AppColors.calorieOrange,
              )),
        ],
      ),
    );
  }

  // ── Sleep card ───────────────────────────────────────────────────────────

  Widget _buildSleepCard() {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sleep', style: _titleStyle),
              const Icon(Icons.bedtime_rounded,
                  color: AppColors.sleepIndigo, size: 20),
            ],
          ),
          const Spacer(),
          Obx(() {
            final v = _ctrl.sleepValue;
            final h = v.floor();
            final m = ((v - h) * 60).round();
            return Text(
              '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            );
          }),
          const SizedBox(height: 2),
          Obx(() => Text(_ctrl.sleepUnit,
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          const SizedBox(height: 6),
          Obx(() => _GoalBar(
                progress: _ctrl.sleepProgress,
                color: AppColors.sleepIndigo,
              )),
        ],
      ),
    );
  }

  // ── Heart card ───────────────────────────────────────────────────────────

  Widget _buildHeartCard() {
    return Container(
      height: 304,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Heart', style: _titleStyle),
              const Icon(Icons.favorite_rounded,
                  color: AppColors.heartPink, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
              child: Obx(() => _miniLineChart(_ctrl.heartRatePoints))),
          const SizedBox(height: 10),
          Obx(() => Text(
                _ctrl.heartBpm > 0 ? '${_ctrl.heartBpm.toInt()}' : '--',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              )),
          const SizedBox(height: 2),
          Obx(() => Text(_ctrl.heartUnit,
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _miniLineChart(List<double> points) {
    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
    final minY = points.reduce((a, b) => a < b ? a : b) - 8;
    final maxY = points.reduce((a, b) => a > b ? a : b) + 8;

    return LineChart(LineChartData(
      minY: minY,
      maxY: maxY,
      lineTouchData: const LineTouchData(enabled: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.heartPink,
          barWidth: 2.2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.heartPink.withAlpha(26),
          ),
        ),
      ],
    ));
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      );

  TextStyle get _titleStyle => TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary);
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _GoalBar extends StatelessWidget {
  final double progress;
  final Color color;
  const _GoalBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          backgroundColor: color.withAlpha(30),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 4,
        ),
      ),
    );
  }
}

class _GoalMiniRing extends StatelessWidget {
  final Color color;
  final double progress;
  final IconData icon;
  final String label;

  const _GoalMiniRing({
    required this.color,
    required this.progress,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => CustomPaint(
              painter: CircularProgressPainter(
                progress: v,
                trackColor: color.withAlpha(30),
                progressColor: color,
                strokeWidth: 5,
              ),
              child: child,
            ),
            child: Center(child: Icon(icon, color: color, size: 18)),
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style:
                TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text('${(progress * 100).round()}%',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int days;
  const _StreakChip({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.calorieOrange.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.calorieOrange.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$days day${days > 1 ? "s" : ""}',
            style: const TextStyle(
              color: AppColors.calorieOrange,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
