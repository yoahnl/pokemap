import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

/// Vérifie si le joueur est dans la ligne de vision (LoS) d'un NPC.
///
/// **Critères de détection :**
/// 1. Joueur aligné avec le facing du NPC (axe cardinal uniquement)
/// 2. Distance Manhattan <= [lineOfSightRange]
/// 3. Aucun obstacle entre le NPC et le joueur (cases intermédiaires uniquement)
///
/// **Comportement MVP assumé :**
/// - Axe cardinal uniquement (nord/sud/est/ouest)
/// - Aucune diagonale
/// - Raycast depuis [npcPos] vers [playerPos]
/// - Obstacles vérifiés via [world.isBlocked()] sur les cases STRICTEMENT entre
///   le NPC et le joueur (exclut la case du NPC et la case du joueur)
/// - Si adjacent : pas d'obstacle testé (retourne true si autres critères OK)
///
/// Retourne `true` si tous les critères sont satisfaits.
bool checkLineOfSight({
  required GridPos npcPos,
  required EntityFacing npcFacing,
  required int lineOfSightRange,
  required GridPos playerPos,
  required GameplayWorldState world,
}) {
  // Désactivé si range <= 0
  if (lineOfSightRange <= 0) return false;

  final dx = playerPos.x - npcPos.x;
  final dy = playerPos.y - npcPos.y;

  // 1. Vérifier alignement avec le facing du NPC
  final direction = npcFacing.asDirection;
  final expectedDx = direction.dx;
  final expectedDy = direction.dy;

  // Le joueur doit être dans la même direction que le facing
  // et dans le bon sens (dx/dy de même signe)
  if (expectedDx != 0) {
    // Axe horizontal (est/ouest)
    if (dy != 0) return false;  // Doit être sur le même axe Y
    if (dx * expectedDx <= 0) return false;  // Doit être dans le bon sens
  } else {
    // Axe vertical (nord/sud)
    if (dx != 0) return false;  // Doit être sur le même axe X
    if (dy * expectedDy <= 0) return false;  // Doit être dans le bon sens
  }

  // 2. Vérifier distance
  final distance = dx.abs() + dy.abs();  // Distance Manhattan
  if (distance > lineOfSightRange) return false;

  // 3. Vérifier obstacles (cases STRICTEMENT entre NPC et joueur)
  if (_hasObstacleBetween(
    from: npcPos,
    to: playerPos,
    dx: dx,
    dy: dy,
    world: world,
  )) {
    return false;
  }

  return true;
}

/// Vérifie les obstacles ENTRE [from] et [to].
///
/// **Ne teste NI la case du NPC ([from]), NI la case du joueur ([to]).**
/// Teste uniquement les cases strictement intermédiaires.
///
/// Si adjacent (distance <= 1), retourne false (pas d'obstacle possible).
bool _hasObstacleBetween({
  required GridPos from,
  required GridPos to,
  required int dx,
  required int dy,
  required GameplayWorldState world,
}) {
  final distance = dx.abs() + dy.abs();

  // Si adjacent, pas d'obstacle possible entre les deux
  if (distance <= 1) return false;

  // Déterminer le pas de progression
  final stepX = dx == 0 ? 0 : (dx > 0 ? 1 : -1);
  final stepY = dy == 0 ? 0 : (dy > 0 ? 1 : -1);

  // Tester chaque case ENTRE from et to
  // Commence APRÈS le NPC (i=1) et s'arrête AVANT le joueur (i < distance)
  var x = from.x + stepX;
  var y = from.y + stepY;

  for (var i = 1; i < distance; i++) {
    if (world.isBlocked(x, y)) return true;
    x += stepX;
    y += stepY;
  }

  return false;
}
