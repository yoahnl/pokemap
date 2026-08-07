import 'package:flutter/material.dart';

import 'package:pokemap_hub/presentation/shell/hub_shell_sections.dart';
import 'package:flutter/services.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/presentation/theme/avelune_theme.dart';
import 'package:pokemap_hub/features/dashboard/application/notifiers/hub_dashboard_state.dart';
import 'package:pokemap_hub/core/diagnostics/hub_diagnostic.dart';

/// Status banner and diagnostic list rendering.
///
/// Split out of hub_shell.dart. These widgets were private; Dart privacy is
/// library-scoped, so crossing a file requires them to be public.

class HubStatusBanner extends StatelessWidget {
  const HubStatusBanner({required this.diagnostic});

  final HubDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PlayerSpacing.md,
            PlayerSpacing.md,
            PlayerSpacing.md,
            0,
          ),
          child: PlayerPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  AveluneIcons.error,
                  color: context.playerColors.danger,
                ),
                const SizedBox(width: PlayerSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        diagnosticMessage(context, diagnostic),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: PlayerSpacing.xxs),
                      Text(
                        diagnosticRecommendation(context, diagnostic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class HubDiagnostics extends StatelessWidget {
  const HubDiagnostics({required this.snapshot});

  final HubDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) => PlayerSurface(
        maxWidth: 980,
        child: ListView(
          children: <Widget>[
            HubHeader(
              title: context.playerL10n.diagnostics,
              subtitle: context.playerL10n.diagnosticsSubtitle,
            ),
            const SizedBox(height: PlayerSpacing.xl),
            PlayerPanel(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        AveluneIcons.storage,
                        color: context.playerColors.primary,
                      ),
                      const SizedBox(width: PlayerSpacing.md),
                      Expanded(child: Text(context.playerL10n.usedStorage)),
                      Text(formatStorageBytes(context, snapshot.storage.usedBytes)),
                    ],
                  ),
                  if (snapshot.storage.availableBytes
                      case final available?) ...<Widget>[
                    const SizedBox(height: PlayerSpacing.sm),
                    Row(
                      children: <Widget>[
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(context.playerL10n.availableStorage),
                        ),
                        Text(formatStorageBytes(context, available)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PlayerSpacing.md),
            if (snapshot.diagnostics.isEmpty)
              PlayerEmptyState(
                icon: AveluneIcons.integrity,
                title: context.playerL10n.noDiagnostics,
                message: context.playerL10n.diagnosticsReady,
              )
            else
              for (final diagnostic in snapshot.diagnostics)
                Padding(
                  padding: const EdgeInsets.only(bottom: PlayerSpacing.md),
                  child: DiagnosticCard(diagnostic: diagnostic),
                ),
          ],
        ),
      );
}

class DiagnosticCard extends StatelessWidget {
  const DiagnosticCard({required this.diagnostic});

  final HubDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) => PlayerPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              switch (diagnostic.severity) {
                HubDiagnosticSeverity.information => AveluneIcons.details,
                HubDiagnosticSeverity.warning => AveluneIcons.warning,
                HubDiagnosticSeverity.error => AveluneIcons.error,
              },
              color: switch (diagnostic.severity) {
                HubDiagnosticSeverity.information =>
                  context.playerColors.primary,
                HubDiagnosticSeverity.warning => context.playerColors.warning,
                HubDiagnosticSeverity.error => context.playerColors.danger,
              },
            ),
            const SizedBox(width: PlayerSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    diagnosticMessage(context, diagnostic),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: PlayerSpacing.xs),
                  Text(diagnosticRecommendation(context, diagnostic)),
                  const SizedBox(height: PlayerSpacing.xs),
                  Text(
                    diagnostic.code,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  if (diagnostic.technicalDetails != null) ...[
                    const SizedBox(height: PlayerSpacing.sm),
                    SelectableText(
                      diagnostic.technicalDetails!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                    if (diagnostic.logPath != null) ...[
                      const SizedBox(height: PlayerSpacing.xs),
                      SelectableText(
                        'Journal : ${diagnostic.logPath}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                    const SizedBox(height: PlayerSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(
                            text: <String>[
                              diagnostic.technicalDetails!,
                              if (diagnostic.logPath != null)
                                'Journal : ${diagnostic.logPath}',
                            ].join('\n'),
                          ),
                        ),
                        icon: const Icon(AveluneIcons.copy),
                        label: const Text('Copier le diagnostic'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

String diagnosticMessage(
  BuildContext context,
  HubDiagnostic diagnostic,
) {
  if (context.playerL10n.locale.languageCode == 'fr') {
    return diagnostic.message;
  }
  if (diagnostic.code.startsWith('install.')) {
    return switch (diagnostic.code) {
      'install.cancelled' =>
        'Installation was cancelled without changing the current game.',
      'install.incompatible' =>
        'This game is not compatible with this Hub version.',
      'install.insufficientDisk' =>
        'There is not enough storage to install this game.',
      'install.integrityFailed' ||
      'install.sourceChanged' =>
        'The package is incomplete or was modified.',
      _ => 'Installation could not be completed.',
    };
  }
  return switch (diagnostic.code) {
    'preferences.currentCorrupt' => 'The main preferences file was unreadable.',
    'preferences.backupCorrupt' => 'The preference backup was unreadable.',
    'preferences.writeFailed' => 'Preferences could not be saved.',
    'game.activityUnavailable' => 'Some game information is unavailable.',
    'storage.measurementUnavailable' => 'Storage usage cannot be measured.',
    'library.currentCorrupt' ||
    'library.backupCorrupt' =>
      'The library had to be recovered.',
    _ when diagnostic.code.startsWith('launch.') =>
      'This game cannot be launched.',
    _ => diagnostic.message,
  };
}

String diagnosticRecommendation(
  BuildContext context,
  HubDiagnostic diagnostic,
) {
  if (context.playerL10n.locale.languageCode == 'fr') {
    return diagnostic.recommendation;
  }
  if (diagnostic.code.startsWith('install.')) {
    return diagnostic.code.contains('repair')
        ? 'Use Repair from the game details.'
        : 'The previously installed game remains available.';
  }
  return switch (diagnostic.code) {
    'preferences.currentCorrupt' => 'The latest valid settings were restored.',
    'preferences.backupCorrupt' => 'Review settings before playing.',
    'preferences.writeFailed' => 'Check storage and try again.',
    'game.activityUnavailable' => 'Verify or repair the installation.',
    'storage.measurementUnavailable' =>
      'Check permissions for the application data folder.',
    'library.currentCorrupt' ||
    'library.backupCorrupt' =>
      'Verify installed games.',
    _ when diagnostic.code.startsWith('launch.') =>
      'Repair the installation before playing.',
    _ => diagnostic.recommendation,
  };
}

String formatStorageBytes(BuildContext context, int bytes) {
  final french = context.playerL10n.locale.languageCode == 'fr';
  if (bytes < 1024) return '$bytes ${french ? 'o' : 'B'}';
  final kib = bytes / 1024;
  if (kib < 1024) return '${kib.toStringAsFixed(1)} ${french ? 'Ko' : 'kB'}';
  final mib = kib / 1024;
  if (mib < 1024) return '${mib.toStringAsFixed(1)} ${french ? 'Mo' : 'MB'}';
  return '${(mib / 1024).toStringAsFixed(1)} ${french ? 'Go' : 'GB'}';
}
