import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'care_recipients_list_screen.dart';
import 'care_recipients_notifier.dart';
import 'care_recipients_state.dart';

class CareRecipientDetailScreen extends ConsumerStatefulWidget {
  const CareRecipientDetailScreen({super.key, required this.id});

  final String id;

  static const routeName = 'recipient-detail';

  @override
  ConsumerState<CareRecipientDetailScreen> createState() =>
      _CareRecipientDetailScreenState();
}

class _CareRecipientDetailScreenState
    extends ConsumerState<CareRecipientDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(careRecipientsNotifierProvider.notifier).loadOne(widget.id),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateControllers(CareRecipientsState state) {
    if (state.selected != null) {
      _nameController.text = state.selected!.name;
      _notesController.text = state.selected!.notes ?? '';
      _selectedDate = state.selected!.dateOfBirth;
    }
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

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    final success =
        await ref.read(careRecipientsNotifierProvider.notifier).update(
              id: widget.id,
              name: _nameController.text.trim(),
              dateOfBirth: _selectedDate!,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            );
    if (!success) return;
    // state.isEditing is now false — notifier already updated it
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recipientDeleteDialogTitle),
        content: Text(l10n.recipientDeleteDialogMessage),
        actions: [
          TextButton(
            key: const Key('cancelDeleteButton'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.confirmCancel),
          ),
          FilledButton(
            key: const Key('confirmDeleteButton'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirmYes),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await ref
        .read(careRecipientsNotifierProvider.notifier)
        .delete(widget.id);
    if (success && mounted) {
      context.goNamed(CareRecipientsListScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(careRecipientsNotifierProvider, (prev, curr) {
      // Populate form controllers when recipient first loads.
      if (prev?.selected == null && curr.selected != null) {
        _populateControllers(curr);
      }
      // Navigate away on 404.
      if (prev?.error != 'not_found' && curr.error == 'not_found') {
        if (mounted) context.goNamed(CareRecipientsListScreen.routeName);
      }
    });

    final state = ref.watch(careRecipientsNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          state.isEditing ? l10n.recipientEditTitle : l10n.recipientsTitle,
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        actions: [
          if (!state.isEditing && state.selected?.isOwner == true) ...[
            IconButton(
              key: const Key('editButton'),
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.recipientEdit,
              onPressed: () => ref
                  .read(careRecipientsNotifierProvider.notifier)
                  .startEditing(),
            ),
            IconButton(
              key: const Key('deleteButton'),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: l10n.recipientDelete,
              onPressed: () => _confirmDelete(context, l10n),
            ),
          ],
          if (state.isEditing)
            IconButton(
              key: const Key('cancelEditButton'),
              icon: const Icon(Icons.close),
              tooltip: l10n.confirmCancel,
              onPressed: () => ref
                  .read(careRecipientsNotifierProvider.notifier)
                  .cancelEditing(),
            ),
          const SizedBox(width: 8),
        ],
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
              child: _buildBody(state, l10n, textTheme, colorScheme, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    CareRecipientsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    if (state.isLoading && state.selected == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error == 'not_found') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.recipientNotFound, style: textTheme.bodyLarge),
        ),
      );
    }

    if (state.error != null && state.selected == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.errorGeneric, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref
                    .read(careRecipientsNotifierProvider.notifier)
                    .loadOne(widget.id),
                child: Text(l10n.errorRetry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.selected == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isEditing) {
      return _buildEditForm(state, l10n, textTheme, colorScheme, context);
    }

    return _buildReadView(state, l10n, textTheme, colorScheme);
  }

  Widget _buildReadView(
    CareRecipientsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final recipient = state.selected!;
    final fmt = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE0E7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            icon: Icons.person_outline,
            label: l10n.recipientName,
            value: recipient.name,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            key: const Key('dobCard'),
            icon: Icons.calendar_today_outlined,
            label: l10n.recipientDateOfBirth,
            value: fmt.format(recipient.dateOfBirth),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          if (recipient.notes != null && recipient.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.notes_outlined,
              label: l10n.recipientNotes,
              value: recipient.notes!,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    Key? key,
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(value, style: textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(
    CareRecipientsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final fmt = DateFormat('dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('editNameField'),
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
              key: const Key('editDateField'),
              readOnly: true,
              onTap: () => _pickDate(context),
              controller: TextEditingController(
                text: _selectedDate != null ? fmt.format(_selectedDate!) : '',
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
              key: const Key('editNotesField'),
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
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                color: colorScheme.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.errorGeneric,
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(height: 16),
            ),
            FilledButton(
              key: const Key('saveButton'),
              onPressed: state.isLoading ? null : _submitUpdate,
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
                  : Text(l10n.recipientSave),
            ),
          ],
        ),
      ),
    );
  }
}
