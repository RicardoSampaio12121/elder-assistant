import '../domain/care_recipient.dart';

class CareRecipientsState {
  const CareRecipientsState({
    this.recipients,
    this.selected,
    this.isLoading = false,
    this.error,
    this.fieldErrors = const {},
    this.isEditing = false,
  });

  /// Null means not yet loaded.
  final List<CareRecipient>? recipients;

  /// The recipient currently shown in the detail screen.
  final CareRecipient? selected;

  final bool isLoading;

  /// Error key: 'not_found', 'generic', or null.
  final String? error;

  /// Field-level validation errors keyed by lowercase field name.
  final Map<String, String> fieldErrors;

  final bool isEditing;

  CareRecipientsState copyWith({
    List<CareRecipient>? recipients,
    CareRecipient? selected,
    bool? isLoading,
    String? error,
    Map<String, String>? fieldErrors,
    bool? isEditing,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return CareRecipientsState(
      recipients: recipients ?? this.recipients,
      selected: clearSelected ? null : (selected ?? this.selected),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}
