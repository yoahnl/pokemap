import 'dart:convert';

import 'package:http/http.dart' as http;

final class StudioUpdateRelease {
  const StudioUpdateRelease({required this.version, required this.notesUri});

  final String version;
  final Uri notesUri;
}

final class StudioUpdateCatalog {
  StudioUpdateCatalog(this._client);

  static final Uri indexUri = Uri.parse(
    'https://github.com/yoahnl/pokemap/releases/download/'
    'pokemap-editor-update-stable/pokemap-update-index.json',
  );

  final http.Client _client;

  Future<StudioUpdateRelease?> newerThan(String installedVersion) async {
    final installed = _parseVersion(installedVersion);
    if (installed == null) return null;

    final response = await _client
        .get(indexUri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 || response.bodyBytes.length > 65536) {
      throw const FormatException('Stable update index is unavailable.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['channel'] != 'stable') {
      throw const FormatException('Stable update index is invalid.');
    }

    final version = decoded['version'];
    final tag = decoded['tag'];
    final notes = decoded['releaseNotesUrl'];
    if (version is! String || tag is! String || notes is! String) {
      throw const FormatException('Stable update index is incomplete.');
    }
    final available = _parseVersion(version);
    final expectedTag = 'pokemap-v$version';
    final expectedNotes =
        'https://github.com/yoahnl/pokemap/releases/tag/$expectedTag';
    if (available == null || tag != expectedTag || notes != expectedNotes) {
      throw const FormatException('Stable update index is untrusted.');
    }
    for (var index = 0; index < available.length; index++) {
      if (available[index] > installed[index]) {
        return StudioUpdateRelease(
          version: version,
          notesUri: Uri.parse(expectedNotes),
        );
      }
      if (available[index] < installed[index]) return null;
    }
    return null;
  }

  List<int>? _parseVersion(String value) {
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value)) return null;
    return value.split('.').map(int.parse).toList(growable: false);
  }
}
