import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/example_project_assets.dart';
import '../support/m2_ui_fixture.dart';
import '../support/resource_administration_host.dart';
import '../support/uwu_resource_host.dart';

VoidCallback? _importAction(WidgetTester tester) => tester
    .widget<StudioButton>(find.widgetWithText(StudioButton, 'Importer').last)
    .onPressed;

Future<String> _projectJson(UwUResourceHost host) async =>
    (await host.tester.runAsync(
      () => File('${host.fixture.directory.path}/project.json').readAsString(),
    ))!;

void main() {
  testWidgets(
    'an imported image stays a source with explicit next steps and is not offered as a decor',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      await host.family(ResourceKind.images);
      await tapResourceAdministrationText(tester, 'Importer une image');
      expect(find.byKey(const ValueKey('resource-import-preflight')), findsOne);
      expect(
        find.byKey(const ValueKey('resource-import-decoded')),
        findsOneWidget,
      );
      await tapResourceAdministrationText(tester, 'Importer');

      final project = host.fixture.controller.project!;
      final imported = project.tilesets.singleWhere(
        (item) => item.name == 'Planche M2',
      );
      expect(host.navigation.decor, isNull);
      expect(host.navigation.library.selectedIdentity, 'tileset:${imported.id}');
      expect(find.byKey(const ValueKey('resource-import-result')), findsOne);
      expect(
        find.textContaining('n’est placée sur aucune carte'),
        findsOneWidget,
      );
      expect(project.elements.where((e) => e.tilesetId == imported.id), isEmpty);
      final palette = MapWorkspaceViewState();
      addTearDown(palette.dispose);
      expect(
        palette
            .paletteResources(project, project.maps.first.id)
            .map((item) => item.identity),
        isNot(contains('tileset:${imported.id}')),
      );

      await host.tap('resource-import-create-decor');
      expect(host.navigation.decor?.tileset.id, imported.id);
    },
  );

  testWidgets('an import started from decor creation opens the decor workshop', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester);
    await host.family(ResourceKind.decors);
    await host.tap('resource-create');
    await tapResourceAdministrationText(tester, 'Importer une image');
    await tapResourceAdministrationText(tester, 'Importer');
    final imported = host.fixture.controller.project!.tilesets.singleWhere(
      (item) => item.name == 'Planche M2',
    );
    expect(host.navigation.decor?.tileset.id, imported.id);
    expect(find.byKey(const ValueKey('resource-import-result')), findsNothing);
  });

  testWidgets('cancelling the preflight publishes nothing', (tester) async {
    final host = await UwUResourceHost.open(tester);
    final before = await _projectJson(host);
    await host.family(ResourceKind.images);
    await tapResourceAdministrationText(tester, 'Importer une image');
    await tapResourceAdministrationText(tester, 'Annuler');
    expect(await _projectJson(host), before);
    expect(host.navigation.error, isNull);
    expect(find.byKey(const ValueKey('resource-import-result')), findsNothing);
  });

  testWidgets('an invalid file is refused before any project change', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(
      tester,
      imagePicker: () async =>
          throw const ResourceFailure('Choisissez une image PNG valide.'),
    );
    final before = await _projectJson(host);
    await host.family(ResourceKind.images);
    await tapResourceAdministrationText(tester, 'Importer une image');
    expect(await _projectJson(host), before);
    expect(find.text('Choisissez une image PNG valide.'), findsOneWidget);
    expect(find.byKey(const ValueKey('resource-import-preflight')), findsNothing);
  });

  testWidgets(
    'the preflight warns about a name already used and an uneven grid',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final existing = host.fixture.controller.project!.tilesets.single.name;
      await host.family(ResourceKind.images);
      await tapResourceAdministrationText(tester, 'Importer une image');
      await tester.enterText(
        find.byKey(const ValueKey('resource-import-name')),
        existing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('resource-import-cell-width')),
        '48',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('resource-import-name-taken')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-import-uneven-width')),
        findsOneWidget,
      );
      expect(_importAction(tester), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('resource-import-cell-width')),
        '32',
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('resource-import-uneven-width')),
        findsNothing,
      );
      expect(_importAction(tester), isNotNull);
      await tapResourceAdministrationText(tester, 'Annuler');
      await pumpIo(tester);
    },
  );

  testWidgets(
    'a PNG whose content does not decode cannot be imported and nothing is published',
    (tester) async {
      final valid = Uint8List.fromList(exampleAtlasPng());
      final corrupt = Uint8List.fromList([
        ...valid.sublist(0, 60),
        ...List.filled(40, 7),
        ...valid.sublist(100),
      ]);
      late File picked;
      final host = await UwUResourceHost.open(
        tester,
        imagePicker: () async {
          picked = File(
            '${Directory.systemTemp.path}/avelune-corrupt-${DateTime.now().microsecondsSinceEpoch}.png',
          );
          await picked.writeAsBytes(corrupt);
          addTearDown(() => picked.deleteSync());
          return PickedResourceImage(picked.path, 'Corrompue', corrupt, 160, 64);
        },
      );
      final before = await _projectJson(host);
      await host.family(ResourceKind.images);
      await tapResourceAdministrationText(tester, 'Importer une image');
      expect(
        find.byKey(const ValueKey('resource-import-unreadable')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-import-decoded')),
        findsNothing,
      );
      expect(_importAction(tester), isNull);
      await tapResourceAdministrationText(tester, 'Annuler');
      expect(await _projectJson(host), before);
      expect(await tester.runAsync(picked.readAsBytes), corrupt);
      expect(
        host.fixture.controller.project!.tilesets.map((item) => item.name),
        isNot(contains('Corrompue')),
      );
    },
  );
}
