import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:careapp/features/auth/presentation/auth_notifier.dart';
import 'package:careapp/features/auth/presentation/auth_state.dart';
import 'package:careapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'fake_secure_token_storage.dart';

/// Returns a testable [MaterialApp] hosting [screen] at `/`.
///
/// Pass [authState] to preset the auth notifier state, or [overrides] for
/// full provider control.
Widget buildAuthTestApp({
  required Widget screen,
  AuthState authState = const AuthState(status: AuthStatus.unauthenticated),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: [
      secureTokenStorageProvider
          .overrideWithValue(FakeSecureTokenStorage()),
      authNotifierProvider.overrideWith(
        () => _FixedAuthNotifier(authState),
      ),
      ...overrides,
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
        routes: [GoRoute(path: '/', builder: (_, __) => screen)],
      ),
    ),
  );
}

class _FixedAuthNotifier extends AuthNotifier {
  _FixedAuthNotifier(this._fixed);
  final AuthState _fixed;

  @override
  AuthState build() => _fixed;
}
