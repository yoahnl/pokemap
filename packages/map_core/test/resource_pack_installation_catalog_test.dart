import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> packInstallationJson() => {
  'installationId': 'installation-original',
  'packId': 'avelune.original',
  'packVersion': '1.0.0',
  'universeId': 'avelune.test',
  'archiveRawSha256': 'a' * 64,
  'catalogRawSha256': 'b' * 64,
  'copyOrdinal': 0,
  'selectedRoots': [
    {'resourceKind': 'element', 'id': 'chair'},
  ],
  'resources': [
    {
      'source': {'resourceKind': 'element', 'id': 'chair'},
      'targetId': 'rp_chair',
      'definitionRawSha256': 'c' * 64,
    },
  ],
  'supports': [
    {
      'kind': 'elementCategory',
      'sourceId': 'furniture',
      'targetId': 'rp_furniture',
    },
  ],
  'assets': [
    {
      'fileId': 'image',
      'assetId': 'asset_native',
      'targetPath': 'assets/images/rp_sheet.png',
      'rawSha256': 'd' * 64,
      'byteLength': 32,
      'mediaType': 'image/png',
      'provenanceId': 'original',
      'licenseIds': ['licenses/${'e' * 64}.txt'],
    },
  ],
  'origins': [
    {
      'id': 'original',
      'author': 'Original',
      'licenseIds': ['licenses/${'e' * 64}.txt'],
      'resources': [
        {'resourceKind': 'element', 'id': 'chair'},
      ],
    },
  ],
  'licenses': [
    {
      'sourcePath': 'licenses/${'e' * 64}.txt',
      'targetPath': 'assets/resource_packs/original/licenses/${'e' * 64}.txt',
      'rawSha256': 'e' * 64,
      'byteLength': 12,
    },
  ],
  'installedAtUtc': '2026-10-16T19:00:00.000Z',
  'provenanceStatus': 'declared',
};

void main() {
  test(
    'installation format v2 persists origin and document associations and refuses v1',
    () {
      expect(ResourcePackInstallationCatalog.currentFormatVersion, 2);
      final value = packInstallationJson();
      value['origins'] = [
        {
          'id': 'original',
          'author': 'Alice',
          'sourceUrl': 'https://example.test/alice',
          'licenseIds': ['licenses/${'e' * 64}.txt'],
          'resources': [
            {'resourceKind': 'element', 'id': 'chair'},
          ],
        },
      ];
      value['licenses'] = [
        {
          'sourcePath': 'licenses/${'e' * 64}.txt',
          'targetPath':
              'assets/resource_packs/original/licenses/${'e' * 64}.txt',
          'rawSha256': 'e' * 64,
          'byteLength': 12,
        },
      ];
      (value['assets'] as List).single.addAll({
        'provenanceId': 'original',
        'licenseIds': ['licenses/${'e' * 64}.txt'],
      });
      final catalog = ResourcePackInstallationCatalog.fromJson({
        'formatVersion': 2,
        'entries': [value],
      });
      expect(
        ResourcePackInstallationCatalog.fromJson(catalog.toJson()),
        catalog,
      );
      expect(
        (catalog.toJson()['entries'] as List).single['origins'],
        value['origins'],
      );
      expect(
        () => ResourcePackInstallationCatalog.fromJson({
          'formatVersion': 1,
          'entries': [],
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'v2 rejects unresolved origins resources licences and non-document descriptors',
    () {
      final valid = packInstallationJson();
      final changes = <Map<String, Object?>>[
        {'origins': []},
        {'licenses': []},
        {
          'origins': [
            {
              'id': 'original',
              'author': 'Alice',
              'licenseIds': [],
              'resources': [
                {'resourceKind': 'model3d', 'id': 'chair'},
              ],
            },
          ],
        },
        {
          'assets': [
            {
              ...Map<String, Object?>.from(
                (valid['assets'] as List).single as Map,
              ),
              'provenanceId': 'missing',
            },
          ],
        },
        {
          'assets': [
            {
              ...Map<String, Object?>.from(
                (valid['assets'] as List).single as Map,
              ),
              'licenseIds': ['licenses/${'f' * 64}.txt'],
            },
          ],
        },
        {
          'licenses': [
            {
              ...Map<String, Object?>.from(
                (valid['licenses'] as List).single as Map,
              ),
              'rawSha256': 'f' * 64,
            },
          ],
        },
        {
          'licenses': [
            {
              ...Map<String, Object?>.from(
                (valid['licenses'] as List).single as Map,
              ),
              'targetPath': 'assets/elsewhere.txt',
            },
          ],
        },
      ];
      for (final change in changes) {
        expect(
          () => ResourcePackInstallation.fromJson({...valid, ...change}),
          throwsFormatException,
          reason: '$change',
        );
      }
    },
  );
  test(
    'installation catalogue roundtrips typed immutable historical mappings',
    () {
      final json = packInstallationJson();
      final installation = ResourcePackInstallation.fromJson(json);
      final catalog = ResourcePackInstallationCatalog(entries: [installation]);
      expect(
        ResourcePackInstallationCatalog.fromJson(catalog.toJson()),
        catalog,
      );
      expect(
        ResourcePackInstallationCatalog.fromJson(catalog.toJson()).hashCode,
        catalog.hashCode,
      );
      expect(
        installation.resources.single.source.kind,
        ResourcePackKind.element,
      );
      expect(
        installation.supports.single.kind,
        ResourcePackSupportKind.elementCategory,
      );
      expect(
        installation.assets.single.targetPath,
        'assets/images/rp_sheet.png',
      );
      (json['resources']! as List).clear();
      expect(installation.resources, hasLength(1));
      expect(() => installation.resources.clear(), throwsUnsupportedError);
      expect(() => installation.selectedRoots.clear(), throwsUnsupportedError);
      expect(() => catalog.entries.clear(), throwsUnsupportedError);
    },
  );

  test('empty origin catalogue is absent from native project JSON', () {
    const project = ProjectManifest(name: 'Original', maps: [], tilesets: []);
    expect(project.resourcePackInstallations.isEmpty, isTrue);
    expect(project.toJson().containsKey('resourcePackInstallations'), isFalse);
    expect(ProjectManifest.fromJson(project.toJson()), project);
  });

  test('deleted imported targets remain valid historical provenance', () {
    final installation = ResourcePackInstallation.fromJson(
      packInstallationJson(),
    );
    final catalog = ResourcePackInstallationCatalog(entries: [installation]);
    final project = ProjectManifest(
      name: 'Local deletion',
      maps: const [],
      tilesets: const [],
      resourcePackInstallations: catalog,
    );
    final reopened = ProjectManifest.fromJson(project.toJson());
    expect(reopened.elements, isEmpty);
    expect(reopened.tilesets, isEmpty);
    expect(reopened.resourcePackInstallations, catalog);
    expect(
      reopened
          .resourcePackInstallations
          .entries
          .single
          .resources
          .single
          .targetId,
      'rp_chair',
    );
  });

  test('dedup identity excludes informational date and selected roots', () {
    final first = ResourcePackInstallation.fromJson(packInstallationJson());
    final second = ResourcePackInstallation.fromJson({
      ...packInstallationJson(),
      'origins': [
        {
          'id': 'original',
          'author': 'Original',
          'licenseIds': ['licenses/${'e' * 64}.txt'],
          'resources': [
            {'resourceKind': 'element', 'id': 'chair'},
          ],
        },
      ],
      'licenses': [
        {
          'sourcePath': 'licenses/${'e' * 64}.txt',
          'targetPath':
              'assets/resource_packs/original/licenses/${'e' * 64}.txt',
          'rawSha256': 'e' * 64,
          'byteLength': 12,
        },
      ],
      'installedAtUtc': '2026-10-17T20:00:00.000Z',
    });
    expect(first.packIdentity, second.packIdentity);
    expect(first, isNot(second));
    expect(first.installationIdentity, second.installationIdentity);
    expect(
      ResourcePackInstallationCatalog(
        entries: [first],
      ).installationFor('avelune.original', '1.0.0'),
      first,
    );
  });

  test('copy ordinal and new version permit isolated installations', () {
    final original = ResourcePackInstallation.fromJson(packInstallationJson());
    final copy = ResourcePackInstallation.fromJson({
      ...packInstallationJson(),
      'installationId': 'installation-copy',
      'copyOrdinal': 1,
    });
    final version = ResourcePackInstallation.fromJson({
      ...packInstallationJson(),
      'installationId': 'installation-v2',
      'packVersion': '2.0.0',
      'archiveRawSha256': 'e' * 64,
    });
    final catalog = ResourcePackInstallationCatalog(
      entries: [version, original, copy],
    );
    expect(catalog.entries, hasLength(3));
    expect(
      catalog.installationFor('avelune.original', '1.0.0', copyOrdinal: 1),
      copy,
    );
    expect(catalog.installationFor('avelune.original', '2.0.0'), version);
    expect(original.installationIdentity, isNot(copy.installationIdentity));
  });

  test(
    'catalogue rejects changed immutable publication and duplicate origin',
    () {
      final original = ResourcePackInstallation.fromJson(
        packInstallationJson(),
      );
      for (final change in [
        {'installationId': 'other', 'archiveRawSha256': 'e' * 64},
        {'installationId': 'other', 'catalogRawSha256': 'e' * 64},
        {'installationId': 'other'},
        {'copyOrdinal': 1},
      ]) {
        final other = ResourcePackInstallation.fromJson({
          ...packInstallationJson(),
          ...change,
        });
        expect(
          () => ResourcePackInstallationCatalog(entries: [original, other]),
          throwsFormatException,
          reason: '$change',
        );
      }
    },
  );

  test(
    'typed target IDs do not merge different kinds with a shared raw id',
    () {
      final json = packInstallationJson();
      final original = (json['resources']! as List).single as Map;
      json['resources'] = [
        original,
        {
          ...original,
          'source': {'resourceKind': 'tileset', 'id': 'chair'},
        },
      ];
      expect(ResourcePackInstallation.fromJson(json).resources, hasLength(2));
      json['resources'] = [original, original];
      expect(
        () => ResourcePackInstallation.fromJson(json),
        throwsFormatException,
      );
    },
  );

  test(
    'installed roots must be covered but no project foreign key is imposed',
    () {
      final json = packInstallationJson();
      json['selectedRoots'] = [
        {'resourceKind': 'element', 'id': 'missing'},
      ];
      expect(
        () => ResourcePackInstallation.fromJson(json),
        throwsFormatException,
      );
    },
  );

  test('owner scoped tileset groups preserve both owner identities', () {
    final json = <String, Object?>{
      'kind': 'tilesetElementGroup',
      'sourceId': 'trees',
      'targetId': 'rp_trees',
      'owner': {'resourceKind': 'tileset', 'id': 'sheet'},
      'targetOwnerId': 'rp_sheet',
    };
    final mapping = ResourcePackSupportMapping.fromJson(json);
    expect(ResourcePackSupportMapping.fromJson(mapping.toJson()), mapping);
    for (final change in [
      {'owner': null},
      {'targetOwnerId': null},
      {
        'owner': {'resourceKind': 'element', 'id': 'sheet'},
      },
      {'kind': 'unknown'},
    ]) {
      expect(
        () => ResourcePackSupportMapping.fromJson({...json, ...change}),
        throwsFormatException,
      );
    }
  });

  test(
    'strict origin contracts reject bad dates hashes keys and selections',
    () {
      for (final change in [
        {'unknown': true},
        {'packVersion': '1.0.0+mutable'},
        {'archiveRawSha256': 'x' * 64},
        {'catalogRawSha256': 'A' * 64},
        {'copyOrdinal': -1},
        {'copyOrdinal': '0'},
        {'installedAtUtc': '2026-10-16'},
        {'installedAtUtc': '2026-02-31T19:00:00.000Z'},
        {'installedAtUtc': '2026-10-16T21:00:00.000+02:00'},
        {'provenanceStatus': 'guaranteed'},
        {'selectedRoots': <Object?>[]},
        {'resources': <Object?>[]},
      ]) {
        expect(
          () => ResourcePackInstallation.fromJson({
            ...packInstallationJson(),
            ...change,
          }),
          throwsFormatException,
          reason: '$change',
        );
      }
      for (final json in [
        {'formatVersion': 3, 'entries': []},
        {'formatVersion': 1, 'entries': [], 'ignored': true},
        {'formatVersion': 1, 'entries': null},
      ]) {
        expect(
          () => ResourcePackInstallationCatalog.fromJson(json),
          throwsFormatException,
        );
      }
    },
  );
}
