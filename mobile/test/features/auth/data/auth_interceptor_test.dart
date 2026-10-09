import 'dart:convert';
import 'dart:typed_data';

import 'package:careapp/features/auth/data/auth_interceptor.dart';
import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeStorage extends SecureTokenStorage {
  _FakeStorage({String? access, String? refresh})
      : _access = access,
        _refresh = refresh,
        super(const FlutterSecureStorage());

  String? _access;
  String? _refresh;

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> saveTokens(String a, String r) async {
    _access = a;
    _refresh = r;
  }

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }
}

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ResponseBody _jsonResponse(Map<String, dynamic> body, int status) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );

final _tokensJson = {
  'accessToken': 'new-access-token',
  'accessTokenExpiresAt': '2099-01-01T00:00:00Z',
  'refreshToken': 'new-refresh-token',
  'refreshTokenExpiresAt': '2099-06-01T00:00:00Z',
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AuthInterceptor', () {
    late _FakeStorage storage;
    late bool authFailed;

    setUp(() {
      storage = _FakeStorage();
      authFailed = false;
    });

    Dio _makeDioWithInterceptor({
      required Future<ResponseBody> Function(RequestOptions) testDioAdapter,
      required Future<ResponseBody> Function(RequestOptions) baseDioAdapter,
    }) {
      final baseDio = Dio(BaseOptions(baseUrl: 'http://test'));
      baseDio.httpClientAdapter = _MockAdapter(baseDioAdapter);

      final testDio = Dio(BaseOptions(baseUrl: 'http://test'));
      testDio.interceptors.add(
        AuthInterceptor(
          storage: storage,
          baseDio: baseDio,
          onAuthFailed: () => authFailed = true,
        ),
      );
      testDio.httpClientAdapter = _MockAdapter(testDioAdapter);

      return testDio;
    }

    test('adds Authorization header when an access token is stored', () async {
      storage = _FakeStorage(access: 'my-token');

      RequestOptions? capturedOptions;
      final dio = _makeDioWithInterceptor(
        testDioAdapter: (opts) async {
          capturedOptions = opts;
          return _jsonResponse({}, 200);
        },
        baseDioAdapter: (_) async => _jsonResponse({}, 200),
      );

      await dio.get('/api/me');

      expect(
        capturedOptions?.headers['Authorization'],
        'Bearer my-token',
      );
    });

    test('does not add Authorization header when no token is stored', () async {
      storage = _FakeStorage();

      RequestOptions? capturedOptions;
      final dio = _makeDioWithInterceptor(
        testDioAdapter: (opts) async {
          capturedOptions = opts;
          return _jsonResponse({}, 200);
        },
        baseDioAdapter: (_) async => _jsonResponse({}, 200),
      );

      await dio.get('/api/me');

      expect(capturedOptions?.headers['Authorization'], isNull);
    });

    test('retries with new access token after a successful refresh', () async {
      storage = _FakeStorage(access: 'old-access', refresh: 'old-refresh');

      var baseDioCalls = 0;
      RequestOptions? retryOptions;

      final dio = _makeDioWithInterceptor(
        testDioAdapter: (_) async => _jsonResponse({}, 401),
        baseDioAdapter: (opts) async {
          baseDioCalls++;
          if (opts.path.contains('/auth/refresh')) {
            return _jsonResponse(_tokensJson, 200);
          }
          // retry call
          retryOptions = opts;
          return _jsonResponse({'ok': true}, 200);
        },
      );

      final response = await dio.get('/api/protected');

      expect(response.statusCode, 200);
      expect(baseDioCalls, 2); // refresh + retry
      expect(
        retryOptions?.headers['Authorization'],
        'Bearer new-access-token',
      );
      expect(storage._access, 'new-access-token');
      expect(storage._refresh, 'new-refresh-token');
      expect(authFailed, isFalse);
    });

    test('clears tokens and calls onAuthFailed when refresh itself returns 401',
        () async {
      storage = _FakeStorage(access: 'old-access', refresh: 'old-refresh');

      final dio = _makeDioWithInterceptor(
        testDioAdapter: (_) async => _jsonResponse({}, 401),
        baseDioAdapter: (_) async => _jsonResponse({}, 401),
      );

      await expectLater(
        dio.get('/api/protected'),
        throwsA(isA<DioException>()),
      );

      expect(authFailed, isTrue);
      expect(storage._access, isNull);
      expect(storage._refresh, isNull);
    });

    test('calls onAuthFailed immediately when no refresh token is stored',
        () async {
      storage = _FakeStorage(access: 'old-access');

      final dio = _makeDioWithInterceptor(
        testDioAdapter: (_) async => _jsonResponse({}, 401),
        baseDioAdapter: (_) async => _jsonResponse({}, 200),
      );

      await expectLater(
        dio.get('/api/protected'),
        throwsA(isA<DioException>()),
      );

      expect(authFailed, isTrue);
    });

    test('does not attempt refresh on a request already marked _authRetry',
        () async {
      storage = _FakeStorage(access: 'old-access', refresh: 'old-refresh');

      var baseDioCalls = 0;
      final dio = _makeDioWithInterceptor(
        testDioAdapter: (_) async => _jsonResponse({}, 401),
        baseDioAdapter: (_) async {
          baseDioCalls++;
          return _jsonResponse(_tokensJson, 200);
        },
      );

      await expectLater(
        dio.get(
          '/api/protected',
          options: Options(extra: {'_authRetry': true}),
        ),
        throwsA(isA<DioException>()),
      );

      expect(baseDioCalls, 0);
    });
  });
}
