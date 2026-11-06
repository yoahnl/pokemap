import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  Future<RegionalMapController> open(WidgetTester tester) async {
    final port = MemoryRegionalMapPort()
      ..project = ProjectManifest(
        name: 'Regional',
        tilesets: [],
        maps: const [
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
          ProjectMapEntry(
            id: 'town',
            name: 'Town',
            relativePath: 'maps/town.json',
            groupId: 'bourg',
          ),
        ],
        groups: const [
          ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.city),
          ProjectMapGroup(
            id: 'bourg',
            name: 'Bourg Geon',
            type: MapGroupType.village,
            parentGroupId: 'johto',
          ),
        ],
      );
    final controller = RegionalMapController(port, changed: () {});
    await controller.load();
    controller.createRegion('Johto');
    controller.editRegion(imagePath: 'assets/region.png');
    return controller;
  }

  Future<void> pump(
    WidgetTester tester,
    RegionalMapController controller,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RegionalMapPage(controller: controller)),
      ),
    );
    await tester.pump();
  }

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  StudioSelect dialogSelect(WidgetTester tester) =>
      tester.widget<StudioSelect>(inDialog(find.byType(StudioSelect)));

  StudioButton dialogButton(WidgetTester tester, String label) =>
      tester.widget<StudioButton>(
        inDialog(
          find.byWidgetPredicate((w) => w is StudioButton && w.label == label),
        ),
      );

  testWidgets(
    'creating a place asks for its linked map instead of taking the first one',
    (tester) async {
      final controller = await open(tester);
      await pump(tester, controller);
      await tester.ensureVisible(find.text('Créer un lieu'));
      await tester.tap(find.text('Créer un lieu'));
      await tester.pumpAndSettle();
      await tester.enterText(inDialog(find.byType(TextField)), 'Bourg Geon');
      await tester.pump();
      expect(dialogSelect(tester).value, isNull);
      expect(dialogSelect(tester).options['town'], 'Town · Johto / Bourg Geon');
      expect(dialogSelect(tester).options['alpha'], 'Alpha');
      expect(dialogButton(tester, 'Créer').onPressed, isNull);
      dialogSelect(tester).onChanged!('town');
      await tester.pump();
      dialogButton(tester, 'Créer').onPressed!();
      await tester.pumpAndSettle();
      expect(controller.point!.label, 'Bourg Geon');
      expect(controller.point!.mapIds, ['town']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cancelling place creation creates no place and links no map', (
    tester,
  ) async {
    final controller = await open(tester);
    await pump(tester, controller);
    await tester.ensureVisible(find.text('Créer un lieu'));
    await tester.tap(find.text('Créer un lieu'));
    await tester.pumpAndSettle();
    await tester.enterText(inDialog(find.byType(TextField)), 'Bourg Geon');
    dialogButton(tester, 'Annuler').onPressed!();
    await tester.pumpAndSettle();
    expect(controller.catalog.pointsOfInterest, isEmpty);
  });

  testWidgets(
    'enabling Flight asks to confirm the arrival map and suggests the place map',
    (tester) async {
      final controller = await open(tester);
      controller.createPoint('Town', 'town');
      await pump(tester, controller);
      tester
          .widget<StudioToggleRow>(
            find.byWidgetPredicate(
              (w) =>
                  w is StudioToggleRow &&
                  w.label == 'Autoriser Vol vers ce lieu',
            ),
          )
          .onChanged!(true);
      await tester.pumpAndSettle();
      expect(controller.point!.destination, isNull);
      expect(dialogSelect(tester).value, 'town');
      dialogButton(tester, 'Autoriser Vol').onPressed!();
      await tester.pumpAndSettle();
      expect(controller.point!.destination?.mapId, 'town');
    },
  );

  testWidgets('cancelling the Flight map choice leaves Flight disabled', (
    tester,
  ) async {
    final controller = await open(tester);
    controller.createPoint('Town', 'town');
    await pump(tester, controller);
    tester
        .widget<StudioToggleRow>(
          find.byWidgetPredicate(
            (w) =>
                w is StudioToggleRow && w.label == 'Autoriser Vol vers ce lieu',
          ),
        )
        .onChanged!(true);
    await tester.pumpAndSettle();
    dialogButton(tester, 'Annuler').onPressed!();
    await tester.pumpAndSettle();
    expect(controller.point!.destination, isNull);
  });
}
