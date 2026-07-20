import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  group('E3 configuration authoring', () {
    test('accepts exact conditions and preserves author order and duplicates',
        () {
      final record = draftRecord(source: entitySource);
      final registry = registryWithRecords([record]);
      final input = [
        NarrativeEventCondition.fact('fact_a', true),
        NarrativeEventCondition.narrativeEventConsumed(eventIdB, false),
        NarrativeEventCondition.fact('fact_a', false),
      ];
      final dependency = configuredRecord(id: eventIdB);
      final projectRegistry = registryWithRecords([record, dependency]);
      final result = setNarrativeEventConditions(
        context: configuredAuthoringContext(registry: projectRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: input,
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      final next = result.nextRecord!.draftOrNull!;
      expect(next.conditions, input);
      input.removeLast();
      expect(next.conditions, hasLength(3));
      expect(result.nextRegistry!.records[1], dependency);
      expect(registry.records.single, record);
    });

    test('rejects missing and ambiguous Facts', () {
      final record = draftRecord();
      final registry = registryWithRecords([record]);
      final missing = setNarrativeEventConditions(
        context:
            configuredAuthoringContext(registry: registry, facts: const []),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: [NarrativeEventCondition.fact('fact_a', true)],
      );
      final ambiguous = setNarrativeEventConditions(
        context: configuredAuthoringContext(
          registry: registry,
          facts: [factEntry(), factEntry()],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: [NarrativeEventCondition.fact('fact_a', false)],
      );

      expect(missing.rejectionCode, 'factMissing');
      expect(ambiguous.rejectionCode, 'factAmbiguous');
    });

    test('rejects missing draft invalid duplicate and self Event references',
        () {
      final candidate = draftRecord();
      final draftDependency = draftRecord(id: eventIdB);
      final invalidDependency = configuredRecord(id: eventIdC);
      final registry = registryWithRecords([
        candidate,
        draftDependency,
        invalidDependency,
      ]);
      NarrativeEventAuthoringResult apply(
        String target,
        NarrativeEventAuthoringContext context,
      ) {
        return setNarrativeEventConditions(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(target, true),
          ],
        );
      }

      expect(
        apply(eventIdD, configuredAuthoringContext(registry: registry))
            .rejectionCode,
        'eventReferenceMissing',
      );
      expect(
        apply(eventIdB, configuredAuthoringContext(registry: registry))
            .rejectionCode,
        'eventReferenceUnavailable',
      );
      expect(
        apply(
          eventIdC,
          configuredAuthoringContext(
            registry: registry,
            invalidEventIds: const {eventIdC},
          ),
        ).rejectionCode,
        'eventReferenceUnavailable',
      );
      final duplicateEntry = NarrativeEventProjectEventEntry(
        record: configuredRecord(id: eventIdC),
        proposed: false,
        inDependencyCycle: false,
        contextuallyValid: true,
      );
      expect(
        apply(
          eventIdC,
          configuredAuthoringContext(
            registry: registry,
            extraEvents: [duplicateEntry],
          ),
        ).rejectionCode,
        'staleCatalog',
      );
      expect(
        apply(eventIdA, configuredAuthoringContext(registry: registry))
            .rejectionCode,
        'selfReference',
      );
    });

    test('rejects projected two-node and three-node dependency cycles', () {
      final eventB = configuredRecord(
        id: eventIdB,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdA, true),
        ],
      );
      final twoRegistry = registryWithRecords([
        configuredRecord(id: eventIdA),
        eventB,
      ]);
      final two = setNarrativeEventConditions(
        context: configuredAuthoringContext(registry: twoRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdB, true),
        ],
      );

      final eventC = configuredRecord(
        id: eventIdC,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdA, true),
        ],
      );
      final threeRegistry = registryWithRecords([
        configuredRecord(id: eventIdA),
        configuredRecord(
          id: eventIdB,
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(eventIdC, true),
          ],
        ),
        eventC,
      ]);
      final three = setNarrativeEventConditions(
        context: configuredAuthoringContext(registry: threeRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdB, false),
        ],
      );

      expect(two.rejectionCode, 'eventDependencyCycle');
      expect(three.rejectionCode, 'eventDependencyCycle');
    });

    test('sets and removes a unique buildable Scene with structural unpublish',
        () {
      final draft = draftRecord(sceneId: null);
      final draftRegistry = registryWithRecords([draft]);
      final setResult = setNarrativeEventScene(
        context: configuredAuthoringContext(registry: draftRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        sceneId: 'scene_a',
      );
      expect(setResult.nextRecord!.draftOrNull!.sceneId, 'scene_a');

      final removedDraft = removeNarrativeEventScene(
        context: configuredAuthoringContext(
          registry: registryWithRecords([setResult.nextRecord!]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(removedDraft.nextRecord!.draftOrNull!.sceneId, isNull);

      final configured = configuredRecord();
      final configuredRegistry = registryWithRecords([configured]);
      final removedConfigured = removeNarrativeEventScene(
        context: configuredAuthoringContext(registry: configuredRegistry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(removedConfigured.nextRecord!.draftOrNull, isNotNull);
      expect(removedConfigured.nextRecord!.draftOrNull!.source, entitySource);
      expect(removedConfigured.nextRecord!.draftOrNull!.sceneId, isNull);
    });

    test('rejects missing duplicate unbuildable Scene and enabled edits', () {
      final draft = draftRecord();
      final registry = registryWithRecords([draft]);
      NarrativeEventAuthoringResult apply(
        List<NarrativeEventProjectSceneEntry> scenes,
      ) {
        return setNarrativeEventScene(
          context: configuredAuthoringContext(
            registry: registry,
            scenes: scenes,
          ),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          sceneId: 'scene_a',
        );
      }

      expect(apply(const []).rejectionCode, 'sceneMissing');
      expect(
          apply([sceneEntry(), sceneEntry()]).rejectionCode, 'sceneAmbiguous');
      expect(apply([sceneEntry(buildable: false)]).rejectionCode,
          'sceneUnavailable');

      final enabled = configuredRecord(enabled: true);
      final enabledContext = configuredAuthoringContext(
        registry: registryWithRecords([enabled]),
      );
      expect(
        setNarrativeEventScene(
          context: enabledContext,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          sceneId: 'scene_b',
        ).rejectionCode,
        'mustDisableFirst',
      );
      expect(
        removeNarrativeEventScene(
          context: enabledContext,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        ).rejectionCode,
        'mustDisableFirst',
      );
    });

    test('sets behavior priority order and metadata-only enabled name', () {
      final draft = draftRecord();
      var registry = registryWithRecords([draft]);
      final oneShot = setNarrativeEventReusePolicy(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
      );
      registry = oneShot.nextRegistry!;
      final reusable = setNarrativeEventReusePolicy(
        context: configuredAuthoringContext(
          registry: registry,
          revision: oneShot.conceptualNextRevision!,
        ),
        expectedRevision: oneShot.conceptualNextRevision!,
        eventId: eventIdA,
        reusePolicy: NarrativeEventReusePolicy.reusable,
      );
      expect(reusable.nextRecord!.draftOrNull!.reusePolicy,
          NarrativeEventReusePolicy.reusable);

      registry = registryWithRecords([configuredRecord(enabled: true)]);
      final renamed = renameNarrativeEvent(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        name: 'Nouveau nom',
      );
      expect(renamed.status, NarrativeEventAuthoringStatus.applied);
      expect(renamed.metadataOnly, isTrue);
      expect(renamed.nextRecord!.enabledOrNull, isTrue);

      for (final result in [
        setNarrativeEventReusePolicy(
          context: configuredAuthoringContext(registry: registry),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          reusePolicy: NarrativeEventReusePolicy.reusable,
        ),
        setNarrativeEventPriority(
          context: configuredAuthoringContext(registry: registry),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          priority: 4,
        ),
        setNarrativeEventOrder(
          context: configuredAuthoringContext(registry: registry),
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          order: 4,
        ),
      ]) {
        expect(result.rejectionCode, 'mustDisableFirst');
      }
    });

    test('reuse policy reports production runtime support without reset claims',
        () {
      final registry = registryWithRecords([draftRecord()]);
      final result = setNarrativeEventReusePolicy(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        reusePolicy: NarrativeEventReusePolicy.oneShot,
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        isNot(contains('runtimeSupportPending')),
      );
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.message),
        everyElement(isNot(contains('réinitialisation'))),
      );
    });

    test('validates names and exact JCS integer boundaries before mutation',
        () {
      final registry = registryWithRecords([draftRecord()]);
      final context = configuredAuthoringContext(registry: registry);
      expect(
        renameNarrativeEvent(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          name: '   ',
        ).rejectionCode,
        'emptyName',
      );
      expect(
        setNarrativeEventOrder(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          order: -1,
        ).rejectionCode,
        'invalidOrder',
      );
      expect(
        setNarrativeEventPriority(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          priority: 0x20000000000001,
        ).rejectionCode,
        'numericOverflow',
      );
      expect(
        setNarrativeEventOrder(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          order: 0x20000000000001,
        ).rejectionCode,
        'numericOverflow',
      );
    });

    test('blocks every configuration setter on a blocking catalog', () {
      final registry = registryWithRecords([draftRecord(sceneId: 'scene_a')]);
      final diagnostic = NarrativeEventProjectDiagnostic(
        code: 'projectReferenceInvalid',
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Référence invalide.',
        path: 'scenes.other',
      );
      final context = configuredAuthoringContext(
        registry: registry,
        diagnostics: [diagnostic],
      );
      final results = [
        renameNarrativeEvent(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          name: 'Renommé',
        ),
        setNarrativeEventConditions(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          conditions: [NarrativeEventCondition.fact('fact_a', true)],
        ),
        setNarrativeEventScene(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          sceneId: 'scene_a',
        ),
        removeNarrativeEventScene(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
        ),
        setNarrativeEventReusePolicy(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
        ),
        setNarrativeEventPriority(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          priority: 2,
        ),
        setNarrativeEventOrder(
          context: context,
          expectedRevision: authoringRevision,
          eventId: eventIdA,
          order: 2,
        ),
      ];

      for (final result in results) {
        expect(result.rejectionCode, 'catalogBlocked');
        expect(result.nextRegistry, isNull);
      }
    });

    test('revalidates unchanged conditions and Scene before returning no-op',
        () {
      final condition = NarrativeEventCondition.fact('gone', true);
      final conditionRecord = draftRecord(conditions: [condition]);
      final conditionResult = setNarrativeEventConditions(
        context: configuredAuthoringContext(
          registry: registryWithRecords([conditionRecord]),
          facts: const [],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: [condition],
      );
      expect(conditionResult.rejectionCode, 'factMissing');

      final sceneRecord = configuredRecord(sceneId: 'gone');
      final sceneResult = setNarrativeEventScene(
        context: configuredAuthoringContext(
          registry: registryWithRecords([sceneRecord]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        sceneId: 'gone',
      );
      expect(sceneResult.rejectionCode, 'sceneMissing');
    });

    test('allows exact condition and Scene repair while blocking other errors',
        () {
      final missingFact = NarrativeEventCondition.fact('gone', true);
      final conditionRecord = configuredRecord(conditions: [missingFact]);
      final conditionDiagnostic = NarrativeEventProjectDiagnostic(
        code: 'narrativeEventFactMissing',
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Fact manquant.',
        path: 'eventRegistry.records.$eventIdA.conditions.0.factId',
      );
      final repairedConditions = setNarrativeEventConditions(
        context: configuredAuthoringContext(
          registry: registryWithRecords([conditionRecord]),
          diagnostics: [conditionDiagnostic],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: const [],
      );
      expect(repairedConditions.status, NarrativeEventAuthoringStatus.applied);

      final sceneRecord = configuredRecord(sceneId: 'gone');
      final sceneDiagnostic = NarrativeEventProjectDiagnostic(
        code: 'narrativeEventSceneMissing',
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Scene manquante.',
        path: 'eventRegistry.records.$eventIdA.sceneId',
      );
      final repairedScene = removeNarrativeEventScene(
        context: configuredAuthoringContext(
          registry: registryWithRecords([sceneRecord]),
          diagnostics: [sceneDiagnostic],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(repairedScene.status, NarrativeEventAuthoringStatus.applied);
      expect(repairedScene.nextRecord!.draftOrNull!.sceneId, isNull);

      final unchangedResult = setNarrativeEventConditions(
        context: configuredAuthoringContext(
          registry: registryWithRecords([conditionRecord]),
          diagnostics: [conditionDiagnostic],
          facts: const [],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: [missingFact],
      );
      expect(unchangedResult.rejectionCode, 'factMissing');

      final unrelatedCode = NarrativeEventProjectDiagnostic(
        code: 'duplicateSceneId',
        severity: NarrativeEventProjectDiagnosticSeverity.error,
        message: 'Erreur étrangère.',
        path: 'eventRegistry.records.$eventIdA.sceneId',
      );
      final wrongCodeResult = removeNarrativeEventScene(
        context: configuredAuthoringContext(
          registry: registryWithRecords([sceneRecord]),
          diagnostics: [unrelatedCode],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
      );
      expect(wrongCodeResult.rejectionCode, 'catalogBlocked');
    });

    test('repairs a canonical transitive dependency cascade', () {
      final dependency = configuredRecord(id: eventIdB, sceneId: 'gone');
      final dependent = configuredRecord(
        id: eventIdA,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdB, true),
        ],
      );
      final registry = registryWithRecords([dependent, dependency]);
      final context = _canonicalAuthoringContext(registry);

      expect(
        context.catalog.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll([
          'narrativeEventSceneMissing',
          'narrativeEventReferenceUnavailable',
        ]),
      );
      final result = setNarrativeEventScene(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdB,
        sceneId: 'scene_a',
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord!.definitionOrNull!.sceneId, 'scene_a');
    });

    test('detaches a dependency while preserving its independent blocker', () {
      final dependency = configuredRecord(id: eventIdB, sceneId: 'gone');
      final dependent = configuredRecord(
        id: eventIdA,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdB, true),
        ],
      );
      final registry = registryWithRecords([dependent, dependency]);
      final context = _canonicalAuthoringContext(registry);
      final result = setNarrativeEventConditions(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: const [],
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord!.definitionOrNull!.conditions, isEmpty);
      expect(
        context.catalog.diagnostics.map((diagnostic) => diagnostic.code),
        contains('narrativeEventSceneMissing'),
      );
    });

    test('breaks a canonical dependency cycle', () {
      final eventA = configuredRecord(
        id: eventIdA,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdB, true),
        ],
      );
      final eventB = configuredRecord(
        id: eventIdB,
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(eventIdA, true),
        ],
      );
      final registry = registryWithRecords([eventA, eventB]);
      final context = _canonicalAuthoringContext(registry);

      expect(
        context.catalog.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code == 'narrativeEventDependencyCycle',
            )
            .length,
        2,
      );
      final result = setNarrativeEventConditions(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: const [],
      );

      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord!.definitionOrNull!.conditions, isEmpty);
    });

    test('repairs independent canonical cycles one at a time', () {
      NarrativeEventRecord cyclic(String id, String targetId) {
        return configuredRecord(
          id: id,
          conditions: [
            NarrativeEventCondition.narrativeEventConsumed(targetId, true),
          ],
        );
      }

      final registry = registryWithRecords([
        cyclic(eventIdA, eventIdB),
        cyclic(eventIdB, eventIdA),
        cyclic(eventIdC, eventIdD),
        cyclic(eventIdD, eventIdC),
      ]);
      final context = _canonicalAuthoringContext(registry);
      final result = setNarrativeEventConditions(
        context: context,
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        conditions: const [],
      );

      expect(
        context.catalog.diagnostics
            .where(
              (diagnostic) =>
                  diagnostic.code == 'narrativeEventDependencyCycle',
            )
            .length,
        4,
      );
      expect(result.status, NarrativeEventAuthoringStatus.applied);
      expect(result.nextRecord!.definitionOrNull!.conditions, isEmpty);
    });

    test('rejects a non-normalized Scene identity before construction', () {
      final registry = registryWithRecords([draftRecord()]);
      final result = setNarrativeEventScene(
        context: configuredAuthoringContext(
          registry: registry,
          scenes: [sceneEntry(id: ' scene_a ')],
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        sceneId: ' scene_a ',
      );

      expect(result.rejectionCode, 'invalidSceneId');
      expect(result.nextRegistry, isNull);
    });

    test('rejects non-canonical stored integers instead of returning no-op',
        () {
      final record = draftRecord(priority: 0x20000000000001);
      final result = setNarrativeEventPriority(
        context: configuredAuthoringContext(
          registry: registryWithRecords([record]),
        ),
        expectedRevision: authoringRevision,
        eventId: eventIdA,
        priority: 0x20000000000001,
      );

      expect(result.status, NarrativeEventAuthoringStatus.invalidRegistry);
      expect(result.nextRegistry, isNull);
    });

    test('detects a 10000 Event cycle without recursive traversal', () {
      String idAt(int index) =>
          'evt_019abcde-0000-7000-8000-${(index + 1).toRadixString(16).padLeft(12, '0')}';

      final records = <NarrativeEventRecord>[];
      for (var index = 0; index < 10000; index++) {
        final conditions = index == 0
            ? const <NarrativeEventCondition>[]
            : [
                NarrativeEventCondition.narrativeEventConsumed(
                  index == 9999 ? idAt(0) : idAt(index + 1),
                  true,
                ),
              ];
        records.add(configuredRecord(
          id: idAt(index),
          conditions: conditions,
          order: index,
        ));
      }
      final registry = registryWithRecords(records);
      final result = setNarrativeEventConditions(
        context: configuredAuthoringContext(registry: registry),
        expectedRevision: authoringRevision,
        eventId: idAt(0),
        conditions: [
          NarrativeEventCondition.narrativeEventConsumed(idAt(1), true),
        ],
      );

      expect(result.rejectionCode, 'eventDependencyCycle');
    });
  });
}

NarrativeEventAuthoringContext _canonicalAuthoringContext(
  NarrativeEventRegistry registry,
) {
  final project = ProjectManifest(
    name: 'Authoring project',
    maps: const [
      ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: const [],
    scenes: [sceneEntry().scene],
    facts: [factEntry().fact],
    eventRegistry: registry,
  );
  final map = MapData(
    id: 'map_a',
    name: 'Map A',
    size: const GridSize(width: 4, height: 4),
    entities: const [
      MapEntity(
        id: 'npc_a',
        name: 'NPC A',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
  final catalog = buildNarrativeEventProjectCatalog(
    project: project,
    maps: [map],
  );
  return NarrativeEventAuthoringContext(
    registryState: EventRegistryDecodeResult.decoded(registry),
    revision: authoringRevision,
    catalog: catalog,
    sourceIndex: buildNarrativeEventSourceIndex(registry.records),
    manifestHash: catalog.manifestHash,
    mapHashes: catalog.mapHashes,
  );
}
