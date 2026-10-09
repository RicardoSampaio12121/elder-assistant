import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterChangeNotifier(ref);

  final router = GoRouter(
    initialLocation: LoginScreen.path,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: HomeScreen.path,
        name: HomeScreen.routeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: LoginScreen.path,
        name: LoginScreen.routeName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RegisterScreen.path,
        name: RegisterScreen.routeName,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});

class _RouterChangeNotifier extends ChangeNotifier {
  _RouterChangeNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final status = authState.status;

    if (status == AuthStatus.checking) return null;

    final loc = state.matchedLocation;
    final isAuthRoute =
        loc == LoginScreen.path || loc == RegisterScreen.path;

    if (status == AuthStatus.unauthenticated && !isAuthRoute) {
      return LoginScreen.path;
    }
    if (status == AuthStatus.authenticated && isAuthRoute) {
      return HomeScreen.path;
    }
    return null;
  }
}
