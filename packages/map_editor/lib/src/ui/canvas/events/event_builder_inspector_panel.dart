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
    final sceneLabel = event.sceneAction.isMissing
        ? 'Aucune scène choisie'
        : event.sceneAction.sceneLabel;
    final conditionsLabel = event.conditions.isEmpty
        ? 'Aucune condition'
        : '${event.conditions.length} condition${event.conditions.length > 1 ? 's' : ''}';
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InspectorLine(label: 'Nom', value: event.displayName),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _InspectorLine(
                          label: 'Statut',
                          value: event.statusLabel,
                        ),
                      ),
                      PokeMapBadge(
                        label: event.statusLabel,
                        variant: _statusVariant(event.status),
                      ),
                    ],
                  ),
                  _InspectorLine(
                    label: 'Type de déclencheur',
                    value: event.trigger.label,
                  ),
                  _InspectorLine(
                    label: 'Conditions',
                    value: conditionsLabel,
                  ),
                  _InspectorLine(
                    label: 'Scène liée',
                    value: sceneLabel,
                  ),
                  _InspectorLine(
                    label: 'Comportement',
                    value: event.behavior.label,
                  ),
                  _InspectorLine(
                    label: 'Position sur la carte',
                    value: 'x ${event.position.x}, y ${event.position.y}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            PokeMapCard(
              borderRadius: 8,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InspectorLine(
                    label: 'Résumé projeté',
                    value: _worldImpactsInspectorLabel(event.worldImpacts),
                  ),
                  _InspectorLine(
                    label: 'Règles liées',
                    value: _worldRulesInspectorLabel(event.worldRules),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const PokeMapButton(
              onPressed: null,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.medium,
              leading: Icon(CupertinoIcons.location),
              child: Text('Voir sur la carte'),
            ),
            const SizedBox(height: 8),
            Text(
              'La navigation carte reste secondaire dans ce lot.',
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                height: 1.3,
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
  });

  final String label;
  final String value;

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
              color: colors.textPrimary,
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

String _worldImpactsInspectorLabel(
  List<EventBuilderWorldImpactReadModel> impacts,
) {
  if (impacts.isEmpty) {
    return 'Aucune source projetée';
  }
  return '${impacts.length} source${impacts.length > 1 ? 's' : ''} projetée${impacts.length > 1 ? 's' : ''}';
}

String _worldRulesInspectorLabel(EventBuilderWorldRulesProjection projection) {
  return switch (projection.status) {
    EventBuilderWorldRulesProjectionStatus.noWorldImpacts =>
      'Aucune source d’état',
    EventBuilderWorldRulesProjectionStatus.noMatchingRules =>
      'Aucune règle liée',
    EventBuilderWorldRulesProjectionStatus.hasMatchingRules =>
      '${projection.rules.length} règle${projection.rules.length > 1 ? 's' : ''} concernée${projection.rules.length > 1 ? 's' : ''}',
  };
}
