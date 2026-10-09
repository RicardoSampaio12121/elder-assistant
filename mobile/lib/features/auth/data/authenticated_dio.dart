import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../presentation/auth_notifier.dart';
import 'auth_interceptor.dart';
import 'secure_token_storage.dart';

/// Dio instance that injects the Bearer token and handles 401 → refresh.
///
/// Use this provider for any endpoint that requires authentication.
/// Auth endpoints (login / register / refresh) use [dioProvider] directly.
final authenticatedDioProvider = Provider<Dio>((ref) {
  final baseDio = ref.read(dioProvider);
  final storage = ref.read(secureTokenStorageProvider);

  final dio = Dio(baseDio.options);
  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      baseDio: baseDio,
      onAuthFailed: () =>
          ref.read(authNotifierProvider.notifier).onTokensExpired(),
    ),
  );
  ref.onDispose(dio.close);

  return dio;
});
