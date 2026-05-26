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
        _OverviewSection(
          title: 'Disponibilité des données principales',
          children: [
            _MetricLine(metric: readModel.metrics.dialogues),
            _MetricLine(metric: readModel.metrics.chapters),
            _MetricLine(metric: readModel.metrics.scenes),
            _MetricLine(metric: readModel.metrics.openIssues),
            _MetricLine(metric: readModel.metrics.quests),
            _MetricLine(metric: readModel.metrics.facts),
            _FeatureLine(feature: readModel.recentActivity),
            _FeatureLine(feature: readModel.notifications),
          ],
        ),
        const SizedBox(height: 12),
        const _OverviewSection(
          title: 'V0 volontairement limitée',
          children: [
            Text(
              'Les sections détaillées seront construites dans les lots suivants.',
            ),
            SizedBox(height: 6),
            Text(
              'Aucun compteur fake, aucune activité récente inventée, aucune notification simulée.',
            ),
          ],
        ),
      ],
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

String _metricValue(NarrativeMetricSummary metric) {
  return switch (metric.availability) {
    NarrativeOverviewAvailability.available ||
    NarrativeOverviewAvailability.empty =>
      '${metric.count ?? 0}',
    _ => _availabilityValue(metric.availability),
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
