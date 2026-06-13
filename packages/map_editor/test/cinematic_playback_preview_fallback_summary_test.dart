import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_walking_animation_preview_resolver.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_playback_preview_fallback_summary.dart';

void main() {
  group('CinematicPlaybackPreviewFallbackSummary', () {
    test('stays hidden when playback is inactive or animation is ready', () {
      final inactive = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.partial,
        isPlaybackOverlayActive: false,
        walkingFrames: [_walkingFrame()],
        spritePreviewPlan: _spritePlan([
          _spriteActor(status: CinematicActorSpriteStatus.missingCharacter),
        ]),
      );

      expect(inactive.hasDetails, isFalse);
      expect(inactive.visibleMessages, isEmpty);

      final ready = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.ready,
        isPlaybackOverlayActive: true,
        walkingFrames: const [],
        spritePreviewPlan: _spritePlan([
          _spriteActor(status: CinematicActorSpriteStatus.spriteReady),
        ]),
      );

      expect(ready.hasDetails, isFalse);
      expect(ready.visibleMessages, isEmpty);
    });

    test('converts fallback reasons into no-code user messages', () {
      final summary = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.partial,
        isPlaybackOverlayActive: true,
        walkingFrames: [
          _walkingFrame(
            reason:
                CinematicActorWalkingAnimationFallbackReason.missingAnimation,
            kind: CinematicActorWalkingAnimationPreviewKind.run,
          ),
        ],
        spritePreviewPlan: _spritePlan([
          _spriteActor(status: CinematicActorSpriteStatus.spriteReady),
        ]),
      );

      expect(summary.hasDetails, isTrue);
      expect(summary.visibleMessages.single.label,
          'Lysa utilise une animation de secours : animation de marche indisponible.');
      expect(summary.visibleMessages.single.severity,
          CinematicPlaybackPreviewFallbackSeverity.warning);
      for (final token in const [
        'sourceRect',
        'tilesetId',
        'payload',
        'JSON',
        'actorId',
        'map_core',
      ]) {
        expect(summary.visibleMessages.single.label.contains(token), isFalse);
      }
    });

    test('deduplicates, ranks, and caps visible messages to three', () {
      final summary = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.partial,
        isPlaybackOverlayActive: true,
        walkingFrames: [
          _walkingFrame(
            actorId: 'actor_alpha',
            reason:
                CinematicActorWalkingAnimationFallbackReason.actorNotRenderable,
          ),
          _walkingFrame(
            actorId: 'actor_beta',
            reason:
                CinematicActorWalkingAnimationFallbackReason.missingCharacter,
          ),
          _walkingFrame(
            actorId: 'actor_gamma',
            reason: CinematicActorWalkingAnimationFallbackReason.emptyFrames,
          ),
          _walkingFrame(
            actorId: 'actor_delta',
            reason:
                CinematicActorWalkingAnimationFallbackReason.missingDirection,
          ),
          _walkingFrame(
            actorId: 'actor_beta',
            reason:
                CinematicActorWalkingAnimationFallbackReason.missingCharacter,
          ),
        ],
        spritePreviewPlan: _spritePlan([
          _spriteActor(
            actorId: 'actor_alpha',
            label: 'Alpha',
            status: CinematicActorSpriteStatus.unsupported,
          ),
          _spriteActor(
            actorId: 'actor_beta',
            label: 'Beta',
            status: CinematicActorSpriteStatus.missingCharacter,
          ),
          _spriteActor(
            actorId: 'actor_gamma',
            label: 'Gamma',
            status: CinematicActorSpriteStatus.missingIdleAnimation,
          ),
          _spriteActor(
            actorId: 'actor_delta',
            label: 'Delta',
            status: CinematicActorSpriteStatus.missingDirectionFrame,
          ),
        ]),
      );

      expect(summary.messages, hasLength(5));
      expect(summary.visibleMessages, hasLength(3));
      expect(summary.extraCount, 2);
      expect(summary.visibleMessages.first.severity,
          CinematicPlaybackPreviewFallbackSeverity.error);
    });

    test('explains empty partial and no-animation previews', () {
      final partial = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.partial,
        isPlaybackOverlayActive: true,
        walkingFrames: const [],
        spritePreviewPlan: _spritePlan([
          _spriteActor(status: CinematicActorSpriteStatus.hidden),
        ]),
      );
      expect(partial.visibleMessages.single.label,
          'Prévisualisation partielle : certains acteurs restent en pose fixe.');

      final none = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.none,
        isPlaybackOverlayActive: true,
        walkingFrames: const [],
        spritePreviewPlan: _spritePlan([
          _spriteActor(status: CinematicActorSpriteStatus.hidden),
        ]),
      );
      expect(none.visibleMessages.single.label,
          'Aucun acteur ne possède encore d’animation exploitable pour cette prévisualisation.');
    });

    test('stays hidden when no fallback source is available', () {
      final summary = buildCinematicPlaybackPreviewFallbackSummary(
        animationState: CinematicPlaybackPreviewAnimationState.none,
        isPlaybackOverlayActive: true,
        walkingFrames: const [],
        spritePreviewPlan: null,
      );

      expect(summary.hasDetails, isFalse);
      expect(summary.visibleMessages, isEmpty);
    });
  });
}

CinematicActorWalkingAnimationPreviewFrame _walkingFrame({
  String actorId = 'actor_lysa',
  CinematicActorWalkingAnimationPreviewKind kind =
      CinematicActorWalkingAnimationPreviewKind.walk,
  CinematicActorWalkingAnimationFallbackReason reason =
      CinematicActorWalkingAnimationFallbackReason.missingAnimation,
}) {
  return CinematicActorWalkingAnimationPreviewFrame(
    actorId: actorId,
    kind: kind,
    direction: EntityFacing.east,
    frameIndex: 0,
    frameDurationMs: 100,
    isMoving: true,
    isFallback: reason != CinematicActorWalkingAnimationFallbackReason.none,
    fallbackReason: reason,
    diagnostics: const [],
  );
}

CinematicActorSpritePreviewPlan _spritePlan(
  List<CinematicActorSpritePreviewActor> actors,
) {
  return CinematicActorSpritePreviewPlan(
    actors: actors,
    diagnostics: const [],
  );
}

CinematicActorSpritePreviewActor _spriteActor({
  String actorId = 'actor_lysa',
  String label = 'Lysa',
  required CinematicActorSpriteStatus status,
}) {
  return CinematicActorSpritePreviewActor(
    actorId: actorId,
    actorLabel: label,
    bindingKind: CinematicActorBindingKind.cinematicOnly,
    position: const GridPos(x: 4, y: 5),
    direction: CinematicActorPreviewDirection.east,
    status: status,
    spriteRef: status == CinematicActorSpriteStatus.spriteReady
        ? const CinematicActorSpriteRef(
            characterId: 'char_lysa',
            tilesetId: 'actor_tileset',
            sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
            frameWidthTiles: 2,
            frameHeightTiles: 2,
            direction: CinematicActorPreviewDirection.east,
          )
        : null,
    placeholderFallback: status != CinematicActorSpriteStatus.spriteReady,
    depthHint: const CinematicActorSpriteDepthHint(
      tileX: 4,
      tileY: 5,
      anchorTileX: 5,
      anchorTileY: 6,
      visualBottom: 6,
      footprintWidthTiles: 1,
      footprintHeightTiles: 1,
      preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
    ),
    diagnostics: const [],
  );
}
