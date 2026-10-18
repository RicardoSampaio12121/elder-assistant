import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/care_recipient_repository_impl.dart';
import '../domain/care_recipient.dart';
import 'care_recipients_state.dart';

class CareRecipientsNotifier extends Notifier<CareRecipientsState> {
  @override
  CareRecipientsState build() => const CareRecipientsState();

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final recipients =
          await ref.read(careRecipientRepositoryProvider).getAll();
      state = state.copyWith(isLoading: false, recipients: recipients);
    } on DioException catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
    }
  }

  Future<void> loadOne(String id) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSelected: true,
      isEditing: false,
    );
    try {
      final recipient =
          await ref.read(careRecipientRepositoryProvider).getById(id);
      state = state.copyWith(isLoading: false, selected: recipient);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        state = state.copyWith(isLoading: false, error: 'not_found');
      } else {
        state = state.copyWith(isLoading: false, error: 'generic');
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
    }
  }

  /// Returns true on success, false on failure.
  Future<bool> create({
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, fieldErrors: {});
    try {
      final recipient = await ref.read(careRecipientRepositoryProvider).create(
            name: name,
            dateOfBirth: dateOfBirth,
            notes: notes,
          );
      final updated = <CareRecipient>[...(state.recipients ?? []), recipient];
      state = state.copyWith(isLoading: false, recipients: updated);
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final fieldErrors = _parseFieldErrors(e.response?.data);
        state = state.copyWith(isLoading: false, fieldErrors: fieldErrors);
      } else {
        state = state.copyWith(isLoading: false, error: 'generic');
      }
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
      return false;
    }
  }

  /// Returns true on success, false on failure.
  Future<bool> update({
    required String id,
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, fieldErrors: {});
    try {
      final recipient = await ref.read(careRecipientRepositoryProvider).update(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            notes: notes,
          );
      final updated = (state.recipients ?? [])
          .map((r) => r.id == id ? recipient : r)
          .toList();
      state = state.copyWith(
        isLoading: false,
        selected: recipient,
        recipients: updated,
        isEditing: false,
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final fieldErrors = _parseFieldErrors(e.response?.data);
        state = state.copyWith(isLoading: false, fieldErrors: fieldErrors);
      } else {
        state = state.copyWith(isLoading: false, error: 'generic');
      }
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
      return false;
    }
  }

  /// Returns true on success, false on failure.
  Future<bool> delete(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(careRecipientRepositoryProvider).delete(id);
      final updated =
          (state.recipients ?? []).where((r) => r.id != id).toList();
      state = state.copyWith(
        isLoading: false,
        recipients: updated,
        clearSelected: true,
      );
      return true;
    } on DioException catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'generic');
      return false;
    }
  }

  void startEditing() {
    state = state.copyWith(isEditing: true, clearError: true, fieldErrors: {});
  }

  void cancelEditing() {
    state =
        state.copyWith(isEditing: false, clearError: true, fieldErrors: {});
  }

  Map<String, String> _parseFieldErrors(dynamic data) {
    if (data is! Map<String, dynamic>) return {};
    final errors = data['errors'];
    if (errors is! Map<String, dynamic>) return {};
    return errors.map((key, value) {
      final messages = value is List ? value : [value];
      return MapEntry(key.toLowerCase(), messages.first.toString());
    });
  }
}

final careRecipientsNotifierProvider =
    NotifierProvider<CareRecipientsNotifier, CareRecipientsState>(
  CareRecipientsNotifier.new,
);
