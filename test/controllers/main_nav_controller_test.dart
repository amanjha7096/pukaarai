import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:tracking/modules/main_nav/controllers/main_nav_controller.dart';

void main() {
  late MainNavController ctrl;

  setUp(() {
    Get.testMode = true;
    ctrl = MainNavController();
  });

  tearDown(Get.reset);

  group('MainNavController', () {
    test('initial currentIndex is 0', () {
      expect(ctrl.currentIndex.value, 0);
    });

    test('changeIndex updates currentIndex', () {
      ctrl.changeIndex(3);
      expect(ctrl.currentIndex.value, 3);
    });

    test('changeIndex to last tab (4)', () {
      ctrl.changeIndex(4);
      expect(ctrl.currentIndex.value, 4);
    });

    test('changeIndex back to 0', () {
      ctrl.changeIndex(4);
      ctrl.changeIndex(0);
      expect(ctrl.currentIndex.value, 0);
    });

    test('changeIndex is reactive via ever()', () {
      final seen = <int>[];
      ever(ctrl.currentIndex, seen.add);

      ctrl.changeIndex(1);
      ctrl.changeIndex(3);

      expect(seen, [1, 3]);
    });

    test('multiple changeIndex calls update sequentially', () {
      for (int i = 0; i < 5; i++) {
        ctrl.changeIndex(i);
        expect(ctrl.currentIndex.value, i);
      }
    });
  });
}
