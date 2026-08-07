import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/smart_tile_mutation_identity.dart';

void main() {
  const values = <String, Object?>{
    'mapId': 'm01',
    'layerId': 'riviere',
    'sequence': 1,
  };

  test('deux sessions ne partagent jamais une clé pour le même geste', () {
    // Le journal d'idempotence est persistant. Un compteur en mémoire repart à
    // zéro au redémarrage, donc le 1er geste de chaque session rejouait la clé
    // du 1er geste de la session précédente — avec d'autres cellules.
    expect(
      smartTileMutationIdentity(
        purpose: 'smart-tile-cell-gesture',
        sessionToken: 'session-a',
        values: values,
      ),
      isNot(
        smartTileMutationIdentity(
          purpose: 'smart-tile-cell-gesture',
          sessionToken: 'session-b',
          values: values,
        ),
      ),
    );
  });

  test('la clé reste stable dans une session', () {
    expect(
      smartTileMutationIdentity(
        purpose: 'smart-tile-cell-gesture',
        sessionToken: 'session-a',
        values: values,
      ),
      smartTileMutationIdentity(
        purpose: 'smart-tile-cell-gesture',
        sessionToken: 'session-a',
        values: values,
      ),
    );
  });

  test('deux gestes de la même session gardent des clés distinctes', () {
    expect(
      smartTileMutationIdentity(
        purpose: 'smart-tile-cell-gesture',
        sessionToken: 'session-a',
        values: values,
      ),
      isNot(
        smartTileMutationIdentity(
          purpose: 'smart-tile-cell-gesture',
          sessionToken: 'session-a',
          values: const <String, Object?>{
            'mapId': 'm01',
            'layerId': 'riviere',
            'sequence': 2,
          },
        ),
      ),
    );
  });

  test('deux intentions différentes ne se confondent pas', () {
    expect(
      smartTileMutationIdentity(
        purpose: 'smart-tile-cell-gesture',
        sessionToken: 'session-a',
        values: values,
      ),
      isNot(
        smartTileMutationIdentity(
          purpose: 'smart-tile-pattern-paint',
          sessionToken: 'session-a',
          values: values,
        ),
      ),
    );
  });

  test('le préfixe reste lisible dans le journal', () {
    expect(
      smartTileMutationIdentity(
        purpose: 'smart-tile-cell-gesture',
        sessionToken: 'session-a',
        values: values,
      ),
      startsWith('smart-tile-cell-gesture-'),
    );
  });

  test('newSmartTileMutationSessionToken rend un jeton par appel', () {
    expect(
      newSmartTileMutationSessionToken(),
      isNot(newSmartTileMutationSessionToken()),
    );
  });
}
