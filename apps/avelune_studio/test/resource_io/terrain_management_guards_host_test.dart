import 'dart:io';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu5_terrain_host.dart';

void main() {
  testWidgets('unchanged normalized name performs no write', (tester) async {
    final host = await openUwU5TerrainHost(tester);
    final file = File('${host.fixture.directory.path}/project.json');
    final bytes = (await WidgetResourcePort.serial(tester, file.readAsBytes))!;
    await host.family(ResourceKind.terrains);
    await host.action('terrains:path-draft', 'Renommer le terrain…');
    await host.enter('resource-terrain-name', '  Chemin des essais  ');
    await host.tap('resource-management-save');
    expect(await WidgetResourcePort.serial(tester, file.readAsBytes), bytes);
    expect(host.navigation.pendingReceipt, isNull);
  });

  testWidgets('rename conflict keeps input and newer saved metadata', (
    tester,
  ) async {
    final host = await openUwU5TerrainHost(tester);
    await host.family(ResourceKind.terrains);
    await host.action('terrains:path-draft', 'Renommer le terrain…');
    await host.enter('resource-terrain-name', 'Ma saisie préservée');
    await WidgetResourcePort.serial(
      tester,
      () => host.fixture.resources.mutate('smart_tile.preset.rename', {
        'presetId': 'path-draft',
        'name': 'Version concurrente',
      }),
    );
    await host.tap('resource-management-save');
    expect(
      find.byKey(const ValueKey('resource-management-error')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('resource-terrain-name')),
          )
          .controller!
          .text,
      'Ma saisie préservée',
    );
    expect(
      (await host.reopen()).smartTileCatalog.presets.single.name,
      'Version concurrente',
    );
  });

  testWidgets(
    'dirty preparation copy requires explicit save without publication',
    (tester) async {
      final host = await openUwU5TerrainHost(tester, savedDraft: true);
      final before = await host.reopen();
      await host.family(ResourceKind.terrains);
      await tester.tap(
        find.text('Reprendre le brouillon : Chemin des essais').last,
      );
      await pumpIo(tester);
      await host.enter('terrain-name', 'Préparation locale');
      await tester.tap(find.text('Ressources › Terrains').last);
      await pumpIo(tester);
      await host.tap('terrain-draft-actions-draft-path-draft');
      await tester.tap(find.text('Dupliquer le brouillon…').last);
      await pumpIo(tester);
      expect(find.text('Enregistrer et continuer'), findsOneWidget);
      await tester.tap(find.text('Rester avec mes modifications').last);
      await pumpIo(tester);
      expect(
        host.navigation.terrains['draft-path-draft']!.draft.name,
        'Préparation locale',
      );
      expect((await host.reopen()).smartTileCatalog, before.smartTileCatalog);
      await host.tap('terrain-draft-actions-draft-path-draft');
      await tester.tap(find.text('Dupliquer le brouillon…').last);
      await pumpIo(tester);
      await tester.tap(find.text('Enregistrer et continuer').last);
      await pumpIo(tester);
      expect(
        find.textContaining('Brouillon enregistré : Préparation locale'),
        findsOneWidget,
      );
      await host.tap('resource-management-save');
      final after = await host.reopen();
      expect(after.smartTileCatalog.presets, before.smartTileCatalog.presets);
      expect(
        after.smartTileCatalog.drafts.where(
          (draft) => draft.name == 'Préparation locale — copie',
        ),
        hasLength(1),
      );
      expect(
        after.smartTileCatalog.drafts
            .singleWhere((draft) => draft.id == 'draft-path-draft')
            .name,
        'Préparation locale',
      );
    },
  );

  testWidgets(
    'advanced path metadata stays editable without converting rules',
    (tester) async {
      final host = await openUwU5TerrainHost(tester, advanced: true);
      final before = await host.reopen();
      await host.family(ResourceKind.terrains);
      expect(find.textContaining('préparation avancée'), findsWidgets);
      await host.action('terrains:path-draft', 'Renommer le terrain…');
      await host.enter('resource-terrain-name', 'Terrain avancé renommé');
      await host.tap('resource-management-save');
      final after = await host.reopen();
      expect(
        after.smartTileCatalog.presets.single.name,
        'Terrain avancé renommé',
      );
      expect(
        after.smartTileCatalog.presets.single.rules,
        before.smartTileCatalog.presets.single.rules,
      );
      expect(find.byType(TerrainEditorScreen), findsNothing);
    },
  );

  testWidgets('local-only preparation withdrawal writes nothing', (
    tester,
  ) async {
    final host = await openUwU5TerrainHost(tester);
    final before = await host.reopen();
    await host.family(ResourceKind.terrains);
    await host.action('terrains:path-draft', 'Modifier les raccords');
    await pumpIo(tester);
    await host.enter('terrain-name', 'Brouillon uniquement local');
    await tester.tap(find.text('Ressources › Terrains').last);
    await pumpIo(tester);
    await host.tap('terrain-draft-actions-draft-path-draft');
    await tester.tap(find.text('Supprimer le brouillon…').last);
    await pumpIo(tester);
    await host.tap('resource-terrain-confirm');
    await host.tap('resource-management-save');
    expect(host.navigation.terrains, isEmpty);
    expect((await host.reopen()).smartTileCatalog, before.smartTileCatalog);
  });
}
