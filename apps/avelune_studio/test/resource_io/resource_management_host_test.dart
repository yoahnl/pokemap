import 'dart:convert';
import 'dart:io';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_management_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';

void main() {
  testWidgets(
    'true resource workspace saves focused title with stable references',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      final before = host.fixture.controller.project!;
      final pixels = await tester.runAsync(
        () => File(
          '${host.fixture.directory.path}/${before.tilesets.single.relativePath}',
        ).readAsBytes(),
      );
      final mapBefore = host.fixture.controller.active!.current;
      await host.family(ResourceKind.images);
      await host.action('images:atelier', 'Modifier les informations');
      expect(before.tilesets.single.source, isNull);
      expect(find.text('160 × 64 px'), findsOneWidget);
      expect(find.text('Grille du projet : 16 × 16 px'), findsOneWidget);
      await host.enter(
        'resource-information-name',
        'Été — la planche des rêves',
      );
      await host.fixture.capture(tester, 'uwu3-metadata-focused');
      await host.tap('resource-management-save');
      expect(find.byType(ResourceManagementDialog), findsNothing);
      final reopened = await host.reopen();
      final after = reopened.tilesets.single;
      expect(after.name, 'Été — la planche des rêves');
      expect(
        after.copyWith(name: before.tilesets.single.name),
        before.tilesets.single,
      );
      expect(reopened.elements, before.elements);
      expect(reopened.characters, before.characters);
      expect(host.fixture.controller.active!.current, mapBefore);
      expect(
        await tester.runAsync(
          () => File(
            '${host.fixture.directory.path}/${after.relativePath}',
          ).readAsBytes(),
        ),
        pixels,
      );
    },
  );

  testWidgets(
    'metadata no-op stays neutral and cancel preserves focused draft',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      await host.family(ResourceKind.images);
      final file = File('${host.fixture.directory.path}/project.json');
      final before = await tester.runAsync(file.readAsString);
      await host.action('images:atelier', 'Modifier les informations');
      await host.tap('resource-management-save');
      expect(await tester.runAsync(file.readAsString), before);
      await host.action('images:atelier', 'Modifier les informations');
      await host.enter('resource-information-name', 'Brouillon précieux');
      await host.tap('resource-management-cancel');
      await tester.tap(find.text('Rester').last);
      await pumpIo(tester, frames: 4);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('resource-information-name')),
            )
            .controller!
            .text,
        'Brouillon précieux',
      );
      await host.tap('resource-management-cancel');
      await tester.tap(find.text('Annuler les modifications').last);
      await pumpIo(tester, frames: 4);
      expect(await tester.runAsync(file.readAsString), before);
    },
  );

  testWidgets('metadata refuses changed disk revision and retains input', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester);
    await host.family(ResourceKind.images);
    await host.action('images:atelier', 'Modifier les informations');
    await host.enter('resource-information-name', 'Mon titre concurrent');
    final file = File('${host.fixture.directory.path}/project.json');
    await tester.runAsync(() async {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      json['name'] = 'Modification extérieure';
      await file.writeAsString(jsonEncode(json));
    });
    await host.tap('resource-management-save');
    expect(find.byType(ResourceManagementDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('resource-management-error')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('resource-information-name')),
          )
          .controller!
          .text,
      'Mon titre concurrent',
    );
    expect((await host.reopen()).name, 'Modification extérieure');
    expect(
      (await host.reopen()).tilesets.single.name,
      host.fixture.controller.project!.tilesets.single.name,
    );
  });

  testWidgets('metadata management remains available with no active map', (
    tester,
  ) async {
    final host = await UwUResourceHost.open(tester, noMaps: true);
    expect(host.fixture.controller.active, isNull);
    await host.family(ResourceKind.images);
    await host.action('images:atelier', 'Modifier les informations');
    await host.enter('resource-information-name', 'Planche sans carte');
    await host.tap('resource-management-save');
    expect((await host.reopen()).tilesets.single.name, 'Planche sans carte');
    expect((await host.reopen()).maps, isEmpty);
  });
}
