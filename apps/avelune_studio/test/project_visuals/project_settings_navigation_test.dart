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
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';

void main() {
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
  @override Future<MapWorkspaceDocument> loadMap(ProjectSession session, ProjectMapEntry entry) async {
    final value=await super.loadMap(session,entry);
    return MapWorkspaceDocument(map:value.map.copyWith(spatialScene:MapSpatialScene(width:20,depth:16)),revision:value.revision,mapId:entry.id);
  }
  @override Future<ProjectVisualsState> loadVisuals(ProjectSession session,{ProjectMapEntry? map}) async=>ProjectVisualsState(profile:SpatialVisualPatch(),revision:'visual');
  @override Future<ProjectVisualsState> saveVisuals(ProjectSession session, SpatialVisualPatch profile,String expectedRevision,{ProjectMapEntry? map}) async=>ProjectVisualsState(profile:profile,revision:'saved');
  @override Future<ProjectVisualsState> undoVisuals(ProjectSession session,String receiptId,String expectedRevision,{ProjectMapEntry? map})=>throw UnimplementedError();
}
class _Sessions implements ProjectSessionPort {
  @override Future<ProjectSession> open(String path) async=>workspaceSession;
  @override Future<void> close(ProjectSession session) async{}
}
