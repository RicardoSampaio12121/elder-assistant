import 'package:careapp/features/care_recipients/data/care_recipient_repository_impl.dart';
import 'package:careapp/features/care_recipients/domain/care_recipient.dart';
import 'package:careapp/features/care_recipients/presentation/care_recipients_notifier.dart';
import 'package:careapp/features/care_recipients/presentation/care_recipients_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_care_recipient_repository.dart';

ProviderContainer _makeContainer(FakeCareRecipientRepository repo) {
  final container = ProviderContainer(
    overrides: [
      careRecipientRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

final _testRecipient = CareRecipient(
  id: 'abc-123',
  name: 'Maria Silva',
  dateOfBirth: DateTime(1945, 6, 15),
  notes: 'Diabética',
  role: 'Owner',
);

void main() {
  group('CareRecipientsNotifier', () {
    test('initial state has no recipients and no error', () {
      final container = _makeContainer(FakeCareRecipientRepository());
      final state = container.read(careRecipientsNotifierProvider);
      expect(state.recipients, isNull);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    });

    group('loadAll', () {
      test('populates recipients on success', () async {
        final repo = FakeCareRecipientRepository(
          initialRecipients: [_testRecipient],
        );
        final container = _makeContainer(repo);

        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadAll();

        final state = container.read(careRecipientsNotifierProvider);
        expect(state.isLoading, isFalse);
        expect(state.recipients, hasLength(1));
        expect(state.recipients!.first.name, 'Maria Silva');
        expect(state.error, isNull);
      });

      test('sets empty list when no recipients exist', () async {
        final container = _makeContainer(FakeCareRecipientRepository());

        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadAll();

        final state = container.read(careRecipientsNotifierProvider);
        expect(state.recipients, isEmpty);
        expect(state.error, isNull);
      });

      test('sets generic error on failure', () async {
        final repo = FakeCareRecipientRepository(throwOnGet: true);
        final container = _makeContainer(repo);

        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadAll();

        final state = container.read(careRecipientsNotifierProvider);
        expect(state.error, 'generic');
        expect(state.isLoading, isFalse);
      });
    });

    group('loadOne', () {
      test('sets selected recipient on success', () async {
        final repo = FakeCareRecipientRepository(
          initialRecipients: [_testRecipient],
        );
        final container = _makeContainer(repo);

        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadOne('abc-123');

        final state = container.read(careRecipientsNotifierProvider);
        expect(state.selected?.id, 'abc-123');
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('sets generic error when fetch fails', () async {
        final repo = FakeCareRecipientRepository(throwOnGet: true);
        final container = _makeContainer(repo);

        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadOne('abc-123');

        final state = container.read(careRecipientsNotifierProvider);
        expect(state.error, 'generic');
        expect(state.selected, isNull);
      });
    });

    group('create', () {
      test('returns true and appends recipient on success', () async {
        final container = _makeContainer(FakeCareRecipientRepository());

        final result = await container
            .read(careRecipientsNotifierProvider.notifier)
            .create(
              name: 'João Costa',
              dateOfBirth: DateTime(1950, 3, 20),
            );

        expect(result, isTrue);
        final state = container.read(careRecipientsNotifierProvider);
        expect(state.recipients, hasLength(1));
        expect(state.recipients!.first.name, 'João Costa');
        expect(state.isLoading, isFalse);
      });

      test('returns false and sets generic error on failure', () async {
        final repo = FakeCareRecipientRepository(throwOnCreate: true);
        final container = _makeContainer(repo);

        final result = await container
            .read(careRecipientsNotifierProvider.notifier)
            .create(
              name: 'João Costa',
              dateOfBirth: DateTime(1950, 3, 20),
            );

        expect(result, isFalse);
        final state = container.read(careRecipientsNotifierProvider);
        expect(state.error, 'generic');
      });
    });

    group('update', () {
      test('returns true and updates recipient in list on success', () async {
        final repo = FakeCareRecipientRepository(
          initialRecipients: [_testRecipient],
        );
        final container = _makeContainer(repo);
        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadAll();

        final result = await container
            .read(careRecipientsNotifierProvider.notifier)
            .update(
              id: 'abc-123',
              name: 'Maria Santos',
              dateOfBirth: DateTime(1945, 6, 15),
            );

        expect(result, isTrue);
        final state = container.read(careRecipientsNotifierProvider);
        expect(state.selected?.name, 'Maria Santos');
        expect(state.recipients!.first.name, 'Maria Santos');
        expect(state.isEditing, isFalse);
      });

      test('returns false and sets generic error on failure', () async {
        final repo = FakeCareRecipientRepository(
          initialRecipients: [_testRecipient],
          throwOnUpdate: true,
        );
        final container = _makeContainer(repo);

        final result = await container
            .read(careRecipientsNotifierProvider.notifier)
            .update(
              id: 'abc-123',
              name: 'Maria Santos',
              dateOfBirth: DateTime(1945, 6, 15),
            );

        expect(result, isFalse);
        final state = container.read(careRecipientsNotifierProvider);
        expect(state.error, 'generic');
      });
    });

    group('delete', () {
      test('returns true and removes recipient from list on success', () async {
        final repo = FakeCareRecipientRepository(
          initialRecipients: [_testRecipient],
        );
        final container = _makeContainer(repo);
        await container
            .read(careRecipientsNotifierProvider.notifier)
            .loadAll();

        final result = await container
            .read(careRecipientsNotifierProvider.notifier)
            .delete('abc-123');

        expect(result, isTrue);
        final state = container.read(careRecipientsNotifierProvider);
        expect(state.recipients, isEmpty);
        expect(state.selected, isNull);
      });

      test('returns false and sets generic error on failure', () async {
        final repo = FakeCareRecipientRepository(
          initialRecipients: [_testRecipient],
          throwOnDelete: true,
        );
        final container = _makeContainer(repo);

        final result = await container
            .read(careRecipientsNotifierProvider.notifier)
            .delete('abc-123');

        expect(result, isFalse);
        final state = container.read(careRecipientsNotifierProvider);
        expect(state.error, 'generic');
      });
    });

    group('startEditing / cancelEditing', () {
      test('startEditing sets isEditing to true', () {
        final container = _makeContainer(FakeCareRecipientRepository());
        container
            .read(careRecipientsNotifierProvider.notifier)
            .startEditing();
        expect(
            container.read(careRecipientsNotifierProvider).isEditing, isTrue);
      });

      test('cancelEditing sets isEditing to false', () {
        final container = _makeContainer(FakeCareRecipientRepository());
        container
            .read(careRecipientsNotifierProvider.notifier)
            .startEditing();
        container
            .read(careRecipientsNotifierProvider.notifier)
            .cancelEditing();
        expect(
            container.read(careRecipientsNotifierProvider).isEditing, isFalse);
      });
    });
  });
}
