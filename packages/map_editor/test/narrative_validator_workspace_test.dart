import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_validator_workspace.dart';

void main() {
  testWidgets('shows one playability verdict and filters diagnostics',
      (tester) async {
    await _pump(tester, report: _report());

    expect(find.byKey(narrativeValidatorWorkspaceKey), findsOneWidget);
    expect(find.text('Non jouable'), findsWidgets);
    expect(find.text('2 erreurs'), findsWidgets);
    expect(find.text('1 avertissement'), findsWidgets);
    expect(find.text('Étape impossible'), findsOneWidget);
    expect(find.text('Timeline non bloquante'), findsOneWidget);

    await tester.tap(find.byKey(narrativeValidatorErrorsFilterKey));
    await tester.pumpAndSettle();

    expect(find.text('Étape impossible'), findsOneWidget);
    expect(find.text('Timeline non bloquante'), findsNothing);
  });

  testWidgets('opens the exact diagnostic source without offering fake fixes',
      (tester) async {
    NarrativeProjectDiagnostic? opened;
    await _pump(
      tester,
      report: _report(),
      onOpenDiagnostic: (diagnostic) => opened = diagnostic,
    );

    await tester.tap(find.text('Ouvrir la source').first);
    await tester.pump();

    expect(opened?.stepId, 'step_blocked');
    expect(find.text('Réparer automatiquement'), findsNothing);
  });

  testWidgets('filters diagnostics by their owning map', (tester) async {
    await _pump(tester, report: _report());

    final mapDropdown = find.descendant(
      of: find.byKey(narrativeValidatorMapFilterKey),
      matching: find.byType(DropdownButton<String>),
    );
    await tester.tap(mapDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Port des Brisants').last);
    await tester.pumpAndSettle();

    expect(find.text('Source PNJ absente de la map.'), findsOneWidget);
    expect(find.text('Étape impossible'), findsNothing);
    expect(find.text('Timeline non bloquante'), findsNothing);
  });

  testWidgets('filters diagnostics by product domain', (tester) async {
    await _pump(tester, report: _report());

    final domainDropdown = find.descendant(
      of: find.byKey(narrativeValidatorDomainFilterKey),
      matching: find.byType(DropdownButton<String>),
    );
    await tester.tap(domainDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cinématiques').last);
    await tester.pumpAndSettle();

    expect(find.text('Timeline non bloquante'), findsOneWidget);
    expect(find.text('Étape impossible'), findsNothing);
    expect(find.text('Source PNJ absente de la map.'), findsNothing);
  });

  testWidgets('consolidates map sources, conditions, Scenes and diagnostics',
      (tester) async {
    String? openedEvent;
    String? openedMap;
    await _pump(
      tester,
      report: _report(),
      onOpenEvent: (eventId) => openedEvent = eventId,
      onOpenMap: (mapId) => openedMap = mapId,
    );

    await tester.tap(find.byKey(narrativeValidatorMapEventsTabKey));
    await tester.pumpAndSettle();

    expect(find.text('Port des Brisants'), findsWidgets);
    expect(find.text('Rencontre au port'), findsOneWidget);
    expect(find.text('PNJ · Rival au port'), findsOneWidget);
    expect(find.text('2 conditions'), findsOneWidget);
    expect(find.text('Source orpheline'), findsOneWidget);
    expect(find.text('Scene · Rencontre rival'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('narrative-validator-open-event-evt_test')),
    );
    await tester.pump();
    expect(openedEvent, 'evt_test');

    await tester.tap(
      find.byKey(const ValueKey('narrative-validator-open-map-map_port')),
    );
    await tester.pump();
    expect(openedMap, 'map_port');
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required NarrativeProjectValidationReport report,
  ValueChanged<NarrativeProjectDiagnostic>? onOpenDiagnostic,
  ValueChanged<String>? onOpenEvent,
  ValueChanged<String>? onOpenMap,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeValidatorWorkspace(
          report: report,
          onOpenDiagnostic: onOpenDiagnostic,
          onOpenEvent: onOpenEvent,
          onOpenMap: onOpenMap,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

NarrativeProjectValidationReport _report() {
  const blocked = NarrativeProjectDiagnostic(
    code: 'storylineStepNeverCompleted',
    severity: NarrativeProjectDiagnosticSeverity.error,
    domain: NarrativeProjectDiagnosticDomain.storyline,
    message: 'Étape impossible',
    path: 'storylines.main.chapter.step_blocked',
    destination: NarrativeProjectDiagnosticDestination.storyline,
    suggestedFixLabel: 'Ajouter une conséquence.',
    storylineId: 'story_main',
    chapterId: 'chapter_main',
    stepId: 'step_blocked',
  );
  const orphan = NarrativeProjectDiagnostic(
    code: 'narrativeEventSourceMissing',
    severity: NarrativeProjectDiagnosticSeverity.error,
    domain: NarrativeProjectDiagnosticDomain.event,
    message: 'Source PNJ absente de la map.',
    path: 'eventRegistry.records.evt_test.source',
    destination: NarrativeProjectDiagnosticDestination.map,
    mapId: 'map_port',
    eventId: 'evt_test',
  );
  const cinematic = NarrativeProjectDiagnostic(
    code: 'cinematicTechnicalLabel',
    severity: NarrativeProjectDiagnosticSeverity.warning,
    domain: NarrativeProjectDiagnosticDomain.cinematic,
    message: 'Timeline non bloquante',
    path: 'cinematics.intro',
    destination: NarrativeProjectDiagnosticDestination.cinematic,
    cinematicId: 'cinematic_intro',
  );
  return NarrativeProjectValidationReport(
    diagnostics: const [blocked, orphan, cinematic],
    mapEventViews: [
      NarrativeMapEventsView(
        groupKind: NarrativeMapEventsGroupKind.map,
        mapId: 'map_port',
        label: 'Port des Brisants',
        events: const [
          NarrativeMapEventEntry(
            eventId: 'evt_test',
            label: 'Rencontre au port',
            enabled: true,
            sourceKind: NarrativeEventSourceKind.entityInteract,
            mapId: 'map_port',
            sourceOwnerId: 'npc_missing',
            sourceOwnerLabel: 'Rival au port',
            sourceEntityKind: MapEntityKind.npc,
            sourceConnected: false,
            sceneId: 'scene_port',
            sceneLabel: 'Rencontre rival',
            sceneConnected: true,
            conditionCount: 2,
            diagnosticCount: 1,
          ),
        ],
      ),
    ],
  );
}
