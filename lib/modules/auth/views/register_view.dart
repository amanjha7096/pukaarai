import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tracking/core/constants/app_constants.dart';
import 'package:tracking/modules/auth/controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final AuthController _ctrl;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<AuthController>();
    // Reset stale controller state so the UI and observables stay in sync
    _ctrl.name.value = '';
    _ctrl.email.value = '';
    _ctrl.password.value = '';
    _ctrl.passwordVisible.value = false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Full Name'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (v) => _ctrl.name.value = v,
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        prefixIcon: Icon(Icons.person_outline,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Email'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (v) => _ctrl.email.value = v,
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Password'),
                    const SizedBox(height: 8),
                    Obx(() => TextField(
                          controller: _passCtrl,
                          obscureText: !_ctrl.passwordVisible.value,
                          onChanged: (v) => _ctrl.password.value = v,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline,
                                color: AppColors.textSecondary, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: _ctrl.togglePasswordVisibility,
                              child: Icon(
                                _ctrl.passwordVisible.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        )),
                    const SizedBox(height: 32),
                    Obx(() => ElevatedButton(
                          onPressed:
                              _ctrl.isLoading.value ? null : _ctrl.register,
                          child: _ctrl.isLoading.value
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Create Account'),
                        )),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14)),
                        GestureDetector(
                          onTap: Get.back,
                          child: const Text('Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 52, 28, 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(height: 22),
          const Text('Create\nAccount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              )),
          const SizedBox(height: 8),
          Text('Start your health journey today',
              style:
                  TextStyle(color: Colors.white.withAlpha(204), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600));
}
