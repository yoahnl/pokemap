import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/narrative_map_view.dart';
import '../models/map_entity_payloads.dart';
import '../models/map_entity_presentation.dart';
import '../models/enums.dart';
import '../models/narrative_event_definition.dart';
import '../models/project_manifest.dart';
import '../models/map_spatial_scene.dart';
import '../operations/narrative_condition_expression_evaluator.dart';
import '../operations/narrative_fact_runtime.dart';
import '../operations/map_entity_collision_footprint.dart';

MapEntityPresentationVariant? resolveMapEntityPresentation({
  required ProjectManifest project,
  required GameState gameState,
  required NarrativeMapView map,
  required MapEntity entity,
  List<NarrativeMapView> maps = const [],
  void Function()? onUnavailable,
}) {
  final presentation = entity.presentation;
  if (presentation == null) return null;
  final resolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
  NarrativeConditionEvaluation leaf(NarrativeEventCondition condition) =>
      condition.whenTyped(
        fact: (id, operator, expected) {
          final resolution = resolver.resolve(
            factId: id,
            runtimeState: gameState.narrativeFactRuntimeState,
            storyFlags: gameState.storyFlags,
          );
          if (resolution is! NarrativeFactRuntimeResolved ||
              resolution.narrativeValue.kind != expected.kind) {
            return const NarrativeConditionEvaluation(
              passed: false,
              unavailable: true,
            );
          }
          return NarrativeConditionEvaluation(
            passed: resolution.narrativeValue.matches(operator, expected),
          );
        },
        narrativeEventConsumed: (id, expected) {
          final matches =
              project.eventRegistry?.records
                  .where((record) => record.id == id)
                  .length ??
              0;
          return NarrativeConditionEvaluation(
            passed:
                matches == 1 &&
                gameState.narrativeEventProgress.consumedNarrativeEventIds
                        .contains(id) ==
                    expected,
            unavailable: matches != 1,
          );
        },
        mapEventInstanceBoolean: (mapId, eventId, key, expected) {
          final candidates = mapId == map.id
              ? [map]
              : maps.where((value) => value.id == mapId).toList();
          final scope = gameState.mapInstanceWorldState.instanceRef(mapId);
          final available =
              scope != null &&
              candidates.length == 1 &&
              candidates.single.entities
                      .where((value) => value.id == eventId)
                      .length ==
                  1;
          return NarrativeConditionEvaluation(
            passed:
                available &&
                gameState.mapInstanceWorldState.eventBoolean(
                      scope,
                      eventId,
                      key,
                    ) ==
                    expected,
            unavailable: !available,
          );
        },
      );
  for (final variant in presentation.variants) {
    final evaluation = evaluateNarrativeConditionExpression(
      variant.condition,
      evaluateLeaf: leaf,
    );
    if (evaluation.unavailable) onUnavailable?.call();
    if (evaluation.passed) return variant;
  }
  return null;
}

MapEntity? projectMapEntityPresentation({
  required ProjectManifest project,
  required GameState gameState,
  required MapData map,
  required MapEntity entity,
  List<MapData> maps = const [],
}) {
  if (entity.presentation == null) return entity;
  if (validateMapEntityPresentation(
    project: project,
    map: map,
    entity: entity,
    maps: maps,
  ).isNotEmpty)
  {
    return null;
  }
  final variant = resolveMapEntityPresentation(
    project: project,
    gameState: gameState,
    map: map,
    entity: entity,
    maps: maps,
  );
  if (variant == null) return null;
  final npc = variant.characterId == null
      ? null
      : (entity.npc ?? const MapEntityNpcData()).copyWith(
          characterId: variant.characterId,
          facing: variant.facing,
          counterInteractionSides: variant.counterInteractionSides,
        );
  return entity.copyWith(
    kind: npc == null ? MapEntityKind.custom : MapEntityKind.npc,
    npc: npc,
    editorVisual: null,
    blocksMovement: variant.blocksMovement,
    size: variant.size,
    interactionMode: variant.interactionMode,
    counterInteractionSides: variant.counterInteractionSides,
    properties: {
      for (final entry in entity.properties.entries)
        if (!entry.key.startsWith('collision.') &&
            !const {
              'collisionWidth',
              'collisionHeight',
              'collisionOffsetX',
              'collisionOffsetY',
            }.contains(entry.key))
          entry.key: entry.value,
      mapEntityCollisionWidthProperty: '${variant.size.width}',
      mapEntityCollisionHeightProperty: '${variant.size.height}',
      mapEntityCollisionOffsetXProperty: '0',
      mapEntityCollisionOffsetYProperty: '0',
    },
  );
}

MapData projectMapEntityPresentations({
  required ProjectManifest project,
  required GameState gameState,
  required MapData map,
  List<MapData> maps = const [],
}) {
  if (!map.entities.any((entity) => entity.presentation != null)) return map;
  return map.copyWith(
    entities: [
      for (final entity in map.entities)
        ?projectMapEntityPresentation(
          project: project,
          gameState: gameState,
          map: map,
          entity: entity,
          maps: maps,
        ),
    ],
  );
}

List<String> validateMapEntityPresentation({
  required ProjectManifest project,
  required NarrativeMapView map,
  required MapEntity entity,
  List<NarrativeMapView> maps = const [],
}) {
  final errors = <String>[];
  if (entity.presentation != null &&
      (!const [MapEntityKind.npc, MapEntityKind.custom].contains(entity.kind) ||
          entity.sign != null ||
          entity.item != null ||
          entity.spawn != null ||
          entity.fieldObstacle != null ||
          entity.healingDisplay != null ||
          entity.interactiveEncounter != null)) {
    errors.add('variantOwnerKindUnsupported');
  }
  for (final variant
      in entity.presentation?.variants ??
          const <MapEntityPresentationVariant>[]) {
    if ((map.spatialScene != null || map.version == ProjectVersion.v9 ||
        project.settings.dimension == ProjectDimension.threeD) && variant.counterInteractionSides.isNotEmpty) {
      errors.add('variantCounterReachSpatialUnsupported');
    }
    final x = entity.pos.x;
    final y = entity.pos.y;
    if (x < 0 ||
        y < 0 ||
        x + variant.size.width > map.size.width ||
        y + variant.size.height > map.size.height) {
      errors.add('variantFootprintOutOfBounds');
    }
    if (variant.characterId != null &&
        project.characters
                .where((value) => value.id == variant.characterId)
                .length !=
            1) {
      errors.add('variantCharacterReferenceInvalid');
    }
    for (final condition in variant.condition.leaves) {
      condition.whenTyped<void>(
        fact: (id, operator, expected) {
          if (project.facts
                  .where(
                    (value) =>
                        value.id == id && value.valueKind == expected.kind,
                  )
                  .length !=
              1) {
            errors.add('variantFactReferenceInvalid');
          }
        },
        narrativeEventConsumed: (id, expected) {
          if (project.eventRegistry?.records
                  .where((record) => record.id == id)
                  .length !=
              1) {
            errors.add('variantEventReferenceInvalid');
          }
        },
        mapEventInstanceBoolean: (mapId, eventId, key, expected) {
          if (project.settings.mapInstanceRetentionPolicy == null) {
            errors.add('variantInstanceRetentionMissing');
          }
          if (mapId != map.id || eventId != entity.id) {
            errors.add('variantInstanceOwnerMustBeSelf');
          }
          final candidates = mapId == map.id
              ? [map]
              : maps.where((value) => value.id == mapId).toList();
          if (candidates.length != 1 ||
              candidates.single.entities
                      .where((value) => value.id == eventId)
                      .length !=
                  1) {
            errors.add('variantInstanceOwnerInvalid');
          }
        },
      );
    }
  }
  return List.unmodifiable(errors.toSet());
}
