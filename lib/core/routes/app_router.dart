import 'package:flutter/material.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

/// Application router for navigation
class AppRouter {
  AppRouter._();

  // Route names
  static const String splash = '/';
  static const String home = '/home';
  static const String addGratitude = '/add-gratitude';
  static const String gratitudeDetails = '/gratitude-details';
  static const String achievements = '/achievements';
  static const String settings = '/settings';

  /// Generate routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    switch (routeName) {
      case AppRouter.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case AppRouter.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case AppRouter.addGratitude:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: Implement AddGratitudeScreen
        );
      case AppRouter.gratitudeDetails:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: Implement GratitudeDetailsScreen
        );
      case AppRouter.achievements:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: Implement AchievementsScreen
        );
      case AppRouter.settings:
        return MaterialPageRoute(
          builder: (_) => const Placeholder(), // TODO: Implement SettingsScreen
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
