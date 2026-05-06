import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/core/controllers/theme_controller.dart';
import 'package:tracking/core/theme/app_theme.dart';
import 'package:tracking/firebase_options.dart';
import 'package:tracking/routes/app_pages.dart';
import 'package:tracking/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();

  // Register ThemeController before runApp so the toggle is accessible globally
  Get.put(ThemeController());

  // Read stored preference to pass as the initial theme mode
  final isDark = GetStorage().read<bool>(ThemeController.storageKey) ?? false;

  runApp(TrackingApp(initialThemeMode: isDark ? ThemeMode.dark : ThemeMode.light));
}

class TrackingApp extends StatelessWidget {
  final ThemeMode initialThemeMode;

  const TrackingApp({super.key, required this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: initialThemeMode,
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
      ),
    );
  }
}
