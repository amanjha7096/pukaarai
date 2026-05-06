import 'package:get/get.dart';
import 'package:tracking/modules/tracking/controllers/tracking_controller.dart';

class TrackingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TrackingController>(() => TrackingController(), fenix: true);
  }
}
