class CareRecipient {
  const CareRecipient({
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

  /// 'Owner' or 'Caregiver'
  final String role;

  bool get isOwner => role == 'Owner';
}
