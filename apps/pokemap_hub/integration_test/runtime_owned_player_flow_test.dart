import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

import '../test/support/runtime_owned_player_package_fixture.dart';

import '../test/support/dashboard_notifier_harness.dart';
import 'package:pokemap_hub/features/session/data/repositories/control_profile_repository_impl.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'installs a data-only game and completes the runtime-owned player journey',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final runtimeLogs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (message, {wrapWidth}) {
        if (message != null) runtimeLogs.add(message);
        previousDebugPrint(message, wrapWidth: wrapWidth);
      };
      addTearDown(() => debugPrint = previousDebugPrint);
      final root = await Directory.systemTemp.createTemp(
        'pokemap-hub-runtime-player-e2e-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final supportRoot = Directory(p.join(root.path, 'PokeMap'));
      final compatibility = _hostCompatibility();
      final selectedPackage = await _buildFixturePackage(root);
      final installer = GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: GamePackageInspector(hostCompatibility: compatibility),
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: _loadInstalledProjectSmoke,
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      );

      final installed = await installer.install(
        selectedPackage,
        source: GamePackageInstallSource.localFile,
      );
      expect(installed.game.gameId, _gameId);

      final libraryStore = GameLibraryStore(supportRoot: supportRoot);
      final preferencesStore = HubPreferencesStore(supportRoot: supportRoot);
      await preferencesStore.save(
        const PlayerPreferences(language: PlayerLanguage.fr),
      );
      final launchResolver = InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      );
      final harness = buildDashboardHarness(
        supportRoot: root,
        libraryStore: libraryStore,
        activityReader:
            InstalledHubGameActivityReader(
              supportRoot: supportRoot,
              launchResolver: launchResolver,
              saveRepositoryFactory:
                  (supportRoot, identity) => HubSaveStore(
                    supportRoot: supportRoot,
                    identity: identity,
                  ),
            ).call,
        preferencesStore: preferencesStore,
      );
      final controller = harness.notifier;
      await controller.initialize();

      await tester.pumpWidget(
        harness.wrap(
          PokeMapHubApp(
            controller: controller,
            initializeController: false,
            playerBuilder:
                (_, game, onHubRequested) => HubInstalledGamePlayer(
                  supportRoot: supportRoot,
                  saveRepositoryFactory:
                      (root, identity) =>
                          HubSaveStore(supportRoot: root, identity: identity),
                  preferencesRepository: preferencesStore,
                  controlProfileRepository: HubControlProfileStore(
                    supportRoot: supportRoot,
                  ),
                  launchResolver: launchResolver,
                  game: game.game,
                  hostBranding: const RuntimeHostSplashBranding(
                    displayName: 'TEST',
                    signature: 'RUNTIME',
                  ),
                  splashLogo: null,
                  onHubRequested: onHubRequested,
                ),
          ),
        ),
      );
      await _pumpUntilFound(tester, find.text(_gameTitle));

      final gameCard = find.byKey(
        const ValueKey<String>('avelune-room-hero-cartridge'),
      );
      await tester.ensureVisible(gameCard);
      await tester.tap(gameCard);
      await tester.pump();
      await _pumpUntilFound(tester, find.text('Appuyer sur Start'));
      await tester.tap(
        find.byKey(const ValueKey<String>('player-title-prompt-hit-area')),
      );
      await _pumpUntilFound(tester, find.text('Nouveau jeu'));
      expect(find.text('FPS'), findsNothing);
      expect(find.textContaining('collision'), findsNothing);
      expect(find.textContaining('seed'), findsNothing);

      await tester.tap(find.text('Nouveau jeu'));
      expect(
        find.byKey(const ValueKey<String>('player-new-game-identity-dialog')),
        findsNothing,
      );
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.playing));
      final game = _mountedGame(tester);
      await _pumpUntilGameReady(tester, game);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 2));
      expect(game.gameStateSnapshot.trainerProfile.name, 'Joueur');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _pumpUntilFound(tester, find.text('Boutique du Rivage'));
      expect(find.byKey(const ValueKey<String>('shop-close')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('shop-close')));
      await _pumpUntilGone(tester, find.text('Boutique du Rivage'));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.paused));
      expect(
        find.byKey(const ValueKey<String>('runtime-pause-navigation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey<String>('pause.party')));
      await _pumpUntilFound(
        tester,
        find.text('Aucun Pokémon dans l’équipe.'),
      );

      final resume = find.byKey(const ValueKey<String>('pause.resume'));
      await tester.ensureVisible(resume);
      await tester.tap(resume);
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.playing));
      await _moveOneTileRight(tester, game);
      expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      await _pumpUntilFact(tester, game, 'fact_mist_source_resolved');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _pumpUntilFound(tester, find.text('Centre Pokémon'));
      expect(find.byKey(const ValueKey<String>('heal-cancel')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('heal-cancel')));
      await _pumpUntilGone(tester, find.text('Centre Pokémon'));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.paused));
      await tester.tap(find.byKey(const ValueKey<String>('pause.save')));
      final saveConfirm = find.byKey(
        const ValueKey<String>('runtime-save-confirm'),
      );
      await _pumpUntilFound(tester, saveConfirm);
      await tester.tap(saveConfirm);
      await _pumpUntilGone(tester, saveConfirm);
      await _pumpUntilSaveCompleted(tester);

      final saveStore = HubSaveStore(
        supportRoot: supportRoot,
        identity: (await launchResolver.resolve(installed.game)).identity,
      );
      final saved = await saveStore.findContinue();
      expect(saved?.canContinue, isTrue);
      expect(
        saved?.envelope == null
            ? null
            : const GameStateSaveEnvelopeMapper()
                .restore(saved!.envelope!)
                .playerPosition,
        const GridPos(x: 2, y: 2),
      );

      await _scrollPauseUntilFound(
        tester,
        find.byKey(const ValueKey<String>('pause.returnToTitle')),
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('pause.returnToTitle')),
      );
      await _pumpUntilFound(tester, find.text('Continuer'));
      expect(find.text('Continuer'), findsOneWidget);

      await tester.tap(find.text('Continuer'));
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.playing));
      final restoredGame = _mountedGame(tester);
      await _pumpUntilGameReady(tester, restoredGame);
      expect(restoredGame.debugPlayerGridPosition, const GridPos(x: 2, y: 2));
      expect(
        restoredGame
            .gameStateSnapshot
            .narrativeFactRuntimeState
            .overridesByFactId['fact_mist_source_resolved'],
        isTrue,
      );

      await _moveOneTileDown(tester, restoredGame);
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.result));
      expect(find.text('Selbrume est sauvée'), findsOneWidget);
      expect(
        find.text(
          'La lumière du phare traverse de nouveau la brume et les habitants '
          'reprennent la mer.',
        ),
        findsOneWidget,
      );
      final completedAddress = SaveSlotAddress(
        gameId: installed.game.gameId,
        profileId: 'default',
        slotId: 'slot-1',
      );
      final completed = await saveStore.read(completedAddress);
      expect(completed.envelope?.status, SaveStatus.completed);
      expect(
        (await HubPlayerSaveGateway(
          store: saveStore,
        ).readSummary(completedAddress))?.canContinue,
        isFalse,
      );
      expect(
        completed.envelope?.state['metadata'],
        containsPair(
          sceneGameCompletionEndingMetadataKey,
          'ending.selbrume-sauvee',
        ),
      );

      await tester.tap(find.text('Voir les crédits'));
      await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.credits));
      expect(find.text('Crédits — Selbrume'), findsOneWidget);
      expect(find.text('Selbrume'), findsOneWidget);
      expect(find.text('Fin principale — Selbrume sauvée'), findsOneWidget);
      await _tapPlayerAction(tester, 'Retour au Hub');
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('avelune-home-screen')),
      );
      expect(
        find.byKey(const ValueKey<String>('pokemap-runtime-player-view')),
        findsNothing,
      );
      expect(find.text(_gameTitle), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey<String>('avelune-room-hero-cartridge')),
      );
      await _pumpUntilFound(tester, find.text('Appuyer sur Start'));
      await tester.tap(
        find.byKey(const ValueKey<String>('player-title-prompt-hit-area')),
      );
      await _pumpUntilFound(tester, find.text('Nouveau jeu'));
      final continueAction = tester.widget<PlayerActionButton>(
        find.widgetWithText(PlayerActionButton, 'Continuer'),
      );
      expect(continueAction.onPressed, isNull);
      await _tapPlayerAction(tester, 'Retour au Hub');
      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey<String>('avelune-home-screen')),
      );
      expect(
        runtimeLogs.where(
          (message) =>
              message.contains('[scene_runtime] player service failed'),
        ),
        isEmpty,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

const _gameId = 'org.pokemap.certification.runtime-player';
const _gameTitle = 'Les Îles Claires';

GamePackageHostCompatibility _hostCompatibility() =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('0.1.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const <String>{
        'dialogue.choices@1',
        'overworld.menu@1',
        'world.shop@1',
      },
      supportedProjectFormats: const <String>{'v6'},
      currentProjectFormat: 'v6',
      supportedSaveFormats: const <int>{1},
    );

Future<File> _buildFixturePackage(Directory root) async {
  final manifest = GamePackageManifest(
    packageFormat: 1,
    gameId: _gameId,
    gameVersion: Version.parse('1.0.0'),
    title: _gameTitle,
    description: 'Fixture neutre du parcours joueur certifié.',
    author: const GamePackageParty(name: 'PokeMap Certification'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse('0.1.0'),
      runtimeApiExpression: '>=1.4.0 <2.0.0',
      projectFormat: 'v6',
      saveFormat: 1,
      compatibilityId: 'runtime-player-v6',
      requiredCapabilities: const <String>['overworld.menu@1', 'world.shop@1'],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr',
      supported: const <String>['fr'],
    ),
    content: GamePackageContent(
      fileCount: 0,
      totalBytes: 0,
      treeSha256: '0' * 64,
      files: const <GamePackageFileEntry>[],
    ),
  );
  final built = const GamePackageBuilder().build(
    manifest: manifest,
    payloadFiles: runtimeOwnedPlayerFixturePayload(),
  );
  final selectedPackage = File(
    p.join(root.path, 'runtime-owned-player-fixture.avelunegame'),
  );
  await selectedPackage.writeAsBytes(built.packageBytes, flush: true);
  return selectedPackage;
}

Future<void> _loadInstalledProjectSmoke(
  Directory stagedVersionRoot,
  GamePackageManifest manifest,
) async {
  final projectFile = File(
    p.join(stagedVersionRoot.path, 'project', 'project.json'),
  );
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile.path,
    mapId: 'runtime_harbor',
  );
  expect(bundle.manifest.version.name, manifest.compatibility.projectFormat);
}

PlayableMapGame _mountedGame(WidgetTester tester) {
  final widget = tester.widget<GameWidget<PlayableMapGame>>(
    find.byWidgetPredicate(
      (candidate) => candidate is GameWidget<PlayableMapGame>,
    ),
  );
  return widget.game!;
}

Finder _playerSurface(RuntimePlayerPhase phase) =>
    find.byKey(ValueKey<String>('runtime-player-surface-${phase.name}'));

Future<void> _pumpUntilGameReady(
  WidgetTester tester,
  PlayableMapGame game,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    try {
      game.debugPlayerGridPosition;
      return;
    } on Object {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
  fail('Timed out waiting for the Flame game to initialize.');
}

Future<void> _moveOneTileRight(
  WidgetTester tester,
  PlayableMapGame game,
) async {
  final start = game.debugPlayerGridPosition;
  await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (game.debugPlayerGridPosition == start &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _moveOneTileDown(WidgetTester tester, PlayableMapGame game) async {
  final start = game.debugPlayerGridPosition;
  await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (game.debugPlayerGridPosition == start &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _pumpUntilFact(
  WidgetTester tester,
  PlayableMapGame game,
  String factId,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (game
          .gameStateSnapshot
          .narrativeFactRuntimeState
          .overridesByFactId[factId] !=
      true) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for narrative fact $factId.');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntilSaveCompleted(WidgetTester tester) async {
  final savingSurface = _playerSurface(RuntimePlayerPhase.saving);
  final pausedSurface = _playerSurface(RuntimePlayerPhase.paused);
  final receipt = find.byKey(const ValueKey<String>('runtime-save-receipt'));
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  var observedSaving = false;
  while (true) {
    observedSaving = observedSaving || savingSurface.evaluate().isNotEmpty;
    if (pausedSurface.evaluate().isNotEmpty && receipt.evaluate().isNotEmpty) {
      return;
    }
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Timed out waiting for the save receipt after confirmation. '
        'Observed saving phase: $observedSaving.',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      final phases = <String>[
        for (final phase in RuntimePlayerPhase.values)
          if (_playerSurface(phase).evaluate().isNotEmpty) phase.name,
      ];
      final visibleText = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .take(20)
          .join(' | ');
      fail(
        'Timed out waiting for ${finder.describeMatch(Plurality.one)}. '
        'Current player phases: ${phases.join(', ')}. '
        'Visible text: $visibleText',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _dragUntilFound(
  WidgetTester tester, {
  required Finder target,
  required Finder scrollView,
}) async {
  for (var attempt = 0; attempt < 10; attempt++) {
    if (target.evaluate().isNotEmpty) {
      await tester.ensureVisible(target.first);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.drag(scrollView, const Offset(0, -80));
      await tester.pump(const Duration(milliseconds: 100));
      return;
    }
    await tester.drag(scrollView, const Offset(0, -240));
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (target.evaluate().isEmpty) {
    fail('Timed out scrolling to ${target.describeMatch(Plurality.one)}.');
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  final targetRect = tester.getRect(target.first);
  final logicalViewSize =
      tester.view.physicalSize / tester.view.devicePixelRatio;
  final visibleRect = targetRect.intersect(Offset.zero & logicalViewSize);
  if (visibleRect.isEmpty) {
    fail('${target.describeMatch(Plurality.one)} is outside the test view.');
  }
  await tester.tapAt(visibleRect.center);
}

Future<void> _tapPlayerAction(WidgetTester tester, String label) async {
  final action = find.widgetWithText(PlayerActionButton, label);
  await tester.ensureVisible(action);
  await tester.pump(const Duration(milliseconds: 100));
  await _tapVisible(tester, action);
}

Future<void> _scrollPauseUntilFound(WidgetTester tester, Finder target) async {
  if (_playerSurface(
    RuntimePlayerPhase.lifecyclePaused,
  ).evaluate().isNotEmpty) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _pumpUntilFound(tester, _playerSurface(RuntimePlayerPhase.paused));
  }
  // A keyed pause action can already exist in the tree while remaining below
  // the viewport (or behind the save receipt). Always scroll it into a
  // hit-testable position before tapping it.
  final navigation = find.byKey(
    const ValueKey<String>('runtime-pause-navigation-scroll'),
  );
  final grid = find.byKey(const ValueKey<String>('player-pause-grid'));
  final list = find.byKey(const ValueKey<String>('player-pause-list'));
  if (navigation.evaluate().isEmpty &&
      grid.evaluate().isEmpty &&
      list.evaluate().isEmpty) {
    fail('The paused player exposes no responsive pause scroll view.');
  }
  final scrollView =
      navigation.evaluate().isNotEmpty
          ? navigation
          : grid.evaluate().isNotEmpty
          ? grid
          : list;
  await _dragUntilFound(tester, target: target, scrollView: scrollView);
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isNotEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      fail(
        'Timed out waiting for ${finder.describeMatch(Plurality.one)} '
        'to disappear.',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}
