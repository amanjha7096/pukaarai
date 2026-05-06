import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const storageKey = 'is_dark_mode';

  final _storage = GetStorage();
  final isDark = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDark.value = _storage.read<bool>(storageKey) ?? false;
  }

  void toggle() {
    isDark.value = !isDark.value;
    _storage.write(storageKey, isDark.value);
    Get.changeThemeMode(isDark.value ? ThemeMode.dark : ThemeMode.light);
  }
}
