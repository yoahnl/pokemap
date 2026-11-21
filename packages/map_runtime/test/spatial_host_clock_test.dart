import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('spatial-host-clock-');
    await File('${directory.path}/hero.png')
        .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
  });

  tearDown(() => directory.delete(recursive: true));

  Future<_ClockProbe> load(WidgetTester tester) async {
    final session = (await tester.runAsync(
      () => SpatialExplorationSession.load(_bundle(directory.path)),
    ))!;
    addTearDown(session.dispose);
    return _ClockProbe(session);
  }

  Iterable<SpatialSceneView> scenes(WidgetTester tester) => tester
      .widgetList<SpatialSceneView>(find.byType(SpatialSceneView));

  void present(WidgetTester tester) {
    for (final scene in scenes(tester)) {
      scene.onReady!();
    }
  }

  Future<void> frame(WidgetTester tester, {int reads = 0}) async {
    for (var read = 0; read < reads; read++) {
      for (final scene in scenes(tester)) {
        scene.actorFrames!(.02);
      }
    }
    await tester.pump(const Duration(milliseconds: 20));
  }

  testWidgets('the session waits for the first presentation before ticking', (
    tester,
  ) async {
    final probe = await load(tester);
    await tester.pumpWidget(probe.app());
    for (var index = 0; index < 3; index++) {
      await frame(tester, reads: 2);
    }
    expect(probe.ticks, isEmpty);
    expect(probe.session.presentationSeconds, 0);

    present(tester);
    await frame(tester);
    await frame(tester);

    expect(probe.ticks, [(.02, false), (.02, false)]);
  });

  testWidgets('reading the presentation never advances the session', (
    tester,
  ) async {
    final reference = await load(tester);
    reference.session.movement.setInput(x: 1, z: 0);
    for (var index = 0; index < 6; index++) {
      reference.session.frames(.02);
    }

    final probe = await load(tester);
    await tester.pumpWidget(probe.app());
    present(tester);
    probe.session.movement.setInput(x: 1, z: 0);
    for (final reads in [0, 1, 5, 0, 3, 1]) {
      await frame(tester, reads: reads);
    }

    expect(probe.ticks, List.filled(6, (.02, false)));
    expect(probe.session.movement.x, greaterThan(0));
    expect(probe.state, reference.state);
    final visuals = scenes(tester).single.actorFrames!(.02);
    scenes(tester).single.actorFrames!(.02);
    expect(scenes(tester).single.actorFrames!(.02), visuals);
    expect(probe.state, reference.state);
  });

  testWidgets('a second view of the session adds no tick and takes over', (
    tester,
  ) async {
    final probe = await load(tester);
    final secondVisible = ValueNotifier(true);
    final firstVisible = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            for (final visible in [firstVisible, secondVisible])
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: visible,
                  builder: (_, shown, _) => shown
                      ? SpatialExplorationView(
                          session: probe.session,
                          keyboardInputEnabled: false,
                        )
                      : const SizedBox(),
                ),
              ),
          ],
        ),
      ),
    );
    expect(scenes(tester), hasLength(2));
    present(tester);
    for (var index = 0; index < 3; index++) {
      await frame(tester, reads: 2);
    }
    expect(probe.ticks, List.filled(3, (.02, false)));

    firstVisible.value = false;
    await tester.pump(const Duration(milliseconds: 20));
    await frame(tester);
    await frame(tester);

    expect(scenes(tester), hasLength(1));
    expect(probe.ticks, hasLength(6));
    expect(probe.ticks.skip(3).map((tick) => tick.$1), everyElement(.02));
  });

  testWidgets('a muted view freezes the session without a catch-up delta', (
    tester,
  ) async {
    final probe = await load(tester);
    final enabled = ValueNotifier(true);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: enabled,
          builder: (_, value, child) => TickerMode(enabled: value, child: child!),
          child: SpatialExplorationView(
            session: probe.session,
            keyboardInputEnabled: false,
          ),
        ),
      ),
    );
    present(tester);
    await frame(tester);
    expect(probe.ticks, [(.02, false)]);

    enabled.value = false;
    await tester.pump();
    expect(probe.ticks, [(.02, false), (0, false)]);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(probe.ticks, hasLength(2));

    enabled.value = true;
    await tester.pump();
    await frame(tester);

    expect(probe.ticks, [(.02, false), (0, false), (.02, false)]);
    expect(probe.session.presentationSeconds, closeTo(.04, 1e-9));
  });

  testWidgets('covered preparation and resizes keep one tick per frame', (
    tester,
  ) async {
    final probe = await load(tester);
    var covered = false;
    await tester.pumpWidget(probe.app(renderPreparationPaused: () => covered));
    present(tester);
    await frame(tester);
    covered = true;
    await frame(tester, reads: 3);
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pump();
    covered = false;
    await frame(tester, reads: 1);

    expect(probe.ticks, [(.02, false), (.02, false), (0, false), (.02, false)]);
    probe.session.dialoguePaused = true;
    await frame(tester);
    expect(probe.ticks.last, (.02, true));
    probe.session.dialoguePaused = false;
  });

  testWidgets('a disposed view releases the clock to the next view', (
    tester,
  ) async {
    final probe = await load(tester);
    await tester.pumpWidget(probe.app());
    present(tester);
    await frame(tester);
    await tester.pumpWidget(const SizedBox());
    expect(probe.ticks, [(.02, false), (0, false)]);
    await frame(tester);
    expect(probe.ticks, hasLength(2));

    await tester.pumpWidget(probe.app());
    await frame(tester);
    expect(probe.ticks, hasLength(2));
    present(tester);
    await frame(tester);

    expect(probe.ticks, hasLength(3));
  });
}

final class _ClockProbe {
  _ClockProbe(this.session) {
    session.onPresentationFrame = (dt, paused) => ticks.add((dt, paused));
  }

  final SpatialExplorationSession session;
  final ticks = <(double, bool)>[];

  (double, double, double, double) get state => (
    session.movement.x,
    session.movement.z,
    session.presentationSeconds,
    session.environmentClock.elapsedSeconds,
  );

  Widget app({bool Function()? renderPreparationPaused}) => MaterialApp(
    home: SpatialExplorationView(
      session: session,
      keyboardInputEnabled: false,
      renderPreparationPaused: renderPreparationPaused,
    ),
  );
}

RuntimeMapBundle _bundle(String root) => RuntimeMapBundle(
  manifest: ProjectManifest(
    version: ProjectVersion.v9,
    name: 'Clock',
    settings: const ProjectSettings(
      dimension: ProjectDimension.threeD,
      defaultPlayerCharacterId: 'hero',
    ),
    maps: const [],
    tilesets: const [],
    characters: [
      ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'unused',
        animations: [
          for (final facing in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.walk,
              direction: facing,
              sourceAssetId: 'hero',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                  durationMs: 100,
                ),
              ],
            ),
        ],
      ),
    ],
  ),
  map: MapData(
    version: ProjectVersion.v9,
    id: 'field',
    name: 'Field',
    size: const GridSize(width: 8, height: 8),
    spatialScene: MapSpatialScene(width: 8, depth: 8),
  ),
  projectRootDirectory: root,
  tilesetAbsolutePathsById: const {},
  characterAnimationAbsolutePathsByAssetId: {'hero': '$root/hero.png'},
);
