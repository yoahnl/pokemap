import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

/// BETA-TRN-001 — le « ! » est au-dessus de la tête, et il se voit.
///
/// L'objectif signé du ticket dit « affiche un point d'exclamation au-dessus de
/// sa tête ». Ses tests vérifiaient que l'emote EXISTE — un sabotage la
/// supprimant faisait tomber deux tests — mais rien ne regardait sa taille ni
/// sa position. Sur appareil réel, la bulle était posée sur le chapeau du
/// dresseur et faisait une demi-tuile.
///
/// Les deux règles sont des fractions de la hauteur du personnage : elles
/// restent donc justes quels que soient le sprite et la taille de tuile, ce
/// qu'une constante en unités monde ne pouvait pas garantir.
void main() {
  group('placement d’une emote au-dessus de la tête', () {
    test('le bas de la bulle passe au-dessus du sommet du crâne', () {
      // Un acteur de 32x48 centré en (100, 100) : son sommet est à 100 - 24.
      const actorCentreY = 100.0;
      const actorHeight = 48.0;

      final bottomY = cinematicEmoteOverlayBottomY(
        actorCentreY: actorCentreY,
        actorHeight: actorHeight,
      );

      expect(
        bottomY,
        lessThan(actorCentreY - actorHeight / 2),
        reason: 'la bulle chevauchait la tête : son bas était 22 unités au'
            ' dessus du CENTRE, soit 2 unités sous le sommet du crâne',
      );
    });

    test('l’ancien décalage de 22 unités serait refusé par la règle', () {
      // Le test qui aurait attrapé le défaut : 22 depuis le centre d'un sprite
      // de 48 ne sort pas de la tête.
      const actorCentreY = 100.0;
      const actorHeight = 48.0;
      const legacyBottomY = actorCentreY - 22;

      expect(legacyBottomY, greaterThan(actorCentreY - actorHeight / 2));
      expect(
        cinematicEmoteOverlayBottomY(
          actorCentreY: actorCentreY,
          actorHeight: actorHeight,
        ),
        lessThan(legacyBottomY),
      );
    });

    test('un sprite plus grand pousse la bulle plus haut', () {
      final small = cinematicEmoteOverlayBottomY(
        actorCentreY: 0,
        actorHeight: 48,
      );
      final tall = cinematicEmoteOverlayBottomY(
        actorCentreY: 0,
        actorHeight: 96,
      );

      expect(
        tall,
        lessThan(small),
        reason: 'la règle est une fraction de la hauteur, pas une constante',
      );
    });
  });

  group('taille d’une emote', () {
    test('un cadre de 16 sur un personnage de 48 est agrandi', () {
      // C'est le cas réel : les atlas du projet sont découpés en 16x16 et les
      // cartes sont en tuiles de 32.
      final scale = cinematicEmoteTargetScale(
        naturalHeight: 16,
        actorHeight: 48,
      );

      expect(scale, greaterThan(1.0));
      // 48 * 0.6 = 28,8 sur une hauteur naturelle de 16.
      expect(scale, closeTo(1.8, 1e-9));
      expect(
        16 * scale,
        greaterThan(16.0),
        reason: 'à l’échelle naturelle la bulle faisait une demi-tuile',
      );
    });

    test('un atlas déjà généreux n’est jamais rétréci', () {
      // La règle agrandit, elle ne rapetisse pas : un auteur qui fournit une
      // grande emote garde sa taille.
      expect(
        cinematicEmoteTargetScale(naturalHeight: 64, actorHeight: 48),
        1.0,
      );
    });

    test('une hauteur inconnue retombe sur l’échelle naturelle', () {
      // Un TextComponent peut n'avoir aucune taille avant son montage : la
      // règle ne doit pas produire une division par zéro ni une bulle géante.
      expect(cinematicEmoteTargetScale(naturalHeight: 0, actorHeight: 48), 1.0);
      expect(cinematicEmoteTargetScale(naturalHeight: 16, actorHeight: 0), 1.0);
    });

    test('le pop-in part plus petit que la cible et y arrive', () {
      final target = cinematicEmoteTargetScale(
        naturalHeight: 16,
        actorHeight: 48,
      );
      final start = target * cinematicEmotePopInFactor;

      expect(start, lessThan(target));
      expect(
        start,
        greaterThan(0),
        reason: 'une emote qui démarre à zéro clignote au montage',
      );
    });
  });
}
