import 'dart:async';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import 'resource_fixture.dart';

void main() {
  test('no-op refuses session closed during final baseline read', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final imported = await fixture.import();
    final saved = await fixture.resources.saveElement(
      fixture.element(imported.createdTilesetId!),
    );
    final reader = _PausedReader();
    final maps = LocalMapWorkspaceAdapter(reader: reader);
    await maps.loadProject(fixture.session);
    final adapter = LocalResourceAdapter(
      session: fixture.session,
      mapAdapter: maps,
    );
    addTearDown(adapter.dispose);
    final before = await fixture.manifestFile.readAsBytes();
    reader.remainingReads = 2;
    final pending = adapter.saveElement(saved.manifest.elements.single);
    final assertion = expectLater(pending, throwsA(isA<ResourceFailure>()));
    await reader.entered.future;
    await adapter.dispose();
    reader.release.complete();
    await assertion;
    expect(await fixture.manifestFile.readAsBytes(), before);
  });
}

final class _PausedReader implements ProjectFileReader {
  final delegate = const LocalProjectFileReader();
  final entered = Completer<void>();
  final release = Completer<void>();
  int remainingReads = 0;

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    if (relativePath == 'project.json' &&
        remainingReads > 0 &&
        --remainingReads == 0) {
      entered.complete();
      await release.future;
    }
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
