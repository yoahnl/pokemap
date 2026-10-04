import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_catalog_fixture.dart';
import 'resource_usage_projection_test.dart'
    show planche, noPokemon, withDocuments;

void main() {
  test('unplaced terrain atlas rules and drafts retain exact source identity',
      () {
    const preset = ProjectSmartTilePreset(
      id: 'grass',
      name: 'Herbe',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      coveragePolicy: SmartTileCoveragePolicy.complete,
      coverageProfile:
          SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: ['grass'],
      rules: [
        SmartTileRule(
          id: 'base',
          centerMatch: SmartTileSlotMatch.material('grass'),
          candidates: [
            SmartTileCandidate(id: 'base', parts: [
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                    frame:
                        SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0)),
              )
            ])
          ],
        )
      ],
    );
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: noPokemon,
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: const [
            ProjectSmartTileAtlas(
                id: 'atlas',
                name: 'Atlas',
                tilesetId: 'shared',
                columns: 1,
                rows: 1)
          ],
          presets: const [preset],
          drafts: const [
            ProjectSmartTileAuthoringDraft(
                id: 'draft',
                targetPresetId: 'grass',
                name: 'Herbe brouillon',
                usage: SmartTileUsage.terrain,
                lastStage: SmartTileAuthoringStage.image,
                sourceTilesetIds: ['shared'])
          ],
        ));
    final report = const ResourceUsageProjection().analyze(
        catalogSnapshot([], project: manifest),
        const ResourceUsageTarget(family: 'images', id: 'shared'));
    expect(report.complete, isTrue);
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'smartTileAtlas' &&
            entry.relation == ResourceUsageRelation.direct),
        isTrue);
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'preset' &&
            entry.ownerLabel == 'Herbe' &&
            entry.relation == ResourceUsageRelation.indirect),
        isTrue);
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'smartTileDraft' &&
            entry.relation == ResourceUsageRelation.technical),
        isTrue);
  });

  test('portrait and character animation retain their logical assets', () {
    final artifact =
        ContentArtifactRef.fromBytes([1, 2], mediaType: 'image/png');
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: noPokemon,
        characters: const [
          ProjectCharacterEntry(
            id: 'person',
            name: 'Personnage',
            tilesetId: 'unused',
            portraits: [
              CharacterPortraitVariant(
                  portraitStateId: 'normal', assetId: 'portrait')
            ],
            animations: [
              CharacterAnimation(
                  state: CharacterAnimationState.walk,
                  direction: EntityFacing.south,
                  sourceAssetId: 'portrait')
            ],
          )
        ]);
    final base = catalogSnapshot([], project: manifest);
    final catalog = AssetCatalog(records: [
      AssetRecord(
          id: 'portrait', logicalPath: planche.relativePath, artifact: artifact)
    ]);
    final snapshot =
        withDocuments(base, {assetCatalogResourceIdentity: catalog.toJson()});
    final report = const ResourceUsageProjection().analyze(
        snapshot, const ResourceUsageTarget(family: 'images', id: 'shared'));
    final usages =
        report.entries.where((entry) => entry.ownerKind == 'character');
    expect(usages, hasLength(2));
    expect(
        usages.every((entry) =>
            entry.ownerId == 'person' &&
            entry.relation == ResourceUsageRelation.direct),
        isTrue);
    expect(
        usages.any((entry) => entry.location.contains('portraits[0].assetId')),
        isTrue);
    expect(
        usages.any(
            (entry) => entry.location.contains('animations[0].sourceAssetId')),
        isTrue);
  });
}
