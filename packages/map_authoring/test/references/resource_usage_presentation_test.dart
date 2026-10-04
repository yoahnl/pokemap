import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/map_catalog_fixture.dart';
import 'resource_usage_projection_test.dart'
    show planche, noPokemon, withDocuments;

void main() {
  test('presentation owners use canonical media and scene reference edges', () {
    final artifact =
        ContentArtifactRef.fromBytes([1, 2], mediaType: 'image/png');
    final cinematic = PresentationCinematicAsset(
      id: 'opening',
      title: 'Ouverture',
      durationUs: 1000000,
      layers: [PresentationLayer(id: 'main', label: 'Principal', zIndex: 0)],
      tracks: [
        PresentationTrack(
            id: 'visual',
            label: 'Image',
            kind: PresentationTrackKind.visual,
            clips: [
              PresentationVisualClip(
                  id: 'cover',
                  startUs: 0,
                  durationUs: 100000,
                  layerId: 'main',
                  resourceId: 'media.planche')
            ])
      ],
    );
    final scene = SceneAsset(
        id: 'intro',
        name: 'Introduction',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'show',
              kind: SceneNodeKind.presentationCinematic,
              payload: ScenePresentationCinematicPayload(
                  presentationCinematicId: 'opening')),
        ], edges: const []));
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: noPokemon,
        scenes: [scene],
        presentationCinematics: [cinematic],
        presentationPresets: const [
          ProjectPresentationPresetRecord(
              id: 'night',
              label: 'Nuit étoilée',
              description: 'Présentation',
              profile: ProjectPresentationProfile(),
              assets: [
                ProjectPresentationPresetAssetReference(
                    projectPath: 'images/planche.png',
                    mediaType: 'image/png',
                    sizeBytes: 2,
                    sha256:
                        '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
                    licenseProjectPath: 'licenses/image.txt')
              ]),
        ]);
    final snapshot = withDocuments(catalogSnapshot([], project: manifest), {
      assetCatalogResourceIdentity: AssetCatalog(records: [
        AssetRecord(
            id: 'physical',
            logicalPath: planche.relativePath,
            artifact: artifact)
      ]).toJson(),
      projectMediaCatalogResourceIdentity: ProjectMediaCatalog(entries: [
        ProjectMediaAsset(
            id: 'media.planche',
            label: 'Planche cinéma',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'physical')
      ]).toJson(),
    });
    final report = const ResourceUsageProjection().analyze(
        snapshot, const ResourceUsageTarget(family: 'images', id: 'shared'));
    expect(report.complete, isTrue, reason: report.coverageIssues.toString());
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'media' &&
            entry.ownerLabel == 'Planche cinéma' &&
            entry.relation == ResourceUsageRelation.direct),
        isTrue);
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'presentationCinematic' &&
            entry.ownerLabel == 'Ouverture' &&
            entry.relation == ResourceUsageRelation.indirect),
        isTrue);
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'scene' &&
            entry.ownerId == 'intro' &&
            entry.relation == ResourceUsageRelation.indirect),
        isTrue);
    expect(
        report.entries.any((entry) =>
            entry.ownerKind == 'presentationPreset' &&
            entry.ownerLabel == 'Nuit étoilée' &&
            entry.location.endsWith('projectPath')),
        isTrue);
  });

  test('matching a label is not a logical asset reference', () {
    final artifact = ContentArtifactRef.fromBytes([1], mediaType: 'image/png');
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: noPokemon,
        characters: const [
          ProjectCharacterEntry(
              id: 'person', name: 'physical', tilesetId: 'unused')
        ]);
    final snapshot = withDocuments(catalogSnapshot([], project: manifest), {
      assetCatalogResourceIdentity: AssetCatalog(records: [
        AssetRecord(
            id: 'physical',
            logicalPath: planche.relativePath,
            artifact: artifact)
      ]).toJson(),
    });
    final report = const ResourceUsageProjection().analyze(
        snapshot, const ResourceUsageTarget(family: 'images', id: 'shared'));
    expect(
        report.entries
            .singleWhere((entry) => entry.ownerKind == 'character')
            .relation,
        ResourceUsageRelation.ambiguous);
  });
  test('unavailable logical asset inventory never becomes zero usage', () {
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: noPokemon,
        characters: const [
          ProjectCharacterEntry(
              id: 'person',
              name: 'Portrait',
              tilesetId: 'unused',
              portraits: [
                CharacterPortraitVariant(
                    portraitStateId: 'normal', assetId: 'unknown')
              ])
        ]);
    final report = const ResourceUsageProjection().analyze(
        catalogSnapshot([], project: manifest),
        const ResourceUsageTarget(family: 'images', id: 'shared'));
    expect(report.complete, isFalse);
    expect(report.coverageIssues,
        contains('resource.usages.asset_catalog_unavailable'));
  });

  test('presentation background and video poster retain the exact image path',
      () {
    final manifest = ProjectManifest(
        name: 'Fixture',
        maps: [],
        tilesets: [planche],
        pokemon: noPokemon,
        presentation: const ProjectPresentationProfile(
            pause: ProjectPausePresentationProfile(
                background: ProjectPauseBackgroundProfile(
                    imagePath: 'images/planche.png')),
            intro: ProjectIntroVideoProfile(
                media: ProjectResponsiveVideoProfile(
                    landscape: ProjectVideoVariantProfile(
                        videoPath: 'media/intro.mp4',
                        posterPath: 'images/planche.png',
                        durationMilliseconds: 1000,
                        width: 32,
                        height: 32,
                        bitrateKbps: 1,
                        sizeBytes: 2,
                        videoCodec: 'h264')))));
    final report = const ResourceUsageProjection().analyze(
        catalogSnapshot([], project: manifest),
        const ResourceUsageTarget(family: 'images', id: 'shared'));
    final project =
        report.entries.where((entry) => entry.ownerKind == 'project').toList();
    expect(project, hasLength(2));
    expect(
        project
            .every((entry) => entry.relation == ResourceUsageRelation.direct),
        isTrue);
    expect(
        project.any((entry) => entry.location.endsWith('imagePath')), isTrue);
    expect(
        project.any((entry) => entry.location.endsWith('posterPath')), isTrue);
  });
}
