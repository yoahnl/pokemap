import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TilesetPalettePanel wires the Ombres auto action to EditorNotifier',
      () {
    final source = File(
      'lib/src/ui/panels/tileset_palette_panel.dart',
    ).readAsStringSync();

    expect(source, contains("child: const Text('Ombres auto')"));
    expect(source, contains('element-auto-shadow-backfill-button'));
    expect(
      source,
      contains('Appliquer les ombres automatiques aux éléments ?'),
    );
    expect(
      source,
      contains('await notifier.applyElementAutoShadowSuggestions();'),
    );
  });
}
