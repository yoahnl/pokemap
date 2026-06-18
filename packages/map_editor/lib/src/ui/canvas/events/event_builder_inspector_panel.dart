import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

class EventBuilderInspectorPanel extends StatelessWidget {
  const EventBuilderInspectorPanel({
    super.key,
    required this.event,
  });

  final EventBuilderEventSummary event;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      key: const ValueKey('event-builder-inspector-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.sidebar_right,
                  tone: PokeMapTone.info,
                  size: 38,
                  iconSize: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inspecteur d’événement',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Détails structurés de l’événement sélectionné.',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PokeMapCard(
              borderRadius: 8,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.displayName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PokeMapBadge(
                        label: event.statusLabel,
                        variant: _statusVariant(event.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InspectorLine(
                    label: 'Déclencheur',
                    value: event.trigger.label,
                  ),
                  _InspectorLine(
                    label: 'Action',
                    value: event.sceneAction.label,
                  ),
                  _InspectorLine(
                    label: 'Réutilisation',
                    value: event.behavior.label,
                  ),
                  _InspectorLine(
                    label: 'Conditions',
                    value: event.conditions.isEmpty
                        ? 'Aucune condition'
                        : '${event.conditions.length} condition${event.conditions.length > 1 ? 's' : ''}',
                  ),
                  _InspectorLine(
                    label: 'Résultats Scene',
                    value: _sceneOutcomesInspectorLabel(event.sceneOutcomes),
                  ),
                  _InspectorLine(
                    label: 'Lifecycle',
                    value: _lifecycleInspectorLabel(event.lifecycle),
                  ),
                  _InspectorLine(
                    label: 'Changements monde',
                    value: _worldImpactsInspectorLabel(event.worldImpacts),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PokeMapCard(
              borderRadius: 8,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Informations techniques',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InspectorLine(
                    label: 'ID technique',
                    value: event.technicalId,
                    secondary: true,
                  ),
                  _InspectorLine(
                    label: 'Groupe',
                    value: event.groupKey,
                    secondary: true,
                  ),
                  _InspectorLine(
                    label: 'Position',
                    value: 'x ${event.position.x}, y ${event.position.y}',
                    secondary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorLine extends StatelessWidget {
  const _InspectorLine({
    required this.label,
    required this.value,
    this.secondary = false,
  });

  final String label;
  final String value;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: secondary ? colors.textSecondary : colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

PokeMapBadgeVariant _statusVariant(EventBuilderEventStatus status) {
  return switch (status) {
    EventBuilderEventStatus.active => PokeMapBadgeVariant.success,
    EventBuilderEventStatus.draft => PokeMapBadgeVariant.warning,
    EventBuilderEventStatus.inactive => PokeMapBadgeVariant.neutral,
    EventBuilderEventStatus.invalid => PokeMapBadgeVariant.error,
  };
}

String _sceneOutcomesInspectorLabel(
  EventBuilderSceneOutcomesProjection projection,
) {
  return switch (projection.status) {
    EventBuilderSceneOutcomesProjectionStatus.hasDeclaredOutcomes =>
      projection.label,
    EventBuilderSceneOutcomesProjectionStatus.noSceneTarget =>
      'Aucune scène liée',
    EventBuilderSceneOutcomesProjectionStatus.missingScene =>
      'Scène introuvable',
    EventBuilderSceneOutcomesProjectionStatus.noDeclaredOutcomes =>
      'Aucun résultat déclaré',
  };
}

String _lifecycleInspectorLabel(EventBuilderLifecycleProjection lifecycle) {
  return switch (lifecycle.status) {
    EventBuilderLifecycleProjectionStatus.reusableNoConsumptionNeeded =>
      'Réutilisable',
    EventBuilderLifecycleProjectionStatus.oneShotNoSceneTarget ||
    EventBuilderLifecycleProjectionStatus.oneShotMissingScene ||
    EventBuilderLifecycleProjectionStatus.oneShotIntentOnly =>
      'Une seule fois à vérifier',
    EventBuilderLifecycleProjectionStatus
          .oneShotExplicitSceneConsequenceForThisEvent =>
      'Une seule fois compatible Scene',
    EventBuilderLifecycleProjectionStatus
          .oneShotExplicitSceneConsequenceForAnotherEvent =>
      'Attention consommation autre événement',
  };
}

String _worldImpactsInspectorLabel(
  List<EventBuilderWorldImpactReadModel> impacts,
) {
  if (impacts.isEmpty) {
    return 'Aucun changement détecté';
  }
  return '${impacts.length} effet${impacts.length > 1 ? 's' : ''} prévisible${impacts.length > 1 ? 's' : ''}';
}
