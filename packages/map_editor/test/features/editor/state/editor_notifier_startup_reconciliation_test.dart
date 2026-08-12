import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';

void main() {
  testWidgets(
    'startup defers Border selection reconciliation until after widget build',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final map = _map();
      container
          .read(activeBorderFeatureControllerProvider.notifier)
          .selectFeature(map: map, layerId: 'border-a', featureId: 'selected');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              ref.watch(activeBorderFeatureControllerProvider);
              ref.watch(editorNotifierProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      final selection = container.read(activeBorderFeatureControllerProvider);
      expect(selection.activeLayerId, isNull);
      expect(selection.activeFeatureId, isNull);
    },
  );
}

MapData _map() => MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: const GridSize(width: 4, height: 4),
  layers: <MapLayer>[
    MapLayer.border(
      id: 'border-a',
      name: 'Bordures',
      content: BorderLayerContent(
        features: <BorderFeature>[_feature('selected')],
      ),
    ),
  ],
);

BorderFeature _feature(String id) => BorderFeature(
  id: id,
  name: id,
  blueprintId: 'coast',
  seed: BorderSignedInt64.zero,
  geometry: BorderRegionGeometry(
    width: 4,
    height: 4,
    cells: List<bool>.filled(16, false),
  ),
  overrides: const <BorderSlotOverride>[],
  keepOutRegions: const <BorderKeepOutRegion>[],
);
