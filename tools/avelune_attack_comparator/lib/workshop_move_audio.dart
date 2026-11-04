import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

final class WorkshopMoveAudio {
  WorkshopMoveAudio({Uri? origin})
    : _origin = origin ?? Uri.https('pokemon-api.yoahn.me');

  static const _release = 'public-2026-11-02-bw2';
  static const _maxMetadataBytes = 256 * 1024;
  static const _maxAudioBytes = 8 * 1024 * 1024;
  static const _timeout = Duration(seconds: 3);
  static final _idPattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$');

  final Uri _origin;

  Future<Uint8List?> load(String moveId, {String? sourceVariant}) async {
    if (!_idPattern.hasMatch(moveId)) return null;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      return await (() async {
        final listing = await _get(
          client,
          '/v1/media/$_release/owners/move/$moveId',
          _maxMetadataBytes,
        );
        if (listing == null) return null;
        final raw = jsonDecode(utf8.decode(listing));
        if (raw is! List) return null;
        final candidates = raw.whereType<Map>().where((entry) {
          final metadata = entry['metadata'];
          final provenance = metadata is Map ? metadata['provenance'] : null;
          return entry['usage'] == 'battle' &&
              entry['representation'] == 'audio' &&
              entry['style'] == 'gen5-local-clip' &&
              entry['contentType'] == 'audio/mpeg' &&
              provenance is Map;
        }).toList();
        final generic = candidates.where((entry) {
          final provenance = (entry['metadata'] as Map)['provenance'] as Map;
          return provenance['kind'] == 'move-clip' ||
              (provenance['kind'] == null && provenance['source'] == 'user-upload');
        }).toList();
        if (generic.length > 1) return null;
        final variants = candidates.where((entry) {
          final metadata = entry['metadata'] as Map;
          final provenance = metadata['provenance'] as Map;
          if (provenance['kind'] != 'move-variant') return false;
          final label = metadata['label'];
          if (label is! String) return false;
          if (moveId == 'present') {
            final expected = switch (sourceVariant) {
              null || 'Present' => 'Present damage.mp3',
              'Present_Variant1' => 'Present heal.mp3',
              _ => null,
            };
            return expected != null && label == expected;
          }
          return label.toLowerCase().endsWith(' 1hit.mp3');
        }).toList();
        if (generic.isEmpty && variants.length != 1) return null;
        final media = generic.isNotEmpty ? generic.single : variants.single;
        final id = media['id'];
        final hash = media['sha256'];
        if (id is! String || !_idPattern.hasMatch(id) || hash is! String) {
          return null;
        }
        final bytes = await _get(
          client,
          '/v1/media/$_release/$id',
          _maxAudioBytes,
        );
        if (bytes == null || bytes.isEmpty) return null;
        final metadata = media['metadata'] as Map;
        final provenance = metadata['provenance'] as Map;
        final file = provenance['file'];
        final declaredSize = file is Map ? file['size'] : null;
        if (declaredSize != null && declaredSize != bytes.length) return null;
        final reference = BattleMoveAnimationResource.fromJson({
          'id': id,
          'role': 'sound',
          'mediaType': 'audio/mpeg',
          'sizeBytes': bytes.length,
          'sha256': hash,
        });
        return reference.matches(bytes) ? bytes : null;
      })().timeout(const Duration(seconds: 8));
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<Uint8List?> _get(HttpClient client, String path, int maxBytes) async {
    final request = await client
        .getUrl(_origin.resolve(path))
        .timeout(_timeout);
    request.followRedirects = false;
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok ||
        response.contentLength > maxBytes) {
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(_timeout)) {
      if (bytes.length + chunk.length > maxBytes) return null;
      bytes.add(chunk);
    }
    return bytes.takeBytes();
  }
}
