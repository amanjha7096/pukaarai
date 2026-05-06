import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:tracking/core/utils/app_utils.dart';
import 'package:tracking/data/services/firebase_service.dart';
import 'package:tracking/routes/app_routes.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final email = ''.obs;
  final password = ''.obs;
  final name = ''.obs;
  final passwordVisible = false.obs;

  void togglePasswordVisibility() =>
      passwordVisible.value = !passwordVisible.value;

  @override
  void onReady() {
    super.onReady();
    FirebaseService.auth.authStateChanges().listen((user) {
      final route = Get.currentRoute;
      if (user == null) {
        // Redirect to login from any protected screen on session expiry
        if (route != AppRoutes.login &&
            route != AppRoutes.register &&
            route != AppRoutes.splash) {
          Get.offAllNamed(AppRoutes.login);
        } else if (route == AppRoutes.splash) {
          Get.offAllNamed(AppRoutes.login);
        }
      } else if (route == AppRoutes.splash) {
        Get.offAllNamed(AppRoutes.home);
      }
    });
  }

  Future<void> login() async {
    final trimmedEmail = email.value.trim();
    if (trimmedEmail.isEmpty || password.value.isEmpty) {
      AppUtils.showError('Please fill in all fields');
      return;
    }
    if (!GetUtils.isEmail(trimmedEmail)) {
      AppUtils.showError('Enter a valid email address');
      return;
    }
    if (password.value.length < 6) {
      AppUtils.showError('Password must be at least 6 characters');
      return;
    }
    try {
      isLoading.value = true;
      await FirebaseService.auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password.value,
      );
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      AppUtils.showError(_friendlyAuthError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    final trimmedName = name.value.trim();
    final trimmedEmail = email.value.trim();
    if (trimmedName.isEmpty) {
      AppUtils.showError('Please enter your name');
      return;
    }
    if (trimmedEmail.isEmpty || password.value.isEmpty) {
      AppUtils.showError('Please fill in all fields');
      return;
    }
    if (!GetUtils.isEmail(trimmedEmail)) {
      AppUtils.showError('Enter a valid email address');
      return;
    }
    if (password.value.length < 6) {
      AppUtils.showError('Password must be at least 6 characters');
      return;
    }
    try {
      isLoading.value = true;
      final cred = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password.value,
      );
      await cred.user?.updateDisplayName(trimmedName);
      Get.offAllNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      AppUtils.showError(_friendlyAuthError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await FirebaseService.auth.signOut();
    Get.offAllNamed(AppRoutes.login);
  }

  // Convert Firebase error codes to user-friendly messages
  String _friendlyAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Something went wrong. Please try again';
    }
  }
}
