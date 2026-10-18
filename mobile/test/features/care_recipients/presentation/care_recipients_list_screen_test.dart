import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:careapp/features/auth/presentation/auth_notifier.dart';
import 'package:careapp/features/auth/presentation/auth_state.dart';
import 'package:careapp/features/care_recipients/data/care_recipient_repository_impl.dart';
import 'package:careapp/features/care_recipients/domain/care_recipient.dart';
import 'package:careapp/features/care_recipients/presentation/care_recipients_list_screen.dart';
import 'package:careapp/features/care_recipients/presentation/care_recipients_notifier.dart';
import 'package:careapp/features/care_recipients/presentation/care_recipients_state.dart';
import 'package:careapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/fake_care_recipient_repository.dart';
import '../../../helpers/fake_secure_token_storage.dart';

class _FixedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthState(status: AuthStatus.authenticated);
}

class _FixedRecipientsNotifier extends CareRecipientsNotifier {
  _FixedRecipientsNotifier(this._fixed);
  final CareRecipientsState _fixed;

  @override
  CareRecipientsState build() => _fixed;

  @override
  Future<void> loadAll() async {
    // No-op: state is fixed for tests
  }
}

Widget _buildApp(
  CareRecipientsNotifier Function() notifierFactory, {
  FakeCareRecipientRepository? repo,
}) {
  return ProviderScope(
    overrides: [
      secureTokenStorageProvider.overrideWithValue(FakeSecureTokenStorage()),
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
      careRecipientRepositoryProvider.overrideWithValue(
        repo ?? FakeCareRecipientRepository(),
      ),
      careRecipientsNotifierProvider.overrideWith(notifierFactory),
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
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const CareRecipientsListScreen(),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('CareRecipientsListScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            const CareRecipientsState(isLoading: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when list is empty', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            const CareRecipientsState(recipients: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emptyState')), findsOneWidget);
      expect(
        find.text('Ainda não tem nenhuma pessoa a cuidar registada.'),
        findsOneWidget,
      );
    });

    testWidgets('shows list when recipients exist', (tester) async {
      final recipients = [
        CareRecipient(
          id: 'id-1',
          name: 'Maria Silva',
          dateOfBirth: DateTime(1945, 6, 15),
          role: 'Owner',
        ),
        CareRecipient(
          id: 'id-2',
          name: 'António Costa',
          dateOfBirth: DateTime(1938, 3, 22),
          role: 'Caregiver',
        ),
      ];

      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(recipients: recipients),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipientsList')), findsOneWidget);
      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('António Costa'), findsOneWidget);
    });

    testWidgets('FAB is present', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            const CareRecipientsState(recipients: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('addRecipientFab')), findsOneWidget);
    });

    testWidgets('shows generic error and retry button on load failure',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            const CareRecipientsState(error: 'generic'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ocorreu um erro. Tente novamente.'), findsOneWidget);
      expect(find.byKey(const Key('retryButton')), findsOneWidget);
    });
  });
}
