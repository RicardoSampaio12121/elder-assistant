import 'package:careapp/app.dart';
import 'package:careapp/core/network/api_client.dart';
import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:careapp/features/auth/presentation/auth_notifier.dart';
import 'package:careapp/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_secure_token_storage.dart';

class _UnauthenticatedNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);
}

void main() {
  testWidgets('unauthenticated user lands on the login screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureTokenStorageProvider
              .overrideWithValue(FakeSecureTokenStorage()),
          authNotifierProvider
              .overrideWith(_UnauthenticatedNotifier.new),
        ],
        child: const CareApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
  });

  test('dio is configured with the API base URL', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dio = container.read(dioProvider);

    expect(dio.options.baseUrl, apiBaseUrl);
  });
}
