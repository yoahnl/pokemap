import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/element_preset_label.dart';

void main() {
  group('Tileset Library Visual Labels Refinement', () {
    test('TilesetEditorCanvas uses French labels and refined visual elements',
        () {
      final source = File(
        'lib/src/ui/canvas/tileset_editor_canvas.dart',
      ).readAsStringSync();

      // Check header translations
      expect(source, contains("tuiles ·"));
      expect(source, contains("Grille utilisable :"));
      expect(source, contains("Aucune sélection"));
      expect(source, contains("Sélection"));
      expect(source, contains("Créer un élément"));

      // Check dialog translations
      expect(source, contains("Catégorie d’élément manquante"));
      expect(source, contains("Créez au moins une catégorie"));
      expect(source, contains("Groupe de tileset"));
      expect(source, contains("Portée du groupe d'éléments"));
      expect(source, contains("Calque recommandé"));
      expect(source, contains("Annuler"));
      expect(source, contains("Créer"));

      // Check that old English labels are NOT present
      expect(source, isNot(contains("Text('Create Element')")));
      expect(source, isNot(contains("Text('Cancel')")));
      expect(source, isNot(contains("Text('Create')")));

      // Asset ownership stays project-scoped and asynchronous. The canvas must
      // not regress to its former static path-only decode cache.
      expect(source, contains('editorImageCacheProvider'));
      expect(source, contains('EditorImageLoadResult'));
      expect(source, isNot(contains('_TilesetEditorImageCache')));
      expect(source, isNot(contains('readAsBytesSync')));
      expect(source, isNot(contains('instantiateImageCodec')));
    });

    test('TilesetPalettePanel uses French labels and semantic colors', () {
      final source = File(
        'lib/src/ui/panels/tileset_palette_panel.dart',
      ).readAsStringSync();

      // Check panel headers
      expect(source, contains("ÉLÉMENTS"));
      expect(source, contains("Aucun projet chargé"));
      expect(source, contains("Aucun tileset sélectionné"));
      expect(source, contains("Aucune carte active : mode édition uniquement"));

      // Check segmented control
      expect(source, contains("TilesElementsPanelMode.palette"));
      expect(source, contains("TilesElementsPanelMode.placedInstances"));

      // Check container border/fill refinement (uses context.pokeMapColors)
      expect(source, contains("colors.surfaceBase"));
      expect(source, contains("colors.borderSubtle"));
    });

    test('shared element preset labels use French product copy', () {
      expect(elementPresetLabel(ElementPresetKind.generic), 'Générique');
      expect(elementPresetLabel(ElementPresetKind.tree), 'Arbre');
      expect(elementPresetLabel(ElementPresetKind.building), 'Bâtiment');
      expect(elementPresetLabel(ElementPresetKind.rock), 'Roche');
      expect(elementPresetLabel(ElementPresetKind.cliff), 'Falaise');
      expect(
        elementPresetLabel(ElementPresetKind.tallDecoration),
        'Grande déco',
      );
    });
  });
}
