import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../application/services/narrative_activity_journal.dart';
import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';

/// Durable authoring activity and actionable Validator work queue.
class NarrativeOverviewUnavailableDataSection extends StatelessWidget {
  const NarrativeOverviewUnavailableDataSection({
    super.key,
    required this.recentActivity,
    required this.notifications,
    required this.activities,
    required this.diagnostics,
    required this.onOpenActivity,
    required this.onOpenDiagnostic,
  });

  final NarrativeOverviewFeatureSummary recentActivity;
  final NarrativeOverviewFeatureSummary notifications;
  final List<NarrativeActivityEntry> activities;
  final List<NarrativeOverviewDiagnosticSummary> diagnostics;
  final ValueChanged<NarrativeActivityEntry>? onOpenActivity;
  final ValueChanged<NarrativeOverviewDiagnosticSummary>? onOpenDiagnostic;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: const ValueKey('narrative-overview-empty-states-section'),
      borderRadius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À traiter et activité',
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Uniquement des diagnostics Validator et des actions d’authoring réellement journalisées.',
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final activity = _ActivityQueue(
                summary: recentActivity,
                entries: activities,
                onOpen: onOpenActivity,
              );
              final validator = _DiagnosticQueue(
                summary: notifications,
                diagnostics: diagnostics,
                onOpen: onOpenDiagnostic,
              );
              if (constraints.maxWidth < 760) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    activity,
                    const SizedBox(height: 10),
                    validator,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: activity),
                  const SizedBox(width: 10),
                  Expanded(child: validator),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActivityQueue extends StatelessWidget {
  const _ActivityQueue({
    required this.summary,
    required this.entries,
    required this.onOpen,
  });

  final NarrativeOverviewFeatureSummary summary;
  final List<NarrativeActivityEntry> entries;
  final ValueChanged<NarrativeActivityEntry>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _UnavailableDataTile(
        item: _UnavailableDataItem(
          slot: summary.id,
          label: summary.label,
          value: _availabilityTitle(summary.availability),
          detail: summary.message,
          availability: summary.availability,
          icon: CupertinoIcons.clock,
        ),
      );
    }
    return PokeMapCard(
      key: const ValueKey('narrative-overview-activity-queue'),
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QueueHeader(
            label: summary.label,
            source: 'Journal durable local',
            icon: CupertinoIcons.clock_fill,
          ),
          const SizedBox(height: 8),
          for (final entry in entries) ...[
            PokeMapButton(
              key: ValueKey('narrative-overview-activity-${entry.id}'),
              onPressed: onOpen == null ? null : () => onOpen!(entry),
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              leading: Icon(_activityIcon(entry.kind)),
              child: Text(entry.label),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticQueue extends StatelessWidget {
  const _DiagnosticQueue({
    required this.summary,
    required this.diagnostics,
    required this.onOpen,
  });

  final NarrativeOverviewFeatureSummary summary;
  final List<NarrativeOverviewDiagnosticSummary> diagnostics;
  final ValueChanged<NarrativeOverviewDiagnosticSummary>? onOpen;

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return _UnavailableDataTile(
        item: _UnavailableDataItem(
          slot: summary.id,
          label: summary.label,
          value: _availabilityTitle(summary.availability),
          detail: summary.message,
          availability: summary.availability,
          icon: CupertinoIcons.checkmark_shield,
        ),
      );
    }
    return PokeMapCard(
      key: const ValueKey('narrative-overview-diagnostic-queue'),
      borderRadius: 14,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _QueueHeader(
            label: summary.label,
            source: 'Validator global',
            icon: CupertinoIcons.exclamationmark_shield_fill,
          ),
          const SizedBox(height: 8),
          for (final item in diagnostics) ...[
            PokeMapButton(
              key: ValueKey(
                'narrative-overview-diagnostic-${item.diagnostic.stableKey}',
              ),
              onPressed: onOpen == null ? null : () => onOpen!(item),
              variant: item.diagnostic.severity ==
                      NarrativeProjectDiagnosticSeverity.error
                  ? PokeMapButtonVariant.danger
                  : PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.compact,
              leading: const Icon(CupertinoIcons.arrow_right_circle),
              child: Text(item.diagnostic.message),
            ),
            if (item.canQuickFix)
              Text(
                item.diagnostic.suggestedFixLabel ?? 'Correction déterministe',
                style: TextStyle(
                  color: context.pokeMapColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.label,
    required this.source,
    required this.icon,
  });

  final String label;
  final String source;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PokeMapIconTile(icon: icon, size: 30, iconSize: 16),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.pokeMapColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Source : $source',
                style: TextStyle(
                  color: context.pokeMapColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

IconData _activityIcon(NarrativeActivityKind kind) => switch (kind) {
      NarrativeActivityKind.edited => CupertinoIcons.pencil,
      NarrativeActivityKind.saved => CupertinoIcons.checkmark_circle_fill,
      NarrativeActivityKind.recovered => CupertinoIcons.arrow_counterclockwise,
      NarrativeActivityKind.saveFailed =>
        CupertinoIcons.exclamationmark_triangle_fill,
      NarrativeActivityKind.conflicted => CupertinoIcons.arrow_branch,
    };

/// Footer metadata sobre pour l'overview V0.
class NarrativeOverviewFooter extends StatelessWidget {
  const NarrativeOverviewFooter({
    super.key,
    required this.projectName,
    required this.footer,
  });

  final String projectName;
  final NarrativeOverviewFooterSummary footer;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: const ValueKey('narrative-overview-footer'),
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 18,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FooterMetadataItem(
            slot: 'project',
            label: footer.project.label,
            value: projectName,
          ),
          _FooterMetadataItem(
            slot: 'locale',
            label: footer.locale.label,
            value: 'non définie',
          ),
          _FooterMetadataItem(
            slot: 'version',
            label: footer.version.label,
            value: 'non définie',
          ),
        ],
      ),
    );
  }
}

class _UnavailableDataTile extends StatelessWidget {
  const _UnavailableDataTile({required this.item});

  final _UnavailableDataItem item;

  @override
  Widget build(BuildContext context) {
    final tone = _availabilityTone(item.availability);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 112),
      child: PokeMapCard(
        key: ValueKey('narrative-overview-empty-state-${item.slot}'),
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PokeMapIconTile(
                  icon: item.icon,
                  tone: tone,
                  size: 30,
                  iconSize: 17,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      PokeMapBadge(
                        label: item.value,
                        variant: _availabilityBadgeVariant(item.availability),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.pokeMapColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterMetadataItem extends StatelessWidget {
  const _FooterMetadataItem({
    required this.slot,
    required this.label,
    required this.value,
  });

  final String slot;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (slot == 'project') {
      return KeyedSubtree(
        key: ValueKey('narrative-overview-footer-$slot'),
        child: Text(
          '$label : $value',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.pokeMapColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }
    return PokeMapStatusLabel(
      key: ValueKey('narrative-overview-footer-$slot'),
      label: '$label : $value',
      tone: PokeMapTone.neutral,
    );
  }
}

class _UnavailableDataItem {
  const _UnavailableDataItem({
    required this.slot,
    required this.label,
    required this.value,
    required this.detail,
    required this.availability,
    required this.icon,
  });

  final String slot;
  final String label;
  final String value;
  final String detail;
  final NarrativeOverviewAvailability availability;
  final IconData icon;
}

String _availabilityTitle(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => 'Disponible',
    NarrativeOverviewAvailability.empty => 'Vide',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}

PokeMapTone _availabilityTone(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => PokeMapTone.success,
    NarrativeOverviewAvailability.empty => PokeMapTone.brand,
    NarrativeOverviewAvailability.unavailable => PokeMapTone.danger,
    NarrativeOverviewAvailability.notEvaluated => PokeMapTone.warning,
    NarrativeOverviewAvailability.outOfScope => PokeMapTone.neutral,
    NarrativeOverviewAvailability.needsModel => PokeMapTone.narrative,
  };
}

PokeMapBadgeVariant _availabilityBadgeVariant(
  NarrativeOverviewAvailability availability,
) =>
    switch (availability) {
      NarrativeOverviewAvailability.available => PokeMapBadgeVariant.success,
      NarrativeOverviewAvailability.empty => PokeMapBadgeVariant.info,
      NarrativeOverviewAvailability.unavailable => PokeMapBadgeVariant.error,
      NarrativeOverviewAvailability.notEvaluated => PokeMapBadgeVariant.warning,
      NarrativeOverviewAvailability.outOfScope => PokeMapBadgeVariant.neutral,
      NarrativeOverviewAvailability.needsModel => PokeMapBadgeVariant.narrative,
    };
