import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:careapp/features/auth/presentation/auth_notifier.dart';
import 'package:careapp/features/auth/presentation/auth_state.dart';
import 'package:careapp/features/auth/presentation/login_screen.dart';
import 'package:careapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/misc.dart' show Override;

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
  String? capturedEmail;
  String? capturedPassword;

  @override
  AuthState build() => _initial;

  @override
  Future<void> login({required String email, required String password}) async {
    capturedEmail = email;
    capturedPassword = password;
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
        routes: [GoRoute(path: '/', builder: (_, _) => const LoginScreen())],
      ),
    ),
  );
}

void main() {
  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(status: AuthStatus.unauthenticated),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
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

    testWidgets('shows invalid-email error for badly formatted e-mail',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(status: AuthStatus.unauthenticated),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('emailField')),
        'not-an-email',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(find.text('Introduza um e-mail válido.'), findsOneWidget);
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
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('submit button is disabled while loading', (tester) async {
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
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('submitButton')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows invalid-credentials error message on 401',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FakeAuthNotifier(
            const AuthState(
              status: AuthStatus.unauthenticated,
              error: 'invalid_credentials',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('E-mail ou palavra-passe incorretos.'),
        findsOneWidget,
      );
    });

    testWidgets('shows generic error message for non-401 errors',
        (tester) async {
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

    testWidgets('valid form submission calls notifier login', (tester) async {
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
        find.byKey(const Key('emailField')),
        'user@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'secret123',
      );
      await tester.tap(find.byKey(const Key('submitButton')));
      await tester.pump();

      expect(spy.capturedEmail, 'user@example.com');
      expect(spy.capturedPassword, 'secret123');
    });
  });
}
