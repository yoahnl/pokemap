import 'dart:io';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'resource_pack_reedition_host_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Studio terrain survives official roundtrip, no-op republication and a real connection edit', () async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    final root = await parent.createTemp('p11-terrain-reedition-');
    addTearDown(() => root.delete(recursive: true));
    final archive = File('${root.path}/terrain.aveluneassets');
    final a = await Host.create(Directory('${root.path}/A'), archive);
    await a.initialize();
    addTearDown(a.close);
    final atlasId = await addAtlas(a);
    a.navigation.prepareTerrain(
      resourceCatalog(a.workspace.project!)
          .singleWhere((item) => item.tileset?.id == atlasId),
    );
    final workshop = a.navigation.terrain!;
    for (var mask = 0; mask < 16; mask++) {
      workshop.selectedRule = mask;
      final index = mask * 5 % 16;
      workshop.assign(index % 4, index ~/ 4);
    }
    expect(
      await workshop.save(a.navigation.mutate, publish: true),
      isTrue,
      reason: workshop.error,
    );
    final sourceBeforeExport = digest(
      await File('${a.root.path}/project.json').readAsBytes(),
    );
    final sourcePreset = (await a.load()).smartTileCatalog.presets.single;
    await officialExport(a, 'smartTilePreset');
    final b = await importAndReopen(Directory('${root.path}/B'), archive);
    addTearDown(b.close);
    final before = b.workspace.project!;
    final preset = before.smartTileCatalog.presets.single;
    final draft = before.smartTileCatalog.drafts.single;
    expect(draft.guideId, 'avelune-cardinal4-v1');
    expect(draft.rules.map((r) => r.id), sourcePreset.rules.map((r) => r.id));
    for (var i = 0; i < draft.rules.length; i++) {
      expect(
        draft.rules[i].candidates.single.id,
        sourcePreset.rules[i].candidates.single.id,
      );
      final original = sourcePreset.rules[i].candidates.single.parts.single;
      final frame = (original.source as SmartTileFrameSource).frame;
      expect(
        draft.rules[i].candidates.single.parts.single,
        original.copyWith(
          source: SmartTileVisualSource.frame(
            frame: frame.copyWith(atlasId: draft.atlases.single.id),
          ),
        ),
      );
    }
    b.navigation.prepareTerrain(
      resourceCatalog(before)
          .singleWhere((item) => item.terrain?.id == preset.id),
    );
    final resumed = b.navigation.terrain!;
    expect(
      await resumed.save(b.navigation.mutate),
      isTrue,
      reason: resumed.error,
    );
    expect(
      await resumed.save(b.navigation.mutate, publish: true),
      isTrue,
      reason: resumed.error,
    );
    final noOp = await b.load();
    expect(noOp.smartTileCatalog.presets.single, preset);
    expect(noOp.smartTileCatalog.atlases, before.smartTileCatalog.atlases);
    expect(noOp.smartTileCatalog.materials, before.smartTileCatalog.materials);
    await b.close();
    final cArchive = File('${root.path}/edited.aveluneassets');
    final reopened = Host(b.root, cArchive);
    await reopened.initialize();
    addTearDown(reopened.close);
    reopened.navigation.prepareTerrain(
      resourceCatalog(reopened.workspace.project!)
          .singleWhere((item) => item.terrain?.id == preset.id),
    );
    final edited = reopened.navigation.terrain!;
    expect(edited.draft.rules, draft.rules);
    edited.selectedRule = 0;
    edited.assign(1, 0);
    expect(
      await edited.save(reopened.navigation.mutate, publish: true),
      isTrue,
      reason: edited.error,
    );
    final changed = (await reopened.load()).smartTileCatalog.presets.single;
    expect(changed.rules.first, isNot(preset.rules.first));
    expect(changed.rules.skip(1), preset.rules.skip(1));
    await officialExport(reopened, 'smartTilePreset');
    final c = await importAndReopen(Directory('${root.path}/C'), cArchive);
    addTearDown(c.close);
    final finalDraft = c.workspace.project!.smartTileCatalog.drafts.single;
    expect(finalDraft.guideId, 'avelune-cardinal4-v1');
    final finalFrame =
        (finalDraft.rules.first.candidates.single.parts.single.source
                as SmartTileFrameSource)
            .frame;
    expect(finalFrame.column, 1);
    expect(finalFrame.row, 0);
    expect(
      terrainDraftCompatibilityProblem(c.workspace.project!, finalDraft),
      isNull,
    );
    expect(
      digest(await File('${a.root.path}/project.json').readAsBytes()),
      sourceBeforeExport,
    );
  });
}
