import 'package:appwrite/models.dart' as models;
import '../../../../core/error/models/result.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Create anonymous session for the user
  Future<Result<models.User>> createAnonymousSession();
  
  /// Get current authenticated user
  Future<Result<models.User>> getCurrentUser();
  
  /// Check if user has active session
  Future<Result<bool>> hasActiveSession();
  
  /// Logout (delete current session)
  Future<Result<void>> logout();
}
