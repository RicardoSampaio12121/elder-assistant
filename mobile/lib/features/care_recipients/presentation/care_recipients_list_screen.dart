import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'care_recipient_detail_screen.dart';
import 'care_recipient_form_screen.dart';
import 'care_recipients_notifier.dart';
import 'care_recipients_state.dart';

class CareRecipientsListScreen extends ConsumerStatefulWidget {
  const CareRecipientsListScreen({super.key});

  static const path = '/recipients';
  static const routeName = 'recipients-list';

  @override
  ConsumerState<CareRecipientsListScreen> createState() =>
      _CareRecipientsListScreenState();
}

class _CareRecipientsListScreenState
    extends ConsumerState<CareRecipientsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(careRecipientsNotifierProvider.notifier).loadAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(careRecipientsNotifierProvider);
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          l10n.recipientsTitle,
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
              child: _buildBody(state, l10n, textTheme),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addRecipientFab'),
        onPressed: () => context.goNamed(CareRecipientFormScreen.routeName),
        tooltip: l10n.recipientCreate,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    CareRecipientsState state,
    AppLocalizations l10n,
    TextTheme textTheme,
  ) {
    if (state.isLoading && state.recipients == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.recipients == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(l10n.errorGeneric, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('retryButton'),
                onPressed: () =>
                    ref.read(careRecipientsNotifierProvider.notifier).loadAll(),
                child: Text(l10n.errorRetry),
              ),
            ],
          ),
        ),
      );
    }

    final recipients = state.recipients ?? [];

    if (recipients.isEmpty) {
      return Center(
        key: const Key('emptyState'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.recipientsEmpty,
                style: textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final fmt = DateFormat('dd/MM/yyyy');

    return ListView.separated(
      key: const Key('recipientsList'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: recipients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        return Card(
          key: Key('recipientItem_${recipient.id}'),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            title: Text(recipient.name, style: textTheme.titleSmall),
            subtitle: Text(
              fmt.format(recipient.dateOfBirth),
              style: textTheme.bodySmall,
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            onTap: () => context.goNamed(
              CareRecipientDetailScreen.routeName,
              pathParameters: {'id': recipient.id},
            ),
          ),
        );
      },
    );
  }
}
