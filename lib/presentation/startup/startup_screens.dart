import 'package:flutter/material.dart';

import '../../data/storage/app_storage.dart';
import '../../l10n/app_localizations.dart';

/// Shown while the encrypted storage opens.
class StartupLoadingScreen extends StatelessWidget {
  const StartupLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: CircularProgressIndicator(
        semanticsLabel: AppLocalizations.of(context).startupLoading,
      ),
    ),
  );
}

/// Explains why the storage could not be opened (DD-007). Offers only a
/// retry: nothing here creates a key or a database, or deletes anything.
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final failure = switch (error) {
      StorageOpenException(:final failure) => failure,
      _ => null,
    };
    final (title, body) = switch (failure) {
      StorageFailure.missingKey => (
        l10n.startupMissingKeyTitle,
        l10n.startupMissingKeyBody,
      ),
      StorageFailure.keyUnavailable => (
        l10n.startupKeyUnavailableTitle,
        l10n.startupKeyUnavailableBody,
      ),
      StorageFailure.databaseUnavailable => (
        l10n.startupDatabaseTitle,
        l10n.startupDatabaseBody,
      ),
      null => (l10n.startupUnexpectedTitle, l10n.startupUnexpectedBody),
    };
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(title, style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(body, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: onRetry,
                child: Text(l10n.startupRetry),
              ),
            ),
            const SizedBox(height: 24),
            SelectableText(
              l10n.startupErrorDetails(error.toString()),
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
