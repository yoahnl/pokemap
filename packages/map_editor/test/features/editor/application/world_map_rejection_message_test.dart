import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/world_map_rejection_message.dart';

void main() {
  test('projects every current English activation rejection into French', () {
    const expectations = <String, String>{
      'Select an active map before choosing an editing tool.':
          'Sélectionnez une carte active avant de choisir un outil.',
      'Place/object requires an active editable tile layer.':
          'Sélectionnez un calque de tuiles modifiable pour placer cet objet.',
      'The active layer cannot be erased.':
          'Le calque actif ne peut pas être effacé.',
      'Paint/tile requires an active editable tile layer.':
          'Sélectionnez un calque de tuiles modifiable pour peindre des éléments.',
      'Paint/terrain requires an active terrain layer.':
          'Sélectionnez un calque de terrain pour peindre le terrain.',
      'Paint/path requires an active path layer.':
          'Sélectionnez un calque de chemins pour peindre un chemin.',
      'Paint/surface requires an active surface layer.':
          'Sélectionnez un calque de surfaces pour peindre une surface.',
      'Paint/collision requires an active collision layer.':
          'Sélectionnez un calque de collisions pour peindre les collisions.',
      'Select an available surface before painting.':
          'Sélectionnez une surface disponible avant de peindre.',
      'No active map selected.': 'Sélectionnez une carte active.',
      'Layer not found: missing-layer': 'Le calque demandé est introuvable.',
    };

    for (final MapEntry(key: internal, value: expected)
        in expectations.entries) {
      final projected = projectWorldMapRejectionMessageFr(internal);
      expect(projected, expected, reason: internal);
      expect(projected, isNot(contains(internal)), reason: internal);
    }
  });

  test('preserves approved French reasons and hides unknown technical text',
      () {
    const approved = 'Sélectionnez ou créez une bordure dans ce calque.';
    expect(projectWorldMapRejectionMessageFr(approved), approved);

    const unknown = 'Renderer rejected source id=private_layer';
    final projected = projectWorldMapRejectionMessageFr(unknown);
    expect(
      projected,
      'Cette action est indisponible dans le contexte actuel.',
    );
    expect(projected, isNot(contains(unknown)));
  });

  test('keeps an absent rejection absent', () {
    expect(projectWorldMapRejectionMessageFr(null), isNull);
  });
}
