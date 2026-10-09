enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.checking,
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
  });

  final AuthStatus status;
  final bool isLoading;

  /// Error key: 'invalid_credentials', 'email_taken', or 'generic'.
  final String? error;

  /// Field-level validation errors keyed by lowercase field name.
  final Map<String, String> fieldErrors;

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? error,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
