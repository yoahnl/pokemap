import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:map_core/map_core.dart';

const int kEntityEditorFrameDurationFallbackMs = 200;

class ResolvedEntityElementVisual {
  const ResolvedEntityElementVisual({
    required this.image,
    required this.srcRect,
  });

  final ui.Image image;
  final Rect srcRect;
}

int entityEditorFrameDurationMs(TilesetVisualFrame frame) {
  final d = frame.durationMs;
  if (d == null || d <= 0) {
    return kEntityEditorFrameDurationFallbackMs;
  }
  return d;
}

TilesetVisualFrame entityEditorPickFrame(
  List<TilesetVisualFrame> frames,
  int elapsedMs,
) {
  if (frames.isEmpty) {
    throw StateError('ProjectElementEntry.frames must not be empty');
  }
  if (frames.length == 1) {
    return frames.first;
  }
  var total = 0;
  for (final f in frames) {
    total += entityEditorFrameDurationMs(f);
  }
  if (total <= 0) {
    return frames.first;
  }
  var t = elapsedMs % total;
  if (t < 0) {
    t = (t % total + total) % total;
  }
  for (final f in frames) {
    final d = entityEditorFrameDurationMs(f);
    if (t < d) {
      return f;
    }
    t -= d;
  }
  return frames.last;
}

Rect? _sourceRectForFrameInImage({
  required TilesetVisualFrame frame,
  required ui.Image image,
  required int sourceTileWidth,
  required int sourceTileHeight,
}) {
  if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
    return null;
  }
  final src = frame.source;
  final wTiles = src.width <= 0 ? 1 : src.width;
  final hTiles = src.height <= 0 ? 1 : src.height;
  final px = src.x * sourceTileWidth;
  final py = src.y * sourceTileHeight;
  final pw = wTiles * sourceTileWidth;
  final ph = hTiles * sourceTileHeight;
  if (px < 0 ||
      py < 0 ||
      px + pw > image.width ||
      py + ph > image.height) {
    return null;
  }
  return Rect.fromLTWH(
    px.toDouble(),
    py.toDouble(),
    pw.toDouble(),
    ph.toDouble(),
  );
}

Rect? _sourceRectForCharacterFrameInImage({
  required ProjectCharacterEntry character,
  required CharacterAnimationFrame frame,
  required ui.Image image,
  required int sourceTileWidth,
  required int sourceTileHeight,
}) {
  if (sourceTileWidth <= 0 || sourceTileHeight <= 0) {
    return null;
  }
  final src = frame.source;
  final wTiles = character.frameWidth <= 0 ? 1 : character.frameWidth;
  final hTiles = character.frameHeight <= 0 ? 1 : character.frameHeight;
  final px = src.x * wTiles * sourceTileWidth;
  final py = src.y * hTiles * sourceTileHeight;
  final pw = wTiles * sourceTileWidth;
  final ph = hTiles * sourceTileHeight;
  if (px < 0 ||
      py < 0 ||
      px + pw > image.width ||
      py + ph > image.height) {
    return null;
  }
  return Rect.fromLTWH(
    px.toDouble(),
    py.toDouble(),
    pw.toDouble(),
    ph.toDouble(),
  );
}

String? _resolveNpcCharacterId(
  MapEntity entity,
  ProjectManifest project,
) {
  if (entity.kind != MapEntityKind.npc) {
    return null;
  }
  final direct = entity.npc?.characterId?.trim();
  if (direct != null && direct.isNotEmpty) {
    return direct;
  }
  final trainerId = entity.npc?.trainerId?.trim();
  if (trainerId == null || trainerId.isEmpty) {
    return null;
  }
  for (final trainer in project.trainers) {
    if (trainer.id != trainerId) {
      continue;
    }
    final fromTrainer = trainer.characterId?.trim();
    if (fromTrainer != null && fromTrainer.isNotEmpty) {
      return fromTrainer;
    }
    break;
  }
  return null;
}

CharacterAnimationFrame? _pickNpcIdleFacingFrame(
  ProjectCharacterEntry character,
  EntityFacing facing,
) {
  CharacterAnimation? idleFacing;
  CharacterAnimation? idleSouth;
  CharacterAnimation? firstIdle;
  for (final animation in character.animations) {
    if (animation.state != CharacterAnimationState.idle) {
      continue;
    }
    firstIdle ??= animation;
    if (animation.direction == facing) {
      idleFacing = animation;
      break;
    }
    if (animation.direction == EntityFacing.south) {
      idleSouth = animation;
    }
  }
  final selectedAnim = idleFacing ?? idleSouth ?? firstIdle;
  if (selectedAnim == null || selectedAnim.frames.isEmpty) {
    return null;
  }
  return selectedAnim.frames.first;
}

ResolvedEntityElementVisual? resolveNpcCharacterVisualForEditor({
  required MapEntity entity,
  required ProjectManifest project,
  required Map<String, ui.Image?> tilesetImagesById,
  required int sourceTileWidth,
  required int sourceTileHeight,
}) {
  final charId = _resolveNpcCharacterId(entity, project);
  if (charId == null) {
    return null;
  }
  ProjectCharacterEntry? character;
  for (final entry in project.characters) {
    if (entry.id == charId) {
      character = entry;
      break;
    }
  }
  if (character == null) {
    return null;
  }
  final frame = _pickNpcIdleFacingFrame(
    character,
    entity.npc?.facing ?? EntityFacing.south,
  );
  if (frame == null) {
    return null;
  }
  final tilesetId = character.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  final image = tilesetImagesById[tilesetId];
  if (image == null) {
    return null;
  }
  final srcRect = _sourceRectForCharacterFrameInImage(
    character: character,
    frame: frame,
    image: image,
    sourceTileWidth: sourceTileWidth,
    sourceTileHeight: sourceTileHeight,
  );
  if (srcRect == null) {
    return null;
  }
  return ResolvedEntityElementVisual(image: image, srcRect: srcRect);
}

ResolvedEntityElementVisual? resolveEntityElementVisualForEditor({
  required MapEntity entity,
  required ProjectManifest? project,
  required Map<String, ui.Image?> tilesetImagesById,
  required int sourceTileWidth,
  required int sourceTileHeight,
  required int editorAnimationTimeMs,
}) {
  if (project == null) {
    return null;
  }
  final characterVisual = resolveNpcCharacterVisualForEditor(
    entity: entity,
    project: project,
    tilesetImagesById: tilesetImagesById,
    sourceTileWidth: sourceTileWidth,
    sourceTileHeight: sourceTileHeight,
  );
  if (characterVisual != null) {
    return characterVisual;
  }
  final elementId = entity.resolvedProjectElementIdForEditor;
  if (elementId == null) {
    return null;
  }
  ProjectElementEntry? entry;
  for (final e in project.elements) {
    if (e.id == elementId) {
      entry = e;
      break;
    }
  }
  if (entry == null || entry.frames.isEmpty) {
    return null;
  }
  final frame =
      entityEditorPickFrame(entry.frames, editorAnimationTimeMs);
  final tilesetId = frame.tilesetId.trim().isNotEmpty
      ? frame.tilesetId.trim()
      : entry.tilesetId.trim();
  if (tilesetId.isEmpty) {
    return null;
  }
  final image = tilesetImagesById[tilesetId];
  if (image == null) {
    return null;
  }
  final srcRect = _sourceRectForFrameInImage(
    frame: frame,
    image: image,
    sourceTileWidth: sourceTileWidth,
    sourceTileHeight: sourceTileHeight,
  );
  if (srcRect == null) {
    return null;
  }
  return ResolvedEntityElementVisual(image: image, srcRect: srcRect);
}

bool mapEntitiesNeedEditorFrameAnimation(
  MapData map,
  ProjectManifest? project,
) {
  if (project == null || map.entities.isEmpty) {
    return false;
  }
  final byId = <String, ProjectElementEntry>{
    for (final e in project.elements) e.id: e,
  };
  for (final ent in map.entities) {
    final id = ent.resolvedProjectElementIdForEditor;
    if (id == null) {
      continue;
    }
    final entry = byId[id];
    if (entry != null && entry.frames.length > 1) {
      return true;
    }
  }
  return false;
}

void collectTilesetIdsForEntityEditorVisuals({
  required MapData map,
  required ProjectManifest? project,
  required void Function(String tilesetId) onTilesetId,
}) {
  if (project == null) {
    return;
  }
  final byId = <String, ProjectElementEntry>{
    for (final e in project.elements) e.id: e,
  };
  final charactersById = <String, ProjectCharacterEntry>{
    for (final c in project.characters) c.id: c,
  };
  final trainersById = <String, ProjectTrainerEntry>{
    for (final t in project.trainers) t.id: t,
  };
  for (final ent in map.entities) {
    if (ent.kind == MapEntityKind.npc) {
      final direct = ent.npc?.characterId?.trim();
      String? charId;
      if (direct != null && direct.isNotEmpty) {
        charId = direct;
      } else {
        final trainerId = ent.npc?.trainerId?.trim();
        if (trainerId != null && trainerId.isNotEmpty) {
          final fromTrainer = trainersById[trainerId]?.characterId?.trim();
          if (fromTrainer != null && fromTrainer.isNotEmpty) {
            charId = fromTrainer;
          }
        }
      }
      if (charId != null) {
        final characterTileset = charactersById[charId]?.tilesetId.trim() ?? '';
        if (characterTileset.isNotEmpty) {
          onTilesetId(characterTileset);
          continue;
        }
      }
    }
    final id = ent.resolvedProjectElementIdForEditor;
    if (id == null) {
      continue;
    }
    final entry = byId[id];
    if (entry == null || entry.frames.isEmpty) {
      continue;
    }
    for (final frame in entry.frames) {
      final tid = frame.tilesetId.trim().isNotEmpty
          ? frame.tilesetId.trim()
          : entry.tilesetId.trim();
      if (tid.isNotEmpty) {
        onTilesetId(tid);
      }
    }
  }
}
