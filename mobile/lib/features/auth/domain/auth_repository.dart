import 'auth_tokens.dart';

abstract class AuthRepository {
  Future<AuthTokens> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  });

  Future<AuthTokens> login({
    required String email,
    required String password,
  });

  Future<AuthTokens> refresh({required String refreshToken});
}
