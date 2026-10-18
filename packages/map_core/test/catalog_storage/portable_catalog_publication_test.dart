import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../resource_pack_dependency_graph_test.dart' show fixture, fileBinding;
import '../resource_pack_publication_test.dart'
    show presetFixture, modelFixture, borderFixture, guideFixture;

void main() {
  test(
    'portable units reconstruct native order, supports, files and provenance',
    () {
      final catalog = fixture();
      final built = PortableCatalogPublication.encodeCatalog(catalog);
      expect(built.descriptor['version'], 2);
      expect(jsonEncode(built.descriptor).length, lessThan(512));
      final decoded = PortableCatalogPublication.decodeCatalogSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(decoded.toJson(), catalog.toJson());
      final again = PortableCatalogPublication.encodeCatalog(decoded);
      expect(again.storage.root, built.storage.root);
      expect(again.storage.objects, built.storage.objects);
    },
  );

  test(
    'declared dynamic typed dependencies survive reexport and reject absent owners',
    () {
      final owner = CatalogDefinitionKey(
        CatalogDefinitionKind.element,
        'absent',
      );
      final catalog = ResourcePackCatalog(
        dynamicDependencies: [
          CatalogDynamicDependency(owner: owner, targets: [owner]),
        ],
      );
      expect(
        () => PortableCatalogPublication.encodeCatalog(catalog),
        throwsFormatException,
      );
      final base = fixture();
      final json = base.toJson();
      json['dynamicDependencies'] = [
        CatalogDynamicDependency(
          owner: CatalogDefinitionKey(CatalogDefinitionKind.element, 'chair'),
          targets: [
            CatalogDefinitionKey(CatalogDefinitionKind.element, 'table'),
          ],
        ).toJson(),
      ];
      final declared = ResourcePackCatalog.fromJson(json);
      final built = PortableCatalogPublication.encodeCatalog(declared);
      final imported = PortableCatalogPublication.decodeCatalogSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(imported.toJson(), declared.toJson());
    },
  );
  test('rehashed omitted and forged typed edges are rejected', () {
    final built = PortableCatalogPublication.encodeCatalog(fixture());
    final read = PortableCatalogPublication.readSync(
      built.descriptor,
      readObject: (r) => built.storage.objects[r.sha256]!,
    );
    for (final forge in [false, true]) {
      final units = read.units.map(
        (unit) =>
            unit.key.kind == CatalogDefinitionKind.element &&
                unit.key.id == 'chair'
            ? CatalogDefinitionUnit(
                key: unit.key,
                payload: unit.payload,
                references: forge
                    ? [
                        CatalogDefinitionKey(
                          CatalogDefinitionKind.element,
                          'table',
                        ),
                        ...unit.references,
                      ]
                    : [],
              )
            : unit,
      );
      final changed = CatalogStorageBuilder().build(units);
      expect(
        () => PortableCatalogPublication.decodeCatalogSync({
          ...built.descriptor,
          'root': changed.root.toJson(),
        }, readObject: (r) => changed.objects[r.sha256]!),
        throwsFormatException,
      );
    }
  });

  test('quotas admit exact unit and graph bytes and reject one byte less', () {
    final built = PortableCatalogPublication.encodeCatalog(fixture());
    final read = PortableCatalogPublication.readSync(
      built.descriptor,
      readObject: (r) => built.storage.objects[r.sha256]!,
    );
    final maxUnit = built.storage.objects.values
        .where(
          (bytes) => (jsonDecode(utf8.decode(bytes)) as Map)['type'] == 'unit',
        )
        .map((bytes) => bytes.length)
        .reduce((a, b) => a > b ? a : b);
    for (final decode in [false, true]) {
      void admit(CatalogStorageLimits limits) {
        if (decode) {
          PortableCatalogPublication.decodeCatalogSync(
            built.descriptor,
            readObject: (r) => built.storage.objects[r.sha256]!,
            limits: limits,
          );
        } else {
          PortableCatalogPublication.encodeCatalog(fixture(), limits: limits);
        }
      }

      admit(
        CatalogStorageLimits(
          maxStoredBytes: read.storedBytes,
          maxUnitBytes: maxUnit,
        ),
      );
      expect(
        () => admit(CatalogStorageLimits(maxStoredBytes: read.storedBytes - 1)),
        throwsFormatException,
      );
      expect(
        () => admit(CatalogStorageLimits(maxUnitBytes: maxUnit - 1)),
        throwsFormatException,
      );
    }
  });

  test(
    'project preserves organization, native drafts, typed dynamic declarations and shell',
    () {
      final (base, draft) = guideFixture();
      final project = PortableCatalogPublication.withProjectDynamicDependencies(
        base.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            categories: base.smartTileCatalog.categories,
            atlases: base.smartTileCatalog.atlases,
            materials: base.smartTileCatalog.materials,
            animations: base.smartTileCatalog.animations,
            presets: base.smartTileCatalog.presets,
            patterns: base.smartTileCatalog.patterns,
            drafts: [draft],
          ),
          tilesets: [
            base.tilesets.single.copyWith(
              isWorldTileset: true,
              groupId: 'local-group',
            ),
          ],
        ),
        [
          CatalogDynamicDependency(
            owner: CatalogDefinitionKey(
              CatalogDefinitionKind.tileset,
              base.tilesets.single.id,
            ),
            targets: [
              CatalogDefinitionKey(
                CatalogDefinitionKind.smartTileMaterial,
                base.smartTileCatalog.materials.single.id,
              ),
            ],
          ),
        ],
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final decoded = PortableCatalogPublication.decodeProjectSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(decoded.toJson(), project.toJson());
      expect(
        PortableCatalogPublication.projectDynamicDependencies(
          decoded,
        ).single.owner.id,
        base.tilesets.single.id,
      );
      final shell = PortableCatalogPublication.projectShellSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(shell['tilesets'], isEmpty);
      expect((shell['smartTileCatalog'] as Map)['drafts'], isEmpty);
      expect(
        PortableCatalogPublication.encodeProject(decoded).storage.root,
        built.storage.root,
      );
    },
  );

  test(
    'typed support kinds, embedded groups, studio identities and model definitions roundtrip',
    () {
      final base = fixture();
      final catalog = ResourcePackCatalog(
        tilesets: [
          base.tilesets.single.copyWith(
            elementGroups: [
              const TilesetElementGroup(id: 'embedded', name: 'Embedded'),
            ],
          ),
        ],
        elements: [base.elements.first.copyWith(tilesetGroupId: 'embedded')],
        elementCategories: base.elementCategories,
        models3d: [modelFixture()],
        characters: [
          const ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'sheet',
            portraits: [
              CharacterPortraitVariant(
                portraitStateId: 'same',
                assetId: 'image',
              ),
            ],
            customAnimations: [
              CharacterCustomAnimationClip(
                definitionId: 'same',
                sourceAssetId: 'image',
              ),
            ],
          ),
        ],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: [
            const ProjectSmartTileMaterial(
              id: 'grass',
              name: 'Grass',
              connectionGroupId: 'ground',
            ),
          ],
          atlases: [
            const ProjectSmartTileAtlas(
              id: 'atlas',
              name: 'Atlas',
              tilesetId: 'sheet',
              columns: 1,
              rows: 1,
            ),
          ],
          animations: [
            const ProjectSmartTileAnimation(
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
          patterns: [
            const ProjectSmartTilePattern(
              id: 'pattern',
              name: 'Pattern',
              usage: SmartTileUsage.terrain,
              width: 1,
              height: 1,
              cells: [],
            ),
          ],
        ),
        smartTilePatternIds: ['pattern'],
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
                  sourceRectPx: BorderPixelRect(
                    x: 0,
                    y: 0,
                    width: 1,
                    height: 1,
                  ),
                  durationMs: 100,
                ),
              ],
            ),
          ],
        ),
        characterStudioCatalog: const ProjectCharacterStudioCatalog(
          portraitStates: [
            CharacterPortraitStateDefinition(
              id: 'same',
              displayName: 'Portrait',
            ),
          ],
          customAnimationDefinitions: [
            CharacterCustomAnimationDefinition(
              id: 'same',
              displayName: 'Clip',
              mode: CharacterCustomAnimationMode.directional,
            ),
          ],
        ),
        files: [
          ...base.files,
          fileBinding('glb', 'assets/models3d/model.glb', glb: true),
          fileBinding('snapshot', 'assets/borders/snapshots/test.png'),
        ],
        provenance: base.provenance,
      );
      final built = PortableCatalogPublication.encodeCatalog(catalog);
      final decoded = PortableCatalogPublication.decodeCatalogSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(decoded.toJson(), catalog.toJson());
      final read = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(
        read.units.where(
          (u) => u.key.kind == CatalogDefinitionKind.characterStudioDefinition,
        ),
        hasLength(2),
      );
      expect(
        read.units
            .singleWhere(
              (u) => u.key.kind == CatalogDefinitionKind.borderVisualSnapshot,
            )
            .key
            .id,
        resourcePackBorderSnapshotAlias('a' * 64),
      );
      expect(
        read.units
            .singleWhere((u) => u.key.kind == CatalogDefinitionKind.character)
            .references
            .where(
              (key) =>
                  key.kind == CatalogDefinitionKind.characterStudioDefinition,
            ),
        hasLength(2),
      );
      expect(
        read.units
            .singleWhere((u) => u.key.kind == CatalogDefinitionKind.element)
            .references,
        contains(CatalogDefinitionKey(CatalogDefinitionKind.tileset, 'sheet')),
      );
    },
  );

  test(
    'large classification is fragmented with no catalog sized reference array',
    () {
      final catalog = ResourcePackCatalog(
        elementCategories: List.generate(
          13000,
          (i) => ProjectElementCategory(id: 'c$i', name: 'Category $i'),
        ),
      );
      final built = PortableCatalogPublication.encodeCatalog(catalog);
      final read = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(
        read.units.where(
          (u) => u.key.kind == CatalogDefinitionKind.elementCategory,
        ),
        hasLength(13000),
      );
      expect(read.units.every((u) => u.references.length <= 4096), isTrue);
      expect(
        PortableCatalogPublication.decodeCatalogSync(
          built.descriptor,
          readObject: (r) => built.storage.objects[r.sha256]!,
        ).toJson(),
        catalog.toJson(),
      );
    },
  );

  test('legacy envelope and payload corruption fail strictly', () {
    final built = PortableCatalogPublication.encodeCatalog(fixture());
    expect(
      () => PortableCatalogPublication.decodeCatalogSync(
        fixture().toJson(),
        readObject: (r) => built.storage.objects[r.sha256]!,
      ),
      throwsFormatException,
    );
    final damaged = {...built.storage.objects};
    final unit = damaged.keys.firstWhere(
      (key) =>
          (jsonDecode(utf8.decode(damaged[key]!)) as Map)['type'] == 'unit',
    );
    damaged[unit] = [0];
    expect(
      () => PortableCatalogPublication.decodeCatalogSync(
        built.descriptor,
        readObject: (r) => damaged[r.sha256]!,
      ),
      throwsFormatException,
    );
  });
  test('canonical pack closure follows declared dynamic targets', () {
    final json = fixture().toJson();
    json['dynamicDependencies'] = [
      CatalogDynamicDependency(
        owner: CatalogDefinitionKey(CatalogDefinitionKind.element, 'chair'),
        targets: [CatalogDefinitionKey(CatalogDefinitionKind.element, 'table')],
      ).toJson(),
    ];
    final graph = ResourcePackDependencyGraph.fromCatalog(
      ResourcePackCatalog.fromJson(json),
    );
    expect(
      graph
          .closure(
            roots: [
              ResourcePackRef(kind: ResourcePackKind.element, id: 'chair'),
            ],
          )
          .resources
          .map((ref) => ref.id),
      contains('table'),
    );
    for (final kind in [
      CatalogDefinitionKind.catalogMetadata,
      CatalogDefinitionKind.resourceLibraryEntry,
      CatalogDefinitionKind.provenance,
      CatalogDefinitionKind.fileBinding,
    ]) {
      expect(
        () => CatalogDynamicDependency(
          owner: CatalogDefinitionKey(kind, 'unknown'),
          targets: [
            CatalogDefinitionKey(CatalogDefinitionKind.element, 'chair'),
          ],
        ),
        throwsFormatException,
      );
    }
  });
  test('one origin can own more resources than a unit reference ceiling', () {
    final base = fixture();
    final elements = List.generate(
      4200,
      (i) => base.elements.first.copyWith(id: 'item-$i', name: 'Item $i'),
    );
    final catalog = ResourcePackCatalog(
      tilesets: base.tilesets,
      elements: elements,
      elementCategories: base.elementCategories,
      files: base.files,
      provenance: [
        ResourcePackProvenance(
          id: 'author',
          author: 'Original',
          licenseIds: [],
          resources: elements.map(
            (element) =>
                ResourcePackRef(kind: ResourcePackKind.element, id: element.id),
          ),
        ),
      ],
    );
    final built = PortableCatalogPublication.encodeCatalog(catalog);
    final imported = PortableCatalogPublication.decodeCatalogSync(
      built.descriptor,
      readObject: (r) => built.storage.objects[r.sha256]!,
    );
    expect(imported.toJson(), catalog.toJson());
    expect(
      PortableCatalogPublication.encodeCatalog(imported).storage.root,
      built.storage.root,
    );
    final read = PortableCatalogPublication.readSync(
      built.descriptor,
      readObject: (r) => built.storage.objects[r.sha256]!,
    );
    final member = read.units.firstWhere(
      (unit) => unit.payload['section'] == r'$provenanceMembership',
    );
    final forged = CatalogStorageBuilder().build(
      read.units.map(
        (unit) => unit.key == member.key
            ? CatalogDefinitionUnit(
                key: unit.key,
                payload: unit.payload,
                references: [],
              )
            : unit,
      ),
    );
    expect(
      () => PortableCatalogPublication.decodeCatalogSync({
        ...built.descriptor,
        'root': forged.root.toJson(),
      }, readObject: (r) => forged.objects[r.sha256]!),
      throwsFormatException,
    );
    final missing = CatalogStorageBuilder().build(
      read.units.where((unit) => unit.key != member.key),
    );
    expect(
      () => PortableCatalogPublication.decodeCatalogSync({
        ...built.descriptor,
        'root': missing.root.toJson(),
      }, readObject: (r) => missing.objects[r.sha256]!),
      throwsFormatException,
    );
  });

  test(
    'large non asset project collections keep a bounded shell and exact order',
    () {
      final project = ProjectManifest(
        name: 'Large game',
        maps: List.generate(
          8000,
          (i) => ProjectMapEntry(
            id: 'map-$i',
            name: 'Map $i ${'long' * 30}',
            relativePath: 'maps/$i.json',
          ),
        ),
        tilesets: [],
        resourcePackInstallations: ResourcePackInstallationCatalog(
          entries: [
            ResourcePackInstallation(
              installationId: 'large-import',
              packId: 'avelune.large',
              packVersion: '1.0.0',
              universeId: 'avelune.test',
              archiveRawSha256: 'a' * 64,
              catalogRawSha256: 'b' * 64,
              copyOrdinal: 0,
              selectedRoots: [
                ResourcePackRef(kind: ResourcePackKind.element, id: 'source-0'),
              ],
              resources: List.generate(
                8000,
                (i) => ResourcePackResourceMapping(
                  source: ResourcePackRef(
                    kind: ResourcePackKind.element,
                    id: 'source-$i',
                  ),
                  targetId: 'installed-$i',
                  definitionRawSha256: 'c' * 64,
                ),
              ),
              supports: [],
              assets: [],
              origins: [],
              licenses: [],
              installedAtUtc: '2026-10-18T10:00:00.000Z',
              provenanceStatus: ResourcePackProvenanceStatus.declared,
            ),
          ],
        ),
        globalProperties: {
          'history': List.generate(
            16000,
            (i) => {'index': i, 'text': 'record' * 16},
          ),
        },
      );
      expect(
        utf8.encode(jsonEncode(project.toJson())).length,
        greaterThan(1048576),
      );
      final built = PortableCatalogPublication.encodeProject(project);
      final decoded = PortableCatalogPublication.decodeProjectSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(decoded.toJson(), project.toJson());
      expect(
        PortableCatalogPublication.encodeProject(decoded).storage.root,
        built.storage.root,
      );
      final read = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (r) => built.storage.objects[r.sha256]!,
      );
      expect(
        utf8
            .encode(
              jsonEncode(
                read.units
                    .singleWhere((unit) => unit.key.id == 'publication-shell')
                    .payload,
              ),
            )
            .length,
        lessThan(65536),
      );
      final chunk = read.units.firstWhere(
        (unit) => unit.payload['section'] == r'$projectAggregateChunk',
      );
      final missing = CatalogStorageBuilder().build(
        read.units.where((unit) => unit.key != chunk.key),
      );
      expect(
        () => PortableCatalogPublication.decodeProjectSync({
          ...built.descriptor,
          'root': missing.root.toJson(),
        }, readObject: (r) => missing.objects[r.sha256]!),
        throwsFormatException,
      );
      final forged = CatalogStorageBuilder().build(
        read.units.map(
          (unit) => unit.key == chunk.key
              ? CatalogDefinitionUnit(
                  key: unit.key,
                  payload: {
                    ...unit.payload,
                    'value': {
                      ...unit.payload['value'] as Map<String, Object?>,
                      'data': base64.encode(List.filled(65536, 0)),
                    },
                  },
                  references: unit.references,
                )
              : unit,
        ),
      );
      expect(
        () => PortableCatalogPublication.decodeProjectSync({
          ...built.descriptor,
          'root': forged.root.toJson(),
        }, readObject: (r) => forged.objects[r.sha256]!),
        throwsFormatException,
      );
      expect(
        () => PortableCatalogPublication.encodeProject(
          project.copyWith(
            maps: [
              ProjectMapEntry(
                id: 'huge',
                name: 'x' * 1048576,
                relativePath: 'maps/huge.json',
              ),
            ],
          ),
        ),
        throwsFormatException,
      );
    },
  );
  test(
    '4096 dynamic targets fit without an incidental metadata edge overflow',
    () {
      final owner = CatalogDefinitionKey(
        CatalogDefinitionKind.smartTileCategory,
        'owner',
      );
      final targets = List.generate(
        4096,
        (index) => CatalogDefinitionKey(
          CatalogDefinitionKind.smartTileCategory,
          'target-$index',
        ),
      );
      final catalog = ResourcePackCatalog(
        smartTileCatalog: ProjectSmartTileCatalog(
          categories: [
            const ProjectSmartTileCategory(id: 'owner', name: 'Owner'),
            for (final target in targets)
              ProjectSmartTileCategory(id: target.id, name: target.id),
          ],
        ),
        dynamicDependencies: [
          CatalogDynamicDependency(owner: owner, targets: targets),
        ],
      );
      final built = PortableCatalogPublication.encodeCatalog(catalog);
      final read = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (reference) => built.storage.objects[reference.sha256]!,
      );
      expect(
        read.units.singleWhere((unit) => unit.key == owner).references,
        hasLength(4096),
      );
      expect(
        read.units
            .singleWhere(
              (unit) => unit.payload['section'] == 'dynamicDependencies',
            )
            .references,
        [owner],
      );
      expect(
        PortableCatalogPublication.decodeCatalogSync(
          built.descriptor,
          readObject: (reference) => built.storage.objects[reference.sha256]!,
        ).toJson(),
        catalog.toJson(),
      );
    },
  );
  test(
    'project publication rejects self and mutually cyclic dynamic declarations',
    () {
      final (base, _) = guideFixture();
      final first = CatalogDefinitionKey(
        CatalogDefinitionKind.tileset,
        base.tilesets.single.id,
      );
      final second = CatalogDefinitionKey(
        CatalogDefinitionKind.tileset,
        'second',
      );
      final project = base.copyWith(
        tilesets: [
          base.tilesets.single,
          base.tilesets.single.copyWith(id: second.id),
        ],
      );
      for (final declarations in [
        [
          CatalogDynamicDependency(owner: first, targets: [first]),
        ],
        [
          CatalogDynamicDependency(owner: first, targets: [second]),
          CatalogDynamicDependency(owner: second, targets: [first]),
        ],
      ]) {
        expect(
          () => PortableCatalogPublication.encodeProject(
            PortableCatalogPublication.withProjectDynamicDependencies(
              project,
              declarations,
            ),
          ),
          throwsFormatException,
        );
      }
    },
  );
  test('project decoding rejects rehashed cyclic dynamic references', () {
    final (base, _) = guideFixture();
    final first = CatalogDefinitionKey(
      CatalogDefinitionKind.tileset,
      base.tilesets.single.id,
    );
    final second = CatalogDefinitionKey(
      CatalogDefinitionKind.tileset,
      'second',
    );
    final project = PortableCatalogPublication.withProjectDynamicDependencies(
      base.copyWith(
        tilesets: [
          base.tilesets.single,
          base.tilesets.single.copyWith(id: second.id),
        ],
      ),
      [
        CatalogDynamicDependency(owner: first, targets: [second]),
      ],
    );
    final built = PortableCatalogPublication.encodeProject(project);
    final read = PortableCatalogPublication.readSync(
      built.descriptor,
      readObject: (reference) => built.storage.objects[reference.sha256]!,
    );
    final declaration = CatalogDynamicDependency(
      owner: second,
      targets: [first],
    );
    final key = CatalogDefinitionKey(
      CatalogDefinitionKind.catalogMetadata,
      jsonEncode(['dynamic', second.kind.name, second.id]),
    );
    final changed = CatalogStorageBuilder().build([
      for (final unit in read.units)
        unit.key == second
            ? CatalogDefinitionUnit(
                key: unit.key,
                payload: unit.payload,
                references: [first],
              )
            : unit,
      CatalogDefinitionUnit(
        key: key,
        payload: {
          'id': key.id,
          'section':
              'globalProperties.${PortableCatalogPublication.projectDynamicDependenciesKey}',
          'position': 1,
          'value': declaration.toJson(),
        },
        references: [second],
      ),
    ]);
    expect(
      () => PortableCatalogPublication.decodeProjectSync({
        ...built.descriptor,
        'root': changed.root.toJson(),
      }, readObject: (reference) => changed.objects[reference.sha256]!),
      throwsFormatException,
    );
  });

  test('logical metadata guard has exact depth and value boundaries', () {
    PortableCatalogPublication.validateProjectMetadataJson(
      '${'[' * 128}0${']' * 128}',
    );
    expect(
      () => PortableCatalogPublication.validateProjectMetadataJson(
        '${'[' * 129}0${']' * 129}',
      ),
      throwsFormatException,
    );
    final exact = '[${List.filled(999999, '0').join(',')}]';
    PortableCatalogPublication.validateProjectMetadataJson(exact);
    expect(
      () => PortableCatalogPublication.validateProjectMetadataJson(
        '${exact.substring(0, exact.length - 1)},0]',
      ),
      throwsFormatException,
    );
    final strings = jsonEncode({
      'key " [ {': 'value \\ " ] } ${'[' * 160}',
      'values': [true, false, null, -1.2e3],
    });
    PortableCatalogPublication.validateProjectMetadataJson(strings);
    for (final invalid in [
      '[1,]',
      '{"key":}',
      '[01]',
      '[truefalse]',
      '{"key" "value"}',
      '"bad\\x"',
    ]) {
      expect(
        () => PortableCatalogPublication.validateProjectMetadataJson(invalid),
        throwsFormatException,
        reason: invalid,
      );
    }
  });

  test(
    'logical metadata is bounded before encoding and before aggregate JSON decoding',
    () {
      Object? deep = 0;
      for (var depth = 0; depth < 160; depth++) {
        deep = {'nested': deep};
      }
      Object? boundary = 0;
      for (var depth = 0; depth < 126; depth++) {
        boundary = {'nested': boundary};
      }
      final exact = ProjectManifest(
        name: 'Exact depth',
        maps: [],
        tilesets: [],
        globalProperties: {'deep': boundary},
      );
      final exactBuilt = PortableCatalogPublication.encodeProject(exact);
      final exactDecoded = PortableCatalogPublication.decodeProjectSync(
        exactBuilt.descriptor,
        readObject: (reference) =>
            exactBuilt.storage.objects[reference.sha256]!,
      );
      expect(
        PortableCatalogPublication.encodeProject(exactDecoded).storage.root,
        exactBuilt.storage.root,
      );
      expect(
        () => PortableCatalogPublication.encodeProject(
          exact.copyWith(
            globalProperties: {
              'deep': {'nested': boundary},
            },
          ),
        ),
        throwsFormatException,
      );
      final base = ProjectManifest(
        name: 'Guard',
        maps: [],
        tilesets: [],
        globalProperties: {'padding': 'x' * 90000, 'deep': 0},
      );
      expect(
        () => PortableCatalogPublication.encodeProject(
          base.copyWith(
            globalProperties: {'padding': 'x' * 90000, 'deep': deep},
          ),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'guard',
            contains('logical depth limit'),
          ),
        ),
      );
      final built = PortableCatalogPublication.encodeProject(base);
      final read = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (reference) => built.storage.objects[reference.sha256]!,
      );
      final bytes = utf8.encode(
        jsonEncode({'padding': 'x' * 90000, 'deep': deep}),
      );
      expect((bytes.length + 65535) ~/ 65536, 2);
      final forged = CatalogStorageBuilder().build(
        read.units.map((unit) {
          final section = unit.payload['section'];
          if (section != r'$projectAggregateHeader' &&
              section != r'$projectAggregateChunk') {
            return unit;
          }
          final value = unit.payload['value'] as Map<String, Object?>;
          if (value['field'] != 'globalProperties') return unit;
          final updated = {...value};
          if (section == r'$projectAggregateHeader') {
            updated['byteLength'] = bytes.length;
            updated['chunkCount'] = 2;
            updated['sha256'] = crypto.sha256.convert(bytes).toString();
          } else {
            final start = (unit.payload['position'] as int) * 65536;
            updated['data'] = base64.encode(
              bytes.sublist(start, (start + 65536).clamp(0, bytes.length)),
            );
          }
          return CatalogDefinitionUnit(
            key: unit.key,
            payload: {...unit.payload, 'value': updated},
            references: unit.references,
          );
        }),
      );
      expect(
        () => PortableCatalogPublication.decodeProjectSync({
          ...built.descriptor,
          'root': forged.root.toJson(),
        }, readObject: (reference) => forged.objects[reference.sha256]!),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'guard',
            contains('logical depth limit'),
          ),
        ),
      );
    },
  );
  test(
    'logical value budget is cumulative across native shell and aggregate chunks',
    () {
      final base = ProjectManifest(name: 'Values', maps: [], tilesets: []);
      int count(Object? value) =>
          1 +
          (value is Map<String, Object?>
              ? value.values.fold<int>(0, (sum, child) => sum + count(child))
              : value is List
              ? value.fold<int>(0, (sum, child) => sum + count(child))
              : 0);
      final values = List.filled(1000000 - count(base.toJson()) - 1, 0);
      final project = base.copyWith(globalProperties: {'values': values});
      final built = PortableCatalogPublication.encodeProject(project);
      expect(
        PortableCatalogPublication.decodeProjectSync(
          built.descriptor,
          readObject: (reference) => built.storage.objects[reference.sha256]!,
        ).toJson(),
        project.toJson(),
      );
      final overflow = {
        'values': [...values, 0],
      };
      expect(
        () => PortableCatalogPublication.encodeProject(
          base.copyWith(globalProperties: overflow),
        ),
        throwsFormatException,
      );
      final bytes = utf8.encode(jsonEncode(overflow));
      final read = PortableCatalogPublication.readSync(
        built.descriptor,
        readObject: (reference) => built.storage.objects[reference.sha256]!,
      );
      final forged = CatalogStorageBuilder().build(
        read.units.map((unit) {
          final section = unit.payload['section'];
          if (section != r'$projectAggregateHeader' &&
              section != r'$projectAggregateChunk') {
            return unit;
          }
          final value = unit.payload['value'] as Map<String, Object?>;
          if (value['field'] != 'globalProperties') return unit;
          final updated = {...value};
          if (section == r'$projectAggregateHeader') {
            updated['byteLength'] = bytes.length;
            updated['chunkCount'] = (bytes.length + 65535) ~/ 65536;
            updated['sha256'] = crypto.sha256.convert(bytes).toString();
          } else {
            final start = (unit.payload['position'] as int) * 65536;
            updated['data'] = base64.encode(
              bytes.sublist(start, (start + 65536).clamp(0, bytes.length)),
            );
          }
          return CatalogDefinitionUnit(
            key: unit.key,
            payload: {...unit.payload, 'value': updated},
            references: unit.references,
          );
        }),
      );
      expect(
        () => PortableCatalogPublication.decodeProjectSync({
          ...built.descriptor,
          'root': forged.root.toJson(),
        }, readObject: (reference) => forged.objects[reference.sha256]!),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'guard',
            contains('logical metadata budget'),
          ),
        ),
      );
    },
  );
}
