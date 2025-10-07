import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

/// Remote data source for authentication operations
/// 
/// Handles anonymous session creation and management using Appwrite Account service
abstract class AuthRemoteDataSource {
  /// Create anonymous session
  Future<models.User> createAnonymousSession();
  
  /// Get current user session
  Future<models.User> getCurrentUser();
  
  /// Check if user has active session
  Future<bool> hasActiveSession();
  
  /// Delete current session (logout)
  Future<void> deleteSession();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Account account;

  AuthRemoteDataSourceImpl(this.account);

  @override
  Future<models.User> createAnonymousSession() async {
    await account.createAnonymousSession();
    return account.get();
  }

  @override
  Future<models.User> getCurrentUser() async {
    return account.get();
  }

  @override
  Future<bool> hasActiveSession() async {
    try {
      await account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> deleteSession() async {
    await account.deleteSession(sessionId: 'current');
  }
}
