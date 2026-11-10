import 'package:avelune_studio/features/map_workspace/application/map_tool_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final spatial in [false, true]) {
    test(
      'connections share tool and destination choices for spatial=$spatial',
      () {
        final state = MapWorkspaceEditingState();
        var palette = '';
        final runner = MapToolCommandRunner(
          view: state,
          paletteTab: () => palette,
          selectPalette: (value) => palette = value,
          spatial: spatial,
          paletteVisible: true,
          onChanged: () {},
          onMoreTools: () {},
          onResources: () {},
        );
        runner.runFamily('Connexions');
        expect(state.tool, StudioMapTool.connection);
        expect(palette, 'Passages');
        final destinations = mapConnectionDestinations(workspaceProject, 'a');
        expect(destinations.map((entry) => entry.id), ['b']);
        expect(mapConnectionTarget(destinations, null), 'b');
        expect(mapConnectionTarget(destinations, 'removed'), 'b');
        expect(mapConnectionTarget(destinations, 'b'), 'b');
        expect(mapConnectionTarget(const [], null), isNull);
        runner.runFamily('Collisions');
        expect(state.tool, StudioMapTool.collisionPaint);
      },
    );
  }

  test(
    'border offsets accept signed integer cells and refuse fractional input',
    () {
      expect(mapConnectionOffset(' -3 '), -3);
      expect(mapConnectionOffset('0'), 0);
      for (final invalid in ['1.5', 'NaN', 'Infinity', 'wrong']) {
        expect(mapConnectionOffset(invalid), isNull);
      }
    },
  );
}
