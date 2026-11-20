import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../resource_pack_publication_test.dart' show modelFixture;

void main() {
  test(
    'resource preview may resolve a draft without admitting it to a map',
    () async {
      final model = modelFixture();
      final draft = BorderBlueprintRecord(
        id: 'draft-fence',
        draft: BorderBlueprintDraft(
          baseRevision: 0,
          definition: BorderBlueprintDraftDefinition(
            name: 'Clôture',
            previewSeed: BorderSignedInt64.fromInt(12),
            template: BorderBlueprintTemplate.connectedLine,
            primitives: [
              BorderPrimitiveDraft(
                id: 'segment',
                sourceModelId: model.id,
                role: BorderPrimitiveRole.lineStraight,
                weight: 1,
                transforms: BorderTransformPolicy(
                  allowFlipX: false,
                  allowedQuarterTurns: [0],
                ),
              ),
            ],
            defaults: BorderGenerationParams(
              irregularityPermille: 0,
              detailDensityPermille: 0,
              variationPermille: 0,
              maxOverlapPx: 0,
              gapTolerancePx: 0,
              depthRows: 1,
            ),
            sortOrder: 0,
          ),
        ),
      );
      final project = ProjectManifest(
        name: 'Recette Bordures',
        maps: [],
        tilesets: [],
        models3d: [
          model,
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'id': 'unrelated',
            'name': 'Hors sujet',
            'relativePath': 'assets/models3d/unrelated.glb',
          }),
        ],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [draft],
        ),
      );
      final build = PortableCatalogPublication.encodeProject(project);
      final reads = <String>[];
      final catalog = await PortableProjectCatalog.open(
        build.descriptor,
        readObject: (reference) async {
          reads.add(reference.sha256);
          return build.storage.objects[reference.sha256]!;
        },
        metadataFields: {},
      );
      final unrelated = await catalog.snapshot.indexEntry(
        CatalogDefinitionKey(CatalogDefinitionKind.model3d, 'unrelated'),
      );
      final key = CatalogDefinitionKey(
        CatalogDefinitionKind.borderRecord,
        'draft-fence',
      );
      final selection = ProjectCatalogSelection(catalog);
      await expectLater(selection.resolve([key]), throwsFormatException);
      reads.clear();
      final preview = await selection.resolve([
        key,
      ], allowUnpublishedBorders: true);
      expect(preview.borderCatalog.records, [draft]);
      expect(preview.models3d, [model]);
      expect(reads, isNot(contains(unrelated!.reference.sha256)));
      await expectLater(
        selection.forMap(
          const MapData(
            id: 'map',
            name: 'Carte',
            size: GridSize(width: 8, height: 8),
          ),
          additionalRoots: [key],
        ),
        throwsFormatException,
      );
    },
  );
}
