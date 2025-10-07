import 'package:equatable/equatable.dart';

/// Base class for all failures
/// 
/// Based on Appwrite error handling:
/// - https://appwrite.io/docs/advanced/platform/response-codes
/// - https://appwrite.io/docs/advanced/platform/error-handling
abstract class Failure extends Equatable {
  /// Original error message from Appwrite (for debugging)
  final String message;
  
  /// Appwrite error type (e.g., 'user_invalid_credentials')
  final String type;
  
  /// HTTP status code (e.g., 400, 401, 404)
  final int code;

  const Failure({
    required this.message,
    required this.type,
    required this.code,
  });

  @override
  List<Object> get props => [message, type, code];

  /// User-friendly error message for display
  String get userMessage;

  @override
  String toString() => '$runtimeType(code: $code, type: $type, message: $message)';
}

/// Platform and general failures
/// 
/// Covers general Appwrite platform errors, project errors, and unknown issues.
class PlatformFailure extends Failure {
  const PlatformFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    // General errors
    if (type.startsWith('general_')) {
      return switch (type) {
        'general_rate_limit_exceeded' => 'Too many requests. Please wait a moment and try again.',
        'general_argument_invalid' => 'Invalid request. Please check your input and try again.',
        'general_query_invalid' => 'Invalid search query. Please adjust and try again.',
        'general_unknown_origin' => 'Access denied. This app is not authorized.',
        'general_access_forbidden' => 'You do not have permission to perform this action.',
        'general_unauthorized_scope' => 'Insufficient permissions for this action.',
        'general_route_not_found' => 'The requested feature is not available.',
        'general_server_error' => 'Server error occurred. Please try again later.',
        'general_service_disabled' => 'This service is temporarily unavailable.',
        'general_not_implemented' => 'This feature is not yet available.',
        _ => 'An unexpected error occurred. Please try again.',
      };
    }

    // Project errors
    if (type.startsWith('project_')) {
      return switch (type) {
        'project_not_found' => 'Project not found. Please contact support.',
        'project_provider_disabled' => 'This sign-in method is currently disabled.',
        'project_already_exists' => 'This project already exists.',
        _ => 'Project configuration error. Please contact support.',
      };
    }

    return 'An unexpected error occurred. Please try again.';
  }
}

/// Authentication and user management failures
/// 
/// Covers user, team, and membership errors.
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    // User account errors
    if (type.startsWith('user_')) {
      return switch (type) {
        'user_invalid_credentials' => 'Invalid email or password. Please try again.',
        'user_blocked' => 'Your account has been suspended. Please contact support.',
        'user_unauthorized' => 'You are not authorized to perform this action.',
        'user_not_found' => 'No account found. Please check your credentials.',
        'user_already_exists' => 'An account with this information already exists.',
        'user_email_already_exists' => 'This email is already registered. Try signing in.',
        'user_phone_already_exists' => 'This phone number is already registered.',
        'user_session_not_found' => 'Your session has expired. Please sign in again.',
        'user_jwt_invalid' => 'Session is invalid. Please sign in again.',
        'user_invalid_token' => 'Invalid verification token. Please try again.',
        'user_password_mismatch' => 'Passwords do not match.',
        'user_password_reset_required' => 'Password reset required. Check your email.',
        'user_oauth2_unauthorized' => 'OAuth authorization failed. Please try again.',
        'user_oauth2_provider_error' => 'Sign-in provider error. Please try again.',
        'user_count_exceeded' => 'User limit reached. Please contact support.',
        'user_auth_method_unsupported' => 'This sign-in method is not supported.',
        _ => 'Authentication failed. Please try again.',
      };
    }

    // Password errors
    if (type.startsWith('password_')) {
      return switch (type) {
        'password_recently_used' => 'Please choose a different password.',
        'password_personal_data' => 'Password cannot contain personal information.',
        _ => 'Password error. Please choose a different password.',
      };
    }

    // Team errors
    if (type.startsWith('team_')) {
      return switch (type) {
        'team_not_found' => 'Team not found.',
        'team_invalid_secret' => 'Invalid team invitation code.',
        'team_invite_already_exists' => 'You are already invited to this team.',
        'team_already_exists' => 'Team already exists.',
        _ => 'Team error. Please try again.',
      };
    }

    // Membership errors
    if (type.startsWith('membership_')) {
      return switch (type) {
        'membership_not_found' => 'Membership not found.',
        'membership_already_confirmed' => 'Membership already confirmed.',
        _ => 'Membership error. Please try again.',
      };
    }

    return 'Authentication failed. Please try again.';
  }
}

/// Database operation failures
/// 
/// Covers database, table, row, column, and index errors.
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    // Database level
    if (type.startsWith('database_')) {
      return switch (type) {
        'database_not_found' => 'Database not found.',
        'database_already_exists' => 'Database already exists.',
        _ => 'Database error occurred.',
      };
    }

    // Table level
    if (type.startsWith('table_')) {
      return switch (type) {
        'table_not_found' => 'The requested data could not be found.',
        'table_already_exists' => 'This data already exists.',
        'table_limit_exceeded' => 'Database table limit reached.',
        _ => 'Database table error.',
      };
    }

    // Row level
    if (type.startsWith('row_')) {
      return switch (type) {
        'row_not_found' => 'Record not found.',
        'row_already_exists' => 'This record already exists.',
        'row_delete_restricted' => 'Cannot delete: record is in use.',
        'row_invalid_structure' => 'Invalid data structure.',
        'row_missing_data' => 'Required fields are missing.',
        'row_update_conflict' => 'Data conflict: record was modified.',
        _ => 'Database record error.',
      };
    }

    // Column level
    if (type.startsWith('column_')) {
      return switch (type) {
        'column_not_found' => 'Data field not found.',
        'column_already_exists' => 'Field already exists.',
        'column_value_invalid' => 'Invalid field value.',
        'column_limit_exceeded' => 'Field limit exceeded.',
        _ => 'Database field error.',
      };
    }

    // Index level
    if (type.startsWith('index_')) {
      return switch (type) {
        'index_not_found' => 'Index not found.',
        'index_already_exists' => 'Index already exists.',
        'index_limit_exceeded' => 'Index limit exceeded.',
        _ => 'Database index error.',
      };
    }

    return 'A database error occurred. Please try again.';
  }
}

/// Storage and file operation failures
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    return switch (type) {
      'storage_file_not_found' => 'File not found.',
      'storage_bucket_not_found' => 'Storage location not found.',
      'storage_file_empty' => 'Please select a valid file.',
      'storage_file_type_unsupported' => 'File type not supported.',
      'storage_invalid_file_size' => 'File size is invalid or too large.',
      'storage_invalid_content_range' => 'Invalid file range.',
      'storage_invalid_file' => 'Invalid file. Please try another.',
      'storage_file_already_exists' => 'File already exists.',
      'storage_bucket_already_exists' => 'Storage bucket already exists.',
      'storage_invalid_range' => 'Invalid file range.',
      'storage_device_not_found' => 'Storage device not found.',
      _ => 'File operation failed. Please try again.',
    };
  }
}

/// Cloud function execution failures
class FunctionFailure extends Failure {
  const FunctionFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    return switch (type) {
      'function_not_found' => 'Function not found.',
      'function_runtime_unsupported' => 'Function runtime not supported.',
      'build_not_ready' => 'Function build not ready. Please try again.',
      'build_in_progress' => 'Function build in progress. Please wait.',
      'build_not_found' => 'Function build not found.',
      'deployment_not_found' => 'Function deployment not found.',
      'variable_not_found' => 'Function variable not found.',
      'variable_already_exists' => 'Function variable already exists.',
      'installation_not_found' => 'VCS installation not found.',
      'repository_not_found' => 'Repository not found.',
      'provider_repository_not_found' => 'VCS repository not found.',
      _ => 'Function execution failed. Please try again.',
    };
  }
}


/// Network and connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    return switch (code) {
      429 => 'Too many requests. Please wait before trying again.',
      500 => 'Server error. Please try again later.',
      503 => 'Service temporarily unavailable. Please try again later.',
      504 => 'Request timeout. Please check your connection.',
      _ => 'Network error. Please check your connection.',
    };
  }
}

/// Input validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    required super.type,
    required super.code,
  });

  @override
  String get userMessage {
    return switch (type) {
      'general_argument_invalid' => 'Invalid input. Please check and try again.',
      'general_query_invalid' => 'Invalid query. Please adjust and try again.',
      'validation_format_error' => 'Invalid data format.',
      'validation_type_error' => 'Invalid data type.',
      _ => 'Please check your input and try again.',
    };
  }
}
