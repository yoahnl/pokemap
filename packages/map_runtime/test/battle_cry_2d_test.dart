import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('2D battle plays the declared cry and the legacy fallback', () async {
    final paths = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final sinks = <String, MockStreamHandlerEventSink>{};
    for (final name in [
      'xyz.luan/audioplayers.global',
      'xyz.luan/audioplayers.global/events',
    ]) {
      messenger.setMockMethodCallHandler(
        MethodChannel(name),
        (_) async => null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final arguments = call.arguments as Map;
        final id = arguments['playerId'] as String;
        switch (call.method) {
          case 'create':
            messenger.setMockStreamHandler(
              EventChannel('xyz.luan/audioplayers/events/$id'),
              MockStreamHandler.inline(
                onListen: (_, sink) => sinks[id] = sink,
                onCancel: (_) => sinks.remove(id),
              ),
            );
          case 'setSourceUrl':
            paths.add(arguments['url'] as String);
            sinks[id]?.success({'event': 'audio.onPrepared', 'value': true});
          case 'getCurrentPosition' || 'getDuration':
            return 0;
        }
        return null;
      },
    );

    final owner = await Directory.systemTemp.createTemp('battle-cry-2d-');
    addTearDown(() => owner.delete(recursive: true));
    final source = Directory(
      p.absolute('../../examples/playable_runtime_host/golden_battle_slice'),
    );
    await for (final entry in source.list(recursive: true, followLinks: false)) {
      final destination = p.join(
        owner.path,
        p.relative(entry.path, from: source.path),
      );
      if (entry is Directory) {
        await Directory(destination).create(recursive: true);
      } else if (entry is File) {
        await File(destination).parent.create(recursive: true);
        await entry.copy(destination);
      }
    }
    final root = owner.path;
    final projectFile = p.join(root, 'project.json');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile,
      mapId: 'golden_field',
    );
    final saved = jsonDecode(
      await File(p.join(root, 'runtime_host_launch_save.json')).readAsString(),
    ) as Map<String, dynamic>;
    final media = File(p.join(root, 'data/pokemon/media/clockbird.json'));
    await media.parent.create(recursive: true);
    await media.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'defaultFormId': 'base',
        'variants': {
          'base': {'cry': 'assets/audio/pokemon/clockbird/cry.wav'},
        },
      }),
    );
    final missingMedia = File(p.join(root, 'data/pokemon/media/missing.json'));
    await missingMedia.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'defaultFormId': 'base',
        'variants': {
          'base': {'cry': 'assets/audio/pokemon/missing/cry.wav'},
        },
      }),
    );
    final declared = File(
      p.join(root, 'assets/audio/pokemon/clockbird/cry.wav'),
    );
    final legacy = File(p.join(root, 'assets/pokemon/cries/legacy.ogg'));
    final alternate = File(p.join(root, 'assets/pokemon/cries/clockbird.ogg'));
    final missingFallback = File(
      p.join(root, 'assets/pokemon/cries/missing.ogg'),
    );
    for (final file in [declared, legacy, alternate, missingFallback]) {
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1, 2, 3]);
    }
    final game = _TestGame(
      bundle: bundle,
      projectFilePath: projectFile,
      saveData: SaveData.fromJson(saved).normalized(),
    );
    addTearDown(() async {
      await game.debugWaitForBattlePrewarm();
      game.onRemove();
    });
    game.onGameResize(Vector2(640, 480));
    await game.onLoad();
    await game.debugOpenBattleForTest(
      const WildBattleStartRequest(
        requestId: 'cry',
        createdAtEpochMs: 1,
        returnContext: OverworldReturnContext(
          mapId: 'golden_field',
          playerPos: GridPos(x: 1, y: 1),
          playerFacing: Direction.east,
        ),
        mapId: 'golden_field',
        encounterSourceId: 'golden_grass',
        encounterSourceKind: EncounterSourceKind.gameplayZone,
        tableId: 'golden_grass',
        encounterKind: EncounterKind.walk,
        speciesId: 'sparkitten',
        level: 6,
        minLevel: 6,
        maxLevel: 6,
        weight: 1,
        playerPos: GridPos(x: 1, y: 1),
      ),
    );
    final callback = game.debugBattleOverlayComponent!.playCry!;
    callback('clockbird');
    await _waitFor(
      () => paths.any(
        (path) => path.contains('assets/audio/pokemon/clockbird/cry.wav'),
      ),
    );
    callback('legacy');
    await _waitFor(
      () =>
          paths.any((path) => path.contains('assets/pokemon/cries/legacy.ogg')),
    );
    callback('missing');
    await _waitFor(
      () => paths.any(
        (path) => path.contains('assets/pokemon/cries/missing.ogg'),
      ),
    );
    expect(
      paths.where(
        (path) => path.contains('assets/audio/pokemon/clockbird/cry.wav'),
      ),
      hasLength(1),
    );
    expect(
      paths.where((path) => path.contains('assets/pokemon/cries/legacy.ogg')),
      hasLength(1),
    );
    expect(
      paths.where(
        (path) => path.contains('assets/pokemon/cries/clockbird.ogg'),
      ),
      isEmpty,
    );
    callback('clockbird');
    game.debugResetBattleForTest();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(
      paths.where(
        (path) => path.contains('assets/audio/pokemon/clockbird/cry.wav'),
      ),
      hasLength(1),
    );
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

class _TestGame extends PlayableMapGame {
  _TestGame({
    required super.bundle,
    required super.projectFilePath,
    super.saveData,
  });

  @override
  bool get isLoaded => true;
}
