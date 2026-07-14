import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/border_studio/application/border_asset_snapshot_service.dart';
import 'package:map_editor/src/features/border_studio/application/ports/border_asset_snapshot_store.dart';
import 'package:map_editor/src/features/border_studio/infrastructure/filesystem/file_border_asset_snapshot_store.dart';
import 'package:path/path.dart' as p;

void main() {
  group('FileBorderAssetSnapshotStore', () {
    late Directory projectRoot;

    setUp(() async {
      projectRoot = await Directory.systemTemp.createTemp(
        'pokemap_border_snapshot_store_',
      );
    });

    tearDown(() async {
      if (await projectRoot.exists()) {
        await projectRoot.delete(recursive: true);
      }
    });

    test('stages every payload atomically below the project root', () async {
      var writes = 0;
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_atomic',
        beforeOperation: (operation, relativePath) {
          if (operation == BorderSnapshotStoreOperation.stageWrite) {
            writes += 1;
            if (writes == 2) throw StateError('injected stage failure');
          }
        },
      );
      final files = <BorderSnapshotFilePayload>[
        _payload('a', <int>[1, 2, 3]),
        _payload('b', <int>[4, 5, 6]),
      ];

      await expectLater(store.stage(files), throwsStateError);

      expect(
        Directory(p.join(projectRoot.path, 'assets', 'borders', '.staging'))
            .listSync(recursive: true),
        isEmpty,
      );
      expect(
        File(p.join(projectRoot.path, files.first.relativePath)).existsSync(),
        isFalse,
      );
    });

    test('finalizes project-relative files and removes staging data', () async {
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_finalize',
      );
      final payload = _payload('created', <int>[10, 20, 30]);

      final stage = await store.stage(<BorderSnapshotFilePayload>[payload]);

      expect(stage.id, 'stage_finalize');
      expect(stage.stagingRelativeDirectory.startsWith('/'), isFalse);
      expect(stage.files.single.relativePath, payload.relativePath);
      expect(
        p.isWithin(
          projectRoot.path,
          p.join(projectRoot.path, stage.stagingRelativeDirectory),
        ),
        isTrue,
      );

      final result = await store.finalize(stage);

      expect(result.createdRelativePaths, <String>[payload.relativePath]);
      expect(result.deduplicatedRelativePaths, isEmpty);
      expect(
        await File(p.join(projectRoot.path, payload.relativePath))
            .readAsBytes(),
        payload.bytes,
      );
      expect(
        Directory(
          p.join(projectRoot.path, stage.stagingRelativeDirectory),
        ).existsSync(),
        isFalse,
      );
    });

    test('deduplicates identical snapshots and preserves shared final files',
        () async {
      var nextStage = 0;
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_${nextStage++}',
      );
      final payload = _payload('shared', <int>[7, 8, 9]);

      final first = await store.stage(<BorderSnapshotFilePayload>[payload]);
      await store.finalize(first);
      final finalFile = File(p.join(projectRoot.path, payload.relativePath));
      final firstBytes = await finalFile.readAsBytes();

      final second = await store.stage(<BorderSnapshotFilePayload>[payload]);
      final result = await store.finalize(second);
      final disposable =
          await store.stage(<BorderSnapshotFilePayload>[payload]);
      await store.discard(disposable);

      expect(result.createdRelativePaths, isEmpty);
      expect(
        result.deduplicatedRelativePaths,
        <String>[payload.relativePath],
      );
      expect(await finalFile.readAsBytes(), firstBytes);
      expect(finalFile.existsSync(), isTrue);
    });

    test('retries the same partially finalized stage idempotently', () async {
      var moves = 0;
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_retry',
        beforeOperation: (operation, relativePath) {
          if (operation == BorderSnapshotStoreOperation.finalizeMove &&
              ++moves == 2) {
            throw StateError('simulated crash after the first move');
          }
        },
      );
      final first = _payload('retry-a', <int>[1, 2, 3]);
      final second = _payload('retry-b', <int>[4, 5, 6]);
      final stage = await store.stage(<BorderSnapshotFilePayload>[
        first,
        second,
      ]);

      await expectLater(store.finalize(stage), throwsStateError);

      final result = await store.finalize(stage);

      expect(result.createdRelativePaths, <String>[second.relativePath]);
      expect(result.deduplicatedRelativePaths, <String>[first.relativePath]);
      expect(
        await File(p.join(projectRoot.path, first.relativePath)).readAsBytes(),
        first.bytes,
      );
      expect(
        await File(p.join(projectRoot.path, second.relativePath)).readAsBytes(),
        second.bytes,
      );
    });

    test('rejects a snapshot directory symlink escaping the project', () async {
      final outside = await Directory.systemTemp.createTemp(
        'pokemap_border_snapshot_outside_',
      );
      addTearDown(() async {
        if (await outside.exists()) await outside.delete(recursive: true);
      });
      final borders = Directory(
        p.join(projectRoot.path, 'assets', 'borders'),
      );
      await borders.create(recursive: true);
      await Link(p.join(borders.path, 'snapshots')).create(outside.path);
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_symlink',
      );

      await expectLater(
        store.stage(<BorderSnapshotFilePayload>[
          _payload('escape', <int>[9, 8, 7]),
        ]),
        throwsA(
          isA<BorderAssetSnapshotStoreException>().having(
            (error) => error.code,
            'code',
            BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
          ),
        ),
      );
      expect(outside.listSync(recursive: true), isEmpty);
    });

    test('rejects a staging directory symlink escaping the project', () async {
      final outside = await Directory.systemTemp.createTemp(
        'pokemap_border_staging_outside_',
      );
      addTearDown(() async {
        if (await outside.exists()) await outside.delete(recursive: true);
      });
      final borders = Directory(
        p.join(projectRoot.path, 'assets', 'borders'),
      );
      await borders.create(recursive: true);
      await Link(p.join(borders.path, '.staging')).create(outside.path);
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_symlink',
      );

      await expectLater(
        store.stage(<BorderSnapshotFilePayload>[
          _payload('escape-stage', <int>[6, 5, 4]),
        ]),
        throwsA(
          isA<BorderAssetSnapshotStoreException>().having(
            (error) => error.code,
            'code',
            BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
          ),
        ),
      );
      expect(outside.listSync(recursive: true), isEmpty);
    });

    test('detects a corrupted existing snapshot without overwriting it',
        () async {
      var nextStage = 0;
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: projectRoot.path,
        stageIdFactory: () => 'stage_${nextStage++}',
      );
      final payload = _payload('corrupt', <int>[1, 3, 5, 7]);
      final first = await store.stage(<BorderSnapshotFilePayload>[payload]);
      await store.finalize(first);
      final finalFile = File(p.join(projectRoot.path, payload.relativePath));
      final corruptBytes = Uint8List.fromList(<int>[99, 98, 97]);
      await finalFile.writeAsBytes(corruptBytes, flush: true);
      final second = await store.stage(<BorderSnapshotFilePayload>[payload]);

      await expectLater(
        store.finalize(second),
        throwsA(
          isA<BorderAssetSnapshotStoreException>().having(
            (error) => error.code,
            'code',
            BorderAssetSnapshotStoreErrorCode.corruptedExistingSnapshot,
          ),
        ),
      );

      expect(await finalFile.readAsBytes(), corruptBytes);
      expect(
        Directory(
          p.join(projectRoot.path, second.stagingRelativeDirectory),
        ).existsSync(),
        isTrue,
      );
      await store.discard(second);
    });

    test('rejects a project root that is itself a file', () async {
      final rootFile = File(p.join(projectRoot.path, 'not_a_directory'));
      await rootFile.writeAsString('x');
      final store = FileBorderAssetSnapshotStore(
        projectRootPath: rootFile.path,
        stageIdFactory: () => 'stage_invalid_root',
      );

      await expectLater(
        store.stage(<BorderSnapshotFilePayload>[
          _payload('invalid-root', <int>[1]),
        ]),
        throwsA(
          isA<BorderAssetSnapshotStoreException>().having(
            (error) => error.code,
            'code',
            BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
          ),
        ),
      );
    });
  });
}

BorderSnapshotFilePayload _payload(String name, List<int> bytes) {
  return BorderSnapshotFilePayload(
    relativePath: 'assets/borders/snapshots/$name/frame_0000.png',
    bytes: Uint8List.fromList(bytes),
  );
}
