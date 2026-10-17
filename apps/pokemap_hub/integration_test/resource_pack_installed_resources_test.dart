import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

import '../test/support/resource_pack_installed_resources_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final dimension in ProjectDimension.values) {
    for (final retainTrace in [true, false]) {
      testWidgets(
        'installed imported resources survive source retirement and fresh player graphs: ${dimension.name}, trace=$retainTrace',
        (tester) async {
          expect(
            const bool.fromEnvironment('P12_INSTALLED_RESOURCES_NATIVE'),
            isTrue,
            reason:
                'Run this local integration journey on a native GPU device.',
          );
          final fixture = await InstalledResourcePackFixture.create(
            dimension: dimension,
            retainTrace: retainTrace,
          );
          addTearDown(fixture.dispose);
          await fixture.install();
          await fixture.retireSources();
          await fixture.assertInstalledClosure();
          await _playFromDisk(tester, fixture);
          await fixture.assertSourcesAbsent();
          await fixture.assertInstalledClosure();
          await _playFromDisk(tester, fixture);
          await fixture.assertMissingPayloadRejected('.png');
          if (dimension == ProjectDimension.threeD) {
            await fixture.assertMissingPayloadRejected('.glb');
          }
          await fixture.assertInstalledClosure();
          await fixture.assertSourcesAbsent();
          expect(tester.takeException(), isNull);
        },
        timeout: const Timeout(Duration(minutes: 5)),
      );
    }
  }
}

Future<void> _playFromDisk(
  WidgetTester tester,
  InstalledResourcePackFixture fixture,
) async {
  final game = await fixture.readInstalledGame();
  final preferences = HubPreferencesStore(supportRoot: fixture.supportRoot);
  await preferences.save(const PlayerPreferences(language: PlayerLanguage.fr));
  final controller = HubInstalledGamePlayerController();
  var stopped = false;
  addTearDown(() async {
    if (!stopped) await controller.stop();
  });
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      theme: PokeMapPlayerTheme.light(),
      home: HubInstalledGamePlayer(
        key: UniqueKey(),
        supportRoot: fixture.supportRoot,
        saveRepositoryFactory: (root, identity) =>
            HubSaveStore(supportRoot: root, identity: identity),
        preferencesRepository: preferences,
        controlProfileRepository: HubControlProfileStore(
          supportRoot: fixture.supportRoot,
        ),
        launchResolver: fixture.newResolver(),
        game: game,
        hostBranding: const RuntimeHostSplashBranding(
          displayName: 'TEST',
          signature: 'P12',
        ),
        splashLogo: null,
        controller: controller,
        onHubRequested: () async {
          await tester.pumpWidget(const SizedBox());
        },
      ),
    ),
  );
  try {
    await _until(
      tester,
      () => find
          .byKey(const ValueKey<String>('player-title-prompt-hit-area'))
          .evaluate()
          .isNotEmpty,
      'normal title prompt',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('player-title-prompt-hit-area')),
    );
    await _until(
      tester,
      () => find.text('Nouveau jeu').evaluate().isNotEmpty,
      'normal New Game action',
    );
    await tester.tap(find.text('Nouveau jeu'));
    final playing = find.byKey(
      const ValueKey<String>('runtime-player-surface-playing'),
    );
    final overwrite = find.byKey(
      const ValueKey<String>('scene-interaction-confirm-yes'),
    );
    await _until(
      tester,
      () => playing.evaluate().isNotEmpty || overwrite.evaluate().isNotEmpty,
      'New Game or saved-game confirmation',
    );
    if (overwrite.evaluate().isNotEmpty) {
      await tester.tap(overwrite);
    }
    await _until(
      tester,
      () => find
          .byKey(const ValueKey<String>('runtime-player-surface-playing'))
          .evaluate()
          .isNotEmpty,
      'loaded runtime surface after normal New Game',
    );
    await fixture.assertSourcesAbsent();
    PlayableMapGame? flameGame;
    if (fixture.dimension == ProjectDimension.twoD) {
      flameGame = tester
          .widget<GameWidget<PlayableMapGame>>(
            find.byWidgetPredicate(
              (candidate) => candidate is GameWidget<PlayableMapGame>,
            ),
          )
          .game!;
    }
    bool gameplayReady() {
      final authority = tester
          .widget<PokeMapPlayerSessionView>(
            find.byType(PokeMapPlayerSessionView),
          )
          .gameplayInputAuthority
          ?.value;
      return authority != null &&
          authority.acceptsOverworldInput &&
          authority.context == RuntimeInputContext.overworld &&
          (flameGame == null ||
              (flameGame.isLoaded &&
                  flameGame.debugCompletedMapActivationDispatchCount > 0 &&
                  !flameGame.debugIsMapActivationDispatchInFlight &&
                  !flameGame.debugIsLoadActivationWorkInFlight &&
                  flameGame.inputAuthoritySnapshot.acceptsOverworldInput));
    }

    await _until(tester, gameplayReady, 'published gameplay authority');
    await tester.pump();
    await _until(
      tester,
      gameplayReady,
      'published gameplay authority after frame',
    );
    if (fixture.dimension == ProjectDimension.threeD) {
      final view = tester.widget<SpatialExplorationView>(
        find.byType(SpatialExplorationView),
      );
      final session = view.session;
      fixture.assertRuntimeProjectRoot(session.bundle.projectRootDirectory);
      fixture.assertRuntimeManifest(session.bundle.manifest);
      expect(
        session.bundle.map.spatialScene!.instances
            .where((entry) => fixture.modelIds.contains(entry.modelId))
            .length,
        greaterThanOrEqualTo(2),
      );
      expect(session.bundle.map.layers.whereType<BorderLayer>(), isNotEmpty);
      final solid = session.bundle.map.spatialScene!.instances.singleWhere(
        (instance) => instance.id == 'p12-solid-volume',
      );
      expect(solid.modelId, fixture.modelIds.first);
      expect(solid.blocksMovement, isTrue);
      expect(solid.rotationDegrees, 0);
      final model = session.bundle.manifest.models3d.singleWhere(
        (entry) => entry.id == solid.modelId,
      );
      expect(model.collisionBounds, isNotNull);
      final bounds = model.collisionBounds!;
      final scale = solid.scale * model.scale;
      final minX = solid.position.x + (bounds.min.x - model.pivot.x) * scale;
      final maxX = solid.position.x + (bounds.max.x - model.pivot.x) * scale;
      final minZ = solid.position.z + (bounds.min.z - model.pivot.z) * scale;
      final maxZ = solid.position.z + (bounds.max.z - model.pivot.z) * scale;
      expect(minX, closeTo(5, .000001));
      expect(maxX, closeTo(6, .000001));
      expect(minZ, closeTo(7, .000001));
      expect(maxZ, closeTo(8, .000001));
      final footprint =
          PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
            spriteTopLeftPx: const PixelPosition(leftPx: 0, topPx: 0),
            spriteWidthPx: 32,
            spriteHeightPx: 32,
          );
      expect(footprint.widthPx, 12);
      expect(footprint.heightPx, 8);
      const pixelsPerCell = SpatialMovementController.pixelsPerCell;
      final halfWidth = footprint.widthPx / (2 * pixelsPerCell);
      final contactX = minX - halfWidth;
      expect(contactX, closeTo(4.625, .000001));
      void expectContactBand() {
        expect(
          contactX - session.movement.x,
          allOf(greaterThanOrEqualTo(0), lessThan(3 / pixelsPerCell)),
        );
        expect(session.movement.z, closeTo(7.5, .001));
      }

      expect(session.movement.x, closeTo(2.5, .001));
      expect(session.movement.z, closeTo(7.5, .001));
      await _hold(
        tester,
        LogicalKeyboardKey.arrowRight,
        const Duration(milliseconds: 1800),
        afterPump: () =>
            expect(session.movement.x, lessThanOrEqualTo(contactX)),
      );
      expectContactBand();
      expect(
        session.movement.wouldModelBlockActor(solid.id, minX, 7.5),
        isTrue,
      );
      expect(
        session.movement.canTraverseActor(
          session.movement.x,
          session.movement.z,
          minX,
          7.5,
        ),
        isFalse,
      );
      await _hold(
        tester,
        LogicalKeyboardKey.arrowRight,
        const Duration(milliseconds: 700),
        afterPump: expectContactBand,
      );
      expectContactBand();
      await _hold(
        tester,
        LogicalKeyboardKey.arrowDown,
        const Duration(milliseconds: 700),
      );
      expect(session.movement.z, greaterThanOrEqualTo(8.5));
      await _hold(
        tester,
        LogicalKeyboardKey.arrowRight,
        const Duration(milliseconds: 1200),
      );
      expect(session.movement.x, greaterThan(maxX + halfWidth));
      for (final modelId in fixture.modelIds) {
        final bytes = await session.modelBytes(modelId);
        fixture.assertModelBytes(modelId, bytes);
      }
    } else {
      final mounted = flameGame!;
      expect(
        tester
            .widget<PokeMapPlayerSessionView>(
              find.byType(PokeMapPlayerSessionView),
            )
            .gameplayInputAuthority,
        same(mounted.inputAuthorityListenable),
      );
      expect(mounted.debugPlayerGridPosition, const GridPos(x: 2, y: 7));
      await _hold(
        tester,
        LogicalKeyboardKey.arrowRight,
        const Duration(milliseconds: 1800),
      );
      expect(mounted.debugPlayerGridPosition, const GridPos(x: 4, y: 7));
      await _hold(
        tester,
        LogicalKeyboardKey.arrowRight,
        const Duration(milliseconds: 700),
      );
      expect(mounted.debugPlayerGridPosition, const GridPos(x: 4, y: 7));
      final launch = await fixture.newResolver().resolve(game);
      final project = await launch.assets.resolveReference(launch.project);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: project.path,
        mapId: fixture.mapId,
      );
      fixture.assertRuntimeProjectRoot(bundle.projectRootDirectory);
      fixture.assertRuntimeManifest(bundle.manifest);
      final placed = bundle.map.placedElements.singleWhere(
        (entry) => entry.id == 'p12-solid-decor',
      );
      expect(placed.elementId, fixture.elementId);
      expect(placed.pos, const GridPos(x: 5, y: 7));
      expect(placed.applyCollision, isTrue);
      expect(bundle.map.layers.whereType<SmartTileLayer>(), isNotEmpty);
      expect(bundle.map.layers.whereType<EnvironmentLayer>(), isNotEmpty);
      expect(bundle.runtimeImageAbsolutePathsById, isNotEmpty);
    }
    await fixture.assertSourcesAbsent();
  } finally {
    await controller.stop();
    stopped = true;
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }
}

Future<void> _hold(
  WidgetTester tester,
  LogicalKeyboardKey key,
  Duration duration, {
  VoidCallback? afterPump,
}) async {
  await tester.sendKeyDownEvent(key);
  try {
    for (
      var elapsed = Duration.zero;
      elapsed < duration;
      elapsed += const Duration(milliseconds: 50)
    ) {
      await tester.pump(const Duration(milliseconds: 50));
      afterPump?.call();
    }
  } finally {
    await tester.sendKeyUpEvent(key);
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _until(
  WidgetTester tester,
  bool Function() ready,
  String stage,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 45));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Installed resource journey timed out at $stage.');
    }
    await tester.pump(const Duration(milliseconds: 100));
    final error = tester.takeException();
    if (error != null) Error.throwWithStackTrace(error, StackTrace.current);
  }
}
