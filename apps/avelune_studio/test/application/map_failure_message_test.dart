import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';

import '../map_workspace/map_relief_fixture.dart';

void main() {
  test('a refused edit shows its French reason without the error type', () {
    final document = reliefDocument(reliefToolMap());
    final commands = SpatialModelEditingCommands(document, reliefToolProject());

    final applied = commands.number(
      '2',
      (_) => throw StateError('Saisissez un décalage vertical valide.'),
    );

    expect(applied, isFalse);
    expect(document.error, 'Saisissez un décalage vertical valide.');
  });
}
