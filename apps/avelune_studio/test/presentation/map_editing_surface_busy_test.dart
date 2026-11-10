import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/neutral_map_host_fixture.dart';
import '../support/spatial_environment_fixture.dart';
import '../support/spatial_narrative_fixture.dart';

void main() {
  testWidgets('busy spatial surface refuses focused deletion and resumes editing', (
    tester,
  ) async {
    final port = _SpatialPort()..saved['a'] = spatialEnvironmentMap();
    final controller = MapWorkspaceController(workspaceSession, port);
    addTearDown(controller.dispose);
    await controller.initialize();
    var busy = false;
    final host = await NeutralMapHostFixture.fromController(
      tester,
      controller,
      visuals: SpatialNarrativeVisuals(),
      isBusy: () => busy,
    );
    final document = controller.active!;
    final placed = SpatialModelEditingCommands(
      document,
      controller.project!,
    ).place(controller.project!.models3d.single, const GridPos(x: 2, y: 2));
    host.nativeView.select(document, MapSelectionFamily.decor, placed.id);
    controller.notify();
    await host.pump();
    FocusNode viewportFocus() => tester.widgetList<Focus>(
      find.descendant(
        of: find.byType(SpatialMapEditingViewport),
        matching: find.byType(Focus),
      ),
    ).firstWhere((focus) => focus.onKeyEvent != null).focusNode!;
    viewportFocus().requestFocus();
    await tester.pump();
    expect(viewportFocus().hasFocus, isTrue);
    final before = document.current;
    final history = document.undoCount;
    busy = true;
    controller.notify();
    await host.pump();
    await host.key(LogicalKeyboardKey.delete);
    expect(document.current, same(before));
    expect(document.undoCount, history);
    busy = false;
    controller.notify();
    await host.pump();
    viewportFocus().requestFocus();
    await tester.pump();
    await host.key(LogicalKeyboardKey.delete);
    expect(document.current.spatialScene!.instances, isEmpty);
    expect(document.undoCount, history + 1);
    expect(tester.takeException(), isNull);
  });
}

class _SpatialPort extends WorkspaceMemoryPort {
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    catalogs++;
    return spatialEnvironmentProject();
  }
}
