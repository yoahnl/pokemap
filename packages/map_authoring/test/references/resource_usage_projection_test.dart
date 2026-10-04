import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_catalog_fixture.dart';

const planche = ProjectTilesetEntry(
    id: 'shared', name: 'Planche', relativePath: 'images/planche.png');
const noPokemon = ProjectPokemonConfig(
    enabled: false, ruleset: PokemonRulesetProfile.pokeMapBetaV1);
const decor = ProjectElementEntry(
  id: 'shared',
  name: 'Arbre',
  tilesetId: 'shared',
  categoryId: 'plants',
  frames: [
    TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    TilesetVisualFrame(
        tilesetId: 'second', source: TilesetSourceRect(x: 1, y: 0))
  ],
);

ResourceUsageReport usage(ProjectSnapshot snapshot,
        {String family = 'images', String id = 'shared'}) =>
    const ResourceUsageProjection()
        .analyze(snapshot, ResourceUsageTarget(family: family, id: id));

ProjectSnapshot withDocuments(
    ProjectSnapshot original, Map<String, Object?> docs,
    {bool inventory = true}) {
  final bytes = {...original.resourceFingerprints};
  final payloads = {
    for (final id in bytes.keys) id: original.resourceBytes(id),
  };
  for (final entry in docs.entries) {
    final value = utf8.encode(jsonEncode(entry.value));
    bytes[entry.key] = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(relativePath: entry.key, bytes: value),
    ]);
    payloads[entry.key] = value;
  }
  return ProjectSnapshot(
      projectHandle: original.projectHandle,
      revision: original.revision,
      manifest: original.manifest,
      maps: original.maps,
      resourceFingerprints: bytes,
      resourceBytes: payloads,
      pokemonInventoryComplete: inventory);
}

void main() {
  test('closed map and unplaced frame definition have qualified owners', () {
    final map = catalogMap('closed').copyWith(placedElements: [
      const MapPlacedElement(
          id: 'instance',
          layerId: 'base',
          elementId: 'shared',
          pos: GridPos(x: 1, y: 1)),
    ]);
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [
          const ProjectMapEntry(
              id: 'closed', name: 'Closed', relativePath: 'maps/closed.json'),
        ],
        pokemon: noPokemon,
        tilesets: [
          planche,
          planche.copyWith(id: 'second', relativePath: 'images/second.png')
        ],
        elements: [decor]);
    final snapshot = catalogSnapshot([map], project: manifest);
    final report = usage(snapshot);
    expect(report.complete, isTrue, reason: report.coverageIssues.toString());
    expect(report.entries.where((e) => e.ownerKind == 'element'), isNotEmpty);
    expect(report.entries.where((e) => e.ownerKind == 'element'), hasLength(1));
    expect(report.entries.singleWhere((e) => e.ownerKind == 'element').relation,
        ResourceUsageRelation.direct);
    final placed = report.entries.singleWhere((e) => e.ownerKind == 'map');
    expect(placed.relation, ResourceUsageRelation.indirect);
    expect(placed.mapId, 'closed');
    expect(placed.entityId, 'instance');
    final second = usage(snapshot, id: 'second');
    expect(second.entries.any((e) => e.location.contains('frames[1]')), isTrue);
    final element = usage(snapshot, family: 'decors');
    expect(element.entries.single.ownerKind, 'map');
    expect(element.entries.single.relation, ResourceUsageRelation.direct);
    expect(usage(snapshot, family: 'terrains').complete, isFalse);
  });

  test('Pokemon inventory includes media unused in the current game', () {
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: const ProjectPokemonConfig(
            enabled: true, ruleset: PokemonRulesetProfile.pokeMapBetaV1));
    final snapshot = withDocuments(catalogSnapshot([], project: manifest), {
      'pokemonMedia:unknown-in-party': const PokemonMediaFile(
          speciesId: 'unknown-in-party',
          defaultFormId: 'normal',
          variants: {
            'normal':
                PokemonMediaVariant(icon: 'images/planche.png', animations: {
              'idle': PokemonMediaAnimationRef(
                  sheet: 'images/planche.png', animationId: 'idle'),
            }),
          }).toJson(),
    });
    final report = usage(snapshot);
    expect(report.complete, isTrue);
    expect(
        report.entries.where((e) => e.ownerKind == 'pokemonMedia').length, 2);
    final incomplete = usage(withDocuments(snapshot, {}, inventory: false));
    expect(incomplete.coverageIssues, contains('asset.inventory_unavailable'));
    expect(usage(withDocuments(snapshot, {'pokemonMedia:broken': {}})).complete,
        isFalse);
  });

  test('shared bytes do not attribute another logical identity', () {
    final artifact =
        ContentArtifactRef.fromBytes([1, 2, 3], mediaType: 'image/png');
    final first = AssetRecord(
        id: 'first', logicalPath: planche.relativePath, artifact: artifact);
    final second = AssetRecord(
        id: 'second', logicalPath: 'images/second.png', artifact: artifact);
    final character = ProjectCharacterEntry(
        id: 'person',
        name: 'Personne',
        tilesetId: 'other',
        portraits: const [
          CharacterPortraitVariant(
              portraitStateId: 'normal', assetId: 'second'),
        ]);
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        pokemon: noPokemon,
        tilesets: [planche],
        characters: [character],
        globalProperties: {
          'retained': artifact.handle,
        });
    final snapshot = withDocuments(catalogSnapshot([], project: manifest), {
      assetCatalogResourceIdentity:
          AssetCatalog(records: [first, second]).toJson(),
    });
    final report = usage(snapshot);
    expect(report.entries.any((e) => e.ownerKind == 'character'), isFalse);
    expect(report.entries.singleWhere((e) => e.ownerKind == 'project').relation,
        ResourceUsageRelation.ambiguous);
  });

  test('canonical read query exposes detail and honest coverage', () {
    final snapshot = catalogSnapshot([],
        project: const ProjectManifest(
            name: 'Fixture',
            maps: [],
            tilesets: [planche],
            pokemon: noPokemon));
    final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'resourceUsage',
          operation: AuthoringQueryOperation.get,
          ids: ['images:shared'],
          view: AuthoringQueryView.detail,
        ));
    expect(page.items.single['revision'], snapshot.revision);
    expect(page.items.single['complete'], isTrue);
    expect(page.items.single['entries'], isNotEmpty);
  });
}
