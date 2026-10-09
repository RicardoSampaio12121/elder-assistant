import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeSecureTokenStorage extends SecureTokenStorage {
  FakeSecureTokenStorage({String? accessToken, String? refreshToken})
      : _accessToken = accessToken,
        _refreshToken = refreshToken,
        super(const FlutterSecureStorage());

  String? _accessToken;
  String? _refreshToken;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _accessToken;

  @override
  Future<String?> getRefreshToken() async => _refreshToken;

  @override
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
