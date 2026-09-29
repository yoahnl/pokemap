import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';
import '../support/map_tool_menu.dart';

void main() {
  testWidgets('a chosen eraser replaces the misleading selection highlight', (
    tester,
  ) async {
    await MapHostFixture.open(tester);
    await chooseMapExtraTool(tester, 'Gomme de tuiles');

    final canvas = tester.widget<MapWorkspaceCanvas>(
      find.byType(MapWorkspaceCanvas),
    );
    expect(canvas.view.tool, StudioMapTool.erase);
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('Sélectionner')))
          .secondary,
      isTrue,
    );
    expect(find.byKey(const ValueKey('active-extra-tool')), findsOneWidget);
    expect(find.text('Gomme de tuiles'), findsOneWidget);
  });
}
