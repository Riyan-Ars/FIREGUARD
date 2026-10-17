import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  /// Determine the appropriate backend gateway URL according to the current runtime platform.
  /// - Android Emulator: 10.0.2.2 points to host loopback
  /// - Flutter Web / macOS / Windows / Linux: localhost
  /// - Android Physical Device over Wi-Fi: development machine LAN IP
  static String get defaultBaseUrl {
    // Check if custom environment override was passed via --dart-define=API_URL=...
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android Emulator uses 10.0.2.2 to access the host development machine
        return 'http://10.0.2.2:3000/api/v1';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000/api/v1';
    }
  }

  static const Duration requestTimeout = Duration(seconds: 10);
  static const int maxRetries = 2;
}
