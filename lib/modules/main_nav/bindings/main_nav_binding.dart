import 'package:get/get.dart';
import 'package:tracking/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:tracking/modules/goals/bindings/goals_binding.dart';
import 'package:tracking/modules/history/bindings/history_binding.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';
import 'package:tracking/modules/profile/bindings/profile_binding.dart';
import 'package:tracking/modules/tracking/bindings/tracking_binding.dart';

class MainNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainNavController>(() => MainNavController());
    DashboardBinding().dependencies();
    GoalsBinding().dependencies();
    TrackingBinding().dependencies();
    HistoryBinding().dependencies();
    ProfileBinding().dependencies();
  }
}
