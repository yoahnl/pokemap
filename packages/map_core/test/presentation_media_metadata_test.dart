import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectMediaAsset authored metadata', () {
    test('roundtrips provenance, license and localized captions', () {
      final catalog = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          _caption('opening-captions-en', 'English captions'),
          _caption('opening-captions-fr', 'Sous-titres français'),
          ProjectMediaAsset(
            id: 'opening-video',
            label: 'Opening video',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset.opening-video',
            captions: <ProjectMediaCaption>[
              ProjectMediaCaption(
                locale: 'en-US',
                mediaId: 'opening-captions-en',
              ),
              ProjectMediaCaption(
                locale: 'fr-FR',
                mediaId: 'opening-captions-fr',
              ),
            ],
            provenance: ProjectMediaProvenance(
              source: 'Avelune Studio original',
              creator: 'Yoahn',
              sourceUrl: 'https://avelune.studio/media/opening',
            ),
            license: ProjectMediaLicense(
              identifier: 'LicenseRef-Avelune-Proprietary',
              name: 'Avelune proprietary media license',
              notice: 'Redistribution in exported games is allowed.',
            ),
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'video/mp4',
              container: 'mp4',
              codec: 'h264',
              audioCodec: 'aac',
              sizeBytes: 4096,
              width: 1920,
              height: 1080,
              durationMilliseconds: 12000,
            ),
          ),
        ],
      );

      final decoded = ProjectMediaCatalog.fromJson(catalog.toJson());
      final video = decoded.require('opening-video');

      expect(video.provenance!.creator, 'Yoahn');
      expect(video.license!.identifier, 'LicenseRef-Avelune-Proprietary');
      expect(
        video
            .resolveCaption(
              requestedLocale: 'fr-FR',
              projectDefaultLocale: 'en-US',
            )!
            .mediaId,
        'opening-captions-fr',
      );
      expect(
        video
            .resolveCaption(
              requestedLocale: 'de-DE',
              projectDefaultLocale: 'en-US',
            )!
            .mediaId,
        'opening-captions-en',
      );
      expect(
        video.resolveCaption(
          requestedLocale: 'de-DE',
          projectDefaultLocale: 'es-ES',
        ),
        isNull,
      );
      expect(decoded.toJson(), catalog.toJson());
    });

    test(
      'rejects duplicate locales and diagnoses invalid relationship kinds',
      () {
        expect(
          () => ProjectMediaAsset(
            id: 'opening-video',
            label: 'Opening video',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset.opening-video',
            captions: <ProjectMediaCaption>[
              ProjectMediaCaption(locale: 'fr-FR', mediaId: 'captions-a'),
              ProjectMediaCaption(locale: 'fr-FR', mediaId: 'captions-b'),
            ],
          ),
          throwsArgumentError,
        );

        final catalog = ProjectMediaCatalog(
          entries: <ProjectMediaAsset>[
            _image('not-captions'),
            ProjectMediaAsset(
              id: 'opening-video',
              label: 'Opening video',
              kind: ProjectMediaKind.video,
              sourceAssetId: 'asset.opening-video',
              captions: <ProjectMediaCaption>[
                ProjectMediaCaption(locale: 'fr-FR', mediaId: 'not-captions'),
              ],
            ),
          ],
        );
        final graph = PresentationReferenceGraph.build(
          mediaCatalog: catalog,
          sourceAssets: const <ProjectMediaSourceAssetDefinition>[
            ProjectMediaSourceAssetDefinition(
              id: 'asset.not-captions',
              label: 'Not captions',
            ),
            ProjectMediaSourceAssetDefinition(
              id: 'asset.opening-video',
              label: 'Opening video',
            ),
          ],
        );

        expect(
          graph.diagnostics.map((entry) => entry.code),
          contains(PresentationReferenceDiagnosticCodes.mediaUnsupported),
        );
      },
    );
  });
}

ProjectMediaAsset _caption(String id, String label) => ProjectMediaAsset(
  id: id,
  label: label,
  kind: ProjectMediaKind.captions,
  sourceAssetId: 'asset.$id',
);

ProjectMediaAsset _image(String id) => ProjectMediaAsset(
  id: id,
  label: id,
  kind: ProjectMediaKind.image,
  sourceAssetId: 'asset.$id',
);
