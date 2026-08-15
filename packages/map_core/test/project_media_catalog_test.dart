import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectMediaCatalog', () {
    test('roundtrips every canonical kind and stable media relation', () {
      final catalog = ProjectMediaCatalog(
        entries: [
          _entry(
            id: 'opening-video',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset.opening.video',
            posterMediaId: 'opening-poster',
            captionMediaIds: const ['opening-captions-fr'],
            fallbackMediaId: 'opening-poster',
          ),
          _entry(
            id: 'opening-poster',
            kind: ProjectMediaKind.poster,
            sourceAssetId: 'asset.opening.poster',
          ),
          _entry(
            id: 'opening-captions-fr',
            kind: ProjectMediaKind.captions,
            sourceAssetId: 'asset.opening.captions.fr',
          ),
          _entry(
            id: 'opening-image',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'asset.opening.image',
          ),
          _entry(
            id: 'opening-music',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset.opening.music',
          ),
        ],
      );

      final json = catalog.toJson();
      final decoded = ProjectMediaCatalog.fromJson(json);

      expect(json['schemaVersion'], ProjectMediaCatalog.schemaVersion);
      expect(decoded.entries.map((entry) => entry.id), [
        'opening-captions-fr',
        'opening-image',
        'opening-music',
        'opening-poster',
        'opening-video',
      ]);
      expect(decoded.toJson(), json);
      expect(decoded.entries.map((entry) => entry.kind).toSet(), {
        ProjectMediaKind.image,
        ProjectMediaKind.audio,
        ProjectMediaKind.video,
        ProjectMediaKind.poster,
        ProjectMediaKind.captions,
      });
    });

    test('keeps custom media kinds roundtrippable for future capabilities', () {
      final catalog = ProjectMediaCatalog(
        entries: [
          _entry(
            id: 'opening-vector',
            kind: ProjectMediaKind('vector_animation'),
            sourceAssetId: 'asset.opening.vector',
          ),
        ],
      );

      final decoded = ProjectMediaCatalog.fromJson(catalog.toJson());

      expect(decoded.entries.single.kind.id, 'vector_animation');
      expect(decoded.toJson(), catalog.toJson());
      expect(
        () => ProjectMediaKind.fromJson('invalid kind'),
        throwsFormatException,
      );
    });

    test('replaces the physical source without changing media identity', () {
      final original = ProjectMediaCatalog(
        entries: [
          _entry(
            id: 'opening-video',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset.opening.video.v1',
            posterMediaId: 'opening-poster',
            captionMediaIds: const ['opening-captions-fr'],
          ),
          _entry(
            id: 'opening-poster',
            kind: ProjectMediaKind.poster,
            sourceAssetId: 'asset.opening.poster',
          ),
          _entry(
            id: 'opening-captions-fr',
            kind: ProjectMediaKind.captions,
            sourceAssetId: 'asset.opening.captions.fr',
          ),
        ],
      );

      final replaced = original.replaceSource(
        mediaId: 'opening-video',
        sourceAssetId: 'asset.opening.video.v2',
      );

      expect(
        original.require('opening-video').sourceAssetId,
        'asset.opening.video.v1',
      );
      expect(replaced.require('opening-video').id, 'opening-video');
      expect(
        replaced.require('opening-video').sourceAssetId,
        'asset.opening.video.v2',
      );
      expect(replaced.require('opening-video').posterMediaId, 'opening-poster');
      expect(replaced.require('opening-video').captionMediaIds, [
        'opening-captions-fr',
      ]);
    });

    test('roundtrips observed technical metadata without trusting paths', () {
      final catalog = ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'opening-video',
            label: 'Opening video',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset.opening.video',
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'video/mp4',
              container: 'mp4',
              codec: 'h264',
              audioCodec: 'aac',
              sizeBytes: 42000,
              width: 1920,
              height: 1080,
              durationMilliseconds: 12000,
            ),
          ),
        ],
      );

      final decoded = ProjectMediaCatalog.fromJson(catalog.toJson());

      expect(decoded.toJson(), catalog.toJson());
      expect(decoded.entries.single.technicalMetadata!.toJson(), {
        'mediaType': 'video/mp4',
        'container': 'mp4',
        'codec': 'h264',
        'audioCodec': 'aac',
        'sizeBytes': 42000,
        'width': 1920,
        'height': 1080,
        'durationMilliseconds': 12000,
      });
    });

    test('rejects partial or non-positive observed metadata', () {
      expect(
        () => ProjectMediaTechnicalMetadata(
          mediaType: 'image/png',
          container: 'png',
          codec: 'png',
          sizeBytes: 24,
          width: 640,
        ),
        throwsArgumentError,
      );
      expect(
        () => ProjectMediaTechnicalMetadata(
          mediaType: 'audio/ogg',
          container: 'ogg',
          codec: 'vorbis',
          sizeBytes: 24,
          durationMilliseconds: 0,
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate identities and raw paths as source identities', () {
      expect(
        () => ProjectMediaCatalog(
          entries: [
            _entry(
              id: 'duplicate',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'asset.one',
            ),
            _entry(
              id: 'duplicate',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'asset.two',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => _entry(
          id: 'raw-path',
          kind: ProjectMediaKind.image,
          sourceAssetId: 'assets/presentation/raw.png',
        ),
        throwsArgumentError,
      );
    });

    test('rejects future schema versions and unknown fields', () {
      expect(
        () => ProjectMediaCatalog.fromJson({
          'schemaVersion': ProjectMediaCatalog.schemaVersion + 1,
          'entries': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ProjectMediaCatalog.fromJson({
          'schemaVersion': ProjectMediaCatalog.schemaVersion,
          'entries': <Object?>[],
          'legacyMedia': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ProjectMediaCatalog.fromJson({
          'schemaVersion': ProjectMediaCatalog.schemaVersion,
          'entries': [
            _entry(
              id: 'duplicate',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'asset.one',
            ).toJson(),
            _entry(
              id: 'duplicate',
              kind: ProjectMediaKind.image,
              sourceAssetId: 'asset.two',
            ).toJson(),
          ],
        }),
        throwsFormatException,
      );
    });
  });
}

ProjectMediaAsset _entry({
  required String id,
  required ProjectMediaKind kind,
  required String sourceAssetId,
  String? posterMediaId,
  List<String> captionMediaIds = const [],
  String? fallbackMediaId,
}) {
  return ProjectMediaAsset(
    id: id,
    label: id,
    kind: kind,
    sourceAssetId: sourceAssetId,
    posterMediaId: posterMediaId,
    captionMediaIds: captionMediaIds,
    fallbackMediaId: fallbackMediaId,
  );
}
