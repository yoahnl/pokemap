import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeAssetMutation cinematic assets', () {
    test('create trims the title and generates a collision-safe stable id', () {
      final project = _project(
        cinematics: [
          _cinematic(id: 'cinematic_port_intro', title: 'Existing'),
          _cinematic(id: 'cinematic_port_intro_2', title: 'Existing copy'),
        ],
      );

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: '  Port Intro  ',
      );

      expect(result, isA<NarrativeAssetCreated>());
      final created = result as NarrativeAssetCreated;
      expect(created.asset.id, 'cinematic_port_intro_3');
      expect(created.asset.title, 'Port Intro');
      expect(created.before, same(project));
      expect(created.after.cinematics.last, same(created.asset));
      expect(project.cinematics, hasLength(2));
    });

    test('create rejects a blank title without changing project identity', () {
      final project = _project();

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: '   ',
      );

      expect(result, isA<NarrativeAssetRejected>());
      expect(result.before, same(project));
      expect(result.after, same(project));
      expect((result as NarrativeAssetRejected).code, 'blankTitle');
    });

    test('create accepts a validated template timeline', () {
      final project = _project();
      final timeline = CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'template.marker',
            kind: CinematicTimelineStepKind.marker,
            label: 'Ouverture',
          ),
        ],
      );

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: 'Ouverture',
        timeline: timeline,
      );

      expect(result, isA<NarrativeAssetCreated>());
      expect((result as NarrativeAssetCreated).asset.timeline, timeline);
    });

    test('update keeps the id stable and returns NoChange for equality', () {
      final original = _cinematic(id: 'cinematic_intro', title: 'Intro');
      final project = _project(cinematics: [original]);
      final updated = _cinematic(id: original.id, title: 'Opening');

      final changed = NarrativeAssetMutation.updateCinematic(
        project,
        cinematicId: original.id,
        cinematic: updated,
      );
      final unchanged = NarrativeAssetMutation.updateCinematic(
        changed.after,
        cinematicId: original.id,
        cinematic: updated,
      );

      expect(changed, isA<NarrativeAssetUpdated>());
      expect(changed.after.cinematics.single.id, original.id);
      expect(changed.after.cinematics.single.title, 'Opening');
      expect(unchanged, isA<NarrativeAssetNoChange>());
      expect(unchanged.after, same(changed.after));
    });

    test('update rejects an id mismatch and an unknown cinematic', () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
      );

      final mismatch = NarrativeAssetMutation.updateCinematic(
        project,
        cinematicId: 'cinematic_intro',
        cinematic: _cinematic(id: 'cinematic_other'),
      );
      final missing = NarrativeAssetMutation.updateCinematic(
        project,
        cinematicId: 'cinematic_missing',
        cinematic: _cinematic(id: 'cinematic_missing'),
      );

      expect(mismatch, isA<NarrativeAssetRejected>());
      expect((mismatch as NarrativeAssetRejected).code, 'idMismatch');
      expect(mismatch.after, same(project));
      expect((missing as NarrativeAssetRejected).code, 'assetNotFound');
      expect(missing.after, same(project));
    });

    test('clone gets a new id and does not retarget external references', () {
      final source = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro',
        description: 'Ouverture complète',
        storylineId: 'story_main',
        chapterId: 'chapter_port',
        mapId: 'map_port',
        tags: const ['intro', 'port'],
        requiredActors: [
          CinematicActorRef(
            actorId: 'actor_rival',
            label: 'Rival',
            entityId: 'npc_rival',
            role: 'opponent',
          ),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_quay',
            label: 'Quai',
            description: 'Point de rendez-vous',
          ),
        ],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'wait_1',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 250,
            ),
          ],
        ),
        notes: 'Ne pas déplacer le rival.',
        metadata: const {'camera': 'wide'},
        legacyBridge: CinematicLegacyBridge(
          sourceKind: CinematicLegacyBridgeSourceKind.cutsceneStudio,
          scenarioId: 'legacy_intro',
          cutsceneSchema: 'cutscene_v2',
          notes: 'Provenance uniquement.',
        ),
      );
      final project = _project(
        cinematics: [source],
        scenes: [
          _sceneWithCinematics('scene_intro', [source.id])
        ],
      );

      final result = NarrativeAssetMutation.cloneCinematic(
        project,
        cinematicId: source.id,
      );

      expect(result, isA<NarrativeAssetCreated>());
      final created = result as NarrativeAssetCreated;
      expect(created.asset.id, 'cinematic_intro_copie');
      expect(created.asset.title, 'Intro (copie)');
      expect(
        created.asset.toJson(),
        Map<String, dynamic>.from(source.toJson())
          ..['id'] = 'cinematic_intro_copie'
          ..['title'] = 'Intro (copie)',
      );
      expect(
        created.after.scenes.single.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneCinematicPayload>()
            .single
            .cinematicId,
        source.id,
      );
    });

    test('delete rejects every reference path by default', () {
      final project = _referencedProject();

      final result = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
      );

      expect(result, isA<NarrativeAssetRejected>());
      final rejected = result as NarrativeAssetRejected;
      expect(rejected.code, 'assetReferenced');
      expect(rejected.after, same(project));
      expect(rejected.referencePaths, [
        'scenes[scene_a].graph.nodes[1].payload.cinematicId',
        'scenes[scene_b].graph.nodes[1].payload.cinematicId',
        'scenes[scene_b].graph.nodes[2].payload.cinematicId',
      ]);
    });

    test('delete with replaceWith rewrites all SceneCinematicPayload refs', () {
      final project = _referencedProject();

      final result = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      );

      expect(result, isA<NarrativeAssetDeleted>());
      final deleted = result as NarrativeAssetDeleted;
      expect(
        deleted.after.cinematics.map((asset) => asset.id),
        ['cinematic_replacement'],
      );
      expect(deleted.rewrittenReferencePaths, hasLength(3));
      expect(
        deleted.after.scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneCinematicPayload>()
            .map((payload) => payload.cinematicId),
        everyElement('cinematic_replacement'),
      );
    });

    test('replaceWith rejects missing target and self rewrite by identity', () {
      final project = _referencedProject();

      final missing = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_missing',
        ),
      );
      final self = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_intro',
        ),
      );

      expect((missing as NarrativeAssetRejected).code, 'rewriteTargetMissing');
      expect(missing.after, same(project));
      expect((self as NarrativeAssetRejected).code, 'selfRewrite');
      expect(self.after, same(project));
    });

    test('ambiguous source, target and blank replacement are rejected', () {
      final duplicateSource = _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
          _cinematic(id: 'cinematic_intro'),
        ],
      );
      final ambiguousSource = NarrativeAssetMutation.deleteCinematic(
        duplicateSource,
        cinematicId: 'cinematic_intro',
      );

      final base = _referencedProject();
      final duplicateTarget = base.copyWith(
        cinematics: [
          ...base.cinematics,
          _cinematic(id: 'cinematic_replacement', title: 'Duplicate'),
        ],
      );
      final ambiguousTarget = NarrativeAssetMutation.deleteCinematic(
        duplicateTarget,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      );
      final blankTarget = NarrativeAssetMutation.deleteCinematic(
        base,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith('   '),
      );

      expect(
        (ambiguousSource as NarrativeAssetRejected).code,
        'assetIdAmbiguous',
      );
      expect(
        (ambiguousTarget as NarrativeAssetRejected).code,
        'rewriteTargetAmbiguous',
      );
      expect(
        (blankTarget as NarrativeAssetRejected).code,
        'rewriteTargetMissing',
      );
    });

    test('replaceWith rejects an id owned by another asset type', () {
      final base = _referencedProject();
      final project = base.copyWith(
        cinematics: [base.cinematics.first],
        scenes: [
          ...base.scenes,
          _sceneWithCinematics('cinematic_replacement', const []),
        ],
      );

      final result = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      );

      expect(result, isA<NarrativeAssetRejected>());
      expect(
        (result as NarrativeAssetRejected).code,
        'rewriteTargetTypeMismatch',
      );
      expect(result.after, same(project));
    });

    test('delete unreferenced asset succeeds and unknown asset is rejected',
        () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
      );

      final deleted = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
      );
      final missing = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_missing',
      );

      expect(deleted, isA<NarrativeAssetDeleted>());
      expect(deleted.after.cinematics, isEmpty);
      expect((missing as NarrativeAssetRejected).code, 'assetNotFound');
      expect(missing.after, same(project));
    });

    test('rejects a projected project that fails structural validation', () {
      final project = _project().copyWith(
        scenarios: const [
          ScenarioAsset(
            id: 'invalid_scenario',
            name: 'Invalid scenario',
            entryNodeId: 'missing',
          ),
        ],
      );

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: 'Cannot persist',
      );

      expect(result, isA<NarrativeAssetRejected>());
      expect(
        (result as NarrativeAssetRejected).code,
        'invalidProjectedProject',
      );
      expect(result.after, same(project));
    });

    test('reference path collections are immutable', () {
      final rejected = NarrativeAssetMutation.deleteCinematic(
        _referencedProject(),
        cinematicId: 'cinematic_intro',
      ) as NarrativeAssetRejected;
      final deleted = NarrativeAssetMutation.deleteCinematic(
        _referencedProject(),
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      ) as NarrativeAssetDeleted;

      expect(
        () => rejected.referencePaths.add('unexpected'),
        throwsUnsupportedError,
      );
      expect(
        () => deleted.rewrittenReferencePaths.add('unexpected'),
        throwsUnsupportedError,
      );
    });

    test('validates a cinematic replacement with exact immutable coverage', () {
      final project = _referencedProject();

      final result = NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      );

      expect(result, isA<NarrativeReferenceReplacementValidated>());
      final capability =
          (result as NarrativeReferenceReplacementValidated).capability;
      expect(
        capability.source,
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          'cinematic_intro',
        ),
      );
      expect(
        capability.replacement,
        const NarrativeDependencyKey(
          NarrativeDependencyTargetKind.cinematic,
          'cinematic_replacement',
        ),
      );
      expect(capability.coveredReferencePaths, [
        'scenes[scene_a].graph.nodes[1].payload.cinematicId',
        'scenes[scene_b].graph.nodes[1].payload.cinematicId',
        'scenes[scene_b].graph.nodes[2].payload.cinematicId',
      ]);
      expect(
        () => capability.coveredReferencePaths.add('forged'),
        throwsUnsupportedError,
      );
    });

    test('validates a cinematic replacement without consumers', () {
      final project = _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
          _cinematic(id: 'cinematic_replacement'),
        ],
      );

      final result = NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      ) as NarrativeReferenceReplacementValidated;

      expect(result.capability.coveredReferencePaths, isEmpty);
    });

    test('returns typed replacement validation rejections', () {
      final project = _referencedProject();

      NarrativeReferenceReplacementRejected rejected(
        String sourceId,
        String replacementId,
      ) {
        return NarrativeAssetMutation.validateCinematicReplacement(
          project,
          sourceId: sourceId,
          replacementId: replacementId,
        ) as NarrativeReferenceReplacementRejected;
      }

      expect(
        rejected('cinematic_missing', 'cinematic_replacement').code,
        'assetNotFound',
      );
      expect(
        rejected('cinematic_intro', 'cinematic_intro').code,
        'selfRewrite',
      );

      final ambiguousSource = _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
          _cinematic(id: 'cinematic_intro'),
          _cinematic(id: 'cinematic_replacement'),
        ],
      );
      final ambiguousReplacement = project.copyWith(
        cinematics: [
          ...project.cinematics,
          _cinematic(id: 'cinematic_replacement'),
        ],
      );

      expect(
        (NarrativeAssetMutation.validateCinematicReplacement(
          ambiguousSource,
          sourceId: 'cinematic_intro',
          replacementId: 'cinematic_replacement',
        ) as NarrativeReferenceReplacementRejected)
            .code,
        'assetIdAmbiguous',
      );
      expect(
        (NarrativeAssetMutation.validateCinematicReplacement(
          ambiguousReplacement,
          sourceId: 'cinematic_intro',
          replacementId: 'cinematic_replacement',
        ) as NarrativeReferenceReplacementRejected)
            .code,
        'rewriteTargetAmbiguous',
      );
    });

    test('revalidates replacement capability before applying deletion', () {
      final project = _referencedProject();
      final capability = (NarrativeAssetMutation.validateCinematicReplacement(
        project,
        sourceId: 'cinematic_intro',
        replacementId: 'cinematic_replacement',
      ) as NarrativeReferenceReplacementValidated)
          .capability;
      final changedProject = project.copyWith(
        scenes: [
          ...project.scenes,
          _sceneWithCinematics('scene_new', ['cinematic_intro']),
        ],
      );

      final stale =
          NarrativeAssetMutation.deleteCinematicWithValidatedReplacement(
        changedProject,
        capability,
      );
      final applied =
          NarrativeAssetMutation.deleteCinematicWithValidatedReplacement(
        project,
        capability,
      );

      expect(stale, isA<NarrativeAssetRejected>());
      expect(
          (stale as NarrativeAssetRejected).code, 'staleReplacementCapability');
      expect(stale.after, same(changedProject));
      expect(applied, isA<NarrativeAssetDeleted>());
      expect(applied.after.cinematics.map((asset) => asset.id), [
        'cinematic_replacement',
      ]);
    });
  });
}

ProjectManifest _referencedProject() {
  return _project(
    cinematics: [
      _cinematic(id: 'cinematic_intro', title: 'Intro'),
      _cinematic(id: 'cinematic_replacement', title: 'Replacement'),
    ],
    scenes: [
      _sceneWithCinematics('scene_a', ['cinematic_intro']),
      _sceneWithCinematics(
        'scene_b',
        ['cinematic_intro', 'cinematic_intro'],
      ),
    ],
  );
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'Narrative mutation test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
    scenes: scenes,
  );
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Cinematic',
}) {
  return CinematicAsset(
    id: id,
    title: title,
    description: 'Description',
    timeline: CinematicTimeline(),
    metadata: const {'test': 'true'},
  );
}

SceneAsset _sceneWithCinematics(String id, List<String> cinematicIds) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start, title: 'Start'),
    for (var index = 0; index < cinematicIds.length; index++)
      SceneNode(
        id: 'cinematic_$index',
        kind: SceneNodeKind.cinematic,
        title: 'Cinematic $index',
        payload: SceneCinematicPayload(cinematicId: cinematicIds[index]),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'End'),
  ];
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(startNodeId: 'start', nodes: nodes),
  );
}
