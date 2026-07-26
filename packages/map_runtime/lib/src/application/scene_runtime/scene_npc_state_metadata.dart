import 'package:map_core/map_core.dart';

String sceneNpcPresenceMetadataKey({
  required String mapId,
  required String entityId,
}) =>
    'pokemap.npcPresence.${mapId.trim()}.${entityId.trim()}';

bool? sceneNpcPresenceOverride(
  GameState gameState, {
  required String mapId,
  required String entityId,
}) {
  return switch (gameState.metadata[
      sceneNpcPresenceMetadataKey(mapId: mapId, entityId: entityId)]) {
    'present' => true,
    'hidden' => false,
    _ => null,
  };
}
