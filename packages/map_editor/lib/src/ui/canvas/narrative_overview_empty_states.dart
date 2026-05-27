import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Section V0 qui rend explicites les zones encore indisponibles.
///
/// Les messages viennent des états du read model afin d'éviter toute activité,
/// notification ou donnée de lore inventée par l'UI.
class NarrativeOverviewUnavailableDataSection extends StatelessWidget {
  const NarrativeOverviewUnavailableDataSection({
    super.key,
    required this.facts,
    required this.recentActivity,
    required this.notifications,
    required this.footer,
  });

  final NarrativeMetricSummary facts;
  final NarrativeOverviewFeatureSummary recentActivity;
  final NarrativeOverviewFeatureSummary notifications;
  final NarrativeOverviewFooterSummary footer;

  @override
  Widget build(BuildContext context) {
    final items = <_UnavailableDataItem>[
      _UnavailableDataItem(
        slot: 'facts',
        label: facts.label,
        value: _availabilityTitle(facts.availability),
        detail: 'Registre de connaissances à définir avant affichage.',
        availability: facts.availability,
        icon: CupertinoIcons.book_fill,
      ),
      _UnavailableDataItem(
        slot: recentActivity.id,
        label: recentActivity.label,
        value: _availabilityTitle(recentActivity.availability),
        detail: recentActivity.message,
        availability: recentActivity.availability,
        icon: CupertinoIcons.clock,
      ),
      _UnavailableDataItem(
        slot: notifications.id,
        label: notifications.label,
        value: _availabilityTitle(notifications.availability),
        detail: notifications.message,
        availability: notifications.availability,
        icon: CupertinoIcons.bell,
      ),
      _UnavailableDataItem(
        slot: footer.locale.id,
        label: footer.locale.label,
        value: 'Non définie',
        detail: footer.locale.unavailableMessage,
        availability: footer.locale.availability,
        icon: CupertinoIcons.globe,
      ),
      _UnavailableDataItem(
        slot: footer.version.id,
        label: footer.version.label,
        value: 'Non définie',
        detail: footer.version.unavailableMessage,
        availability: footer.version.availability,
        icon: CupertinoIcons.info_circle,
      ),
    ];

    return Container(
      key: const ValueKey('narrative-overview-empty-states-section'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.accentPrimary.withValues(alpha: 0.18),
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Données à venir',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Ces zones restent visibles pour clarifier le périmètre V0, sans inventer de données.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final maxWidth = constraints.maxWidth;
              final columns = switch (maxWidth) {
                >= 960 => 3,
                >= 620 => 2,
                _ => 1,
              };
              final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: cardWidth,
                      child: _UnavailableDataTile(item: item),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

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
    return Container(
      key: const ValueKey('narrative-overview-footer'),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.subtleSeparator(context).withValues(alpha: 0.8),
        ),
      ),
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
    final accent = _availabilityAccent(context, item.availability);
    return Container(
      key: ValueKey('narrative-overview-empty-state-${item.slot}'),
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, color: accent, size: 17),
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
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _UnavailableDataPill(label: item.value, accent: accent),
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
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableDataPill extends StatelessWidget {
  const _UnavailableDataPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w900,
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
    return Container(
      key: ValueKey('narrative-overview-footer-$slot'),
      constraints: const BoxConstraints(minHeight: 24),
      child: Text(
        '$label : $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
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

Color _availabilityAccent(
  BuildContext context,
  NarrativeOverviewAvailability availability,
) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => EditorChrome.accentJade,
    NarrativeOverviewAvailability.empty => EditorChrome.accentPrimary,
    NarrativeOverviewAvailability.unavailable => EditorChrome.accentCoral,
    NarrativeOverviewAvailability.notEvaluated => EditorChrome.accentWarm,
    NarrativeOverviewAvailability.outOfScope =>
      EditorChrome.subtleLabel(context),
    NarrativeOverviewAvailability.needsModel => EditorChrome.inspectorJoyPlum,
  };
}
