import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_tool_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../test/support/neutral_map_host_fixture.dart';
import '../../tool/create_example_project.dart';

class TechnicalMapJourneyHost {
  TechnicalMapJourneyHost._(
    this.tester,
    this.directory,
    this.sessions,
    this.session,
    this.adapter,
    this.maps,
    this.visuals,
  );

  final WidgetTester tester;
  final Directory directory;
  final LocalProjectSessionAdapter sessions;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter adapter;
  final MapWorkspaceController maps;
  final StudioMapResources visuals;
  late final NeutralMapHostFixture viewport;
  bool _mounted = false;
  bool _disposed = false;

  String get root => session.directoryPath;
  EditableMapDocument get document => maps.active!;

  static Future<TechnicalMapJourneyHost> open(WidgetTester tester) async {
    final configuredRoot = Platform.environment['AVELUNE_QA_ROOT'];
    final userHome = Platform.environment['HOME'];
    if (configuredRoot != null &&
        configuredRoot.isNotEmpty &&
        !p.isAbsolute(configuredRoot)) {
      throw ArgumentError.value(
        configuredRoot,
        'AVELUNE_QA_ROOT',
        'The QA root must be an absolute path.',
      );
    }
    final fallbackRoot =
        Platform.isMacOS && userHome != null && p.isAbsolute(userHome)
        ? p.join(userHome, 'Library', 'Caches', 'AveluneQA')
        : p.join(Directory.systemTemp.path, 'AveluneQA');
    final parent = Directory(
      configuredRoot == null || configuredRoot.isEmpty
          ? fallbackRoot
          : configuredRoot,
    );
    final fixture = (await tester.runAsync(() async {
      await parent.create(recursive: true);
      final directory = await parent.createTemp('native-map-journey-');
      final sessions = LocalProjectSessionAdapter();
      ProjectSession? session;
      MapWorkspaceController? maps;
      StudioMapResources? visuals;
      try {
        await writeExampleProject(directory);
        session = await sessions.open(await directory.resolveSymbolicLinks());
        final adapter = LocalMapWorkspaceAdapter();
        maps = MapWorkspaceController(session, adapter);
        await maps.initialize();
        expect(maps.error, isNull);
        await maps.activate(
          maps.project!.maps.singleWhere((entry) => entry.id == 'jardin'),
        );
        await maps.ensureResourceKind('element');
        visuals = await StudioMapResources.load(session, maps.project!);
        visuals.setActiveMap(maps.active!.current);
        await visuals.settled;
        return TechnicalMapJourneyHost._(
          tester,
          directory,
          sessions,
          session,
          adapter,
          maps,
          visuals,
        );
      } catch (_) {
        await visuals?.dispose();
        maps?.dispose();
        if (session != null) await sessions.close(session);
        await directory.delete(recursive: true);
        rethrow;
      }
    }))!;
    addTearDown(fixture.dispose);
    fixture.viewport = await NeutralMapHostFixture.fromController(
      tester,
      fixture.maps,
      mapAdapter: fixture.adapter,
      visuals: fixture.visuals,
    );
    fixture._mounted = true;
    await fixture.until(
      () => fixture.visuals.cachedImageDimensions('atelier') != null,
    );
    expect(fixture.visuals.diagnostics, isEmpty);
    return fixture;
  }

  Future<void> selectDecor(String id) async {
    await tester.runAsync(() => maps.ensureResourceKind('element'));
    await tester.runAsync(() => visuals.updateCatalog(maps.project!));
    final source = document.current;
    final history = document.undoCount;
    expect(
      await useMapResource(
        workspace: maps,
        item: resourceCatalog(maps.project!)
            .singleWhere((item) => item.element?.id == id),
        view: () => viewport.nativeView,
        isActive: () => !maps.isDisposed,
        chooseMap: (_) async => null,
        chooseTile: (_) async => null,
      ),
      isTrue,
    );
    expect(viewport.nativeView.brush?.id, id);
    expect(document.current, same(source));
    expect(document.undoCount, history);
    retainWorkspaceBrush(visuals, viewport.nativeView);
    await tester.runAsync(() => visuals.settled);
    expect(visuals.diagnostics, isEmpty);
    maps.notify();
    await viewport.pump();
  }

  Future<void> tool(String label) async {
    MapToolCommandRunner(
      view: viewport.nativeView,
      paletteTab: () => 'Décors',
      selectPalette: (_) {},
      spatial: false,
      paletteVisible: true,
      onChanged: maps.notify,
      onMoreTools: () {},
      onResources: () {},
    ).runExtra(label);
    await viewport.pump();
  }

  Future<void> chord(LogicalKeyboardKey key, {bool shift = false}) async {
    final modifier = Platform.isMacOS
        ? LogicalKeyboardKey.metaLeft
        : LogicalKeyboardKey.controlLeft;
    await tester.sendKeyDownEvent(modifier);
    try {
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      try {
        await tester.sendKeyEvent(key);
      } finally {
        if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
    } finally {
      await tester.sendKeyUpEvent(modifier);
    }
    await viewport.pump();
  }

  Future<void> save() async {
    final snapshot = document.current;
    final revision = document.base.revision;
    expect(document.dirty, isTrue);
    await chord(LogicalKeyboardKey.keyS);
    await until(() => !document.saving && !document.dirty);
    expect(document.error, isNull);
    expect(document.base.revision, isNot(revision));
    expect(await readSavedMap(snapshot.id), snapshot);
  }

  Future<void> activate(String id) async {
    await tester.runAsync(
      () => maps.activate(
        maps.project!.maps.singleWhere((entry) => entry.id == id),
      ),
    );
    expect(maps.error, isNull);
    expect(document.current.id, id);
    visuals.setActiveMap(document.current);
    retainWorkspaceBrush(visuals, viewport.nativeView);
    await tester.runAsync(() => visuals.settled);
    maps.notify();
    await viewport.pump();
  }

  Future<void> until(bool Function() ready) async {
    for (var attempt = 0; attempt < 300; attempt++) {
      await viewport.pump(frames: 1);
      if (ready()) return;
      if (document.error != null) throw TestFailure(document.error!);
    }
    throw TestFailure('Technical map host did not reach the expected state');
  }

  Future<Map<String, List<int>>> savedMapBytes() async =>
      (await tester.runAsync(() async {
        const reader = LocalProjectFileReader();
        final policy = await WorkspacePolicy.create(
          allowedRootPaths: [root],
          fileReader: reader,
        );
        final handles = WorkspaceHandleStore();
        final opener = ProjectOpenService(
          policy: policy,
          fileReader: reader,
          handles: handles,
        );
        final opened = await opener.openProject(root);
        try {
          final snapshot = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.editorReadProjection,
          );
          return {
            for (final map in snapshot.maps)
              map.id: (await snapshot.readResourceBytes('map:${map.id}'))!,
          };
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
      }))!;

  Future<MapData> readSavedMap(String id) async => MapData.fromJson(
    jsonDecode(utf8.decode((await savedMapBytes())[id]!))
        as Map<String, dynamic>,
  );

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_mounted) {
      await viewport.dispose();
    } else {
      await tester.runAsync(visuals.dispose);
    }
    maps.dispose();
    await tester.runAsync(() async {
      await sessions.close(session);
      if (await directory.exists()) await directory.delete(recursive: true);
    });
  }
}
