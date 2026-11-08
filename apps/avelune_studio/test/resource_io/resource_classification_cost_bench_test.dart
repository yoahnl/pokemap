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
  final environment = Platform.environment;
  final root = environment['AVELUNE_CLASSIFY_BENCH_ROOT'];
  final kind = environment['AVELUNE_CLASSIFY_BENCH_KIND'] ?? 'tileset';
  final ids = (environment['AVELUNE_CLASSIFY_BENCH_IDS'] ?? '')
      .split(',')
      .where((id) => id.isNotEmpty)
      .toList();
  final gestures =
      (environment['AVELUNE_CLASSIFY_BENCH_GESTURES'] ?? 'classify')
          .split(',')
          .where((gesture) => gesture.isNotEmpty)
          .toSet();
  final reserveMap = environment['AVELUNE_CLASSIFY_BENCH_RESERVE_MAP'];

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
      final phases = Stopwatch();
      final timeline = <String>[];
      final resources = LocalResourceAdapter(
        session: session,
        mapAdapter: maps,
        mutationPhaseObserver: (phase) =>
            timeline.add('$phase@${phases.elapsedMilliseconds}'),
      );
      try {
        Future<void> mutate(
          String label,
          String action,
          Map<String, Object?> parameters,
        ) => measure(label, () async {
          timeline.clear();
          phases
            ..reset()
            ..start();
          final revision = await resources.captureResourceRevision();
          final preparation = await resources.prepareOperation(
            action,
            parameters,
            expectedSnapshotRevision: revision,
          );
          final receipt = await resources.applyPrepared(preparation);
          workspace.acceptResources(receipt.before, receipt.manifest);
          final path = timeline.any((phase) => phase.startsWith('attach.'))
              ? 'global'
              : 'targeted';
          stdout.writeln(
            'bench $label path=$path phases ${timeline.join(' ')} '
            'accepted@${phases.elapsedMilliseconds}',
          );
        });

        Future<void> file(String label, List<String> targets, String? family) =>
            mutate(label, 'resource.classify_batch', {
              'entries': [
                for (final id in targets)
                  {'resourceKind': kind, 'resourceId': id, 'familyId': family},
              ],
            });

        Future<void> clear(String label, String id) =>
            mutate(label, 'resource.classify', {
              'resourceKind': kind,
              'resourceId': id,
              'description': null,
              'familyId': null,
              'mapId': null,
              'role': 'standard',
              'placementContext': null,
            });

        if (gestures.contains('borders')) {
          final adapterMaps = LocalMapWorkspaceAdapter();
          await adapterMaps.loadCatalog(session);
          final loaded = await measure(
            'borders.adapter',
            () => adapterMaps.loadResourceKind(session, 'borderBlueprint'),
          );
          stdout.writeln(
            'bench borders records=${loaded.metadata.borderCatalog.records.length} '
            'models=${loaded.metadata.models3d.length} '
            'elements=${loaded.metadata.elements.length} '
            'tilesets=${loaded.metadata.tilesets.length}',
          );
          await measure(
            'borders.controller',
            () => workspace.ensureResourceKind('borderBlueprint'),
          );
        }
        if (gestures.contains('borderProfiles')) {
          await measure(
            'borders.profiles.first',
            workspace.ensureBorderProfiles,
          );
          final records = workspace.project!.borderCatalog.records
              .where((record) => record.latestPublished != null)
              .toList();
          stdout.writeln(
            'bench borders.profiles records=${workspace.project!.borderCatalog.records.length} '
            'published=${records.length} '
            'models=${workspace.project!.models3d.length}',
          );
          await measure(
            'borders.profiles.again',
            workspace.ensureBorderProfiles,
          );
          for (final (index, record) in records.take(3).indexed) {
            await measure(
              'borders.select.${index == 0 ? 'first' : 'next$index'}',
              () => workspace.ensureBorderBlueprint(record.id),
            );
            stdout.writeln(
              'bench borders.select ${record.id} '
              'models=${workspace.project!.models3d.length}',
            );
          }
        }
        if (gestures.contains('classify') ||
            gestures.contains('clear') ||
            gestures.contains('reserve')) {
          if (ids.isEmpty) {
            await workspace.ensureResourceKind(kind);
            ids.addAll(resourceItemIds(workspace.project!, kind).take(3));
          }
          stdout.writeln('bench targets $kind:${ids.join(',')}');
          await measure('dialog.open', resources.captureResourceRevision);
        }
        if (gestures.contains('classify')) {
          await file('classify.first', [ids.first], 'props');
          await file('classify.second', [ids.first], 'buildings');
          await file('classify.third', [ids.first], 'props');
          await file('classify.batch', ids, 'vegetation');
        }
        if (gestures.contains('clear')) {
          await file('clear.setup', ids, 'vegetation');
          await clear('clear.first', ids.first);
          await clear('clear.second', ids[1]);
          await file('clear.restore', [ids.first], 'vegetation');
          await clear('clear.third', ids.first);
        }
        if (gestures.contains('family')) {
          final stamp = DateTime.now().microsecondsSinceEpoch;
          await mutate('family.create.first', 'resource.family.create', {
            'familyId': 'family_bench_$stamp',
            'name': 'Banc A',
            'parentId': null,
          });
          await mutate('family.update.first', 'resource.family.update', {
            'familyId': 'family_bench_$stamp',
            'name': 'Banc A renommé',
            'parentId': null,
          });
          await mutate('family.create.second', 'resource.family.create', {
            'familyId': 'family_bench_${stamp}_b',
            'name': 'Banc B',
            'parentId': 'family_bench_$stamp',
          });
          await mutate('family.update.second', 'resource.family.update', {
            'familyId': 'family_bench_${stamp}_b',
            'name': 'Banc B renommé',
            'parentId': 'family_bench_$stamp',
          });
          if (gestures.contains('familyDelete')) {
            await mutate('family.delete.first', 'resource.family.delete', {
              'familyId': 'family_bench_${stamp}_b',
            });
            await mutate('family.delete.second', 'resource.family.delete', {
              'familyId': 'family_bench_$stamp',
            });
          }
          final families = workspace.project!.resourceLibraryCatalog.families
              .where((family) => family.id.startsWith('family_bench_$stamp'))
              .map((family) => '${family.id}=${family.name}')
              .toList();
          stdout.writeln('bench families $families');
        }
        if (gestures.contains('reserve') && reserveMap != null) {
          final watch = Stopwatch()..start();
          try {
            await mutate('reserve.first', 'resource.classify', {
              'resourceKind': kind,
              'resourceId': ids.last,
              'mapId': reserveMap,
            });
          } on Object catch (failure) {
            stdout.writeln(
              'bench reserve.first refused ms=${watch.elapsedMilliseconds} '
              'path=${timeline.any((phase) => phase.startsWith('attach.')) ? 'global' : 'targeted'} '
              'phases ${timeline.join(' ')} $failure',
            );
            rethrow;
          }
          await mutate('reserve.release', 'resource.classify', {
            'resourceKind': kind,
            'resourceId': ids.last,
            'mapId': null,
          });
          await mutate('reserve.second', 'resource.classify', {
            'resourceKind': kind,
            'resourceId': ids.last,
            'mapId': reserveMap,
          });
        }

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
        }
      } finally {
        await resources.dispose();
        workspace.dispose();
        await sessions.close(session);
      }
    },
    skip: root == null
        ? 'Set AVELUNE_CLASSIFY_BENCH_ROOT to a working catalog copy.'
        : false,
    timeout: const Timeout(Duration(minutes: 40)),
  );
}

Iterable<String> resourceItemIds(
  ProjectManifest project,
  String kind,
) => switch (kind) {
  'tileset' => project.tilesets.map((value) => value.id),
  'element' => project.elements.map((value) => value.id),
  'model3d' => project.models3d.map((value) => value.id),
  'character' => project.characters.map((value) => value.id),
  'environmentPreset' => project.environmentPresets.map((value) => value.id),
  'smartTilePreset' => project.smartTileCatalog.presets.map(
    (value) => value.id,
  ),
  'borderBlueprint' => project.borderCatalog.records.map((value) => value.id),
  _ => const <String>[],
};

List<String> _writtenSince(String root, DateTime started) => [
  for (final entity in Directory(root).listSync(recursive: true))
    if (entity is File &&
        !entity.path.contains('/.dart_tool/') &&
        !entity.lastModifiedSync().isBefore(started))
      entity.path,
];
