import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/appwrite_service.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Appwrite service (creates client and services internally)
  final appwriteService = AppwriteService();
  appwriteService.initialize();
  sl.registerLazySingleton<AppwriteService>(() => appwriteService);
}
