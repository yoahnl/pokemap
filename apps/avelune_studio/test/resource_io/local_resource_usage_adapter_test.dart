import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/resources/data/local_resource_usage_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import 'resource_fixture.dart';

Future<Map<String, List<int>>> imageFiles(Directory root) async {
  final result = <String, List<int>>{};
  await for (final entry in root.list(recursive: true)) {
    if (entry is File) result[entry.path] = await entry.readAsBytes();
  }
  return result;
}

void main() {
  test(
    'usage reads closed persisted maps without mutation or PNG decoding',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final receipt = await fixture.import();
      final id = receipt.createdTilesetId!;
      await fixture.resources.saveElement(fixture.element(id));
      final loaded = await fixture.loadMap();
      await fixture.maps.saveMap(
        fixture.session,
        loaded,
        loaded.map.copyWith(
          placedElements: const [
            MapPlacedElement(
              id: 'placed',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
      );
      final reader = RetainedUsageReader(pause: false);
      final port = LocalResourceUsageAdapter(
        session: fixture.session,
        reader: reader,
      );
      addTearDown(port.dispose);
      final before = await imageFiles(fixture.root);
      final report = await port.analyze(
        ResourceUsageTarget(family: 'images', id: id),
      );
      expect(report.complete, isTrue, reason: report.coverageIssues.toString());
      expect(
        report.entries.any((entry) => entry.ownerKind == 'element'),
        isTrue,
      );
      final map = report.entries.singleWhere(
        (entry) => entry.ownerKind == 'map',
      );
      expect((map.mapId, map.entityId), ('garden', 'placed'));
      expect(map.relation, ResourceUsageRelation.indirect);
      expect(await port.isCurrent(report), isTrue);
      expect(
        reader.readPaths.where(
          (path) => path.endsWith('.png') || path.endsWith('.blob'),
        ),
        isEmpty,
      );
      expect(await imageFiles(fixture.root), before);
      final next = LocalResourceUsageAdapter(session: fixture.session);
      addTearDown(next.dispose);
      expect(
        (await next.analyze(
          report.target,
        )).entries.map((entry) => entry.toJson()),
        report.entries.map((entry) => entry.toJson()),
      );
      await fixture.maps.saveMap(
        fixture.session,
        await fixture.loadMap(),
        loaded.map.copyWith(name: 'Nom changé'),
      );
      expect(await port.isCurrent(report), isFalse);
    },
  );

  for (final dispose in [false, true]) {
    test(
      '${dispose ? 'dispose' : 'cancel'} retained read never publishes',
      () async {
        final fixture = await ResourceFixture.create();
        addTearDown(fixture.dispose);
        final receipt = await fixture.import();
        final reader = RetainedUsageReader();
        final port = LocalResourceUsageAdapter(
          session: fixture.session,
          reader: reader,
        );
        addTearDown(port.dispose);
        var cancelled = false;
        final pending = port.analyze(
          ResourceUsageTarget(family: 'images', id: receipt.createdTilesetId!),
          cancelled: () => cancelled,
        );
        final expectation = expectLater(
          pending,
          throwsA(isA<ResourceUsageCancelled>()),
        );
        await reader.entered.future;
        if (dispose) {
          await port.dispose();
        } else {
          cancelled = true;
        }
        reader.release.complete();
        await expectation;
      },
    );
  }

  test(
    'a failed initial read can be retried without reopening the editor',
    () async {
      final fixture = await ResourceFixture.create();
      addTearDown(fixture.dispose);
      final receipt = await fixture.import();
      final reader = RetainedUsageReader(pause: false, failFirst: true);
      final port = LocalResourceUsageAdapter(
        session: fixture.session,
        reader: reader,
      );
      addTearDown(port.dispose);
      final target = ResourceUsageTarget(
        family: 'images',
        id: receipt.createdTilesetId!,
      );
      await expectLater(
        port.analyze(target),
        throwsA(
          isA<FileSystemException>().having(
            (error) => error.message,
            'message',
            'Fixture read failure.',
          ),
        ),
      );
      final recovered = await port.analyze(target);
      expect(recovered.complete, isTrue);
      expect(recovered.target.identity, target.identity);
    },
  );
}

final class RetainedUsageReader
    implements ProjectFileReader, ProjectDirectoryReader {
  RetainedUsageReader({this.pause = true, this.failFirst = false});
  final bool pause;
  final bool failFirst;
  final readPaths = <String>[];
  final entered = Completer<void>();
  final release = Completer<void>();
  final delegate = const LocalProjectFileReader();
  bool retained = false;
  bool failed = false;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) => delegate.listFiles(
    projectRoot: projectRoot,
    relativeDirectory: relativeDirectory,
  );

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    readPaths.add(relativePath);
    if (failFirst && relativePath == 'project.json' && !failed) {
      failed = true;
      throw const FileSystemException('Fixture read failure.');
    }
    if (pause && relativePath == 'project.json' && !retained) {
      retained = true;
      entered.complete();
      await release.future;
    }
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
