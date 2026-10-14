import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/overworld_actor_component.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'visual invisibility hides NPC pixels while preserving presence and motion',
    () async {
      final actor = OverworldActorComponent(
        character: const ProjectCharacterEntry(
          id: 'door',
          name: 'Door',
          tilesetId: 'door',
        ),
        tileImages: const {},
        tileWidth: 32,
        tileHeight: 32,
        cellWidth: 32,
        cellHeight: 32,
      );
      actor.configureGridPlacement(
        pos: const GridPos(x: 0, y: 0),
        footprint: const GridSize(width: 1, height: 1),
        mapOrigin: Vector2.zero(),
      );
      expect(await _hasPixels(actor), isTrue);
      actor.isVisible = false;
      expect(await _hasPixels(actor), isFalse);
      expect(actor.isGameplayPresent, isTrue);
      expect(actor.containsLocalPoint(Vector2(4, 4)), isTrue);
      final originalX = actor.position.x;
      expect(
        actor.startGridStep(
          to: const GridPos(x: 1, y: 0),
          facing: EntityFacing.east,
          durationSeconds: .25,
        ),
        isTrue,
      );
      actor.update(.125);
      expect(actor.isStepping, isTrue);
      expect(actor.position.x, greaterThan(originalX));
      actor.update(.125);
      expect(actor.isStepping, isFalse);
      expect(actor.gridPos, const GridPos(x: 1, y: 0));
      actor.isVisible = true;
      expect(await _hasPixels(actor), isTrue);
      actor.setGameplayVisible(false);
      expect(await _hasPixels(actor), isFalse);
      expect(actor.containsLocalPoint(Vector2(4, 4)), isFalse);
    },
  );

  test(
    'visual invisibility hides the player while animation and feet continue',
    () async {
      final bundle = RuntimeMapBundle(
        manifest: const ProjectManifest(
          name: 'Actor visibility',
          maps: [],
          tilesets: [],
          settings: ProjectSettings(tileWidth: 32, tileHeight: 32),
        ),
        map: const MapData(
          id: 'map',
          name: 'Map',
          size: GridSize(width: 4, height: 4),
        ),
        projectRootDirectory: '/tmp/actor-visibility',
        tilesetAbsolutePathsById: const {},
      );
      GameplayPlayerState stateAt(int x) => GameplayPlayerState.fromGridSpawn(
        cell: GridPos(x: x, y: 1),
        facing: Direction.east,
        tileWidthPx: 32,
        tileHeightPx: 32,
        mapWidthCells: 4,
        mapHeightCells: 4,
      );
      final player = PlayerComponent(bundle: bundle, state: stateAt(1));
      await player.onLoad();
      expect(await _hasPixels(player), isTrue);
      player.isVisible = false;
      expect(await _hasPixels(player), isFalse);
      final originalFoot = player.footPoint.clone();
      player.startStep(stateAt(2), durationSeconds: .25);
      player.update(.125);
      expect(player.isStepping, isTrue);
      expect(player.footPoint.x, greaterThan(originalFoot.x));
      player.update(.125);
      expect(player.isStepping, isFalse);
      player.isVisible = true;
      expect(await _hasPixels(player), isTrue);
    },
  );
}

Future<bool> _hasPixels(PositionComponent component) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(-component.position.x, -component.position.y);
  component.renderTree(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(128, 128);
  try {
    final data = await image.toByteData();
    final bytes = data!.buffer.asUint8List();
    for (var offset = 3; offset < bytes.length; offset += 4) {
      if (bytes[offset] != 0) return true;
    }
    return false;
  } finally {
    image.dispose();
    picture.dispose();
  }
}
