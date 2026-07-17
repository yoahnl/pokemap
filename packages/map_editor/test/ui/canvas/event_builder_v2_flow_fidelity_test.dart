import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_editor.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_element_library.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_inspector.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('NS-EVENT-V2-39 editor flow fidelity', () {
    testWidgets('keeps a narrow rail and handles 0/1/2/3+ Scene outcomes',
        (tester) async {
      for (final count in [0, 1, 2, 4]) {
        await _pumpPanel(
          tester,
          width: 565,
          child: EventBuilderV2Editor(
            event: _summary(outcomeCount: count),
            onOpenScene: () {},
          ),
        );

        expect(
          tester
              .getSize(
                find.byKey(const ValueKey('event-builder-v2-flow-rail')),
              )
              .width,
          lessThanOrEqualTo(404),
          reason: '$count outcomes',
        );
        expect(
          find.byKey(ValueKey('event-builder-v2-outcomes-$count')),
          findsOneWidget,
        );
        expect(
          tester
              .getSize(
                find.byKey(
                  const ValueKey('event-builder-v2-source-block'),
                ),
              )
              .height,
          lessThanOrEqualTo(96),
          reason: 'the trigger card must keep the compact reference density',
        );
        final sourceWidth = tester
            .getSize(
              find.byKey(
                const ValueKey('event-builder-v2-source-block'),
              ),
            )
            .width;
        final conditionsWidth = tester
            .getSize(
              find.byKey(
                const ValueKey('event-builder-v2-conditions-block'),
              ),
            )
            .width;
        expect(sourceWidth, lessThanOrEqualTo(304));
        expect(sourceWidth, lessThan(conditionsWidth));
        expect(
          find.byKey(
            const ValueKey('event-builder-v2-outcome-branch-connector'),
          ),
          count >= 2 ? findsOneWidget : findsNothing,
          reason: '$count outcomes',
        );
        expect(
          find.byKey(
            const ValueKey('event-builder-v2-behavior-block'),
          ),
          findsNothing,
          reason: 'behavior stays editable in the inspector, as in the target',
        );
        final endBadge = tester.getRect(find.text('Fin de l’événement'));
        expect(
          endBadge.bottom,
          lessThanOrEqualTo(817),
          reason: 'the full event flow must fit the reference-height canvas',
        );
        expect(tester.takeException(), isNull, reason: '$count outcomes');
      }
    });

    testWidgets('wraps long author labels without overflow', (tester) async {
      final longLabel = List.filled(
        8,
        'Victoire diplomatique au port pendant la grande célébration',
      ).join(' ');

      await _pumpPanel(
        tester,
        width: 565,
        child: EventBuilderV2Editor(
          event: _summary(
            title: longLabel,
            outcomeLabels: [longLabel, longLabel],
          ),
          onOpenScene: () {},
        ),
      );

      expect(find.text(longLabel), findsWidgets);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Déposez'), findsNothing);
      expect(find.textContaining('Ajouter une réaction'), findsNothing);
    });

    testWidgets('does not invent outcome meaning from Scene list order',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 565,
        child: EventBuilderV2Editor(
          event: _summary(outcomeLabels: const ['Échec', 'Victoire']),
          onOpenScene: () {},
        ),
      );

      // The read model exposes labels only. Success/danger styling based on
      // list position would lie whenever the Scene orders its outcomes
      // differently, so every projected outcome stays semantically neutral.
      expect(find.byIcon(CupertinoIcons.rosette), findsNothing);
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);
      expect(find.byIcon(CupertinoIcons.flag_fill), findsWidgets);
    });
  });

  group('NS-EVENT-V2-39 element library fidelity', () {
    testWidgets('is dense and separates Event authoring from Scene read-only',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 213,
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: true,
          onOpenScene: () {},
        ),
      );

      for (final heading in const [
        'DÉCLENCHEURS',
        'CONDITIONS',
        'SCENE LIÉE',
        'RÉSULTATS',
        'RÉACTIONS',
        'MONDE',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      expect(find.text('Interaction avec un PNJ'), findsOneWidget);
      expect(find.text('Entrée dans une zone'), findsOneWidget);
      expect(find.text('Interaction avec un objet'), findsOneWidget);
      expect(find.text('Défini dans la Scene'), findsWidgets);
      expect(find.textContaining('Défini dans la Scene'), findsWidgets);
      for (var index = 0; index < 4; index++) {
        expect(
          tester
              .getSize(
                find.byKey(
                  ValueKey('event-builder-v2-library-authorable-$index'),
                ),
              )
              .height,
          lessThanOrEqualTo(34),
        );
      }
      expect(find.textContaining('Déposez'), findsNothing);
      expect(find.textContaining('Glissez'), findsNothing);
      expect(find.byIcon(CupertinoIcons.line_horizontal_3), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the real Scene action supports hover and keyboard focus',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 213,
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: true,
          onOpenScene: () {},
        ),
      );
      final action = find.text('Ouvrir la Scene');
      final actionButton = find.ancestor(
        of: action,
        matching: find.byType(PokeMapButton),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);

      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await mouse.addPointer(location: tester.getCenter(action));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(action, findsOneWidget);
      expect(
        find.descendant(
          of: actionButton,
          matching: find.byType(FocusableActionDetector),
        ),
        findsOneWidget,
      );
      expect(_primaryFocusIsInside(actionButton), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not expose a dead Scene action without a callback',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 213,
        child: const EventBuilderV2ElementLibrary(hasLinkedScene: true),
      );

      expect(find.text('Ouvrir la Scene'), findsNothing);
      expect(find.text('Scene liée — ouverture indisponible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('NS-EVENT-V2-39 inspector fidelity', () {
    testWidgets('renders the truthful dense hierarchy and optional conflict',
        (tester) async {
      await _pumpPanel(
        tester,
        width: 388,
        child: EventBuilderV2Inspector(
          event: _summary(
            outcomeCount: 2,
            activeCandidateCount: 2,
            priority: 10,
            order: 0,
          ),
          onOpenScene: () {},
          onChangeBehavior: () {},
        ),
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-source')),
        findsOneWidget,
      );
      expect(find.text('SOURCE DU DÉCLENCHEUR'), findsOneWidget);
      expect(find.text('PORTÉE DÉRIVÉE · LECTURE SEULE'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-conditions')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-scene')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-behavior')),
        findsOneWidget,
      );
      expect(find.text('Modifier'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-conflict')),
        findsNothing,
      );
      expect(find.textContaining('2 résultats'), findsOneWidget);
      expect(find.textContaining('Lecture seule'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _pumpPanel(
        tester,
        width: 388,
        child: EventBuilderV2Inspector(
          event: _summary(
            outcomeCount: 2,
            activeCandidateCount: 2,
            priority: 10,
            order: 0,
          ),
          onOpenScene: () {},
          onManageEvaluationOrder: () {},
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('event-builder-v2-inspector-conflict')),
        240,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-inspector-conflict')),
        findsOneWidget,
      );
    });

    testWidgets('supports long labels and four projected outcomes',
        (tester) async {
      final longLabel = List.filled(
        7,
        'Rencontre rivale au port sous une pluie particulièrement intense',
      ).join(' ');
      await _pumpPanel(
        tester,
        width: 388,
        child: EventBuilderV2Inspector(
          event: _summary(
            title: longLabel,
            outcomeCount: 4,
            sceneLabel: longLabel,
          ),
          onOpenScene: () {},
        ),
      );

      expect(find.text(longLabel), findsWidgets);
      expect(find.textContaining('4 résultats'), findsOneWidget);
      expect(find.textContaining('sourceId'), findsNothing);
      expect(find.textContaining('layerId'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

bool _primaryFocusIsInside(Finder finder) {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  final target = finder.evaluate().single;
  if (focusContext == null) return false;
  if (identical(focusContext, target)) return true;
  var found = false;
  (focusContext as Element).visitAncestorElements((ancestor) {
    found = identical(ancestor, target);
    return !found;
  });
  return found;
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required double width,
  required Widget child,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 817));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(width: width, height: 817, child: child),
      ),
    ),
  );
  await tester.pump();
}

NarrativeEventProjectSummary _summary({
  String title = 'Rencontre rival au port',
  String sceneLabel = 'Rencontre avec le rival',
  int outcomeCount = 0,
  List<String>? outcomeLabels,
  int? priority,
  int? order,
  int activeCandidateCount = 0,
}) {
  final outcomes = outcomeLabels ??
      [
        for (var index = 0; index < outcomeCount; index++)
          switch (index) {
            0 => 'Victoire',
            1 => 'Défaite',
            2 => 'Échec',
            _ => 'Résultat ${index + 1}',
          },
      ];
  return NarrativeEventProjectSummary(
    stableKey: 'event:rival',
    eventId: 'evt_rival',
    title: title,
    origin: NarrativeEventProjectOrigin.v2,
    readOnly: false,
    enabled: true,
    group: NarrativeEventProjectGroupKind.map,
    groupKey: 'map:port',
    groupLabel: 'Port Selbrume',
    status: NarrativeEventProjectStatus.configuredEnabledReady,
    severity: NarrativeEventProjectSummarySeverity.info,
    source: NarrativeEventSourceSummary(
      source: NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_rival',
      ),
      humanSentence: 'Quand le joueur parle au Rival, au Port Selbrume.',
      sourceTypeLabel: 'Interaction avec un personnage ou un objet',
      mapId: 'map_port',
      mapLabel: 'Port Selbrume',
      available: true,
      debugTechnicalLabel: 'hidden',
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: 'scene_rival',
      humanLabel: sceneLabel,
      valid: true,
    ),
    conditions: NarrativeEventConditionsSummary(
      count: 2,
      valid: true,
      unresolvedCount: 0,
      humanLabel: '2 conditions, toutes doivent être remplies',
    ),
    lifecycle: NarrativeEventLifecycleSummary(
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      enabled: true,
      humanLabel: 'Une seule fois',
      priority: priority,
      order: order,
      activeCandidateCount: activeCandidateCount,
    ),
    migration: NarrativeEventMigrationSummary(humanLabel: 'Format V2'),
    projection: NarrativeEventProjectionSummary(
      outcomeLabels: outcomes,
      consequences: [
        NarrativeEventProjectedConsequenceSummary(
          kind: SceneConsequenceKind.setFact,
          humanLabel: 'Le rival a été rencontré.',
          debugReference: 'hidden',
        ),
      ],
      worldRules: [
        NarrativeEventProjectedWorldRuleSummary(
          ruleId: 'rule_port',
          humanLabel: 'Le gardien du port se déplace.',
          enabled: true,
        ),
      ],
      readOnly: true,
    ),
    compatibilityOrigins: const [],
    diagnostics: const [],
    debug: NarrativeEventProjectDebugFields(
      eventId: 'evt_rival',
      provenanceTechnicalLabels: const [],
      targetEventIds: const [],
    ),
  );
}
