import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Character Studio resources', () {
    test('registers the four canonical read resources', () {
      expect(
        canonicalQueryableResourceKindIds,
        containsAll(<String>{
          'characterStudioCatalog',
          'characterStudioCharacter',
          'characterStudioDependency',
          'characterStudioReadiness',
        }),
      );
    });

    test('catalog exposes custom and immutable system definitions', () {
      final page = _query(
        'characterStudioCatalog',
        operation: AuthoringQueryOperation.get,
        ids: const <String>['catalog'],
      );
      final item = page.items.single;
      final animations = item['animationDefinitions']! as List<Object?>;

      expect(page.snapshotRevision, _revision);
      expect(item['portraitStates'], <Object?>[
        <String, Object?>{
          'id': 'neutral',
          'displayName': 'Neutre',
          'sortOrder': 0,
        },
      ]);
      expect(
        animations.map((value) => (value! as Map)['id']),
        <String>['base', 'run', 'victory', 'walk'],
      );
      expect(
        animations.where((value) => (value! as Map)['system'] == true),
        hasLength(3),
      );
      expect(() => animations.add(const <String, Object?>{}),
          throwsUnsupportedError);
    });

    test('characters support selection filters and deterministic sorting', () {
      final request = AuthoringQueryRequest(
        resourceKind: 'characterStudioCharacter',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.detail,
        filters: const <String, Object?>{'isSelected': true},
        sort: const <AuthoringQuerySort>[
          AuthoringQuerySort(field: 'sortOrder'),
        ],
        extensions: const <String, Object?>{'selectedCharacterId': 'elia'},
      );
      final first = const ProjectQueryService().query(_snapshot(), request);
      final second = const ProjectQueryService().query(_snapshot(), request);

      expect(first.items, second.items);
      expect(first.items.single['id'], 'elia');
      expect(first.items.single['isDefaultPlayer'], isTrue);
      expect(first.items.single['dependencyCount'], 2);
      expect(first.items.single['portraitCoverage'], 1.0);
      expect(first.items.single['workspaceRevision'], _revision);
    });

    test('readiness exposes selected character coverage and diagnostics', () {
      final page = _query(
        'characterStudioReadiness',
        operation: AuthoringQueryOperation.get,
        ids: const <String>['nox'],
        selectedCharacterId: 'nox',
      );
      final item = page.items.single;
      final diagnostics = item['diagnostics']! as List<Object?>;
      final coverage = item['coverage']! as Map<String, Object?>;

      expect(item['isSelected'], isTrue);
      expect(item['isReady'], isFalse);
      expect(item['errorCount'], 4);
      expect(
        diagnostics.map((value) => (value! as Map)['code']).toSet(),
        contains('baseDirectionMissing'),
      );
      expect(coverage['baseDefined'], 0);
      expect(coverage['baseRequired'], 4);
      expect(coverage['portraitDefined'], 0);
      expect(coverage['portraitRequired'], 1);
    });

    test('dependencies are stable and do not mutate the manifest', () {
      final snapshot = _snapshot();
      final before = jsonEncode(snapshot.manifest.toJson());
      final first = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'characterStudioDependency',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          filters: const <String, Object?>{'targetId': 'elia'},
        ),
      );
      final second = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'characterStudioDependency',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          filters: const <String, Object?>{'targetId': 'elia'},
        ),
      );

      expect(first.items, second.items);
      expect(first.totalAvailable, 2);
      expect(
        first.items.map((item) => item['sourceKind']),
        <String>['newGameAvatar', 'defaultPlayer'],
      );
      expect(jsonEncode(snapshot.manifest.toJson()), before);
      expect(
        () => first.items.first['targetId'] = 'changed',
        throwsUnsupportedError,
      );
    });
  });
}

AuthoringQueryPage _query(
  String resourceKind, {
  required AuthoringQueryOperation operation,
  List<String> ids = const <String>[],
  String? selectedCharacterId,
}) {
  return const ProjectQueryService().query(
    _snapshot(),
    AuthoringQueryRequest(
      resourceKind: resourceKind,
      operation: operation,
      view: AuthoringQueryView.detail,
      ids: ids,
      extensions: <String, Object?>{
        if (selectedCharacterId != null)
          'selectedCharacterId': selectedCharacterId,
      },
    ),
  );
}

const _revision =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

ProjectSnapshot _snapshot() {
  const frame = CharacterAnimationFrame(
    source: TilesetSourceRect(x: 0, y: 0, width: 16, height: 32),
  );
  final manifest = ProjectManifest(
    name: 'Character Studio fixture',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    settings: const ProjectSettings(defaultPlayerCharacterId: 'elia'),
    newGame: const ProjectNewGameConfig(
      playerAvatarCharacterIds: <String>['elia'],
    ),
    characterStudioCatalog: const ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(
          id: 'neutral',
          displayName: 'Neutre',
        ),
      ],
      customAnimationDefinitions: <CharacterCustomAnimationDefinition>[
        CharacterCustomAnimationDefinition(
          id: 'victory',
          displayName: 'Victoire',
          mode: CharacterCustomAnimationMode.single,
        ),
      ],
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'nox',
        name: 'Nox',
        tilesetId: 'nox-sheet',
        sortOrder: 0,
      ),
      ProjectCharacterEntry(
        id: 'elia',
        name: 'Élia',
        tilesetId: 'elia-sheet',
        sortOrder: 1,
        portraits: <CharacterPortraitVariant>[
          CharacterPortraitVariant(
            portraitStateId: 'neutral',
            assetId: 'portrait-elia-neutral',
          ),
        ],
        animations: <CharacterAnimation>[
          for (final direction in EntityFacing.values)
            CharacterAnimation(
              state: CharacterAnimationState.idle,
              direction: direction,
              frames: const <CharacterAnimationFrame>[frame],
            ),
        ],
      ),
    ],
  );
  final bytes = utf8.encode(jsonEncode(manifest.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('character_studio_query'),
    revision: _revision,
    manifest: manifest,
    maps: const <MapData>[],
    resourceFingerprints: <String, String>{'project': _revision},
    resourceBytes: <String, List<int>>{'project': bytes},
  );
}
