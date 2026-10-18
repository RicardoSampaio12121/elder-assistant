import '../../domain/care_recipient.dart';

class CareRecipientResponse {
  const CareRecipientResponse({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    this.notes,
    required this.role,
  });

  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String? notes;
  final String role;

  factory CareRecipientResponse.fromJson(Map<String, dynamic> json) {
    return CareRecipientResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      notes: json['notes'] as String?,
      role: json['role'] as String,
    );
  }

  CareRecipient toDomain() => CareRecipient(
        id: id,
        name: name,
        dateOfBirth: dateOfBirth,
        notes: notes,
        role: role,
      );
}
