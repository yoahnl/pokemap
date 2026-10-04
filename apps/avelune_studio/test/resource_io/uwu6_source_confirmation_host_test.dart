import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/uwu4_resource_host.dart';

void main() {
  for (final apply in [false, true]) {
    testWidgets('source OFF ON OFF ON remains explicit, apply=$apply', (
      tester,
    ) async {
      final host = await openUwU4ResourceHost(tester);
      final project = await host.reopen();
      final sheet = project.tilesets.single;
      final source = File(
        '${host.fixture.directory.path}/${sheet.relativePath}',
      );
      final catalog = File(
        '${host.fixture.directory.path}/assets/.pokemap-assets.json',
      );
      final pixels = (await tester.runAsync(source.readAsBytes))!;
      await host.action('decors:tree', 'Supprimer la définition…');
      await host.tap('resource-removal-confirm');
      await host.tap('resource-management-save');
      await host.family(ResourceKind.images);
      final before = (await tester.runAsync(catalog.readAsBytes))!;
      await host.action('images:${sheet.id}', 'Supprimer la planche…');
      final choice = find.byKey(const ValueKey('resource-removal-source'));
      final confirmation = find.byKey(
        const ValueKey('resource-removal-confirm'),
      );
      final submit = find.byKey(const ValueKey('resource-management-save'));
      expect(tester.widget<CheckboxListTile>(choice).value, isFalse);
      expect(tester.widget<CheckboxListTile>(choice).onChanged, isNotNull);
      expect(find.textContaining('La source reste conservée'), findsOneWidget);
      for (final enabled in [true, false, true]) {
        await host.tap('resource-removal-confirm');
        expect(tester.widget<StudioButton>(submit).onPressed, isNotNull);
        await host.tap('resource-removal-source');
        expect(tester.widget<CheckboxListTile>(choice).value, enabled);
        expect(tester.widget<CheckboxListTile>(choice).onChanged, isNotNull);
        expect(tester.widget<CheckboxListTile>(confirmation).value, isFalse);
        expect(tester.widget<StudioButton>(submit).onPressed, isNull);
        expect(
          find.textContaining('La source reste conservée'),
          enabled ? findsNothing : findsOneWidget,
        );
        expect(await tester.runAsync(catalog.readAsBytes), before);
        expect(await tester.runAsync(source.readAsBytes), pixels);
      }
      final addressed = sheet.relativePath.startsWith('assets/.pokemap-store/');
      expect(
        find.textContaining(
          addressed
              ? 'fichier adressé par contenu'
              : 'son fichier seront retirés',
        ),
        findsOneWidget,
      );
      await host.fixture.capture(tester, 'uwu6-source-off-on-off-on-$apply');
      if (apply) {
        await host.tap('resource-removal-confirm');
        await host.tap('resource-management-save');
        expect((await host.reopen()).tilesets, isEmpty);
        final after = jsonDecode(
          (await tester.runAsync(catalog.readAsString))!,
        );
        expect(after['records'], isEmpty);
        expect(await tester.runAsync(source.exists), addressed);
        if (addressed) {
          expect(await tester.runAsync(source.readAsBytes), pixels);
        }
      } else {
        await host.tap('resource-management-cancel');
        expect((await host.reopen()).tilesets.single, sheet);
        expect(await tester.runAsync(catalog.readAsBytes), before);
        expect(await tester.runAsync(source.readAsBytes), pixels);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
