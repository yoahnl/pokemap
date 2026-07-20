import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

const narrativeLegacyMigrationCenterKey =
    ValueKey<String>('narrative-legacy-migration-center');

Future<void> showNarrativeLegacyMigrationCenter({
  required BuildContext context,
  required NarrativeLegacyMigrationScan scan,
  VoidCallback? onRefreshDryRun,
  VoidCallback? onCreateBackup,
  ValueChanged<NarrativeLegacyDomain>? onOpenDomain,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 680),
        child: NarrativeLegacyMigrationCenter(
          scan: scan,
          onRefreshDryRun: onRefreshDryRun,
          onCreateBackup: onCreateBackup,
          onOpenDomain: onOpenDomain,
          onClose: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    ),
  );
}

/// Consolidated, dry-run-first migration surface for every Narrative domain.
///
/// The center never mutates a project directly. Each domain keeps ownership of
/// its attested apply use case while this surface makes backup, blockers,
/// losses, dependencies and retirement conditions visible in one place.
class NarrativeLegacyMigrationCenter extends StatelessWidget {
  const NarrativeLegacyMigrationCenter({
    super.key,
    required this.scan,
    this.onRefreshDryRun,
    this.onCreateBackup,
    this.onOpenDomain,
    this.onClose,
  });

  final NarrativeLegacyMigrationScan scan;
  final VoidCallback? onRefreshDryRun;
  final VoidCallback? onCreateBackup;
  final ValueChanged<NarrativeLegacyDomain>? onOpenDomain;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final l10n = context.pokeMapL10n;
    return Semantics(
      key: narrativeLegacyMigrationCenterKey,
      container: true,
      namesRoute: true,
      label: l10n.migrationCenterSemantics,
      explicitChildNodes: true,
      child: PokeMapPanel(
        expandChild: true,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 14),
          child: Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.arrow_2_circlepath,
                tone: PokeMapTone.warning,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.migrationCenterTitle,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.migrationCenterDryRunSummary(
                        scan.schemaVersion,
                        scan.minimumProjectVersion,
                      ),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PokeMapIconButton(
                key: const ValueKey('migration-center-close'),
                icon: const Icon(CupertinoIcons.xmark),
                tooltip: l10n.migrationCenterClose,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        footer: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapButton(
                key: const ValueKey('migration-center-refresh'),
                onPressed: onRefreshDryRun,
                variant: PokeMapButtonVariant.secondary,
                leading: const Icon(CupertinoIcons.refresh),
                child: Text(l10n.migrationCenterRefresh),
              ),
              PokeMapButton(
                key: const ValueKey('migration-center-backup'),
                onPressed: scan.backupRequired ? onCreateBackup : null,
                variant: PokeMapButtonVariant.primary,
                leading: const Icon(CupertinoIcons.archivebox),
                child: Text(l10n.migrationCenterCreateBackup),
              ),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PokeMapStatusTile(
                    label: l10n.migrationCenterLegacyRemaining,
                    value: '${scan.legacyRemainingCount}',
                    icon: CupertinoIcons.archivebox,
                    tone: scan.legacyRemainingCount == 0
                        ? PokeMapTone.success
                        : PokeMapTone.warning,
                  ),
                  PokeMapStatusTile(
                    label: l10n.migrationCenterBlockers,
                    value: '${scan.blockerCount}',
                    icon: CupertinoIcons.exclamationmark_triangle,
                    tone: scan.blockerCount == 0
                        ? PokeMapTone.success
                        : PokeMapTone.danger,
                  ),
                  PokeMapStatusTile(
                    label: l10n.migrationCenterLossRisks,
                    value: '${scan.lossRiskCount}',
                    icon: CupertinoIcons.shield,
                    tone: scan.lossRiskCount == 0
                        ? PokeMapTone.success
                        : PokeMapTone.danger,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.info,
                title: scan.canRetireLegacyReaders
                    ? l10n.migrationCenterReadersRetirable
                    : l10n.migrationCenterCompatibilityReadOnly,
                message: scan.canRetireLegacyReaders
                    ? l10n.migrationCenterCanonicalMessage
                    : l10n.migrationCenterReadOnlyMessage,
              ),
              const SizedBox(height: 14),
              for (final domain in scan.domains) ...[
                _MigrationDomainCard(
                  scan: domain,
                  onOpen: onOpenDomain == null
                      ? null
                      : () => onOpenDomain!(domain.domain),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                l10n.migrationCenterRollbackHint,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MigrationDomainCard extends StatelessWidget {
  const _MigrationDomainCard({required this.scan, this.onOpen});

  final NarrativeLegacyMigrationDomainScan scan;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.pokeMapL10n;
    final label = switch (scan.domain) {
      NarrativeLegacyDomain.storyline => l10n.migrationCenterStorylineDomain,
      NarrativeLegacyDomain.event => l10n.migrationCenterEventDomain,
      NarrativeLegacyDomain.cinematic => l10n.migrationCenterCinematicDomain,
    };
    final icon = switch (scan.domain) {
      NarrativeLegacyDomain.storyline => CupertinoIcons.book,
      NarrativeLegacyDomain.event => CupertinoIcons.bolt,
      NarrativeLegacyDomain.cinematic => CupertinoIcons.film,
    };
    final tone = scan.blockerCount > 0 || scan.lossRiskCount > 0
        ? PokeMapTone.danger
        : scan.remainingCount > 0
            ? PokeMapTone.warning
            : PokeMapTone.success;
    return PokeMapModuleCard(
      key: ValueKey('migration-domain-${scan.domain.name}'),
      title: label,
      description: l10n.migrationCenterDomainSummary(
        scan.remainingCount,
        scan.readyCount,
      ),
      icon: icon,
      tone: tone,
      count: '${scan.remainingCount}',
      footer: Row(
        children: [
          Expanded(
            child: PokeMapStatusLabel(
              label: l10n.migrationCenterBlockerDependencySummary(
                scan.blockerCount,
                scan.dependencyCount,
              ),
              tone: tone,
            ),
          ),
          PokeMapButton(
            key: ValueKey('migration-open-${scan.domain.name}'),
            onPressed: onOpen,
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: Text(l10n.migrationCenterExamine),
          ),
        ],
      ),
    );
  }
}
