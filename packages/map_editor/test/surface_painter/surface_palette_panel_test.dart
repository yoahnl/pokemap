import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_painter/surface_palette_panel.dart';

void main() {
  group('SurfacePalettePanel', () {
    testWidgets('empty palette shows the empty catalog message',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfacePalettePanel(
            presets: const [],
            selectedSurfacePresetId: null,
            onPresetSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Surfaces'), findsOneWidget);
      expect(find.text('Aucune surface disponible'), findsOneWidget);
    });

    testWidgets('lists presets and reports selected surface ids',
        (tester) async {
      final selectedIds = <String>[];

      await tester.pumpWidget(
        _wrap(
          SurfacePalettePanel(
            presets: [
              _preset(id: 'water', name: 'Water'),
              _preset(id: 'lava', name: 'Lava'),
            ],
            selectedSurfacePresetId: 'lava',
            onPresetSelected: selectedIds.add,
          ),
        ),
      );

      expect(find.text('Water'), findsOneWidget);
      expect(find.text('Lava'), findsOneWidget);
      expect(find.text('ID : water'), findsOneWidget);
      expect(find.text('ID : lava'), findsOneWidget);
      expect(find.text('Surface sélectionnée'), findsOneWidget);

      await tester.tap(find.byKey(const Key('surface-palette-preset-water')));
      expect(selectedIds, ['water']);
    });
  });
}

Widget _wrap(Widget child) {
  return CupertinoApp(
    home: CupertinoPageScaffold(child: child),
  );
}

ProjectSurfacePreset _preset({
  required String id,
  required String name,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '$id-isolated',
        ),
      ],
    ),
  );
}
