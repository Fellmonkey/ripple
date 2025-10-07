import 'dart:async';
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
class AppProviders extends StatefulWidget {
  final Widget child;

  const AppProviders({
    required this.child, 
    super.key,
  });

  @override
  State<AppProviders> createState() => _AppProvidersState();
}

class _AppProvidersState extends State<AppProviders> {
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastLoadedUserId;

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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
            // Only reload when userId actually changes
            _authSubscription = authBloc.stream.listen((authState) {
              final userId = authState is Authenticated ? authState.user.$id : null;
              
              // Only reload if userId changed (avoid duplicate loads)
              if (userId != _lastLoadedUserId) {
                _lastLoadedUserId = userId;
                gratitudeBloc.add(LoadGratitudes(currentUserId: userId));
              }
            });
            
            // Initial load
            final currentState = authBloc.state;
            final initialUserId = currentState is Authenticated ? currentState.user.$id : null;
            _lastLoadedUserId = initialUserId;
            gratitudeBloc.add(LoadGratitudes(currentUserId: initialUserId));
            
            return gratitudeBloc;
          },
        ),
      ],
      child: widget.child,
    );
  }
}
