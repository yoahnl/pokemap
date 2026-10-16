import 'package:map_core/src/models/resource_pack.dart';
import 'package:map_core/src/models/resource_pack_installation_catalog.dart';
import 'package:test/test.dart';

Map<String, Object?> packManifestJson() => {
  'format': 'avelune.asset-pack',
  'formatVersion': 1,
  'pack': {
    'id': 'avelune.original-fixture',
    'version': '1.0.0',
    'name': 'Atelier original',
    'description': 'Ressources de contrôle',
    'universeId': 'avelune.original',
    'authors': ['Avelune'],
    'provenance': 'Original test fixture',
  },
  'compatibility': {
    'resourceLibraryCatalogVersion': 2,
    'smartTileCatalogVersion': 7,
    'borderCatalogVersion': 10,
    'requiredCapabilities': ['resources.element'],
    'tileWidth': 16,
    'tileHeight': 16,
  },
  'content': {
    'catalog': {
      'path': 'catalog.json',
      'byteLength': 2,
      'mediaType': 'application/json',
      'rawSha256': 'a' * 64,
    },
    'files': [
      {
        'path': 'blobs/${'b' * 64}.png',
        'byteLength': 10,
        'mediaType': 'image/png',
        'rawSha256': 'b' * 64,
      },
      {
        'path': 'licenses/${'c' * 64}.txt',
        'byteLength': 20,
        'mediaType': 'text/plain',
        'rawSha256': 'c' * 64,
      },
    ],
    'treeSha256': 'd' * 64,
  },
};

Map<String, Object?> _object(Object? value) =>
    Map<String, Object?>.from(value! as Map);

void main() {
  test('each definition carries its own provenance even with shared media', () {
    final json = <String, Object?>{
      'id': 'author-one',
      'author': 'Author one',
      'licenseIds': <String>[],
      'resources': [
        {'resourceKind': 'element', 'id': 'chair'},
      ],
    };
    final first = ResourcePackProvenance.fromJson(json);
    final second = ResourcePackProvenance.fromJson({
      ...json,
      'id': 'author-two',
      'author': 'Author two',
      'resources': [
        {'resourceKind': 'element', 'id': 'cupboard'},
      ],
    });
    expect(first.toJson()['resources'], [
      {'resourceKind': 'element', 'id': 'chair'},
    ]);
    expect(second.toJson()['resources'], [
      {'resourceKind': 'element', 'id': 'cupboard'},
    ]);
    expect(ResourcePackProvenance.fromJson(first.toJson()), first);
    expect(
      () => ResourcePackProvenance.fromJson({
        ...json,
        'resources': [
          {'resourceKind': 'element', 'id': 'chair'},
          {'resourceKind': 'element', 'id': 'chair'},
        ],
      }),
      throwsFormatException,
    );
  });

  test(
    'a pattern-only selection records supports without a dummy resource',
    () {
      final json = _originJson()
        ..['selectedRoots'] = <Object?>[]
        ..['resources'] = <Object?>[]
        ..['selectedSmartTilePatternIds'] = ['flowers']
        ..['supports'] = [
          {
            'kind': 'smartTilePattern',
            'sourceId': 'flowers',
            'targetId': 'rp_flowers',
          },
        ];
      final origin = ResourcePackInstallation.fromJson(json);
      expect(origin.selectedRoots, isEmpty);
      expect(origin.resources, isEmpty);
      expect(origin.toJson()['selectedSmartTilePatternIds'], ['flowers']);
      expect(ResourcePackInstallation.fromJson(origin.toJson()), origin);
      expect(
        () => ResourcePackInstallation.fromJson({
          ...json,
          'supports': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ResourcePackInstallation.fromJson({
          ...json,
          'selectedSmartTilePatternIds': ['absent'],
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'asset aliases require one consistent native record within an origin',
    () {
      final asset = <String, Object?>{
        'fileId': 'first',
        'assetId': 'asset_native',
        'targetPath': 'assets/images/first.png',
        'rawSha256': 'd' * 64,
        'byteLength': 32,
        'mediaType': 'image/png',
      };
      final json = _originJson()
        ..['assets'] = [
          asset,
          {...asset, 'fileId': 'second'},
        ];
      expect(ResourcePackInstallation.fromJson(json).assets, hasLength(2));
      for (final change in [
        {'rawSha256': 'e' * 64},
        {'byteLength': 33},
        {'targetPath': 'assets/images/other.png'},
        {'assetId': 'another_native_id'},
      ]) {
        expect(
          () => ResourcePackInstallation.fromJson({
            ...json,
            'assets': [
              asset,
              {...asset, 'fileId': 'second', ...change},
            ],
          }),
          throwsFormatException,
          reason: '$change',
        );
      }
      for (final id in ['../id', 'with space', ':id', '.id', '-id']) {
        expect(
          () => ResourcePackAssetMapping.fromJson({...asset, 'assetId': id}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'origin support owners resolve through their recorded resource mappings',
    () {
      final json = <String, Object?>{
        'installationId': 'installation',
        'packId': 'avelune.original',
        'packVersion': '1.0.0',
        'universeId': 'avelune.original',
        'archiveRawSha256': 'a' * 64,
        'catalogRawSha256': 'b' * 64,
        'copyOrdinal': 0,
        'selectedRoots': [
          {'resourceKind': 'tileset', 'id': 'sheet'},
        ],
        'resources': [
          {
            'source': {'resourceKind': 'tileset', 'id': 'sheet'},
            'targetId': 'rp_sheet',
            'definitionRawSha256': 'c' * 64,
          },
        ],
        'supports': <Object?>[],
        'assets': <Object?>[],
        'installedAtUtc': '2026-10-16T19:00:00.000Z',
        'provenanceStatus': 'declared',
      };
      for (final (sourceOwner, targetOwner) in [
        ('sheet', 'rp_other'),
        ('missing', 'rp_sheet'),
      ]) {
        expect(
          () => ResourcePackInstallation.fromJson({
            ...json,
            'supports': [
              {
                'kind': 'tilesetElementGroup',
                'sourceId': 'group',
                'targetId': 'rp_group',
                'owner': {'resourceKind': 'tileset', 'id': sourceOwner},
                'targetOwnerId': targetOwner,
              },
            ],
          }),
          throwsFormatException,
        );
      }
    },
  );

  test('portable references keep all seven typed identities separate', () {
    final refs = [
      for (final kind in ResourcePackKind.values)
        ResourcePackRef(kind: kind, id: 'shared'),
    ];
    expect(refs.toSet(), hasLength(7));
    for (final ref in refs) {
      expect(ResourcePackRef.fromJson(ref.toJson()), ref);
      expect(ResourcePackRef.fromJson(ref.toJson()).hashCode, ref.hashCode);
      expect(ref.toJson(), {'resourceKind': ref.kind.name, 'id': 'shared'});
    }
    expect(
      () => ResourcePackRef.fromJson({'resourceKind': 'scene', 'id': 'x'}),
      throwsFormatException,
    );
    expect(
      () => ResourcePackRef.fromJson({
        'resourceKind': 'element',
        'id': 'x',
        'name': 'ignored',
      }),
      throwsFormatException,
    );
  });

  test('manifest roundtrip owns immutable sorted data and stable equality', () {
    final json = packManifestJson();
    final manifest = ResourcePackManifest.fromJson(json);
    final decoded = ResourcePackManifest.fromJson(manifest.toJson());
    expect(decoded, manifest);
    expect(decoded.hashCode, manifest.hashCode);
    expect(manifest.pack.id, 'avelune.original-fixture');
    expect(manifest.compatibility.resourceLibraryCatalogVersion, 2);
    expect(manifest.compatibility.smartTileCatalogVersion, 7);
    expect(manifest.compatibility.borderCatalogVersion, 10);
    expect(
      manifest.content.files.map((file) => file.path),
      orderedEquals(['blobs/${'b' * 64}.png', 'licenses/${'c' * 64}.txt']),
    );
    (_object(json['pack'])['authors']! as List).add('Later');
    expect(manifest.pack.authors, ['Avelune']);
    expect(() => manifest.pack.authors.clear(), throwsUnsupportedError);
    expect(() => manifest.content.files.clear(), throwsUnsupportedError);
    expect(
      () => manifest.compatibility.requiredCapabilities.clear(),
      throwsUnsupportedError,
    );
  });

  test('manifest forbids unknown keys at every contract boundary', () {
    for (final boundary in ['', 'pack', 'compatibility', 'content']) {
      final json = packManifestJson();
      if (boundary.isEmpty) {
        json['maps'] = [];
      } else {
        json[boundary] = {..._object(json[boundary]), 'unknown': true};
      }
      expect(
        () => ResourcePackManifest.fromJson(json),
        throwsFormatException,
        reason: boundary,
      );
    }
    final json = packManifestJson();
    final content = _object(json['content']);
    json['content'] = {
      ...content,
      'catalog': {..._object(content['catalog']), 'unknown': true},
    };
    expect(() => ResourcePackManifest.fromJson(json), throwsFormatException);
  });

  test('format identity and exact native codec versions fail closed', () {
    for (final change in [
      {'format': 'avelune.game'},
      {'formatVersion': 2},
      {'formatVersion': '1'},
    ]) {
      expect(
        () => ResourcePackManifest.fromJson({...packManifestJson(), ...change}),
        throwsFormatException,
      );
    }
    for (final change in [
      {'resourceLibraryCatalogVersion': 1},
      {'smartTileCatalogVersion': 6},
      {'borderCatalogVersion': 9},
      {'tileWidth': 0},
      {'tileHeight': -1},
      {'tileWidth': 16.5},
      {
        'requiredCapabilities': ['x', 'x'],
      },
      {
        'requiredCapabilities': ['../escape'],
      },
    ]) {
      final json = packManifestJson();
      json['compatibility'] = {..._object(json['compatibility']), ...change};
      expect(
        () => ResourcePackManifest.fromJson(json),
        throwsFormatException,
        reason: '$change',
      );
    }
  });

  test('published identity validates SemVer without build metadata', () {
    for (final version in ['0.0.0', '1.2.3', '2.0.0-rc.1', '1.0.0-beta-2']) {
      final json = packManifestJson();
      json['pack'] = {..._object(json['pack']), 'version': version};
      expect(ResourcePackManifest.fromJson(json).pack.version, version);
    }
    for (final change in [
      {'id': '../pack'},
      {'id': 'Uppercase'},
      {'id': 'x' * 97},
      {'version': '01.0.0'},
      {'version': '1.0'},
      {'version': '1.0.0+rebuilt'},
      {'version': '1.0.0-01'},
      {'version': '1.0.0-rc..1'},
      {'name': ''},
      {'name': 'x' * 257},
      {'description': 'x' * 4097},
      {'authors': <String>[]},
      {
        'authors': [''],
      },
      {
        'authors': ['x' * 129],
      },
      {
        'authors': ['Avelune', 1],
      },
      {'provenance': ''},
      {'universeId': 'https://remote.invalid'},
    ]) {
      final json = packManifestJson();
      json['pack'] = {..._object(json['pack']), ...change};
      expect(
        () => ResourcePackManifest.fromJson(json),
        throwsFormatException,
        reason: '$change',
      );
    }
  });

  test(
    'inventory binds path hash MIME and byte count without path escapes',
    () {
      final valid = {
        'path': 'blobs/${'a' * 64}.png',
        'byteLength': 1,
        'mediaType': 'image/png',
        'rawSha256': 'a' * 64,
      };
      expect(ResourcePackInventoryFile.fromJson(valid).toJson(), valid);
      for (final change in [
        {'path': '../outside.png'},
        {'path': '/blobs/${'a' * 64}.png'},
        {'path': 'blobs\\${'a' * 64}.png'},
        {'path': 'blobs/${'a' * 64}.exe'},
        {'path': 'blobs/${'b' * 64}.png'},
        {'path': 'previews/${'a' * 64}.glb'},
        {'path': 'licenses/${'a' * 64}.png'},
        {'mediaType': 'model/gltf-binary'},
        {'rawSha256': 'A' * 64},
        {'byteLength': 0},
        {'byteLength': 1.5},
        {'unknown': true},
      ]) {
        expect(
          () => ResourcePackInventoryFile.fromJson({...valid, ...change}),
          throwsFormatException,
          reason: '$change',
        );
      }
    },
  );

  test('content rejects duplicate inventory rows and malformed digests', () {
    final json = packManifestJson();
    final content = _object(json['content']);
    final files = (content['files']! as List).cast<Map<String, Object?>>();
    json['content'] = {
      ...content,
      'files': [files.first, files.first],
    };
    expect(() => ResourcePackManifest.fromJson(json), throwsFormatException);
    for (final hash in ['', 'x' * 64, 'A' * 64, 'a' * 63]) {
      json['content'] = {...content, 'treeSha256': hash};
      expect(() => ResourcePackManifest.fromJson(json), throwsFormatException);
    }
    json['content'] = {
      ...content,
      'catalog': {..._object(content['catalog']), 'path': 'other.json'},
    };
    expect(() => ResourcePackManifest.fromJson(json), throwsFormatException);
  });

  test('file bindings are portable owned IDs rather than old CAS handles', () {
    final json = <String, Object?>{
      'id': 'image',
      'logicalPath': 'images/original.png',
      'archivePath': 'blobs/${'a' * 64}.png',
      'rawSha256': 'a' * 64,
      'byteLength': 32,
      'mediaType': 'image/png',
      'provenanceId': 'original',
      'licenseIds': ['licenses/${'b' * 64}.txt'],
    };
    final binding = ResourcePackFileBinding.fromJson(json);
    expect(ResourcePackFileBinding.fromJson(binding.toJson()), binding);
    for (final change in [
      {'logicalPath': '/Users/karim/image.png'},
      {'logicalPath': '../image.png'},
      {'logicalPath': 'https://remote.invalid/image.png'},
      {'archivePath': 'previews/${'a' * 64}.png'},
      {
        'licenseIds': ['unknown'],
      },
      {
        'licenseIds': ['licenses/${'b' * 64}.txt', 'licenses/${'b' * 64}.txt'],
      },
      {'artifactHandle': 'session-old'},
      {'assetId': 'source-cas'},
    ]) {
      expect(
        () => ResourcePackFileBinding.fromJson({...json, ...change}),
        throwsFormatException,
        reason: '$change',
      );
    }
  });

  test('provenance keeps source URLs descriptive and licenses explicit', () {
    final json = <String, Object?>{
      'id': 'original',
      'author': 'Avelune',
      'sourceUrl': 'https://example.invalid/original',
      'licenseIds': ['licenses/${'b' * 64}.txt'],
    };
    final provenance = ResourcePackProvenance.fromJson(json);
    expect(ResourcePackProvenance.fromJson(provenance.toJson()), provenance);
    expect(provenance.sourceUrl, json['sourceUrl']);
    for (final change in [
      {'sourceUrl': 'file:///Users/karim/secret'},
      {'sourceUrl': 'javascript:alert(1)'},
      {
        'licenseIds': ['../license'],
      },
      {'download': true},
    ]) {
      expect(
        () => ResourcePackProvenance.fromJson({...json, ...change}),
        throwsFormatException,
      );
    }
  });
}

Map<String, Object?> _originJson() => {
  'installationId': 'installation',
  'packId': 'avelune.original',
  'packVersion': '1.0.0',
  'universeId': 'avelune.original',
  'archiveRawSha256': 'a' * 64,
  'catalogRawSha256': 'b' * 64,
  'copyOrdinal': 0,
  'selectedRoots': [
    {'resourceKind': 'tileset', 'id': 'sheet'},
  ],
  'resources': [
    {
      'source': {'resourceKind': 'tileset', 'id': 'sheet'},
      'targetId': 'rp_sheet',
      'definitionRawSha256': 'c' * 64,
    },
  ],
  'supports': <Object?>[],
  'assets': <Object?>[],
  'installedAtUtc': '2026-10-16T19:00:00.000Z',
  'provenanceStatus': 'declared',
};
