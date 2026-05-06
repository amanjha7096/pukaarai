import 'package:get/get.dart';
import 'package:tracking/modules/auth/bindings/auth_binding.dart';
import 'package:tracking/modules/auth/views/login_view.dart';
import 'package:tracking/modules/auth/views/register_view.dart';
import 'package:tracking/modules/auth/views/splash_view.dart';
import 'package:tracking/modules/main_nav/bindings/main_nav_binding.dart';
import 'package:tracking/modules/main_nav/views/main_nav_view.dart';
import 'package:tracking/routes/app_routes.dart';

class AppPages {
  static const _duration = Duration(milliseconds: 320);

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const RegisterView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: _duration,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainNavView(),
      bindings: [AuthBinding(), MainNavBinding()],
      transition: Transition.fadeIn,
      transitionDuration: _duration,
    ),
  ];
}
