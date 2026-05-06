import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tracking/core/controllers/theme_controller.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('gs_theme_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => tempDir.path,
    );
    await GetStorage.init();
  });

  tearDownAll(() async {
    try { await tempDir.delete(recursive: true); } catch (_) {}
  });

  setUp(() {
    Get.testMode = true;
    GetStorage().erase();
  });

  tearDown(Get.reset);

  // ── Init behaviour (no widget tree needed) ────────────────────────────────

  group('ThemeController.onInit', () {
    test('isDark defaults to false when storage is empty', () {
      final ctrl = ThemeController()..onInit();
      expect(ctrl.isDark.value, isFalse);
    });

    test('reads stored true preference on init', () {
      GetStorage().write(ThemeController.storageKey, true);
      final ctrl = ThemeController()..onInit();
      expect(ctrl.isDark.value, isTrue);
    });

    test('reads stored false preference on init', () {
      GetStorage().write(ThemeController.storageKey, false);
      final ctrl = ThemeController()..onInit();
      expect(ctrl.isDark.value, isFalse);
    });
  });

  // ── Toggle (requires a mounted GetMaterialApp for Get.changeThemeMode) ────

  group('ThemeController.toggle', () {
    testWidgets('flips isDark from false to true', (tester) async {
      await tester.pumpWidget(
          GetMaterialApp(home: const SizedBox.shrink()));

      final ctrl = Get.put(ThemeController())..onInit();

      ctrl.toggle();

      expect(ctrl.isDark.value, isTrue);
    });

    testWidgets('flips isDark from true to false', (tester) async {
      GetStorage().write(ThemeController.storageKey, true);
      await tester.pumpWidget(
          GetMaterialApp(home: const SizedBox.shrink()));

      final ctrl = Get.put(ThemeController())..onInit();

      ctrl.toggle();

      expect(ctrl.isDark.value, isFalse);
    });

    testWidgets('persists new value to GetStorage', (tester) async {
      await tester.pumpWidget(
          GetMaterialApp(home: const SizedBox.shrink()));

      final ctrl = Get.put(ThemeController())..onInit();

      ctrl.toggle();

      expect(GetStorage().read<bool>(ThemeController.storageKey), isTrue);
    });

    testWidgets('double toggle restores original storage value', (tester) async {
      await tester.pumpWidget(
          GetMaterialApp(home: const SizedBox.shrink()));

      final ctrl = Get.put(ThemeController())..onInit();

      ctrl.toggle();
      ctrl.toggle();

      expect(GetStorage().read<bool>(ThemeController.storageKey), isFalse);
      expect(ctrl.isDark.value, isFalse);
    });
  });
}
