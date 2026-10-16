import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/regional_map/application/regional_map_controller.dart';
import 'package:avelune_studio/presentation/features/regional_map/regional_map_page.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  testWidgets(
    'regional image dragging edits normalized draft coordinates and preserves undo',
    (tester) async {
      final port = MemoryRegionalMapPort()
        ..imageBytes = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        );
      VoidCallback refresh = () {};
      final controller = RegionalMapController(port, changed: () => refresh());
      await controller.load();
      controller.createRegion('Kanto');
      controller.editRegion(imagePath: 'assets/region.png');
      controller.createPoint('Town', 'town');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, rebuild) {
                refresh = () => rebuild(() {});
                return RegionalMapPage(controller: controller);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final image = find.byKey(const ValueKey('regional-map-image'));
      for (
        var attempt = 0;
        attempt < 20 && image.evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump();
      }
      expect(image, findsOneWidget);
      await tester.ensureVisible(image);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byTooltip('Town')),
      );
      await gesture.moveBy(const Offset(25, -25));
      await tester.pump();
      await gesture.moveBy(const Offset(55, -55));
      await tester.pump();
      await gesture.up();
      expect(controller.point!.u, greaterThan(.5));
      expect(controller.point!.v, lessThan(.5));
      expect(controller.dirty, isTrue);
      controller.discard();
      expect(controller.catalog.regions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'native regional page offers image, discovery map and real spawn pickers',
    (tester) async {
      final controller = RegionalMapController(
        MemoryRegionalMapPort(),
        changed: () {},
      );
      await controller.load();
      controller.createRegion('Kanto');
      controller.editRegion(imagePath: 'assets/region.png');
      controller.createPoint('Town', 'town');
      controller.editPoint(
        destination: ProjectRegionDestination(
          mapId: 'town',
          spawnId: 'arrival',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RegionalMapPage(controller: controller)),
        ),
      );
      expect(find.text('Carte régionale'), findsOneWidget);
      expect(find.text('Image de la région'), findsOneWidget);
      expect(find.text('Destination de Vol'), findsOneWidget);
      expect(find.text('Carte d’arrivée'), findsOneWidget);
      expect(find.text('Point d’arrivée'), findsOneWidget);
      expect(find.textContaining('3, 4'), findsOneWidget);
      expect(find.textContaining('JSON'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
