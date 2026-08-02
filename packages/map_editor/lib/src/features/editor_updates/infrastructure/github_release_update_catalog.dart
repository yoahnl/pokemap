import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

import '../domain/editor_update_catalog.dart';
import '../domain/editor_update_models.dart';

final class GithubReleaseUpdateCatalog implements EditorUpdateCatalog {
  GithubReleaseUpdateCatalog({
    required http.Client client,
    required Uri indexUri,
    this.requestTimeout = const Duration(seconds: 5),
    this.maxResponseBytes = 64 * 1024,
  })  : _client = client,
        _indexUri = indexUri;

  final http.Client _client;
  final Uri _indexUri;
  final Duration requestTimeout;
  final int maxResponseBytes;

  @override
  Future<EditorUpdateRelease?> latestStable(Version currentVersion) async {
    final http.Response response;
    try {
      response = await _client.get(_indexUri).timeout(requestTimeout);
    } on TimeoutException {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.timeout,
        'The update check timed out.',
      );
    } on http.ClientException {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.network,
        'The update index could not be reached.',
      );
    }

    final finalUri = response.request?.url;
    if (finalUri != null && !_isTrustedIndexUri(finalUri)) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.untrustedUrl,
        'The update index was redirected to an untrusted host.',
      );
    }

    if (response.statusCode != 200) {
      throw EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.httpStatus,
        'The update index returned HTTP ${response.statusCode}.',
      );
    }
    if (response.bodyBytes.length > maxResponseBytes) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.responseTooLarge,
        'The update index is larger than the accepted limit.',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidJson,
        'The update index is not valid JSON.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidJson,
        'The update index must be a JSON object.',
      );
    }

    if (decoded['schemaVersion'] != 1) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidSchema,
        'The update index schema is not supported.',
      );
    }
    if (decoded['channel'] != 'stable') {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidChannel,
        'Only the stable update channel is supported.',
      );
    }

    final versionText = decoded['version'];
    final Version version;
    if (versionText is! String) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidVersion,
        'The update version is missing or invalid.',
      );
    }
    try {
      version = Version.parse(versionText);
    } on FormatException {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidVersion,
        'The update version is missing or invalid.',
      );
    }
    if (version.isPreRelease) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidVersion,
        'Prerelease versions are not accepted on the stable channel.',
      );
    }
    if (version.compareTo(currentVersion) <= 0) {
      return null;
    }

    final tag = decoded['tag'];
    if (tag is! String || tag != 'pokemap-v$version') {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidTag,
        'The release tag does not match the advertised version.',
      );
    }

    final publishedAtText = decoded['publishedAt'];
    final publishedAt =
        publishedAtText is String ? DateTime.tryParse(publishedAtText) : null;
    if (publishedAt == null || !publishedAt.isUtc) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.invalidDate,
        'The release publication date is missing or invalid.',
      );
    }

    final releaseNotesText = decoded['releaseNotesUrl'];
    final releaseNotesUri =
        releaseNotesText is String ? Uri.tryParse(releaseNotesText) : null;
    if (!_isTrustedReleaseNotesUri(releaseNotesUri, tag)) {
      throw const EditorUpdateCatalogException(
        EditorUpdateCatalogFailureCode.untrustedUrl,
        'The release notes URL is not trusted.',
      );
    }

    return EditorUpdateRelease(
      version: version,
      tag: tag,
      publishedAt: publishedAt,
      releaseNotesUri: releaseNotesUri!,
    );
  }

  bool _isTrustedReleaseNotesUri(Uri? uri, String tag) {
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'github.com' &&
        uri.port == 443 &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty &&
        uri.path == '/yoahnl/pokemap/releases/tag/$tag';
  }

  bool _isTrustedIndexUri(Uri uri) {
    const trustedHosts = {
      'github.com',
      'release-assets.githubusercontent.com',
      'objects.githubusercontent.com',
    };
    return uri.scheme == 'https' && trustedHosts.contains(uri.host);
  }
}
