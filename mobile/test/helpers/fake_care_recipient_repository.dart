import 'package:careapp/features/care_recipients/domain/care_recipient.dart';
import 'package:careapp/features/care_recipients/domain/care_recipient_repository.dart';

class FakeCareRecipientRepository implements CareRecipientRepository {
  FakeCareRecipientRepository({
    List<CareRecipient>? initialRecipients,
    bool throwOnGet = false,
    bool throwOn404 = false,
    bool throwOnCreate = false,
    bool throwOnUpdate = false,
    bool throwOnDelete = false,
  })  : _recipients = initialRecipients ?? [],
        _throwOnGet = throwOnGet,
        _throwOn404 = throwOn404,
        _throwOnCreate = throwOnCreate,
        _throwOnUpdate = throwOnUpdate,
        _throwOnDelete = throwOnDelete;

  final List<CareRecipient> _recipients;
  final bool _throwOnGet;
  final bool _throwOn404;
  final bool _throwOnCreate;
  final bool _throwOnUpdate;
  final bool _throwOnDelete;

  int getByIdCallCount = 0;
  int createCallCount = 0;
  int updateCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<List<CareRecipient>> getAll() async {
    if (_throwOnGet) throw Exception('network error');
    return List.of(_recipients);
  }

  @override
  Future<CareRecipient> getById(String id) async {
    getByIdCallCount++;
    if (_throwOn404) {
      throw _FakeNotFoundException();
    }
    if (_throwOnGet) throw Exception('network error');
    final match = _recipients.firstWhere(
      (r) => r.id == id,
      orElse: () => throw _FakeNotFoundException(),
    );
    return match;
  }

  @override
  Future<CareRecipient> create({
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  }) async {
    createCallCount++;
    if (_throwOnCreate) throw Exception('create error');
    final recipient = CareRecipient(
      id: 'new-id-${_recipients.length}',
      name: name,
      dateOfBirth: dateOfBirth,
      notes: notes,
      role: 'Owner',
    );
    _recipients.add(recipient);
    return recipient;
  }

  @override
  Future<CareRecipient> update({
    required String id,
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  }) async {
    updateCallCount++;
    if (_throwOnUpdate) throw Exception('update error');
    final index = _recipients.indexWhere((r) => r.id == id);
    final updated = CareRecipient(
      id: id,
      name: name,
      dateOfBirth: dateOfBirth,
      notes: notes,
      role: _recipients[index].role,
    );
    _recipients[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCallCount++;
    if (_throwOnDelete) throw Exception('delete error');
    _recipients.removeWhere((r) => r.id == id);
  }
}

class _FakeNotFoundException implements Exception {}
