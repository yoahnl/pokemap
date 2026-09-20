import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/capture_m3_widget.dart';
import '../support/m2_ui_fixture.dart';

void main() {
  testWidgets(
    'UI06 real scene page composition and linked document preserve the graph',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        return Ui06SceneFixture.create();
      }))!;
      final maps = MapWorkspaceController(fixture.session, fixture.maps);
      await tester.runAsync(maps.initialize);
      final changed = ValueNotifier(0);
      final narrative = NarrativeWorkspaceController(
        maps,
        LocalNarrativeAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ),
        () => changed.value++,
        (_, _) async {},
      );
      final scenes = SceneWorkspaceController(
        maps,
        LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
        narrative: narrative,
        changed: () => changed.value++,
      );
      scenes.open(Ui06SceneFixture.sceneId);
      final views = SceneBuilderViewStore();
      final search = TextEditingController();
      final capture = GlobalKey();
      addTearDown(() async {
        scenes.dispose();
        narrative.dispose();
        maps.dispose();
        views.dispose();
        search.dispose();
        changed.dispose();
        await fixture.dispose();
      });
      Widget app(double scale) => MaterialApp(
        theme: studioTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: RepaintBoundary(
              key: capture,
              child: ValueListenableBuilder(
                valueListenable: changed,
                builder: (context, value, _) => StudioApplicationFrame(
                  search: search,
                  onSearch: (_) {},
                  onDestination: (_) {},
                  active: 'story',
                  projectName: fixture.session.name,
                  child: SceneBuilderPage(
                    controller: scenes,
                    views: views,
                    narrative: narrative,
                    onBack: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(1));
      await pumpIo(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(SceneGraphCanvas), findsOneWidget);
      await captureM3Widget(tester, capture, '01-scene-complete');
      final initial = scenes.active!.current;
      final dialogueNode = initial.graph.nodes.firstWhere(
        (n) => n.id == 'welcome',
      );
      final state = views.forScene(initial.id);
      final firstEdge = initial.graph.edges.first;
      state.edgeId = firstEdge.id;
      changed.value++;
      await tester.pumpAndSettle();
      await tester.tap(find.text('Déconnecter'));
      await tester.pumpAndSettle();
      final wire = await tester.startGesture(
        tester.getCenter(
          find.byKey(
            ValueKey(
              'scene-graph-output-port-${firstEdge.fromNodeId}-${firstEdge.fromPortId}',
            ),
          ),
        ),
      );
      await wire.moveTo(
        tester.getCenter(
          find.byKey(
            ValueKey('scene-graph-input-port-${firstEdge.toNodeId}-in'),
          ),
        ),
      );
      await tester.pump();
      await captureM3Widget(tester, capture, '02-fil-cible-compatible');
      await wire.cancel();
      await tester.pump();
      await tester.tap(find.byTooltip('Annuler la scène · ⌘Z'));
      await tester.pumpAndSettle();
      expect(scenes.active!.current, initial);
      state.edgeId = null;
      state.nodeId = dialogueNode.id;
      changed.value++;
      await pumpIo(tester);
      await tester.pumpAndSettle();
      await captureM3Widget(tester, capture, '03-propriete-document');
      await tester.ensureVisible(find.text('Ouvrir le dialogue'));
      await tester.tap(find.text('Ouvrir le dialogue'));
      await pumpIo(tester);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(Ui06SceneFixture.lines['station_welcome']!),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Retour à la scène'));
      await tester.pumpAndSettle();
      expect(scenes.active!.current, initial);
      expect(state.nodeId, dialogueNode.id);
      await captureM3Widget(tester, capture, '06-retour-document');
      await tester.tap(find.text('Prévisualiser le chemin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculer le chemin'));
      await tester.pumpAndSettle();
      expect(state.preview, isNotNull);
      await captureM3Widget(tester, capture, '04-chemin-entrees-explicites');
      for (final size in [const Size(1440, 900), const Size(1280, 800)]) {
        tester.view.physicalSize = size;
        state.previewOpen = false;
        await tester.pumpWidget(app(1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(1024, 640);
      await tester.pumpWidget(app(1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Cadrer la scène'));
      await tester.pumpAndSettle();
      await captureM3Widget(tester, capture, '05-compact-texte150');
      for (final label in ['Bibliothèque de scène', 'Inspecteur de scène']) {
        await tester.tap(find.byTooltip(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(state.nodeId, dialogueNode.id);
        expect(scenes.active!.current, initial);
        await tester.tap(find.byTooltip(label));
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
