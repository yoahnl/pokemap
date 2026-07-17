import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';

void main() {
  group('NS-EVENT-V2-26 project workspace', () {
    testWidgets('renders the project groups without an active-map filter',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1672);

      expect(find.text('Port Selbrume'), findsOneWidget);
      expect(find.text('Brouillons à terminer'), findsOneWidget);
      expect(find.text('Ancien format à convertir'), findsOneWidget);
      expect(find.text('Rencontre rival au port'), findsWidgets);
      expect(find.text('Coffre sans déclencheur'), findsOneWidget);
      expect(find.text('Messager existant'), findsOneWidget);
      expect(find.textContaining('sourceId'), findsNothing);
      expect(find.textContaining('layerId'), findsNothing);
    });

    testWidgets('uses the exact four business panel widths at 1672',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1672);

      expect(
        tester.getSize(find.byKey(const ValueKey('event-builder-v2-list'))),
        const Size(266, 817),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('event-builder-v2-library')),
        ),
        const Size(213, 817),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('event-builder-v2-editor'))),
        const Size(565, 817),
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('event-builder-v2-inspector')),
        ),
        const Size(388, 817),
      );

      final list = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-list')),
      );
      final library = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-library')),
      );
      final editor = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-editor')),
      );
      final inspector = tester.getTopLeft(
        find.byKey(const ValueKey('event-builder-v2-inspector')),
      );
      expect(library.dx - (list.dx + 266), 8);
      expect(editor.dx - (library.dx + 213), 8);
      expect(inspector.dx - (editor.dx + 565), 8);
    });

    testWidgets('search and human filter callbacks are functional',
        (tester) async {
      var state = NarrativeEventBuilderV2State(readModel: _readModel());
      late StateSetter rebuild;

      await tester.binding.setSurfaceSize(const Size(1456, 817));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return EventBuilderV2Workspace(
                  state: state,
                  mode: EventSystemMode.dualRead,
                  selectedStableKey: 'event:rival',
                  viewportWidth: 1672,
                  onQueryChanged: (value) {
                    rebuild(() => state = state.withQuery(value));
                  },
                  onFilterChanged: (value) {
                    rebuild(() => state = state.withFilter(value));
                  },
                  onSelectEvent: (_) {},
                  onCreateEvent: () {},
                  onOpenLibrary: () {},
                );
              },
            ),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('event-builder-v2-search')),
        'coffre',
      );
      await tester.pump();

      final list = find.byKey(const ValueKey('event-builder-v2-list'));
      expect(
        find.descendant(
          of: list,
          matching: find.text('Coffre sans déclencheur'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: list,
          matching: find.text('Rencontre rival au port'),
        ),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-filter-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ancien format à convertir'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: list, matching: find.text('Messager existant')),
        findsNothing,
      );
      expect(
        find.descendant(of: list, matching: find.text('Aucun résultat')),
        findsOneWidget,
      );
    });

    testWidgets('moves the library to an explicit side-sheet action at 1440',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1440, width: 1232);

      expect(
        find.byKey(const ValueKey('event-builder-v2-library')),
        findsNothing,
      );
      expect(find.text('Ouvrir la bibliothèque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('uses available width when the 1480 shell is constrained',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1480, width: 1264);

      expect(
        find.byKey(const ValueKey('event-builder-v2-library')),
        findsNothing,
      );
      expect(find.text('Ouvrir la bibliothèque'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows a state-preserving unsupported message below 1280',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1279, width: 1100);

      expect(find.text('Zone de travail trop étroite'), findsOneWidget);
      expect(
        find.textContaining('Votre sélection est conservée'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('event-builder-v2-list')),
        findsNothing,
      );
    });

    testWidgets('v2Only never exposes a legacy creation action',
        (tester) async {
      await _pumpWorkspace(
        tester,
        viewportWidth: 1672,
        mode: EventSystemMode.v2Only,
      );

      expect(find.text('Nouvel événement'), findsOneWidget);
      expect(find.textContaining('legacy'), findsNothing);
      expect(find.text('Ancien format à convertir'), findsOneWidget);
    });

    testWidgets('renders ordered condition details and numeric priority',
        (tester) async {
      await _pumpWorkspace(tester, viewportWidth: 1672);

      expect(find.text('Le port est ouvert = vrai'), findsNWidgets(2));
      expect(find.text('Écho dans la brume = non joué'), findsNWidgets(2));
      expect(find.text('7 (ordre 2)'), findsOneWidget);
      expect(find.text('2 événements actifs sur cet élément'), findsOneWidget);
      expect(find.textContaining('Réinitialisation'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('distinguishes an empty project from empty filters',
        (tester) async {
      await _pumpWorkspace(
        tester,
        viewportWidth: 1672,
        readModel: NarrativeEventBuilderProjectReadModel(
          groups: const [],
          diagnostics: const [],
        ),
      );

      expect(find.text('Aucun événement dans ce projet'), findsOneWidget);
      expect(find.text('Nouvel événement'), findsOneWidget);
    });
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required double viewportWidth,
  double width = 1456,
  EventSystemMode mode = EventSystemMode.dualRead,
  NarrativeEventBuilderProjectReadModel? readModel,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 817));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final state = NarrativeEventBuilderV2State(
    readModel: readModel ?? _readModel(),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: 817,
          child: EventBuilderV2Workspace(
            state: state,
            mode: mode,
            selectedStableKey: 'event:rival',
            viewportWidth: viewportWidth,
            onQueryChanged: (_) {},
            onFilterChanged: (_) {},
            onSelectEvent: (_) {},
            onCreateEvent: () {},
            onOpenLibrary: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

NarrativeEventBuilderProjectReadModel _readModel() {
  return NarrativeEventBuilderProjectReadModel(
    groups: [
      NarrativeEventProjectGroup(
        stableKey: 'group:map:port',
        label: 'Port Selbrume',
        kind: NarrativeEventProjectGroupKind.map,
        events: [
          _summary(
            stableKey: 'event:rival',
            eventId: 'evt_rival',
            title: 'Rencontre rival au port',
            group: NarrativeEventProjectGroupKind.map,
            groupKey: 'map:port',
            groupLabel: 'Port Selbrume',
            status: NarrativeEventProjectStatus.configuredEnabledReady,
            enabled: true,
            sentence: 'Quand le joueur parle au Rival, au Port Selbrume.',
            conditions: NarrativeEventConditionsSummary(
              count: 2,
              valid: true,
              unresolvedCount: 0,
              humanLabel: '2 conditions',
              details: [
                NarrativeEventConditionDetailSummary(
                  kind: NarrativeEventConditionDetailKind.fact,
                  targetLabel: 'Le port est ouvert',
                  expectedValue: true,
                  resolved: true,
                  humanLabel: 'Le port est ouvert = vrai',
                ),
                NarrativeEventConditionDetailSummary(
                  kind:
                      NarrativeEventConditionDetailKind.narrativeEventConsumed,
                  targetLabel: 'Écho dans la brume',
                  expectedValue: false,
                  resolved: true,
                  humanLabel: 'Écho dans la brume = non joué',
                ),
              ],
            ),
            lifecycle: NarrativeEventLifecycleSummary(
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              enabled: true,
              humanLabel: 'Une seule fois',
              priority: 7,
              order: 2,
              activeCandidateCount: 2,
            ),
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:drafts',
        label: 'Brouillons à terminer',
        kind: NarrativeEventProjectGroupKind.drafts,
        events: [
          _summary(
            stableKey: 'event:chest',
            eventId: 'evt_chest',
            title: 'Coffre sans déclencheur',
            group: NarrativeEventProjectGroupKind.drafts,
            groupKey: 'drafts',
            groupLabel: 'Brouillons à terminer',
            status: NarrativeEventProjectStatus.draftIncomplete,
            enabled: null,
            sentence: 'Aucun élément déclencheur choisi.',
          ),
        ],
      ),
      NarrativeEventProjectGroup(
        stableKey: 'group:legacy',
        label: 'Ancien format à convertir',
        kind: NarrativeEventProjectGroupKind.legacyCompatibility,
        events: [
          _summary(
            stableKey: 'legacy:messenger',
            eventId: null,
            title: 'Messager existant',
            group: NarrativeEventProjectGroupKind.legacyCompatibility,
            groupKey: 'legacy',
            groupLabel: 'Ancien format à convertir',
            status: NarrativeEventProjectStatus.legacyOnly,
            enabled: null,
            sentence: 'Déclencheur existant, lecture seule.',
            origin: NarrativeEventProjectOrigin.legacyMapEvent,
            readOnly: true,
          ),
        ],
      ),
    ],
    diagnostics: const [],
  );
}

NarrativeEventProjectSummary _summary({
  required String stableKey,
  required String? eventId,
  required String title,
  required NarrativeEventProjectGroupKind group,
  required String groupKey,
  required String groupLabel,
  required NarrativeEventProjectStatus status,
  required bool? enabled,
  required String sentence,
  NarrativeEventProjectOrigin origin = NarrativeEventProjectOrigin.v2,
  bool readOnly = false,
  NarrativeEventConditionsSummary? conditions,
  NarrativeEventLifecycleSummary? lifecycle,
}) {
  return NarrativeEventProjectSummary(
    stableKey: stableKey,
    eventId: eventId,
    title: title,
    origin: origin,
    readOnly: readOnly,
    enabled: enabled,
    group: group,
    groupKey: groupKey,
    groupLabel: groupLabel,
    status: status,
    severity: NarrativeEventProjectSummarySeverity.info,
    source: NarrativeEventSourceSummary(
      source: null,
      humanSentence: sentence,
      sourceTypeLabel: 'Élément déclencheur',
      available: true,
      debugTechnicalLabel: 'hidden',
    ),
    scene: NarrativeEventSceneSummary(
      sceneId: 'scene_rival',
      humanLabel: 'Rencontre rival',
      valid: true,
    ),
    conditions: conditions ??
        NarrativeEventConditionsSummary(
          count: 0,
          valid: true,
          unresolvedCount: 0,
          humanLabel: 'Aucune condition',
        ),
    lifecycle: lifecycle ??
        NarrativeEventLifecycleSummary(
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          enabled: enabled,
          humanLabel: enabled == true ? 'Actif' : 'Brouillon',
        ),
    migration: NarrativeEventMigrationSummary(
      humanLabel: readOnly ? 'Ancien format à convertir' : 'Format V2',
    ),
    projection: NarrativeEventProjectionSummary(
      outcomeLabels: const [],
      consequences: const [],
      worldRules: const [],
      readOnly: true,
    ),
    compatibilityOrigins: const [],
    diagnostics: const [],
    debug: NarrativeEventProjectDebugFields(
      eventId: eventId,
      provenanceTechnicalLabels: const [],
      targetEventIds: const [],
    ),
  );
}
