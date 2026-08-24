import 'dart:convert';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import 'authoring_query_adapter.dart';

enum PresentationTimelineProjectionKind { audio, video, captions }

enum PresentationTimelineProjectionStatus {
  loading,
  ready,
  missing,
  unsupported,
  error,
}

final class PresentationTimelineCaptionSegment {
  const PresentationTimelineCaptionSegment({
    required this.startUs,
    required this.endUs,
    required this.text,
  });

  final int startUs;
  final int endUs;
  final String text;
}

final class PresentationTimelineProjectionRequest {
  const PresentationTimelineProjectionRequest({
    required this.mediaId,
    required this.kind,
    required this.sampleCount,
  }) : assert(sampleCount > 0);

  final String mediaId;
  final PresentationTimelineProjectionKind kind;
  final int sampleCount;
}

final class PresentationTimelineMediaProjection {
  const PresentationTimelineMediaProjection._({
    required this.mediaId,
    required this.status,
    required this.waveform,
    required this.captions,
    this.thumbnailBytes,
    this.diagnostic,
    this.fallbackUsed = false,
  }) : assert(
         status == PresentationTimelineProjectionStatus.ready ||
             status == PresentationTimelineProjectionStatus.loading ||
             diagnostic != null,
       );

  const PresentationTimelineMediaProjection.loading({required String mediaId})
    : this._(
        mediaId: mediaId,
        status: PresentationTimelineProjectionStatus.loading,
        waveform: const <double>[],
        captions: const <PresentationTimelineCaptionSegment>[],
      );

  const PresentationTimelineMediaProjection.ready({
    required String mediaId,
    List<double> waveform = const <double>[],
    List<PresentationTimelineCaptionSegment> captions =
        const <PresentationTimelineCaptionSegment>[],
    Uint8List? thumbnailBytes,
    bool fallbackUsed = false,
    String? diagnostic,
  }) : this._(
         mediaId: mediaId,
         status: PresentationTimelineProjectionStatus.ready,
         waveform: waveform,
         captions: captions,
         thumbnailBytes: thumbnailBytes,
         fallbackUsed: fallbackUsed,
         diagnostic: diagnostic,
       );

  const PresentationTimelineMediaProjection.unavailable({
    required String mediaId,
    required PresentationTimelineProjectionStatus status,
    required String diagnostic,
  }) : this._(
         mediaId: mediaId,
         status: status,
         waveform: const <double>[],
         captions: const <PresentationTimelineCaptionSegment>[],
         diagnostic: diagnostic,
       );

  final String mediaId;
  final PresentationTimelineProjectionStatus status;
  final List<double> waveform;
  final List<PresentationTimelineCaptionSegment> captions;
  final Uint8List? thumbnailBytes;
  final String? diagnostic;
  final bool fallbackUsed;

  bool get loading => status == PresentationTimelineProjectionStatus.loading;
  bool get available => status == PresentationTimelineProjectionStatus.ready;
}

abstract interface class PresentationTimelineProjectionGateway {
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  );
}

final class PresentationTimelineProjectionMedia {
  const PresentationTimelineProjectionMedia({
    required this.mediaId,
    required this.kind,
    required this.sourceAvailable,
    this.sourceBytes,
    this.posterBytes,
    this.fallbackUsed = false,
  });

  final String mediaId;
  final ProjectMediaKind kind;
  final bool sourceAvailable;
  final Uint8List? sourceBytes;
  final Uint8List? posterBytes;
  final bool fallbackUsed;
}

abstract interface class PresentationTimelineProjectionMediaReader {
  Future<PresentationTimelineProjectionMedia?> read(
    String projectRootPath,
    String mediaId,
  );
}

final class CanonicalPresentationTimelineProjectionGateway
    implements PresentationTimelineProjectionGateway {
  const CanonicalPresentationTimelineProjectionGateway({
    required PresentationTimelineProjectionMediaReader reader,
  }) : _reader = reader;

  final PresentationTimelineProjectionMediaReader _reader;

  @override
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  ) async {
    final media = await _reader.read(projectRootPath, request.mediaId);
    if (media == null || !media.sourceAvailable) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.missing,
        diagnostic: 'Média introuvable',
      );
    }
    if (!_matches(request.kind, media.kind)) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.error,
        diagnostic: 'Type de média incompatible avec la piste',
      );
    }
    return switch (request.kind) {
      PresentationTimelineProjectionKind.audio => _audio(request, media),
      PresentationTimelineProjectionKind.video => _video(request, media),
      PresentationTimelineProjectionKind.captions => _captions(request, media),
    };
  }

  Future<PresentationTimelineMediaProjection> _audio(
    PresentationTimelineProjectionRequest request,
    PresentationTimelineProjectionMedia media,
  ) async {
    final bytes = media.sourceBytes;
    if (bytes == null) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.missing,
        diagnostic: 'Source audio introuvable',
      );
    }
    try {
      final waveform = await Isolate.run(
        () => _decodeWaveform(bytes, request.sampleCount),
      );
      return PresentationTimelineMediaProjection.ready(
        mediaId: request.mediaId,
        waveform: waveform,
        fallbackUsed: media.fallbackUsed,
      );
    } on FormatException catch (error) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.unsupported,
        diagnostic: error.message,
      );
    }
  }

  Future<PresentationTimelineMediaProjection> _video(
    PresentationTimelineProjectionRequest request,
    PresentationTimelineProjectionMedia media,
  ) async {
    final bytes = media.posterBytes;
    if (bytes == null) {
      return PresentationTimelineMediaProjection.ready(
        mediaId: request.mediaId,
        fallbackUsed: media.fallbackUsed,
        diagnostic: 'Poster de prévisualisation absent',
      );
    }
    try {
      final thumbnail = await Isolate.run(
        () => _normalizeThumbnail(bytes, request.sampleCount * 2),
      );
      return PresentationTimelineMediaProjection.ready(
        mediaId: request.mediaId,
        thumbnailBytes: thumbnail,
        fallbackUsed: media.fallbackUsed,
      );
    } on FormatException catch (error) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.unsupported,
        diagnostic: error.message,
      );
    }
  }

  Future<PresentationTimelineMediaProjection> _captions(
    PresentationTimelineProjectionRequest request,
    PresentationTimelineProjectionMedia media,
  ) async {
    final bytes = media.sourceBytes;
    if (bytes == null) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.missing,
        diagnostic: 'Source de captions introuvable',
      );
    }
    try {
      final segments = await Isolate.run(() => _decodeWebVtt(bytes));
      return PresentationTimelineMediaProjection.ready(
        mediaId: request.mediaId,
        captions: segments,
        fallbackUsed: media.fallbackUsed,
      );
    } on FormatException catch (error) {
      return PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.unsupported,
        diagnostic: error.message,
      );
    }
  }
}

final class AuthoringPresentationTimelineProjectionMediaReader
    implements PresentationTimelineProjectionMediaReader {
  const AuthoringPresentationTimelineProjectionMediaReader({
    required AuthoringQueryAdapter queries,
  }) : _queries = queries;

  final AuthoringQueryAdapter _queries;

  @override
  Future<PresentationTimelineProjectionMedia?> read(
    String projectRootPath,
    String mediaId,
  ) async {
    final session = await _queries.open(projectRootPath);
    final media = _media(session, mediaId);
    if (media == null) return null;
    final kind = ProjectMediaKind.fromJson(media['kind']);
    final resolved = _resolveSource(session, media, <String>{});
    var poster = (bytes: null as Uint8List?, fallbackUsed: false);
    if (kind == ProjectMediaKind.video) {
      poster = _resolvePoster(session, media, <String>{});
    }
    return PresentationTimelineProjectionMedia(
      mediaId: mediaId,
      kind: kind,
      sourceAvailable: resolved.bytes != null,
      sourceBytes: resolved.bytes,
      posterBytes: poster.bytes,
      fallbackUsed: resolved.fallbackUsed || poster.fallbackUsed,
    );
  }

  ({Uint8List? bytes, bool fallbackUsed}) _resolveSource(
    EditorAuthoringReadSession session,
    Map<String, Object?> media,
    Set<String> visited,
  ) {
    final id = media['id'] as String;
    if (!visited.add(id)) return (bytes: null, fallbackUsed: false);
    final sourceAssetId = media['sourceAssetId'] as String?;
    final source = sourceAssetId == null
        ? null
        : session.assetBytes(sourceAssetId);
    if (source != null) {
      return (bytes: Uint8List.fromList(source), fallbackUsed: false);
    }
    final fallbackId = media['fallbackMediaId'] as String?;
    final fallback = fallbackId == null ? null : _media(session, fallbackId);
    if (fallback == null || fallback['kind'] != media['kind']) {
      return (bytes: null, fallbackUsed: false);
    }
    final resolved = _resolveSource(session, fallback, visited);
    return (bytes: resolved.bytes, fallbackUsed: resolved.bytes != null);
  }

  ({Uint8List? bytes, bool fallbackUsed}) _resolvePoster(
    EditorAuthoringReadSession session,
    Map<String, Object?> media,
    Set<String> visited,
  ) {
    final id = media['id'] as String;
    if (!visited.add(id)) return (bytes: null, fallbackUsed: false);
    final posterId = media['posterMediaId'] as String?;
    final poster = posterId == null ? null : _media(session, posterId);
    if (poster != null) {
      final resolved = _resolveSource(session, poster, <String>{});
      if (resolved.bytes != null) {
        return (bytes: resolved.bytes, fallbackUsed: false);
      }
    }
    final fallbackId = media['fallbackMediaId'] as String?;
    final fallback = fallbackId == null ? null : _media(session, fallbackId);
    if (fallback == null) return (bytes: null, fallbackUsed: false);
    final fallbackKind = ProjectMediaKind.fromJson(fallback['kind']);
    if (fallbackKind == ProjectMediaKind.image ||
        fallbackKind == ProjectMediaKind.poster) {
      final resolved = _resolveSource(session, fallback, <String>{});
      return (bytes: resolved.bytes, fallbackUsed: resolved.bytes != null);
    }
    if (fallbackKind == ProjectMediaKind.video) {
      final resolved = _resolvePoster(session, fallback, visited);
      return (
        bytes: resolved.bytes,
        fallbackUsed: resolved.bytes != null || resolved.fallbackUsed,
      );
    }
    return (bytes: null, fallbackUsed: false);
  }

  Map<String, Object?>? _media(
    EditorAuthoringReadSession session,
    String mediaId,
  ) {
    final response = session.query(
      AuthoringQueryRequest(
        resourceKind: 'presentationMedia',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: <String>[mediaId],
      ),
    );
    final items = response['items'];
    if (items is! List || items.isEmpty || items.single is! Map) return null;
    return Map<String, Object?>.from(items.single as Map);
  }
}

final class PresentationTimelineProjectionController extends ChangeNotifier {
  PresentationTimelineProjectionController({
    required this.projectRootPath,
    required PresentationTimelineProjectionGateway gateway,
  }) : _gateway = gateway;

  /// How many resolved projections stay warm behind the viewport.
  ///
  /// A waveform is a couple hundred doubles and a lane thumbnail is a few
  /// hundred pixels wide, so the whole cache is cheap — far cheaper than
  /// re-reading the media and spawning a decoding isolate every time a clip
  /// scrolls back into sight.
  static const int retainedProjections = 192;

  final String projectRootPath;
  final PresentationTimelineProjectionGateway _gateway;

  /// Insertion order is the recency order: [_touch] moves a key to the end,
  /// and [_evict] drops from the front.
  final Map<_ProjectionKey, PresentationTimelineMediaProjection> _projections =
      <_ProjectionKey, PresentationTimelineMediaProjection>{};
  final Map<_ProjectionKey, int> _tokens = <_ProjectionKey, int>{};
  Set<_ProjectionKey> _activeKeys = const <_ProjectionKey>{};
  bool _disposed = false;

  PresentationTimelineMediaProjection? projectionFor(
    PresentationClip clip, {
    required double pixelsPerSecond,
  }) {
    final key = _keyFor(clip, pixelsPerSecond);
    return key == null ? null : _projections[key];
  }

  void sync({
    required Iterable<PresentationClip> clips,
    required double pixelsPerSecond,
  }) {
    if (_disposed) return;
    final keys = <_ProjectionKey>{
      for (final clip in clips) ?_keyFor(clip, pixelsPerSecond),
    };
    var changed = false;
    for (final key in _activeKeys.difference(keys)) {
      // A projection that already resolved outlives the viewport. Only an
      // in-flight one is cancelled: finishing a decode for a clip nobody
      // looks at is wasted work, and it would otherwise leave a permanent
      // pending badge behind.
      if (!(_projections[key]?.loading ?? false)) continue;
      _tokens[key] = (_tokens[key] ?? 0) + 1;
      _projections.remove(key);
      changed = true;
    }
    _activeKeys = Set<_ProjectionKey>.unmodifiable(keys);
    for (final key in keys) {
      if (_projections.containsKey(key)) {
        _touch(key);
        continue;
      }
      _projections[key] = PresentationTimelineMediaProjection.loading(
        mediaId: key.mediaId,
      );
      changed = true;
      _load(key);
    }
    _evict();
    if (changed) notifyListeners();
  }

  void _touch(_ProjectionKey key) {
    final projection = _projections.remove(key);
    if (projection != null) _projections[key] = projection;
  }

  void _evict() {
    if (_projections.length <= retainedProjections) return;
    for (final key in _projections.keys.toList(growable: false)) {
      if (_projections.length <= retainedProjections) return;
      if (_activeKeys.contains(key)) continue;
      _tokens[key] = (_tokens[key] ?? 0) + 1;
      _projections.remove(key);
    }
  }

  void invalidateMedia(String mediaId) {
    if (_disposed) return;
    final keys = <_ProjectionKey>{
      ..._projections.keys.where((key) => key.mediaId == mediaId),
      ..._tokens.keys.where((key) => key.mediaId == mediaId),
    };
    var changed = false;
    for (final key in keys) {
      _tokens[key] = (_tokens[key] ?? 0) + 1;
      changed = _projections.remove(key) != null || changed;
    }
    if (changed) notifyListeners();
  }

  Future<void> _load(_ProjectionKey key) async {
    final token = (_tokens[key] ?? 0) + 1;
    _tokens[key] = token;
    PresentationTimelineMediaProjection projection;
    try {
      projection = await _gateway.load(
        projectRootPath,
        PresentationTimelineProjectionRequest(
          mediaId: key.mediaId,
          kind: key.kind,
          sampleCount: key.sampleCount,
        ),
      );
    } on Object catch (error) {
      projection = PresentationTimelineMediaProjection.unavailable(
        mediaId: key.mediaId,
        status: PresentationTimelineProjectionStatus.error,
        diagnostic: 'Aperçu indisponible : $error',
      );
    }
    // Only the token gates a publication: a key that left the viewport while
    // loading already had its token bumped, and one that is merely warm in
    // the cache must still receive its result.
    if (_disposed || _tokens[key] != token) return;
    _projections[key] = projection;
    _evict();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final key in _tokens.keys) {
      _tokens[key] = _tokens[key]! + 1;
    }
    _activeKeys = const <_ProjectionKey>{};
    _projections.clear();
    super.dispose();
  }
}

final class _ProjectionKey {
  const _ProjectionKey({
    required this.mediaId,
    required this.kind,
    required this.sampleCount,
  });

  final String mediaId;
  final PresentationTimelineProjectionKind kind;
  final int sampleCount;

  @override
  bool operator ==(Object other) =>
      other is _ProjectionKey &&
      other.mediaId == mediaId &&
      other.kind == kind &&
      other.sampleCount == sampleCount;

  @override
  int get hashCode => Object.hash(mediaId, kind, sampleCount);
}

_ProjectionKey? _keyFor(PresentationClip clip, double pixelsPerSecond) {
  final sampleCount = pixelsPerSecond < 160
      ? 64
      : pixelsPerSecond < 320
      ? 128
      : 256;
  return switch (clip) {
    PresentationAudioClip() => _ProjectionKey(
      mediaId: clip.resourceId,
      kind: PresentationTimelineProjectionKind.audio,
      sampleCount: sampleCount,
    ),
    PresentationVisualClip(mediaKind: PresentationVisualMediaKind.video) =>
      _ProjectionKey(
        mediaId: clip.resourceId,
        kind: PresentationTimelineProjectionKind.video,
        sampleCount: sampleCount,
      ),
    PresentationCaptionClip() => _ProjectionKey(
      mediaId: clip.captionId,
      kind: PresentationTimelineProjectionKind.captions,
      sampleCount: sampleCount,
    ),
    _ => null,
  };
}

bool _matches(
  PresentationTimelineProjectionKind projectionKind,
  ProjectMediaKind mediaKind,
) => switch (projectionKind) {
  PresentationTimelineProjectionKind.audio =>
    mediaKind == ProjectMediaKind.audio,
  PresentationTimelineProjectionKind.video =>
    mediaKind == ProjectMediaKind.video,
  PresentationTimelineProjectionKind.captions =>
    mediaKind == ProjectMediaKind.captions,
};

List<double> _decodeWaveform(Uint8List bytes, int sampleCount) {
  if (bytes.length < 44 ||
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
      ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != 'WAVE') {
    throw const FormatException(
      'Waveform disponible uniquement pour les sources WAV PCM.',
    );
  }
  final data = ByteData.sublistView(bytes);
  var offset = 12;
  int? audioFormat;
  int? channels;
  int? bitsPerSample;
  int? dataOffset;
  int? dataLength;
  while (offset + 8 <= bytes.length) {
    final chunkId = ascii.decode(
      bytes.sublist(offset, offset + 4),
      allowInvalid: true,
    );
    final chunkLength = data.getUint32(offset + 4, Endian.little);
    final payloadOffset = offset + 8;
    if (payloadOffset + chunkLength > bytes.length) break;
    if (chunkId == 'fmt ' && chunkLength >= 16) {
      audioFormat = data.getUint16(payloadOffset, Endian.little);
      channels = data.getUint16(payloadOffset + 2, Endian.little);
      bitsPerSample = data.getUint16(payloadOffset + 14, Endian.little);
    } else if (chunkId == 'data') {
      dataOffset = payloadOffset;
      dataLength = chunkLength;
    }
    offset = payloadOffset + chunkLength + (chunkLength.isOdd ? 1 : 0);
  }
  if (audioFormat == null ||
      channels == null ||
      channels < 1 ||
      bitsPerSample == null ||
      dataOffset == null ||
      dataLength == null) {
    throw const FormatException('Structure WAV incomplète.');
  }
  final bytesPerSample = bitsPerSample ~/ 8;
  if ((audioFormat != 1 && audioFormat != 3) ||
      !<int>{1, 2, 3, 4}.contains(bytesPerSample) ||
      (audioFormat == 3 && bitsPerSample != 32)) {
    throw const FormatException('Format WAV non supporté pour la waveform.');
  }
  final frameSize = bytesPerSample * channels;
  final frameCount = dataLength ~/ frameSize;
  if (frameCount == 0) {
    throw const FormatException('Source WAV vide.');
  }
  final amplitudes = List<double>.filled(sampleCount, 0);
  for (var frame = 0; frame < frameCount; frame += 1) {
    var frameAmplitude = 0.0;
    for (var channel = 0; channel < channels; channel += 1) {
      final sampleOffset =
          dataOffset + frame * frameSize + channel * bytesPerSample;
      final amplitude = _readWaveSample(
        data,
        sampleOffset,
        audioFormat: audioFormat,
        bitsPerSample: bitsPerSample,
      ).abs();
      frameAmplitude = math.max(frameAmplitude, amplitude);
    }
    final bucket = math.min(sampleCount - 1, frame * sampleCount ~/ frameCount);
    amplitudes[bucket] = math.max(amplitudes[bucket], frameAmplitude);
  }
  final peak = amplitudes.reduce(math.max);
  if (peak == 0) return List<double>.unmodifiable(amplitudes);
  return List<double>.unmodifiable(
    amplitudes.map((value) => (value / peak).clamp(0, 1).toDouble()),
  );
}

double _readWaveSample(
  ByteData data,
  int offset, {
  required int audioFormat,
  required int bitsPerSample,
}) {
  if (audioFormat == 3) return data.getFloat32(offset, Endian.little);
  return switch (bitsPerSample) {
    8 => (data.getUint8(offset) - 128) / 128,
    16 => data.getInt16(offset, Endian.little) / 32768,
    24 => _readInt24(data, offset) / 8388608,
    32 => data.getInt32(offset, Endian.little) / 2147483648,
    _ => 0,
  };
}

int _readInt24(ByteData data, int offset) {
  final value =
      data.getUint8(offset) |
      (data.getUint8(offset + 1) << 8) |
      (data.getUint8(offset + 2) << 16);
  return value & 0x800000 == 0 ? value : value | ~0xffffff;
}

Uint8List _normalizeThumbnail(Uint8List bytes, int targetWidth) {
  final decoded = image.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Poster vidéo illisible.');
  }
  final width = targetWidth.clamp(96, 512);
  final resized = decoded.width <= width
      ? decoded
      : image.copyResize(decoded, width: width);
  return Uint8List.fromList(image.encodePng(resized, level: 6));
}

List<PresentationTimelineCaptionSegment> _decodeWebVtt(Uint8List bytes) =>
    List<PresentationTimelineCaptionSegment>.unmodifiable([
      for (final segment in decodePresentationCaptionWebVtt(bytes))
        PresentationTimelineCaptionSegment(
          startUs: segment.startUs,
          endUs: segment.endUs,
          text: segment.text,
        ),
    ]);
