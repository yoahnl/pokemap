import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/project_model_workshop_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/model_shadow_fixture.dart';

void main() {
  test('the first workshop write stays local, rejects a stale revision and survives reopening', () async {
    final fixture = await ModelShadowFixture.create(unrelated: 90);
    addTearDown(fixture.dispose);
    final session = fixture.session;
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    final adapter = LocalResourceAdapter(session: session, mapAdapter: maps);
    addTearDown(adapter.dispose);
    final ProjectModelWorkshopPort port = adapter;
    final initial = await maps.resourceBaseline(session);
    final reads = <String>[];
    final read = await fixture.observe(
      () => port.readWorkshopModel('house'),
      reads,
      denyForeign: true,
    );
    final original = read.model!;
    expect(read.revision, initial.revision);
    final unchanged = {
      for (final path in fixture.foreignPaths)
        path: await File(path).readAsBytes(),
    };

    final applied = await fixture.observe(
      () => port.saveModelShadow(
        'house',
        castsShadows: true,
        expectedRevision: read.revision!,
      ),
      reads,
      denyForeign: true,
    );
    expect(applied.actionId, 'model3d.configure');
    expect(applied.changedModels, {
      'house': original.copyWith(castsShadowsByDefault: true),
    });
    expect(applied.changedPaths, contains('catalog/HEAD.json'));
    expect(applied.changedMaps, isEmpty);
    expect(applied.manifest.maps, same(initial.manifest.maps));

    await expectLater(
      fixture.observe(
        () => port.saveModelShadow(
          'house',
          castsShadows: false,
          expectedRevision: initial.revision,
        ),
        reads,
        denyForeign: true,
      ),
      throwsA(
        isA<ResourceFailure>().having(
          (failure) => failure.message,
          'conflict',
          contains('catalogue a changé'),
        ),
      ),
    );
    expect(await maps.resourceRevision(session), applied.revision);
    final refreshed = await fixture.observe(
      () => port.readWorkshopModel('house'),
      reads,
      denyForeign: true,
    );
    expect(refreshed.revision, applied.revision);
    expect(refreshed.model, applied.changedModels['house']);

    final reopened = LocalMapWorkspaceAdapter();
    await reopened.loadCatalog(session);
    final persisted = await reopened.readResourcePreview(
      session,
      'model3d',
      'house',
    );
    expect(persisted.models3d.single, applied.changedModels['house']);

    final restored = await fixture.observe(
      () => port.saveModelShadow(
        'house',
        castsShadows: false,
        expectedRevision: applied.revision,
      ),
      reads,
      denyForeign: true,
    );
    expect(restored.changedModels, {'house': original});
    expect(restored.changedMaps, isEmpty);
    expect(reads, isEmpty);
    for (final entry in unchanged.entries) {
      expect(
        await File(entry.key).readAsBytes(),
        entry.value,
        reason: entry.key,
      );
    }
    await reopened.loadCatalog(session);
    expect(
      (await reopened.readResourcePreview(
        session,
        'model3d',
        'house',
      )).models3d.single,
      original,
    );
  });
}
