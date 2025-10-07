import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/gratitude/presentation/bloc/gratitude_bloc.dart';
import '../../features/gratitude/presentation/bloc/gratitude_event.dart';
import '../di/injection_container.dart';

/// Global BLoC providers for the application
/// 
/// Provides application-wide state management including:
/// - AuthBloc: User authentication state
/// - GratitudeBloc: Gratitude data management
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({
    required this.child, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Authentication state
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const CheckAuthStatus()),
        ),
        
        // Gratitude data state
        BlocProvider(
          create: (_) => sl<GratitudeBloc>()..add(const LoadGratitudes()),
        ),
      ],
      child: child,
    );
  }
}
