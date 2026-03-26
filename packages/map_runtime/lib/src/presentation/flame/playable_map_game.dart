import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/load_runtime_map_bundle.dart';
import '../../application/runtime_map_bundle.dart';
import '../../infrastructure/tile_image_loader.dart';
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

  @override
  Future<void> onLoad() async {
    _world = GameplayWorldState.fromMap(_bundle.map);
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
    final intent = _intentFromKey(event.logicalKey);
    if (intent == null) return KeyEventResult.ignored;

    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _player.updateState(_world.player);
    _applyCamera();

    if (result is WarpTriggered) {
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

  Future<void> _handleWarp(TriggeredWarp warp) async {
    _transitioning = true;
    try {
      final newBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: _world.player.facing,
      );
      final images =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);

      world.remove(_layers);
      world.remove(_player);

      _bundle = newBundle;
      _world = newWorld;
      _layers =
          MapLayersComponent(bundle: newBundle, tileImagesByTilesetId: images);
      _player = PlayerComponent(bundle: newBundle, state: _world.player);

      await world.add(_layers);
      await world.add(_player);
      _applyCamera();
    } catch (_) {
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
