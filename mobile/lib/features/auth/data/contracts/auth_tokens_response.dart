import '../../domain/auth_tokens.dart';

class AuthTokensResponse {
  const AuthTokensResponse({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;

  factory AuthTokensResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokensResponse(
      accessToken: json['accessToken'] as String,
      accessTokenExpiresAt: DateTime.parse(json['accessTokenExpiresAt'] as String),
      refreshToken: json['refreshToken'] as String,
      refreshTokenExpiresAt: DateTime.parse(json['refreshTokenExpiresAt'] as String),
    );
  }

  AuthTokens toDomain() => AuthTokens(
        accessToken: accessToken,
        accessTokenExpiresAt: accessTokenExpiresAt,
        refreshToken: refreshToken,
        refreshTokenExpiresAt: refreshTokenExpiresAt,
      );
}
