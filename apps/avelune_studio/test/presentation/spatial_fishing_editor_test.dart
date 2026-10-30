import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_fishing_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('fishing height commits validates and supports undo', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'fishing'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => SpatialFishingEditor(
              document: document,
              project: spatialEnvironmentProject(),
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    );
    final field = find.byType(TextField);
    await tester.enterText(field, '0,5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      document.current.spatialScene!.navigation.maximumFishingDropWorld,
      .5,
    );
    expect(document.undoCount, 1);
    expect(
      document.current.spatialScene!.instances,
      map.spatialScene!.instances,
    );
    await tester.enterText(field, '5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(
      document.current.spatialScene!.navigation.maximumFishingDropWorld,
      .5,
    );
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
  });
}
