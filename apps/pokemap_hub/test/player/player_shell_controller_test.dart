import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late InstalledGameLaunchContext launch;
  late HubSaveStore saves;
  late List<_ShellAdapter> adapters;
  late GameSessionController sessions;
  late PlayerShellController shell;
  var sessionSerial = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('player-shell-');
    launch = await _launchContext(root);
    saves = HubSaveStore(supportRoot: root, identity: launch.identity);
    adapters = <_ShellAdapter>[];
    final committer = HubSessionCheckpointCommitter(store: saves);
    sessions = GameSessionController(
      adapterFactory: (descriptor) {
        final adapter = _ShellAdapter(descriptor);
        adapters.add(adapter);
        return adapter;
      },
      commitCheckpoint: committer.commit,
    );
    shell = PlayerShellController(
      launch: launch,
      saves: saves,
      sessions: sessions,
      sessionIdFactory: () => 'session-${++sessionSerial}',
      sessionTokenFactory: () => 'token-$sessionSerial',
    );
  });

  tearDown(() async {
    await shell.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('first opening enables New Game but not Continue', () async {
    await shell.initialize();

    expect(shell.snapshot.state, PlayerShellState.title);
    expect(
      shell.snapshot.title.enabledActions,
      contains(PlayerTitleAction.newGame),
    );
    expect(
      shell.snapshot.title.enabledActions,
      isNot(contains(PlayerTitleAction.continueGame)),
    );
    expect(shell.snapshot.title.gameTitle, 'Adventure');
  });

  test('new game reaches gameplay and Menu toggles pause', () async {
    await shell.initialize();
    expect(
      await shell.startNewGame(
        profileId: 'player-1',
        slotId: 'slot-1',
      ),
      PlayerLaunchResult.started,
    );
    await shell.settle();

    expect(adapters, hasLength(1));
    expect(
        adapters.single.descriptor.launchMode, GameSessionLaunchMode.newGame);
    expect(shell.snapshot.state, PlayerShellState.playing);
    expect(shell.inputSurface, PlayerInputSurface.gameplay);

    await shell.togglePause();
    expect(shell.snapshot.state, PlayerShellState.paused);
    expect(shell.inputSurface, PlayerInputSurface.pause);
    await shell.togglePause();
    expect(shell.snapshot.state, PlayerShellState.playing);
  });

  test('player shell exposes checkpoint saving from gameplay and pause',
      () async {
    await shell.initialize();
    await shell.startNewGame(profileId: 'player-1', slotId: 'slot-1');
    await shell.settle();

    expect(await shell.save(), isTrue);
    await shell.togglePause();
    expect(await shell.save(), isTrue);
    expect(adapters.single.calls.where((call) => call == 'checkpoint'),
        hasLength(2));
  });

  test('lifecycle is a no-op on title and restores an active session',
      () async {
    await shell.initialize();

    await shell.pauseForLifecycle();
    await shell.resumeFromLifecycle();
    expect(shell.snapshot.state, PlayerShellState.title);

    await shell.startNewGame(profileId: 'player-1', slotId: 'slot-1');
    await shell.settle();
    await shell.pauseForLifecycle();
    await shell.settle();
    expect(shell.snapshot.state, PlayerShellState.lifecyclePaused);

    await shell.resumeFromLifecycle();
    await shell.settle();
    expect(shell.snapshot.state, PlayerShellState.playing);
    expect(
      adapters.single.calls,
      containsAllInOrder(<String>['pause', 'resume']),
    );
  });

  test('Continue targets the newest compatible isolated save', () async {
    await _writeSave(
      saves,
      launch.identity,
      profileId: 'player-1',
      slotId: 'slot-old',
      updatedAt: DateTime.utc(2026, 7, 24),
    );
    await _writeSave(
      saves,
      launch.identity,
      profileId: 'player-2',
      slotId: 'slot-new',
      updatedAt: DateTime.utc(2026, 7, 25),
    );
    await shell.initialize();

    expect(await shell.continueGame(), PlayerLaunchResult.started);
    await shell.settle();

    final descriptor = adapters.single.descriptor;
    expect(descriptor.launchMode, GameSessionLaunchMode.continueGame);
    expect(descriptor.profileId, 'player-2');
    expect(descriptor.slotId, 'slot-new');
    expect(
      descriptor.saveReadHandle,
      hubSaveReadHandle((await saves.findContinue())!.envelope!),
    );
  });

  test('new game requires overwrite confirmation and preserves old save',
      () async {
    await _writeSave(
      saves,
      launch.identity,
      profileId: 'player-1',
      slotId: 'slot-1',
      updatedAt: DateTime.utc(2026, 7, 25),
    );
    await shell.initialize();

    expect(
      await shell.startNewGame(
        profileId: 'player-1',
        slotId: 'slot-1',
      ),
      PlayerLaunchResult.overwriteConfirmationRequired,
    );
    expect(shell.snapshot.title.state, PlayerTitleState.confirmingOverwrite);
    expect(adapters, isEmpty);
    expect(
      (await saves.read(
        SaveSlotAddress(
          gameId: launch.identity.gameId,
          profileId: 'player-1',
          slotId: 'slot-1',
        ),
      ))
          .canContinue,
      isTrue,
    );

    expect(
      await shell.startNewGame(
        profileId: 'player-1',
        slotId: 'slot-1',
        overwriteConfirmed: true,
      ),
      PlayerLaunchResult.started,
    );
    expect(
      (await saves.read(
        SaveSlotAddress(
          gameId: launch.identity.gameId,
          profileId: 'player-1',
          slotId: 'slot-1',
        ),
      ))
          .canContinue,
      isTrue,
      reason: 'The old save remains until the new session checkpoints.',
    );
  });

  test('completion commits save, shows result/credits, then returns to Hub',
      () async {
    await shell.initialize();
    await shell.startNewGame(profileId: 'player-1', slotId: 'slot-1');
    await shell.settle();
    final adapter = adapters.single;
    final completedAt = DateTime.utc(2026, 7, 25, 3);
    adapter.emit(
      GameSessionCompleted(
        GameCompletionEvent(
          sessionId: adapter.descriptor.sessionId,
          gameId: launch.identity.gameId,
          endingId: 'main-ending',
          outcome: GameCompletionOutcome.victory,
          completedAt: completedAt,
          playTimeSeconds: 600,
          result: const GameResultSnapshot(
            title: 'Victoire',
            summary: 'La région est sauvée.',
          ),
          credits: const GameCreditsSnapshot(
            title: 'Adventure',
            author: 'Example Studio',
            endingLabel: 'Fin principale',
          ),
          destination: GameCompletionDestination.playerChoice,
          allowPostGameContinue: false,
          finalCheckpoint: GameSessionCheckpoint(
            saveId: '123e4567-e89b-42d3-a456-426614174000',
            createdAt: DateTime.utc(2026, 7, 25, 2),
            updatedAt: completedAt,
            playTimeSeconds: 600,
            state: const <String, Object?>{
              'saveId': '123e4567-e89b-42d3-a456-426614174000',
              'currentMapId': 'credits',
            },
          ),
        ),
      ),
    );
    await shell.settle();

    expect(shell.snapshot.state, PlayerShellState.result);
    final saved = await saves.read(
      SaveSlotAddress(
        gameId: launch.identity.gameId,
        profileId: 'player-1',
        slotId: 'slot-1',
      ),
    );
    expect(saved.envelope?.status, SaveStatus.completed);

    shell.showCredits();
    expect(shell.snapshot.state, PlayerShellState.credits);
    await expectLater(
      shell.finishCredits(GameCompletionDestination.playerChoice),
      throwsArgumentError,
    );
    expect(shell.snapshot.state, PlayerShellState.credits);
    await shell.finishCredits(GameCompletionDestination.hub);
    await shell.settle();
    expect(shell.snapshot.state, PlayerShellState.hub);
    expect(
        adapter.calls,
        containsAllInOrder(<String>[
          'lock-completion',
          'completion:true',
          'stop:hub',
          'dispose',
        ]));
  });
}

Future<InstalledGameLaunchContext> _launchContext(Directory root) async {
  final versionRoot = Directory(p.join(root.path, 'version'));
  await Directory(p.join(versionRoot.path, 'project')).create(recursive: true);
  await File(p.join(versionRoot.path, 'project', 'project.json'))
      .writeAsString('{}');
  final manifest = GamePackageManifest(
    packageFormat: 1,
    gameId: 'org.example.adventure',
    gameVersion: Version.parse('1.0.0'),
    title: 'Adventure',
    author: const GamePackageParty(name: 'Example Studio'),
    compatibility: GamePackageCompatibility(
      minHubVersion: Version.parse('1.0.0'),
      runtimeApiExpression: '^1.0.0',
      projectFormat: 'v2',
      saveFormat: 1,
      compatibilityId: 'story-v1',
      requiredCapabilities: const <String>[],
    ),
    locales: GamePackageLocales(
      defaultLocale: 'fr-FR',
      supported: const <String>['fr-FR'],
    ),
    content: GamePackageContent(
      fileCount: 1,
      totalBytes: 2,
      treeSha256: 'a' * 64,
      files: <GamePackageFileEntry>[
        GamePackageFileEntry(
          path: 'project/project.json',
          size: 2,
          sha256: 'b' * 64,
        ),
      ],
    ),
  );
  final assets = await PackageAssetResolver.create(
    versionRoot: versionRoot,
    manifest: manifest,
  );
  final pointer = InstalledGamePointer(
    gameVersion: manifest.gameVersion,
    treeSha256: manifest.content.treeSha256,
  );
  final game = InstalledGame(
    gameId: manifest.gameId,
    title: manifest.title,
    authorName: manifest.author.name,
    defaultLocale: manifest.locales.defaultLocale,
    supportedLocales: manifest.locales.supported,
    current: pointer,
    versions: <InstalledGameVersion>[
      InstalledGameVersion(
        gameVersion: manifest.gameVersion,
        treeSha256: manifest.content.treeSha256,
        installedAt: DateTime.utc(2026, 7, 25),
        receiptFileName: 'receipt.json',
        source: GamePackageInstallSource.localFile,
        signatureStatus: PackageSignatureStatus.notPresent,
      ),
    ],
  );
  return InstalledGameLaunchContext(
    game: game,
    manifest: manifest,
    identity: GameIdentity(
      gameId: manifest.gameId,
      gameVersion: manifest.gameVersion.toString(),
      projectFormat: ProjectFormat.v2,
      saveFormat: 1,
      compatibilityId: 'story-v1',
    ),
    assets: assets,
    project: assets.reference('project/project.json'),
    installedVersionHandle: 'opaque-install',
    runtimeApiVersion: '1.0.0',
    grantedCapabilities: const <String>{},
  );
}

Future<void> _writeSave(
  HubSaveStore store,
  GameIdentity identity, {
  required String profileId,
  required String slotId,
  required DateTime updatedAt,
}) {
  return store.write(
    const SaveEnvelopeCodec().create(
      identity: identity,
      profileId: profileId,
      slotId: slotId,
      saveId: '123e4567-e89b-42d3-a456-426614174000',
      createdAt: DateTime.utc(2026, 7, 23),
      updatedAt: updatedAt,
      status: SaveStatus.active,
      playTimeSeconds: 120,
      state: const <String, Object?>{
        'saveId': '123e4567-e89b-42d3-a456-426614174000',
        'currentMapId': 'route-1',
      },
    ),
  );
}

final class _ShellAdapter implements GameSessionAdapter {
  _ShellAdapter(this.descriptor);

  final GameSessionDescriptor descriptor;
  final calls = <String>[];
  final _events = StreamController<GameSessionAdapterEvent>.broadcast();

  @override
  Stream<GameSessionAdapterEvent> get events => _events.stream;

  void emit(GameSessionAdapterEvent event) => _events.add(event);

  @override
  Future<void> prepare(GameSessionDescriptor descriptor) async =>
      calls.add('prepare');

  @override
  Future<void> start() async {
    calls.add('start');
    emit(GameSessionReady(descriptor.sessionId));
    emit(GameSessionRunning(descriptor.sessionId));
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async {
    calls.add('checkpoint');
    return null;
  }

  @override
  Future<void> lockGameplayForCompletion() async =>
      calls.add('lock-completion');

  @override
  Future<void> acknowledgeCompletion({required bool accepted}) async =>
      calls.add('completion:$accepted');

  @override
  Future<void> stop(GameSessionExitReason reason) async =>
      calls.add('stop:${reason.name}');

  @override
  Future<void> dispose() async {
    calls.add('dispose');
    await _events.close();
  }

  @override
  bool handleInput(RuntimeInputEvent event) => true;
}
