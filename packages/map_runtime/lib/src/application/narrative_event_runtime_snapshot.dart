import 'package:map_core/map_core.dart';

/// Immutable Event V2 runtime view built from one project/map corpus.
///
/// The runtime deliberately refuses to combine maps loaded from a different
/// manifest revision. That keeps the registry, catalog and legacy-claim
/// evidence on the same authority snapshot.
final class NarrativeEventRuntimeSnapshot {
  const NarrativeEventRuntimeSnapshot._({
    required this.project,
    required this.mapsById,
    required this.registryResult,
    required this.factResolver,
    required this.projectCatalog,
    required this.legacyClaimIndex,
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final EventRegistryDecodeResult registryResult;
  final NarrativeFactRuntimeResolver factResolver;
  final NarrativeEventProjectCatalog projectCatalog;
  final ValidatedLegacyClaimIndex legacyClaimIndex;

  static Future<NarrativeEventRuntimeSnapshot> build({
    required ProjectManifest project,
    required Future<({ProjectManifest project, MapData map})> Function(
      String mapId,
    ) loadMap,
  }) async {
    final registry = project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final structuralClaimIndex = buildValidatedLegacyClaimIndex(registry);
    final registryResult = project.eventRegistry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry);
    final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
    if (registry.mode == EventSystemMode.legacyOnly) {
      return NarrativeEventRuntimeSnapshot._(
        project: project,
        mapsById: const <String, MapData>{},
        registryResult: registryResult,
        factResolver: factResolver,
        projectCatalog: buildNarrativeEventProjectCatalog(
          project: project,
          maps: const <MapData>[],
        ),
        legacyClaimIndex: structuralClaimIndex,
      );
    }
    final projectFingerprint = canonicalizeNarrativeEventJson(project.toJson());
    final mapsById = <String, MapData>{};

    for (final mapEntry in project.maps) {
      if (mapsById.containsKey(mapEntry.id)) {
        throw StateError(
          'Event V2 runtime snapshot contains duplicate map id '
          '"${mapEntry.id}".',
        );
      }
      final loaded = await loadMap(mapEntry.id);
      if (canonicalizeNarrativeEventJson(loaded.project.toJson()) !=
          projectFingerprint) {
        throw StateError(
          'Event V2 runtime snapshot changed while loading map '
          '"${mapEntry.id}".',
        );
      }
      if (loaded.map.id != mapEntry.id) {
        throw StateError(
          'Event V2 runtime snapshot expected map "${mapEntry.id}" but '
          'loaded "${loaded.map.id}".',
        );
      }
      mapsById[mapEntry.id] = loaded.map;
    }

    final legacyMapProjections = <LegacyMapEventProjection>[
      for (final map in mapsById.values)
        for (final event in map.events)
          projectLegacyMapEventReadOnly(
            mapId: map.id,
            map: map,
            event: event,
            claimIndex: structuralClaimIndex,
            rawEventJson: Map<String, Object?>.from(event.toJson()),
          ),
    ];
    final legacyScenarioProjections = <LegacyScenarioSourceProjection>[
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes)
          if (isLegacyScenarioSourceNode(node))
            projectLegacyScenarioSourceReadOnly(
              scenario: scenario,
              node: node,
              scenes: project.scenes,
              claimIndex: structuralClaimIndex,
            ),
    ];
    final runtimeEvidence = LegacyClaimRuntimeEvidence(
      entries: [
        for (final projection in legacyMapProjections)
          if (projection.confirmedSource != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.confirmedSource!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
        for (final projection in legacyScenarioProjections)
          if (projection.source != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.source!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
      ],
    );
    final referencedOutcomes = <NarrativeOutcomeRef>[
      for (final projection in legacyScenarioProjections)
        if (projection.source != null)
          ...projection.source!.when(
            entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
            triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
            mapEnter: (_) => const <NarrativeOutcomeRef>[],
            outcomeReceived: (outcome) => <NarrativeOutcomeRef>[outcome],
          ),
    ];
    final projectCatalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: mapsById.values.toList(growable: false),
      legacyProjections: legacyMapProjections,
      referencedOutcomes: referencedOutcomes,
    );

    return NarrativeEventRuntimeSnapshot._(
      project: project,
      mapsById: Map<String, MapData>.unmodifiable(mapsById),
      registryResult: registryResult,
      factResolver: factResolver,
      projectCatalog: projectCatalog,
      legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: runtimeEvidence,
      ),
    );
  }
}
