import 'dart:async';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/working_catalog_preview_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  const projectSession = ProjectSession(
    sessionId: 'preview',
    name: 'Preview',
    directoryPath: '/preview',
  );

  for (final dimension in ProjectDimension.values) {
    final definitions = ProjectManifest(
      version: dimension == ProjectDimension.threeD
          ? ProjectVersion.v9
          : ProjectVersion.v8,
      name: 'Preview',
      settings: ProjectSettings(
        dimension: dimension,
        spatialCamera: dimension == ProjectDimension.threeD
            ? SpatialCameraProfile()
            : null,
      ),
      tilesets: const [],
      maps: const [],
    );
    final detail = WorkingCatalogDetail(
      entry: const WorkingCatalogEntry(
        id: 'asset',
        kind: 'element',
        name: 'Asset',
      ),
      revision: 'r1',
      definitions: definitions,
    );

    test(
      '${dimension.name} loads original definitions and releases once',
      () async {
        final visual = _Visuals();
        final preview = WorkingCatalogPreviewSession(
          loadVisuals: (session, manifest) async {
            expect(session, same(projectSession));
            expect(manifest, same(definitions));
            return visual;
          },
        );
        await preview.load(projectSession, detail);
        expect(preview.resources, same(visual));
        expect(preview.error, isNull);
        await preview.dispose();
        await preview.dispose();
        expect(preview.resources, isNull);
        expect(visual.disposals, 1);
      },
    );

    test(
      '${dimension.name} disposes an out-of-order result without publishing it',
      () async {
        final pending = [
          Completer<MapWorkspaceVisuals>(),
          Completer<MapWorkspaceVisuals>(),
        ];
        var index = 0;
        final preview = WorkingCatalogPreviewSession(
          loadVisuals: (_, _) => pending[index++].future,
        );
        final stale = _Visuals();
        final latest = _Visuals();
        final first = preview.load(projectSession, detail);
        final second = preview.load(projectSession, detail);
        pending[1].complete(latest);
        await second;
        pending[0].complete(stale);
        await first;
        expect(preview.resources, same(latest));
        expect(stale.disposals, 1);
        expect(latest.disposals, 0);
        await preview.dispose();
        expect(latest.disposals, 1);
      },
    );

    test(
      '${dimension.name} closing during a load releases its late result',
      () async {
        final pending = Completer<MapWorkspaceVisuals>();
        var calls = 0;
        final preview = WorkingCatalogPreviewSession(
          loadVisuals: (_, _) {
            calls++;
            return pending.future;
          },
        );
        final visual = _Visuals();
        final loading = preview.load(projectSession, detail);
        await preview.dispose();
        pending.complete(visual);
        await loading;
        await preview.load(projectSession, detail);
        expect(visual.disposals, 1);
        expect(preview.resources, isNull);
        expect(calls, 1);
      },
    );

    test(
      '${dimension.name} stale failure does not replace a current preview',
      () async {
        final failure = Completer<MapWorkspaceVisuals>();
        final visual = _Visuals();
        var calls = 0;
        final preview = WorkingCatalogPreviewSession(
          loadVisuals: (_, _) async {
            if (calls++ == 0) return failure.future;
            return visual;
          },
        );
        final loading = preview.load(projectSession, detail);
        await preview.load(projectSession, detail);
        failure.completeError(StateError('stale'));
        await loading;
        expect(preview.resources, same(visual));
        expect(preview.error, isNull);
        await preview.dispose();
      },
    );

    test(
      '${dimension.name} failed replacement releases the previous preview',
      () async {
        final visual = _Visuals();
        var calls = 0;
        final preview = WorkingCatalogPreviewSession(
          loadVisuals: (_, _) async {
            if (calls++ == 0) return visual;
            expect(visual.disposals, 1);
            throw StateError('unavailable');
          },
        );
        await preview.load(projectSession, detail);
        await preview.load(projectSession, detail);
        expect(preview.resources, isNull);
        expect(preview.error, contains('unavailable'));
        expect(visual.disposals, 1);
        await preview.dispose();
        expect(visual.disposals, 1);
      },
    );
  }
}

class _Visuals implements MapWorkspaceVisuals {
  int disposals = 0;

  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
