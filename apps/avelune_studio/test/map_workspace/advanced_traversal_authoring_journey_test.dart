import 'package:avelune_studio/presentation/features/map_workspace/traversal_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('a ledge jump is described with the values the game applies', () {
    expect(
      ledgeJumpSummary(BorderJumpBehavior(durationMs: 500, peakHeightPx: 24)),
      'Saut de 2 cases en 0,5 s, hauteur 24 px. Le rebord ne se franchit que depuis le côté choisi ; l’autre côté reste bloquant.',
    );
  });

  test('a 3D ledge is described with its direction and applied values', () {
    expect(
      spatialLedgeSummary(
        SpatialLedge(
          id: 'l',
          x: 26,
          z: 6,
          direction: SpatialRampDirection.east,
        ),
      ),
      'Saut de 2 cases vers la droite en 0,4 s, hauteur 0,65 case ; '
      'le retour est bloqué.',
    );
  });

  test('a platform duration reads in seconds without losing milliseconds', () {
    expect(traversalDurationLabel(1500), '1,5 s');
    expect(traversalDurationLabel(1250), '1,25 s');
    expect(traversalDurationLabel(30000), '30 s');
    expect(traversalDurationLabel(100), '0,1 s');
  });
}
