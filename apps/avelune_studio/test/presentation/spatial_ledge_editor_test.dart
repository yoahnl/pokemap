import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_ledge_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spatial_environment_fixture.dart';

void main() {
  testWidgets('guided ledge editing adds a native jump and can undo it', (
    tester,
  ) async {
    final map = spatialEnvironmentMap();
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'ledge'),
    );
    await tester.binding.setSurfaceSize(const Size(900, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => SpatialLedgeEditor(
              document: document,
              project: spatialEnvironmentProject(),
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('spatial-ledge-add')));
    await tester.pump();
    expect(document.current.spatialScene!.navigation.ledges, hasLength(1));
    expect(document.undoCount, 1);
    await tester.tap(find.byKey(const ValueKey('spatial-ledge-delete')));
    await tester.pump();
    expect(document.current.spatialScene!.navigation.ledges, isEmpty);
    document.restore(redo: false);
    expect(document.current.spatialScene!.navigation.ledges, hasLength(1));
  });
}
