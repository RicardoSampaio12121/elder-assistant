class CareRecipientRequest {
  const CareRecipientRequest({
    required this.name,
    required this.dateOfBirth,
    this.notes,
  });

  final String name;
  final DateTime dateOfBirth;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        'dateOfBirth':
            '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        if (notes != null) 'notes': notes,
      };
}
