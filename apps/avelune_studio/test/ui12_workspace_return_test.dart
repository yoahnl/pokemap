import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/presentations/presentation_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';
import 'support/ui11_widget_port.dart';
import 'support/ui12_return_harness.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 15);
}

SceneBuilderPage scenePage(WidgetTester tester) =>
    tester.widget<SceneBuilderPage>(find.byType(SceneBuilderPage));

void selectNode(WidgetTester tester, String sceneId, String nodeId) {
  final page = scenePage(tester);
  page.views.forScene(sceneId).nodeId = nodeId;
  page.controller.changed();
}

void main() {
  testWidgets('a detour through a second consumer still returns to scene A', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = (await tester.runAsync(Ui12ReturnHarness.create))!;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    final visuals = (await tester.runAsync(
      () => StudioMapResources.load(h.session, h.controller.project!),
    ))!;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(h.dispose);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: h.controller,
          loadVisuals: (_, _) async => visuals,
          narrativePort: Ui05NarrativePort(h.narrativeAdapter, tester),
          scenePort: h.scenePort,
          presentationPort: Ui11WidgetPort(h.presentationPort, tester)
            ..interactive = true,
          onClose: () async {},
          registerExitGuard: (_) {},
          runtimeBuilder: (_, _, _) => const SizedBox(),
        ),
      ),
    );
    await pumpIo(tester);

    await activate(
      tester,
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await activate(tester, find.text('Scènes').first);
    await activate(tester, find.text(h.sceneA.name).last);
    expect(scenePage(tester).controller.active!.current.id, h.sceneA.id);
    selectNode(tester, h.sceneA.id, h.nodeA);
    await pumpIo(tester);

    await activate(tester, find.text('Ouvrir la présentation'));
    final presentation = tester.widget<PresentationWorkspacePage>(
      find.byType(PresentationWorkspacePage),
    );
    expect(presentation.controller.activeId, h.presentationId);
    expect(
      presentation.previewSceneId,
      h.sceneA.id,
      reason: 'The preview must follow the scene the author came from',
    );
    for (var i = 0; i < 40 && presentation.controller.active == null; i++) {
      await pumpIo(tester, frames: 3);
    }
    final asset = presentation.controller.active!.asset;
    presentation.views
        .forAsset(asset)
        .editing
        .selectClip(asset.tracks.expand((t) => t.clips).first.id);
    presentation.controller.changed();
    await pumpIo(tester);

    await activate(tester, find.text('${h.sceneB.name} · Présentation liée'));
    expect(find.byType(SceneBuilderPage), findsOneWidget);
    expect(scenePage(tester).controller.active!.current.id, h.sceneB.id);

    await activate(tester, find.text('la présentation'));
    expect(find.byType(PresentationWorkspacePage), findsOneWidget);
    expect(presentation.controller.activeId, h.presentationId);

    await activate(tester, find.byTooltip('Retour à la scène'));
    expect(find.byType(SceneBuilderPage), findsOneWidget);
    expect(
      scenePage(tester).controller.active!.current.id,
      h.sceneA.id,
      reason: 'A detour through B must not rewrite where the author started',
    );
    expect(tester.takeException(), isNull);
  });
}
