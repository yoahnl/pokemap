import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:path/path.dart' as p;

import '../../map_gameplay/test/support/border_jump_fixture.dart';

void main() {
  for (final partitioned in [false, true]) {
    test(
      'map catalog retains Border collision sources partitioned=$partitioned',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'runtime-border-sources-',
        );
        addTearDown(() => root.delete(recursive: true));
        final fixture = BorderJumpFixture();
        final project = fixture.project.copyWith(
          elements: [
            ...fixture.project.elements,
            fixture.project.elements.first.copyWith(id: 'unused-element'),
          ],
        );
        final file = File(p.join(root.path, 'project.json'));
        if (partitioned) {
          final publication = PortableCatalogPublication.encodeProject(project);
          await file.writeAsString(jsonEncode(publication.descriptor));
          for (final object in publication.storage.objects.entries) {
            final target = File(
              p.join(root.path, 'catalog/objects/${object.key}.json'),
            );
            await target.parent.create(recursive: true);
            await target.writeAsBytes(object.value);
          }
        } else {
          await file.writeAsString(jsonEncode(project.toJson()));
        }
        final catalog = await RuntimeProjectCatalog.open(file.path);
        addTearDown(catalog.dispose);
        final selected = await catalog.manifestForMap(fixture.map);
        expect(
          selected.elements.map((element) => element.id),
          unorderedEquals(
            fixture.project.elements.map((element) => element.id),
          ),
        );
        expect(
          selected.elements.any((element) => element.id == 'unused-element'),
          isFalse,
        );
        final binding = fixture.evidence.edges.single;
        final world = GameplayWorldState.initial(
          map: fixture.map,
          project: selected,
          playerPos: GridPos(
            x: binding.expectedCarrierCell.x,
            y: binding.expectedCarrierCell.y - 1,
          ),
          tileWidth: 32,
          tileHeight: 32,
        );
        final result = stepGameplayWorld(
          world,
          const MoveIntent(Direction.south),
        );
        expect(result, isA<Jumped>());
        expect(
          (result as Jumped).plan.binding.owner.featureId,
          fixture.feature.id,
        );
      },
    );
  }
}
