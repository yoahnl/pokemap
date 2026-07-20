import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_diagnostic_suppression_service.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/narrative_validator_workspace.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

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

  testWidgets(
      'materializes and focuses an offscreen restored diagnostic before acknowledging it',
      (tester) async {
    final diagnostics = List<NarrativeProjectDiagnostic>.generate(
      40,
      (index) => NarrativeProjectDiagnostic(
        code: 'diagnostic$index',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.scene,
        message: 'Diagnostic $index',
        path: 'scenes.scene_$index',
        destination: NarrativeProjectDiagnosticDestination.scene,
        sceneId: 'scene_$index',
      ),
    );
    final report = NarrativeProjectValidationReport(
      diagnostics: diagnostics,
      mapEventViews: const [],
    );
    final target = diagnostics.last;
    int? appliedRevision;

    await _pump(
      tester,
      report: report,
      requestedDiagnosticKey: target.stableKey,
      requestedDiagnosticNonce: 7,
      requestedRestorationRevision: 42,
      onRestorationApplied: (revision) => appliedRevision = revision,
    );

    final restored = find.byKey(
      ValueKey('narrative-validator-diagnostic-${target.stableKey}'),
    );
    expect(restored, findsOneWidget);
    expect(tester.widget<Focus>(restored).focusNode?.hasFocus, isTrue);
    expect(appliedRevision, 42);
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

  testWidgets('shows four honest verdicts with evidence and limitations',
      (tester) async {
    await _pump(
      tester,
      report: _report(),
      multidimensionalReport: _multidimensionalReport(),
    );

    expect(find.text('Preuve de jouabilité · 4 dimensions'), findsOneWidget);
    expect(find.text('Structure'), findsWidgets);
    expect(find.text('Solvabilité'), findsOneWidget);
    expect(find.text('Atteignabilité'), findsOneWidget);
    expect(find.text('Smoke runtime'), findsWidgets);
    expect(find.text('Indéterminé'), findsNWidgets(2));
    expect(find.textContaining('Limite · Budget symbolique'), findsOneWidget);
    expect(find.textContaining('suite:journey'), findsOneWidget);

    await _selectDropdown(
      tester,
      narrativeValidatorDimensionFilterKey,
      'Atteignabilité physique',
    );
    expect(find.textContaining('Budget physique dépassé.'), findsOneWidget);
    expect(find.text('Étape impossible'), findsNothing);
  });

  testWidgets(
      'filters by status, storyline and asset while keeping stale suppressions visible',
      (tester) async {
    const service = NarrativeDiagnosticSuppressionService();
    final report = _report();
    final suppressedDiagnostic = report.diagnostics.last;
    final staleDiagnostic = report.diagnostics.first;
    final project = ProjectManifest(
      name: 'Validator filters',
      maps: const [],
      tilesets: const [],
      narrativeDiagnosticSuppressions: [
        NarrativeDiagnosticSuppression(
          diagnosticId: suppressedDiagnostic.stableKey,
          diagnosticFingerprint: service.fingerprint(suppressedDiagnostic),
          reason: 'Accepté pour la démo.',
          author: 'Karim',
          createdAt: DateTime.utc(2026, 7, 20),
        ),
        NarrativeDiagnosticSuppression(
          diagnosticId: staleDiagnostic.stableKey,
          diagnosticFingerprint: 'sha256:${'1' * 64}',
          reason: 'Ancienne décision.',
          author: 'Karim',
          createdAt: DateTime.utc(2026, 7, 20),
        ),
      ],
    );
    final snapshot = service.buildSnapshot(
      project: project,
      diagnostics: report.diagnostics,
      now: DateTime.utc(2026, 7, 20, 12),
    );
    String? removedSuppression;
    await _pump(
      tester,
      report: report,
      suppressionSnapshot: snapshot,
      onRemoveSuppression: (id) => removedSuppression = id,
    );

    expect(find.text('Timeline non bloquante'), findsNothing);
    expect(find.text('Masquage obsolète'), findsOneWidget);

    await _selectDropdown(
      tester,
      narrativeValidatorStatusFilterKey,
      'Masqués',
    );
    expect(find.text('Timeline non bloquante'), findsOneWidget);
    expect(find.text('Étape impossible'), findsNothing);
    await tester.tap(find.text('Réactiver le diagnostic'));
    await tester.pump();
    expect(removedSuppression, suppressedDiagnostic.stableKey);

    await _selectDropdown(
      tester,
      narrativeValidatorStatusFilterKey,
      'Actifs',
    );
    await tester.enterText(
      find.byKey(narrativeValidatorAssetFilterKey),
      'step_blocked',
    );
    await tester.pumpAndSettle();
    expect(find.text('Étape impossible'), findsOneWidget);
    expect(find.text('Source PNJ absente de la map.'), findsNothing);
  });

  testWidgets('offers governed suppression only for non-blocking diagnostics',
      (tester) async {
    NarrativeProjectDiagnostic? requested;
    await _pump(
      tester,
      report: _report(),
      onSuppressDiagnostic: (diagnostic) => requested = diagnostic,
    );

    final warning = _report().diagnostics.last;
    final button = find.byKey(
      ValueKey('narrative-validator-suppress-${warning.stableKey}'),
    );
    expect(button, findsOneWidget);
    tester.widget<PokeMapButton>(button).onPressed!();
    await tester.pump();

    expect(requested?.severity, NarrativeProjectDiagnosticSeverity.warning);
    expect(requested?.code, 'cinematicTechnicalLabel');
  });
}

Future<void> _selectDropdown(
  WidgetTester tester,
  Key key,
  String label,
) async {
  final dropdown = find.descendant(
    of: find.byKey(key),
    matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
  );
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _pump(
  WidgetTester tester, {
  required NarrativeProjectValidationReport report,
  ValueChanged<NarrativeProjectDiagnostic>? onOpenDiagnostic,
  ValueChanged<String>? onOpenEvent,
  ValueChanged<String>? onOpenMap,
  String? requestedDiagnosticKey,
  int? requestedDiagnosticNonce,
  int? requestedRestorationRevision,
  ValueChanged<int>? onRestorationApplied,
  NarrativeMultidimensionalValidationReport? multidimensionalReport,
  NarrativeDiagnosticSuppressionSnapshot? suppressionSnapshot,
  ValueChanged<NarrativeProjectDiagnostic>? onSuppressDiagnostic,
  ValueChanged<String>? onRemoveSuppression,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: NarrativeValidatorWorkspace(
          report: mergeNarrativePublicationDiagnostics(
            authoringReport: report,
            publicationReport: multidimensionalReport,
          ),
          onOpenDiagnostic: onOpenDiagnostic,
          onOpenEvent: onOpenEvent,
          onOpenMap: onOpenMap,
          requestedDiagnosticKey: requestedDiagnosticKey,
          requestedDiagnosticNonce: requestedDiagnosticNonce,
          requestedRestorationRevision: requestedRestorationRevision,
          onRestorationApplied: onRestorationApplied,
          multidimensionalReport: multidimensionalReport,
          suppressionSnapshot: suppressionSnapshot,
          onSuppressDiagnostic: onSuppressDiagnostic,
          onRemoveSuppression: onRemoveSuppression,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

NarrativeMultidimensionalValidationReport _multidimensionalReport() {
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'narrative-validator-v1',
    profileId: 'selbrume-release-v1',
    profileVersion: 1,
    projectFingerprint: 'sha256:${'a' * 64}',
    generatedAt: DateTime.utc(2026, 7, 20),
    structurallyValid: NarrativeValidationDimensionResult(
      status: NarrativeValidationStatus.pass,
    ),
    narrativelySolvable: NarrativeValidationDimensionResult(
      status: NarrativeValidationStatus.indeterminate,
      limitations: const ['Budget symbolique atteint.'],
    ),
    physicallyReachable: NarrativeValidationDimensionResult(
      status: NarrativeValidationStatus.indeterminate,
      evidenceRefs: const ['event:evt_test@map_port:4,5'],
      limitations: const ['Budget physique atteint.'],
      diagnostics: [
        NarrativeMultidimensionalDiagnostic(
          id: 'physical:budget',
          code: 'explorationBudgetExceeded',
          severity: 'warning',
          message: 'Budget physique dépassé.',
          path: 'maps.map_port',
          provenance: const ['spawn:start', 'event:evt_test'],
        ),
      ],
    ),
    runtimeSmokeVerified: NarrativeValidationDimensionResult(
      status: NarrativeValidationStatus.pass,
      evidenceRefs: const ['suite:journey'],
    ),
  );
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
