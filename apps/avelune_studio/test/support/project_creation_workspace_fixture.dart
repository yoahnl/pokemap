import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

import 'm2_ui_fixture.dart' show WidgetResourcePort, pumpIo;
import 'ui05_narrative_fixture.dart' show Ui05NarrativePort;
import 'ui08_workspace_harness.dart' show Ui08MapPort;

class ProjectCreationWorkspaceFixture {
  ProjectCreationWorkspaceFixture(this.tester, this.parent, this.packageFile);
  final WidgetTester tester;
  final Directory parent;
  final File packageFile;
  late ProjectSessionController session = ProjectSessionController(
    _SessionIo(tester),
  );
  final recents = MemoryRecentProjectsAdapter();

  Future<void> mount({
    ProjectCreationPort? creationPort,
    MapWorkspacePort Function(MapWorkspacePort)? mapPort,
    ProjectSessionController? sessionController,
    bool withNarrative = false,
    bool settle = true,
    bool bridgeCreate = true,
    Size size = const Size(1536, 960),
    double textScale = 1,
    GlobalKey? captureKey,
  }) async {
    if (sessionController != null) session = sessionController;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final app = DefaultAssetBundle(
      bundle: CreationStudioAssets(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: studioTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: ProjectSessionScreen(
          session: session,
          chooseDirectory: () async => null,
          recentProjects: recents,
          creationPort: _CreationIo(
            tester,
            creationPort ?? const LocalProjectCreationService(),
            bridgeCreate,
          ),
          chooseCreationParent: () async => parent.path,
          workspaceBuilder: (project, close) => _CreatedWorkspace(
            tester: tester,
            session: project,
            onClose: close,
            packageFile: packageFile,
            mapPort: mapPort,
            withNarrative: withNarrative,
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      captureKey == null ? app : RepaintBoundary(key: captureKey, child: app),
    );
    if (settle) await pumpIo(tester);
  }

  MapWorkspaceController get maps => tester
      .widget<MapWorkspaceScreen>(
        find.byType(MapWorkspaceScreen, skipOffstage: false),
      )
      .controller;

  Future<void> create(int tileSize, {String? name}) async {
    await submitCreation(tileSize, name: name);
    for (var i = 0; i < 100 && session.state.project == null; i++) {
      await pumpIo(tester, frames: 2);
    }
    expect(session.state.project, isNotNull);
    await pumpIo(tester, frames: 30);
    expect(find.byType(MapWorkspaceScreen), findsOneWidget);
  }

  Future<void> submitCreation(
    int tileSize, {
    String? name,
    bool settle = true,
    bool confirm = true,
  }) async {
    await tester.tap(find.text('Nouveau projet'));
    await pumpIo(tester, frames: 4);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom du projet'),
      name ?? 'Projet grille $tileSize',
    );
    await next();
    await next();
    await tester.tap(find.byKey(ValueKey('creation-grid-$tileSize')));
    await next();
    await tester.tap(find.byKey(const ValueKey('creation-choose-parent')));
    await pumpIo(tester, frames: 8);
    if (confirm) {
      await tester.tap(find.byKey(const ValueKey('create-project-confirm')));
    }
    if (settle) await pumpIo(tester, frames: 20);
  }

  Future<void> next() async {
    await tester.tap(find.text('Suivant'));
    await pumpIo(tester, frames: 4);
  }

  Future<void> dispose() async {
    await tester.pumpWidget(const SizedBox());
    await session.dispose();
  }
}

class _CreationIo implements ProjectCreationPort {
  _CreationIo(this.tester, this.delegate, this.bridgeCreate);
  final WidgetTester tester;
  final ProjectCreationPort delegate;
  final bool bridgeCreate;
  Future<T> _run<T>(Future<T> Function() action) async {
    final result = await WidgetResourcePort.serial(tester, () async {
      try {
        return (value: await action(), error: null);
      } catch (error) {
        return (value: null, error: error);
      }
    });
    if (result!.error case final error?) throw error;
    return result.value as T;
  }

  @override
  Future<List<int>?> preview(ProjectCreationRequest request) => bridgeCreate
      ? _run(() => delegate.preview(request))
      : delegate.preview(request);

  @override
  Future<String> validateDestination(ProjectCreationRequest request) =>
      bridgeCreate
      ? _run(() => delegate.validateDestination(request))
      : delegate.validateDestination(request);

  @override
  Future<ProjectCreationReceipt> create(
    ProjectCreationRequest request, {
    void Function(ProjectCreationPhase)? onPhase,
    bool Function()? isCancelled,
    String? expectedDestination,
  }) => bridgeCreate
      ? _run(
          () => delegate.create(
            request,
            onPhase: onPhase,
            isCancelled: isCancelled,
            expectedDestination: expectedDestination,
          ),
        )
      : delegate.create(
          request,
          onPhase: onPhase,
          isCancelled: isCancelled,
          expectedDestination: expectedDestination,
        );
}

class _SessionIo implements ProjectSessionPort {
  _SessionIo(this.tester);
  final WidgetTester tester;
  final delegate = LocalProjectSessionAdapter();
  @override
  Future<ProjectSession> open(String path) async =>
      (await WidgetResourcePort.serial(tester, () => delegate.open(path)))!;
  @override
  Future<void> close(ProjectSession session) => delegate.close(session);
}

class _CreatedWorkspace extends StatefulWidget {
  const _CreatedWorkspace({
    required this.tester,
    required this.session,
    required this.onClose,
    required this.packageFile,
    this.mapPort,
    this.withNarrative = false,
  });
  final WidgetTester tester;
  final ProjectSession session;
  final Future<void> Function() onClose;
  final File packageFile;
  final MapWorkspacePort Function(MapWorkspacePort)? mapPort;
  final bool withNarrative;
  @override
  State<_CreatedWorkspace> createState() => _CreatedWorkspaceState();
}

class _CreatedWorkspaceState extends State<_CreatedWorkspace> {
  late final adapter = LocalMapWorkspaceAdapter();
  late final ioPort = Ui08MapPort(adapter, widget.tester)..interactive = true;
  late final port = widget.mapPort?.call(ioPort) ?? ioPort;
  late final maps = MapWorkspaceController(widget.session, port);
  late final export = StudioGameExportController(
    projectRoot: Directory(widget.session.directoryPath),
    projectName: widget.session.name,
  );
  @override
  void dispose() {
    maps.dispose();
    export.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MapWorkspaceScreen(
    controller: maps,
    home: StudioHomeScope.of(context),
    loadVisuals: (session, manifest) async => (await WidgetResourcePort.serial(
      widget.tester,
      () => StudioMapResources.load(session, manifest),
    ))!,
    narrativePort: widget.withNarrative
        ? Ui05NarrativePort(
            LocalNarrativeAdapter(session: widget.session, mapAdapter: adapter),
            widget.tester,
          )
        : null,
    gameExport: export,
    gameExportPicker: (_) async => StudioGameExportDestination(
      widget.packageFile.path,
      exists: (await WidgetResourcePort.serial(
        widget.tester,
        widget.packageFile.exists,
      ))!,
    ),
    runtimeBuilder: (_, _, _) => const SizedBox(),
    onClose: widget.onClose,
    registerExitGuard: (_) {},
  );
}

class CreationStudioAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (!key.startsWith('assets/home/')) return rootBundle.load(key);
    final studio = p.basename(Directory.current.path) == 'avelune_studio'
        ? Directory.current.path
        : p.join(Directory.current.path, '../avelune_studio');
    return ByteData.sublistView(
      Uint8List.fromList(await File(p.join(studio, key)).readAsBytes()),
    );
  }
}
