import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'care_recipients_list_screen.dart';
import 'care_recipients_notifier.dart';
import 'care_recipients_state.dart';

class CareRecipientFormScreen extends ConsumerStatefulWidget {
  const CareRecipientFormScreen({super.key});

  static const routeName = 'recipient-new';

  @override
  ConsumerState<CareRecipientFormScreen> createState() =>
      _CareRecipientFormScreenState();
}

class _CareRecipientFormScreenState
    extends ConsumerState<CareRecipientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1960),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success =
        await ref.read(careRecipientsNotifierProvider.notifier).create(
              name: _nameController.text.trim(),
              dateOfBirth: _selectedDate!,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
    if (success && mounted) {
      context.goNamed(CareRecipientsListScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(careRecipientsNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          l10n.recipientNewTitle,
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        key: const Key('nameField'),
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: l10n.recipientName,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.fieldRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('dateField'),
                        readOnly: true,
                        onTap: () => _pickDate(context),
                        controller: TextEditingController(
                          text: _selectedDate != null
                              ? fmt.format(_selectedDate!)
                              : '',
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.recipientDateOfBirth,
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: const Icon(Icons.arrow_drop_down),
                        ),
                        validator: (_) {
                          if (_selectedDate == null) return l10n.fieldRequired;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const Key('notesField'),
                        controller: _notesController,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: l10n.recipientNotes,
                          prefixIcon: const Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: state.error != null
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: _buildErrorBanner(
                                    state, l10n, colorScheme, textTheme),
                              )
                            : const SizedBox(height: 16),
                      ),
                      FilledButton(
                        key: const Key('submitButton'),
                        onPressed: state.isLoading ? null : _submit,
                        child: state.isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(l10n.recipientCreate),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(
    CareRecipientsState state,
    AppLocalizations l10n,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.errorGeneric,
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
