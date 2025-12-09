import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/auth_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final success = await ref.read(authServiceProvider).authenticate();

    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        widget.onUnlock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Cream background
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.pastelRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  size: 64,
                  color: AppColors.pastelRed,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'App Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please authenticate to continue',
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _authenticate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pastelRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
