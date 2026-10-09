import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Placeholder home screen until the first feature lands.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const path = '/';
  static const routeName = 'home';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.homeWelcome, style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(l10n.homeComingSoon, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
