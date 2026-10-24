import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum ConverterUpdateStatus { available, current, unpublished }

final class ConverterInstalledBuild {
  const ConverterInstalledBuild({
    required this.version,
    required this.buildNumber,
    this.bundleId = ConverterUpdateCatalog.bundleId,
  });

  final String version;
  final int buildNumber;
  final String bundleId;
}

final class ConverterUpdateRelease {
  const ConverterUpdateRelease({
    required this.version,
    required this.buildNumber,
    required this.revision,
    required this.notesUri,
  });

  final String version;
  final int buildNumber;
  final String revision;
  final Uri notesUri;
}

final class ConverterUpdateCheck {
  const ConverterUpdateCheck(this.status, {this.release});

  final ConverterUpdateStatus status;
  final ConverterUpdateRelease? release;
}

final class ConverterUpdateCatalog {
  ConverterUpdateCatalog(
    this._client, {
    this.timeout = const Duration(seconds: 10),
  });

  static const bundleId = 'com.yoahnl.avelune.converter';
  static final indexUri = Uri.parse(
    'https://github.com/yoahnl/pokemap/releases/download/'
    'avelune-converter-update-stable/avelune-converter-update-index.json',
  );
  static const maxResponseBytes = 65536;

  final http.Client _client;
  final Duration timeout;

  Future<ConverterUpdateCheck> check(ConverterInstalledBuild installed) async {
    final installedVersion = _ConverterVersion.parse(installed.version);
    if (installedVersion == null ||
        installed.buildNumber <= 0 ||
        installed.bundleId != bundleId) {
      throw const FormatException('Installed Converter build is invalid.');
    }
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      indexUri,
      abortTrigger: abort.future,
    )..maxRedirects = 5;
    try {
      return await _read(request, installed, installedVersion).timeout(timeout);
    } finally {
      if (!abort.isCompleted) abort.complete();
    }
  }

  Future<ConverterUpdateCheck> _read(
    http.BaseRequest request,
    ConverterInstalledBuild installed,
    _ConverterVersion installedVersion,
  ) async {
    final response = await _client.send(request);
    if (response.statusCode == 404) {
      await response.stream.listen(null).cancel();
      return const ConverterUpdateCheck(ConverterUpdateStatus.unpublished);
    }
    if (response.statusCode != 200 ||
        (response.contentLength ?? 0) > maxResponseBytes) {
      await response.stream.listen(null).cancel();
      throw const FormatException('Converter update index is unavailable.');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxResponseBytes) {
        throw const FormatException('Converter update index is too large.');
      }
      bytes.addAll(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['product'] != 'avelune-converter' ||
        decoded['bundleId'] != bundleId ||
        decoded['channel'] != 'stable') {
      throw const FormatException(
        'Converter update index identity is invalid.',
      );
    }
    final version = decoded['version'];
    final build = decoded['buildNumber'];
    final revision = decoded['revision'];
    final tag = decoded['tag'];
    final notes = decoded['releaseNotesUrl'];
    if (version is! String ||
        build is! int ||
        build <= 0 ||
        build > 2147483647 ||
        revision is! String ||
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(revision)) {
      throw const FormatException('Converter release provenance is invalid.');
    }
    final available = _ConverterVersion.parse(version);
    final expectedTag = 'avelune-converter-v$version';
    final expectedNotes =
        'https://github.com/yoahnl/pokemap/releases/tag/$expectedTag';
    if (available == null ||
        available.prerelease ||
        version.contains('+') ||
        tag != expectedTag ||
        notes != expectedNotes) {
      throw const FormatException(
        'Converter release URL or version is untrusted.',
      );
    }
    final comparison = available.compareTo(installedVersion);
    if (comparison < 0 || comparison == 0 && build <= installed.buildNumber) {
      return const ConverterUpdateCheck(ConverterUpdateStatus.current);
    }
    return ConverterUpdateCheck(
      ConverterUpdateStatus.available,
      release: ConverterUpdateRelease(
        version: version,
        buildNumber: build,
        revision: revision,
        notesUri: Uri.parse(expectedNotes),
      ),
    );
  }
}

final class _ConverterVersion {
  _ConverterVersion(this.parts, this.prerelease);

  final List<int> parts;
  final bool prerelease;

  static _ConverterVersion? parse(String value) {
    if (value.length > 128) return null;
    final match = RegExp(
      r'^(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})\.(0|[1-9][0-9]{0,8})'
      r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
      r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
    ).firstMatch(value);
    if (match == null) return null;
    final pre = match[4];
    if (pre != null &&
        pre
            .split('.')
            .any(
              (part) =>
                  RegExp(r'^[0-9]+$').hasMatch(part) &&
                  part.length > 1 &&
                  part.startsWith('0'),
            )) {
      return null;
    }
    return _ConverterVersion([
      for (var i = 1; i <= 3; i++) int.parse(match[i]!),
    ], pre != null);
  }

  int compareTo(_ConverterVersion other) {
    for (var i = 0; i < parts.length; i++) {
      final comparison = parts[i].compareTo(other.parts[i]);
      if (comparison != 0) return comparison;
    }
    if (prerelease == other.prerelease) return 0;
    return prerelease ? -1 : 1;
  }
}
