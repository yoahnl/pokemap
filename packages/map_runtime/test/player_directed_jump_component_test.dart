import 'dart:ui' as ui;

import '../../map_gameplay/test/support/border_jump_fixture.dart';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/presentation/flame/player_component.dart';

({MapData map, ProjectManifest project}) _nativeFixture() {
  final base = BorderJumpFixture(
    points: const [GridPos(x: 2, y: 2), GridPos(x: 3, y: 2)],
  );
  final definition = base.revision.definition;
  final revision = BorderBlueprintRevision(
    revision: base.revision.revision,
    definition: BorderBlueprintPublishedDefinition(
      name: definition.name,
      previewSeed: definition.previewSeed,
      template: definition.template,
      primitives: definition.primitives,
      defaults: definition.defaults,
      sortOrder: definition.sortOrder,
      jumpBehavior: BorderJumpBehavior(
        side: BorderLineSide.primary,
        durationMs: 500,
        peakHeightPx: 24,
      ),
    ),
  );
  final project = base.project.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 7,
      records: [
        BorderBlueprintRecord(
          id: base.feature.blueprintId,
          draft: base.project.borderCatalog.records.single.draft,
          latestPublished: revision,
        ),
      ],
      visualSnapshots: base.project.borderCatalog.visualSnapshots,
    ),
  );
  final feature = base.feature;
  final resolved = resolveLedgeLineBorderWithEvidence(
    BorderResolutionRequest(
      mapSize: base.map.size,
      tileSizePx: const GridSize(width: 32, height: 32),
      blueprintId: feature.blueprintId,
      blueprintRevision: revision,
      feature: feature,
      visualSnapshots: project.borderCatalog.visualSnapshots,
      resolverVersion: borderResolverVersion,
    ),
  );
  expect(resolved.result.canApply, isTrue);
  return (
    map: base.map.copyWith(
      id: 'jump',
      layers: [
        MapLayer.border(
          id: 'original-borders',
          name: 'Borders',
          content: BorderLayerContent(
            formatVersion: 4,
            features: [
              BorderFeature(
                id: feature.id,
                name: feature.name,
                blueprintId: feature.blueprintId,
                seed: feature.seed,
                geometry: feature.geometry,
                lineSide: feature.lineSide,
                overrides: feature.overrides,
                keepOutRegions: feature.keepOutRegions,
                materialization: resolved.result.materialization,
              ),
            ],
          ),
        ),
        MapLayer.tile(
          id: 'objects',
          name: 'Objects',
          cells: List.filled(144, 0),
        ),
      ],
    ),
    project: project,
  );
}

GameplayPlayerState _state(GridPos cell) => GameplayPlayerState.fromGridSpawn(
  cell: cell,
  facing: Direction.south,
  tileWidthPx: 32,
  tileHeightPx: 32,
  mapWidthCells: 12,
  mapHeightCells: 12,
  spriteWidthPx: 64,
  spriteHeightPx: 64,
);

RuntimeMapBundle _bundle({double scale = 1}) => RuntimeMapBundle(
  manifest: _nativeFixture().project.copyWith(
    settings: ProjectSettings(
      tileWidth: 32,
      tileHeight: 32,
      displayScale: scale,
    ),
  ),
  map: _nativeFixture().map,
  projectRootDirectory: '/tmp/jump',
  tilesetAbsolutePathsById: const {},
);

DirectedJumpPlan _plan({int duration = 500, int height = 24}) =>
    DirectedJumpPlan(
      binding: bindMaterializedBorderJumpFaces(
        map: _nativeFixture().map,
        project: _nativeFixture().project,
        tileSize: const PixelSize(width: 32, height: 32),
      ).single,
      direction: Direction.south,
      sourcePos: const GridPos(x: 2, y: 1),
      viaPos: const GridPos(x: 2, y: 2),
      landingPos: const GridPos(x: 2, y: 3),
      sourcePositionPx: _state(const GridPos(x: 2, y: 1)).playerPositionPx,
      landingPositionPx: _state(const GridPos(x: 2, y: 3)).playerPositionPx,
      durationMs: duration,
      peakHeightPx: height,
    );

Future<PlayerComponent> _component({double scale = 1}) async {
  final player = PlayerComponent(
    bundle: _bundle(scale: scale),
    state: _state(const GridPos(x: 2, y: 1)),
    mapOrigin: Vector2(7, 11),
    characterEntry: const ProjectCharacterEntry(
      id: 'player',
      name: 'Player',
      tilesetId: 'player',
      frameWidth: 2,
      frameHeight: 2,
    ),
  );
  await player.onLoad();
  return player;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('jump animates the legs and draws its shadow at ground level', () async {
    final player = await _component();
    player.startDirectedJump(
      _state(const GridPos(x: 2, y: 3)),
      plan: _plan(),
      onComplete: () {},
    );
    expect(player.debugStepAnimationState, CharacterAnimationState.walk);
    player.update(.25);
    final recorder = ui.PictureRecorder();
    player.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final rendered = await picture.toImage(128, 128);
    final bytes = (await rendered.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    expect(bytes.getUint8((63 * 128 + 32) * 4 + 3), greaterThan(0));
    expect(bytes.getUint8((39 * 128 + 32) * 4 + 3), 0);
    rendered.dispose();
    picture.dispose();
    player.update(.25);
    final stoppedRecorder = ui.PictureRecorder();
    player.render(ui.Canvas(stoppedRecorder));
    final stoppedPicture = stoppedRecorder.endRecording();
    final stoppedImage = await stoppedPicture.toImage(128, 128);
    final stoppedBytes = (await stoppedImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    expect(stoppedBytes.getUint8((63 * 128 + 32) * 4 + 3), 0);
    stoppedImage.dispose();
    stoppedPicture.dispose();
  });

  test('jump has a 500ms ground translation and a 24px visual peak with unchanged feet', () async {
    final player = await _component();
    final from = player.position.clone();
    final foot = player.footPoint.clone();
    var completions = 0;
    player.startDirectedJump(
      _state(const GridPos(x: 2, y: 3)),
      plan: _plan(),
      onComplete: () => completions++,
    );
    expect(player.isJumping, isTrue);
    expect(player.isStepping, isTrue);
    player.update(.25);
    expect(player.position.x, from.x);
    expect(player.position.y, closeTo(from.y + 32, .000001));
    expect(player.footPoint.y, closeTo(foot.y + 32, .000001));
    expect(player.debugJumpLiftPx, closeTo(24, .000001));
    expect(player.debugActorLocalPosition!.y, closeTo(-24, .000001));
    expect(completions, 0);
    player.update(.25);
    expect(player.position.y, closeTo(from.y + 64, .000001));
    expect(player.footPoint.y, closeTo(foot.y + 64, .000001));
    expect(player.debugActorLocalPosition!.y, 0);
    expect(player.debugJumpLiftPx, 0);
    expect(player.isJumping, isFalse);
    expect(player.isStepping, isFalse);
    expect(completions, 1);
    player.update(2);
    expect(completions, 1);
  });

  test(
    'large dt completes once and pixel lift follows display scale',
    () async {
      final player = await _component(scale: 2);
      var completions = 0;
      final from = player.position.clone();
      player.startDirectedJump(
        _state(const GridPos(x: 2, y: 3)),
        plan: _plan(),
        onComplete: () => completions++,
      );
      player.update(.25);
      expect(player.debugJumpLiftPx, 48);
      expect(player.position.y, from.y + 64);
      player.update(4);
      player.update(4);
      expect(completions, 1);
      expect(player.debugJumpLiftPx, 0);
      expect(player.position.y, from.y + 128);
    },
  );

  test(
    'fractional updates totaling 500ms complete without an extra frame',
    () async {
      final player = await _component();
      var completions = 0;
      player.startDirectedJump(
        _state(const GridPos(x: 2, y: 3)),
        plan: _plan(),
        onComplete: () => completions++,
      );
      player.update(.49);
      expect(completions, 0);
      player.update(.01);
      expect(completions, 1);
      expect(player.isJumping, isFalse);
    },
  );

  test(
    'cancel removal and map state replacement cannot deliver stale completion',
    () async {
      for (final cancel in [
        (PlayerComponent p) => p.cancelDirectedJump(),
        (PlayerComponent p) => p.onRemove(),
        (PlayerComponent p) =>
            p.syncState(_state(const GridPos(x: 0, y: 0)), snapToGrid: true),
      ]) {
        final player = await _component();
        var completions = 0;
        player.startDirectedJump(
          _state(const GridPos(x: 2, y: 3)),
          plan: _plan(),
          onComplete: () => completions++,
        );
        player.update(.1);
        cancel(player);
        player.update(2);
        expect(completions, 0);
        expect(player.isJumping, isFalse);
        expect(player.debugJumpLiftPx, 0);
      }
    },
  );

  test('invalid duration and lift reject before motion and invalid landing is refused', () async {
    for (final plan in [_plan(duration: 0), _plan(height: -1)]) {
      final player = await _component();
      final from = player.position.clone();
      expect(
        () => player.startDirectedJump(
          _state(const GridPos(x: 2, y: 3)),
          plan: plan,
          onComplete: () {},
        ),
        throwsArgumentError,
      );
      expect(player.isJumping, isFalse);
      expect(player.position, from);
    }
    final player = await _component();
    expect(
      () => player.startDirectedJump(
        _state(const GridPos(x: 2, y: 4)),
        plan: _plan(),
        onComplete: () {},
      ),
      throwsArgumentError,
    );
  });
}
