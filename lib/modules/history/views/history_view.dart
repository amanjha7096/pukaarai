import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/data/models/activity_model.dart';
import 'package:tracking/modules/history/controllers/history_controller.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    with SingleTickerProviderStateMixin {
  final _ctrl = Get.find<HistoryController>();
  late AnimationController _fadeAnim;
  bool _showCharts = false;

  static const _filters = [
    ('all', 'All'),
    ('steps', 'Steps'),
    ('water', 'Water'),
    ('calories', 'Calories'),
    ('sleep', 'Sleep'),
    ('heart', 'Heart'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _fadeAnim.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() => _showCharts = !_showCharts);
    _fadeAnim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (!_showCharts) ...[
              _buildFilterChips(),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: _showCharts
                    ? _buildChartsView()
                    : _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Activity History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _ViewToggle(
            icon: Icons.bar_chart_rounded,
            active: _showCharts,
            onTap: () { if (!_showCharts) _toggleView(); },
          ),
          const SizedBox(width: 8),
          _ViewToggle(
            icon: Icons.list_rounded,
            active: !_showCharts,
            onTap: () { if (_showCharts) _toggleView(); },
          ),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: Obx(() => ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: _filters.map((f) {
              final selected = _ctrl.selectedFilter.value == f.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _ctrl.setFilter(f.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(77),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          )),
    );
  }

  // ── Charts view ───────────────────────────────────────────────────────────

  Widget _buildChartsView() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      return FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          key: const ValueKey('charts'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          children: [
            _chartCard(
              title: 'Steps',
              icon: Icons.directions_walk_rounded,
              color: AppColors.primary,
              data: _ctrl.stepsLast7,
              unit: 'steps',
              isLine: true,
            ),
            const SizedBox(height: 16),
            _chartCard(
              title: 'Water Intake',
              icon: Icons.water_drop_rounded,
              color: AppColors.waterBlue,
              data: _ctrl.waterLast7,
              unit: 'ml',
              isLine: false,
            ),
            const SizedBox(height: 16),
            _chartCard(
              title: 'Calories',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.calorieOrange,
              data: _ctrl.caloriesLast7,
              unit: 'kcal',
              isLine: true,
            ),
            const SizedBox(height: 16),
            _chartCard(
              title: 'Sleep',
              icon: Icons.bedtime_rounded,
              color: AppColors.sleepIndigo,
              data: _ctrl.sleepLast7,
              unit: 'h',
              isLine: false,
            ),
          ],
        ),
      );
    });
  }

  Widget _chartCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<double> data,
    required String unit,
    required bool isLine,
  }) {
    String fmtVal(double v) {
      switch (unit) {
        case 'steps':
          return NumberFormat('#,###').format(v.toInt());
        case 'ml':
          return v >= 1000
              ? '${(v / 1000).toStringAsFixed(1)}L'
              : '${v.toInt()} ml';
        case 'kcal':
          return '${v.toStringAsFixed(0)} kcal';
        case 'h':
          final h = v.floor();
          final m = ((v - h) * 60).round();
          return '${h}h ${m}m';
        default:
          return v.toStringAsFixed(1);
      }
    }

    final nonZero = data.where((v) => v > 0).toList();
    final total = nonZero.fold(0.0, (s, v) => s + v);
    final peak = nonZero.isEmpty ? 0.0 : nonZero.reduce(max);
    final activeDays = nonZero.length;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Last 7 days',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: isLine
                  ? _lineChart(data, color, fmtVal)
                  : _barChart(data, color, fmtVal),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _statBadge('Total', fmtVal(total), color),
                const SizedBox(width: 10),
                _statBadge('Peak', fmtVal(peak), color),
                const SizedBox(width: 10),
                _statBadge('Active', '$activeDays / 7 days', color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineChart(
    List<double> data,
    Color color,
    String Function(double) fmt,
  ) {
    final hasData = data.any((v) => v > 0);
    final maxVal = hasData ? data.reduce(max) : 1.0;
    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxVal * 1.25,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary.withAlpha(220),
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((s) => LineTooltipItem(
                      fmt(s.y),
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= 7) return const SizedBox();
                final day =
                    DateTime.now().subtract(Duration(days: 6 - idx));
                return Text(
                  DateFormat('E').format(day).substring(0, 1),
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.dividerColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, xPct, barData, index) {
                if (spot.y == 0) {
                  return FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  );
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withAlpha(55), color.withAlpha(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barChart(
    List<double> data,
    Color color,
    String Function(double) fmt,
  ) {
    final maxVal = data.any((v) => v > 0) ? data.reduce(max) : 1.0;

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.25,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary.withAlpha(220),
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
              fmt(rod.toY),
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 20,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= 7) return const SizedBox();
                final day =
                    DateTime.now().subtract(Duration(days: 6 - idx));
                return Text(
                  DateFormat('E').format(day).substring(0, 1),
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.dividerColor, strokeWidth: 1),
        ),
        barGroups: data
            .asMap()
            .entries
            .map((e) => BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value,
                      color: e.value > 0 ? color : color.withAlpha(35),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  // ── List view ─────────────────────────────────────────────────────────────

  Widget _buildList() {
    return Obx(() {
      if (_ctrl.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.primary));
      }
      final grouped = _ctrl.groupedByDate;
      final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

      if (keys.isEmpty) {
        return Center(
          key: const ValueKey('empty'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded,
                  size: 64,
                  color: AppColors.textSecondary.withAlpha(128)),
              const SizedBox(height: 12),
              Text('No activity recorded yet',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15)),
            ],
          ),
        );
      }

      return RefreshIndicator(
        key: const ValueKey('list'),
        onRefresh: _ctrl.loadHistory,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: keys.length,
          itemBuilder: (context, i) {
            final dateKey = keys[i];
            final items = grouped[dateKey]!;
            return _AnimatedItem(
              index: i,
              child: _DateGroup(
                dateKey: dateKey,
                items: items,
                onDelete: _ctrl.deleteActivity,
              ),
            );
          },
        ),
      );
    });
  }
}

// ── View toggle button ────────────────────────────────────────────────────────

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ViewToggle({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 18,
            color: active ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}

// ── Staggered item animation ──────────────────────────────────────────────────

class _AnimatedItem extends StatefulWidget {
  final Widget child;
  final int index;

  const _AnimatedItem({required this.child, required this.index});

  @override
  State<_AnimatedItem> createState() => _AnimatedItemState();
}

class _AnimatedItemState extends State<_AnimatedItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    final delay = widget.index < 6 ? widget.index * 65 : 0;
    if (delay == 0) {
      _ctrl.forward();
    } else {
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
        child: widget.child,
      ),
    );
  }
}

// ── Date group ────────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  final String dateKey;
  final List<ActivityModel> items;
  final Future<void> Function(String) onDelete;

  const _DateGroup({
    required this.dateKey,
    required this.items,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(dateKey);
    final isToday =
        dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final label =
        isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isToday ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                return _ActivityRow(
                  item: entry.value,
                  isLast: isLast,
                  onDelete: onDelete,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity row ──────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final ActivityModel item;
  final bool isLast;
  final Future<void> Function(String) onDelete;

  const _ActivityRow({
    required this.item,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config(item.type);
    final valueStr = _formatValue(item.type, item.value);
    final time = DateFormat('h:mm a').format(item.createdAt);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.deleteSurface,
          borderRadius: isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(16))
              : BorderRadius.zero,
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Color(0xFFE53E3E), size: 22),
      ),
      onDismissed: (_) => onDelete(item.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: AppColors.dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cfg.color.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cfg.icon, color: cfg.color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cfg.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (item.note != null && item.note!.isNotEmpty)
                    Text(
                      item.note!,
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valueStr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cfg.color,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _TypeConfig _config(String type) {
    switch (type) {
      case 'steps':
        return _TypeConfig(
            icon: Icons.directions_walk_rounded,
            color: AppColors.primary,
            label: 'Steps');
      case 'water':
        return _TypeConfig(
            icon: Icons.water_drop_rounded,
            color: AppColors.waterBlue,
            label: 'Water');
      case 'calories':
        return _TypeConfig(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.calorieOrange,
            label: 'Calories');
      case 'sleep':
        return _TypeConfig(
            icon: Icons.bedtime_rounded,
            color: AppColors.sleepIndigo,
            label: 'Sleep');
      case 'heart':
        return _TypeConfig(
            icon: Icons.favorite_rounded,
            color: AppColors.heartPink,
            label: 'Heart Rate');
      default:
        return _TypeConfig(
            icon: Icons.circle,
            color: AppColors.textSecondary,
            label: type);
    }
  }

  String _formatValue(String type, double value) {
    switch (type) {
      case 'steps':
        return '${value.toInt()} steps';
      case 'water':
        return '${value.toInt()} ml';
      case 'calories':
        return '${value.toStringAsFixed(0)} kcal';
      case 'sleep':
        final h = value.floor();
        final m = ((value - h) * 60).round();
        return '${h}h ${m}m';
      case 'heart':
        return '${value.toInt()} bpm';
      default:
        return value.toString();
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig(
      {required this.icon, required this.color, required this.label});
}
