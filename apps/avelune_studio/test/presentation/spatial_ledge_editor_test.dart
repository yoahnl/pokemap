import 'package:avelune_studio/features/map_workspace/application/spatial_ledge_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  test('ledge commands add a native jump and can undo its deletion', () {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'ledge'),
    );
    final commands = SpatialLedgeEditingCommands(
      document,
      spatialEnvironmentProject(),
    );
    final ledge = commands.next();
    expect(commands.configure([ledge]), isTrue);
    expect(document.current.spatialScene!.navigation.ledges, hasLength(1));
    expect(document.undoCount, 1);
    expect(
      document.current.spatialScene!.navigation.ledges.single.durationMs,
      400,
    );
    expect(commands.configure([]), isTrue);
    expect(document.current.spatialScene!.navigation.ledges, isEmpty);
    document.restore(redo: false);
    expect(document.current.spatialScene!.navigation.ledges, hasLength(1));
  });
}
