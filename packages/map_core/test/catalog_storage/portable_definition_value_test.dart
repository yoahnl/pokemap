import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../resource_pack_dependency_graph_test.dart' show fixture;
import '../resource_pack_publication_test.dart'
    show borderFixture, guideFixture, modelFixture, presetFixture;

void main() {
  late PortableProjectCatalog catalog;
  late List<CatalogDefinitionUnit> units;
  final project = _project();
  final sections = _values(project);

  setUpAll(() async {
    final built = PortableCatalogPublication.encodeProject(project);
    catalog = await PortableProjectCatalog.open(
      built.descriptor,
      readObject: (reference) async => built.storage.objects[reference.sha256]!,
    );
    units = await catalog.snapshot.readAllUnits();
  });

  for (final section in sections.keys) {
    test('direct typed value matches materialized $section', () {
      final selected = units.where(
        (unit) => unit.payload['section'] == section,
      );
      expect(selected, hasLength(sections[section]!.length));
      for (final unit in selected) {
        final materialized = catalog.definitions(
          section.startsWith('resourceLibraryCatalog.')
              ? units.where(
                  (unit) =>
                      unit.key.kind == CatalogDefinitionKind.resourceFamily ||
                      unit.key.kind ==
                          CatalogDefinitionKind.resourceLibraryEntry,
                )
              : [unit],
        );
        final candidates = _values(materialized)[section]!;
        final expected = candidates.length == 1
            ? candidates.single
            : candidates.singleWhere(
                (value) =>
                    _json(value)['id'] == (unit.payload['value'] as Map)['id'],
              );
        final value = catalog.definitionValue(unit);
        expect(value.runtimeType, expected.runtimeType);
        expect(_json(value), _json(expected));
      }
    });
  }

  for (final invalid in ['section', 'kind', 'payload id', 'value id']) {
    test('direct typed value rejects invalid $invalid', () {
      final original = units.firstWhere(
        (unit) => unit.key.kind == CatalogDefinitionKind.tileset,
      );
      final payload = Map<String, Object?>.of(original.payload);
      var key = original.key;
      switch (invalid) {
        case 'section':
          payload['section'] = 'unknown';
        case 'kind':
          key = CatalogDefinitionKey(CatalogDefinitionKind.element, key.id);
        case 'payload id':
          payload.remove('id');
        case 'value id':
          payload['value'] = {
            ...Map<String, Object?>.from(payload['value']! as Map),
            'id': 'another-tileset',
          };
      }
      final invalidUnit = CatalogDefinitionUnit(key: key, payload: payload);
      expect(() => catalog.definitionValue(invalidUnit), throwsFormatException);
    });
  }

  test('direct values preserve valid nonzero definition positions', () {
    final original = units.firstWhere(
      (unit) => unit.key.kind == CatalogDefinitionKind.element,
    );
    final positioned = CatalogDefinitionUnit(
      key: original.key,
      payload: {...original.payload, 'position': 17},
    );
    final expected = catalog.definitions([positioned]).elements.single;
    expect(_json(catalog.definitionValue(positioned)), expected.toJson());
    expect(positioned.payload['position'], 17);
  });

  for (final position in [null, '0', 0.5, -1, 1000000]) {
    test('direct typed values reject invalid position $position', () {
      final original = units.firstWhere(
        (unit) => unit.key.kind == CatalogDefinitionKind.tileset,
      );
      final invalid = CatalogDefinitionUnit(
        key: original.key,
        payload: {...original.payload, 'position': position},
      );
      expect(() => catalog.definitionValue(invalid), throwsFormatException);
    });
  }

  test(
    'direct Border values retain the enclosing catalog version gate',
    () async {
      final older = await _catalogWithHeader(units, 'borderCatalog', 11);
      final original = units.singleWhere(
        (unit) => unit.key.kind == CatalogDefinitionKind.borderRecord,
      );
      final value =
          jsonDecode(jsonEncode(original.payload['value']))
              as Map<String, dynamic>;
      final published = value['latestPublished'] as Map;
      final definition = published['definition'] as Map;
      definition['sequenceLength'] = 2;
      final changed = CatalogDefinitionUnit(
        key: original.key,
        payload: {...original.payload, 'value': value},
      );
      final rejected = throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('requires catalog format version 12'),
        ),
      );
      expect(() => older.definitions([changed]), rejected);
      expect(() => older.definitionValue(changed), rejected);
    },
  );

  test(
    'direct Smart Tile values retain the enclosing catalog version gate',
    () async {
      final older = await _catalogWithHeader(units, 'smartTileCatalog', 7);
      final original = units.singleWhere(
        (unit) => unit.key.kind == CatalogDefinitionKind.smartTilePattern,
      );
      final changed = CatalogDefinitionUnit(
        key: original.key,
        payload: {
          ...original.payload,
          'value': {
            ...Map<String, Object?>.from(original.payload['value']! as Map),
            'construction': <String, Object?>{},
          },
        },
      );
      final rejected = throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('requires catalog format version 8'),
        ),
      );
      expect(() => older.definitions([changed]), rejected);
      expect(() => older.definitionValue(changed), rejected);
    },
  );

  test('direct typed values reject metadata and pack-only definitions', () {
    for (final unit in [
      units.singleWhere((unit) => unit.payload['section'] == r'$shell'),
      CatalogDefinitionUnit(
        key: CatalogDefinitionKey(CatalogDefinitionKind.fileBinding, 'image'),
        payload: {
          'id': 'image',
          'section': 'files',
          'position': 0,
          'value': fixture().files.first.toJson(),
        },
      ),
    ]) {
      expect(() => catalog.definitionValue(unit), throwsFormatException);
    }
  });

  test('direct Border values keep strict malformed-record rejection', () {
    final original = units.singleWhere(
      (unit) => unit.key.kind == CatalogDefinitionKind.borderRecord,
    );
    final invalid = CatalogDefinitionUnit(
      key: original.key,
      payload: {
        ...original.payload,
        'value': {
          ...Map<String, Object?>.from(original.payload['value']! as Map),
          'unexpected': true,
        },
      },
    );
    expect(() => catalog.definitions([invalid]), throwsFormatException);
    expect(() => catalog.definitionValue(invalid), throwsFormatException);
  });
}

Map<String, Object?> _json(Object value) => switch (value) {
  EnvironmentPreset() => encodeEnvironmentPreset(value),
  BorderBlueprintRecord() => encodeBorderBlueprintRecordJson(
    value,
    formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
  ),
  BorderVisualSnapshot() => encodeBorderVisualSnapshotJson(value),
  _ => Map<String, Object?>.from((value as dynamic).toJson() as Map),
};

Map<String, List<Object>> _values(ProjectManifest project) => {
  'tilesets': project.tilesets,
  'elements': project.elements,
  'models3d': project.models3d,
  'characters': project.characters,
  'environmentPresets': project.environmentPresets,
  'elementCategories': project.elementCategories,
  'tilesetFolders': project.tilesetFolders,
  'smartTileCatalog.categories': project.smartTileCatalog.categories,
  'smartTileCatalog.atlases': project.smartTileCatalog.atlases,
  'smartTileCatalog.materials': project.smartTileCatalog.materials,
  'smartTileCatalog.patterns': project.smartTileCatalog.patterns,
  'smartTileCatalog.animations': project.smartTileCatalog.animations,
  'smartTileCatalog.presets': project.smartTileCatalog.presets,
  'smartTileCatalog.drafts': project.smartTileCatalog.drafts,
  'borderCatalog.records': project.borderCatalog.records,
  'borderCatalog.visualSnapshots': project.borderCatalog.visualSnapshots,
  'resourceLibraryCatalog.families': project.resourceLibraryCatalog.families,
  'resourceLibraryCatalog.entries': project.resourceLibraryCatalog.entries,
  'characterStudioCatalog.portraitStates':
      project.characterStudioCatalog.portraitStates,
  'characterStudioCatalog.customAnimationDefinitions':
      project.characterStudioCatalog.customAnimationDefinitions,
};

ProjectManifest _project() {
  final base = fixture();
  return ProjectManifest(
    name: 'Direct typed definitions',
    maps: const [],
    tilesets: [base.tilesets.single.copyWith(folderId: 'folder')],
    elements: base.elements,
    models3d: [modelFixture()],
    elementCategories: base.elementCategories,
    tilesetFolders: const [ProjectTilesetFolder(id: 'folder', name: 'Folder')],
    resourceLibraryCatalog: base.resourceLibraryCatalog,
    characters: const [
      ProjectCharacterEntry(
        id: 'hero',
        name: 'Hero',
        tilesetId: 'sheet',
        portraits: [
          CharacterPortraitVariant(
            portraitStateId: 'same',
            assetId: 'portrait',
          ),
        ],
        customAnimations: [
          CharacterCustomAnimationClip(
            definitionId: 'same',
            sourceAssetId: 'wave',
            direction: EntityFacing.south,
          ),
        ],
      ),
    ],
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: [
        CharacterPortraitStateDefinition(id: 'same', displayName: 'Portrait'),
      ],
      customAnimationDefinitions: [
        CharacterCustomAnimationDefinition(
          id: 'same',
          displayName: 'Animation',
          mode: CharacterCustomAnimationMode.directional,
        ),
      ],
    ),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forest',
        templateId: 'forest_dense',
        palette: [EnvironmentPaletteItem(elementId: 'chair', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: const [
        ProjectSmartTileCategory(id: 'nature', name: 'Nature'),
      ],
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          categoryId: 'nature',
          connectionGroupId: 'ground',
        ),
      ],
      atlases: const [
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'sheet',
          columns: 1,
          rows: 1,
        ),
      ],
      animations: const [
        ProjectSmartTileAnimation(
          id: 'animation',
          name: 'Animation',
          frames: [
            ProjectSmartTileAnimationFrame(
              frame: SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
              durationMs: 100,
            ),
          ],
        ),
      ],
      presets: [presetFixture()],
      drafts: [guideFixture().$2],
      patterns: const [
        ProjectSmartTilePattern(
          id: 'pattern',
          name: 'Pattern',
          usage: SmartTileUsage.terrain,
          width: 1,
          height: 1,
          cells: [],
        ),
      ],
    ),
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [borderFixture()],
      visualSnapshots: [
        BorderVisualSnapshot(
          id: 'border-snapshot-sha256:${'a' * 64}',
          contentFingerprint: 'a' * 64,
          frames: [
            BorderVisualFrameSnapshot(
              relativeAssetPath: 'assets/borders/snapshots/test.png',
              sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
              durationMs: 100,
            ),
          ],
        ),
      ],
    ),
  );
}

Future<PortableProjectCatalog> _catalogWithHeader(
  List<CatalogDefinitionUnit> units,
  String section,
  int version,
) async {
  final changed = [
    for (final unit in units)
      if (unit.payload['section'] == r'$shell')
        CatalogDefinitionUnit(
          key: unit.key,
          payload: {
            ...unit.payload,
            'value': {
              ...Map<String, Object?>.from(unit.payload['value']! as Map),
              section: {
                ...Map<String, Object?>.from(
                  (unit.payload['value']! as Map)[section] as Map,
                ),
                'formatVersion': version,
              },
            },
          },
        )
      else
        unit,
  ];
  final built = CatalogStorageBuilder().build(changed);
  final snapshot = await CatalogSnapshot.open(
    root: built.root,
    readObject: (reference) async => built.objects[reference.sha256]!,
  );
  return PortableProjectCatalog.fromSnapshot(snapshot);
}
