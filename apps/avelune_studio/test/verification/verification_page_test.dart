import 'package:flutter/material.dart';
import 'package:avelune_studio/features/scenes/domain/scene_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_fakes.dart';
import '../presentation/story_memory_harness.dart';
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
        ),
        verificationDiagnostic(
          'node',
          NarrativeProjectDiagnosticDestination.scene,
          sceneId: 'gate',
          path: 'scenes.gate.node.$nodeId',
        ),
      ],
    );
    final index = memoryIndex()
      ..documents['gate'] = SceneDocument(
        scene: scene,
        dialogues: const [],
        missingDialogueIds: const [],
        events: [trameRecords.last],
        maps: const {},
        mapReads: 0,
      );
    await openTrameStudio(tester, verification: port, index: index);
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

    await tester.tap(find.byKey(const ValueKey('story-section-verification')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('verification-open-3')));
    await settleMemory(tester);
    expect(
      find.byKey(const ValueKey('memory-fact-detail-met')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('story-section-verification')));
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
