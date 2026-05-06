import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppUtils {
  static void showError(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      message,
      titleText: const SizedBox.shrink(),
      messageText: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE53E3E),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      borderRadius: 14,
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static void showSuccess(String message) {
    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      message,
      titleText: const SizedBox.shrink(),
      messageText: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF22C55E),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      borderRadius: 14,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
