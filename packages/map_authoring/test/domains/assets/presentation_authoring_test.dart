import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('presentation authoring', () {
    test('validates every media reference against the canonical asset catalog',
        () {
      final profile = _profile(
        branding: const ProjectBrandingProfile(
          iconPath: 'presentation/icon.png',
          titleMusicPath: 'presentation/title.png',
        ),
      );
      final result = const PresentationAuthoringGate().inspect(
        profile,
        _catalog(),
      );

      expect(result.canPublish, isFalse);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.code),
        contains('presentationAssetMediaTypeMismatch'),
      );
      expect(
        result.diagnostics
            .where(
                (diagnostic) => diagnostic.code == 'presentationAssetMissing')
            .map((diagnostic) => diagnostic.path),
        contains(r'$.presentation.typography.body.licensePath'),
      );
    });

    test('editor adapter and mutation gate share the same projected state', () {
      final profile = _profile();
      final manifest = ProjectManifest(
        name: 'Presentation fixture',
        maps: const [],
        tilesets: const [],
      );
      final result = const ProjectPresentationEditorAdapter().prepare(
        manifest: manifest,
        profile: profile,
        assets: _catalog(includeLicense: true),
      );

      expect(result.canApply, isTrue);
      expect(result.projectedManifest.presentation, profile);
      expect(
        result.diagnostics,
        const PresentationAuthoringGate()
            .inspect(profile, _catalog(includeLicense: true))
            .diagnostics,
      );
    });

    test('preview handles are revision-bound and reject stale consumption', () {
      final preview = const PresentationPreviewService().create(
        profile: _profile(),
        projectRevision: _revision('a'),
        assets: _catalog(includeLicense: true),
      );

      expect(preview.assetHandles, hasLength(6));
      expect(preview.previewId, startsWith('presentation-preview:'));
      preview.requireRevision(_revision('a'));
      expect(
        () => preview.requireRevision(_revision('b')),
        throwsA(
          isA<PresentationAuthoringException>().having(
            (error) => error.code,
            'code',
            'presentation.preview_stale',
          ),
        ),
      );
    });

    test('media processing jobs are asynchronous and idempotent', () async {
      final processing = Completer<MediaProcessingResult>();
      final port = InMemoryMediaProcessingPort(
        processor: (request) => processing.future,
      );
      final request = MediaProcessingRequest(
        idempotencyKey: 'intro-transcode-1',
        kind: MediaProcessingKind.transcodeVideo,
        source: _artifact('video/mp4', 42),
        expectedProjectRevision: _revision('c'),
        targetMediaType: 'video/webm',
      );

      final first = await port.submit(request);
      final duplicate = await port.submit(request);
      expect(first.status, MediaProcessingStatus.queued);
      expect(duplicate.jobId, first.jobId);

      processing.complete(
        MediaProcessingResult(
          output: _artifact('video/webm', 43),
          metadata: const {'videoCodec': 'vp9'},
        ),
      );
      final completed = await port.wait(first.jobId);
      expect(completed.status, MediaProcessingStatus.succeeded);
      expect(completed.result?.output.mediaType, 'video/webm');
    });

    test('dispatcher exposes canonical presentation mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(ids, containsAll({'presentation.update', 'presentation.delete'}));
    });

    test('validates every authored responsive intro and title loop asset', () {
      final profile = _profile().copyWith(
        titleMotion: const ProjectTitleMotionProfile(
          promptLoop: ProjectResponsiveVideoProfile(
            landscape: ProjectVideoVariantProfile(
              videoPath: 'presentation/prompt-landscape.mp4',
              posterPath: 'presentation/prompt-landscape.png',
              durationMilliseconds: 7000,
              width: 1920,
              height: 1080,
              bitrateKbps: 3000,
              sizeBytes: 6000000,
              videoCodec: 'h264',
              audioCodec: 'none',
            ),
            portrait: ProjectVideoVariantProfile(
              videoPath: 'presentation/prompt-portrait.mp4',
              posterPath: 'presentation/prompt-portrait.png',
              durationMilliseconds: 7000,
              width: 1080,
              height: 1920,
              bitrateKbps: 3000,
              sizeBytes: 6000000,
              videoCodec: 'h264',
              audioCodec: 'none',
            ),
          ),
        ),
      );

      final result = const PresentationAuthoringGate().inspect(
        profile,
        _catalog(includeLicense: true, includeMotion: true),
      );

      expect(result.canPublish, isTrue);
      final preview = const PresentationPreviewService().create(
        profile: profile,
        projectRevision: _revision('d'),
        assets: _catalog(includeLicense: true, includeMotion: true),
      );
      expect(
        preview.assetHandles,
        containsAll(<String>[
          _catalog(includeMotion: true)
              .records
              .singleWhere((asset) => asset.id == 'prompt-landscape')
              .artifact
              .handle,
          _catalog(includeMotion: true)
              .records
              .singleWhere((asset) => asset.id == 'prompt-portrait')
              .artifact
              .handle,
        ]),
      );
    });
  });
}

ProjectPresentationProfile _profile({ProjectBrandingProfile? branding}) =>
    ProjectPresentationProfile(
      branding: branding ??
          const ProjectBrandingProfile(
            iconPath: 'presentation/icon.png',
            titleMusicPath: 'presentation/title.ogg',
          ),
      intro: const ProjectIntroVideoProfile(
        media: ProjectResponsiveVideoProfile(
          landscape: ProjectVideoVariantProfile(
            videoPath: 'presentation/intro.mp4',
            posterPath: 'presentation/poster.png',
            durationMilliseconds: 3000,
            width: 1280,
            height: 720,
            bitrateKbps: 4000,
            sizeBytes: 42,
            videoCodec: 'h264',
            audioCodec: 'aac',
          ),
        ),
      ),
      typography: const ProjectTypographyProfile(
        body: ProjectTypographyRoleProfile(
          fontPath: 'presentation/body.ttf',
          family: 'Fixture Sans',
          licensePath: 'presentation/body-license.txt',
          redistributable: true,
          fallbackFamilies: ['sans-serif'],
          glyphCoverage: ['latin', 'latinExtended', 'digits', 'punctuation'],
        ),
      ),
      theme: safeProjectSemanticTheme,
    );

AssetCatalog _catalog({
  bool includeLicense = false,
  bool includeMotion = false,
}) =>
    AssetCatalog(records: [
      _asset('icon', 'presentation/icon.png', 'image/png', 1),
      _asset('wrong-music', 'presentation/title.png', 'image/png', 7),
      _asset('music', 'presentation/title.ogg', 'audio/ogg', 2),
      _asset('intro', 'presentation/intro.mp4', 'video/mp4', 3),
      _asset('poster', 'presentation/poster.png', 'image/png', 4),
      if (includeMotion) ...<AssetRecord>[
        _asset(
          'prompt-landscape',
          'presentation/prompt-landscape.mp4',
          'video/mp4',
          8,
        ),
        _asset(
          'prompt-landscape-poster',
          'presentation/prompt-landscape.png',
          'image/png',
          9,
        ),
        _asset(
          'prompt-portrait',
          'presentation/prompt-portrait.mp4',
          'video/mp4',
          10,
        ),
        _asset(
          'prompt-portrait-poster',
          'presentation/prompt-portrait.png',
          'image/png',
          11,
        ),
      ],
      _asset('font', 'presentation/body.ttf', 'font/ttf', 5),
      if (includeLicense)
        _asset(
          'font-license',
          'presentation/body-license.txt',
          'text/plain',
          6,
        ),
    ]);

AssetRecord _asset(String id, String path, String mediaType, int byte) =>
    AssetRecord(
      id: id,
      logicalPath: path,
      artifact: _artifact(mediaType, byte),
    );

ContentArtifactRef _artifact(String mediaType, int byte) =>
    ContentArtifactRef.fromBytes([byte], mediaType: mediaType);

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';
