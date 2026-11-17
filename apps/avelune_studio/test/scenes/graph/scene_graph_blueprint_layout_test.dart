import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../steps/scene_step_fixtures.dart';

void main() {
  testWidgets('a dialogue socket displays its author-facing outcome name', (
    tester,
  ) async {
    final scene = SceneAsset(
      id: 'choice',
      name: 'Choice',
      graph: graphOf(
        [
          startNode(),
          dialogueNode('ask', ['accept_offer']),
          endNode('end'),
        ],
        [link('start', 'ask'), link('ask', 'end')],
      ),
    );
    final project = ProjectManifest(
      name: 'Example',
      maps: const [],
      tilesets: const [],
      dialogues: [
        ProjectDialogueEntry(
          id: 'talk',
          name: 'Invitation',
          relativePath: 'talk.yarn',
          declaredOutcomes: [
            DialogueDeclaredOutcome(id: 'accept_offer', label: 'Accepter'),
          ],
        ),
      ],
    );

    await _pump(tester, scene: scene, project: project, textScale: 1.5);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('scene-graph-port-ask-accept_offer')),
        matching: find.text('Accepter'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 99-step scene opens at a readable scale and can be reframed', (
    tester,
  ) async {
    final scene = SceneAsset(
      id: 'long',
      name: 'Long scene',
      graph: graphOf(
        [
          startNode(),
          for (var i = 1; i <= 97; i++) waitNode('wait-$i'),
          endNode('end'),
        ],
        [
          link('start', 'wait-1'),
          for (var i = 1; i < 97; i++) link('wait-$i', 'wait-${i + 1}'),
          link('wait-97', 'end'),
        ],
      ),
    );
    await _pump(tester, scene: scene, viewport: const Size(765, 556));

    final canvas = tester.state<SceneGraphCanvasState>(
      find.byType(SceneGraphCanvas),
    );
    final originalScale = canvas.camera!.scale;
    expect(originalScale, greaterThan(.6));
    expect(
      tester
          .getRect(find.byKey(const ValueKey('scene-graph-canvas')))
          .contains(
            tester.getCenter(
              find.byKey(const ValueKey('scene-graph-card-start')),
            ),
          ),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('scene-graph-show-all')));
    await tester.pump();
    expect(canvas.camera!.scale, lessThan(originalScale));
    final viewport = tester.getRect(
      find.byKey(const ValueKey('scene-graph-canvas')),
    );
    for (final id in ['start', 'end']) {
      final card = tester.getRect(find.byKey(ValueKey('scene-graph-card-$id')));
      expect(viewport.contains(card.topLeft), isTrue, reason: id);
      expect(viewport.contains(card.bottomRight), isTrue, reason: id);
    }
    final overviewScale = canvas.camera!.scale;
    await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-out')));
    await tester.pump();
    expect(canvas.camera!.scale, overviewScale);
    await tester.tap(find.byKey(const ValueKey('scene-graph-zoom-in')));
    await tester.pump();
    expect(canvas.camera!.scale, greaterThan(overviewScale));
    canvas.show('end');
    await tester.pump();
    expect(canvas.camera!.scale, greaterThan(.6));
    final map = tester.getRect(
      find.byKey(const ValueKey('scene-graph-minimap')),
    );
    await tester.tapAt(map.centerLeft + const Offset(8, -20));
    await tester.pump();
    expect(
      viewport.contains(
        tester.getCenter(find.byKey(const ValueKey('scene-graph-card-start'))),
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required SceneAsset scene,
  ProjectManifest? project,
  double textScale = 1,
  Size viewport = const Size(1280, 720),
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SceneGraphCanvas(scene: scene, project: project),
      ),
    ),
  );
}
