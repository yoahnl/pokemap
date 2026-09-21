import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:path/path.dart' as path;

class PresentationContentStore implements PresentationFrameContentPort {
  PresentationContentStore({
    required this.projectRoot,
    required this.catalog,
    required this.mediaUris,
    this.stagedBytes = const {},
  });
  final String projectRoot;
  final ProjectMediaCatalog catalog;
  final Map<String, Uri> mediaUris;
  final Map<String, List<int>> stagedBytes;
  final Map<String, Uint8List> _bytes = {};
  final Map<String, String> failures = {};
  final Map<String, List<PresentationCaptionSegment>> _captions = {};
  final Map<String, Future<void>> _pending = {};
  PresentationStudioMediaSink? sink;
  int reads = 0;
  Set<String> _activeIds = {};
  String? get currentDiagnostic {
    for (final id in _activeIds) {
      if (failures[id] case final error?) return error;
      if (catalog.find(id)?.kind == ProjectMediaKind.video &&
          _bytes.containsKey(id) &&
          sink?.videoFor(id) == null) {
        return 'Aperçu fixe : ${catalog.find(id)!.label}';
      }
    }
    return null;
  }

  bool get currentDiagnosticIsFailure {
    for (final id in _activeIds) {
      if (failures.containsKey(id)) return true;
      if (catalog.find(id)?.kind == ProjectMediaKind.video &&
          _bytes.containsKey(id) &&
          sink?.videoFor(id) == null) {
        return false;
      }
    }
    return false;
  }

  Future<void> prepare(
    PresentationCinematicAsset asset, {
    required bool portrait,
  }) async {
    final ids = <String>{};
    for (final track in asset.tracks) {
      for (final clip in track.clips) {
        if (clip is PresentationVisualClip) {
          ids.add(
            (portrait ? clip.portraitResourceId : clip.landscapeResourceId) ??
                clip.resourceId,
          );
        } else if (clip is PresentationCaptionClip) {
          ids.add(clip.captionId);
        }
      }
    }
    _activeIds = ids;
    await Future.wait(
      ids.map((id) => _pending.putIfAbsent(id, () => _read(id, {}))),
    );
  }

  Future<void> _read(String id, Set<String> ancestors) async {
    if (_bytes.containsKey(id) || _captions.containsKey(id)) return;
    if (!ancestors.add(id)) {
      failures[id] = 'Référence média cyclique : $id';
      return;
    }
    final media = catalog.find(id);
    if (media == null) {
      failures[id] = 'Média introuvable : $id';
      return;
    }
    if (media.kind == ProjectMediaKind.video) {
      final poster = media.posterMediaId;
      if (poster != null) {
        await _read(poster, ancestors);
        if (_bytes[poster] case final bytes?) _bytes[id] = bytes;
      }
      return;
    }
    try {
      final staged = stagedBytes[id];
      if (staged != null) {
        final bytes = Uint8List.fromList(staged);
        if (media.kind == ProjectMediaKind.captions) {
          _captions[id] = decodePresentationCaptionWebVtt(bytes);
        } else {
          _bytes[id] = bytes;
        }
        return;
      }
      final uri = mediaUris[id];
      if (uri == null || uri.scheme != 'file') {
        throw StateError('Source absente');
      }
      final root = await Directory(projectRoot).resolveSymbolicLinks();
      final resolved = await File.fromUri(uri).resolveSymbolicLinks();
      if (!path.isWithin(root, resolved)) {
        throw StateError('Source hors projet');
      }
      reads++;
      final bytes = await File(resolved).readAsBytes();
      if (media.kind == ProjectMediaKind.captions) {
        _captions[id] = decodePresentationCaptionWebVtt(bytes);
      } else {
        _bytes[id] = bytes;
      }
    } on Object catch (error) {
      final fallback = media.fallbackMediaId;
      if (fallback != null && catalog.find(fallback)?.kind == media.kind) {
        await _read(fallback, ancestors);
        if (_bytes[fallback] case final bytes?) _bytes[id] = bytes;
        if (_captions[fallback] case final captions?) _captions[id] = captions;
      }
      if (!_bytes.containsKey(id) && !_captions.containsKey(id)) {
        failures[id] = 'Média illisible : ${media.label} ($error)';
      }
    }
  }

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    final live = sink?.videoFor(clip.resourceId);
    if (live != null) return PresentationVisualReady(child: live);
    final bytes = _bytes[clip.resourceId];
    if (bytes == null) {
      return PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message:
            failures[clip.resourceId] ??
            'Aperçu indisponible : ${clip.resourceId}',
      );
    }
    return PresentationVisualReady(
      child: Image.memory(
        bytes,
        fit: BoxFit.cover,
        key: ValueKey('presentation-media-${clip.resourceId}'),
        errorBuilder: (_, error, _) =>
            Center(child: Text('Image illisible : $error')),
      ),
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) {
    final segments = _captions[clip.captionId];
    if (segments == null) {
      return PresentationCaptionUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message:
            failures[clip.captionId] ?? 'Sous-titres en cours de chargement',
      );
    }
    return PresentationCaptionReady(
      text:
          activePresentationCaptionSegment(
            segments,
            elapsedUs: clip.elapsedUs,
          )?.text ??
          '',
    );
  }
}
