import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      // Production URL (Vercel deployment)
      return 'https://your-vercel-domain.vercel.app/api';
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
