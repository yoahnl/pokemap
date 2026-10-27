import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/project_settings/project_settings_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_ambiance_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_toolbar.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('an open Ambiance panel cannot edit a map that is no longer active', (tester) async {
    final workspace = MapWorkspaceController(workspaceSession, _Maps());
    await workspace.initialize();
    final original = workspace.active!;
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: MapAmbiancePanel(workspace: workspace, document: original, project: workspace.project!, onChanged: () {}))));
    await tester.pumpAndSettle();
    await workspace.activate(workspaceEntries.last);
    await tester.pumpAndSettle();
    final source = tester.widget<StudioSelect>(find.byKey(const ValueKey('map-weather-source')));
    expect(source.onChanged, isNull);
    expect(original.weatherVisuals!.dirty, isFalse);
    await tester.pumpWidget(const SizedBox()); workspace.dispose();
  });
  testWidgets('toolbar reports the unsaved map weather draft immediately', (tester) async {
    tester.view.physicalSize = const Size(1536, 1024); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
    final workspace = MapWorkspaceController(workspaceSession, _Maps());
    await workspace.initialize();
    final owner = workspace.weatherDraftFor(workspace.active!)!;
    await tester.pump(Duration.zero); await tester.pump(Duration.zero);
    expect(owner.saved, isNotNull);
    await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: MapWorkspaceToolbar(controller: workspace, view: null, onChanged: () {}, onActivate: (_) {}, onSave: () {}, onTest: null, onClose: () {}, onPalette: () {}, onInspector: () {}, onNavigator: () {}, paletteVisible: true, inspectorVisible: true, navigatorVisible: true))));
    owner.edit(SpatialVisualPatch.fromJson({'weatherMode': 'fixed', 'weatherKind': 'storm'}));
    await tester.pump();
    expect(find.text('Non enregistré'), findsOneWidget);
    await tester.pumpWidget(const SizedBox()); workspace.dispose();
  });
  testWidgets('Ambiance edits the displayed map after switching and uses the common save button', (tester) async {
    final maps = _Maps();
    final workspace = MapWorkspaceController(workspaceSession, maps);
    await workspace.initialize();
    Future<void> show() async {
      final document = workspace.active!;
      await tester.pumpWidget(MaterialApp(theme: studioTheme(), home: Scaffold(body: MapAmbiancePanel(key: const ValueKey('ambiance'), workspace: workspace, document: document, project: workspace.project!, onChanged: () {}, onSave: () { workspace.save(document); }))));
      await tester.pumpAndSettle();
    }
    await show();
    await workspace.activate(workspaceEntries.last);
    await show();
    final source = find.byKey(const ValueKey('map-weather-source'));
    await tester.ensureVisible(source); await tester.tap(source); await tester.pumpAndSettle();
    await tester.tap(find.text('Forcer un ciel dégagé').last); await tester.pumpAndSettle();
    expect(workspace.active!.visualProfile.choice(SpatialVisualParameter.weatherKind), 'clear');
    final reads = maps.visualReads;
    final catalogs = maps.catalogs;
    await tester.tap(find.byKey(const ValueKey('ambiance-save'))); await tester.pumpAndSettle();
    expect(maps.lastVisualMap, workspaceEntries.last.id);
    expect(maps.visualWrites, 1);
    expect(maps.visualReads, reads);
    expect(maps.catalogs, catalogs);
    expect(maps.writes, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); workspace.dispose();
  });
  test('map ambiance draft survives panel changes and saves only its visual document', () async {
    final maps = _Maps();
    final workspace = MapWorkspaceController(workspaceSession, maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final owner = workspace.weatherDraftFor(document)!;
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    final catalogs = maps.catalogs;
    final writes = maps.writes;
    var workspaceNotifications = 0;
    workspace.addListener(() => workspaceNotifications++);
    owner.edit(owner.preview.value.set(SpatialVisualParameter.weatherMode, 'fixed').set(SpatialVisualParameter.weatherKind, 'storm'));
    expect(workspace.dirty, isTrue);
    expect(workspaceNotifications, 0);
    expect(identical(workspace.weatherDraftFor(document), owner), isTrue);
    expect(document.visualProfile.choice(SpatialVisualParameter.weatherKind), 'storm');
    await workspace.activate(workspaceEntries.last);
    await workspace.activate(workspaceEntries.first);
    expect(document.visualProfile.choice(SpatialVisualParameter.weatherKind), 'storm');
    final reads = maps.visualReads;
    expect(await workspace.save(document), isTrue);
    expect(maps.visualWrites, 1);
    expect(maps.lastVisualMap, document.base.mapId);
    expect(maps.visualReads, reads);
    expect(maps.catalogs, catalogs);
    expect(maps.writes, writes);
    expect(workspace.dirty, isFalse);
  });
  testWidgets('visual settings open from home and map without a workshop or project reload', (tester) async {
    tester.view.physicalSize = const Size(1536,1024);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final maps = _Maps();
    final controller = MapWorkspaceController(workspaceSession,maps);
    await tester.pumpWidget(MaterialApp(theme:studioTheme(),home:ProjectSessionScreen(
      session:ProjectSessionController(_Sessions()), recentProjects:MemoryRecentProjectsAdapter(),chooseDirectory:() async=>'/fixture',
      workspaceBuilder:(_,close)=>Builder(builder:(context)=>MapWorkspaceScreen(controller:controller,
        home:StudioHomeScope.of(context),loadVisuals:(_,_) async=>WorkspaceTestVisuals(),
        runtimeBuilder:(_,_,_)=>const SizedBox(), onClose:close,registerExitGuard:(_){})))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-project-picker')));await tester.pumpAndSettle();
    final catalogs = maps.catalogs;
    final layout = tester.widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout));
    layout.onHome!();await tester.pumpAndSettle();
    await tester.tap(find.text('Réglages du projet'));await tester.pumpAndSettle();
    expect(find.byType(ProjectSettingsPage), findsOneWidget);
    expect(find.text('Test en jeu'),findsOneWidget);
    expect(maps.catalogs,catalogs);
    expect(tester.takeException(),isNull);
    final current = tester.widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout));
    current.onMap();await tester.pumpAndSettle();
    tester.widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout)).onProjectSettings!();await tester.pumpAndSettle();
    expect(find.byType(ProjectSettingsPage),findsOneWidget);
    expect(maps.catalogs,catalogs);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
class _Maps extends WorkspaceMemoryPort implements ProjectVisualsPort {
  int visualReads = 0, visualWrites = 0;
  String? lastVisualMap;
  @override Future<MapWorkspaceDocument> loadMap(ProjectSession session, ProjectMapEntry entry) async {
    final value=await super.loadMap(session,entry);
    return MapWorkspaceDocument(map:value.map.copyWith(spatialScene:MapSpatialScene(width:20,depth:16)),revision:value.revision,mapId:entry.id);
  }
  @override Future<ProjectVisualsState> loadVisuals(ProjectSession session,{ProjectMapEntry? map}) async { visualReads++; return ProjectVisualsState(profile:SpatialVisualPatch(),revision:'visual'); }
  @override Future<ProjectVisualsState> saveVisuals(ProjectSession session, SpatialVisualPatch profile,String expectedRevision,{ProjectMapEntry? map}) async { visualWrites++; lastVisualMap=map?.id; return ProjectVisualsState(profile:profile,revision:'saved'); }
  @override Future<ProjectVisualsState> undoVisuals(ProjectSession session,String receiptId,String expectedRevision,{ProjectMapEntry? map})=>throw UnimplementedError();
}
class _Sessions implements ProjectSessionPort {
  @override Future<ProjectSession> open(String path) async=>workspaceSession;
  @override Future<void> close(ProjectSession session) async{}
}
