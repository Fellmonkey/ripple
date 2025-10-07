import 'package:flutter/material.dart';
import 'core/app/app_providers.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'assets/.env');

  await initializeDependencies();
  
  runApp(const RippleApp());
}

class RippleApp extends StatelessWidget {
  const RippleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        
        // Theming
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        
        
        // Routing
        onGenerateRoute: AppRouter.onGenerateRoute,
        initialRoute: AppRouter.splash,
      ),
    );
  }
}
