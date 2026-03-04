// API Configuration

class ApiConfig {
  static String get baseUrl {
    // Always use the absolute live URL for both Web and Mobile
    // This prevents "Unsupported scheme" errors in Flutter web's http package
    // and correctly bypasses the Vercel domain mismatch redirect.
    return 'https://diuconnect.vercel.app/api';
  }
}
