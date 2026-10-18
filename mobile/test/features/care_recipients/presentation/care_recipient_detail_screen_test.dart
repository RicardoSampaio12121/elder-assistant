import 'package:careapp/features/auth/data/secure_token_storage.dart';
import 'package:careapp/features/auth/presentation/auth_notifier.dart';
import 'package:careapp/features/auth/presentation/auth_state.dart';
import 'package:careapp/features/care_recipients/data/care_recipient_repository_impl.dart';
import 'package:careapp/features/care_recipients/domain/care_recipient.dart';
import 'package:careapp/features/care_recipients/presentation/care_recipient_detail_screen.dart';
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
  Future<void> loadOne(String id) async {
    // No-op: state is fixed
  }

  @override
  void startEditing() {
    state = state.copyWith(isEditing: true);
  }

  @override
  void cancelEditing() {
    state = state.copyWith(isEditing: false);
  }
}

final _ownerRecipient = CareRecipient(
  id: 'abc-123',
  name: 'Maria Silva',
  dateOfBirth: DateTime(1945, 6, 15),
  notes: 'Diabética',
  role: 'Owner',
);

final _caregiverRecipient = CareRecipient(
  id: 'def-456',
  name: 'António Costa',
  dateOfBirth: DateTime(1938, 3, 22),
  role: 'Caregiver',
);

Widget _buildApp(
  CareRecipientsNotifier Function() factory, {
  String recipientId = 'abc-123',
}) {
  return ProviderScope(
    overrides: [
      secureTokenStorageProvider.overrideWithValue(FakeSecureTokenStorage()),
      authNotifierProvider.overrideWith(() => _FixedAuthNotifier()),
      careRecipientRepositoryProvider
          .overrideWithValue(FakeCareRecipientRepository()),
      careRecipientsNotifierProvider.overrideWith(factory),
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
            builder: (_, __) =>
                CareRecipientDetailScreen(id: recipientId),
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('CareRecipientDetailScreen', () {
    testWidgets('shows loading indicator while recipient is loading',
        (tester) async {
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

    testWidgets('displays recipient details in read mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _ownerRecipient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Maria Silva'), findsOneWidget);
      expect(find.text('15/06/1945'), findsOneWidget);
      expect(find.text('Diabética'), findsOneWidget);
    });

    testWidgets('shows edit and delete buttons for owner', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _ownerRecipient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editButton')), findsOneWidget);
      expect(find.byKey(const Key('deleteButton')), findsOneWidget);
    });

    testWidgets('hides edit and delete buttons for caregiver', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _caregiverRecipient),
          ),
          recipientId: 'def-456',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editButton')), findsNothing);
      expect(find.byKey(const Key('deleteButton')), findsNothing);
    });

    testWidgets('tapping edit button switches to edit mode', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _ownerRecipient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editNameField')), findsOneWidget);
      expect(find.byKey(const Key('saveButton')), findsOneWidget);
    });

    testWidgets('tapping cancel in edit mode returns to read mode',
        (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _ownerRecipient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelEditButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editNameField')), findsNothing);
      expect(find.text('Maria Silva'), findsOneWidget);
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _ownerRecipient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteButton')));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar registo'), findsOneWidget);
      expect(
        find.text(
          'Tem a certeza que pretende eliminar este registo? Esta ação é irreversível.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('confirmDeleteButton')), findsOneWidget);
      expect(find.byKey(const Key('cancelDeleteButton')), findsOneWidget);
    });

    testWidgets('cancelling delete dialog keeps screen open', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          () => _FixedRecipientsNotifier(
            CareRecipientsState(selected: _ownerRecipient),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancelDeleteButton')));
      await tester.pumpAndSettle();

      expect(find.text('Maria Silva'), findsOneWidget);
    });
  });
}
