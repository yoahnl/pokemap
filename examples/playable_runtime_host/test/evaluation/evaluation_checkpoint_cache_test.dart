import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/driver/evaluation_game_fixtures.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_checkpoint_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cache key changes with project tree hash', () {
    final left = _provenance(projectHash: 'a' * 64);
    final right = _provenance(projectHash: 'b' * 64);

    expect(left.digestSha256, isNot(right.digestSha256));
  });

  test('cache stores and reloads a serialized game state atomically', () async {
    final root = await Directory.systemTemp.createTemp('pokemap-checkpoint-');
    addTearDown(() => root.delete(recursive: true));
    final cache = EvaluationCheckpointCache(root: root);
    final provenance = _provenance();
    final state = gameStateFixture();

    await cache.store('after-lysa', provenance, state);
    final loaded = await cache.load('after-lysa', provenance);

    expect(loaded.toJson(), state.toJson());
    final entry = cache.entryDirectory('after-lysa', provenance);
    expect(File(p.join(entry.path, 'manifest.json')).existsSync(), isTrue);
    expect(File(p.join(entry.path, 'save.json')).existsSync(), isTrue);
    expect(
      entry.listSync().whereType<File>().map((file) => p.basename(file.path)),
      isNot(contains(endsWith('.tmp'))),
    );
  });

  test('cache refuses an incomplete provenance manifest', () async {
    final root = await Directory.systemTemp.createTemp('pokemap-checkpoint-');
    addTearDown(() => root.delete(recursive: true));
    final cache = EvaluationCheckpointCache(root: root);
    final provenance = _provenance();
    final entry = cache.entryDirectory('after-lysa', provenance);
    await entry.create(recursive: true);
    await File(p.join(entry.path, 'manifest.json')).writeAsString(
      jsonEncode(<String, Object?>{'schemaVersion': 1}),
    );

    expect(
      () => cache.load('after-lysa', provenance),
      throwsA(isA<EvaluationCheckpointStale>()),
    );
  });

  test('cache refuses a checkpoint produced by different code', () async {
    final root = await Directory.systemTemp.createTemp('pokemap-checkpoint-');
    addTearDown(() => root.delete(recursive: true));
    final cache = EvaluationCheckpointCache(root: root);
    final previous = _provenance(codeHash: 'b' * 64);
    final current = _provenance(codeHash: 'c' * 64);
    await cache.store('after-lysa', previous, gameStateFixture());

    expect(
      () => cache.load('after-lysa', current),
      throwsA(isA<EvaluationCheckpointStale>()),
    );
  });

  test('checkpoint ids cannot escape the cache root', () async {
    final root = await Directory.systemTemp.createTemp('pokemap-checkpoint-');
    addTearDown(() => root.delete(recursive: true));
    final cache = EvaluationCheckpointCache(root: root);

    expect(
      () => cache.entryDirectory('../outside', _provenance()),
      throwsArgumentError,
    );
  });

  test(
    'two worker-owned drivers share only a verified checkpoint cache',
    () async {
      final root = await Directory.systemTemp.createTemp('pokemap-checkpoint-');
      addTearDown(() => root.delete(recursive: true));
      final cache = EvaluationCheckpointCache(root: root);
      final provenance = _provenance();
      final projectRoot = Directory(p.normalize(
        p.join(Directory.current.path, '..', '..', 'selbrume'),
      ));
      final first = await SelbrumeEvaluationDriver.start(
        projectRoot: projectRoot,
        runId: 'checkpoint-producer',
        checkpointCache: cache,
        checkpointProvenance: provenance,
      );
      await first.probeSetMoney(777);
      await first.createCheckpoint('after-lysa');
      await first.dispose();

      final second = await SelbrumeEvaluationDriver.start(
        projectRoot: projectRoot,
        runId: 'checkpoint-consumer',
        checkpointCache: cache,
        checkpointProvenance: provenance,
      );
      addTearDown(second.dispose);
      await second.probeLoadCheckpoint('after-lysa');

      expect(second.snapshot().money, 777);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

EvaluationCheckpointProvenance _provenance({
  String projectHash = _hashA,
  String codeHash = _hashB,
}) {
  return EvaluationCheckpointProvenance(
    projectTreeHashSha256: projectHash,
    evaluationCodeDigestSha256: codeHash,
    scenarioId: 'selbrume.shared-checkpoints',
    scenarioVersion: 1,
    saveSchemaVersion: 1,
  );
}

const _hashA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _hashB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
