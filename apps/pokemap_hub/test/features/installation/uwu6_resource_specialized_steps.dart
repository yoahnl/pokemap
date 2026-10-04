import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../avelune_studio/test/support/m2_ui_fixture.dart';
import 'uwu6_resource_host.dart';

Future<void> editUwu6Terrain(Uwu6ResourceHost host) async {
  final tester = host.tester;
  await host.go('Ressources');
  await host.family(ResourceKind.terrains);
  final before = await host.reopen();
  final preset = before.smartTileCatalog.presets.single;
  await host.action('terrains:${preset.id}', 'Renommer le terrain…');
  await host.enter('resource-terrain-name', 'Sentier émeraude — raccords');
  await host.tap('resource-management-save');
  expect(
    (await host.reopen()).smartTileCatalog.presets.single.rules,
    preset.rules,
  );
  await host.tap('resource-card-terrains:${preset.id}');
  await host.text('Modifier les raccords');
  final editor = tester.widget<TerrainEditorScreen>(
    find.byType(TerrainEditorScreen),
  );
  final beforeRules = editor.controller.draft.rules;
  await host.tap('terrain-rule-4');
  expect(editor.controller.selectedRule, 4);
  final atlas = tester.getRect(find.byKey(const ValueKey('atlas-selection')));
  await tester.tapAt(
    atlas.topLeft + Offset(atlas.width * .75, atlas.height * .25),
  );
  await pumpIo(tester, frames: 4);
  expect(editor.controller.draft.rules, isNot(beforeRules));
  await host.text('Publier et peindre');
  for (var i = 0; i < 40 && editor.controller.busy; i++) {
    await pumpIo(tester, frames: 3);
  }
  expect(editor.controller.busy, false);
  expect(editor.controller.error, isNull);
  final published = (await host.reopen()).smartTileCatalog.presets.single;
  expect(published.name, 'Sentier émeraude — raccords');
  expect(published.rules, isNot(preset.rules));
  await host.go('Ressources');
  if (find.byType(TerrainEditorScreen).evaluate().isNotEmpty) {
    await host.text('Ressources › Terrains');
  }
  await host.family(ResourceKind.terrains);
  await host.action('terrains:${preset.id}', 'Dupliquer le terrain…');
  await host.enter('resource-terrain-name', 'Copie de chemin indépendante');
  await host.tap('resource-management-save');
  final withCopy = await host.reopen();
  expect(withCopy.smartTileCatalog.presets, [published]);
  final copy = withCopy.smartTileCatalog.drafts.single;
  expect(copy.targetPresetId, isNot(preset.id));
  expect(copy.sourcePresetId, isNull);
  for (
    var i = 0;
    i < 40 && find.byType(TerrainEditorScreen).evaluate().isEmpty;
    i++
  ) {
    await pumpIo(tester, frames: 3);
  }
  expect(find.byType(TerrainEditorScreen), findsOneWidget);
  final copyOwner =
      tester
          .widget<TerrainEditorScreen>(find.byType(TerrainEditorScreen))
          .controller;
  await host.text('Publier et peindre');
  for (var i = 0; i < 40 && copyOwner.busy; i++) {
    await pumpIo(tester, frames: 3);
  }
  expect(copyOwner.busy, false);
  expect(copyOwner.error, isNull);
  final after = await host.reopen();
  expect(after.smartTileCatalog.presets, hasLength(2));
  expect(
    after.smartTileCatalog.presets.singleWhere((p) => p.id == preset.id),
    published,
  );
  expect(after.smartTileCatalog.drafts, isEmpty);
  await host.go('Ressources');
  if (find.byType(TerrainEditorScreen).evaluate().isNotEmpty) {
    await host.text('Ressources › Terrains');
  }
  print(
    'UWU6_RESOURCE_TERRAIN_UI source=${preset.id} copy=${copy.targetPresetId}',
  );
}

Future<void> resolveUwu6Characters(Uwu6ResourceHost host) async {
  final tester = host.tester;
  await host.go('Ressources');
  if (find.text('Personnages').evaluate().isEmpty) await host.text('Actions');
  await host.text('Personnages');
  final before = await host.reopen();
  final free = before.characters.singleWhere(
    (entry) => entry.name == 'Personnage libre',
  );
  await host.tap('character-studio-${free.id}');
  await host.tap('character-studio-remove');
  await host.tap('character-removal-confirm');
  await host.tap('resource-management-save');
  expect(
    (await host.reopen()).characters.any((entry) => entry.id == free.id),
    false,
  );
  await host.tap('character-studio-guide');
  await host.tap('character-studio-remove');
  expect(find.textContaining('Joueur'), findsWidgets);
  await host.choose(
    'character-removal-resolution',
    'Remplacer par un autre personnage',
  );
  await host.choose('character-removal-replacement', 'Guide remplaçant');
  await host.tap('character-removal-confirm');
  await host.fixture.capture(tester, 'uwu6-widget-character-resolution');
  await host.tap('resource-management-save');
  final after = await host.reopen();
  expect(after.characters.map((entry) => entry.id), ['uwu5-replacement']);
  expect(after.settings.defaultPlayerCharacterId, 'uwu5-replacement');
  expect(after.tilesets, before.tilesets);
  print(
    'UWU6_RESOURCE_CHARACTER_UI removed=${free.id},guide replacement=uwu5-replacement',
  );
}
