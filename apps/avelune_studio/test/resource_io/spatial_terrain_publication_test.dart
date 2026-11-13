import 'dart:io';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/authoring_resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('spatial terrain transforms publish through the local writer and reopen without an atlas', () async {
    final fixture = await AuthoringResourceFixture.create(
      noMaps: true,
      dimension: ProjectDimension.threeD,
    );
    addTearDown(fixture.dispose);
    final input = File('${fixture.directory.path}/terrain-source.glb');
    await input.writeAsBytes(
      triangleGlb(
        edit: (json) {
          json['nodes'] = [
            {
              'mesh': 0,
              'translation': [-.1, 0, 0],
              'scale': [.1, .1, .1],
            },
          ];
        },
      ),
    );
    await fixture.navigation.accept(
      await fixture.resources.importModel(
        sourcePath: input.path,
        name: 'Herbe spatiale',
      ),
    );
    final item = resourceCatalog(fixture.workspace.project!)
        .singleWhere((item) => item.model3d != null);
    fixture.navigation.prepareTerrain(item);
    final model = fixture.navigation.terrain!;
    final maps = await fixture.mapFiles();
    final original = model.draft;
    model.assignModel(item.model3d!, scale: double.nan);
    expect(model.draft, original);
    model.assignModel(item.model3d!, scale: 1.5, offsetX: double.infinity);
    expect(model.draft, original);
    model.assignModel(item.model3d!, scale: 0);
    expect(model.draft, original);
    model.assignModel(
      item.model3d!,
      scale: 1.5,
      offsetX: .125,
      offsetY: .2,
      offsetZ: -.375,
      quarterTurns: 1,
    );
    final part = model.partFor(0)!;
    final source = part.source as SmartTileModel3dSource;
    expect(part.transform.quarterTurns, 1);
    expect(source.scale, 1.5);
    expect(source.offsetX, .125);
    expect(source.offsetY, .2);
    expect(source.offsetZ, -.375);
    final actions = <String>[];
    expect(
      await model.save((action, parameters) {
        actions.add(action);
        return fixture.navigation.mutate(action, parameters);
      }, publish: true),
      isTrue,
      reason: model.error,
    );
    expect(actions, [
      'smart_tile.preset.draft.upsert',
      'smart_tile.preset.publish',
    ]);
    final reopened = await fixture.reopen();
    final preset = reopened.smartTileCatalog.presets.singleWhere(
      (preset) => preset.id == model.draft.targetPresetId,
    );
    expect(preset.rules.single.candidates.single.parts.single, part);
    expect(reopened.smartTileCatalog.atlases, isEmpty);
    expect(reopened.smartTileCatalog.drafts, isEmpty);
    expect(reopened.maps, isEmpty);
    expect(await fixture.mapFiles(), maps);
    expect(model.error, isNull);
  });
}
