import 'package:map_core/map_core.dart';

import 'narrative_authoring_exception.dart';

SceneAsset decodeAuthoringScene(Map<String, dynamic> json) {
  try {
    return SceneAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.invalid',
      'The Scene payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

Iterable<SceneAsset> decodeAuthoringSceneBatch(
    Map<String, Object?> parameters) sync* {
  final rawScenes = parameters['scenes'];
  if (parameters.keys.any((key) => key != 'scenes') ||
      rawScenes is! List ||
      rawScenes.isEmpty ||
      rawScenes.length > 128) {
    throw NarrativeAuthoringException('scene.batch_invalid',
        'A Scene batch must contain between 1 and 128 scenes.');
  }
  final ids = <String>{};
  for (var index = 0; index < rawScenes.length; index++) {
    final raw = rawScenes[index];
    if (raw is! Map<String, dynamic>) {
      throw NarrativeAuthoringException(
          'scene.invalid', 'The Scene payload is invalid.',
          details: {'index': index});
    }
    final scene = decodeAuthoringScene(raw);
    if (!ids.add(scene.id)) {
      throw NarrativeAuthoringException('scene.batch_duplicate_id',
          'Scene identities must be unique within a batch.',
          details: {'index': index, 'sceneId': scene.id});
    }
    yield scene;
  }
}

List<SceneNode> decodeSceneGraphPatchNodes(Map<String, Object?> parameters) {
  final values = parameters['upsertNodes'] ?? const [];
  if (values is List && values.every((value) => value is Map)) {
    try {
      return [
        for (final value in values)
          SceneNode.fromJson(Map<String, dynamic>.from(value as Map)),
      ];
    } on Object catch (error) {
      if (error is! FormatException &&
          error is! ArgumentError &&
          error is! ValidationException &&
          error is! TypeError) {
        rethrow;
      }
    }
  }
  throw NarrativeAuthoringException(
    'scene.graph.invalid_patch',
    'The graph patch contains invalid nodes.',
    details: {'sceneId': parameters['sceneId'], 'field': 'upsertNodes'},
  );
}

bool introducesPeriodicReward(
    String actionId, Map<String, Object?> parameters) {
  bool isReward(Object? command) =>
      command is Map && command['kind'] == 'claimPeriodicReward';
  bool hasReward(Object? scene) {
    if (scene is! Map || scene['graph'] is! Map) return false;
    final nodes = (scene['graph'] as Map)['nodes'];
    return nodes is List &&
        nodes.whereType<Map>().any((node) {
          final payload = node['payload'];
          return payload is Map && isReward(payload['interactiveCommand']);
        });
  }

  return switch (actionId) {
    'scene.interactive_command.set' => isReward(parameters['command']),
    'scene.upsert' => hasReward(parameters['scene']),
    'scene.upsert_batch' when parameters['scenes'] is List =>
      (parameters['scenes'] as List).any(hasReward),
    _ => false,
  };
}

final class SceneWorkshopReferences {
  final rewardSceneIds = <String>{};
  final stepIds = <String>{};
  final itemIds = <String>{};
  final eventIds = <String>{};
  final journeyIds = <String>{};
  final starterIds = <String>{};
  final imageIds = <String>{};
  final entityIds = <String, Set<String>>{};

  void collect(Iterable<NarrativeDependencyUsage> usages,
      void Function(String, Iterable<String>) add) {
    for (final usage in usages) {
      final target = usage.target;
      if (target.kind == NarrativeDependencyTargetKind.scene &&
          usage.path.endsWith('.rewardReference.sceneId')) {
        rewardSceneIds.add(target.id);
        continue;
      }
      switch (target.kind) {
        case NarrativeDependencyTargetKind.fact:
          add('facts', [target.id]);
        case NarrativeDependencyTargetKind.badge:
          add('badges', [target.id]);
        case NarrativeDependencyTargetKind.item:
          itemIds.add(target.id);
        case NarrativeDependencyTargetKind.scene:
          add('scenes', [target.id]);
        case NarrativeDependencyTargetKind.dialogue:
          add('dialogues', [target.id]);
        case NarrativeDependencyTargetKind.cinematic:
          add('cinematics', [target.id]);
        case NarrativeDependencyTargetKind.media:
          add('cinematicMediaAssets', [target.id]);
        case NarrativeDependencyTargetKind.storyline:
          add('storylines', [target.id]);
        case NarrativeDependencyTargetKind.step:
          stepIds.add(target.id);
        case NarrativeDependencyTargetKind.worldRule:
          add('worldRules', [target.id]);
        case NarrativeDependencyTargetKind.railJourney:
          journeyIds.add(target.id);
        case NarrativeDependencyTargetKind.sourceMap:
          if (target.physicalMapId case final String mapId) {
            add('maps', [mapId]);
            if (target.sourceKind == 'entity') {
              entityIds.putIfAbsent(mapId, () => {}).add(target.id);
            }
          }
          switch (target.sourceKind) {
            case 'encounterTable':
              add('encounterTables', [target.id]);
            case 'presentationCinematic':
              add('presentationCinematics', [target.id]);
            case 'starterOption':
              starterIds.add(target.id);
            case 'projectMedia':
              imageIds.add(target.id);
            case 'shop':
              add('shops', [target.id]);
            case 'battle':
              for (final prefix in ['trainer:', 'static:']) {
                if (target.id.startsWith(prefix)) {
                  add('trainers', [target.id.substring(prefix.length)]);
                }
              }
          }
        case NarrativeDependencyTargetKind.eventV2:
          eventIds.add(target.id);
        case NarrativeDependencyTargetKind.chapter:
          break;
      }
    }
  }
}
