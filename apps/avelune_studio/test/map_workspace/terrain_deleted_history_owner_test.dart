import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/terrain_lifecycle_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'deleted terrain cannot return through map undo after saved removal',
    () async {
      final host = await openTerrainLifecycle(used: true);
      final controller = host.workspace;
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
      expect(await controller.save(document), isTrue, reason: document.error);
      expect(document.dirty, isFalse);
      final cleared = document.current;
      final retainedUndo = document.undoCount;
      final preset = controller.project!.smartTileCatalog.presets.single;

      String? error;
      await manageTerrainLifecycle(host, TerrainResourceAction.deleteDraft, (
        removal,
      ) async {
        await removal.prepareRemoval();
        removal.confirm(true);
        error = await removal.apply();
      }, presetId: preset.id);
      expect(error, isNull);
      final reopened = await host.reopen();
      expect(reopened.smartTileCatalog.presets, isEmpty);
      final saved = await host.fixture.maps.loadMap(
        host.fixture.session,
        reopened.maps.single,
      );
      expect(saved.map.layers.whereType<SmartTileLayer>(), isEmpty);
      expect(controller.project!.smartTileCatalog.presets, isEmpty);

      controller.restore(redo: false);
      expect(document.current, cleared);
      expect(document.undoCount, retainedUndo);
      expect(document.error, contains('terrain supprimé'));
      expect(document.dirty, isFalse);

      document.commit(cleared.copyWith(properties: {'ordinary': true}));
      controller.restore(redo: false);
      expect(document.current, cleared);
      expect(document.error, isNull);
      controller.restore(redo: true);
      expect(document.current.properties['ordinary'], true);
      expect(document.current.layers.whereType<SmartTileLayer>(), isEmpty);
      expect(document.undoCount, retainedUndo + 1);
    },
  );
}
