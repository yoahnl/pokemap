import 'package:map_authoring/src/domains/distribution/runtime_unused_border_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('keeps placed borders and omits the ones no document references', () {
    final project = _project(['placed', 'orphan']);

    final projected = projectRuntimeBorderRecords(
      project: project,
      documents: [
        {
          'borders': [
            {'blueprintId': 'placed'},
          ],
        },
      ],
    );

    expect(projected.borderCatalog.records.map((record) => record.id), [
      'placed',
    ]);
    expect(
      projected.borderCatalog.formatVersion,
      project.borderCatalog.formatVersion,
    );
    expect(project.borderCatalog.records, hasLength(2));
  });

  test('keeps borders targeted by a declared dynamic dependency', () {
    final project = PortableCatalogPublication.withProjectDynamicDependencies(
      _project(['placed', 'spawned', 'orphan']),
      [
        CatalogDynamicDependency(
          owner: CatalogDefinitionKey(
              CatalogDefinitionKind.borderRecord, 'placed'),
          targets: [
            CatalogDefinitionKey(CatalogDefinitionKind.borderRecord, 'spawned'),
          ],
        ),
      ],
    );

    final projected = projectRuntimeBorderRecords(
      project: project,
      documents: [
        {'blueprintId': 'placed'},
      ],
    );

    expect(projected.borderCatalog.records.map((record) => record.id), [
      'placed',
      'spawned',
    ]);
  });

  test('a library listing alone does not keep a border', () {
    final project = _project(['placed', 'listed']).copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'borderBlueprint',
            resourceId: 'placed',
          ),
          ResourceLibraryEntry(
            resourceKind: 'borderBlueprint',
            resourceId: 'listed',
          ),
        ],
      ),
    );

    final projected = projectRuntimeBorderRecords(
      project: project,
      documents: [
        {'blueprintId': 'placed'},
      ],
    );

    expect(projected.borderCatalog.records.map((record) => record.id), [
      'placed',
    ]);
    expect(
      projected.resourceLibraryCatalog.entries.map((entry) => entry.resourceId),
      ['placed'],
    );
    validateResourceLibraryTargets(projected);
  });

  test('returns the project untouched when every border is used', () {
    final project = _project(['placed']);

    expect(
      projectRuntimeBorderRecords(
        project: project,
        documents: [
          {'blueprintId': 'placed'},
        ],
      ),
      same(project),
    );
  });
}

ProjectManifest _project(List<String> borderIds) => ProjectManifest(
      name: 'Borders',
      maps: const [],
      tilesets: const [],
      borderCatalog: ProjectBorderCatalog(
        formatVersion: ProjectBorderCatalog.formatVersionV13,
        records: [for (final id in borderIds) _record(id)],
      ),
    );

BorderBlueprintRecord _record(String id) => BorderBlueprintRecord(
      id: id,
      draft: BorderBlueprintDraft(
        baseRevision: 0,
        definition:
            BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>(
          name: 'Border $id',
          previewSeed: BorderSignedInt64.zero,
          template: BorderBlueprintTemplate.organicEdge,
          primitives: const <BorderPrimitiveDraft>[],
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
