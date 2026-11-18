import 'package:flutter/material.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:avelune_studio/presentation/features/scene_focus/graph/scene_graph_canvas.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
import '../scenes/steps/scene_step_fixtures.dart';
import '../storyline/storyline_fakes.dart';
import '../storyline/storyline_widget_support.dart';
import 'verification_fakes.dart';

FakeVerificationPort _port() => FakeVerificationPort(
  diagnostics: [
    verificationDiagnostic(
      'milestone',
      NarrativeProjectDiagnosticDestination.storyline,
      stepId: 'meet',
    ),
    verificationDiagnostic(
      'fact',
      NarrativeProjectDiagnosticDestination.fact,
      severity: NarrativeProjectDiagnosticSeverity.warning,
      factId: 'met',
    ),
    verificationDiagnostic(
      'behaviour',
      NarrativeProjectDiagnosticDestination.event,
      eventId: behaviourId(1),
    ),
    verificationDiagnostic(
      'overview',
      NarrativeProjectDiagnosticDestination.overview,
    ),
  ],
);

Future<void> _verify(WidgetTester tester, FakeVerificationPort port) async {
  await openTrameStudio(tester, verification: port);
  await tester.tap(find.byKey(const ValueKey('story-section-verification')));
  await settleMemory(tester);
  expect(port.analyses, 0);
  await tester.tap(find.byKey(const ValueKey('verification-start')));
  await settleMemory(tester);
}

void main() {
  testWidgets('an empty report with unverified coverage is not clean', (
    tester,
  ) async {
    await _verify(tester, FakeVerificationPort());

    expect(find.byKey(const ValueKey('verification-clean')), findsNothing);
    expect(find.byKey(const ValueKey('verification-summary')), findsNothing);
    expect(
      find.byKey(const ValueKey('verification-incomplete')),
      findsOneWidget,
    );
  });

  testWidgets(
    'the navigation and report mark a changed saved revision without rerunning',
    (tester) async {
      final port = FakeVerificationPort();
      await _verify(tester, port);
      expect(find.byKey(const ValueKey('verification-stale')), findsNothing);

      port.revision = 'r2';
      await tester.pump(const Duration(seconds: 2));
      await settleMemory(tester);

      expect(find.byKey(const ValueKey('verification-stale')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('verification-nav-status')),
          matching: find.text('Périmée'),
        ),
        findsOneWidget,
      );
      expect(port.analyses, 1);
    },
  );

  for (final (label, savedId, currentIds, target) in [
    ('focuses the end of a scene', 'end', ['end'], 'end'),
    ('accepts a dotted node identity', 'part.end', ['part.end'], 'part.end'),
    ('shows diagnostics for a removed node', 'end', ['replacement'], null),
    (
      'rejects a different node named after a removed node field',
      'end',
      ['end.outcomePolicy'],
      null,
    ),
    (
      'rejects a surviving prefix of a removed node',
      'part.end',
      ['part'],
      null,
    ),
    (
      'uses the real node identity when the field path is also a node id',
      'end',
      ['end', 'end.outcomePolicy'],
      'end',
    ),
  ]) {
    testWidgets('an outcome-policy diagnostic $label', (tester) async {
      final saved = _diagnosticScene([savedId]);
      final project = trameProject.copyWith(scenes: [saved]);
      final diagnostic = validateNarrativeProject(
        project,
        maps: const [],
      ).byCode('sceneOutcomePolicyIndeterminate').single;
      expect(diagnostic.path, 'scenes.gate.nodes.$savedId.outcomePolicy');
      final port = FakeVerificationPort(diagnostics: [diagnostic]);
      final index = memoryIndex()
        ..documents['gate'] = SceneDocument(
          scene: _diagnosticScene(currentIds),
          dialogues: const [],
          missingDialogueIds: const [],
          events: const [],
          maps: const {},
          mapReads: 0,
        );
      await openTrameStudio(
        tester,
        project: project,
        verification: port,
        index: index,
      );
      await tester.tap(
        find.byKey(const ValueKey('story-section-verification')),
      );
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('verification-start')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('verification-open-0')));
      await settleMemory(tester);

      final graph = find.byType(SceneGraphCanvas).first;
      expect(tester.state<SceneGraphCanvasState>(graph).selection, {?target});
      if (target == null) {
        expect(
          find.byKey(const ValueKey('scene-graph-checks')),
          findsOneWidget,
        );
      } else {
        expect(
          find.byKey(ValueKey('scene-graph-inspector-$target')),
          findsOneWidget,
        );
        final viewport = tester.getRect(
          find.byKey(const ValueKey('scene-graph-canvas')).first,
        );
        final card = tester.getRect(
          find.byKey(ValueKey('scene-graph-card-$target')).first,
        );
        expect(viewport.contains(card.center), isTrue);
      }
    });
  }

  testWidgets('a scene diagnostic opens the scene without choosing a carrier', (
    tester,
  ) async {
    final scene = trameProject.scenes.last;
    final nodeId = scene.graph.nodes.last.id;
    final port = FakeVerificationPort(
      diagnostics: [
        verificationDiagnostic(
          'scene',
          NarrativeProjectDiagnosticDestination.scene,
          sceneId: 'gate',
          path: 'scenes.gate.node.$nodeId',
        ),
        verificationDiagnostic(
          'node',
          NarrativeProjectDiagnosticDestination.scene,
          sceneId: 'gate',
          sceneNodeId: nodeId,
          path: 'scenes.gate.node.$nodeId',
        ),
      ],
    );
    final index = memoryIndex()
      ..documents['gate'] = SceneDocument(
        scene: scene,
        dialogues: const [],
        missingDialogueIds: const [],
        events: const [],
        maps: const {},
        mapReads: 0,
      );
    await openTrameStudio(
      tester,
      index: index,
      verification: port,
      project: trameProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [trameRecords.first],
          legacyClaims: const [],
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('story-section-verification')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-start')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-0')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('scene-focus-graph-gate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('map-story-inspector-map:a')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('scene-graph-checks')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scene-focus-close')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-1')));
    await settleMemory(tester);
    expect(
      find.byKey(ValueKey('scene-graph-inspector-$nodeId')),
      findsOneWidget,
    );
  });

  testWidgets('global verification reads saved data and keeps the plot draft', (
    tester,
  ) async {
    final saved = trameProject.copyWith(storylines: [mainStoryline()]);
    final port = FakeVerificationPort();
    await openTrameStudio(tester, project: saved, verification: port);
    await tester.tap(find.byKey(const ValueKey('trame-storyline-main')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('trame-chapter-add')));
    await settleMemory(tester);
    expect(find.text('Nouveau chapitre'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-section-verification')));
    await settleMemory(tester);
    expect(port.analyses, 0);
    expect(find.byKey(const ValueKey('verification-unsaved')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('verification-start')));
    await settleMemory(tester);

    expect(port.analyses, 1);
    expect(port.analysedProject!.storylines, saved.storylines);
    expect(port.analysedProject!.storylines.single.chapters, hasLength(2));
    expect(find.byKey(const ValueKey('verification-unsaved')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('story-section-trame')));
    await settleMemory(tester);
    expect(find.text('Nouveau chapitre'), findsOneWidget);
    expect(saved.storylines.single.chapters, hasLength(2));
  });

  testWidgets('a verification lists problems and opens each place', (
    tester,
  ) async {
    final port = _port();
    await _verify(tester, port);

    expect(port.analyses, 1);
    expect(find.byKey(const ValueKey('verification-summary')), findsOneWidget);
    expect(find.text('Problème milestone'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-open-2')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('verification-open-0')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('trame-milestone-detail-meet')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('story-return')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-3')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('memory-fact-detail-met')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('story-return')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-1')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('map-story-inspector-entity:guide')),
      findsOneWidget,
    );
  });

  testWidgets('editing never starts a verification', (tester) async {
    final port = _port();
    await openTrameStudio(tester, verification: port);
    await tester.tap(find.byKey(const ValueKey('trame-storyline-main')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('trame-chapter-add')));
    await settleMemory(tester);

    expect(port.analyses, 0);
    await tester.tap(find.byKey(const ValueKey('story-section-verification')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('verification-unsaved')), findsOneWidget);
    expect(find.text('Le projet n’a pas encore été vérifié'), findsOneWidget);
  });
}

SceneAsset _diagnosticScene(List<String> ends) => SceneAsset(
  id: 'gate',
  name: 'La grille',
  graph: graphOf(
    [
      startNode(),
      for (final id in ends)
        SceneNode(id: id, kind: SceneNodeKind.end, payload: SceneEndPayload()),
    ],
    [link('start', ends.first)],
  ),
  layout: SceneGraphLayout(
    nodeLayouts: [
      SceneNodeLayout(nodeId: 'start', x: 0, y: 0),
      for (final (index, id) in ends.indexed)
        SceneNodeLayout(nodeId: id, x: 2200, y: 300.0 * index),
    ],
  ),
);
