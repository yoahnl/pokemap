import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  test('shops owns a typed Narrative Studio route and breadcrumb', () {
    final location = NarrativeStudioRouteLocation.shops();
    expect(location.destination, NarrativeStudioDestination.shops);
    expect(location.childRoute, NarrativeStudioChildRoute.shopBuilder);
    expect(
      narrativeStudioRoutePresentationFor(EditorWorkspaceMode.shops)!
          .breadcrumbLabels,
      contains('Boutique Builder'),
    );
  });

  testWidgets('the Boutiques rail opens the four-zone Shop Builder',
      (tester) async {
    final container = await pumpEditorShellPage(
      tester,
      initialState: const EditorState(
        project: ProjectManifest(
          name: 'Selbrume',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          shops: <ShopDefinition>[
            ShopDefinition(id: 'port', label: 'Boutique du Port'),
          ],
        ),
        workspaceMode: EditorWorkspaceMode.facts,
      ),
      surfaceSize: const Size(1672, 941),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('narrative-studio-product-nav-shops'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      container.read(editorNotifierProvider).workspaceMode,
      EditorWorkspaceMode.shops,
    );
    expect(find.byKey(const Key('shop-editor-panel')), findsOneWidget);
    expect(find.textContaining('Boutique Builder'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
