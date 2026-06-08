import 'package:map_core/map_core.dart';
import 'cinematic_actor_sprite_preview_plan.dart';

EntityFacing? _mapFacing(CinematicActorPreviewDirection direction) {
  return switch (direction) {
    CinematicActorPreviewDirection.north => EntityFacing.north,
    CinematicActorPreviewDirection.south => EntityFacing.south,
    CinematicActorPreviewDirection.east => EntityFacing.east,
    CinematicActorPreviewDirection.west => EntityFacing.west,
    CinematicActorPreviewDirection.unknown => null,
  };
}

CinematicActorSpritePreviewPlan buildCinematicActorSpritePreviewPlan({
  required CinematicActorDisplayPreviewModel actorDisplayModel,
  required ProjectManifest project,
}) {
  final List<CinematicActorSpritePreviewActor> resolvedActors = [];
  final List<CinematicActorDisplayPreviewDiagnostic> newlyGenerated = [];

  for (final actor in actorDisplayModel.actors) {
    final List<CinematicActorDisplayPreviewDiagnostic> actorDiagnostics =
        List.from(actor.diagnostics);
    final bindingKind = actor.bindingKind ?? CinematicActorBindingKind.unbound;
    final pos = GridPos(
      x: actor.position.x ?? 0,
      y: actor.position.y ?? 0,
    );

    CinematicActorSpriteStatus status = CinematicActorSpriteStatus.placeholderFallback;
    bool placeholderFallback = true;
    CinematicActorSpriteRef? spriteRef;
    ProjectCharacterEntry? resolvedCharacter;

    // 1. Check if actor is hidden
    if (actor.renderHint == CinematicActorPreviewRenderHint.hidden) {
      status = CinematicActorSpriteStatus.hidden;
      placeholderFallback = false;
    }
    // 2. Check if position is unresolved
    else if (!actor.position.isResolved) {
      status = CinematicActorSpriteStatus.placeholderFallback;
      placeholderFallback = true;
    }
    // 3. Handle appearance-based status or resolution
    else {
      final appStatus = actor.appearance.status;
      final characterId = actor.appearance.characterId?.trim();

      // Look up character if ID is provided, to use for height/depth metrics
      if (characterId != null && characterId.isNotEmpty) {
        for (final c in project.characters) {
          if (c.id.trim() == characterId) {
            resolvedCharacter = c;
            break;
          }
        }
      }

      if (appStatus == CinematicActorPreviewAppearanceStatus.notRequired) {
        status = CinematicActorSpriteStatus.hidden;
        placeholderFallback = false;
      } else if (appStatus == CinematicActorPreviewAppearanceStatus.unsupported) {
        status = CinematicActorSpriteStatus.unsupported;
        placeholderFallback = true;
      } else if (appStatus == CinematicActorPreviewAppearanceStatus.placeholderOnly) {
        status = CinematicActorSpriteStatus.placeholderFallback;
        placeholderFallback = true;
      } else if (appStatus == CinematicActorPreviewAppearanceStatus.missingCharacter) {
        status = CinematicActorSpriteStatus.missingCharacter;
        placeholderFallback = true;
      } else if (appStatus == CinematicActorPreviewAppearanceStatus.missingTileset) {
        status = CinematicActorSpriteStatus.missingTileset;
        placeholderFallback = true;
      } else if (appStatus == CinematicActorPreviewAppearanceStatus.missingIdleAnimation) {
        status = CinematicActorSpriteStatus.missingIdleAnimation;
        placeholderFallback = true;
      } else {
        // appStatus == spriteReady, attempt symbolic resolution of the sprite
        if (resolvedCharacter == null) {
          status = CinematicActorSpriteStatus.missingCharacter;
          placeholderFallback = true;
          final diag = CinematicActorDisplayPreviewDiagnostic(
            code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnknownCharacter,
            severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
            message: 'Character "$characterId" not found in project manifest.',
            actorId: actor.actorId,
            sourceId: characterId,
          );
          actorDiagnostics.add(diag);
          newlyGenerated.add(diag);
        } else {
          final tilesetId = resolvedCharacter.tilesetId.trim();
          bool tilesetExists = false;
          for (final t in project.tilesets) {
            if (t.id.trim() == tilesetId) {
              tilesetExists = true;
              break;
            }
          }

          if (tilesetId.isEmpty || !tilesetExists) {
            status = CinematicActorSpriteStatus.missingTileset;
            placeholderFallback = true;
            final diag = CinematicActorDisplayPreviewDiagnostic(
              code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplayCharacterMissingTileset,
              severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
              message: 'Tileset "$tilesetId" not found in project tilesets for character "${resolvedCharacter.name}".',
              actorId: actor.actorId,
              sourceId: resolvedCharacter.id,
            );
            actorDiagnostics.add(diag);
            newlyGenerated.add(diag);
          } else {
            // Find preferred facing mapping
            final preferredFacing = _mapFacing(actor.direction);

            // Filter animations to idle state only
            final idleAnimations = resolvedCharacter.animations
                .where((anim) => anim.state == CharacterAnimationState.idle)
                .toList();

            // Find all exploitable idles (with frames)
            final exploitableIdles = idleAnimations
                .where((anim) => anim.frames.isNotEmpty)
                .toList();

            CharacterAnimation? selectedAnimation;
            bool directionFallback = false;

            if (exploitableIdles.isNotEmpty) {
              for (final anim in exploitableIdles) {
                if (preferredFacing != null && anim.direction == preferredFacing) {
                  selectedAnimation = anim;
                  break;
                }
              }
              if (selectedAnimation == null) {
                selectedAnimation = exploitableIdles.first;
                directionFallback = true;
              }
            }

            if (selectedAnimation == null) {
              // Check if any empty idle animation matching preferred direction exists
              CharacterAnimation? emptyPreferredIdle;
              for (final anim in idleAnimations) {
                if (preferredFacing != null && anim.direction == preferredFacing) {
                  emptyPreferredIdle = anim;
                  break;
                }
              }

              if (emptyPreferredIdle != null) {
                status = CinematicActorSpriteStatus.missingDirectionFrame;
                placeholderFallback = true;
                final diag = CinematicActorDisplayPreviewDiagnostic(
                  code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplaySpriteUnavailable,
                  severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
                  message: 'Idle animation for requested direction ${actor.direction} has no frames.',
                  actorId: actor.actorId,
                  sourceId: resolvedCharacter.id,
                );
                actorDiagnostics.add(diag);
                newlyGenerated.add(diag);
              } else {
                status = CinematicActorSpriteStatus.missingIdleAnimation;
                placeholderFallback = true;
                final diag = CinematicActorDisplayPreviewDiagnostic(
                  code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplayCharacterMissingIdleAnimation,
                  severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
                  message: 'No exploitable idle animation found for character.',
                  actorId: actor.actorId,
                  sourceId: resolvedCharacter.id,
                );
                actorDiagnostics.add(diag);
                newlyGenerated.add(diag);
              }
            } else {
              final frame = selectedAnimation.frames.first;
              if (frame.source.x < 0 || frame.source.y < 0) {
                status = CinematicActorSpriteStatus.invalidSourceRect;
                placeholderFallback = true;
                final diag = CinematicActorDisplayPreviewDiagnostic(
                  code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplaySpriteUnavailable,
                  severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
                  message: 'Invalid source tile rectangle coordinates: (${frame.source.x}, ${frame.source.y}).',
                  actorId: actor.actorId,
                  sourceId: resolvedCharacter.id,
                );
                actorDiagnostics.add(diag);
                newlyGenerated.add(diag);
              } else {
                status = CinematicActorSpriteStatus.spriteReady;
                placeholderFallback = false;

                spriteRef = CinematicActorSpriteRef(
                  characterId: resolvedCharacter.id,
                  tilesetId: tilesetId,
                  sourceTileRect: TilesetSourceRect(
                    x: frame.source.x,
                    y: frame.source.y,
                    width: resolvedCharacter.frameWidth,
                    height: resolvedCharacter.frameHeight,
                  ),
                  frameWidthTiles: resolvedCharacter.frameWidth,
                  frameHeightTiles: resolvedCharacter.frameHeight,
                  direction: actor.direction,
                );

                if (directionFallback) {
                  final diag = CinematicActorDisplayPreviewDiagnostic(
                    code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplayDirectionFallback,
                    severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
                    message: 'Idle animation for requested direction ${actor.direction} not found, using fallback.',
                    actorId: actor.actorId,
                    sourceId: resolvedCharacter.id,
                  );
                  actorDiagnostics.add(diag);
                  newlyGenerated.add(diag);
                }
              }
            }
          }
        }
      }
    }

    // 4. Compute Depth Hint
    final frameWidthTiles = resolvedCharacter?.frameWidth ?? 1;
    final frameHeightTiles = resolvedCharacter?.frameHeight ?? 2;
    final tileX = actor.position.x ?? 0;
    final tileY = actor.position.y ?? 0;

    final depthHint = CinematicActorSpriteDepthHint(
      tileX: tileX,
      tileY: tileY,
      anchorTileX: tileX + frameWidthTiles / 2.0,
      anchorTileY: (tileY + frameHeightTiles).toDouble(),
      visualBottom: (tileY + frameHeightTiles).toDouble(),
      footprintWidthTiles: frameWidthTiles,
      footprintHeightTiles: frameHeightTiles,
      preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
    );

    resolvedActors.add(
      CinematicActorSpritePreviewActor(
        actorId: actor.actorId,
        actorLabel: actor.label,
        bindingKind: bindingKind,
        position: pos,
        direction: actor.direction,
        status: status,
        spriteRef: spriteRef,
        placeholderFallback: placeholderFallback,
        depthHint: depthHint,
        diagnostics: actorDiagnostics,
      ),
    );
  }

  final allDiagnostics = <CinematicActorDisplayPreviewDiagnostic>[
    ...actorDisplayModel.diagnostics,
    ...newlyGenerated,
  ];

  return CinematicActorSpritePreviewPlan(
    actors: resolvedActors,
    diagnostics: allDiagnostics,
  );
}
