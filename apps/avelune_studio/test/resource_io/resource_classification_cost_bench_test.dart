import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

void main() {
  final root = Platform.environment['AVELUNE_CLASSIFY_BENCH_ROOT'];
  final kind = Platform.environment['AVELUNE_CLASSIFY_BENCH_KIND'] ?? 'tileset';
  final ids = (Platform.environment['AVELUNE_CLASSIFY_BENCH_IDS'] ?? '')
      .split(',')
      .where((id) => id.isNotEmpty)
      .toList();

  test(
    'resource classification cost on a real working catalog',
    () async {
      Future<T> measure<T>(String label, Future<T> Function() body) async {
        final started = DateTime.now();
        final watch = Stopwatch()..start();
        final result = await body();
        watch.stop();
        final written = _writtenSince(root!, started);
        stdout.writeln(
          'bench $label ms=${watch.elapsedMilliseconds} '
          'writes=${written.length} '
          'catalogObjects=${written.where((path) => path.contains('/catalog/objects/')).length}',
        );
        return result;
      }

      final sessions = LocalProjectSessionAdapter();
      final session = await measure('session.open', () => sessions.open(root!));
      expect(session.storage, ProjectSessionStorage.workingCatalog);
      final maps = LocalMapWorkspaceAdapter();
      final workspace = MapWorkspaceController(session, maps);
      await measure('workspace.initialize', workspace.initialize);
      expect(workspace.error, isNull);
      final resources = LocalResourceAdapter(
        session: session,
        mapAdapter: maps,
      );
      try {
        Future<void> file(String label, List<String> targets, String? family) =>
            measure(label, () async {
              final revision = await resources.captureResourceRevision();
              final preparation = await resources.prepareOperation(
                'resource.classify_batch',
                {
                  'entries': [
                    for (final id in targets)
                      {
                        'resourceKind': kind,
                        'resourceId': id,
                        'familyId': family,
                      },
                  ],
                },
                expectedSnapshotRevision: revision,
              );
              final receipt = await resources.applyPrepared(preparation);
              workspace.acceptResources(receipt.before, receipt.manifest);
            });

        await measure('dialog.open', resources.captureResourceRevision);
        await file('classify.first', [ids.first], 'props');
        await file('classify.second', [ids.first], 'buildings');
        await file('classify.third', [ids.first], 'props');
        await file('classify.batch', ids, 'vegetation');

        final store = await CatalogStorageStore.open(projectRoot: root!);
        final snapshot = (await store.openRoot((await store.readHead())!))
            .snapshot;
        for (final id in ids) {
          final unit = await snapshot.lookup(
            CatalogDefinitionKey(
              CatalogDefinitionKind.resourceLibraryEntry,
              '$kind:$id',
            ),
          );
          stdout.writeln('bench persisted $kind:$id ${unit?.payload['value']}');
          expect((unit!.payload['value'] as Map)['familyId'], 'vegetation');
        }
      } finally {
        await resources.dispose();
        workspace.dispose();
        await sessions.close(session);
      }
    },
    skip: root == null || ids.isEmpty
        ? 'Set AVELUNE_CLASSIFY_BENCH_ROOT and AVELUNE_CLASSIFY_BENCH_IDS.'
        : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

List<String> _writtenSince(String root, DateTime started) => [
  for (final entity in Directory(root).listSync(recursive: true))
    if (entity is File &&
        !entity.path.contains('/.dart_tool/') &&
        !entity.lastModifiedSync().isBefore(started))
      entity.path,
];
