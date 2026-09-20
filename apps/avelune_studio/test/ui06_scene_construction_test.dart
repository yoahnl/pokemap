import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_graph_canvas.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_canvas_painter.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/ui06_scene_fixture.dart';
import 'support/ui06_scene_construction_driver.dart';

void main() {
  testWidgets(
    'build both branches through palette, properties and wires then publish and reopen',
    (tester) async {
      tester.view.physicalSize = const Size(1800, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(Ui06SceneFixture.create))!;
      final maps = MapWorkspaceController(fixture.session, fixture.maps);
      await tester.runAsync(maps.initialize);
      final changed = ValueNotifier(0);
      final controller = SceneWorkspaceController(
        maps,
        LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
        changed: () => changed.value++,
      );
      final views = SceneBuilderViewStore();
      addTearDown(() async {
        controller.dispose();
        maps.dispose();
        views.dispose();
        changed.dispose();
        await fixture.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: changed,
              builder: (_, _, _) => SceneBuilderPage(
                controller: controller,
                views: views,
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Créer une scène'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Construite au pointeur',
      );
      await tester.pump();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      final session = controller.active!;
      expect(session.current.graph.nodes, hasLength(2));
      final state = views.forScene(session.current.id);
      state.viewport.zoomAt(.75, Offset.zero);
      state.viewport.translate(-state.viewport.pan + const Offset(10, 10));
      await tester.pump();
      final driver = Ui06SceneConstructionDriver(tester, controller, views);
      final initial = session.current.graph.edges.single;
      final geometry = SceneCanvasGeometry(session.current);
      final path = sceneWirePath(
        state.viewport.worldToLocal(
          geometry.output(initial.fromNodeId, initial.fromPortId, {}),
        ),
        state.viewport.worldToLocal(geometry.input(initial.toNodeId, {})),
      );
      final metric = path.computeMetrics().single;
      await tester.tapAt(
        driver.origin +
            metric.getTangentForOffset(metric.length * .5)!.position,
      );
      await tester.pump();
      await driver.tap('Déconnecter');
      expect(session.current.graph.edges, isEmpty);
      await driver.move('node_start', const Offset(20, 200));
      await driver.move('node_end', const Offset(1220, 400));
      final welcome = await driver.add(
        SceneNodeKind.yarnDialogue,
        const Offset(220, 200),
        document: Ui06SceneFixture.names['station_welcome'],
      );
      final condition = await driver.add(
        SceneNodeKind.condition,
        const Offset(460, 200),
      );
      await driver.select('Référence', 'Laissez-passer obtenu');
      await driver.select('Valeur attendue', 'Oui');
      await driver.tap('Appliquer la condition');
      final refusal = await driver.add(
        SceneNodeKind.yarnDialogue,
        const Offset(710, 440),
        document: Ui06SceneFixture.names['station_refusal'],
      );
      final agreement = await driver.add(
        SceneNodeKind.yarnDialogue,
        const Offset(710, 20),
        document: Ui06SceneFixture.names['station_agreement'],
      );
      final action = await driver.add(
        SceneNodeKind.action,
        const Offset(960, 20),
      );
      final end = await driver.add(SceneNodeKind.end, const Offset(1220, 20));
      await driver.clear();
      for (final label in ['Attente', 'Embarquement']) {
        await driver.tap('Ajouter un résultat');
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          label,
        );
        await tester.tap(find.text('Ajouter'));
        await tester.pumpAndSettle();
      }
      await driver.node('node_end');
      await driver.select('Résultat public', 'Attente');
      await driver.node(end);
      await driver.select('Résultat public', 'Embarquement');
      for (final connection in [
        ('node_start', 'completed', welcome),
        (welcome, 'completed', condition),
        (condition, 'false', refusal),
        (condition, 'true', agreement),
        (refusal, 'completed', 'node_end'),
        (agreement, 'completed', action),
        (action, 'completed', end),
      ]) {
        await driver.wire(connection.$1, connection.$2, connection.$3);
      }
      expect(session.current.graph.nodes, hasLength(8));
      expect(session.current.graph.edges, hasLength(7));
      expect(
        (session.current.graph.nodes
                    .firstWhere((n) => n.id == condition)
                    .payload
                as SceneConditionPayload)
            .conditionSource!
            .sourceId,
        Ui06SceneFixture.passFactId,
      );
      expect(
        (session.current.graph.nodes.firstWhere((n) => n.id == action).payload
                as SceneActionPayload)
            .consequence,
        SceneConsequence.setFact(
          factId: Ui06SceneFixture.departureFactId,
          value: true,
        ),
      );
      final plan = buildSceneRuntimePlan(session.current);
      expect(plan.plan, isNotNull, reason: plan.diagnostics.toString());
      for (final choice in ['false', 'true']) {
        final preview = previewSceneRuntimePath(
          plan.plan!,
          input: SceneDryRunInputState(
            outputPortByNodeId: {
              welcome: 'completed',
              condition: choice,
              refusal: 'completed',
              agreement: 'completed',
            },
          ),
        );
        expect(preview.status, SceneDryRunPreviewStatus.completed);
        expect(
          preview.sceneOutcomeId,
          choice == 'false' ? 'result_1' : 'result_2',
        );
      }
      final expected = session.current;
      debugPrint(
        'UI06 construction: 8 blocs et 7 fils construits, publication',
      );
      final saveButton = find.text('Enregistrer');
      await tester.ensureVisible(saveButton);
      await tester.runAsync(() async {
        await tester.tap(saveButton);
        for (var frame = 0; controller.busy && frame < 300; frame++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      expect(
        controller.busy,
        isFalse,
        reason: 'La publication doit produire un reçu.',
      );
      debugPrint(
        'UI06 construction: publication terminée, relecture indépendante',
      );
      await tester.pumpAndSettle();
      expect(session.error, isNull);
      expect(session.dirty, isFalse);
      final reopened = (await tester.runAsync(
        () => LocalMapWorkspaceAdapter().loadProject(fixture.session),
      ))!;
      expect(reopened.scenes.firstWhere((s) => s.id == expected.id), expected);
      expect(
        reopened.scenes.firstWhere((s) => s.id == Ui06SceneFixture.sceneId),
        fixture.scene,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
