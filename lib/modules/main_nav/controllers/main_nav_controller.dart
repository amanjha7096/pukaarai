import 'package:get/get.dart';

class MainNavController extends GetxController {
  final currentIndex = 0.obs;

  void changeIndex(int index) => currentIndex.value = index;
}
