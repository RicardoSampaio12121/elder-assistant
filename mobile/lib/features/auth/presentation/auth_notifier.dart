import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_impl.dart';
import '../data/secure_token_storage.dart';
import 'auth_state.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_checkAuthStatus);
    return const AuthState();
  }

  Future<void> _checkAuthStatus() async {
    final token = await ref.read(secureTokenStorageProvider).getAccessToken();
    state = AuthState(
      status: token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, fieldErrors: {});
    try {
      await ref.read(authRepositoryProvider).login(email: email, password: password);
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        state = state.copyWith(isLoading: false, error: 'invalid_credentials');
      } else {
        state = state.copyWith(isLoading: false, error: 'generic');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, fieldErrors: {});
    try {
      await ref.read(authRepositoryProvider).register(
            name: name,
            email: email,
            password: password,
            phoneNumber: phoneNumber,
          );
      state = state.copyWith(isLoading: false, status: AuthStatus.authenticated);
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        state = state.copyWith(isLoading: false, error: 'email_taken');
      } else if (statusCode == 400) {
        final fieldErrors = _parseFieldErrors(e.response?.data);
        state = state.copyWith(isLoading: false, fieldErrors: fieldErrors);
      } else {
        state = state.copyWith(isLoading: false, error: 'generic');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
    }
  }

  Future<void> logout() async {
    await ref.read(secureTokenStorageProvider).clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void onTokensExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Map<String, String> _parseFieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return {};
    final errors = data['errors'];
    if (errors is! Map<String, dynamic>) return {};
    return errors.map((key, value) {
      final messages = value is List ? value : [value];
      return MapEntry(key.toLowerCase(), messages.first.toString());
    });
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
