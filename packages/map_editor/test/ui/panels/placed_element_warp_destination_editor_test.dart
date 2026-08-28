import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/panels/tileset_palette/widgets/placed_instances/placed_element_warp_destination_editor.dart';

void main() {
  testWidgets('edits an animated entrance destination without raw IDs', (
    tester,
  ) async {
    MapPlacedElementEffect? changed;
    const effect = MapPlacedElementEffect(
      type: MapPlacedElementEffectType.traverseWarp,
      targetMapId: 'interior-a',
      targetPos: GridPos(x: 2, y: 3),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PlacedElementWarpDestinationEditor(
            effect: effect,
            maps: const [
              ProjectMapEntry(
                id: 'interior-a',
                name: 'Maison A',
                relativePath: 'maps/interior-a.json',
              ),
              ProjectMapEntry(
                id: 'interior-b',
                name: 'Maison B',
                relativePath: 'maps/interior-b.json',
              ),
            ],
            onChanged: (value) => changed = value,
          ),
        ),
      ),
    );

    expect(find.text('Carte de destination'), findsOneWidget);
    expect(find.text('Maison A'), findsOneWidget);

    await tester.tap(find.byKey(const Key('placed-warp-target-map')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maison B').last);
    await tester.pumpAndSettle();

    expect(changed?.targetMapId, 'interior-b');

    await tester.enterText(find.byKey(const Key('placed-warp-target-x')), '7');
    await tester.enterText(find.byKey(const Key('placed-warp-target-y')), '9');

    expect(changed?.targetPos, const GridPos(x: 7, y: 9));
  });
}
