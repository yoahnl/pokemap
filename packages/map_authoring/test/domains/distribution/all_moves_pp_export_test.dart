import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../tool/generate_synthetic_catalog_project.dart' as generator;

void main() {
  for (final allMoves in [false, true]) {
    test(
        'canonical export derives PP capability from authored scope all=$allMoves',
        () async {
      final temporary = await Directory.systemTemp.createTemp('all-pp-export-');
      addTearDown(() => temporary.delete(recursive: true));
      final root = Directory('${temporary.path}/project');
      final profile = File('${temporary.path}/profile.json');
      await generator.generateSyntheticCatalogProject(
        projectRoot: root,
        profileFile: profile,
        receiptFile: File('${temporary.path}/fixture.json'),
      );
      final items = File('${root.path}/data/pokemon/catalogs/items.json');
      await items.parent.create(recursive: true);
      final catalog = ProjectItemCatalog(schemaVersion: 1, entries: [
        ProjectItemDefinition(
          id: 'pp-item',
          displayName: 'PP',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
              contexts: {
                ProjectItemUseContext.overworld,
                ProjectItemUseContext.battle
              },
              target: allMoves
                  ? ProjectItemTargetKind.partyMember
                  : ProjectItemTargetKind.partyMove,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.restorePp(
                  mode: ProjectItemAmountMode.flat,
                  amount: 10,
                  scope: allMoves
                      ? ProjectItemPpScope.allMoves
                      : ProjectItemPpScope.selectedMove),
            )
          ],
        )
      ]);
      await items.writeAsString(jsonEncode(encodeProjectItemCatalog(catalog)));
      final original = await items.readAsBytes();
      final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile:
            GamePackageExportProfile.decodeUtf8(await profile.readAsBytes()),
      );
      expect(
          artifact.manifest.compatibility.requiredCapabilities
              .contains(ItemPpRestoreCapabilities.allMovesCapabilityId),
          allMoves);
      final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
      final exported = decodeProjectItemCatalog(jsonDecode(utf8.decode(archive
          .findFile('project/data/pokemon/catalogs/items.json')!
          .content)));
      expect(exported, catalog.normalized());
      expect(await items.readAsBytes(), original);
    });
  }
}
