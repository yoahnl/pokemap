import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';

void main() {
  for (final size in [
    const Size(1536, 1024),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    testWidgets(
      'resource management stays reachable at ${size.width} with enlarged text',
      (tester) async {
        final scale = size.width == 1024 ? 1.5 : 1.0;
        final host = await UwUResourceHost.open(
          tester,
          size: size,
          textScale: scale,
        );
        await host.family(ResourceKind.images);
        await host.action('images:atelier', 'Modifier les informations');
        await host.enter('resource-information-name', 'Planche à $scale');
        expect(
          find.byKey(const ValueKey('resource-management-save')),
          findsOneWidget,
        );
        await host.fixture.capture(
          tester,
          'uwu3-information-${size.width.toInt()}',
        );
        await host.tap('resource-management-save');
        expect((await host.reopen()).tilesets.single.name, 'Planche à $scale');
        await host.tap('resource-manage-containers');
        await host.fixture.capture(
          tester,
          'uwu3-containers-${size.width.toInt()}',
        );
        await host.tap('resource-container-create');
        await host.enter('resource-container-name', 'Dossier accessible');
        await host.tap('resource-management-save');
        await tester.tap(find.text('Retour aux ressources').last);
        await pumpIo(tester, frames: 6);
        await host.action('images:atelier', 'Voir les usages dans le projet');
        await host.tap('resource-usage-analyze');
        await host.fixture.capture(tester, 'uwu3-usages-${size.width.toInt()}');
        expect(
          find.byKey(const ValueKey('resource-usage-analyze')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
