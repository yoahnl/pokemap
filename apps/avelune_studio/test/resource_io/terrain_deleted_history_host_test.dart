import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/uwu5_terrain_host.dart';

void main() {
  testWidgets(
    'deleted terrain cannot return through map undo after saved removal',
    (tester) async {
      final host = await openUwU5TerrainHost(tester, used: true);
      final controller = host.fixture.controller;
      final document = controller.active!;
      final painted = document.current;
      expect(painted.layers.whereType<SmartTileLayer>(), hasLength(1));
      document.commit(
        painted.copyWith(
          layers: [
            for (final layer in painted.layers)
              if (layer is! SmartTileLayer) layer,
          ],
        ),
      );
      await tester.tap(find.byTooltip('Carte').first);
      await pumpIo(tester);
      await host.tap('Enregistrer');
      expect(document.dirty, false);
      final cleared = document.current;
      final retainedUndo = document.undoCount;
      await tester.tap(find.byTooltip('Ressources').first);
      await pumpIo(tester);
      await host.family(ResourceKind.terrains);
      await host.action('terrains:path-draft', 'Supprimer le terrain…');
      await host.tap('resource-terrain-confirm');
      await host.tap('resource-management-save');
      final reopened = await host.reopen();
      expect(reopened.smartTileCatalog.presets, isEmpty);
      final saved = (await WidgetResourcePort.serial(
        tester,
        () => host.fixture.port.loadMap(
          host.fixture.session,
          reopened.maps.single,
        ),
      ))!;
      expect(saved.map.layers.whereType<SmartTileLayer>(), isEmpty);
      await tester.tap(find.byTooltip('Carte').first);
      await pumpIo(tester);
      await tester.tap(find.byTooltip('Annuler').last);
      await pumpIo(tester);
      expect(document.current, cleared);
      expect(document.undoCount, retainedUndo);
      expect(document.error, contains('terrain supprimé'));
      expect(document.dirty, false);
      document.commit(cleared.copyWith(properties: {'ordinary': true}));
      await tester.pump();
      await tester.tap(find.byTooltip('Annuler').last);
      await pumpIo(tester);
      expect(document.current, cleared);
      expect(document.error, isNull);
      await tester.tap(find.byTooltip('Rétablir').last);
      await pumpIo(tester);
      expect(document.current.properties['ordinary'], true);
      expect(document.current.layers.whereType<SmartTileLayer>(), isEmpty);
      expect(document.undoCount, retainedUndo + 1);
    },
  );
}
