import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      if (kIsWeb) {
        // Use relative URL on web to bypass any domain or CORS redirect issues
        return '/api';
      }
      // Production URL for mobile app deployment (Vercel)
      return 'https://diuconnect.vercel.app/api';
    } else {
      // Development URL
      if (kIsWeb) {
        return 'http://localhost:3000/api';
      } else if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:3000/api';
      } else {
        return 'http://localhost:3000/api';
      }
    }
  }
}
