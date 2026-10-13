import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_border_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/native_ledge_regeneration_test.dart'
    show nativeLedgeMap, nativeLedgeFeature;
import '../resource_io/ledge_border_metadata_test.dart'
    show NativeLedgeResourceFixture;

void main() {
  testWidgets('a stale 2D ledge exposes explicit preview cancel and apply', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = (await tester.runAsync(NativeLedgeResourceFixture.create))!;
    addTearDown(fixture.dispose);
    final base = (await tester.runAsync(fixture.base.loadMap))!;
    final map = nativeLedgeMap(base.map, fixture.project);
    final receipt = (await tester.runAsync(
      () => fixture.resources.createBorder(
        BorderCreationRequest(
          blueprintId: fixture.record.id,
          name: 'Rebord republié',
          jumpSide: BorderLineSide.inverted,
          expectedRecord: fixture.record,
        ),
      ),
    ))!;
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'r0', mapId: map.id),
    );
    final view = MapWorkspaceViewState();
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => MapBorderToolPanel(
              document: document,
              project: receipt.manifest,
              view: view,
              onChanged: () => refresh(() {}),
              onCreateModel: () {},
            ),
          ),
        ),
      ),
    );
    final preview = find.byKey(const ValueKey('border-regeneration-preview'));
    expect(preview, findsOneWidget);
    expect(
      find.textContaining('Le tracé ou une pièce source a changé'),
      findsOneWidget,
    );
    await tester.tap(preview);
    await tester.pump();
    expect(view.borderPreview, isNotNull);
    expect(document.current, same(map));
    expect(document.undoCount, 0);
    await tester.tap(find.text('Annuler l’aperçu'));
    await tester.pump();
    expect(view.borderPreview, isNull);
    expect(document.current, same(map));
    await tester.tap(preview);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('border-regeneration-apply')));
    await tester.pump();
    expect(document.undoCount, 1);
    expect(
      nativeLedgeFeature(document.current)
          .materialization!
          .receipt
          .blueprintRevision,
      2,
    );
    expect(
      nativeLedgeFeature(document.current).overrides,
      nativeLedgeFeature(map).overrides,
    );
    expect(view.borderPreview, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
