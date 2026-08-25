import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

/// Gives a content-addressed media blob a name a media framework recognises.
///
/// The media store is content-addressed: every file lands at `<digest>.blob`.
/// AVFoundation picks its demuxer from the path extension, so it refuses those
/// files outright — the audio player can be told the type out of band, the
/// video player cannot, and neither should have to be.
///
/// One immutable link per digest and container, named from what the catalog
/// declares, makes both work from an ordinary path. The store is
/// content-addressed, so an alias never goes stale and two media that share a
/// digest share a link. Nothing here is required: a media that declares no
/// container, or a root that cannot be written, resolves to the blob it came
/// from and the platform is left to its own sniffing.
final class PresentationMediaAliasStore {
  PresentationMediaAliasStore({required this.root});

  /// Where the links live. A directory the process may write — a cache, not a
  /// part of the project: nothing here is authored, and losing it costs one
  /// symlink call.
  final Directory root;

  final Map<String, Uri> _aliases = <String, Uri>{};
  final Set<String> _refused = <String>{};

  /// The path [media] should be played from, aliasing [blob] when it helps.
  Future<Uri> resolve(ProjectMediaAsset media, Uri blob) async {
    if (blob.scheme != 'file') return blob;
    final extension = _extensionFor(media);
    if (extension == null) return blob;
    final path = blob.toFilePath();
    if (p.extension(path).toLowerCase() == '.$extension') return blob;

    final key = '${p.basenameWithoutExtension(path)}.$extension';
    final cached = _aliases[key];
    if (cached != null) return cached;
    if (_refused.contains(key)) return blob;

    try {
      final alias = File(p.join(root.path, key));
      if (!await alias.exists()) {
        await root.create(recursive: true);
        await Link(alias.path).create(path, recursive: true);
      }
      final uri = Uri.file(alias.path);
      _aliases[key] = uri;
      return uri;
    } on Object {
      // A cache that cannot be written must never cost playback: the blob is
      // still a perfectly good path, just one the platform has to sniff.
      _refused.add(key);
      return blob;
    }
  }

  /// The extension the catalog implies, or null when it declares nothing.
  ///
  /// The container is a validated technical token whenever the metadata
  /// exists, so it needs no second guess — a media with no metadata at all is
  /// the only case left to the platform.
  static String? _extensionFor(ProjectMediaAsset media) =>
      media.technicalMetadata?.container.toLowerCase();
}
