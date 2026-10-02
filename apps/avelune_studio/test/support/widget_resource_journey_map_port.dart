import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'm2_ui_fixture.dart';

class WidgetResourceJourneyMapPort implements MapWorkspacePort {
  WidgetResourceJourneyMapPort(this.port, this.tester);
  final MapWorkspacePort port;
  final WidgetTester tester;
  bool active = false;

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      port.loadProject(session);

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    if (!active) return port.loadMap(session, entry);
    return (await WidgetResourcePort.serial(
      tester,
      () => port.loadMap(session, entry),
    ))!;
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => port.saveMap(session, base, current);
}
