import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/modules/goals/controllers/goals_controller.dart';

class GoalsView extends StatefulWidget {
  const GoalsView({super.key});

  @override
  State<GoalsView> createState() => _GoalsViewState();
}

class _GoalsViewState extends State<GoalsView>
    with SingleTickerProviderStateMixin {
  late final GoalsController _ctrl;
  late final AnimationController _entry;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<GoalsController>();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  Widget _animated(Widget child, {double start = 0.0, double end = 0.55}) {
    final opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _entry, curve: Interval(start, end, curve: Curves.easeOut)),
    );
    final slide =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entry, curve: Interval(start, end, curve: Curves.easeOut)),
    );
    return FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: slide, child: child));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          return RefreshIndicator(
            onRefresh: _ctrl.loadData,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
              children: [
                _animated(_buildHeader(), start: 0.0, end: 0.4),
                const SizedBox(height: 24),
                _animated(_buildGoalCard(type: 'steps'), start: 0.1, end: 0.55),
                const SizedBox(height: 16),
                _animated(_buildGoalCard(type: 'water'), start: 0.2, end: 0.7),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goals & Streaks',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Build consistent healthy habits',
                style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ],
    );
  }

  // ── Unified goal card ─────────────────────────────────────────────────────

  Widget _buildGoalCard({required String type}) {
    final isSteps = type == 'steps';
    final color =
        isSteps ? AppColors.primary : AppColors.waterBlue;
    final icon = isSteps
        ? Icons.directions_walk_rounded
        : Icons.water_drop_rounded;
    final label = isSteps ? 'Steps' : 'Water';
    final emoji = isSteps ? '👟' : '💧';

    return Obx(() {
      final goal = isSteps ? _ctrl.stepsGoal.value : _ctrl.waterGoal.value;
      final streak =
          isSteps ? _ctrl.stepsStreak.value : _ctrl.waterStreak.value;
      final longest = isSteps
          ? _ctrl.stepsLongestStreak.value
          : _ctrl.waterLongestStreak.value;
      final weekDays =
          isSteps ? _ctrl.stepsWeekDays.value : _ctrl.waterWeekDays.value;
      final dataByDate =
          isSteps ? _ctrl.stepsByDate : _ctrl.waterByDate;
      final unit = isSteps ? 'steps/day' : 'ml/day';
      final goalDisplay = isSteps
          ? '${goal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps'
          : '${goal.toInt()} ml';

      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Gradient header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withAlpha(230),
                    color.withAlpha(180),
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$emoji $label Goal',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(goalDisplay,
                            style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditGoal(
                        context, isSteps, goal, unit, color),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withAlpha(80)),
                      ),
                      child: const Text('Edit',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Streak stats ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                      child:
                          _StatBadge(
                    value: streak,
                    label: 'Current streak',
                    icon: '🔥',
                    color: color,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatBadge(
                    value: longest,
                    label: 'Best streak',
                    icon: '🏆',
                    color: color,
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _StatBadge(
                    value: weekDays,
                    label: 'This week',
                    icon: '📅',
                    color: color,
                    suffix: '/7',
                  )),
                ],
              ),
            ),

            // ── Week day dots ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _WeekDots(
                dataByDate: dataByDate,
                goal: goal,
                color: color,
              ),
            ),

            // ── 28-day heatmap ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last 28 days',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  Row(
                    children: [
                      _LegendDot(color: color.withAlpha(40), label: '0%'),
                      const SizedBox(width: 6),
                      _LegendDot(color: color.withAlpha(130), label: '50%'),
                      const SizedBox(width: 6),
                      _LegendDot(color: color, label: '100%'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _HeatmapGrid(
                dataByDate: dataByDate,
                goal: goal,
                color: color,
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Edit goal bottom sheet ─────────────────────────────────────────────────

  void _showEditGoal(
    BuildContext context,
    bool isSteps,
    double current,
    String unit,
    Color color,
  ) {
    final textCtrl =
        TextEditingController(text: current.toInt().toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 28,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Set ${isSteps ? "Step" : "Water"} Goal',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              isSteps
                  ? 'How many steps do you want to take daily?'
                  : 'How much water do you want to drink daily?',
              style:
                  TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: InputDecoration(
                hintText: isSteps ? '10000' : '3000',
                suffixText: isSteps ? 'steps' : 'ml',
                prefixIcon: Icon(
                  isSteps
                      ? Icons.directions_walk_rounded
                      : Icons.water_drop_rounded,
                  color: color,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Quick presets
            Row(
              children: (isSteps
                      ? [5000.0, 7500.0, 10000.0, 12000.0]
                      : [1500.0, 2000.0, 2500.0, 3000.0])
                  .map((preset) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => textCtrl.text =
                              preset.toInt().toString(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: color.withAlpha(60)),
                            ),
                            child: Text(
                              isSteps
                                  ? '${(preset / 1000).toStringAsFixed(preset % 1000 == 0 ? 0 : 1)}k'
                                  : '${preset.toInt()}',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(textCtrl.text);
                if (val != null && val > 0) {
                  if (isSteps) {
                    _ctrl.setStepsGoal(val);
                  } else {
                    _ctrl.setWaterGoal(val);
                  }
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Goal'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final int value;
  final String label;
  final String icon;
  final Color color;
  final String suffix;

  const _StatBadge({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            '$value$suffix',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _WeekDots extends StatelessWidget {
  final Map<String, double> dataByDate;
  final double goal;
  final Color color;

  const _WeekDots({
    required this.dataByDate,
    required this.goal,
    required this.color,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Start the 7-day window from Monday of this week
    final todayWeekday = now.weekday; // 1=Mon, 7=Sun
    final monday = now.subtract(Duration(days: todayWeekday - 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This week',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (i) {
            final day = DateTime(
                monday.year, monday.month, monday.day + i);
            final key =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final value = dataByDate[key] ?? 0;
            final hit = value >= goal * 0.8;
            final isFuture = day.isAfter(now);
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;

            return Expanded(
              child: Column(
                children: [
                  Text(_dayLabels[i],
                      style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: isToday
                              ? FontWeight.w700
                              : FontWeight.w400)),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isFuture
                          ? Colors.transparent
                          : hit
                              ? color
                              : color.withAlpha(28),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: color, width: 2)
                          : null,
                    ),
                    child: isFuture
                        ? null
                        : hit
                            ? const Center(
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14))
                            : null,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Map<String, double> dataByDate;
  final double goal;
  final Color color;

  const _HeatmapGrid({
    required this.dataByDate,
    required this.goal,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Column(
      children: List.generate(4, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            children: List.generate(7, (col) {
              // day 0 = oldest (27 days ago), day 27 = today
              final dayOffset = 27 - (row * 7 + col);
              final day = DateTime(
                  now.year, now.month, now.day - dayOffset);
              final key =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final value = dataByDate[key] ?? 0;
              final progress = goal > 0 ? (value / goal).clamp(0.0, 1.5) : 0.0;
              final isToday = dayOffset == 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: Duration(
                        milliseconds:
                            400 + (row * 7 + col) * 20),
                    curve: Curves.easeOut,
                    builder: (_, v, child) => Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: _cellColor(v),
                        borderRadius: BorderRadius.circular(7),
                        border: isToday
                            ? Border.all(
                                color: color.withAlpha(200),
                                width: 2)
                            : null,
                      ),
                      child: progress >= 0.8
                          ? const Center(
                              child: Icon(Icons.check_rounded,
                                  color: Colors.white, size: 13))
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Color _cellColor(double progress) {
    if (progress <= 0) return AppColors.textSecondary.withAlpha(25);
    if (progress < 0.5) return color.withAlpha(50);
    if (progress < 0.8) return color.withAlpha(115);
    if (progress < 1.0) return color.withAlpha(185);
    return color;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}
