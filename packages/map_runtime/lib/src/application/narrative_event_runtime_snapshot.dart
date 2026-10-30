import 'dart:isolate';

import 'package:map_core/map_core.dart';

import 'runtime_project_catalog.dart';

/// Immutable Event V2 runtime view built from one project/map corpus.
///
/// The runtime deliberately refuses to combine maps loaded from a different
/// manifest revision. That keeps the registry, catalog and legacy-claim
/// evidence on the same authority snapshot.
final class NarrativeEventRuntimeSnapshot {
  NarrativeEventRuntimeSnapshot._({
    required this.project,
    required this.presentationMediaCatalog,
    required this.mapsById,
    required this.registryResult,
    required this.factResolver,
    required this.projectCatalog,
    required this.legacyClaimIndex,
    required Set<ProjectManifest> validatedProjects,
  }) : _validatedProjects = validatedProjects,
       _owner = RuntimeProjectCatalog.ownerOf(project);

  final ProjectManifest project;
  final ProjectMediaCatalog? presentationMediaCatalog;
  final Map<String, NarrativeMapView> mapsById;
  final EventRegistryDecodeResult registryResult;
  final NarrativeFactRuntimeResolver factResolver;
  final NarrativeEventProjectCatalog projectCatalog;
  final ValidatedLegacyClaimIndex legacyClaimIndex;
  final Set<ProjectManifest> _validatedProjects;
  final RuntimeProjectCatalog? _owner;

  bool matchesProject(ProjectManifest candidate) => _owner != null
      ? identical(RuntimeProjectCatalog.ownerOf(project), _owner) &&
            identical(RuntimeProjectCatalog.ownerOf(candidate), _owner)
      : RuntimeProjectCatalog.ownerOf(candidate) == null &&
            (_validatedProjects.contains(candidate) || project == candidate);

  static Future<NarrativeEventRuntimeSnapshot> build({
    required ProjectManifest project,
    ProjectMediaCatalog? presentationMediaCatalog,
    Future<ProjectMediaCatalog?> Function()? loadPresentationMediaCatalog,
    required Future<({ProjectManifest project, MapData map})> Function(
      String mapId,
    )
    loadMap,
    void Function(int completed, int total)? onMapLoaded,
    List<NarrativeMapProjection>? preparedMaps,
  }) async {
    final registry =
        project.eventRegistry ??
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
    final validatedProjects = Set<ProjectManifest>.identity()..add(project);
    if (registry.mode == EventSystemMode.legacyOnly &&
        !registry.hasLocalRuntimeAuthority) {
      if (presentationMediaCatalog == null && _hasWorldPictures(project)) {
        presentationMediaCatalog = await loadPresentationMediaCatalog?.call();
      }
      return NarrativeEventRuntimeSnapshot._(
        project: project,
        presentationMediaCatalog: presentationMediaCatalog,
        mapsById: const <String, MapData>{},
        registryResult: registryResult,
        factResolver: factResolver,
        projectCatalog: buildNarrativeEventProjectCatalog(
          project: project,
          maps: const <MapData>[],
          deferFingerprints: true,
          presentationMediaCatalog: presentationMediaCatalog,
        ),
        legacyClaimIndex: structuralClaimIndex,
        validatedProjects: validatedProjects,
      );
    }
    String? projectFingerprint;
    final owner = RuntimeProjectCatalog.ownerOf(project);
    final mapsById = <String, NarrativeMapView>{};
    final preparedById = preparedMaps == null
        ? null
        : {for (final map in preparedMaps) map.id: map};
    if (preparedMaps != null &&
        (preparedById!.length != preparedMaps.length ||
            preparedMaps.length != project.maps.length ||
            !project.maps.every(
              (entry) => preparedById.containsKey(entry.id),
            ))) {
      throw StateError(
        'Prepared narrative corpus does not match the project maps.',
      );
    }

    for (final mapEntry in project.maps) {
      if (mapsById.containsKey(mapEntry.id)) {
        throw StateError(
          'Event V2 runtime snapshot contains duplicate map id '
          '"${mapEntry.id}".',
        );
      }
      final ({ProjectManifest project, NarrativeMapView map}) loaded =
          preparedById == null
          ? await loadMap(mapEntry.id)
          : (project: project, map: preparedById[mapEntry.id]!);
      if (!identical(owner, RuntimeProjectCatalog.ownerOf(loaded.project)) ||
          (owner == null &&
              !identical(loaded.project, project) &&
              _runtimeProjectFingerprint(loaded.project) !=
                  (projectFingerprint ??= _runtimeProjectFingerprint(
                    project,
                  )))) {
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
      validatedProjects.add(loaded.project);
      onMapLoaded?.call(mapsById.length, project.maps.length);
    }

    if (owner != null) {
      final hydrated = await owner.manifestForNarrativeMaps(mapsById.values);
      if (!identical(owner, RuntimeProjectCatalog.ownerOf(hydrated))) {
        throw StateError(
          'Event V2 runtime snapshot changed while hydrating maps.',
        );
      }
      validatedProjects.add(hydrated);
    }

    final validationProject = owner == null
        ? project
        : owner.mergeNarrativeVisualDefinitions(project, validatedProjects);
    if (presentationMediaCatalog == null && _hasWorldPictures(validationProject)) {
      presentationMediaCatalog = await loadPresentationMediaCatalog?.call();
    }
    final catalog = await Isolate.run(
      () => _buildNarrativeCatalog(
        project: validationProject,
        mapsById: mapsById,
        registry: registry,
        structuralClaimIndex: structuralClaimIndex,
        presentationMediaCatalog: presentationMediaCatalog,
      ),
    );

    return NarrativeEventRuntimeSnapshot._(
      project: validationProject,
      presentationMediaCatalog: presentationMediaCatalog,
      mapsById: Map<String, NarrativeMapView>.unmodifiable(mapsById),
      registryResult: registryResult,
      factResolver: factResolver,
      projectCatalog: catalog.projectCatalog,
      legacyClaimIndex: catalog.legacyClaimIndex,
      validatedProjects: validatedProjects,
    );
  }
}

({
  NarrativeEventProjectCatalog projectCatalog,
  ValidatedLegacyClaimIndex legacyClaimIndex,
})
_buildNarrativeCatalog({
  required ProjectManifest project,
  required Map<String, NarrativeMapView> mapsById,
  required NarrativeEventRegistry registry,
  required ValidatedLegacyClaimIndex structuralClaimIndex,
  required ProjectMediaCatalog? presentationMediaCatalog,
}) {
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
          modelInteract: (mapId, instanceId) => const <NarrativeOutcomeRef>[],
          entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
          entityAutorun: (_, _) => const <NarrativeOutcomeRef>[],
          entityBump: (_, _) => const <NarrativeOutcomeRef>[],
          triggerBump: (_, _) => const <NarrativeOutcomeRef>[],
          triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
          mapEnter: (_) => const <NarrativeOutcomeRef>[],
          outcomeReceived: (outcome) => <NarrativeOutcomeRef>[outcome],
        ),
  ];
  final projectCatalog = buildNarrativeEventProjectCatalog(
    project: project,
    maps: mapsById.values.toList(growable: false),
    deferFingerprints: true,
    legacyProjections: legacyMapProjections,
    referencedOutcomes: referencedOutcomes,
    presentationMediaCatalog: presentationMediaCatalog,
  );

  return (
    projectCatalog: projectCatalog,
    legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
      registry,
      runtimeEvidence: runtimeEvidence,
    ),
  );
}

String _runtimeProjectFingerprint(ProjectManifest project) {
  final ordered = project.copyWith(
    elements: project.elements
        .map((element) {
          final profile = element.collisionProfile;
          if (profile == null) return element;
          final cells = [...profile.cells]
            ..sort((a, b) {
              final row = a.y.compareTo(b.y);
              return row == 0 ? a.x.compareTo(b.x) : row;
            });
          return element.copyWith(
            collisionProfile: profile.copyWith(cells: cells),
          );
        })
        .toList(growable: false),
  );
  return canonicalizeNarrativeEventJson(ordered.toJson());
}

bool _hasWorldPictures(ProjectManifest project) => project.scenes.any((scene) => scene.graph.nodes.any((node) {
  final payload = node.payload;
  final command = payload is SceneActionPayload ? payload.interactiveCommand : null;
  return command is SceneOpenImagePuzzleInteractiveCommand || command is SceneWorldPresentationInteractiveCommand && command.operation == SceneWorldPresentationOperation.showPicture;
}));
