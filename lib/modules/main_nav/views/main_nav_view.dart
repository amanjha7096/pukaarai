import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/modules/dashboard/views/dashboard_view.dart';
import 'package:tracking/modules/goals/views/goals_view.dart';
import 'package:tracking/modules/history/views/history_view.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';
import 'package:tracking/modules/profile/views/profile_view.dart';
import 'package:tracking/modules/tracking/views/tracking_view.dart';

class MainNavView extends GetView<MainNavController> {
  const MainNavView({super.key});

  // index: 0=Dashboard, 1=Goals, 2=Tracking, 3=History, 4=Profile
  static const _pages = [
    DashboardView(),
    GoalsView(),
    TrackingView(),
    HistoryView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: controller.currentIndex.value,
            children: _pages,
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeIndex,
          ),
        ));
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavIcon(
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavIcon(
              icon: Icons.emoji_events_rounded,
              label: 'Goals',
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap),
          _GoButton(isActive: currentIndex == 2, onTap: () => onTap(2)),
          _NavIcon(
              icon: Icons.bar_chart_rounded,
              label: 'History',
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavIcon(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              index: 4,
              currentIndex: currentIndex,
              onTap: onTap),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated indicator bar above the icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: selected ? 22 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedScale(
              scale: selected ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 10,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Roboto',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// Floating GO button with pulsing glow — navigates to Tracking (index 2)
class _GoButton extends StatefulWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _GoButton({required this.isActive, required this.onTap});

  @override
  State<_GoButton> createState() => _GoButtonState();
}

class _GoButtonState extends State<_GoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) => Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withAlpha(
                    (55 + _glowAnim.value * 65).toInt(),
                  ),
                  blurRadius: 14 + _glowAnim.value * 10,
                  spreadRadius: _glowAnim.value * 3,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
          child: Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primaryLight],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                'GO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
