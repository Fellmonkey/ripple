import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
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
          create: (context) {
            final authBloc = context.read<AuthBloc>();
            final gratitudeBloc = sl<GratitudeBloc>();
            
            // Listen to auth state changes to reload gratitudes with userId
            authBloc.stream.listen((authState) {
              if (authState is Authenticated) {
                gratitudeBloc.add(LoadGratitudes(currentUserId: authState.user.$id));
              } else {
                gratitudeBloc.add(const LoadGratitudes());
              }
            });
            
            // Initial load
            final currentState = authBloc.state;
            if (currentState is Authenticated) {
              gratitudeBloc.add(LoadGratitudes(currentUserId: currentState.user.$id));
            } else {
              gratitudeBloc.add(const LoadGratitudes());
            }
            
            return gratitudeBloc;
          },
        ),
      ],
      child: child,
    );
  }
}
