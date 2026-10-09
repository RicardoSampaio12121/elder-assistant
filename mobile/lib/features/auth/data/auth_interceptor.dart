import 'package:dio/dio.dart';

import 'contracts/auth_tokens_response.dart';
import 'secure_token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureTokenStorage storage,
    required Dio baseDio,
    required void Function() onAuthFailed,
  })  : _storage = storage,
        _baseDio = baseDio,
        _onAuthFailed = onAuthFailed;

  final SecureTokenStorage _storage;
  final Dio _baseDio;
  final void Function() _onAuthFailed;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra.containsKey('_authRetry')) {
      handler.next(err);
      return;
    }

    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      _onAuthFailed();
      handler.next(err);
      return;
    }

    try {
      final refreshResponse = await _baseDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = AuthTokensResponse.fromJson(refreshResponse.data!);
      await _storage.saveTokens(tokens.accessToken, tokens.refreshToken);

      final retryOptions = err.requestOptions.copyWith(
        headers: {
          ...err.requestOptions.headers,
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
        extra: {
          ...err.requestOptions.extra,
          '_authRetry': true,
        },
      );
      final retryResponse = await _baseDio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _storage.clearTokens();
      _onAuthFailed();
      handler.next(err);
    }
  }
}
