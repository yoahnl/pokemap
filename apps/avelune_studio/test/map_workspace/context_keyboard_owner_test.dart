import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_context_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  late MapContextOwnerHarness h;
  setUp(() => h = MapContextOwnerHarness.of(workspaceProject));
  tearDown(() => h.dispose());

  testWidgets('a single decor reports blocked stacking actions', (
    tester,
  ) async {
    MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    await h.pump(tester);
    await h.rightClick(tester, 4, 4);
    final action = h.request!.actions.singleWhere(
      (action) => action.command == MapContextCommand.bringForward,
    );
    expect(action.enabled, isFalse);
    expect(action.unavailable, contains('Aucun autre décor'));
  });

  testWidgets('right-clicking another cell never reuses the old target', (
    tester,
  ) async {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final first = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    await h.pump(tester);
    await h.rightClick(tester, 4, 4);
    expect(h.request!.target!.id, first.id);
    await h.rightClick(tester, 18, 1);
    expect(h.request!.target, isNull);
    expect(h.request!.targets, isEmpty);
    expect(commands.selected(first.id), isNotNull);
  });

}
