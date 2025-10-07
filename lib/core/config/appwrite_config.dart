import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppwriteConfig {
  AppwriteConfig._();

  static String get endpoint => dotenv.env['APPWRITE_ENDPOINT'] ?? 'http://localhost/v1';
  static String get projectId => dotenv.env['APPWRITE_PROJECT_ID'] ?? 'YOUR_PROJECT_ID';
  static String get databaseId => dotenv.env['APPWRITE_DATABASE_ID'] ?? 'ripple_db';

  // Tables
  static const String gratitudesCollectionId = 'gratitudes';
  static const String userLikesCollectionId = 'user_likes';
  static const String achievementsDefinitionsCollectionId = 'achievements_definitions';
  static const String userAchievementsCollectionId = 'user_achievements';

  // Storage
  static String get photosBucketId => dotenv.env['APPWRITE_PHOTOS_BUCKET'] ?? 'photos';
}
