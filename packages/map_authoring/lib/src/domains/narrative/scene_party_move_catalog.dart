import 'dart:convert';
import 'package:map_core/map_core.dart';
import '../../workspace/project_snapshot.dart';
import 'narrative_authoring_exception.dart';

bool sceneNeedsPartyMoveCatalog(SceneAsset scene) => scene.graph.nodes.any(
    (node) =>
        node.payload is SceneConditionPayload &&
        (node.payload as SceneConditionPayload).conditionSource?.partyMoveId !=
            null);

Future<Set<String>> loadScenePartyMoveCatalog(ProjectSnapshot snapshot) async {
  try {
    if (!snapshot.manifest.pokemon.enabled ||
        !snapshot.manifest.pokemon.catalogFiles.containsKey('moves')) {
      throw const FormatException('Moves catalogue unavailable.');
    }
    final length =
        snapshot.storedResources['pokemonCatalog:moves']?.byteLength ??
            snapshot.inlineResourceBytes['pokemonCatalog:moves']?.length;
    if (length != null && length > 8 * 1024 * 1024) {
      throw const FormatException('Moves catalogue exceeds its read limit.');
    }
    final bytes = await snapshot.readResourceBytes('pokemonCatalog:moves');
    if (bytes == null || bytes.length > 8 * 1024 * 1024) {
      throw const FormatException('Moves catalogue unavailable.');
    }
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! Map<String, dynamic> ||
        json['entries'] is! List ||
        (json['entries'] as List)
            .any((entry) => entry is! Map<String, dynamic>)) {
      throw const FormatException('Moves catalogue malformed.');
    }
    final catalog = PokemonCatalogFile.fromJson(json);
    if (catalog.kind != 'catalog' || catalog.catalog != 'moves') {
      throw const FormatException('Wrong catalogue.');
    }
    final ids = <String>{};
    for (final entry in catalog.entries) {
      final id = entry['id'];
      if (id is! String || id.isEmpty || id.trim() != id || !ids.add(id)) {
        throw const FormatException('Invalid or duplicate move identity.');
      }
    }
    return Set.unmodifiable(ids);
  } on Object {
    throw NarrativeAuthoringException('scene.party_move_catalog_unavailable',
        'Party move conditions require a readable catalogue with unique canonical move identities.');
  }
}

void validateScenePartyMoves(SceneAsset scene, Set<String> moveIds) {
  for (final node in scene.graph.nodes) {
    final payload = node.payload;
    if (payload is! SceneConditionPayload) continue;
    final moveId = payload.conditionSource?.partyMoveId;
    if (moveId != null && !moveIds.contains(moveId)) {
      throw NarrativeAuthoringException('scene.party_move_ref_unknown',
          'The selected party move is not in the active project catalogue.',
          details: {'sceneId': scene.id, 'nodeId': node.id, 'moveId': moveId});
    }
  }
}
