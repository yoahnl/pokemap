import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CinematicActorDisplayPreviewModel', () {
    test(
      'builds actor display preview model for cinematic actors without rendering them',
      () {
        final model = buildCinematicActorDisplayPreviewModel(
          cinematic: _cinematic(
            requiredActors: [
              _actor('player', label: 'Player'),
              _actor('guard', label: 'Guard'),
              _actor('liza', label: 'Liza'),
              _actor('unbound', label: 'Unbound'),
            ],
            movementTargets: [
              _target('target_player_spawn'),
              _target('target_event_arrival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'player',
                  kind: CinematicActorBindingKind.player,
                ),
                CinematicActorBinding(
                  actorId: 'guard',
                  kind: CinematicActorBindingKind.mapEntity,
                  mapEntityId: 'entity_guard',
                ),
                CinematicActorBinding(
                  actorId: 'liza',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
                CinematicActorBinding(
                  actorId: 'unbound',
                  kind: CinematicActorBindingKind.unbound,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'liza',
                  characterId: 'liza_character',
                ),
              ],
              initialPlacements: [
                CinematicActorInitialPlacement(
                  actorId: 'player',
                  kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                  targetId: 'target_player_spawn',
                ),
                CinematicActorInitialPlacement(
                  actorId: 'guard',
                  kind: CinematicActorInitialPlacementKind.fromMapEntity,
                ),
                CinematicActorInitialPlacement(
                  actorId: 'liza',
                  kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                  targetId: 'target_event_arrival',
                ),
              ],
              movementTargetBindings: [
                CinematicMovementTargetBinding(
                  targetId: 'target_player_spawn',
                  kind: CinematicMovementTargetBindingKind.mapEntity,
                  sourceId: 'entity_spawn',
                ),
                CinematicMovementTargetBinding(
                  targetId: 'target_event_arrival',
                  kind: CinematicMovementTargetBindingKind.mapEvent,
                  sourceId: 'event_arrival',
                ),
              ],
            ),
          ),
          project: _project(),
          stageMap: _stageMap(),
          mapData: _mapData(),
        );

        expect(model.actors.map((actor) => actor.actorId), [
          'player',
          'guard',
          'liza',
          'unbound',
        ]);

        final player = model.actorById('player')!;
        expect(player.bindingStatus, CinematicActorDisplayBindingStatus.player);
        expect(player.position.status,
            CinematicActorPreviewPositionStatus.resolved);
        expect(player.position.x, 2);
        expect(player.position.y, 3);
        expect(
          player.appearance.status,
          CinematicActorPreviewAppearanceStatus.spriteReady,
        );
        expect(player.appearance.characterId, 'hero_character');

        final guard = model.actorById('guard')!;
        expect(
            guard.bindingStatus, CinematicActorDisplayBindingStatus.mapEntity);
        expect(guard.position.x, 6);
        expect(guard.position.y, 4);
        expect(guard.appearance.characterId, 'guard_character');
        expect(guard.direction, CinematicActorPreviewDirection.east);

        final liza = model.actorById('liza')!;
        expect(
          liza.bindingStatus,
          CinematicActorDisplayBindingStatus.cinematicOnly,
        );
        expect(liza.position.x, 9);
        expect(liza.position.y, 5);
        expect(liza.appearance.characterId, 'liza_character');
        expect(liza.renderHint, CinematicActorPreviewRenderHint.sprite);

        final unbound = model.actorById('unbound')!;
        expect(
            unbound.bindingStatus, CinematicActorDisplayBindingStatus.unbound);
        expect(unbound.position.status,
            CinematicActorPreviewPositionStatus.unbound);
        expect(
          unbound.appearance.status,
          CinematicActorPreviewAppearanceStatus.notRequired,
        );
        expect(unbound.renderHint, CinematicActorPreviewRenderHint.hidden);
        expect(unbound.isRenderable, isFalse);
      },
    );

    test('returns no actors status when cinematic has no required actors', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(model.status, CinematicActorDisplayPreviewStatus.noActors);
      expect(model.actors, isEmpty);
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
            CinematicActorDisplayPreviewDiagnosticCode.actorDisplayNoActors),
      );
    });

    test('reports missing binding for actor without stage binding', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(requiredActors: [_actor('guard')]),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      final actor = model.actorById('guard')!;
      expect(actor.bindingStatus, CinematicActorDisplayBindingStatus.missing);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingBinding,
        ),
      );
    });

    test('marks unbound actor as non renderable', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.unbound,
        ),
      );

      final actor = model.actorById('actor')!;
      expect(actor.bindingStatus, CinematicActorDisplayBindingStatus.unbound);
      expect(actor.isRenderable, isFalse);
      expect(actor.renderHint, CinematicActorPreviewRenderHint.hidden);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayUnboundActor),
      );
    });

    test('resolves map entity actor position from map data entity', () {
      final model = _singleActorModel(
        actorId: 'guard',
        binding: CinematicActorBinding(
          actorId: 'guard',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_guard',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'guard',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
      );

      final position = model.actorById('guard')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(position.x, 6);
      expect(position.y, 4);
      expect(position.sourceId, 'entity_guard');
    });

    test('reports missing map entity when binding points to unknown entity',
        () {
      final model = _singleActorModel(
        actorId: 'guard',
        binding: CinematicActorBinding(
          actorId: 'guard',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_missing',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'guard',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
      );

      final actor = model.actorById('guard')!;
      expect(actor.position.status,
          CinematicActorPreviewPositionStatus.missingSource);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayMissingMapEntity,
        ),
      );
    });

    test(
        'resolves cinematic only actor appearance from character library binding',
        () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'liza',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_event_arrival',
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'liza_character',
        ),
        movementTargets: [_target('target_event_arrival')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_event_arrival',
            kind: CinematicMovementTargetBindingKind.mapEvent,
            sourceId: 'event_arrival',
          ),
        ],
      );

      final appearance = model.actorById('liza')!.appearance;
      expect(
          appearance.status, CinematicActorPreviewAppearanceStatus.spriteReady);
      expect(appearance.characterId, 'liza_character');
      expect(appearance.tilesetId, 'characters');
    });

    test('reports missing appearance binding for cinematic only actor', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      );

      final actor = model.actorById('liza')!;
      expect(
        actor.appearance.status,
        CinematicActorPreviewAppearanceStatus.placeholderOnly,
      );
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayMissingAppearance,
        ),
      );
    });

    test('reports unknown character reference', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'missing_character',
        ),
      );

      final actor = model.actorById('liza')!;
      expect(
        actor.appearance.status,
        CinematicActorPreviewAppearanceStatus.missingCharacter,
      );
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayUnknownCharacter,
        ),
      );
    });

    test('reports character missing tileset', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'character_without_tileset',
        ),
      );

      expect(
        model.actorById('liza')!.appearance.status,
        CinematicActorPreviewAppearanceStatus.missingTileset,
      );
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayCharacterMissingTileset,
        ),
      );
    });

    test('reports character missing idle animation', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'character_without_idle',
        ),
      );

      expect(
        model.actorById('liza')!.appearance.status,
        CinematicActorPreviewAppearanceStatus.missingIdleAnimation,
      );
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayCharacterMissingIdleAnimation,
        ),
      );
    });

    test(
        'uses player default character when available without '
        'Game'
        'State', () {
      final model = _singleActorModel(
        actorId: 'player',
        binding: CinematicActorBinding(
          actorId: 'player',
          kind: CinematicActorBindingKind.player,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'player',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_player_spawn',
        ),
        movementTargets: [_target('target_player_spawn')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_player_spawn',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_spawn',
          ),
        ],
      );

      final appearance = model.actorById('player')!.appearance;
      expect(
          appearance.status, CinematicActorPreviewAppearanceStatus.spriteReady);
      expect(appearance.characterId, 'hero_character');
    });

    test('falls back to placeholder for player without default character', () {
      final model = _singleActorModel(
        actorId: 'player',
        binding: CinematicActorBinding(
          actorId: 'player',
          kind: CinematicActorBindingKind.player,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'player',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_player_spawn',
        ),
        movementTargets: [_target('target_player_spawn')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_player_spawn',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_spawn',
          ),
        ],
        project: _project(defaultPlayerCharacterId: null),
      );

      final actor = model.actorById('player')!;
      expect(
        actor.appearance.status,
        CinematicActorPreviewAppearanceStatus.placeholderOnly,
      );
      expect(actor.renderHint, CinematicActorPreviewRenderHint.placeholder);
    });

    test('resolves from movement target bound to map entity', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_entity',
        ),
        movementTargets: [_target('target_entity')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_entity',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_spawn',
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(position.x, 2);
      expect(position.y, 3);
    });

    test(
        'resolves from movement target bound to map event when position exists',
        () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_event_arrival',
        ),
        movementTargets: [_target('target_event_arrival')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_event_arrival',
            kind: CinematicMovementTargetBindingKind.mapEvent,
            sourceId: 'event_arrival',
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(position.x, 9);
      expect(position.y, 5);
    });

    test('does not resolve abstract movement target to fake coordinates', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_abstract',
        ),
        movementTargets: [_target('target_abstract')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_abstract',
            kind: CinematicMovementTargetBindingKind.abstractPoint,
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.abstractOnly);
      expect(position.x, isNull);
      expect(position.y, isNull);
    });

    test('does not treat target_center as map coordinates', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_center',
        ),
        movementTargets: [_target('target_center')],
      );

      final position = model.actorById('actor')!.position;
      expect(
          position.status, CinematicActorPreviewPositionStatus.missingSource);
      expect(position.x, isNull);
      expect(position.y, isNull);
    });

    test('does not invent center map fallback for missing placement', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      );

      final position = model.actorById('actor')!.position;
      expect(
        position.status,
        CinematicActorPreviewPositionStatus.missingInitialPlacement,
      );
      expect(position.x, isNull);
      expect(position.y, isNull);
    });

    test('reports out of bounds position', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_outside',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
      );

      final actor = model.actorById('actor')!;
      expect(actor.position.status,
          CinematicActorPreviewPositionStatus.outOfMapBounds);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOutOfMapBounds,
        ),
      );
    });

    test('uses actorFace as static direction hint without playback', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        timelineSteps: [
          _actorFaceStep(actorId: 'actor', direction: 'left'),
          CinematicTimelineStep(
            id: 'move_actor',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'actor',
            targetId: 'target_exit',
            metadata: const {
              'authoring.source': 'cinematic-builder-v0',
              'authoring.kind': 'basicBlock',
              'authoring.block': 'actorMove',
            },
          ),
        ],
      );

      final actor = model.actorById('actor')!;
      expect(actor.direction, CinematicActorPreviewDirection.west);
      expect(actor.directionSource,
          CinematicActorPreviewDirectionSource.actorFace);
    });

    test('ignores actorMove for initial position', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_guard',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
        movementTargets: [_target('target_exit')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_exit',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_exit',
          ),
        ],
        timelineSteps: [
          CinematicTimelineStep(
            id: 'move_actor',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'actor',
            targetId: 'target_exit',
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.x, 6);
      expect(position.y, 4);
    });

    test('reports orphan actor binding', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor')],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_orphan',
                kind: CinematicActorBindingKind.player,
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOrphanBinding),
      );
    });

    test('reports orphan actor appearance binding', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor')],
          stageContext: CinematicStageContext(
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_orphan',
                characterId: 'hero_character',
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayOrphanAppearance,
        ),
      );
    });

    test('reports orphan initial placement', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor')],
          stageContext: CinematicStageContext(
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_orphan',
                kind: CinematicActorInitialPlacementKind.fromMapEntity,
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayOrphanPlacement,
        ),
      );
    });

    test('keeps model pure without Flutter Flame runtime imports', () {
      final sourceFiles = [
        File('lib/src/read_models/cinematic_actor_display_preview_model.dart'),
        File('test/cinematic_actor_display_preview_model_test.dart'),
      ];
      final forbiddenFragments = [
        'package:' 'flutter',
        'dart:' 'ui',
        'ui.' 'Image',
        'Can' 'vas',
        'Custom' 'Painter',
        'Wid' 'get',
        'Build' 'Context',
        'package:' 'flame',
        'Game' 'State',
        'map_' 'runtime',
        'map_' 'editor',
      ];

      for (final file in sourceFiles) {
        final content = file.readAsStringSync();
        for (final fragment in forbiddenFragments) {
          expect(
            content.contains(fragment),
            isFalse,
            reason: '${file.path} must not contain $fragment',
          );
        }
      }
    });

    test('resolves actor position from stage point', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor_professor')],
          stageContext: CinematicStageContext(
            stagePoints: [
              CinematicStagePoint(
                id: 'point_a',
                label: 'Point A',
                x: 4.2,
                y: 6.8,
              ),
            ],
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'point_a',
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      final actor = model.actorById('actor_professor')!;
      expect(actor.position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(actor.position.x, 4); // 4.2 rounded
      expect(actor.position.y, 7); // 6.8 rounded
      expect(actor.position.sourceId, 'point_a');
      expect(actor.position.sourceLabel, 'Point A');
      expect(actor.position.sourceKind, CinematicActorPreviewPositionSourceKind.stagePoint);
    });

    test('actor display reports missing stage point and does not invent coordinates', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor_professor')],
          stageContext: CinematicStageContext(
            stagePoints: const [],
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_professor',
                kind: CinematicActorBindingKind.cinematicOnly,
              ),
            ],
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_professor',
                kind: CinematicActorInitialPlacementKind.stagePoint,
                stagePointId: 'point_a',
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      final actor = model.actorById('actor_professor')!;
      expect(actor.position.status, CinematicActorPreviewPositionStatus.missingSource);
      expect(actor.position.x, isNull);
      expect(actor.position.y, isNull);
      expect(
        actor.diagnostics.map((d) => d.code),
        contains(CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingStagePoint),
      );
    });
  });
}

CinematicActorDisplayPreviewModel _singleActorModel({
  required String actorId,
  required CinematicActorBinding binding,
  CinematicActorInitialPlacement? placement,
  CinematicActorAppearanceBinding? appearance,
  List<CinematicMovementTargetRef> movementTargets = const [],
  List<CinematicMovementTargetBinding> movementTargetBindings = const [],
  List<CinematicTimelineStep> timelineSteps = const [],
  ProjectManifest? project,
}) {
  return buildCinematicActorDisplayPreviewModel(
    cinematic: _cinematic(
      requiredActors: [_actor(actorId)],
      movementTargets: movementTargets,
      timelineSteps: timelineSteps,
      stageContext: CinematicStageContext(
        actorBindings: [binding],
        actorAppearanceBindings: [
          if (appearance != null) appearance,
        ],
        initialPlacements: [
          if (placement != null) placement,
        ],
        movementTargetBindings: movementTargetBindings,
      ),
    ),
    project: project ?? _project(),
    stageMap: _stageMap(),
    mapData: _mapData(),
  );
}

CinematicActorRef _actor(String actorId, {String? label}) {
  return CinematicActorRef(actorId: actorId, label: label);
}

CinematicMovementTargetRef _target(String targetId) {
  return CinematicMovementTargetRef(targetId: targetId, label: targetId);
}

CinematicAsset _cinematic({
  List<CinematicActorRef> requiredActors = const [],
  List<CinematicMovementTargetRef> movementTargets = const [],
  CinematicStageContext? stageContext,
  List<CinematicTimelineStep> timelineSteps = const [],
}) {
  return CinematicAsset(
    id: 'cinematic_test',
    title: 'Cinematic Test',
    mapId: 'map_lab',
    requiredActors: requiredActors,
    movementTargets: movementTargets,
    stageContext: stageContext,
    timeline: CinematicTimeline(steps: timelineSteps),
  );
}

CinematicTimelineStep _actorFaceStep({
  required String actorId,
  required String direction,
}) {
  return CinematicTimelineStep(
    id: 'face_$actorId',
    kind: CinematicTimelineStepKind.actorFace,
    actorId: actorId,
    metadata: {
      'authoring.source': 'cinematic-builder-v0',
      'authoring.kind': 'basicBlock',
      'authoring.block': 'actorFace',
      'actor.direction': direction,
    },
  );
}

ProjectManifest _project(
    {String? defaultPlayerCharacterId = 'hero_character'}) {
  return ProjectManifest(
    name: 'Test Project',
    maps: [_stageMap()],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'tilesets/characters.png',
      ),
    ],
    characters: [
      _character('hero_character', 'Hero'),
      _character('guard_character', 'Guard'),
      _character('liza_character', 'Liza'),
      _character(
        'character_without_tileset',
        'Missing Tileset',
        tilesetId: '',
      ),
      _character(
        'character_without_idle',
        'Missing Idle',
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: EntityFacing.south,
            frames: [_frame()],
          ),
        ],
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_guard',
        name: 'Guard Trainer',
        trainerClass: 'Guard',
        characterId: 'guard_character',
      ),
    ],
    settings: ProjectSettings(
      defaultPlayerCharacterId: defaultPlayerCharacterId,
    ),
  );
}

ProjectCharacterEntry _character(
  String id,
  String name, {
  String tilesetId = 'characters',
  List<CharacterAnimation>? animations,
}) {
  return ProjectCharacterEntry(
    id: id,
    name: name,
    tilesetId: tilesetId,
    animations: animations ??
        [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [_frame()],
          ),
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.east,
            frames: [_frame(x: 1)],
          ),
        ],
  );
}

CharacterAnimationFrame _frame({int x = 0, int y = 0}) {
  return CharacterAnimationFrame(
    source: TilesetSourceRect(x: x, y: y),
  );
}

ProjectMapEntry _stageMap() {
  return const ProjectMapEntry(
    id: 'map_lab',
    name: 'Research Lab',
    relativePath: 'maps/research_lab.json',
  );
}

MapData _mapData() {
  return const MapData(
    id: 'map_lab',
    name: 'Research Lab',
    size: GridSize(width: 12, height: 10),
    entities: [
      MapEntity(
        id: 'entity_spawn',
        name: 'Player spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 3),
        spawn: MapEntitySpawnData(spawnKey: 'default'),
      ),
      MapEntity(
        id: 'entity_guard',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 6, y: 4),
        npc: MapEntityNpcData(
          displayName: 'Guard',
          facing: EntityFacing.east,
          characterId: 'guard_character',
        ),
      ),
      MapEntity(
        id: 'entity_exit',
        name: 'Exit',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 10, y: 8),
      ),
      MapEntity(
        id: 'entity_outside',
        name: 'Outside',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 16, y: 4),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_arrival',
        title: 'Arrival',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'ground', x: 9, y: 5),
      ),
    ],
  );
}
