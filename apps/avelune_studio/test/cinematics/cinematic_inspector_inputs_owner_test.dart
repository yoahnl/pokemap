import 'package:avelune_studio/features/cinematics/application/cinematic_actor_choices.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_camera_options.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_input_state.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late CinematicWorkspaceController controller;
  setUp(() async {
    f = await CinematicAdapterFixture.create(
      cinematics: [CinematicAdapterFixture.asset('a')],
    );
    await f.writeManifest(
      (await f.readManifest()).copyWith(
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'wave',
              displayName: 'Saluer',
              mode: CharacterCustomAnimationMode.single,
            ),
          ],
        ),
      ),
    );
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    maps.project = await f.readManifest();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    controller = CinematicWorkspaceController(
      narrative,
      f.adapter(),
      changed: () {},
    );
    expect(await controller.open('a'), isTrue);
  });
  tearDown(() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await f.dispose();
  });

  CinematicInputState inputs() => controller.inputsFor('a');

  CinematicFieldCommitResult commitTitle(String text) {
    final field = inputs().field(
      'cinematic-title-a',
      controller.active!.asset.title,
    )..edit(text);
    return inputs().commitField(
      field,
      tryCommit: (value) => controller.editFromInspector(
        'a',
        (asset) => asset.copyWith(title: value),
        inputs(),
      ),
      fallbackError: 'Corrigez la saisie de « Nom de la cinématique ».',
      alwaysCommit: true,
    );
  }

  CinematicFieldCommitResult commitDuration(
    CinematicTimelineStep step,
    String text,
  ) {
    final field = inputs().field('duration-a-${step.id}', '${step.durationMs}')
      ..edit(text);
    return inputs().commitField(
      field,
      tryCommit: (value) =>
          controller.commitStepDuration('a', inputs(), step, value),
      fallbackError: 'Corrigez la saisie de « Durée (ms) ».',
      alwaysCommit: true,
    );
  }

  CinematicTimelineStep step(String id) =>
      controller.active!.asset.timeline.steps.singleWhere((s) => s.id == id);

  test('targeted discard recovers a rejected inspector field and its validation diagnostics', () async {
    final before = controller.active!.asset;
    final disk = await f.file('project.json').readAsBytes();

    expect(commitTitle(''), CinematicFieldCommitResult.rejected);
    final field = inputs().field('cinematic-title-a', before.title);
    expect(inputs().error, isNotNull);
    expect(inputs().inspectorError, isNotNull);
    expect(controller.flushEdits!(), isFalse);

    expect(
      controller.discardInputs(
        controller.prepareInputDiscard('a')!,
        confirmed: true,
      ),
      isTrue,
    );

    expect(inputs().field('cinematic-title-a', before.title), same(field));
    expect(field.text, before.title);
    expect(inputs().error, isNull);
    expect(inputs().inspectorError, isNull);
    expect(controller.error, isNull);
    expect(controller.flushEdits!(), isTrue);
    expect(await controller.saveAll(), isTrue);
    expect(controller.active!.asset, same(before));
    expect(await f.file('project.json').readAsBytes(), disk);
  });

  test(
    'inspector delegates accepted and rejected commits to its input owner',
    () async {
      final disk = await f.file('project.json').readAsBytes();

      expect(
        commitTitle('Départ renommé'),
        CinematicFieldCommitResult.accepted,
      );
      final field = inputs().field('cinematic-title-a', 'Départ renommé');
      expect(controller.active!.asset.title, 'Départ renommé');
      expect(field.pending, isFalse);
      expect(controller.flushEdits!(), isTrue);
      final accepted = controller.active!.asset;

      expect(commitTitle(''), CinematicFieldCommitResult.rejected);
      expect(controller.active!.asset, same(accepted));
      expect(field.problem, isNotNull);
      expect(inputs().inspectorError, isNotNull);
      expect(controller.flushEdits!(), isFalse);

      expect(
        controller.discardInputs(
          controller.prepareInputDiscard('a')!,
          confirmed: true,
        ),
        isTrue,
      );
      expect(field.text, 'Départ renommé');
      expect(await f.file('project.json').readAsBytes(), disk);
    },
  );

  test('tab transition commits focused title before showing actors', () {
    final field = inputs().field('cinematic-title-a', 'Départ')
      ..edit('Départ renommé');
    expect(field.pending, isTrue);
    expect(controller.active!.asset.title, 'Départ');

    expect(commitTitle('Départ renommé'), CinematicFieldCommitResult.accepted);

    expect(controller.active!.asset.title, 'Départ renommé');
    expect(field.pending, isFalse);
    expect(inputs().valid, isTrue);
  });

  test(
    'an inspector edit from a document that is no longer active is ignored',
    () async {
      final before = controller.active!.asset;
      expect(
        controller.editFromInspector(
          'b',
          (asset) => asset.copyWith(title: 'Fantôme'),
          inputs(),
        ),
        isFalse,
      );
      expect(controller.active!.asset, same(before));
      expect(inputs().error, isNull);
    },
  );

  test(
    'focused duration commits canonical value and invalid duration is rejected',
    () async {
      final id = controller.addBasic(
        CinematicTimelineBasicBlockKind.wait,
        durationMs: 500,
      )!;
      final disk = await f.file('project.json').readAsBytes();
      final wait = step(id);

      expect(commitDuration(wait, '1750'), CinematicFieldCommitResult.accepted);
      expect(step(id).durationMs, 1750);
      final accepted = controller.active!.asset;

      expect(
        commitDuration(step(id), '-2'),
        CinematicFieldCommitResult.rejected,
      );
      expect(controller.active!.asset, same(accepted));
      expect(inputs().error, contains('strictement positive'));
      final field = inputs().field('duration-a-$id', '1750');
      expect(field.text, '-2');
      expect(controller.flushEdits!(), isFalse);
      expect(await controller.saveAll(), isFalse);
      expect(await f.file('project.json').readAsBytes(), disk);

      expect(
        commitDuration(step(id), 'abc'),
        CinematicFieldCommitResult.rejected,
      );
      expect(inputs().error, cinematicStepDurationError);

      expect(
        commitDuration(step(id), '1750'),
        CinematicFieldCommitResult.accepted,
      );
      expect(inputs().error, isNull);
      expect(await controller.save(), isTrue, reason: controller.error);
      final saved = (await f.readManifest()).cinematics.single;
      expect(
        saved.timeline.steps.singleWhere((s) => s.id == id).durationMs,
        1750,
      );
    },
  );

  test(
    'invalid command number and title remain blocked until corrected',
    () async {
      final id = controller.addCommand(
        CinematicTimelineStepKind.shake,
        durationMs: 600,
      )!;
      bool intensity(String text) => controller.commitCommandNumber(
        'a',
        inputs(),
        'Intensité (0 à 1)',
        text,
        (asset, value) => updateCinematicTimelineCommandStep(
          asset,
          stepId: id,
          intensity: value,
        ).cinematic,
        max: 1,
      );
      final before = controller.active!.asset;

      expect(intensity('2'), isFalse);
      expect(inputs().error, contains('Valeur invalide'));
      expect(controller.active!.asset, same(before));
      expect(intensity('-0.1'), isFalse);
      expect(controller.active!.asset, same(before));

      expect(intensity('0.5'), isTrue);
      expect(inputs().error, isNull);
      expect(
        step(id).metadata[cinematicTimelineCommandIntensityMetadataKey],
        '0.5',
      );

      expect(commitTitle(''), CinematicFieldCommitResult.rejected);
      expect(inputs().error, isNotNull);
      expect(controller.active!.asset.title, 'Départ');
      expect(commitTitle('Départ'), CinematicFieldCommitResult.accepted);
      expect(inputs().error, isNull);
      expect(await controller.save(), isTrue, reason: controller.error);
    },
  );

  test(
    'command numbers refuse non integers where milliseconds are required',
    () {
      expect(parseCinematicCommandNumber('250', integer: true), 250);
      expect(parseCinematicCommandNumber('250.5', integer: true), isNull);
      expect(parseCinematicCommandNumber('1.01', max: 1), isNull);
      expect(parseCinematicCommandNumber('NaN'), isNull);
      expect(parseCinematicCommandNumber('1', max: 1), 1);
    },
  );

  test('camera target and zoom update canonical focus while actor choices preserve identity', () {
    final actor = controller.addActor('Guide')!;
    controller.bindActor(
      CinematicActorBinding(
        actorId: actor,
        kind: CinematicActorBindingKind.cinematicOnly,
      ),
    );
    final id = controller.addBasic(
      CinematicTimelineBasicBlockKind.camera,
      durationMs: 700,
      cameraMode: CinematicTimelineCameraMode.focus,
      cameraFocusBinding: CinematicTimelineCameraFocusBinding(
        target: CinematicCameraTargetBinding.sceneCenter(),
        zoomPreset: CinematicCameraZoomPreset.medium,
      ),
    )!;
    bool focus(
      CinematicTimelineCameraFocusBinding Function(CinematicTimelineStep)
      binding,
    ) => controller.editFromInspector(
      'a',
      (asset) => updateCinematicTimelineBasicBlockStep(
        controller.projectWith(asset),
        cinematicId: asset.id,
        stepId: id,
        cameraFocusBinding: binding(step(id)),
      ).cinematic,
      inputs(),
    );

    expect(cinematicCameraTargetOption(null), cinematicCameraCenterOption);
    expect(
      focus(
        (s) => cinematicCameraFocusWithTarget(
          s,
          cinematicCameraActorOption(actor),
        ),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(
      cinematicCameraTargetOption(
        cinematicTimelineCameraFocusBindingOf(step(id))!.target,
      ),
      'actor:$actor',
    );
    expect(
      focus(
        (s) => cinematicCameraFocusWithZoom(s, CinematicCameraZoomPreset.close),
      ),
      isTrue,
      reason: controller.error,
    );
    final result = cinematicTimelineCameraFocusBindingOf(step(id))!;
    expect(result.target.kind, CinematicCameraTargetKind.actor);
    expect(result.target.actorId, actor);
    expect(result.zoomPreset, CinematicCameraZoomPreset.close);
  });

  test(
    'camera option codec falls back to the scene centre and medium framing',
    () {
      final point = cinematicCameraTargetFromOption(
        cinematicCameraPointOption('arrival'),
      );
      expect(point.kind, CinematicCameraTargetKind.stagePoint);
      expect(point.stagePointId, 'arrival');
      expect(
        cinematicCameraTargetFromOption('inconnu').kind,
        CinematicCameraTargetKind.sceneCenter,
      );
      final reset = CinematicTimelineStep(
        id: 'camera',
        kind: CinematicTimelineStepKind.camera,
        durationMs: 700,
      );
      expect(cinematicCameraZoomOf(reset), CinematicCameraZoomPreset.medium);
      final focus = cinematicCameraFocusForMode(
        reset,
        CinematicTimelineCameraMode.focus,
      )!;
      expect(focus.target.kind, CinematicCameraTargetKind.sceneCenter);
      expect(focus.zoomPreset, CinematicCameraZoomPreset.medium);
      expect(
        cinematicCameraFocusForMode(reset, CinematicTimelineCameraMode.hold),
        isNull,
      );
    },
  );

  test('guided initial placement is nonblocking and map entity role remains explicitly unbound', () {
    final actor = controller.addActor('Guide')!;
    controller.setStagePoint(
      CinematicStagePoint(id: 'start', label: 'Départ', x: 2, y: 3),
    );
    final before = controller.active!.asset;

    expect(cinematicPlacementChoiceIsStaged('stagePoint'), isTrue);
    expect(cinematicPlacementChoiceIsStaged('fromMovementTarget'), isTrue);
    expect(controller.active!.asset, same(before));
    expect(controller.error, isNull);

    expect(
      controller.setPlacement(
        CinematicActorInitialPlacement(
          actorId: actor,
          kind: CinematicActorInitialPlacementKind.stagePoint,
          stagePointId: 'start',
        ),
      ),
      isTrue,
      reason: controller.error,
    );
    final placement =
        controller.active!.asset.stageContext!.initialPlacements.single;
    expect(placement.stagePointId, 'start');

    expect(cinematicPlacementChoiceIsStaged('fromMapEntity'), isFalse);
    final fromEntity = cinematicPlacementForKind(
      actor,
      'fromMapEntity',
      placement,
    );
    expect(fromEntity.stagePointId, isNull);
    expect(
      cinematicPlacementForKind(actor, 'stagePoint', placement).stagePointId,
      'start',
    );

    expect(
      controller.bindActor(cinematicBindingForRole(actor, 'mapEntity', null)),
      isTrue,
      reason: controller.error,
    );
    final binding = controller.active!.asset.stageContext!.actorBindings.single;
    expect(binding.kind, CinematicActorBindingKind.mapEntity);
    expect(binding.mapEntityId, isNull);
    final linked = CinematicActorBinding(
      actorId: actor,
      kind: CinematicActorBindingKind.mapEntity,
      mapEntityId: 'chief',
    );
    expect(
      cinematicBindingForRole(actor, 'mapEntity', linked).mapEntityId,
      'chief',
    );
    expect(
      cinematicBindingForRole(actor, 'player', linked).mapEntityId,
      isNull,
    );
  });

  test('typed animation inspector edits repeat count and retains invalid input diagnostic', () {
    final actor = controller.addActor('Guide')!;
    final id = controller.addAnimation(
      CharacterCustomAnimationRuntimeCommand(
        actorId: actor,
        definitionId: 'wave',
      ),
    )!;
    CharacterCustomAnimationRuntimeCommand command() =>
        cinematicCharacterCustomAnimationCommandOf(step(id))!;

    expect(
      controller.updateAnimationFromInspector(
        'a',
        inputs(),
        id,
        cinematicAnimationCommandWith(
          command(),
          playback: cinematicAnimationPlaybackFor('repeatCount'),
        ),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(command().playback.repeatCount, 2);
    final before = controller.active!.asset;

    expect(
      controller.commitAnimationCount('a', inputs(), id, command(), '0'),
      isFalse,
    );
    expect(inputs().error, contains('strictement positive'));
    expect(inputs().inspectorError, contains('strictement positive'));
    expect(controller.active!.asset, same(before));

    expect(
      controller.commitAnimationCount('a', inputs(), id, command(), '4'),
      isTrue,
      reason: controller.error,
    );
    expect(inputs().error, isNull);
    expect(command().playback.repeatCount, 4);

    expect(
      controller.updateAnimationFromInspector(
        'a',
        inputs(),
        id,
        cinematicAnimationCommandWith(
          command(),
          playback: cinematicAnimationPlaybackFor('forDuration'),
        ),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(command().playback.durationMs, 1000);
  });

  test('jump inspector authors height duration target and facing with safe refusal and save/reopen', () async {
    final actor = controller.addActor('Guide')!;
    final target = controller.addTarget('Arrivée')!;
    final id = controller.addJump(actor, target)!;
    double? height() => cinematicTimelineActorJumpHeightCellsOf(step(id));

    expect(controller.commitJumpHeight('a', inputs(), step(id), '0'), isFalse);
    expect(inputs().error, contains('hauteur'));
    expect(height(), 0.5);
    expect(
      controller.commitJumpHeight('a', inputs(), step(id), '4.5'),
      isFalse,
    );
    expect(height(), 0.5);
    expect(
      controller.commitJumpHeight('a', inputs(), step(id), '1.25'),
      isTrue,
      reason: controller.error,
    );
    expect(inputs().error, isNull);
    expect(height(), 1.25);

    expect(
      controller.commitStepDuration('a', inputs(), step(id), '100'),
      isFalse,
    );
    expect(inputs().error, contains('durée du saut'));
    expect(step(id).durationMs, 1000);
    expect(
      controller.commitStepDuration('a', inputs(), step(id), '1400'),
      isTrue,
      reason: controller.error,
    );
    expect(inputs().error, isNull);
    expect(step(id).durationMs, 1400);

    expect(await controller.save(), isTrue, reason: controller.error);
    final saved = (await f.readManifest()).cinematics.single;
    expect(saved, controller.active!.asset);
    expect(
      saved.timeline.steps.singleWhere((s) => s.id == id).durationMs,
      1400,
    );
  });

  test(
    'completion picker edits both policies with undo and canonical save/reopen',
    () async {
      final before = controller.active!.asset;
      expect(
        controller.editFromInspector(
          'a',
          (asset) => asset.copyWith(allowMobileActorCrossing: true),
          inputs(),
        ),
        isTrue,
      );
      expect(controller.active!.asset.allowMobileActorCrossing, isTrue);
      controller.undo();
      expect(controller.active!.asset, before);
      controller.redo();
      expect(controller.active!.asset.allowMobileActorCrossing, isTrue);
      final crossed = controller.active!.asset;

      bool policy(CinematicActorCompletionPolicy value) =>
          controller.editFromInspector(
            'a',
            (asset) => setCinematicActorCompletionPolicy(
              controller.projectWith(asset),
              cinematicId: asset.id,
              policy: value,
            ).cinematic,
            inputs(),
          );
      expect(policy(CinematicActorCompletionPolicy.restoreInitial), isTrue);
      final restored = controller.active!.asset;
      expect(
        restored.actorCompletionPolicy,
        CinematicActorCompletionPolicy.restoreInitial,
      );
      expect(restored.timeline, crossed.timeline);
      expect(restored.stageContext, crossed.stageContext);
      controller.undo();
      expect(controller.active!.asset, crossed);
      controller.redo();
      expect(controller.active!.asset, restored);

      expect(await controller.save(), isTrue, reason: controller.error);
      expect((await f.readManifest()).cinematics.single, restored);
    },
  );

  test('inspector edits keep authored manual paths', () {
    final actor = controller.addActor('Guide')!;
    final target = controller.addTarget('Arrivée')!;
    final move = controller.addMove(actor, target)!;
    expect(
      controller.setStagePoint(
        CinematicStagePoint(id: 'corner', label: 'Coin', x: 4, y: 4),
      ),
      isTrue,
      reason: controller.error,
    );
    expect(
      controller.setManualPath(move, ['corner']),
      isTrue,
      reason: controller.error,
    );
    final paths = controller.active!.asset.stageContext!.manualPaths;
    expect(paths, isNotEmpty);

    expect(
      controller.editFromInspector('a', (asset) {
        final context = asset.stageContext!;
        return asset.copyWith(
          notes: 'Notes',
          stageContext: CinematicStageContext(
            backdropMode: context.backdropMode,
            actorBindings: context.actorBindings,
            actorAppearanceBindings: context.actorAppearanceBindings,
            initialPlacements: context.initialPlacements,
            movementTargetBindings: context.movementTargetBindings,
            stagePoints: context.stagePoints,
          ),
        );
      }, inputs()),
      isTrue,
      reason: controller.error,
    );
    expect(controller.active!.asset.notes, 'Notes');
    expect(controller.active!.asset.stageContext!.manualPaths, paths);
  });
}
