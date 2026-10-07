import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flame/components.dart';
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:path/path.dart' as p;

import '../application/character_animation_source_resolver.dart';
import '../application/runtime_map_bundle.dart';
import '../application/load_runtime_map_bundle.dart';
import '../application/dialogue_runtime_models.dart';
import '../application/resolve_dialogue.dart';
import '../application/load_dialogue_content.dart';
import '../presentation/flutter/dialogue_presentation_snapshot.dart';
import '../presentation/flame/dialogue_overlay_component.dart';
import '../presentation/flame/dialogue_text_speed.dart';

final class SpatialExplorationSession {
  SpatialExplorationSession._(
      this.bundle, this.character, this.movement, this._images, this._textures);
  RuntimeMapBundle bundle;
  ProjectCharacterEntry character;
  SpatialMovementController movement;
  final Map<String, ui.Image> _images;
  final Map<String, SpatialActorTexture> _textures;
  final _resolver = CharacterAnimationSourceResolver();
  bool _disposed = false;
  late Future<RuntimeMapBundle> Function(String) _loadMap;
  late SpatialWarpController _warps;
  final mapRevision = ValueNotifier(0);
  final transitioning = ValueNotifier(false);
  int _transferGeneration = 0;
  ({
    MapConnection connection,
    GridSize sourceSize,
    double sourceX,
    double sourceZ
  })? _connectionEntry;
  ({
    MapConnection connection,
    GridSize sourceSize,
    double sourceX,
    double sourceZ
  })? get connectionEntry => _connectionEntry;
  VoidCallback? onFrame;
  final interactionError = ValueNotifier<Object?>(null);
  final interactionActive = ValueNotifier(false);
  final dialoguePresentation =
      ValueNotifier<DialoguePresentationSnapshot?>(null);
  DialogueOverlayComponent? _dialogue;
  RuntimeDialogueTextSpeed textSpeed = RuntimeDialogueTextSpeed.instant;
  bool dialoguePaused = false;
  bool _lifecyclePaused = false;
  bool get presentationPaused => dialoguePaused || _lifecyclePaused;
  void setLifecyclePaused(bool paused) {
    if (_disposed) return;
    _lifecyclePaused = paused;
    if (paused && transitioning.value) cancelPendingTransition();
    movement.setPaused(
        presentationPaused || interactionActive.value || transitioning.value);
  }

  int _revision = 0, _interactionGeneration = 0;
  Future<Uint8List> groundImageBytes(String id) async {
    final path = bundle.runtimeImageAbsolutePathsById[id];
    if (path == null) throw StateError('Image du terrain introuvable : $id');
    return File(path).readAsBytes();
  }

  final Map<String, EntityFacing> npcFacing = {};

  void setTextSpeed(RuntimeDialogueTextSpeed value) {
    textSpeed = value;
    _dialogue?.setTextSpeed(value);
  }

  Future<void> interact() async {
    if (_disposed ||
        presentationPaused ||
        interactionActive.value ||
        transitioning.value) {
      return;
    }
    final entity = findSpatialNpcInteraction(
        scene: bundle.map.spatialScene!,
        entities: bundle.map.entities,
        x: movement.x,
        z: movement.z,
        facing: movement.facing);
    if (entity == null) return;
    final resolved = resolveDialogue(
        entityId: entity.id,
        ref: entity.npc?.dialogue,
        projectRootDirectory: bundle.projectRootDirectory,
        dialogues: bundle.manifest.dialogues);
    if (resolved == null) return;
    interactionError.value = null;
    final generation = ++_interactionGeneration;
    npcFacing[entity.id] =
        spatialNpcFacingPlayer(entity, x: movement.x, z: movement.z);
    movement.setPaused(true);
    interactionActive.value = true;
    try {
      final loaded = await loadDialogueContent(resolved);
      if (_disposed || generation != _interactionGeneration) return;
      if (loaded == null) {
        throw StateError('Le dialogue ne peut pas être ouvert.');
      }
      final overlay = DialogueOverlayComponent(
          session: loaded,
          onFinished: (_) => closeDialogue(),
          viewportSize: Vector2(640, 480),
          renderInFlame: false,
          textSpeed: textSpeed,
          onPresentationSnapshotChanged: (_) {
            if (!_disposed && generation == _interactionGeneration) {
              _publishDialogue();
            }
          });
      _dialogue = overlay;
      await overlay.onLoad();
      if (_disposed || generation != _interactionGeneration) {
        overlay.removeFromParent();
        return;
      }
      _publishDialogue();
    } on Object catch (error) {
      if (!_disposed && generation == _interactionGeneration) {
        interactionError.value = error;
        _dialogue?.removeFromParent();
        _dialogue = null;
      }
    } finally {
      if (!_disposed &&
          generation == _interactionGeneration &&
          _dialogue == null) {
        closeDialogue();
      }
    }
  }

  void dispatchDialogueCommand(DialoguePresentationCommand command) {
    final snapshot = dialoguePresentation.value;
    if (_disposed ||
        presentationPaused ||
        snapshot == null ||
        !validateDialoguePresentationCommand(snapshot, command).accepted) {
      return;
    }
    if (command is DialogueAdvanceCommand) {
      _dialogue?.advance();
    }
  }

  void _publishDialogue() {
    final dialogue = _dialogue;
    final state = dialogue?.currentSession.state;
    if (dialogue == null || state is! DialogueShowingLine) {
      closeDialogue();
      return;
    }
    dialoguePresentation.value = buildDialoguePresentationSnapshot(
        session: dialogue.currentSession,
        revision: ++_revision,
        visibleText: dialogue.visibleText,
        isCurrentLineFullyRevealed: dialogue.isCurrentLineFullyRevealed);
  }

  void closeDialogue() {
    if (_disposed) return;
    _interactionGeneration++;
    _dialogue?.removeFromParent();
    _dialogue = null;
    dialoguePresentation.value = null;
    movement.setPaused(presentationPaused || transitioning.value);
    interactionActive.value = false;
  }

  static Future<SpatialExplorationSession> load(
    RuntimeMapBundle bundle, {
    GridPos? arrival,
    EntityFacing? facing,
    Future<RuntimeMapBundle> Function(String)? loadMap,
  }) async {
    final scene = bundle.map.spatialScene;
    if (scene == null ||
        bundle.manifest.settings.dimension != ProjectDimension.threeD) {
      throw StateError('Une carte 3D est requise.');
    }
    final id = bundle.manifest.settings.defaultPlayerCharacterId;
    final character =
        bundle.manifest.characters.where((v) => v.id == id).firstOrNull;
    if (character == null || character.animations.isEmpty) {
      throw StateError(
          'Choisissez un héros animé dans les réglages du projet.');
    }
    for (final direction in [
      EntityFacing.north,
      EntityFacing.south,
      EntityFacing.east,
      EntityFacing.west
    ]) {
      if (!character.animations.any((v) =>
          v.direction == direction &&
          v.state == CharacterAnimationState.walk &&
          v.frames.isNotEmpty)) {
        throw StateError('Animation de marche absente : ${direction.name}');
      }
    }
    final characters = <ProjectCharacterEntry>{character};
    for (final entity in bundle.map.entities
        .where((entity) => entity.kind == MapEntityKind.npc)) {
      final npcCharacter = bundle.manifest.characters
          .where((c) => c.id == entity.npc?.characterId)
          .firstOrNull;
      if (npcCharacter == null) {
        throw StateError('Personnage du PNJ absent : ${entity.id}');
      }
      characters.add(npcCharacter);
    }
    final movement = SpatialMovementController.fromMap(
        map: bundle.map,
        models: bundle.manifest.models3d,
        arrival: arrival,
        facing: facing);
    final images = <String, ui.Image>{},
        textures = <String, SpatialActorTexture>{};
    try {
      final paths = bundle.runtimeImageAbsolutePathsById;
      final ids = {
        for (final actor in characters)
          for (final animation in actor.animations)
            if (animation.sourceAssetId case final asset?
                when asset.trim().isNotEmpty)
              characterAnimationRuntimeImageId(asset)
            else
              actor.tilesetId
      };
      for (final imageId in ids) {
        final path = paths[imageId];
        if (path == null) {
          throw StateError('Image du héros introuvable : $imageId');
        }
        final codec =
            await ui.instantiateImageCodec(await File(path).readAsBytes());
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        images[imageId] = image;
        textures[imageId] = await SpatialActorTexture.fromImage(image);
      }
      final session = SpatialExplorationSession._(
          bundle, character, movement, images, textures);
      session._loadMap = loadMap ??
          (id) => loadRuntimeMapBundle(
              projectFilePath:
                  p.join(bundle.projectRootDirectory, 'project.json'),
              mapId: id,
              preloadedManifest: bundle.manifest);
      session._warps =
          SpatialWarpController(map: bundle.map, x: movement.x, z: movement.z);
      for (final actor in characters) {
        for (final animation in actor.animations) {
          if (animation.frames.isEmpty) {
            throw StateError('Animation du héros vide.');
          }
          for (final frame in animation.frames) {
            final resolved = session._resolve(animation, frame, actor: actor);
            final image = images[resolved.imageId]!;
            final rect = resolved.sourceRect;
            if (frame.durationMs <= 0 ||
                rect.left < 0 ||
                rect.top < 0 ||
                rect.width <= 0 ||
                rect.height <= 0 ||
                rect.right > image.width ||
                rect.bottom > image.height) {
              throw StateError('Frame du héros invalide.');
            }
          }
        }
      }
      session.frames(0);
      return session;
    } on Object {
      for (final image in images.values) {
        image.dispose();
      }
      rethrow;
    }
  }

  ResolvedCharacterAnimationFrameSource _resolve(
          CharacterAnimation animation, CharacterAnimationFrame frame,
          {ProjectCharacterEntry? actor}) =>
      _resolver.resolveFrame(
          character: actor ?? character,
          animation: animation,
          frame: frame,
          tileWidth: bundle.manifest.settings.tileWidth,
          tileHeight: bundle.manifest.settings.tileHeight,
          availableImageIds: _images.keys.toSet()) ??
      (throw StateError('Source d’animation du héros indisponible.'));
  SpatialActorVisual frame(double dt) {
    if (!_disposed) {
      movement.update(dt);
      if (!presentationPaused &&
          !interactionActive.value &&
          !transitioning.value) {
        final warp = _warps.update(
            x: movement.x,
            z: movement.z,
            facing: movement.facing,
            bumpedCell: movement.bumpedCell);
        if (warp != null) {
          unawaited(enterWarp(warp));
        } else {
          final direction = movement.edgeExitDirection;
          final connection = direction == null
              ? null
              : findMapConnection(bundle.map, direction);
          if (connection != null) unawaited(enterConnection(connection));
        }
      }
      onFrame?.call();
      if (!presentationPaused && dt.isFinite && dt > 0) {
        _dialogue?.update(dt.clamp(0.0, .05));
      }
    }
    final state = movement.moving
        ? (movement.running
            ? CharacterAnimationState.run
            : CharacterAnimationState.walk)
        : CharacterAnimationState.idle;
    final animation = character.animations
            .where((v) => v.state == state && v.direction == movement.facing)
            .firstOrNull ??
        character.animations
            .where((v) =>
                v.state == CharacterAnimationState.walk &&
                v.direction == movement.facing)
            .firstOrNull;
    if (animation == null) {
      throw StateError(
          'Animation directionnelle du héros absente : ${movement.facing.name}');
    }
    final total =
        animation.frames.fold<int>(0, (sum, frame) => sum + frame.durationMs);
    var remaining = (movement.animationSeconds * 1000).floor();
    remaining =
        animation.loop ? remaining % total : remaining.clamp(0, total - 1);
    var selected = animation.frames.last;
    for (final frame in animation.frames) {
      if (remaining < frame.durationMs) {
        selected = frame;
        break;
      }
      remaining -= frame.durationMs;
    }
    final resolved = _resolve(animation, selected);
    return SpatialActorVisual(
        x: movement.x,
        y: movement.y,
        z: movement.z,
        texture: _textures[resolved.imageId]!,
        frame: resolved.sourceRect);
  }

  Map<String, SpatialActorVisual> frames(double dt) {
    final hero = frame(dt);
    return {
      'hero': hero,
      for (final entity in bundle.map.entities
          .where((entity) => entity.kind == MapEntityKind.npc))
        'npc:${entity.id}': npcFrame(entity)
    };
  }

  SpatialActorVisual npcFrame(MapEntity entity) {
    final actor = bundle.manifest.characters
        .firstWhere((c) => c.id == entity.npc!.characterId);
    final facing = npcFacing[entity.id] ?? entity.npc!.facing;
    final animation = actor.animations
            .where((clip) =>
                clip.direction == facing &&
                clip.state == CharacterAnimationState.idle)
            .firstOrNull ??
        actor.animations.firstWhere((clip) =>
            clip.direction == facing &&
            clip.state == CharacterAnimationState.walk);
    final source = _resolve(animation, animation.frames.first, actor: actor);
    final x = entity.pos.x + .5, z = entity.pos.y + .5;
    return SpatialActorVisual(
        x: x,
        z: z,
        y: bundle.map.spatialScene!.worldHeightAt(x, z),
        texture: _textures[source.imageId]!,
        frame: source.sourceRect);
  }

  Future<List<int>> modelBytes(String id) async {
    final model = bundle.manifest.models3d.where((v) => v.id == id).firstOrNull;
    if (model == null) throw StateError('Modèle absent : $id');
    return File(p.join(bundle.projectRootDirectory, model.relativePath))
        .readAsBytes();
  }

  Future<void> enterWarp(MapWarp warp) async {
    if (!bundle.map.warps.contains(warp)) return;
    await _transfer(warp.targetMapId, (_) => warp.targetPos);
  }

  Future<void> enterConnection(MapConnection connection) async {
    if (!bundle.map.connections.contains(connection) ||
        movement.edgeExitDirection != connection.direction) {
      return;
    }
    final source = bundle.map;
    final sourcePos = GridPos(x: movement.x.floor(), y: movement.z.floor());
    final sourceHeight = movement.y;
    final entry = (
      connection: connection,
      sourceSize: source.size,
      sourceX: movement.x,
      sourceZ: movement.z
    );
    await _transfer(connection.targetMapId, (next) {
      final arrival = resolveConnectedMapTargetPos(
          sourcePos: sourcePos,
          sourceSize: source.size,
          targetSize: next.size,
          direction: connection.direction,
          offset: connection.offset);
      if (arrival == null) {
        throw StateError(
            'Le bord de la connexion ne rejoint pas la destination.');
      }
      final scene = next.spatialScene;
      if (scene == null ||
          (scene.worldHeightAt(arrival.x + .5, arrival.y + .5) - sourceHeight)
                  .abs() >
              .25) {
        throw StateError('La hauteur de la connexion 3D est incompatible.');
      }
      return arrival;
    }, connectionEntry: entry);
  }

  Future<RuntimeMapBundle> loadConnectionNeighbor(
      MapConnection connection) async {
    if (_disposed || !bundle.map.connections.contains(connection)) {
      throw StateError('La connexion ne possède pas de voisin actif.');
    }
    final root = bundle.projectRootDirectory;
    final next = await _loadMap(connection.targetMapId);
    _validateDestination(next, connection.targetMapId, root);
    return next;
  }

  static void _validateDestination(
      RuntimeMapBundle next, String targetMapId, String root) {
    final scene = next.map.spatialScene;
    if (next.map.id != targetMapId ||
        p.normalize(next.projectRootDirectory) != p.normalize(root) ||
        next.manifest.settings.dimension != ProjectDimension.threeD ||
        scene == null ||
        scene.width != next.map.size.width ||
        scene.depth != next.map.size.height) {
      throw StateError('La destination du passage est invalide.');
    }
  }

  Future<void> _transfer(
      String targetMapId, GridPos Function(MapData) resolveArrival,
      {({
        MapConnection connection,
        GridSize sourceSize,
        double sourceX,
        double sourceZ
      })? connectionEntry}) async {
    if (_disposed ||
        transitioning.value ||
        presentationPaused ||
        interactionActive.value) {
      return;
    }
    final generation = ++_transferGeneration;
    final facing = movement.facing;
    final diagonal = movement.allowDiagonalMovement;
    movement.setPaused(true);
    interactionError.value = null;
    transitioning.value = true;
    SpatialExplorationSession? candidate;
    try {
      final next = await _loadMap(targetMapId);
      if (_disposed || generation != _transferGeneration) return;
      _validateDestination(next, targetMapId, bundle.projectRootDirectory);
      candidate = await load(next,
          arrival: resolveArrival(next.map), facing: facing, loadMap: _loadMap);
      if (_disposed || generation != _transferGeneration) return;
      for (final id in next.map.spatialScene!.instances
          .map((instance) => instance.modelId)
          .toSet()) {
        await ModelByteLoader.load(
            Uint8List.fromList(await candidate.modelBytes(id)));
      }
      final ground = SpatialGroundPlan(next.map, next.manifest);
      ground.resolve(0);
      for (final id in ground.imageIds) {
        final codec = await ui
            .instantiateImageCodec(await candidate.groundImageBytes(id));
        try {
          (await codec.getNextFrame()).image.dispose();
        } finally {
          codec.dispose();
        }
      }
      if (_disposed || generation != _transferGeneration) return;
      for (final entry in candidate._images.entries) {
        if (_images.containsKey(entry.key)) {
          entry.value.dispose();
        } else {
          _images[entry.key] = entry.value;
          _textures[entry.key] = candidate._textures[entry.key]!;
        }
      }
      candidate._images.clear();
      final nextMovement = candidate.movement;
      final nextWarps = candidate._warps;
      candidate.dispose();
      candidate = null;
      bundle = next;
      movement = nextMovement;
      _warps = nextWarps;
      movement.setDiagonalMovement(diagonal);
      npcFacing.clear();
      _connectionEntry = connectionEntry;
      mapRevision.value++;
    } on Object catch (error) {
      if (!_disposed && generation == _transferGeneration) {
        interactionError.value = error;
      }
    } finally {
      candidate?.dispose();
      if (!_disposed && generation == _transferGeneration) {
        movement.setPaused(presentationPaused || interactionActive.value);
        transitioning.value = false;
        onFrame?.call();
      }
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _transferGeneration++;
    onFrame = null;
    _interactionGeneration++;
    _dialogue?.removeFromParent();
    _dialogue = null;
    interactionError.dispose();
    interactionActive.dispose();
    dialoguePresentation.dispose();
    mapRevision.dispose();
    transitioning.dispose();
    movement.setPaused(true);
    for (final image in _images.values) {
      image.dispose();
    }
  }

  void cancelPendingTransition() {
    if (_disposed) return;
    _transferGeneration++;
    movement.setPaused(true);
    transitioning.value = false;
  }

  void resetPosition() {
    if (_disposed || transitioning.value) return;
    closeDialogue();
    movement.reset();
    movement.setPaused(presentationPaused);
    _warps =
        SpatialWarpController(map: bundle.map, x: movement.x, z: movement.z);
  }
}
