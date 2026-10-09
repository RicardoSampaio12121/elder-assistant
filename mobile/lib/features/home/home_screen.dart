import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const path = '/';
  static const routeName = 'home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.appTitle,
              style: textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: l10n.homeLogout,
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeWelcome,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.homeSubtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: const Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      icon: Icons.medication_rounded,
                      iconColor: const Color(0xFFE07A0A),
                      iconBackground: const Color(0xFFFFF3E0),
                      title: l10n.homeSectionMedication,
                      emptyMessage: l10n.homeEmptyMedication,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      icon: Icons.calendar_today_rounded,
                      iconColor: AppTheme.primary,
                      iconBackground: const Color(0xFFE0E7FF),
                      title: l10n.homeSectionAppointments,
                      emptyMessage: l10n.homeEmptyAppointments,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 14),
                    _buildSectionCard(
                      icon: Icons.people_rounded,
                      iconColor: const Color(0xFF2E7D52),
                      iconBackground: const Color(0xFFE8F5E9),
                      title: l10n.homeSectionFamily,
                      emptyMessage: l10n.homeEmptyFamily,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: Text(
                        l10n.homeComingSoon,
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required String emptyMessage,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    emptyMessage,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.outlineVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
