import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/app/bundled_licenses.dart';
import '../../l10n/app_localizations.dart';
import '../settings/build_info_provider.dart';

/// *About Offload* (T8.10, REQ-062): what the app is for, its version, its
/// licence with the full text, and the licences of its components through
/// Flutter's own overview. Reached from the section *About Offload* in
/// Settings, which keeps showing the version (REQ-060). On Windows Tab walks
/// the rows, Enter opens one and Escape goes back.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final build = ref.watch(buildInfoProvider);
    final version = build == null
        ? l10n.settingsDevelopmentBuild
        : l10n.settingsVersion(build.version, build.buildNumber);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.settingsAboutHeader)),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ListTile(
                title: Text(l10n.appTitle, style: theme.textTheme.titleLarge),
                subtitle: Text(version),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(l10n.aboutPurpose),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.gavel_outlined),
                title: Text(l10n.aboutLicenceTitle),
                subtitle: Text(l10n.aboutLicenceName),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const _LicenceText()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(l10n.aboutComponentsTitle),
                subtitle: Text(l10n.aboutComponentsSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: version,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full text of the GPL 3.0, as bundled with the app.
class _LicenceText extends StatelessWidget {
  const _LicenceText();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(title: Text(l10n.aboutLicenceName)),
          body: FutureBuilder<String>(
            future: rootBundle.loadString(appLicenseAsset),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text(l10n.aboutLicenceFailed));
              }
              final text = snapshot.data;
              if (text == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    text,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
