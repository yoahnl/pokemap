import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/home/application/recent_projects_controller.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_catalog_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

import 'neutral_map_host_fixture.dart';
import 'real_test_io.dart';
import 'synthetic_template_fixture.dart';

class ProjectCreationWorkspaceFixture {
  ProjectCreationWorkspaceFixture(this.tester, this.parent, this.packageFile);
  final WidgetTester tester;
  final Directory parent;
  final File packageFile;
  late ProjectSessionController session = ProjectSessionController(
    LocalProjectSessionAdapter(),
  );
  final recents = MemoryRecentProjectsAdapter();
  late final _recents = RecentProjectsController(recents);
  ProjectSessionOpenController? _opening;
  ProjectCreationController? creator;
  MapWorkspaceController? _maps;
  NeutralMapHostFixture? viewport;
  WorkspaceWorkflow? workflow;
  StudioGameExportController? gameExport;
  late final LocalMapWorkspaceAdapter adapter;
  bool _adapterReady = false;
  ProjectCreationPort _creationPort = offlineProjectCreation;
  MapWorkspacePort Function(MapWorkspacePort)? _mapPort;
  bool _withNarrative = false;
  bool _withViewport = true;
  bool _bridgeCreate = true;
  GlobalKey? _captureKey;
  Completer<void>? _creatorClosed;
  Future<void>? _creationLifetime;
  Future<bool> Function(String)? _openCreated;
  WorkspaceCloseChoice closeChoice = WorkspaceCloseChoice.cancel;
  Future<void>? _disposal;
  bool _disposed = false;
  int releases = 0;
  final creatorVisibility = <bool>[];

  MapWorkspaceController get maps => _maps!;

  Future<void> mount({
    ProjectCreationPort? creationPort,
    MapWorkspacePort Function(MapWorkspacePort)? mapPort,
    ProjectSessionController? sessionController,
    bool withNarrative = false,
    bool withViewport = true,
    bool settle = true,
    bool bridgeCreate = true,
    Size size = const Size(1536, 960),
    double textScale = 1,
    GlobalKey? captureKey,
  }) async {
    if (!_adapterReady) {
      adapter = (await RealTestIo.run(tester, () async => LocalMapWorkspaceAdapter()))!;
      _adapterReady = true;
    }
    if (sessionController != null && !identical(sessionController, session)) {
      _opening?.dispose();
      _opening = null;
      await _closeViewport();
      session = sessionController;
    }
    _creationPort = creationPort ?? offlineProjectCreation;
    _mapPort = mapPort;
    _withNarrative = withNarrative;
    _withViewport = withViewport;
    _bridgeCreate = bridgeCreate;
    _captureKey = captureKey;
    _opening ??= ProjectSessionOpenController(
      session: session,
      chooseDirectory: () async => null,
      recentProjects: _recents,
      allowSwitch: () async => await workflow?.allowClose() ?? true,
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _recents.load();
    if (session.state.project != null) {
      await mountCurrent();
    } else {
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    }
    if (settle) await pump();
  }

  Future<ProjectCreationController> beginCreation({String? name}) async {
    if (!await closeCreation()) {
      throw StateError(
        'The pending creation must finish before another starts',
      );
    }
    final controller = ProjectCreationController(_creationPort);
    creator = controller;
    controller.setName(name ?? 'Nouveau projet');
    _creatorClosed = Completer<void>();
    final owner = _opening!;
    _creationLifetime = owner.runCreation(
      releaseParent: () async {
        releases++;
      },
      onVisibilityChanged: creatorVisibility.add,
      present: (open) async {
        _openCreated = open;
        await _creatorClosed!.future;
      },
    );
    return controller;
  }

  Future<void> submitCreation(
    int tileSize, {
    String? name,
    bool settle = true,
    bool confirm = true,
    String? templateId,
  }) async {
    final controller = await beginCreation(
      name: name ?? 'Projet grille $tileSize',
    );
    await RealTestIo.run(tester, () async {
      expect(controller.next(), isTrue);
      if (templateId == null) {
        controller.setTemplate(ProjectCreationTemplate.playable);
      } else {
        controller.setCatalogueTemplate(templateId);
      }
      expect(controller.next(), isTrue);
      if (templateId == null) {
        controller.change(() => controller.tileSize = tileSize);
      }
      expect(controller.next(), isTrue);
      await controller.loadPreview();
      await controller.chooseParent(() async => parent.path);
      expect(controller.error, isNull);
    });
    if (confirm) await performCreation();
    if (settle) await pump();
  }

  Future<bool> performCreation() async {
    final controller = creator!;
    final receipt = _bridgeCreate
        ? await RealTestIo.run(tester, controller.create)
        : await controller.create();
    if (receipt == null) return false;
    return tryOpenCreated();
  }

  Future<bool> tryOpenCreated() async {
    final controller = creator!;
    final open = _openCreated!;
    final opened = _bridgeCreate
        ? await RealTestIo.run(
                tester,
                () => controller.openCreated(
                  (receipt) => open(receipt.projectPath),
                ),
              ) ??
              false
        : await controller.openCreated((receipt) => open(receipt.projectPath));
    if (opened) {
      await closeCreation();
      await mountCurrent();
    }
    return opened;
  }

  Future<void> create(int tileSize, {String? name, String? templateId}) async {
    await submitCreation(tileSize, name: name, templateId: templateId);
    expect(session.state.project, isNotNull);
    expect(maps.active, isNotNull);
  }

  Future<bool> openExisting(String path) async {
    final opened = await RealTestIo.run(
      tester,
      () => _opening!.open(directoryPath: path),
    );
    if (opened == true) await mountCurrent();
    return opened ?? false;
  }

  Future<bool> exportPackage({
    required StudioGameExportMetadata metadata,
    bool publication = false,
  }) async {
    final owner = session.state.project!;
    final exporter = gameExport!;
    final guard = workflow!;
    await RealTestIo.run(tester, exporter.load);
    return await RealTestIo.run(
          tester,
          () => exporter.export(
            metadata: metadata,
            outputPath: packageFile.path,
            overwriteConfirmed: false,
            publication: publication,
            prepare: guard.saveForExport,
            preparationFailure: () => guard.exportPreparationFailure,
            hasPendingChanges: () => guard.hasPendingChanges,
            isCurrentProject: () => identical(session.state.project, owner),
          ),
        ) ??
        false;
  }

  Future<void> mountCurrent() async {
    final current = session.state.project!;
    if (_maps?.session.sessionId == current.sessionId) return;
    await _closeViewport();
    final port = _mapPort?.call(adapter) ?? adapter;
    final controller = MapWorkspaceController(
      current,
      port,
      catalogPort: LocalMapCatalogAdapter(adapter),
    );
    _maps = controller;
    await RealTestIo.run(tester, controller.initialize);
    expect(controller.error, isNull);
    gameExport = StudioGameExportController(
      projectRoot: Directory(current.directoryPath),
      projectName: current.name,
    );
    if (_withViewport) {
      final visuals = (await RealTestIo.run(
        tester,
        () => StudioMapResources.load(current, controller.project!),
      ))!;
      viewport = await NeutralMapHostFixture.fromController(
        tester,
        controller,
        mapAdapter: adapter,
        withNarrative: _withNarrative,
        visuals: visuals,
        captureKey: _captureKey,
      );
    }
    final host = viewport;
    workflow = WorkspaceWorkflow(
      controller: controller,
      isActive: () => !controller.isDisposed && identical(_maps, controller),
      changed: controller.notify,
      resources: () => null,
      narrative: () => host?.sessions.narrative,
      scenes: () => host?.sessions.scenes,
      events: () => host?.sessions.events,
      dialogues: () => host?.sessions.dialogues,
      cinematics: () => host?.sessions.cinematics,
      presentations: () => host?.sessions.presentations,
      regionalMap: () => host?.sessions.regionalMap,
      world: () => host?.sessions.world,
      projectVisuals: () => host?.sessions.projectVisuals,
      projectSurf: () => host?.sessions.projectSurf,
      projectCs: () => host?.sessions.projectCs,
      projectAudio: () => host?.sessions.projectAudio,
      projectIdentity: () => host?.sessions.projectIdentity,
      confirmClose: () async => closeChoice,
      flushFocus: () {},
      launchMap: (_, _) async =>
          throw StateError('No playtest launch requested by creation fixture'),
    );
  }

  Future<bool> closeCreation() async {
    final controller = creator;
    if (controller == null) return true;
    if (!controller.canClose) {
      controller.cancel();
      return false;
    }
    final closed = _creatorClosed;
    if (closed != null && !closed.isCompleted) closed.complete();
    await _creationLifetime;
    _creationLifetime = null;
    _creatorClosed = null;
    controller.dispose();
    creator = null;
    _openCreated = null;
    return true;
  }

  Future<void> pump({int frames = 4}) =>
      RealTestIo.pump(tester, frames: frames);

  Future<void> _closeViewport() async {
    await viewport?.dispose();
    viewport = null;
    workflow = null;
    gameExport?.dispose();
    gameExport = null;
    _maps?.dispose();
    _maps = null;
  }

  Future<void> dispose() {
    if (_disposed) return Future<void>.value();
    return _disposal ??= _dispose().whenComplete(() => _disposed = true);
  }

  Future<void> _dispose() async {
    _opening?.dispose();
    final closed = _creatorClosed;
    if (closed != null && !closed.isCompleted) closed.complete();
    await _creationLifetime;
    creator?.dispose();
    creator = null;
    await _closeViewport();
    _recents.dispose();
    await session.dispose();
    await tester.pumpWidget(const SizedBox());
  }
}
