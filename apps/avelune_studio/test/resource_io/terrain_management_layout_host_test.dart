import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_terrain_host.dart';

void main() {
  for (final size in const [
    Size(1536, 1024),
    Size(1280, 800),
    Size(1024, 640),
  ]) {
    testWidgets('terrain management fits ${size.width} at enlarged text', (
      tester,
    ) async {
      final host = await openUwU5TerrainHost(
        tester,
        savedDraft: true,
        size: size,
        textScale: size.width == 1024 ? 1.5 : 1,
      );
      await host.family(ResourceKind.terrains);
      await host.fixture.capture(
        tester,
        'uwu5-host-terrain-library-${size.width.toInt()}',
      );
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('resource-card-terrains:path-draft')),
        findsOneWidget,
      );
      expect(
        tester
            .getSize(
              find.byKey(const ValueKey('resource-card-terrains:path-draft')),
            )
            .height,
        greaterThan(40),
      );
      if (find
          .byKey(const ValueKey('resource-terrain-preparations'))
          .evaluate()
          .isNotEmpty) {
        await host.tap('resource-terrain-preparations');
      }
      await host.tap('terrain-draft-actions-draft-path-draft');
      await tester.tap(find.text('Renommer le brouillon…').last);
      await pumpIo(tester);
      await host.fixture.capture(
        tester,
        'uwu5-host-terrain-rename-${size.width.toInt()}',
      );
      expect(
        find.byKey(const ValueKey('resource-terrain-name')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-management-cancel')),
        findsOneWidget,
      );
      await host.tap('resource-management-cancel');
      expect(tester.takeException(), isNull);
    });
  }
}
