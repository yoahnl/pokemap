import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/avelune_embedded_runtime.dart';
import 'package:map_core/map_core.dart' show SaveEnvelopeCodec;
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/core/config/avelune_host_compatibility.dart';
import 'package:pokemap_hub/embedding/install_progress_relay.dart';
import 'package:pokemap_hub/pokemap_hub_player.dart';

import '../support/game_package_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.avelune.runtime/library');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AveluneLibraryBridge bridge;
  late Directory root;
  late int rootReads;
  late List<String> nativeNotifications;
  late Future<void> Function() stopPlayer;
  late int integrityChecks;

  Future<Object?> invoke(String method, [Object? arguments]) {
    final result = Completer<Object?>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (data) {
        try {
          if (data == null) throw MissingPluginException();
          result.complete(codec.decodeEnvelope(data));
        } on Object catch (error) {
          result.completeError(error);
        }
      },
    );
    return result.future;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-embedded-bridge-');
    rootReads = 0;
    nativeNotifications = [];
    stopPlayer = () async {};
    integrityChecks = 0;
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeNotifications.add(call.method);
      return null;
    });
    bridge = AveluneLibraryBridge(
      stopPlayer: () => stopPlayer(),
      verifier: InstalledGameVerifier(
        fileIntegrityCheck: (file, entry) async {
          integrityChecks++;
          final bytes = await file.readAsBytes();
          return sha256.convert(bytes).toString() == entry.sha256
              ? null
              : InstalledGameVerificationCode.hashMismatch;
        },
      ),
      supportRootResolver: () async {
        rootReads++;
        return root;
      },
    );
    bridge.attach();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    bridge.detach();
    messenger.setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  test('notifies the shell only after the library handler is attached', () {
    expect(nativeNotifications, ['runtimeReady']);
  });

  test(
    'loads the canonical empty library once across repeated calls',
    () async {
      expect(await invoke('listGames'), isEmpty);
      expect(await invoke('listGames'), isEmpty);
      expect(rootReads, 1);
    },
  );

  test('reports a missing game without creating a player session', () async {
    await expectLater(
      invoke('playGame', {'gameId': 'missing'}),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'gameNotInstalled',
        ),
      ),
    );
    expect(bridge.playing.value, isNull);
  });

  test('rejects malformed commands before loading storage', () async {
    for (final method in ['playGame', 'installGame', 'uninstallGame']) {
      await expectLater(
        invoke(method),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'invalidArguments',
          ),
        ),
      );
    }
    expect(rootReads, 0);
  });

  test('unknown methods do not initialize the runtime library', () async {
    await expectLater(
      invoke('unknown'),
      throwsA(isA<MissingPluginException>()),
    );
    expect(rootReads, 0);
  });

  test(
    'returns an actionable installation error to the native shell',
    () async {
      await expectLater(
        invoke('installGame', {
          'packagePath': '${root.path}/missing.avelunegame',
        }),
        throwsA(
          isA<PlatformException>()
              .having(
                (error) => error.code,
                'code',
                'installation.integrityFailed',
              )
              .having(
                (error) => error.message,
                'message',
                'Le package est incomplet ou a été modifié.',
              )
              .having(
                (error) => error.details,
                'details',
                isA<Map>()
                    .having(
                      (details) => details['code'],
                      'diagnostic',
                      'integrityFailed',
                    )
                    .having(
                      (details) => details['stage'],
                      'stage',
                      'inspecting',
                    )
                    .having(
                      (details) => details['cause'],
                      'cause',
                      contains('regular file'),
                    ),
              ),
        ),
      );
      expect(bridge.playing.value, isNull);
    },
  );

  test('stopping an idle session does not load storage', () async {
    expect(await invoke('stopGame'), isNull);
    expect(rootReads, 0);
  });

  test('acknowledges stop only after player resources close', () async {
    final stopped = Completer<void>();
    stopPlayer = () => stopped.future;
    var acknowledged = false;
    final response = invoke('stopGame').then((_) => acknowledged = true);
    await Future<void>.delayed(Duration.zero);
    expect(acknowledged, isFalse);
    stopped.complete();
    await response;
    expect(acknowledged, isTrue);
    expect(rootReads, 0);
  });

  test('failed stop remains an error and may be retried', () async {
    stopPlayer = () async => throw StateError('stop failed');
    await expectLater(invoke('stopGame'), throwsA(isA<PlatformException>()));
    stopPlayer = () async {};
    expect(await invoke('stopGame'), isNull);
  });

  group('install progress', () {
    late List<Map<Object?, Object?>> progressMessages;

    GameInstallProgress progress(
      GameInstallStage stage, {
      int completedBytes = 10,
      int totalBytes = 100,
    }) => GameInstallProgress(
      stage: stage,
      completedFiles: 0,
      totalFiles: 0,
      completedBytes: completedBytes,
      totalBytes: totalBytes,
      cancellable: false,
    );

    setUp(() {
      progressMessages = [];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'installProgress') {
          progressMessages.add(call.arguments as Map<Object?, Object?>);
        }
        return null;
      });
    });

    test('install progress is forwarded and throttled', () async {
      var now = Duration.zero;
      final relay = InstallProgressRelay(channel: channel, elapsed: () => now);

      for (var index = 0; index < 100; index++) {
        now = Duration(milliseconds: index);
        relay.call(
          progress(GameInstallStage.extracting, completedBytes: index),
        );
      }
      now = const Duration(milliseconds: 100);
      relay.call(progress(GameInstallStage.extracting, completedBytes: 100));
      now = const Duration(milliseconds: 101);
      relay.call(progress(GameInstallStage.verifying));
      await Future<void>.delayed(Duration.zero);

      expect(progressMessages, hasLength(3));
      expect(progressMessages.map((message) => message['stage']), [
        'extracting',
        'extracting',
        'verifying',
      ]);
      expect(progressMessages[1]['completedBytes'], 100);
      expect(progressMessages[1]['totalBytes'], 100);
    });

    test('unknown totals are sent as null', () async {
      InstallProgressRelay(channel: channel).call(
        progress(GameInstallStage.inspecting, completedBytes: 0, totalBytes: 0),
      );
      await Future<void>.delayed(Duration.zero);

      expect(progressMessages.single, {
        'stage': 'inspecting',
        'completedBytes': null,
        'totalBytes': null,
      });
    });

    test('a missing native handler does not break the relay', () async {
      messenger.setMockMethodCallHandler(channel, null);
      InstallProgressRelay(channel: channel)
          .call(progress(GameInstallStage.extracting));
      await Future<void>.delayed(Duration.zero);
    });

    test('installGame reports the stages of a real installation', () async {
      final package = await writeTestPackage(
        Directory(p.join(root.path, 'pkg-progress')),
        gameId: 'games.example.progress',
        minHubVersion: AveluneRuntimeCompatibility.minimumHubVersion,
        saveFormat: SaveEnvelopeCodec.currentSaveFormat,
      );

      await invoke('installGame', {
        'packagePath': package.path,
      }).then<void>((_) {}, onError: (Object _) {});
      await Future<void>.delayed(Duration.zero);

      final stages = progressMessages.map((message) => message['stage']);
      expect(stages, contains('inspecting'));
      expect(stages, contains('extracting'));
      expect(
        stages.toSet().difference(
          GameInstallStage.values.map((stage) => stage.name).toSet(),
        ),
        isEmpty,
      );
    });
  });

  group('with installed games', () {
    Future<List<GameInstallationResult>> installGames(int count) async {
      final installer = GamePackageInstaller(
        supportRoot: root,
        inspector: GamePackageInspector(
          hostCompatibility: aveluneHostCompatibility(),
        ),
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, _) async {},
        prepareSavesForUpdate: (_, _) async => const SaveUpdatePreparation(),
      );
      return [
        for (var index = 0; index < count; index++)
          await installer.install(
            await writeTestPackage(
              Directory(p.join(root.path, 'pkg-$index')),
              gameId: 'games.example.game$index',
              minHubVersion: AveluneRuntimeCompatibility.minimumHubVersion,
              saveFormat: SaveEnvelopeCodec.currentSaveFormat,
            ),
            source: GamePackageInstallSource.localFile,
          ),
      ];
    }

    test('listGames does not hash installed content', () async {
      await installGames(3);

      final listed = await invoke('listGames') as List<Object?>;

      expect(listed, hasLength(3));
      expect(integrityChecks, 0);
    });

    test('a tampered file is listed but cannot be played', () async {
      final installed = (await installGames(1)).single;
      await File(
        p.join(
          root.path,
          'games',
          installed.game.gameId,
          'versions',
          installed.game.current.gameVersion.toString(),
          'project',
          'project.json',
        ),
      ).writeAsString('tampered');

      final listed = await invoke('listGames') as List<Object?>;

      expect(
        listed.cast<Map<Object?, Object?>>().map((game) => game['gameId']),
        contains(installed.game.gameId),
      );
      expect(integrityChecks, 0);
      await expectLater(
        bridge.launchResolver.resolve(installed.game),
        throwsA(
          isA<InstalledGameLaunchException>().having(
            (error) => error.code,
            'code',
            InstalledGameLaunchErrorCode.installationUnhealthy,
          ),
        ),
      );
    });
  });
}
