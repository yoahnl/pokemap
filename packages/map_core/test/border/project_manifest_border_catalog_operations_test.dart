import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest Border catalog operations', () {
    test('read returns the exact catalog instance', () {
      final catalog = _catalog('coast');
      final manifest = _manifest(borderCatalog: catalog);

      expect(identical(borderCatalogForProject(manifest), catalog), isTrue);
    });

    test('persisting the first nonempty catalog promotes only the manifest',
        () {
      final original = _manifest(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'port',
            name: 'Port',
            relativePath: 'maps/port.json',
          ),
        ],
        globalProperties: const <String, dynamic>{'keep': 'manifest'},
      );
      final catalog = _catalog('coast');

      final updated = replaceProjectBorderCatalog(original, catalog);

      expect(original.version, ProjectVersion.v6);
      expect(original.borderCatalog.isEmpty, isTrue);
      expect(updated.version, ProjectVersion.v6);
      expect(updated.borderCatalog, catalog);
      expect(updated.name, original.name);
      expect(updated.maps, original.maps);
      expect(updated.tilesets, original.tilesets);
      expect(updated.globalProperties, original.globalProperties);
    });

    test('empty replacement does not promote V1 and never downgrades V2', () {
      final v1 = replaceProjectBorderCatalog(
        _manifest(),
        const ProjectBorderCatalog.empty(),
      );
      final v2 = replaceProjectBorderCatalog(
        _manifest(
          version: ProjectVersion.v6,
          borderCatalog: _catalog('coast'),
        ),
        const ProjectBorderCatalog.empty(),
      );

      expect(v1.version, ProjectVersion.v6);
      expect(v1.borderCatalog.isEmpty, isTrue);
      expect(v2.version, ProjectVersion.v6);
      expect(v2.borderCatalog.isEmpty, isTrue);
    });

    test('nonempty replacement never downgrades a Smart Tile V5 manifest', () {
      final updated = replaceProjectBorderCatalog(
        _manifest(version: ProjectVersion.v6),
        _catalog('coast'),
      );

      expect(updated.version, ProjectVersion.v6);
      expect(updated.borderCatalog.isNotEmpty, isTrue);
    });

    test('update receives the current catalog once and applies promotion', () {
      final current = _catalog('first');
      final next = ProjectBorderCatalog(
        records: <BorderBlueprintRecord>[
          ...current.records,
          _record('second'),
        ],
      );
      var callCount = 0;
      ProjectBorderCatalog? received;

      final updated = updateProjectBorderCatalog(
        _manifest(borderCatalog: current),
        (catalog) {
          callCount += 1;
          received = catalog;
          return next;
        },
      );

      expect(callCount, 1);
      expect(identical(received, current), isTrue);
      expect(updated.version, ProjectVersion.v6);
      expect(updated.borderCatalog, next);
    });

    test('update propagates failure without mutating the source', () {
      final current = _catalog('first');
      final manifest = _manifest(
        version: ProjectVersion.v6,
        borderCatalog: current,
      );

      expect(
        () => updateProjectBorderCatalog(
          manifest,
          (_) => throw StateError('catalog update failed'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(identical(manifest.borderCatalog, current), isTrue);
      expect(manifest.version, ProjectVersion.v6);
    });
  });
}

ProjectManifest _manifest({
  ProjectVersion version = ProjectVersion.v6,
  ProjectBorderCatalog borderCatalog = const ProjectBorderCatalog.empty(),
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[],
  Map<String, dynamic> globalProperties = const <String, dynamic>{},
}) =>
    ProjectManifest(
      name: 'Border operations',
      version: version,
      maps: maps,
      tilesets: const <ProjectTilesetEntry>[],
      borderCatalog: borderCatalog,
      globalProperties: globalProperties,
    );

ProjectBorderCatalog _catalog(String id) => ProjectBorderCatalog(
      records: <BorderBlueprintRecord>[_record(id)],
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
