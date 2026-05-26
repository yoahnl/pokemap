import 'package:flutter/cupertino.dart';

import '../../features/narrative/application/overview/narrative_overview_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';

/// Shell V0 de la page "Aperçu" du Narrative Studio.
///
/// Ce widget reste volontairement sobre : il prouve le point d'entrée UI et la
/// consommation du read model sans construire le dashboard final.
class NarrativeOverviewWorkspace extends StatelessWidget {
  const NarrativeOverviewWorkspace({
    super.key,
    required this.readModel,
  });

  final NarrativeOverviewReadModel readModel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        Text(
          'Aperçu',
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Vue d’ensemble auteur du Narrative Studio.',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        _OverviewSection(
          title: 'Projet',
          children: [
            _OverviewLine(label: 'Nom', value: readModel.projectName),
            _OverviewLine(
              label: 'Statut éditorial',
              value: _editorialStatusLabel(
                readModel.editorialStatus.validationState,
              ),
            ),
            _OverviewLine(
              label: 'Project Health',
              value: _projectHealthLabel(readModel.projectHealth.healthKind),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _KpiCardsSection(
          metrics: [
            readModel.metrics.chapters,
            readModel.metrics.scenes,
            readModel.metrics.cutscenes,
            readModel.metrics.quests,
            readModel.metrics.dialogues,
            readModel.metrics.openIssues,
          ],
        ),
        const SizedBox(height: 12),
        _OverviewSection(
          title: 'V0 volontairement limitée',
          children: [
            const Text(
              'Les sections détaillées seront construites dans les lots suivants.',
            ),
            const SizedBox(height: 6),
            const Text(
              'Aucun compteur fake, aucune activité récente inventée, aucune notification simulée.',
            ),
            const SizedBox(height: 6),
            _MetricLine(metric: readModel.metrics.facts),
            _FeatureLine(feature: readModel.recentActivity),
            _FeatureLine(feature: readModel.notifications),
          ],
        ),
      ],
    );
  }
}

class _KpiCardsSection extends StatelessWidget {
  const _KpiCardsSection({
    required this.metrics,
  });

  final List<NarrativeMetricSummary> metrics;

  @override
  Widget build(BuildContext context) {
    return _OverviewSection(
      title: 'Indicateurs auteur',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 10.0;
            final maxWidth = constraints.maxWidth;
            final columns = switch (maxWidth) {
              >= 1080 => 6,
              >= 720 => 3,
              _ => 2,
            };
            final cardWidth = (maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              key: const ValueKey('narrative-overview-kpi-grid'),
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: cardWidth,
                    child: _KpiCard(metric: metric),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.metric});

  final NarrativeMetricSummary metric;

  @override
  Widget build(BuildContext context) {
    final accent = _availabilityAccent(context, metric.availability);
    return Container(
      key: ValueKey('narrative-overview-kpi-${metric.id}'),
      height: 154,
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MetricIcon(metricId: metric.id, accent: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            _metricCardValue(metric),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: _metricCardValue(metric).length > 12 ? 18 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 6),
          _AvailabilityPill(
            label: _metricSupportLabel(metric),
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({
    required this.metricId,
    required this.accent,
  });

  final String metricId;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.26)),
      ),
      alignment: Alignment.center,
      child: Icon(
        _metricIcon(metricId),
        size: 18,
        color: accent,
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final inheritedFontFamily = DefaultTextStyle.of(context).style.fontFamily;
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.islandCoolTint.withValues(alpha: 0.16),
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children.map(
            (child) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: DefaultTextStyle(
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontFamily: inheritedFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.metric});

  final NarrativeMetricSummary metric;

  @override
  Widget build(BuildContext context) {
    return Text('${metric.label} : ${_metricValue(metric)}');
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.feature});

  final NarrativeOverviewFeatureSummary feature;

  @override
  Widget build(BuildContext context) {
    return Text(
        '${feature.label} : ${_availabilityValue(feature.availability)}');
  }
}

class _OverviewLine extends StatelessWidget {
  const _OverviewLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text('$label : $value');
  }
}

String _metricCardValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    NarrativeOverviewAvailability.unavailable => 'Indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'Non évalué',
    NarrativeOverviewAvailability.outOfScope => 'Hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'Nécessite un modèle',
  };
}

String _metricValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    _ => _availabilityValue(metric.availability),
  };
}

String _metricSupportLabel(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available => 'Disponible',
    NarrativeOverviewAvailability.empty => 'Disponible',
    NarrativeOverviewAvailability.unavailable => metric.unavailableMessage,
    NarrativeOverviewAvailability.notEvaluated => 'Validation non lancée',
    NarrativeOverviewAvailability.outOfScope =>
      metric.id == 'quests' ? 'Pas de modèle Quest' : metric.unavailableMessage,
    NarrativeOverviewAvailability.needsModel => 'Registre absent',
  };
}

String _availabilityValue(NarrativeOverviewAvailability availability) {
  return switch (availability) {
    NarrativeOverviewAvailability.available => 'disponible',
    NarrativeOverviewAvailability.empty => '0',
    NarrativeOverviewAvailability.unavailable => 'indisponible',
    NarrativeOverviewAvailability.notEvaluated => 'non évalué',
    NarrativeOverviewAvailability.outOfScope => 'hors scope V0',
    NarrativeOverviewAvailability.needsModel => 'nécessite un modèle',
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

IconData _metricIcon(String metricId) {
  return switch (metricId) {
    'chapters' => CupertinoIcons.book_fill,
    'scenes' => CupertinoIcons.rectangle_stack_fill,
    'cutscenes' => CupertinoIcons.film_fill,
    'quests' => CupertinoIcons.flag_fill,
    'dialogues' => CupertinoIcons.chat_bubble_2_fill,
    'open_issues' => CupertinoIcons.exclamationmark_triangle_fill,
    _ => CupertinoIcons.chart_bar_fill,
  };
}

String _editorialStatusLabel(NarrativeEditorialValidationState state) {
  return switch (state) {
    NarrativeEditorialValidationState.notEvaluated => 'Non évalué',
    NarrativeEditorialValidationState.upToDate => 'À jour',
    NarrativeEditorialValidationState.toReview => 'À revoir',
    NarrativeEditorialValidationState.blocking => 'Bloquant',
  };
}

String _projectHealthLabel(NarrativeProjectHealthKind healthKind) {
  return switch (healthKind) {
    NarrativeProjectHealthKind.notEvaluated => 'Non évalué',
    NarrativeProjectHealthKind.healthy => 'Sain',
    NarrativeProjectHealthKind.reviewNeeded => 'À revoir',
    NarrativeProjectHealthKind.blocked => 'Bloqué',
  };
}
