import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';

MapSelectionOwnerHarness fixture() {
  final h = MapSelectionOwnerHarness.of(workspaceProject);
  final id = MapEditingCommands(
    h.document,
    h.project,
  ).place(workspaceElement, const GridPos(x: 4, y: 4))!;
  h.view.select(h.document, MapSelectionFamily.decor, id);
  addTearDown(h.dispose);
  return h;
}

Offset point(WidgetTester tester, Offset pixels) => tester
    .renderObject<RenderBox>(find.byKey(const ValueKey('map-canvas')))
    .localToGlobal(pixels * workspaceProject.settings.displayScale.toDouble());
