import 'package:avelune_studio/features/characters/coordination/character_removal_workflow.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_terrain_actions.dart';
import 'package:avelune_studio/features/resources/coordination/resource_terrain_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'uwu6_resource_host.dart';

Future<void> editUwu6Terrain(Uwu6ResourceHost host) => host.io(() async {
  final navigation = host.navigation;
  final controller = host.fixture.controller;
  final before = await host.read();
  final preset = before.smartTileCatalog.presets.single;
  Future<void> manage(
    TerrainResourceAction action,
    String name,
    String value,
  ) => runTerrainResourceManagement(
    navigation: navigation,
    action: action,
    name: name,
    presetId: preset.id,
    isActive: () => true,
    confirmOwnerSave: (owners) async => true,
    present: (lifecycle) async {
      lifecycle.name = value;
      expect(await lifecycle.apply(), isNull);
    },
  );
  await manage(
    TerrainResourceAction.rename,
    preset.name,
    'Sentier émeraude — raccords',
  );
  expect(navigation.error, isNull);
  expect((await host.read()).smartTileCatalog.presets.single.rules, preset.rules);
  navigation.prepareTerrain(
    resourceCatalog(
      controller.project!,
    ).singleWhere((item) => item.terrain?.id == preset.id),
  );
  final editor = navigation.terrain!;
  final beforeRules = editor.draft.rules;
  editor.selectedRule = 4;
  editor.assignSelectedFrame(const TilesetSourceRect(x: 1, y: 0));
  expect(editor.selectedRule, 4);
  expect(editor.draft.rules, isNot(beforeRules));
  expect(
    await editor.save(navigation.mutate, publish: true),
    true,
    reason: editor.error,
  );
  navigation.completeTerrainPublication(editor.publishedPreset!);
  expect(editor.busy, false);
  expect(editor.error, isNull);
  final published = (await host.read()).smartTileCatalog.presets.single;
  expect(published.name, 'Sentier émeraude — raccords');
  expect(published.rules, isNot(preset.rules));
  navigation.showLibrary();
  await manage(
    TerrainResourceAction.duplicate,
    published.name,
    'Copie de chemin indépendante',
  );
  expect(navigation.error, isNull);
  final withCopy = await host.read();
  expect(withCopy.smartTileCatalog.presets, [published]);
  final copy = withCopy.smartTileCatalog.drafts.single;
  expect(copy.targetPresetId, isNot(preset.id));
  expect(copy.sourcePresetId, isNull);
  final copyOwner = navigation.terrain!;
  expect(copyOwner.draft.id, copy.id);
  expect(
    await copyOwner.save(navigation.mutate, publish: true),
    true,
    reason: copyOwner.error,
  );
  navigation.completeTerrainPublication(copyOwner.publishedPreset!);
  expect(copyOwner.busy, false);
  expect(copyOwner.error, isNull);
  final after = await host.read();
  expect(after.smartTileCatalog.presets, hasLength(2));
  expect(
    after.smartTileCatalog.presets.singleWhere((p) => p.id == preset.id),
    published,
  );
  expect(after.smartTileCatalog.drafts, isEmpty);
  navigation.showLibrary();
  print(
    'UWU6_RESOURCE_TERRAIN_OWNER source=${preset.id} copy=${copy.targetPresetId}',
  );
});

Future<void> resolveUwu6Characters(Uwu6ResourceHost host) => host.io(() async {
  final navigation = host.navigation;
  final before = await host.read();
  final free = before.characters.singleWhere(
    (entry) => entry.name == 'Personnage libre',
  );
  await runCharacterRemoval(
    navigation: navigation,
    character: free,
    present: (removal) async {
      await removal.inspect();
      expect(removal.error, isNull);
      expect(removal.requiresResolution, false);
      removal.confirm(true);
      expect(await removal.submit(), isNull);
    },
  );
  expect(navigation.error, isNull);
  expect(
    (await host.read()).characters.any((entry) => entry.id == free.id),
    false,
  );
  final guide = host.fixture.controller.project!.characters.singleWhere(
    (entry) => entry.id == 'guide',
  );
  await runCharacterRemoval(
    navigation: navigation,
    character: guide,
    present: (removal) async {
      await removal.inspect();
      expect(removal.error, isNull);
      expect(removal.requiresResolution, true);
      expect(
        [
          for (final dependency
              in (removal.impact['dependencies'] as List).whereType<Map>())
            characterRemovalOwnerLabel(
              host.fixture.controller.project!,
              dependency,
            ),
        ].any((label) => label.contains('Joueur')),
        true,
      );
      await removal.selectResolution('replace');
      await removal.selectReplacement('uwu5-replacement');
      expect(removal.error, isNull);
      removal.confirm(true);
      expect(await removal.submit(), isNull);
    },
  );
  expect(navigation.error, isNull);
  final after = await host.read();
  expect(after.characters.map((entry) => entry.id), ['uwu5-replacement']);
  expect(after.settings.defaultPlayerCharacterId, 'uwu5-replacement');
  expect(after.tilesets, before.tilesets);
  print(
    'UWU6_RESOURCE_CHARACTER_OWNER removed=${free.id},guide replacement=uwu5-replacement',
  );
});
