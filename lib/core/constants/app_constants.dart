/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Ripple';
  static const String appVersion = '0.1.0';

  // Shared preferences keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguageCode = 'language_code';
  static const String keyUserId = 'user_id';

  // Gratitude categories
  static const List<String> categories = [
    'MEDICINE',
    'EDUCATION',
    'TRANSPORT',
    'HELP',
    'SERVICE',
    'OTHER',
  ];

  // Map settings
  static const (double, double) defaultCenter = (55.7558, 37.6173); // Moscow
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // Pagination
  static const int itemsPerPage = 20;
  static const int maxItemsPerPage = 100;

  // File upload
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  // Text limits
  static const int maxGratitudeTextLength = 500;
  static const int maxHashtagLength = 30;
  static const int maxHashtags = 5;
}
