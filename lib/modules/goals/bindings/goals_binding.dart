import 'package:get/get.dart';
import 'package:tracking/modules/goals/controllers/goals_controller.dart';

class GoalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GoalsController>(() => GoalsController());
  }
}
