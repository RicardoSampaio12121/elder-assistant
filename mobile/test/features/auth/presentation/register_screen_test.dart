import 'package:careapp/features/auth/presentation/auth_notifier.dart';
import 'package:careapp/features/auth/presentation/auth_state.dart';
import 'package:careapp/features/auth/presentation/register_screen.dart';
import 'package:careapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_secure_token_storage.dart';

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  AuthState build() => _state;
}

class _SpyAuthNotifier extends AuthNotifier {
  _SpyAuthNotifier(this._initial);

  final AuthState _initial;
  String? capturedName;
  String? capturedEmail;
  String? capturedPassword;
  String? capturedPhone;

  @override
  AuthState build() => _initial;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    capturedName = name;
    capturedEmail = email;
    capturedPassword = password;
    capturedPhone = phoneNumber;
    state = state.copyWith(isLoading: true);
  }
}

Widget _buildApp(
  AuthNotifier Function() notifierFactory, {
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      secureTokenStorageProvider
          .overrideWithValue(FakeSecureTokenStorage()),
      authNotifierProvider.overrideWith(notifierFactory),
      ...extra,
    ],
    child: MaterialApp.router(
      locale: const Locale('pt', 'PT'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (_, __) => const RegisterScreen())],
      ),
    ),
  );
}

void main() {
  group('RegisterScreen', () {
    testWidgets('renders all required fields', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(status: AuthStatus.unauthenticated),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nameField')), findsOneWidget);
      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byKey(const Key('phoneField')), findsOneWidget);
      expect(find.byKey(const Key('submitButton')), findsOneWidget);
    });

    testWidgets('shows required-field error when submitting empty form',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(status: AuthStatus.unauthenticated),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Campo obrigatório.'), findsWidgets);
    });

    testWidgets('shows password-too-short error for short password',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(status: AuthStatus.unauthenticated),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('nameField')), 'Alice');
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'alice@example.com',
      );
      await tester.enterText(find.byKey(const Key('passwordField')), 'short');
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(
        find.text('A palavra-passe deve ter pelo menos 8 caracteres.'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator while request is in flight',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.unauthenticated,
              isLoading: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows email-taken error message on 409', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.unauthenticated,
              error: 'email_taken',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Este e-mail já está registado.'), findsOneWidget);
    });

    testWidgets('shows generic error message on other failures', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.unauthenticated,
              error: 'generic',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ocorreu um erro. Tente novamente.'), findsOneWidget);
    });

    testWidgets('valid form submission calls notifier register', (tester) async {
      late _SpyAuthNotifier spy;
      await tester.pumpWidget(
        _buildApp(() {
          spy = _SpyAuthNotifier(
            const AuthState(status: AuthStatus.unauthenticated),
          );
          return spy;
        }),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('nameField')),
        'Alice Silva',
      );
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'alice@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'securepass',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(spy.capturedName, 'Alice Silva');
      expect(spy.capturedEmail, 'alice@example.com');
      expect(spy.capturedPassword, 'securepass');
    });

    testWidgets('field-level error is shown for 400 response', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.unauthenticated,
              fieldErrors: {'email': 'Este e-mail já está em uso.'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
    });
  });
}
