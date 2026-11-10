import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/authoring_resource_fixture.dart';
import '../support/resource_library_context_seed.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AuthoringResourceFixture> open() async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    return fixture;
  }

  test('context-only classification saves reopens and clears all seven resource kinds', () async {
    final fixture = await open();
    final project = await seedResourceLibraryKinds(fixture);
    final items = resourceCatalog(project);
    final mapsBefore = await fixture.mapFiles();
    const contexts = {
      ResourcePlacementContext.interior: 'Intérieur',
      ResourcePlacementContext.exterior: 'Extérieur',
      ResourcePlacementContext.both: 'Les deux',
      null: 'Non renseigné',
    };
    for (final kind in [
      'element',
      'smartTilePreset',
      'tileset',
      'model3d',
      'borderBlueprint',
      'environmentPreset',
      'character',
    ]) {
      final item = items.firstWhere((item) => item.canonicalKind == kind);
      for (final context in contexts.entries) {
        final failure = await publishResourceLibraryChange(
          fixture.navigation,
          'resource.classify',
          {
            'resourceKind': kind,
            'resourceId': item.id,
            'description': null,
            'placementContext': context.key?.name,
            'role': 'standard',
            'familyId': null,
            'mapId': null,
          },
        );
        expect(failure, isNull, reason: '$kind ${context.value}');
        final reopened = await fixture.reopen();
        final entry = reopened.resourceLibraryCatalog.entryFor(kind, item.id);
        expect(
          entry?.placementContext,
          context.key,
          reason: '$kind ${context.value}',
        );
        expect(resourceCatalogContextLabel(reopened, item), context.value);
        expect(entry?.familyId, isNull);
        expect(entry?.mapId, isNull);
        expect(
          entry?.role ?? ResourceLibraryRole.standard,
          ResourceLibraryRole.standard,
        );
      }
    }
    expect(await fixture.mapFiles(), mapsBefore);
    expect((await fixture.reopen()).resourceLibraryCatalog.entries, isEmpty);
  });

  test(
    'classifying a local resource persists without changing map contents',
    () async {
      final fixture = await open();
      final imported = await fixture.resources.importImage(
        ResourceImageImport(
          sourcePath: '${fixture.directory.path}/assets/atelier.png',
          name: 'Source de l’arbre local',
          tileWidth: 16,
          tileHeight: 16,
        ),
      );
      await fixture.navigation.accept(imported);
      final original = imported.manifest.elements.first;
      final receipt = await fixture.resources.mutate('element.upsert', {
        'element': original
            .copyWith(
              id: 'arbre-local',
              name: 'Arbre unique',
              tilesetId: imported.createdTilesetId!,
              frames: original.frames
                  .map(
                    (frame) =>
                        frame.copyWith(tilesetId: imported.createdTilesetId!),
                  )
                  .toList(),
            )
            .toJson(),
      });
      await fixture.navigation.accept(receipt);
      final mapsBefore = await fixture.mapFiles();
      expect(
        await publishResourceLibraryChange(
          fixture.navigation,
          'resource.classify',
          {
            'resourceKind': 'element',
            'resourceId': 'arbre-local',
            'familyId': 'trees',
            'mapId': 'jardin',
          },
        ),
        isNull,
      );
      final catalog = (await fixture.reopen()).resourceLibraryCatalog;
      expect(catalog.entryFor('element', 'arbre-local')?.familyId, 'trees');
      expect(catalog.entryFor('element', 'arbre-local')?.mapId, 'jardin');
      expect(
        catalog.availableForMap('element', 'arbre-local', 'clairiere'),
        isFalse,
      );
      expect(await fixture.mapFiles(), mapsBefore);
    },
  );
}
