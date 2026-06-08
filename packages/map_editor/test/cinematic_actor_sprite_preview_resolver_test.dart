import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart';

void main() {
  group('Cinematic Actor Sprite Preview Resolver', () {
    test('resolves cinematic only actor sprite preview plan from character idle frame', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 2, y: 3, width: 1, height: 2),
              ),
            ],
          ),
        ],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.actorId, 'actor_prof');
      expect(planActor.status, CinematicActorSpriteStatus.spriteReady);
      expect(planActor.placeholderFallback, isFalse);
      expect(planActor.spriteRef, isNotNull);
      expect(planActor.spriteRef!.tilesetId, 'char_tileset_id');
      expect(planActor.spriteRef!.frameWidthTiles, 1);
      expect(planActor.spriteRef!.frameHeightTiles, 2);
      expect(planActor.spriteRef!.sourceTileRect.x, 2);
      expect(planActor.spriteRef!.sourceTileRect.y, 3);
      expect(planActor.depthHint.visualBottom, 12.0);
      expect(planActor.depthHint.anchorTileX, 5.5);
      expect(plan.hasReadySprites, isTrue);
      expect(plan.hasFallbacks, isFalse);
      expect(plan.hasErrors, isFalse);
    });

    test('resolves player actor using settings default character ID', () {
      const character = ProjectCharacterEntry(
        id: 'char_player',
        name: 'Hero',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              ),
            ],
          ),
        ],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
        settings: ProjectSettings(
          defaultPlayerCharacterId: 'char_player',
        ),
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_hero',
        label: 'Hero',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.player,
        bindingKind: CinematicActorBindingKind.player,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 4,
          y: 6,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_player',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.spriteReady);
      expect(planActor.placeholderFallback, isFalse);
      expect(planActor.spriteRef!.characterId, 'char_player');
    });

    test('resolves direction fallback warning when requested direction idle is missing', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [
          // Idle is only available facing North
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.north,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 10, y: 10, width: 1, height: 2),
              ),
            ],
          ),
        ],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south, // Requested south, but we only have north
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      // Should resolve to spriteReady using directional fallback
      expect(planActor.status, CinematicActorSpriteStatus.spriteReady);
      expect(planActor.placeholderFallback, isFalse);
      expect(planActor.spriteRef!.sourceTileRect.x, 10);

      // Verify that diagnostic warning is added
      final warnings = planActor.diagnostics.where(
        (d) => d.code == CinematicActorDisplayPreviewDiagnosticCode.actorDisplayDirectionFallback,
      );
      expect(warnings, hasLength(1));
      expect(warnings.first.severity, CinematicActorDisplayPreviewDiagnosticSeverity.warning);
    });

    test('returns missingDirectionFrame when idle animation for requested direction has no frames', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [], // Empty frames list
          ),
        ],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.missingDirectionFrame);
      expect(planActor.placeholderFallback, isTrue);
      expect(planActor.spriteRef, isNull);

      final warnings = planActor.diagnostics.where(
        (d) => d.code == CinematicActorDisplayPreviewDiagnosticCode.actorDisplaySpriteUnavailable,
      );
      expect(warnings, hasLength(1));
    });

    test('returns missingIdleAnimation when character has no idle animations at all', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [], // No animations
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.missingIdleAnimation);
      expect(planActor.placeholderFallback, isTrue);

      final warnings = planActor.diagnostics.where(
        (d) => d.code == CinematicActorDisplayPreviewDiagnosticCode.actorDisplayCharacterMissingIdleAnimation,
      );
      expect(warnings, hasLength(1));
    });

    test('returns missingCharacter when character is not found in manifest', () {
      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [],
        characters: [], // No characters
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'non_existent_char',
          tilesetId: 'some_tileset',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.missingCharacter);
      expect(planActor.placeholderFallback, isTrue);

      final warnings = planActor.diagnostics.where(
        (d) => d.code == CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnknownCharacter,
      );
      expect(warnings, hasLength(1));
    });

    test('returns missingTileset when character tileset is not found in manifest', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'missing_tileset_id', // Does not exist in tilesets
        frameWidth: 1,
        frameHeight: 2,
        animations: [],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [], // No tilesets
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'missing_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.missingTileset);
      expect(planActor.placeholderFallback, isTrue);

      final warnings = planActor.diagnostics.where(
        (d) => d.code == CinematicActorDisplayPreviewDiagnosticCode.actorDisplayCharacterMissingTileset,
      );
      expect(warnings, hasLength(1));
    });

    test('returns invalidSourceRect when frame source coordinates are negative', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: -1, y: 0, width: 1, height: 2), // Invalid X
              ),
            ],
          ),
        ],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.invalidSourceRect);
      expect(planActor.placeholderFallback, isTrue);

      final warnings = planActor.diagnostics.where(
        (d) => d.code == CinematicActorDisplayPreviewDiagnosticCode.actorDisplaySpriteUnavailable,
      );
      expect(warnings, hasLength(1));
    });

    test('resolves hidden actors without generating errors', () {
      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [],
        characters: [],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.hidden, // Hidden
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.hidden);
      expect(planActor.placeholderFallback, isFalse);
    });

    test('keeps visual element actors as placeholder only in sprite preview plan', () {
      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [],
        characters: [],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.placeholder,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.placeholderFallback);
      expect(planActor.placeholderFallback, isTrue);
    });

    test('resolves map entity npc actor sprite from display model character id', () {
      const character = ProjectCharacterEntry(
        id: 'char_professor',
        name: 'Professor',
        tilesetId: 'char_tileset_id',
        frameWidth: 1,
        frameHeight: 2,
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [
              CharacterAnimationFrame(
                source: TilesetSourceRect(x: 2, y: 3, width: 1, height: 2),
              ),
            ],
          ),
        ],
      );

      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'char_tileset_id',
            name: 'Char Tileset',
            relativePath: 'char.png',
          ),
        ],
        characters: [character],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_npc',
        label: 'NPC',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.mapEntity,
        bindingKind: CinematicActorBindingKind.mapEntity,
        bindingSourceId: 'npc_1',
        bindingSourceLabel: 'NPC 1',
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.mapEntityFacing,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final plan = buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(plan.actors, hasLength(1));
      final planActor = plan.actors.first;
      expect(planActor.status, CinematicActorSpriteStatus.spriteReady);
      expect(planActor.spriteRef!.characterId, 'char_professor');
    });

    test('does not mutate project or map data when building sprite preview plan', () {
      const project = ProjectManifest(
        surfaceCatalog: ProjectSurfaceCatalog.empty(),
        name: 'test_project',
        maps: [],
        tilesets: [],
        characters: [],
      );

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.placeholder,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final projectJsonBefore = project.toJson();
      final modelActorsBefore = model.actors.map((a) => a.actorId).toList();

      buildCinematicActorSpritePreviewPlan(
        actorDisplayModel: model,
        project: project,
      );

      expect(project.toJson(), projectJsonBefore);
      expect(model.actors.map((a) => a.actorId).toList(), modelActorsBefore);
    });
  });
}
