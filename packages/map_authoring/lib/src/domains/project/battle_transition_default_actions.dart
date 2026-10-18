import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../assets/tileset_actions.dart';

final class BattleTransitionDefaultActions {
  const BattleTransitionDefaultActions();

  static const String updateActionId = 'project.battle_transitions.update';

  static final List<AuthoringActionDescriptor> descriptors =
      List.unmodifiable(<AuthoringActionDescriptor>[
    visualLibraryDescriptor(
      updateActionId,
      'Define project-owned battle transition effects and select project defaults',
      resourceKinds: const <String>['project', 'battleTransitionDefinition'],
      inputSchema: {
        'type': 'object', 'additionalProperties': false,
        'properties': {
          'definitions': {'type': 'array', 'minItems': 1, 'maxItems': 256,
            'items': battleTransitionDefinitionJsonSchema},
          'wildTransitionId': {'type': ['string', 'null']},
          'trainerTransitionId': {'type': ['string', 'null']},
        },
      },
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId != updateActionId) {
      throw VisualLibraryException(
        'battle_transitions.action_unsupported',
        'The requested battle transition action is unsupported.',
      );
    }
    final parameters = VisualLibraryParameters(context.request.parameters);
    parameters.allow(const <String>{'wildTransitionId', 'trainerTransitionId', 'definitions'});

    final manifest = context.snapshot.manifest;
    final current = manifest.battleTransitions;
    final definitions = <String, BattleTransitionDefinition>{
      for (final definition in current?.definitions ?? const <BattleTransitionDefinition>[]) definition.id: definition,
    };
    if (context.request.parameters.containsKey('definitions')) {
      final raw = context.request.parameters['definitions'];
      if (raw is! List || raw.isEmpty || raw.length > 256) {
        throw const FormatException('Provide 1..256 typed battle transition definitions.');
      }
      final incoming = raw.map(BattleTransitionDefinition.fromJson).toList();
      if (incoming.map((definition) => definition.id).toSet().length != incoming.length) {
        throw const FormatException('Battle transition definition IDs must be distinct.');
      }
      for (final definition in incoming) {
        definitions[definition.id] = definition;
      }
    }
    final catalog = ProjectBattleTransitionConfig(definitions: definitions.values.toList());
    catalog.validate();
    final wild = _readTransition(
      parameters: context.request.parameters,
      key: 'wildTransitionId',
      allowed: battleTransitionIdsForUsage(catalog, BattleTransitionUsage.wild),
      fallback: current?.wildTransitionId,
    );
    final trainer = _readTransition(
      parameters: context.request.parameters,
      key: 'trainerTransitionId',
      allowed: battleTransitionIdsForUsage(catalog, BattleTransitionUsage.trainer),
      fallback: current?.trainerTransitionId,
    );

    final next = wild == null && trainer == null && definitions.isEmpty
        ? manifest.copyWith(battleTransitions: null)
        : manifest.copyWith(
            battleTransitions: ProjectBattleTransitionConfig(
              wildTransitionId: wild,
              trainerTransitionId: trainer,
              definitions: definitions.values.toList(),
            ),
          );

    next.battleTransitions?.validate();
    final allowedWild = battleTransitionIdsForUsage(
        next.battleTransitions, BattleTransitionUsage.wild).toSet();
    final allowedTrainer = battleTransitionIdsForUsage(
        next.battleTransitions, BattleTransitionUsage.trainer).toSet();
    final referencedWild = <String>[
      for (final map in context.snapshot.maps) ...[
        for (final zone in map.gameplayZones)
          ...?zone.encounter?.battleTransitionIds,
        for (final layer in map.layers.whereType<SmartTileLayer>())
          ...?layer.encounterBehavior?.encounter.battleTransitionIds,
        for (final entity in map.entities)
          ...?entity.interactiveEncounter?.presentation.battleTransitionIds,
      ],
    ];
    final referencedTrainer = manifest.trainers
        .map((trainer) => trainer.battleTransitionId).whereType<String>();
    if (referencedWild.any((id) => !allowedWild.contains(id)) ||
        referencedTrainer.any((id) => !allowedTrainer.contains(id))) {
      throw const FormatException(
          'Transition definitions must preserve the usage of authored references.');
    }

    return buildVisualManifestDraft(
      context.snapshot,
      next,
      operation: updateActionId,
      path: '/battleTransitions',
      before: current?.toJson(),
      after: next.battleTransitions?.toJson(),
    );
  }
}

String? _readTransition({
  required Map<String, Object?> parameters,
  required String key,
  required List<String> allowed,
  required String? fallback,
}) {
  if (!parameters.containsKey(key)) {
    return fallback;
  }
  final value = parameters[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw VisualLibraryException(
      'battle_transitions.parameter_invalid',
      'The battle transition identifier must be a string.',
      details: <String, Object?>{'parameter': key},
    );
  }
  final id = value.trim();
  if (id.isEmpty) {
    return null;
  }
  if (!allowed.contains(id)) {
    throw VisualLibraryException(
      'battle_transitions.unknown_id',
      'The battle transition identifier is unknown for this side.',
      details: <String, Object?>{
        'parameter': key,
        'transitionId': id,
        'allowed': allowed,
      },
    );
  }
  return id;
}
