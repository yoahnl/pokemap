import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import 'map_catalog_fixture.dart';

void main() {
  test('closed map adds terrain reference after initial check under lock',
      () async {
    final original = smartInformationFixture();
    final manifest = original.copyWith(
      maps: const [
        ProjectMapEntry(
            id: 'closed', name: 'Fermée', relativePath: 'closed.json'),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        categories: original.smartTileCatalog.categories,
        atlases: original.smartTileCatalog.atlases,
        materials: original.smartTileCatalog.materials,
        presets: original.smartTileCatalog.presets,
      ),
    );
    final fixture =
        await ResourceInformationFixture.create(manifest.copyWith(maps: []));
    addTearDown(fixture.dispose);
    final map = catalogMap('closed');
    final mapFile = File('${fixture.root.path}/closed.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    await File('${fixture.root.path}/project.json')
        .writeAsString(jsonEncode(manifest.toJson()));
    final plan =
        await fixture.plan('smart_tile.preset.delete', {'presetId': 'ground'});
    expect(plan.status, AuthoringResultStatus.success,
        reason: jsonEncode(plan.toJson()));
    final confirmation = await fixture.command('confirm', {
      'projectHandle': fixture.project,
      'planId': plan.data['planId'],
    });
    final before =
        await File('${fixture.root.path}/project.json').readAsBytes();
    var checked = false;
    await expectLater(
      fixture.mutations.applyMutation(
        ProjectHandle(fixture.project),
        planId: plan.data['planId'] as String,
        operationId: 'terrain-locked-reference',
        confirmationToken: confirmation.data['confirmationToken'] as String,
        precondition: () async {
          checked = true;
          final changed = map.copyWith(layers: [
            ...map.layers,
            SmartTileLayer(
              id: 'semantic',
              name: 'Terrain',
              presetId: 'ground',
              usage: SmartTileUsage.terrain,
              materialPalette: const ['', 'material'],
              field: SmartTileField.cell(semanticCells: List.filled(30, 1)),
            ),
          ]);
          await mapFile.writeAsString(jsonEncode(changed.toJson()));
        },
      ),
      throwsA(isA<AuthoringPlanException>()
          .having((error) => error.code, 'code', 'plan.stale')),
    );
    expect(checked, isTrue);
    expect(
        await File('${fixture.root.path}/project.json').readAsBytes(), before);
    final reread = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
    expect(reread.layers.whereType<SmartTileLayer>().single.presetId, 'ground');
  });
}
