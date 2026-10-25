import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final value in <bool?>[true, false, null]) {
    test('projects a character contact shadow override of $value', () {
      final before = _characterManifest(value == false);
      final after = _characterManifest(value);
      final projected = _projectManifest(before, after);
      expect(projected, isNotNull);
      expect(projected!.manifest.characters.single.contactShadow, value);
      expect(
          projected.resourceBytes('project'), utf8.encode(jsonEncode(after)));
    });
  }

  test('rejects character source changes alongside a contact shadow edit', () {
    final before = _characterManifest(false);
    final after = _characterManifest(true);
    (after['characters'] as List).single['tilesetId'] = 'missing';
    expect(_projectManifest(before, after), isNull);
  });

  test('rejects unmodeled character changes alongside a contact shadow edit',
      () {
    final before = _characterManifest(false);
    final after = _characterManifest(true);
    (after['characters'] as List).single['unknownProperty'] = true;
    expect(_projectManifest(before, after), isNull);
  });

  test('projects a committed map post-image without rereading other bytes', () {
    final manifestBytes = utf8.encode(_manifestJson);
    final beforeBytes = utf8.encode(_mapJson('Before'));
    final afterBytes = utf8.encode(_mapJson('After'));
    final snapshot = ProjectSnapshot(
      projectHandle: const ProjectHandle('prj_before'),
      revision: computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/alpha.json',
          bytes: beforeBytes,
        ),
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
      ]),
      manifest: ProjectManifest.fromJson(
        jsonDecode(_manifestJson) as Map<String, dynamic>,
      ),
      maps: [
        MapData.fromJson(jsonDecode(_mapJson('Before'))),
      ],
      resourceFingerprints: {
        'map:alpha': _fingerprint('maps/alpha.json', beforeBytes),
        'project': _fingerprint('project.json', manifestBytes),
      },
      resourceBytes: {
        'map:alpha': beforeBytes,
        'project': manifestBytes,
      },
      resourceStorageKeys: const {
        'map:alpha': 'maps/alpha.json',
        'project': 'project.json',
      },
    );

    final projected = const ProjectSnapshotMapProjector().project(
      snapshot,
      [
        AuthoringResourceChange(
          resource: AuthoringResourceRef(
            kind: 'map',
            id: 'alpha',
            revision: _fingerprint('maps/alpha.json', beforeBytes),
          ),
          storageKey: 'maps/alpha.json',
          beforeBytes: beforeBytes,
          afterBytes: afterBytes,
        ),
      ],
    );

    expect(projected, isNotNull);
    expect(projected!.mapById('alpha')!.name, 'After');
    expect(projected.resourceBytes('map:alpha'), afterBytes);
    expect(projected.resourceBytes('project'), manifestBytes);
    expect(projected.revision, isNot(snapshot.revision));
  });
}

Map<String, dynamic> _characterManifest(bool? value) => {
      ...jsonDecode(_manifestJson) as Map<String, dynamic>,
      'tilesets': [
        const ProjectTilesetEntry(
          id: 'people',
          name: 'People',
          relativePath: 'people.png',
        ).toJson(),
      ],
      'characters': [
        {
          ...const ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'people',
          ).toJson(),
          if (value != null) 'contactShadow': value,
        },
      ],
    };

ProjectSnapshot? _projectManifest(
  Map<String, dynamic> before,
  Map<String, dynamic> after,
) {
  final beforeBytes = utf8.encode(jsonEncode(before));
  final afterBytes = utf8.encode(jsonEncode(after));
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_contact_shadow'),
    revision: _fingerprint('project.json', beforeBytes),
    manifest: ProjectManifest.fromJson(before),
    maps: [MapData.fromJson(jsonDecode(_mapJson('Before')))],
    resourceFingerprints: {
      'project': _fingerprint('project.json', beforeBytes),
    },
    resourceBytes: {'project': beforeBytes},
    resourceStorageKeys: const {'project': 'project.json'},
  );
  return const ProjectSnapshotMapProjector().project(snapshot, [
    AuthoringResourceChange(
      resource: AuthoringResourceRef(kind: 'project', id: 'project'),
      storageKey: 'project.json',
      beforeBytes: beforeBytes,
      afterBytes: afterBytes,
    ),
  ]);
}

String _fingerprint(String path, List<int> bytes) =>
    computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(relativePath: path, bytes: bytes),
    ]);

final _manifestJson = jsonEncode({
  'name': 'Projection',
  'version': 'v8',
  'pokemon': ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  ).toJson(),
  'maps': [
    {'id': 'alpha', 'name': 'Alpha', 'relativePath': 'maps/alpha.json'},
  ],
  'tilesets': <Object?>[],
});

String _mapJson(String name) => '''
{
  "id": "alpha",
  "name": "$name",
  "version": "v8",
  "size": {"width": 1, "height": 1},
  "layers": []
}
''';
