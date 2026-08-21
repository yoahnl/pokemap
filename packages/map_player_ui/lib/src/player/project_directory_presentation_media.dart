import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

/// Presentation media resolved from an authored project directory.
///
/// Two surfaces read a project directory rather than an installed package: the
/// standalone host and the Studio preview. They share this façade so a third
/// resolver cannot drift from the certified one — the catalog format, the digest
/// convention and the fail-closed rules are the same everywhere.
final class ProjectDirectoryPresentationMedia {
  const ProjectDirectoryPresentationMedia({
    required this.catalog,
    required this.mediaUris,
  });

  final ProjectMediaCatalog catalog;
  final Map<String, Uri> mediaUris;
}

final class ProjectDirectoryPresentationMediaException implements Exception {
  const ProjectDirectoryPresentationMediaException(
    this.message, {
    this.mediaId,
  });

  final String message;
  final String? mediaId;

  @override
  String toString() => 'ProjectDirectoryPresentationMediaException: $message'
      '${mediaId == null ? '' : ' ($mediaId)'}';
}

final _digestPattern = RegExp(r'^sha256:([a-f0-9]{64})$');

/// Loads the Presentation media of a project directory, or null when the
/// project simply has no media catalog — a project without cinematics stays
/// perfectly playable, and previewable.
Future<ProjectDirectoryPresentationMedia?>
    loadProjectDirectoryPresentationMedia({
  required String projectRootDirectory,
}) async {
  final mediaFile = File(
    p.join(projectRootDirectory, 'assets', '.pokemap-media.json'),
  );
  if (!await mediaFile.exists()) return null;

  final catalog = ProjectMediaCatalog.fromJson(
    await _readObject(mediaFile, 'the media catalog'),
  );
  if (catalog.entries.isEmpty) {
    return ProjectDirectoryPresentationMedia(
      catalog: catalog,
      mediaUris: const <String, Uri>{},
    );
  }

  final assetFile = File(
    p.join(projectRootDirectory, 'assets', '.pokemap-assets.json'),
  );
  if (!await assetFile.exists()) {
    throw const ProjectDirectoryPresentationMediaException(
      'The project declares media but carries no asset catalog.',
    );
  }
  final assetCatalog = await _readObject(assetFile, 'the asset catalog');
  final records = assetCatalog['records'];
  if (assetCatalog['schemaVersion'] != 1 || records is! List<Object?>) {
    throw const ProjectDirectoryPresentationMediaException(
      'The project asset catalog is invalid.',
    );
  }
  final digestsByAssetId = <String, String>{};
  for (final raw in records) {
    if (raw is! Map) {
      throw const ProjectDirectoryPresentationMediaException(
        'The project asset catalog is invalid.',
      );
    }
    final record = Map<String, Object?>.from(raw);
    final artifact = record['artifact'];
    if (record['id'] is! String || artifact is! Map) {
      throw const ProjectDirectoryPresentationMediaException(
        'The project asset catalog is invalid.',
      );
    }
    final digest = Map<String, Object?>.from(artifact)['digest'];
    final match = digest is String ? _digestPattern.firstMatch(digest) : null;
    if (match == null) {
      throw const ProjectDirectoryPresentationMediaException(
        'The project asset catalog is invalid.',
      );
    }
    digestsByAssetId[record['id']! as String] = match.group(1)!;
  }

  final mediaUris = <String, Uri>{};
  for (final media in catalog.entries) {
    final digest = digestsByAssetId[media.sourceAssetId];
    if (digest == null) {
      throw ProjectDirectoryPresentationMediaException(
        'A Presentation media asset is missing from the project.',
        mediaId: media.id,
      );
    }
    final blob = File(
      p.join(projectRootDirectory, 'assets', '.pokemap-store', digest),
    );
    if (!await blob.exists()) {
      throw ProjectDirectoryPresentationMediaException(
        'A Presentation media blob is missing from the project store.',
        mediaId: media.id,
      );
    }
    mediaUris[media.id] = blob.uri;
  }
  return ProjectDirectoryPresentationMedia(
    catalog: catalog,
    mediaUris: Map<String, Uri>.unmodifiable(mediaUris),
  );
}

Future<Map<String, Object?>> _readObject(File file, String what) async {
  final Object? decoded;
  try {
    decoded = jsonDecode(await file.readAsString());
  } on Object {
    throw ProjectDirectoryPresentationMediaException(
      '$what could not be read.',
    );
  }
  if (decoded is! Map) {
    throw ProjectDirectoryPresentationMediaException('$what must be an object.');
  }
  return Map<String, Object?>.from(decoded);
}
