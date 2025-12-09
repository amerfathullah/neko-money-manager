import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      // Using minimal parameters compatible with local_auth 2.0.0 - 2.1.1
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
      );
    } on PlatformException catch (_) {
      // If error occurs (e.g. no hardware), return false
      return false;
    }
  }
}
