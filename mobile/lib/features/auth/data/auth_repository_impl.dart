import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_tokens.dart';
import 'contracts/auth_tokens_response.dart';
import 'contracts/login_request.dart';
import 'contracts/refresh_token_request.dart';
import 'contracts/register_request.dart';
import 'secure_token_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dio, this._storage);

  final Dio _dio;
  final SecureTokenStorage _storage;

  @override
  Future<AuthTokens> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: RegisterRequest(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      ).toJson(),
    );
    final tokens = AuthTokensResponse.fromJson(response.data!).toDomain();
    await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  @override
  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: LoginRequest(email: email, password: password).toJson(),
    );
    final tokens = AuthTokensResponse.fromJson(response.data!).toDomain();
    await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }

  @override
  Future<AuthTokens> refresh({required String refreshToken}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: RefreshTokenRequest(refreshToken: refreshToken).toJson(),
    );
    final tokens = AuthTokensResponse.fromJson(response.data!).toDomain();
    await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);
    return tokens;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(secureTokenStorageProvider),
  );
});
