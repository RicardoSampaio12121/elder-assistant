import 'care_recipient.dart';

abstract class CareRecipientRepository {
  Future<List<CareRecipient>> getAll();

  Future<CareRecipient> getById(String id);

  Future<CareRecipient> create({
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  });

  Future<CareRecipient> update({
    required String id,
    required String name,
    required DateTime dateOfBirth,
    String? notes,
  });

  Future<void> delete(String id);
}
