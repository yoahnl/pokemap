import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final environment = Platform.environment;
  final root = environment['AVELUNE_MAP_BUILDER_BENCH_ROOT'];
  final kinds =
      (environment['AVELUNE_MAP_BUILDER_BENCH_KINDS'] ??
              'smartTilePreset,model3d,borderBlueprint,smartTilePreset,model3d')
          .split(',')
          .where((kind) => kind.isNotEmpty)
          .toList();
  final switchMap = environment['AVELUNE_MAP_BUILDER_BENCH_SWITCH_MAP'];
  final placeable = environment['AVELUNE_MAP_BUILDER_BENCH_ALL'] == null;

  test(
    'map builder loading cost on a real working catalog',
    () => Zone.root.run(() async {
      Future<T> measure<T>(String label, Future<T> Function() body) async {
        final watch = Stopwatch()..start();
        final result = await body();
        stdout.writeln('bench $label ms=${watch.elapsedMilliseconds}');
        return result;
      }

      final session = await measure(
        'session.open',
        () => LocalProjectSessionAdapter().open(root!),
      );
      final workspace = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(),
      );
      await measure('workspace.initialize', workspace.initialize);
      if (workspace.error case final error?) throw StateError(error);
      stdout.writeln(
        'bench maps=${workspace.project!.maps.length} '
        'active=${workspace.active?.base.mapId}',
      );
      if (switchMap != null) {
        final entry = workspace.project!.maps.singleWhere(
          (map) => map.id == switchMap,
        );
        await measure('activate.$switchMap', () => workspace.activate(entry));
        if (workspace.error case final error?) throw StateError(error);
      }
      for (final (index, kind) in kinds.indexed) {
        await measure(
          'resourceKind.$index.$kind',
          () => workspace.ensureResourceKind(kind, placeableOnly: placeable),
        );
        if (workspace.error case final error?) throw StateError(error);
        final project = workspace.project!;
        stdout.writeln(
          'bench loaded models=${project.models3d.length} '
          'elements=${project.elements.length} '
          'presets=${project.smartTileCatalog.presets.length} '
          'library=${project.resourceLibraryCatalog.entries.length}',
        );
      }
    }),
    skip: root == null ? 'Set AVELUNE_MAP_BUILDER_BENCH_ROOT.' : false,
    timeout: const Timeout(Duration(minutes: 40)),
  );
}
