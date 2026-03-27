import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/dialogue_runtime_models.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'dialogue_overlay_component.dart';
import 'map_layers_component.dart';
import 'player_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
  }) : _bundle = bundle;

  final String projectFilePath;
  RuntimeMapBundle _bundle;
  late GameplayWorldState _world;
  late MapLayersComponent _layers;
  late PlayerComponent _player;
  bool _transitioning = false;
  DialogueOverlayComponent? _dialogueOverlay;
  TextComponent? _notification;

  @override
  Future<void> onLoad() async {
    try {
      _world = GameplayWorldState.fromMap(_bundle.map);
      debugPrint(
        '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } on GameplaySpawnResolutionException catch (e) {
      debugPrint('[runtime] Spawn resolution failed ($e), falling back to (0,0)');
      _world = GameplayWorldState.initial(
        map: _bundle.map,
        playerPos: const GridPos(x: 0, y: 0),
      );
    }
    final images =
        await loadTilesetImagesById(_bundle.tilesetAbsolutePathsById);
    _layers =
        MapLayersComponent(bundle: _bundle, tileImagesByTilesetId: images);
    _player = PlayerComponent(bundle: _bundle, state: _world.player);
    await world.add(_layers);
    await world.add(_player);
    _applyCamera();
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (_transitioning) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    if (_dialogueOverlay != null) {
      final overlay = _dialogueOverlay!;
      if (overlay.isShowingChoices) {
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          _moveChoiceCursor(-1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _moveChoiceCursor(1);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.keyE ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _confirmDialogueChoice();
          return KeyEventResult.handled;
        }
      } else {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.keyE ||
                event.logicalKey == LogicalKeyboardKey.space)) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _handleInteract();
      return KeyEventResult.handled;
    }

    final intent = _intentFromKey(event.logicalKey);
    if (intent == null) return KeyEventResult.ignored;

    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _player.updateState(_world.player);
    _applyCamera();

    if (result is Blocked) {
      debugPrint('[move] Blocked at (${_world.player.pos.x}, ${_world.player.pos.y})');
    }

    if (result is WarpTriggered) {
      debugPrint(
        '[warp] Triggered warp ${result.warp.warpId} → map=${result.warp.targetMapId} pos=(${result.warp.targetPos.x}, ${result.warp.targetPos.y})',
      );
      _handleWarp(result.warp);
    }

    return KeyEventResult.handled;
  }

  GameplayIntent? _intentFromKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return const MoveIntent(Direction.north);
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return const MoveIntent(Direction.south);
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return const MoveIntent(Direction.west);
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return const MoveIntent(Direction.east);
    }
    return null;
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;

    switch (result) {
      case NothingToInteract():
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        _tryOpenDialogue(entity.id, entity.npc?.dialogue, entity.inspectorHeadline);
      case SignInteracted(:final entity):
        debugPrint('[interact] Sign: ${entity.id}');
        _tryOpenDialogue(entity.id, entity.sign?.dialogue, entity.inspectorHeadline);
      case ItemInteracted(:final entity):
        debugPrint('[interact] Item: ${entity.id}');
        _showNotification(entity.inspectorHeadline);
      case EntityInteracted(:final entity):
        debugPrint('[interact] Entity: ${entity.id}');
        _showNotification(entity.inspectorHeadline);
      default:
        break;
    }
  }

  void _tryOpenDialogue(String entityId, DialogueRef? ref, String fallbackLabel) {
    if (_dialogueOverlay != null) return;

    final resolved = resolveDialogue(
      entityId: entityId,
      ref: ref,
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      _showNotification(fallbackLabel);
      return;
    }

    loadDialogueContent(resolved).then((session) {
      if (_dialogueOverlay != null) return;
      if (session == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
        _showNotification(fallbackLabel);
        return;
      }
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    });
  }

  void _openDialogue(DialogueSession session) {
    _notification?.removeFromParent();
    _notification = null;

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      onFinished: () {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
      },
    );
    camera.viewport.add(overlay);
    _dialogueOverlay = overlay;
    final openedState = session.state;
    if (openedState is DialogueShowingLine) {
      debugPrint('[dialogue] opened node=${session.currentNodeTitle} text="${openedState.text}"');
    } else if (openedState is DialogueWaitingForChoice) {
      debugPrint('[dialogue] opened node=${session.currentNodeTitle} choice count=${openedState.choices.length}');
    }
  }

  void _advanceDialogue() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.advance();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _moveChoiceCursor(int delta) {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    overlay.moveCursor(delta);
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice moved selected=${state.selectedIndex}');
    }
  }

  void _confirmDialogueChoice() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      final idx = state.selectedIndex;
      debugPrint('[dialogue] choice confirmed index=$idx text="${state.choices[idx].text}"');
    }
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.confirmChoice();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    final paint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        backgroundColor: Color(0xAA000000),
      ),
    );
    final component = TextComponent(
      text: text,
      textRenderer: paint,
      anchor: Anchor.topCenter,
    );
    component.position = Vector2(
      camera.viewport.size.x / 2,
      camera.viewport.size.y - 48,
    );
    camera.viewport.add(component);
    _notification = component;
    Future.delayed(const Duration(seconds: 2), () {
      if (_notification == component) {
        component.removeFromParent();
        _notification = null;
      }
    });
  }

  Future<void> _handleWarp(TriggeredWarp warp) async {
    _transitioning = true;
    try {
      final newBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: _world.player.facing,
      );

      world.remove(_layers);
      world.remove(_player);

      _bundle = newBundle;
      _world = newWorld;
      _layers =
          MapLayersComponent(bundle: newBundle, tileImagesByTilesetId: newImages);
      _player = PlayerComponent(bundle: newBundle, state: _world.player);

      await world.add(_layers);
      await world.add(_player);
      _applyCamera();
      debugPrint('[warp] Transition complete → map=${newBundle.map.id}');
    } catch (e, st) {
      debugPrint('[warp] Transition failed: $e\n$st');
      _showNotification('Warp failed');
    } finally {
      _transitioning = false;
    }
  }

  void _applyCamera() {
    final cw = _bundle.cellWidth;
    final ch = _bundle.cellHeight;
    final mw = _bundle.map.size.width * cw;
    final mh = _bundle.map.size.height * ch;
    final vw = math.min(_kViewportTilesX * cw, mw);
    final vh = math.min(_kViewportTilesY * ch, mh);
    camera.viewfinder.visibleGameSize = Vector2(vw, vh);
    camera.viewfinder.position = Vector2(
      (_world.player.pos.x + 0.5) * cw,
      (_world.player.pos.y + 0.5) * ch,
    );
  }
}
