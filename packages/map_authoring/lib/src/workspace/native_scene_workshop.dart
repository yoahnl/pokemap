part of 'project_snapshot_loader.dart';

final class _NativeSceneWorkshop {
  _NativeSceneWorkshop(String actionId, Map<String, Object?> parameters,
      Map<String, dynamic>? previousScene) {
    if (actionId == 'scene.upsert' || actionId == 'scene.upsert_batch') {
      final scenes = actionId == 'scene.upsert_batch'
          ? decodeAuthoringSceneBatch(parameters)
          : [
              decodeAuthoringScene(
                  Map<String, dynamic>.from(parameters['scene'] as Map))
            ];
      for (final scene in scenes) {
        targetSceneIds.add(scene.id);
        nodes.addAll(scene.graph.nodes);
      }
    } else {
      final updates = actionId == 'scene.graph.patch'
          ? decodeSceneGraphPatchNodes(parameters)
          : const <SceneNode>[];
      final replaced = {
        for (final node in updates) node.id,
        if (parameters['removeNodeIds'] case final List removed)
          ...removed.whereType<String>(),
        if (parameters['nodeId'] case final String nodeId) nodeId,
      };
      if (parameters['sceneId'] case final String sceneId) {
        targetSceneIds.add(sceneId);
      }
      if (previousScene != null) {
        nodes.addAll(SceneAsset.fromJson(previousScene)
            .graph
            .nodes
            .where((node) => !replaced.contains(node.id)));
      }
      nodes.addAll(updates);
    }
    for (final node in nodes) {
      if (node.payload
          case SceneActionPayload(
            consequence: SceneSetNpcPoseConsequence(
              :final mapId,
              :final entityId
            )
          )) {
        poseOwners.putIfAbsent(mapId, () => {}).add(entityId);
      }
    }
  }

  final nodes = <SceneNode>[];
  final targetSceneIds = <String>{};
  final references = SceneWorkshopReferences();
  final poseOwners = <String, Set<String>>{};

  void selectDocuments(void Function(String, Iterable<String>) add,
      Map<String, dynamic> raw, Map<String, dynamic> projected) {
    add('scenes', targetSceneIds);
    final dependencies = buildNarrativeDependencyIndex(
      project:
          const ProjectManifest(name: 'Scene workshop', maps: [], tilesets: []),
      additionalSceneNodes: nodes,
    );
    references.collect(dependencies.usages, add);
    if (references.stepIds.isNotEmpty && raw['storylines'] is List) {
      for (final story in (raw['storylines'] as List).whereType<Map>()) {
        final chapters = story['chapters'];
        if (chapters is! List) continue;
        final ownsStep = chapters.whereType<Map>().any((chapter) =>
            chapter['steps'] is List &&
            (chapter['steps'] as List)
                .whereType<Map>()
                .any((step) => references.stepIds.contains(step['id'])));
        if (ownsStep && story['id'] is String) {
          add('storylines', [story['id'] as String]);
        }
      }
    }
    if (raw['newGame'] case final Map config
        when references.starterIds.isNotEmpty) {
      projected['newGame'] = {
        'starterOptions': [
          for (final option in (config['starterOptions'] as List? ?? const [])
              .whereType<Map>())
            if (references.starterIds.contains(option['id'])) option,
        ],
      };
    }
    if (raw['railJourneyCatalog'] case final Map catalog
        when references.journeyIds.isNotEmpty) {
      final journeys = (catalog['journeys'] as List? ?? const [])
          .whereType<Map>()
          .where((journey) => references.journeyIds.contains(journey['id']))
          .toList();
      if (journeys.isNotEmpty) {
        projected['railJourneyCatalog'] = {...catalog, 'journeys': journeys};
      }
    }
  }
}
