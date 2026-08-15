import 'dart:convert';
import 'dart:io';

import '../../application/models/narrative_document_route.dart';

final class FileNarrativeDocumentRouteStore
    implements NarrativeDocumentRouteStore {
  FileNarrativeDocumentRouteStore({
    required String filePath,
    NarrativeDocumentRouteCodec codec = const NarrativeDocumentRouteCodec(),
  }) : _file = File(_requiredPath(filePath)),
       _codec = codec;

  final File _file;
  final NarrativeDocumentRouteCodec _codec;

  @override
  Future<NarrativeDocumentRoute?> read() async {
    if (!await _file.exists()) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(await _file.readAsString());
    } on Object catch (error) {
      throw FormatException('Narrative route store cannot be decoded: $error');
    }
    if (decoded is! Map) {
      throw const FormatException('Narrative route store must be an object.');
    }
    final json = <String, Object?>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        throw const FormatException(
          'Narrative route store contains a non-string key.',
        );
      }
      json[entry.key as String] = entry.value;
    }
    final unknown = json.keys.toSet().difference(const {
      'schemaVersion',
      'route',
    });
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Narrative route store contains an unknown key: ${unknown.first}.',
      );
    }
    if (json['schemaVersion'] != 1) {
      throw FormatException(
        'Unsupported Narrative route schema: ${json['schemaVersion']}.',
      );
    }
    final route = json['route'];
    if (route is! String || route.trim().isEmpty) {
      throw const FormatException('Narrative route must be a non-empty URI.');
    }
    return _codec.decode(Uri.parse(route));
  }

  @override
  Future<void> write(NarrativeDocumentRoute route) async {
    final temporary = File('${_file.path}.tmp');
    await _file.parent.create(recursive: true);
    final bytes = utf8.encode(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'route': _codec.encode(route).toString(),
      }),
    );
    final handle = await temporary.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }
    try {
      final verified = jsonDecode(await temporary.readAsString());
      if (verified is! Map || verified['route'] is! String) {
        throw const FormatException(
          'Narrative route store verification failed.',
        );
      }
      _codec.decode(Uri.parse(verified['route'] as String));
      await temporary.rename(_file.path);
    } on Object {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    if (await _file.exists()) await _file.delete();
    final temporary = File('${_file.path}.tmp');
    if (await temporary.exists()) await temporary.delete();
  }
}

String _requiredPath(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'filePath', 'must not be empty');
  }
  return normalized;
}
