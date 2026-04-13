import 'package:map_core/map_core.dart';

import 'direction.dart';

/// État joueur : **vérité moteur** = [playerPositionPx] (coin haut-gauche sprite monde).
///
/// [pos] est la projection grille dérivée des **pieds** (voir
/// [PlayerCollisionConventionsV1.projectFeetAnchorToCell]) : sert warps, triggers,
/// interactions, pathfinding PNJ scripté — **pas** la primitive de collision déplacement.
class GameplayPlayerState {
  /// Spawn sur une cellule auteur : calcule [playerPositionPx] + projection [pos].
  factory GameplayPlayerState.fromGridSpawn({
    required GridPos cell,
    required Direction facing,
    MovementMode movementMode = MovementMode.walk,
    required int tileWidthPx,
    required int tileHeightPx,
    required int mapWidthCells,
    required int mapHeightCells,
    int spriteWidthPx = PlayerCollisionConventionsV1.defaultSpriteWidthPx,
    int spriteHeightPx = PlayerCollisionConventionsV1.defaultSpriteHeightPx,
  }) {
    final tw = tileWidthPx <= 0 ? 16 : tileWidthPx;
    final th = tileHeightPx <= 0 ? 16 : tileHeightPx;
    final topLeft = PlayerCollisionConventionsV1.playerSpriteTopLeftFromSpawnCell(
      cellX: cell.x,
      cellY: cell.y,
      tileWidthPx: tw,
      tileHeightPx: th,
      spriteWidthPx: spriteWidthPx,
      spriteHeightPx: spriteHeightPx,
    );
    final hitbox = PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
      spriteTopLeftPx: topLeft,
      spriteWidthPx: spriteWidthPx,
      spriteHeightPx: spriteHeightPx,
    );
    final gridPos = PlayerCollisionConventionsV1.projectFeetAnchorToCell(
      playerCollisionRectPx: hitbox,
      tileWidthPx: tw,
      tileHeightPx: th,
      mapWidthCells: mapWidthCells,
      mapHeightCells: mapHeightCells,
    );
    return GameplayPlayerState(
      pos: gridPos,
      playerPositionPx: topLeft,
      facing: facing,
      movementMode: movementMode,
      playerSpriteWidthPx: spriteWidthPx,
      playerSpriteHeightPx: spriteHeightPx,
    );
  }

  const GameplayPlayerState({
    required this.pos,
    required this.playerPositionPx,
    required this.facing,
    this.movementMode = MovementMode.walk,
    this.playerSpriteWidthPx = PlayerCollisionConventionsV1.defaultSpriteWidthPx,
    this.playerSpriteHeightPx = PlayerCollisionConventionsV1.defaultSpriteHeightPx,
  });

  /// Cellule grille alignée sur l’ancrage pieds (systèmes encore indexés grille).
  final GridPos pos;

  /// Coin haut-gauche du rectangle de rendu sprite dans le repère monde pixels.
  final PixelPosition playerPositionPx;

  final Direction facing;
  final MovementMode movementMode;

  final int playerSpriteWidthPx;
  final int playerSpriteHeightPx;

  /// Hitbox déplacement V1 (12×8), dérivée de [playerPositionPx].
  PixelRect get playerCollisionRectPx =>
      PlayerCollisionConventionsV1.playerCollisionRectFromSpriteTopLeft(
        spriteTopLeftPx: playerPositionPx,
        spriteWidthPx: playerSpriteWidthPx,
        spriteHeightPx: playerSpriteHeightPx,
      );

  GameplayPlayerState copyWith({
    GridPos? pos,
    PixelPosition? playerPositionPx,
    Direction? facing,
    MovementMode? movementMode,
    int? playerSpriteWidthPx,
    int? playerSpriteHeightPx,
  }) {
    return GameplayPlayerState(
      pos: pos ?? this.pos,
      playerPositionPx: playerPositionPx ?? this.playerPositionPx,
      facing: facing ?? this.facing,
      movementMode: movementMode ?? this.movementMode,
      playerSpriteWidthPx: playerSpriteWidthPx ?? this.playerSpriteWidthPx,
      playerSpriteHeightPx: playerSpriteHeightPx ?? this.playerSpriteHeightPx,
    );
  }
}
