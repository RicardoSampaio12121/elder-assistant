import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');

/// Base URL of the CareApp API.
///
/// Override at build time with `--dart-define=API_BASE_URL=...`.
/// Defaults to localhost for web/desktop and 10.0.2.2 for Android emulator.
String get apiBaseUrl {
  if (_apiBaseUrlEnv.isNotEmpty) return _apiBaseUrlEnv;
  return kIsWeb ? 'http://localhost:5293' : 'http://10.0.2.2:5293';
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );
  ref.onDispose(dio.close);

  return dio;
});
