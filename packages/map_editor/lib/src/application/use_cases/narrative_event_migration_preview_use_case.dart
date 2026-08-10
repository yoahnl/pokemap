import 'package:map_core/map_core.dart';

import '../models/narrative_event_authoring_session.dart';
import '../models/narrative_event_migration_persistence_models.dart';

/// Builds an attested migration plan without writing project bytes.
///
/// Auto-safe single-page legacy map Events can be proposed here, but the plan
/// deliberately preserves the current runtime mode. Activation remains a
/// separate, explicit product action after review and persistence.
final class NarrativeEventMigrationPreviewUseCase {
  NarrativeEventMigrationPreviewUseCase({
    NarrativeEventMigrationIdSource? ids,
    NarrativeEventMigrationClock? clock,
  })  : _ids = ids ?? _EditorMigrationIds(),
        _clock = clock ?? DateTime.now;

  final NarrativeEventMigrationIdSource _ids;
  final NarrativeEventMigrationClock _clock;

  Future<NarrativeEventMigrationPreview> preview(
    String projectPath, {
    NarrativeEventMigrationSnapshot? expectedSnapshot,
    List<int>? existingReceiptJsonBytes,
  }) async {
    final session = await NarrativeEventAuthoringSession.prepare(projectPath);
    final project = session.manifest;
    final registry = project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final claimIndex = buildValidatedLegacyClaimIndex(registry);
    final mapProjections = <LegacyMapEventProjection>[];
    final sourceChoices = <NarrativeEventMigrationSourceChoice>[];
    for (final map in session.maps) {
      for (final event in map.events) {
        final projection = projectLegacyMapEventReadOnly(
          mapId: map.id,
          map: map,
          event: event,
          claimIndex: claimIndex,
          rawEventJson: Map<String, Object?>.from(event.toJson()),
        );
        mapProjections.add(projection);
        final source = projection.confirmedSource;
        if (projection.classification ==
                LegacyMigrationClassification.autoSafe &&
            source != null &&
            projection.pages.length == 1 &&
            projection.pages.single.sceneId != null) {
          sourceChoices.add(
            NarrativeEventMigrationSourceChoice.confirmCandidate(
              provenance: projection.provenance,
              source: source,
              targets: [
                NarrativeEventMigrationTargetProposal(
                  name: event.title.trim().isEmpty ? event.id : event.title,
                  legacyPageIndex: projection.pages.single.pageIndex,
                  conditions: const [],
                  sceneId: projection.pages.single.sceneId,
                  reusePolicy: NarrativeEventReusePolicy.reusable,
                  priority: 0,
                  order: projection.pages.single.pageIndex,
                ),
              ],
            ),
          );
        }
      }
    }
    final scenarioProjections = <LegacyScenarioSourceProjection>[
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes)
          if (isLegacyScenarioSourceNode(node))
            projectLegacyScenarioSourceReadOnly(
              scenario: scenario,
              node: node,
              scenes: project.scenes,
              claimIndex: claimIndex,
            ),
    ];
    final referencedOutcomes = <NarrativeOutcomeRef>[
      for (final projection in scenarioProjections)
        if (projection.source != null)
          ...projection.source!.when(
            entityInteract: (_, _) => const <NarrativeOutcomeRef>[],
            triggerEnter: (_, _) => const <NarrativeOutcomeRef>[],
            mapEnter: (_) => const <NarrativeOutcomeRef>[],
            outcomeReceived: (outcome) => [outcome],
          ),
    ];
    final catalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: session.maps,
      legacyProjections: mapProjections,
      referencedOutcomes: referencedOutcomes,
    );
    final references = NarrativeEventReferenceCatalog.empty();
    final characterizedCorpus = <String, Object?>{
      'version': 'NS-EVENT-V2-I4-v0',
    };
    final snapshot = NarrativeEventMigrationSnapshot(
      projectRevisionToken: session.projectRevision,
      manifestHash: catalog.manifestHash,
      corpusHash: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(characterizedCorpus),
      ),
      referenceCatalogHash: narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(references.toJson()),
      ),
      mapHashes: catalog.mapHashes,
      legacySourceHashes: {
        for (final projection in mapProjections)
          legacyMigrationSourceSnapshotKey(projection.provenance):
              projection.sourceFingerprint,
        for (final projection in scenarioProjections)
          legacyMigrationSourceSnapshotKey(projection.provenance):
              projection.sourceFingerprint,
      },
      saveHashes: const {},
    );
    final planner = NarrativeEventMigrationPlanner(
      ids: _ids,
      clock: _clock,
    );
    final input = NarrativeEventMigrationPlannerInput(
      project: project,
      maps: session.maps,
      mapEventProjections: mapProjections,
      scenarioProjections: scenarioProjections,
      references: references,
      currentSnapshot: snapshot,
      expectedSnapshot: expectedSnapshot,
      choices: NarrativeEventMigrationChoices(
        sourceChoices: sourceChoices,
      ),
      characterizedCorpus: characterizedCorpus,
      saveSnapshots: const [],
      unknownLegacyData: const [],
      backupPlan: NarrativeEventMigrationBackupPlan(
        futureDestinations: const {
          'manifest': '.pokemap/event-migration/project.before.json',
          'receipt': '.pokemap/event-migration/receipt.json',
        },
      ),
      existingReceiptJsonBytes: existingReceiptJsonBytes,
      validationCatalog: catalog,
    );
    final plan = planner.plan(input);
    return NarrativeEventMigrationPreview(
      projectPath: session.projectPath,
      projectRevision: session.projectRevision,
      project: project,
      plan: plan,
      impact: NarrativeEventMigrationPlanner.previewImpact(
        input: input,
        plan: plan,
      ),
    );
  }
}

final class _EditorMigrationIds implements NarrativeEventMigrationIdSource {
  final NarrativeEventIdGenerator _generator = NarrativeEventIdGenerator();

  @override
  String nextEventId() => _generator.generate(existingRecords: const []);

  @override
  String nextReceiptId() {
    final eventId = _generator.generate(existingRecords: const []);
    return 'evmr_${eventId.substring(4)}';
  }
}
