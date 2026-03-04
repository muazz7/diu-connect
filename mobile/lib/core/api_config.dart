import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Use relative URL on web to bypass any domain or CORS redirect issues
      return '/api';
    }

    // For mobile (Android/iOS), always use the live Vercel backend
    // for both debug testing and production release
    return 'https://diuconnect.vercel.app/api';
  }
}
