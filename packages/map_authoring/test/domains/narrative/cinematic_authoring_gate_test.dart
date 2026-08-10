import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('cinematic authoring and narrative parity', () {
    test('all twelve timeline kinds have an explicit runtime consumer truth',
        () {
      final gate = const NarrativeParityGate().inspect(_manifest());
      final cinematicEntries = gate.entries
          .where((entry) => entry.domain == 'cinematic.timeline')
          .toList();

      expect(
          cinematicEntries, hasLength(CinematicTimelineStepKind.values.length));
      expect(
        cinematicEntries.map((entry) => entry.featureId).toSet(),
        CinematicTimelineStepKind.values.map((kind) => kind.name).toSet(),
      );
      expect(
        cinematicEntries.every((entry) => entry.runtimeAuthority.isNotEmpty),
        isTrue,
      );
    });

    test('missing dialogue is an explicit blocking preflight issue', () {
      final cinematic = CinematicAsset(
        id: 'cine_intro',
        title: 'Intro',
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'line',
              kind: CinematicTimelineStepKind.dialogueLine,
              assetRef: 'missing_dialogue',
              durationMs: 500,
            ),
          ],
        ),
      );

      final report = const CinematicAuthoringInspector().inspect(
        project: _manifest(cinematics: [cinematic]),
        cinematic: cinematic,
      );

      expect(report.canPublish, isFalse);
      expect(
        report.preflightIssues.map((issue) => issue['kind']),
        contains('missingDialogue'),
      );
    });

    test('timeline move keeps selected identities and relative order', () {
      final cinematic = _cinematic();
      final project = _manifest(cinematics: [cinematic]);

      final moved = const CinematicActions().moveTimelineSteps(
        project,
        cinematicId: cinematic.id,
        stepIds: const {'wait', 'fade'},
        insertionIndex: 3,
      );

      expect(
        moved.cinematics.single.timeline.steps.map((step) => step.id),
        ['camera', 'wait', 'fade'],
      );
    });

    test('dispatcher and resource registry expose cinematic authoring', () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        ids,
        containsAll({
          'cinematic.upsert',
          'cinematic.delete',
          'cinematic.timeline_move',
          'cinematic.timeline_duplicate',
          'cinematic.timeline_paste',
          'cinematic.timeline_delete',
          'cinematic.character_animation.upsert',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        contains('cinematic'),
      );
    });

    test('semantic action adds and updates a stable animation step', () {
      final project = _manifest(cinematics: <CinematicAsset>[_cinematic()]);
      final command = CharacterCustomAnimationRuntimeCommand(
        actorId: 'hero',
        definitionId: 'wave',
        direction: EntityFacing.south,
      );

      final added = const CinematicActions().upsertCharacterAnimationStep(
        project,
        cinematicId: 'cine_timeline',
        command: command,
      );
      final step = added.cinematics.single.timeline.steps.last;
      final renamedDefinition = added.copyWith(
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Salut renommé',
              mode: CharacterCustomAnimationMode.directional,
            ),
          ],
        ),
      );
      final updated = const CinematicActions().upsertCharacterAnimationStep(
        renamedDefinition,
        cinematicId: 'cine_timeline',
        stepId: step.id,
        command: CharacterCustomAnimationRuntimeCommand(
          actorId: command.actorId,
          definitionId: command.definitionId,
          direction: command.direction,
          playback: CharacterCustomAnimationPlayback.repeatCount(2),
        ),
      );

      expect(step.kind, CinematicTimelineStepKind.actorAnimation);
      expect(
        cinematicCharacterCustomAnimationCommandOf(
          updated.cinematics.single.timeline.steps.last,
        )!
            .definitionId,
        'wave',
      );
      expect(updated.cinematics.single.timeline.steps.last.id, step.id);
    });
  });
}

ProjectManifest _manifest({List<CinematicAsset> cinematics = const []}) =>
    ProjectManifest(
      name: 'Cinematic fixture',
      maps: const [],
      tilesets: const [],
      cinematics: cinematics,
      characterStudioCatalog: const ProjectCharacterStudioCatalog(
        customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
          CharacterCustomAnimationDefinition(
            id: 'wave',
            displayName: 'Saluer',
            mode: CharacterCustomAnimationMode.directional,
          ),
        ],
      ),
    );

CinematicAsset _cinematic() => CinematicAsset(
      id: 'cine_timeline',
      title: 'Timeline',
      timeline: CinematicTimeline(
        steps: [
          CinematicTimelineStep(
            id: 'wait',
            kind: CinematicTimelineStepKind.wait,
            durationMs: 100,
          ),
          CinematicTimelineStep(
            id: 'camera',
            kind: CinematicTimelineStepKind.camera,
            durationMs: 100,
          ),
          CinematicTimelineStep(
            id: 'fade',
            kind: CinematicTimelineStepKind.fade,
            durationMs: 100,
          ),
        ],
      ),
      requiredActors: <CinematicActorRef>[
        CinematicActorRef(actorId: 'hero', label: 'Héros'),
      ],
    );
