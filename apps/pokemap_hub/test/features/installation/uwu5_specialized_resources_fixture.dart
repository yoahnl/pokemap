import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../../avelune_studio/test/support/m3_story_fixture.dart';
import 'uwu4_resource_replacement_player_support.dart';

Future<void> prepareUwu5ExportFixture(
  M3StoryFixture source, {
  bool discriminatingTerrain = false,
}) async {
  await prepareUwu4ExportFixture(source);
  await source.maps.loadProject(source.session);
  final port = LocalResourceAdapter(
    session: source.session,
    mapAdapter: source.maps,
  );
  final temporary = await Directory.systemTemp.createTemp('uwu5-seed-assets-');
  try {
    final pixels = image.Image(width: 32, height: 32)
      ..clear(image.ColorRgba8(25, 211, 181, 255));
    if (discriminatingTerrain) {
      final colors = [
        [25, 211, 181],
        [55, 100, 240],
        [220, 60, 90],
        [245, 210, 80],
      ];
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final color = colors[(y ~/ 16) * 2 + x ~/ 16];
          pixels.setPixelRgba(x, y, color[0], color[1], color[2], 255);
        }
      }
    }
    final file = File(p.join(temporary.path, 'terrain.png'));
    await file.writeAsBytes(image.encodePng(pixels));
    final imported = await port.importImage(
      ResourceImageImport(
        sourcePath: file.path,
        name: 'Planche UwU V',
        tileWidth: 16,
        tileHeight: 16,
      ),
    );
    final sheet = imported.manifest.tilesets.singleWhere(
      (entry) => entry.id == imported.createdTilesetId,
    );
    final model = TerrainDraftController(
      manifest: imported.manifest,
      atlas: terrainAtlas(sheet, 'uwu5-atlas'),
      id: 'uwu5-path',
      name: 'Chemin conservé',
    );
    for (var i = 0; i < 16; i++) {
      model.selectedRule = i;
      model.assign(
        discriminatingTerrain ? i % 2 : 0,
        discriminatingTerrain ? (i ~/ 2) % 2 : 0,
      );
    }
    await model.save(
      (action, parameters) async =>
          (await port.mutate(action, parameters)).manifest,
      publish: true,
    );
    await model.save(
      (action, parameters) async =>
          (await port.mutate(action, parameters)).manifest,
    );
    final published = await port.mutate('smart_tile.preset.rename', {
      'presetId': 'uwu5-path',
      'name': 'Sentier des étoiles',
    });
    final republished = await port.mutate('smart_tile.preset.publish', {
      'draftId': model.draft.id,
    });
    expect(
      republished.manifest.smartTileCatalog.presets.single.name,
      'Sentier des étoiles',
    );
    expect(
      republished.manifest.smartTileCatalog.presets.single.rules,
      published.manifest.smartTileCatalog.presets.single.rules,
    );
    final borderImage = File(p.join(temporary.path, 'border.png'));
    await borderImage.writeAsBytes(
      image.encodePng(
        image.Image(width: 32, height: 32)
          ..clear(image.ColorRgba8(241, 117, 23, 255)),
      ),
    );
    final borderSheet = await port.importImage(
      ResourceImageImport(
        sourcePath: borderImage.path,
        name: 'Planche bordure UwU V',
        tileWidth: 16,
        tileHeight: 16,
      ),
    );
    for (final role in ['cap', 'straight', 'corner']) {
      await port.saveElement(
        ProjectElementEntry(
          id: 'uwu5-$role',
          name: role,
          tilesetId: borderSheet.createdTilesetId!,
          categoryId: published.manifest.elementCategories.first.id,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      );
    }
    await port.createBorder(
      const BorderCreationRequest(
        name: 'Muret conservé',
        blueprintId: 'uwu5-border',
        capElementId: 'uwu5-cap',
        straightElementId: 'uwu5-straight',
        cornerElementId: 'uwu5-corner',
      ),
    );
    final manifest = await source.maps.loadProject(source.session);
    final base = await source.maps.loadMap(source.session, manifest.maps.first);
    final cells = List<int>.filled(
      base.map.size.width * base.map.size.height,
      0,
    );
    cells[8 * base.map.size.width + 5] = 1;
    if (discriminatingTerrain) {
      cells[9 * base.map.size.width + 5] = 1;
      cells[9 * base.map.size.width + 6] = 1;
    }
    await source.maps.saveMap(
      source.session,
      base,
      addBorderLayer(
        base.map.copyWith(
          layers: [
            SmartTileLayer(
              id: 'uwu5-painted',
              name: 'Chemin peint',
              presetId: 'uwu5-path',
              usage: SmartTileUsage.path,
              materialPalette: const ['', 'material-uwu5-path'],
              field: SmartTileField.cell(semanticCells: cells),
            ),
            ...base.map.layers,
          ],
        ),
        id: 'uwu5-border-layer',
        name: 'Bordures',
        insertIndex: resolveAuthoredLayerInsertIndex(
          base.map,
          activeLayerId: null,
        ),
      ),
    );
    final projectFile = File(p.join(source.directory.path, 'project.json'));
    final current = await source.maps.loadProject(source.session);
    final guide = current.characters.singleWhere(
      (entry) => entry.id == 'guide',
    );
    await projectFile.writeAsString(
      jsonEncode(
        current
            .copyWith(
              characters: [
                ...current.characters,
                guide.copyWith(
                  id: 'uwu5-replacement',
                  name: 'Guide remplaçant',
                ),
              ],
            )
            .toJson(),
      ),
    );
    await source.maps.loadProject(source.session);
    await port.mutate('characterStudio.portraitState.create', {
      'displayName': 'Neutral',
    });
    final withState = await source.maps.loadProject(source.session);
    final state = withState.characterStudioCatalog.portraitStates.single.id;
    final portrait = File(p.join(temporary.path, 'portrait.png'));
    await portrait.writeAsBytes(
      image.encodePng(
        image.Image(width: 32, height: 32)
          ..clear(image.ColorRgba8(226, 53, 185, 255)),
      ),
    );
    for (final character in ['guide', 'uwu5-replacement']) {
      await port.importCharacterPortrait(
        CharacterPortraitImport(
          sourcePath: portrait.path,
          characterId: character,
          portraitStateId: state,
        ),
      );
    }
    final dialogue = current.dialogues.single;
    final yarn = File(p.join(source.directory.path, dialogue.relativePath));
    final text = await yarn.readAsString();
    await yarn.writeAsString(
      text.replaceFirst('---\n', '---\n<<portrait guide $state>>\n'),
    );
  } finally {
    await port.dispose();
    await temporary.delete(recursive: true);
  }
}

Future<void> resolveUwu5Character(M3StoryFixture source) async {
  final port = LocalResourceAdapter(
    session: source.session,
    mapAdapter: source.maps,
  );
  try {
    final before =
        await File(
          p.join(source.directory.path, 'project.json'),
        ).readAsString();
    final inspection = await port.prepareOperation(
      'characterStudio.character.deletePlan',
      {'characterId': 'guide'},
    );
    expect(inspection.impact['requiresResolution'], true);
    await port.releasePreparation(inspection);
    expect(
      await File(p.join(source.directory.path, 'project.json')).readAsString(),
      before,
    );
    final planning = Stopwatch()..start();
    final plan = await port
        .prepareOperation('characterStudio.character.delete', {
          'characterId': 'guide',
          'resolution': 'replace',
          'replacementId': 'uwu5-replacement',
        });
    planning.stop();
    final applying = Stopwatch()..start();
    await port.applyPrepared(plan, confirmDestructive: true);
    applying.stop();
    print(
      'UWU5_CHARACTER_PLAN_US=${planning.elapsedMicroseconds} APPLY_US=${applying.elapsedMicroseconds}',
    );
    final after = await source.maps.loadProject(source.session);
    print(
      'UWU5_OWNER_SIZE maps=${after.maps.length} characters=${after.characters.length} dialogues=${after.dialogues.length} tilesets=${after.tilesets.length}',
    );
    expect(after.characters.any((entry) => entry.id == 'guide'), false);
    expect(after.settings.defaultPlayerCharacterId, 'uwu5-replacement');
    final yarn =
        await File(
          p.join(source.directory.path, after.dialogues.single.relativePath),
        ).readAsString();
    expect(yarn, contains('<<portrait uwu5-replacement '));
    expect(yarn, isNot(contains('<<portrait guide ')));
  } finally {
    await port.dispose();
  }
}
