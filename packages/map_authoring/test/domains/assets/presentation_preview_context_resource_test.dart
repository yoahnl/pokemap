import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentationPreviewContext resource', () {
    test('projects every real project-backed preview context', () {
      final snapshot = _snapshot();
      final before = jsonEncode(snapshot.manifest.toJson());
      final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );

      expect(page.snapshotRevision, _revision);
      expect(page.totalAvailable, 5);
      expect(
        page.items.map((item) => item['id']),
        <String>[
          'characterPortrait:leo:happy',
          'dialogue:welcome',
          'encounter:grass',
          'map:village',
          'map:woods',
        ],
      );
      expect(
        page.items.map((item) => item['contextKind']).toSet(),
        <String>{'map', 'dialogue', 'characterPortrait', 'encounter'},
      );
      expect(jsonEncode(snapshot.manifest.toJson()), before);
    });

    test('exposes usable references and explicit degraded diagnostics', () {
      final map = _get('map:village');
      final missingMap = _get('map:woods');
      final dialogue = _get('dialogue:welcome');
      final portrait = _get('characterPortrait:leo:happy');
      final encounter = _get('encounter:grass');

      expect(map['availability'], 'ready');
      expect((map['map']! as Map)['id'], 'village');
      expect(missingMap['availability'], 'degraded');
      expect(
        missingMap['diagnosticCodes'],
        <Object?>['previewContext.mapSourceUnavailable'],
      );
      expect(dialogue['sourceAvailable'], isTrue);
      expect(dialogue['relativePath'], 'dialogues/welcome.yarn');
      expect(portrait['portraitAssetId'], 'portrait-leo-happy');
      expect(portrait['portraitPath'], 'characters/leo/happy.png');
      expect(portrait['portraitStateLabel'], 'Joyeux');
      expect(encounter['entries'], <Object?>[
        <String, Object?>{
          'speciesId': 'roucool',
          'minLevel': 4,
          'maxLevel': 6,
          'weight': 1,
        },
      ]);
      expect((encounter['playerPokemon']! as Map)['speciesId'], 'brindibou');
    });

    test('keeps deterministic pagination bound to the snapshot revision', () {
      final first = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.summary,
          pageSize: 2,
        ),
      );
      final second = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.summary,
          pageSize: 2,
          cursor: first.nextCursor,
        ),
      );

      expect(first.items, hasLength(2));
      expect(first.nextCursor, isNotNull);
      expect(second.items, hasLength(2));
      expect(second.snapshotRevision, _revision);
      expect(second.items.first['id'], 'encounter:grass');
    });

    test('marks combat context degraded without a playable party', () {
      final context = const PresentationPreviewContextProjector()
          .project(
            manifest: const ProjectManifest(
              name: 'No party',
              maps: <ProjectMapEntry>[],
              tilesets: <ProjectTilesetEntry>[],
              encounterTables: <ProjectEncounterTable>[
                ProjectEncounterTable(
                  id: 'grass',
                  name: 'Herbes',
                  encounterKind: EncounterKind.walk,
                  entries: <ProjectEncounterEntry>[
                    ProjectEncounterEntry(
                      speciesId: 'roucool',
                      minLevel: 4,
                      maxLevel: 4,
                    ),
                  ],
                ),
              ],
            ),
            workspaceRevision: _revision,
            maps: const <MapData>[],
            dialogueSourceAvailable: (_) => false,
            portraitAssetPath: (_) => null,
          )
          .single
          .detail;

      expect(context['availability'], 'degraded');
      expect(
        context['diagnosticCodes'],
        <Object?>['previewContext.playerPokemonUnavailable'],
      );
      expect(context, isNot(contains('playerPokemon')));
    });
  });
}

Map<String, Object?> _get(String id) {
  return const ProjectQueryService()
      .query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'presentationPreviewContext',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: <String>[id],
        ),
      )
      .items
      .single;
}

const _revision =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

ProjectSnapshot _snapshot() {
  const manifest = ProjectManifest(
    name: 'Preview contexts',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'woods',
        name: 'Bois Vermeil',
        relativePath: 'maps/woods.json',
      ),
      ProjectMapEntry(
        id: 'village',
        name: 'Village Vermeil',
        relativePath: 'maps/village.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    dialogues: <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'welcome',
        name: 'Bienvenue',
        relativePath: 'dialogues/welcome.yarn',
      ),
    ],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'grass',
        name: 'Herbes du village',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'roucool',
            minLevel: 4,
            maxLevel: 6,
          ),
        ],
      ),
    ],
    characterStudioCatalog: ProjectCharacterStudioCatalog(
      portraitStates: <CharacterPortraitStateDefinition>[
        CharacterPortraitStateDefinition(
          id: 'happy',
          displayName: 'Joyeux',
        ),
      ],
    ),
    characters: <ProjectCharacterEntry>[
      ProjectCharacterEntry(
        id: 'leo',
        name: 'Léo',
        tilesetId: 'leo-sheet',
        portraits: <CharacterPortraitVariant>[
          CharacterPortraitVariant(
            portraitStateId: 'happy',
            assetId: 'portrait-leo-happy',
          ),
        ],
      ),
    ],
    newGame: ProjectNewGameConfig(
      initialParty: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'brindibou',
          natureId: 'hardy',
          abilityId: 'engrais',
          level: 8,
          currentHp: 24,
          knownMoveIds: <String>['charge'],
        ),
      ],
    ),
  );
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final assetCatalog = AssetCatalog(
    records: <AssetRecord>[
      AssetRecord(
        id: 'portrait-leo-happy',
        logicalPath: 'characters/leo/happy.png',
        artifact: ContentArtifactRef.fromBytes(
          const <int>[1, 2, 3],
          mediaType: 'image/png',
        ),
      ),
    ],
  );
  final assetCatalogBytes = utf8.encode(jsonEncode(assetCatalog.toJson()));
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('presentation_preview_contexts'),
    revision: _revision,
    manifest: manifest,
    maps: const <MapData>[
      MapData(
        id: 'village',
        name: 'Village Vermeil',
        size: GridSize(width: 20, height: 15),
      ),
    ],
    resourceFingerprints: const <String, String>{
      'project': _revision,
      'dialogueSource:welcome': _revision,
      'assetCatalog': _revision,
    },
    resourceBytes: <String, List<int>>{
      'project': projectBytes,
      'dialogueSource:welcome': utf8.encode(
        'title: Start\n---\nBienvenue !\n===',
      ),
      'assetCatalog': assetCatalogBytes,
    },
  );
}
