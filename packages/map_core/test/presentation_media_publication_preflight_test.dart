import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('PresentationMediaPublicationPreflight', () {
    test('exports rights and exact-boundary budgets before runtime', () {
      final catalog = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          _media(
            id: 'opening-image',
            kind: ProjectMediaKind.image,
            sizeBytes: 100,
            width: 100,
            height: 100,
          ),
        ],
      );
      const policy = PresentationMediaBudgetPolicy(
        maxFileBytes: 100,
        maxPresentationPayloadBytes: 100,
        maxSequenceDurationUs: 100,
        maxImageDimension: 100,
        maxImagePixels: 10000,
        maxVideoLongEdge: 100,
        maxVideoShortEdge: 100,
      );

      final receipt = const PresentationMediaPublicationPreflight().inspect(
        catalog: catalog,
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'opening-image', durationUs: 100),
        ],
        policy: policy,
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.android,
          PresentationMediaTargetPlatform.windows,
        },
      );

      expect(receipt.canPublish, isTrue);
      expect(receipt.totalPayloadBytes, 100);
      expect(receipt.estimatedDecodedVisualBytes, 40000);
      expect(receipt.sequences.single.payloadBytes, 100);
      expect(receipt.sequences.single.estimatedDecodedVisualBytes, 40000);
      expect(receipt.sequences.single.maxConcurrentVideoDecoders, 0);
      expect(receipt.platforms, hasLength(2));
      expect(receipt.platforms.every((entry) => entry.canPublish), isTrue);
      expect(
        receipt.platforms.every(
          (entry) => entry.estimatedDecodedVisualBytes == 40000,
        ),
        isTrue,
      );
      final exported = receipt.toJson();
      final media = (exported['media']! as List).single as Map;
      expect(media['provenance'], isA<Map>());
      expect(media['license'], isA<Map>());
      expect(exported['budgets'], policy.toJson());
      expect(
        (exported['budgets']! as Map)['deviceCacheBytes'],
        'profiledByBETA-CIN-032',
      );
    });

    test('requires a compatible fallback on platforms without video', () {
      final withoutFallback = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          _media(
            id: 'opening-video',
            kind: ProjectMediaKind.video,
            sizeBytes: 100,
            width: 1920,
            height: 1080,
            durationMilliseconds: 1000,
          ),
        ],
      );

      final blocked = const PresentationMediaPublicationPreflight().inspect(
        catalog: withoutFallback,
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'opening-video'),
        ],
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.windows,
        },
      );

      expect(blocked.canPublish, isFalse);
      expect(
        blocked.diagnostics.map((entry) => entry.code),
        contains(PresentationMediaPublicationDiagnosticCodes.mediaUnsupported),
      );

      final withPoster = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          _captionsMedia('opening-captions-fr'),
          _media(
            id: 'opening-poster',
            kind: ProjectMediaKind.poster,
            sizeBytes: 20,
            width: 1920,
            height: 1080,
          ),
          _media(
            id: 'opening-video',
            kind: ProjectMediaKind.video,
            sizeBytes: 100,
            width: 1920,
            height: 1080,
            durationMilliseconds: 1000,
            posterMediaId: 'opening-poster',
            captions: <ProjectMediaCaption>[
              ProjectMediaCaption(
                locale: 'fr-FR',
                mediaId: 'opening-captions-fr',
              ),
            ],
          ),
        ],
      );

      final ready = const PresentationMediaPublicationPreflight().inspect(
        catalog: withPoster,
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'opening-video'),
        ],
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.windows,
        },
      );

      expect(ready.canPublish, isTrue);
      expect(
        ready.platforms.single.resolutions
            .singleWhere((entry) => entry.mediaId == 'opening-video')
            .fallbackMediaId,
        'opening-poster',
      );
      expect(ready.platforms.single.payloadBytes, 40);
      expect(
        (ready.toJson()['media']! as List).every((item) {
          final media = item as Map;
          return media.containsKey('provenance') &&
              media.containsKey('license');
        }),
        isTrue,
      );
    });

    test('uses one conservative capability matrix for every platform', () {
      expect(
        presentationMediaPlatformCapabilities(
          PresentationMediaTargetPlatform.web,
        ).toJson(),
        <String, Object?>{
          'image': 'unsupported',
          'audio': 'unsupported',
          'video': 'unsupported',
          'captions': 'unsupported',
        },
      );

      for (final platform in <PresentationMediaTargetPlatform>{
        PresentationMediaTargetPlatform.windows,
        PresentationMediaTargetPlatform.linux,
      }) {
        final capabilities = presentationMediaPlatformCapabilities(platform);
        expect(capabilities.image, PresentationMediaPlatformCapability.target);
        expect(capabilities.audio, PresentationMediaPlatformCapability.target);
        expect(
          capabilities.video,
          PresentationMediaPlatformCapability.fallbackOnly,
        );
        expect(
          capabilities.captions,
          PresentationMediaPlatformCapability.target,
        );
      }
    });

    test('rejects an uncertified Web target before resolving media', () {
      final receipt = const PresentationMediaPublicationPreflight().inspect(
        catalog: ProjectMediaCatalog(
          entries: <ProjectMediaAsset>[
            _media(
              id: 'opening-image',
              kind: ProjectMediaKind.image,
              sizeBytes: 100,
              width: 100,
              height: 100,
            ),
          ],
        ),
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'opening-image'),
        ],
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.web,
        },
      );

      expect(receipt.canPublish, isFalse);
      expect(receipt.platforms.single.resolutions, isEmpty);
      expect(
        receipt.platforms.single.diagnostics.single,
        isA<PresentationMediaPublicationDiagnostic>()
            .having(
              (diagnostic) => diagnostic.code,
              'code',
              PresentationMediaPublicationDiagnosticCodes.platformUnsupported,
            )
            .having(
              (diagnostic) => diagnostic.constraint,
              'constraint',
              PresentationMediaPublicationConstraints.platformCertification,
            )
            .having((diagnostic) => diagnostic.path, 'path', 'platforms.web'),
      );
    });

    test('default publication excludes uncertified platforms', () {
      final receipt = const PresentationMediaPublicationPreflight().inspect(
        catalog: ProjectMediaCatalog(
          entries: <ProjectMediaAsset>[
            _media(
              id: 'opening-image',
              kind: ProjectMediaKind.image,
              sizeBytes: 100,
              width: 100,
              height: 100,
            ),
          ],
        ),
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'opening-image'),
        ],
      );

      expect(receipt.canPublish, isTrue);
      expect(
        receipt.platforms.map((entry) => entry.platform).toSet(),
        defaultPresentationMediaTargetPlatforms,
      );
      expect(
        receipt.platforms.map((entry) => entry.platform),
        isNot(contains(PresentationMediaTargetPlatform.web)),
      );
    });

    test('reports missing rights and every authored budget overflow', () {
      final catalog = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          _media(
            id: 'oversized-video',
            kind: ProjectMediaKind.video,
            sizeBytes: 101,
            width: 101,
            height: 100,
            durationMilliseconds: 1000,
            rights: false,
          ),
        ],
      );
      const policy = PresentationMediaBudgetPolicy(
        maxFileBytes: 100,
        maxPresentationPayloadBytes: 100,
        maxSequenceDurationUs: 100,
        maxImageDimension: 100,
        maxImagePixels: 10000,
        maxVideoLongEdge: 100,
        maxVideoShortEdge: 100,
      );

      final receipt = const PresentationMediaPublicationPreflight().inspect(
        catalog: catalog,
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'oversized-video', durationUs: 101),
        ],
        policy: policy,
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.android,
        },
      );

      expect(receipt.canPublish, isFalse);
      expect(receipt.diagnostics.map((entry) => entry.code).toSet(), <String>{
        PresentationMediaPublicationDiagnosticCodes.mediaUnsupported,
        PresentationMediaPublicationDiagnosticCodes.budgetExceeded,
      });
      expect(
        receipt.diagnostics.map((entry) => entry.constraint).toSet(),
        containsAll(<String>{
          PresentationMediaPublicationConstraints.provenance,
          PresentationMediaPublicationConstraints.license,
          PresentationMediaPublicationConstraints.fileBytes,
          PresentationMediaPublicationConstraints.presentationPayloadBytes,
          PresentationMediaPublicationConstraints.sequenceDurationUs,
          PresentationMediaPublicationConstraints.sequencePayloadBytes,
          PresentationMediaPublicationConstraints.resolution,
        }),
      );
    });

    test('blocks overlapping videos beyond the authored decoder budget', () {
      final catalog = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          _media(
            id: 'video-a',
            kind: ProjectMediaKind.video,
            sizeBytes: 100,
            width: 1920,
            height: 1080,
            durationMilliseconds: 1000,
          ),
          _media(
            id: 'video-b',
            kind: ProjectMediaKind.video,
            sizeBytes: 100,
            width: 1080,
            height: 1920,
            durationMilliseconds: 1000,
          ),
        ],
      );

      final receipt = const PresentationMediaPublicationPreflight().inspect(
        catalog: catalog,
        cinematics: <PresentationCinematicAsset>[_overlappingVideoCinematic()],
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.android,
        },
      );

      expect(receipt.canPublish, isFalse);
      expect(receipt.sequences.single.maxConcurrentVideoDecoders, 2);
      expect(
        receipt.diagnostics.map((entry) => entry.code),
        contains(
          PresentationMediaPublicationDiagnosticCodes
              .concurrentVideoBudgetExceeded,
        ),
      );
      expect(
        receipt.diagnostics.single.constraint,
        PresentationMediaPublicationConstraints.concurrentVideoDecoders,
      );
    });

    test('blocks an incompatible localized caption codec', () {
      final catalog = ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'captions-fr',
            label: 'Captions FR',
            kind: ProjectMediaKind.captions,
            sourceAssetId: 'asset.captions-fr',
            provenance: ProjectMediaProvenance(
              source: 'Avelune Studio original',
            ),
            license: ProjectMediaLicense(
              identifier: 'LicenseRef-Avelune-Proprietary',
              name: 'Avelune proprietary media license',
            ),
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'text/plain',
              container: 'text',
              codec: 'plain',
              sizeBytes: 20,
            ),
          ),
          _media(
            id: 'opening-image',
            kind: ProjectMediaKind.image,
            sizeBytes: 100,
            width: 100,
            height: 100,
            captions: <ProjectMediaCaption>[
              ProjectMediaCaption(locale: 'fr-FR', mediaId: 'captions-fr'),
            ],
          ),
        ],
      );

      final receipt = const PresentationMediaPublicationPreflight().inspect(
        catalog: catalog,
        cinematics: <PresentationCinematicAsset>[
          _cinematic(resourceId: 'opening-image'),
        ],
        targetPlatforms: const <PresentationMediaTargetPlatform>{
          PresentationMediaTargetPlatform.android,
        },
      );

      expect(receipt.canPublish, isFalse);
      expect(
        receipt.diagnostics,
        contains(
          isA<PresentationMediaPublicationDiagnostic>()
              .having(
                (diagnostic) => diagnostic.code,
                'code',
                PresentationMediaPublicationDiagnosticCodes.mediaUnsupported,
              )
              .having(
                (diagnostic) => diagnostic.mediaId,
                'mediaId',
                'captions-fr',
              ),
        ),
      );
    });
  });
}

ProjectMediaAsset _media({
  required String id,
  required ProjectMediaKind kind,
  required int sizeBytes,
  required int width,
  required int height,
  int? durationMilliseconds,
  String? posterMediaId,
  Iterable<ProjectMediaCaption> captions = const [],
  bool rights = true,
}) => ProjectMediaAsset(
  id: id,
  label: id,
  kind: kind,
  sourceAssetId: 'asset.$id',
  posterMediaId: posterMediaId,
  captions: captions,
  provenance: rights
      ? ProjectMediaProvenance(source: 'Avelune Studio original')
      : null,
  license: rights
      ? ProjectMediaLicense(
          identifier: 'LicenseRef-Avelune-Proprietary',
          name: 'Avelune proprietary media license',
        )
      : null,
  technicalMetadata: ProjectMediaTechnicalMetadata(
    mediaType: switch (kind.id) {
      'video' => 'video/mp4',
      _ => 'image/png',
    },
    container: switch (kind.id) {
      'video' => 'mp4',
      _ => 'png',
    },
    codec: switch (kind.id) {
      'video' => 'h264',
      _ => 'png',
    },
    sizeBytes: sizeBytes,
    width: width,
    height: height,
    durationMilliseconds: durationMilliseconds,
  ),
);

ProjectMediaAsset _captionsMedia(String id) => ProjectMediaAsset(
  id: id,
  label: id,
  kind: ProjectMediaKind.captions,
  sourceAssetId: 'asset.$id',
  provenance: ProjectMediaProvenance(source: 'Avelune Studio original'),
  license: ProjectMediaLicense(
    identifier: 'LicenseRef-Avelune-Proprietary',
    name: 'Avelune proprietary media license',
  ),
  technicalMetadata: ProjectMediaTechnicalMetadata(
    mediaType: 'text/vtt',
    container: 'webvtt',
    codec: 'webvtt',
    sizeBytes: 20,
  ),
);

PresentationCinematicAsset _cinematic({
  required String resourceId,
  int durationUs = 100,
}) => PresentationCinematicAsset(
  id: 'opening',
  title: 'Opening',
  durationUs: durationUs,
  layers: <PresentationLayer>[
    PresentationLayer(id: 'main', label: 'Main', zIndex: 0),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'visuals',
      label: 'Visuals',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        PresentationVisualClip(
          id: 'opening-clip',
          startUs: 0,
          durationUs: durationUs,
          layerId: 'main',
          resourceId: resourceId,
        ),
      ],
    ),
  ],
);

PresentationCinematicAsset _overlappingVideoCinematic() =>
    PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 100,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'back', label: 'Back', zIndex: 0),
        PresentationLayer(id: 'front', label: 'Front', zIndex: 1),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visuals',
          label: 'Visuals',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationVisualClip(
              id: 'video-a-clip',
              startUs: 0,
              durationUs: 100,
              layerId: 'back',
              resourceId: 'video-a',
            ),
            PresentationVisualClip(
              id: 'video-b-clip',
              startUs: 0,
              durationUs: 100,
              layerId: 'front',
              resourceId: 'video-b',
            ),
          ],
        ),
      ],
    );
