import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../../packages/map_authoring/test/support/terrain_workshop_fixture.dart';

void main() {
  test(
    'publishes a terrain and resumes a failed reread without writing twice',
    () async {
      final (root, foreign) = await _project();
      var interrupt = true;
      final (maps, editor) = await _studio(
        root,
        beforeReconciliation: () async {
          if (interrupt) throw StateError('Interruption de la relecture');
        },
      );
      final read = await _read(maps, editor);
      final candidate = _center(read.preset, 2);
      final observed = <String>[];
      final outside = Zone.current;
      final head = File('$root/catalog/HEAD.json');
      final before = await head.readAsBytes();
      final pending = await IOOverrides.runZoned(
        () async {
          try {
            await editor.publishTerrainConnections(
              candidate,
              expectedRevision: read.revision,
            );
          } on ResourceFailure catch (failure) {
            if (failure.partialReceipt != null) return failure.partialReceipt!;
            rethrow;
          }
          throw StateError('La relecture devait être interrompue');
        },
        createFile: (path) {
          observed.add(path);
          return outside.run(() => File(path));
        },
      );
      expect(pending.changedTerrain, candidate);
      expect(pending.changedPaths, ['catalog/HEAD.json']);
      expect(
        observed.where(
          (path) => path.contains('/maps/') || path.endsWith('.png'),
        ),
        isEmpty,
      );
      expect(observed.where((path) => foreign.any(path.endsWith)), isEmpty);
      final published = await head.readAsBytes();
      expect(published, isNot(before));

      interrupt = false;
      await editor.reconcileTerrainConnections(pending);
      expect(await head.readAsBytes(), published);
      expect((await _read(maps, editor)).preset, candidate);
      expect((await _read(maps, editor)).revision, pending.revision);
    },
  );

  test(
    'another Studio session cannot publish from an earlier revision',
    () async {
      final (root, _) = await _project();
      final (otherMaps, otherEditor) = await _studio(root);
      final stale = await _read(otherMaps, otherEditor);
      final (maps, editor) = await _studio(root);
      final read = await _read(maps, editor);
      final chosen = _center(read.preset, 1);
      await editor.publishTerrainConnections(
        chosen,
        expectedRevision: read.revision,
      );
      final head = File('$root/catalog/HEAD.json');
      final current = await head.readAsBytes();

      await expectLater(
        otherEditor.publishTerrainConnections(
          _center(stale.preset, 2),
          expectedRevision: stale.revision,
        ),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.message,
            'message',
            contains('catalogue a changé'),
          ),
        ),
      );
      expect(await head.readAsBytes(), current);
      expect((await _read(maps, editor)).preset, chosen);
    },
  );
}

Future<(String, Set<String>)> _project() async {
  final root = await Directory.systemTemp.createTemp('studio-terrain-');
  addTearDown(() => root.delete(recursive: true));
  final paths = await writeTerrainWorkshopFixture(root, unrelatedRecords: 16);
  return (await root.resolveSymbolicLinks(), paths);
}

Future<(LocalMapWorkspaceAdapter, LocalResourceAdapter)> _studio(
  String root, {
  Future<void> Function()? beforeReconciliation,
}) async {
  final sessions = LocalProjectSessionAdapter();
  final session = await sessions.open(root);
  addTearDown(() => sessions.close(session));
  final maps = LocalMapWorkspaceAdapter();
  final workspace = MapWorkspaceController(session, maps);
  addTearDown(workspace.dispose);
  await workspace.initialize();
  expect(workspace.error, isNull);
  final editor = LocalResourceAdapter(
    session: session,
    mapAdapter: maps,
    beforeReconciliation: beforeReconciliation,
  );
  addTearDown(editor.dispose);
  expect(editor.terrainConnectionEditingAvailable, isTrue);
  return (maps, editor);
}

Future<({ProjectSmartTilePreset preset, String revision})> _read(
  LocalMapWorkspaceAdapter maps,
  LocalResourceAdapter editor,
) async {
  final read = await maps.readResourcePreviewWithRevision(
    editor.session,
    'smartTilePreset',
    terrainWorkshopPresetId,
  );
  return (
    preset: read.project.smartTileCatalog.presets.single,
    revision: read.revision,
  );
}

ProjectSmartTilePreset _center(ProjectSmartTilePreset current, int column) {
  final rule = current.rules.last;
  final candidate = rule.candidates.single;
  final part = candidate.parts.single;
  final source = part.source as SmartTileFrameSource;
  return current.copyWith(
    rules: [
      ...current.rules.take(current.rules.length - 1),
      rule.copyWith(
        candidates: [
          candidate.copyWith(
            parts: [
              part.copyWith(
                source: SmartTileVisualSource.frame(
                  frame: source.frame.copyWith(column: column),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
