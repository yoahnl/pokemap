import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

String presentationPresetFileSha256(List<int> bytes) =>
    sha256.convert(bytes).toString();

final class PresentationPresetPackException implements Exception {
  const PresentationPresetPackException({
    required this.code,
    required this.path,
    required this.message,
  });

  final String code;
  final String path;
  final String message;

  @override
  String toString() =>
      'PresentationPresetPackException($code, $path): $message';
}

final class PresentationPresetCompatibility {
  const PresentationPresetCompatibility({
    required this.minimumProfileSchemaVersion,
    required this.maximumProfileSchemaVersion,
  });

  factory PresentationPresetCompatibility.fromJson(
    Map<String, dynamic> json,
  ) {
    _requireKeys(
      json,
      const <String>{
        'minimumProfileSchemaVersion',
        'maximumProfileSchemaVersion',
      },
      r'$.compatibility',
    );
    return PresentationPresetCompatibility(
      minimumProfileSchemaVersion: _integer(
        json['minimumProfileSchemaVersion'],
        r'$.compatibility.minimumProfileSchemaVersion',
      ),
      maximumProfileSchemaVersion: _integer(
        json['maximumProfileSchemaVersion'],
        r'$.compatibility.maximumProfileSchemaVersion',
      ),
    );
  }

  final int minimumProfileSchemaVersion;
  final int maximumProfileSchemaVersion;

  bool supports(int schemaVersion) =>
      schemaVersion >= minimumProfileSchemaVersion &&
      schemaVersion <= maximumProfileSchemaVersion;

  Map<String, Object?> toJson() => <String, Object?>{
        'minimumProfileSchemaVersion': minimumProfileSchemaVersion,
        'maximumProfileSchemaVersion': maximumProfileSchemaVersion,
      };
}

final class PresentationPresetAsset {
  PresentationPresetAsset({
    required this.projectPath,
    required this.archivePath,
    required this.mediaType,
    required this.sizeBytes,
    required this.sha256,
    this.licenseProjectPath,
    this.licenseArchivePath,
    this.licenseSizeBytes,
    this.licenseSha256,
  }) {
    _validateProjectPath(projectPath, r'$.assets[].projectPath');
    _validateArchivePath(archivePath, r'$.assets[].archivePath', 'assets');
    if (!_mediaTypePattern.hasMatch(mediaType)) {
      _fail(
        'presetPackMediaTypeInvalid',
        r'$.assets[].mediaType',
        'Asset MIME types must use a normalized type/subtype value.',
      );
    }
    if (sizeBytes < 1 || sizeBytes > presentationPresetMaxAssetBytes) {
      _fail(
        'presetPackAssetTooLarge',
        r'$.assets[].sizeBytes',
        'Preset assets exceed the supported size.',
      );
    }
    if (!_sha256Pattern.hasMatch(sha256)) {
      _fail(
        'presetPackChecksumInvalid',
        r'$.assets[].sha256',
        'Preset asset checksums must be lowercase SHA-256.',
      );
    }
    if (licenseProjectPath == null ||
        licenseArchivePath == null ||
        licenseSizeBytes == null ||
        licenseSha256 == null) {
      _fail(
        'presetPackLicenseRequired',
        r'$.assets[]',
        'Every redistributed preset asset requires a license.',
      );
    }
    _validateProjectPath(
      licenseProjectPath!,
      r'$.assets[].licenseProjectPath',
    );
    _validateArchivePath(
      licenseArchivePath!,
      r'$.assets[].licenseArchivePath',
      'licenses',
    );
    if (licenseSizeBytes! < 1 ||
        licenseSizeBytes! > presentationPresetMaxAssetBytes) {
      _fail(
        'presetPackLicenseInvalid',
        r'$.assets[].licenseSizeBytes',
        'Preset license sizes are invalid.',
      );
    }
    if (!_sha256Pattern.hasMatch(licenseSha256!)) {
      _fail(
        'presetPackChecksumInvalid',
        r'$.assets[].licenseSha256',
        'Preset license checksums must be lowercase SHA-256.',
      );
    }
  }

  factory PresentationPresetAsset.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      const <String>{
        'projectPath',
        'archivePath',
        'mediaType',
        'sizeBytes',
        'sha256',
        'licenseProjectPath',
        'licenseArchivePath',
        'licenseSizeBytes',
        'licenseSha256',
      },
      r'$.assets[]',
    );
    return PresentationPresetAsset(
      projectPath: _string(json['projectPath'], r'$.assets[].projectPath'),
      archivePath: _string(json['archivePath'], r'$.assets[].archivePath'),
      mediaType: _string(json['mediaType'], r'$.assets[].mediaType'),
      sizeBytes: _integer(json['sizeBytes'], r'$.assets[].sizeBytes'),
      sha256: _string(json['sha256'], r'$.assets[].sha256'),
      licenseProjectPath: _optionalString(
        json['licenseProjectPath'],
        r'$.assets[].licenseProjectPath',
      ),
      licenseArchivePath: _optionalString(
        json['licenseArchivePath'],
        r'$.assets[].licenseArchivePath',
      ),
      licenseSizeBytes: json['licenseSizeBytes'] == null
          ? null
          : _integer(
              json['licenseSizeBytes'],
              r'$.assets[].licenseSizeBytes',
            ),
      licenseSha256: _optionalString(
        json['licenseSha256'],
        r'$.assets[].licenseSha256',
      ),
    );
  }

  final String projectPath;
  final String archivePath;
  final String mediaType;
  final int sizeBytes;
  final String sha256;
  final String? licenseProjectPath;
  final String? licenseArchivePath;
  final int? licenseSizeBytes;
  final String? licenseSha256;

  Map<String, Object?> toJson() => <String, Object?>{
        'projectPath': projectPath,
        'archivePath': archivePath,
        'mediaType': mediaType,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'licenseProjectPath': licenseProjectPath,
        'licenseArchivePath': licenseArchivePath,
        'licenseSizeBytes': licenseSizeBytes,
        'licenseSha256': licenseSha256,
      };
}

final class PresentationPresetPackManifest {
  PresentationPresetPackManifest({
    this.formatVersion = 1,
    required this.id,
    required this.label,
    required this.description,
    required this.compatibility,
    Iterable<PresentationPresetAsset> assets = const [],
  }) : assets = _orderedAssets(assets) {
    if (formatVersion != 1) {
      _fail(
        'presetPackVersionUnsupported',
        r'$.formatVersion',
        'This preset pack version is not supported.',
      );
    }
    if (!_idPattern.hasMatch(id)) {
      _fail(
        'presetPackIdInvalid',
        r'$.id',
        'Preset IDs must use lowercase letters, numbers, and dashes.',
      );
    }
    _boundedText(label, r'$.label', 64);
    _boundedText(description, r'$.description', 240);
    if (compatibility.minimumProfileSchemaVersion < 1 ||
        compatibility.maximumProfileSchemaVersion <
            compatibility.minimumProfileSchemaVersion) {
      _fail(
        'presetPackCompatibilityInvalid',
        r'$.compatibility',
        'Preset compatibility bounds are invalid.',
      );
    }
  }

  factory PresentationPresetPackManifest.fromJson(Map<String, dynamic> json) {
    _requireKeys(
      json,
      const <String>{
        'formatVersion',
        'id',
        'label',
        'description',
        'compatibility',
        'assets',
      },
      r'$',
    );
    final compatibility = json['compatibility'];
    final assets = json['assets'];
    if (compatibility is! Map || assets is! List) {
      _fail(
        'presetPackManifestInvalid',
        r'$',
        'Preset manifest compatibility and assets are required.',
      );
    }
    return PresentationPresetPackManifest(
      formatVersion: _integer(json['formatVersion'], r'$.formatVersion'),
      id: _string(json['id'], r'$.id'),
      label: _string(json['label'], r'$.label'),
      description: _string(json['description'], r'$.description'),
      compatibility: PresentationPresetCompatibility.fromJson(
        Map<String, dynamic>.from(compatibility),
      ),
      assets: assets.map((raw) {
        if (raw is! Map) {
          _fail(
            'presetPackManifestInvalid',
            r'$.assets[]',
            'Preset assets must be objects.',
          );
        }
        return PresentationPresetAsset.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }),
    );
  }

  final int formatVersion;
  final String id;
  final String label;
  final String description;
  final PresentationPresetCompatibility compatibility;
  final List<PresentationPresetAsset> assets;

  Map<String, Object?> toJson() => <String, Object?>{
        'formatVersion': formatVersion,
        'id': id,
        'label': label,
        'description': description,
        'compatibility': compatibility.toJson(),
        'assets': <Object?>[for (final asset in assets) asset.toJson()],
      };
}

final class ProjectPresentationPresetPack {
  ProjectPresentationPresetPack({
    required this.manifest,
    required this.profile,
    Map<String, Uint8List> files = const <String, Uint8List>{},
  }) : files = _validatePackFiles(manifest, profile, files);

  final PresentationPresetPackManifest manifest;
  final ProjectPresentationProfile profile;
  final Map<String, Uint8List> files;
}

const int presentationPresetMaxArchiveBytes = 256 * 1024 * 1024;
const int presentationPresetMaxAssetBytes = 100 * 1024 * 1024;
const int presentationPresetMaxFiles = 128;

Map<String, Uint8List> _validatePackFiles(
  PresentationPresetPackManifest manifest,
  ProjectPresentationProfile profile,
  Map<String, Uint8List> files,
) {
  if (!manifest.compatibility.supports(profile.schemaVersion) ||
      !manifest.compatibility.supports(
        ProjectPresentationProfile.supportedSchemaVersion,
      )) {
    _fail(
      'presetPackProfileIncompatible',
      r'$.compatibility',
      'The preset profile is incompatible with this PokeMap version.',
    );
  }
  final diagnostics = validateProjectPresentationProfile(profile).where(
    (diagnostic) =>
        diagnostic.severity == ProjectPresentationDiagnosticSeverity.error,
  );
  if (diagnostics.isNotEmpty) {
    _fail(
      'presetPackProfileInvalid',
      diagnostics.first.path,
      diagnostics.first.message,
    );
  }
  if (files.length > presentationPresetMaxFiles) {
    _fail(
      'presetPackEntryCountExceeded',
      r'$',
      'Preset packs contain too many files.',
    );
  }
  final expected = <String>{};
  final projectPaths = <String>{};
  var totalBytes = 0;
  for (final asset in manifest.assets) {
    if (!projectPaths.add(asset.projectPath)) {
      _fail(
        'presetPackProjectPathDuplicate',
        asset.projectPath,
        'Preset asset destinations must be unique.',
      );
    }
    expected
      ..add(asset.archivePath)
      ..add(asset.licenseArchivePath!);
    final bytes = files[asset.archivePath];
    if (bytes == null) {
      _fail(
        'presetPackAssetMissing',
        asset.archivePath,
        'A declared preset asset is missing.',
      );
    }
    if (bytes.length != asset.sizeBytes) {
      _fail(
        'presetPackSizeMismatch',
        asset.archivePath,
        'A preset asset size differs from its manifest.',
      );
    }
    if (presentationPresetFileSha256(bytes) != asset.sha256) {
      _fail(
        'presetPackChecksumMismatch',
        asset.archivePath,
        'A preset asset checksum differs from its manifest.',
      );
    }
    _validateMedia(asset, bytes);
    final license = files[asset.licenseArchivePath!];
    if (license == null || license.isEmpty) {
      _fail(
        'presetPackLicenseRequired',
        asset.licenseArchivePath!,
        'Every redistributed preset asset requires a license.',
      );
    }
    if (license.length != asset.licenseSizeBytes ||
        presentationPresetFileSha256(license) != asset.licenseSha256) {
      _fail(
        'presetPackChecksumMismatch',
        asset.licenseArchivePath!,
        'A preset license differs from its manifest.',
      );
    }
    try {
      if (utf8.decode(license, allowMalformed: false).trim().isEmpty) {
        throw const FormatException();
      }
    } on FormatException {
      _fail(
        'presetPackLicenseInvalid',
        asset.licenseArchivePath!,
        'Preset licenses must be non-empty UTF-8 text.',
      );
    }
  }
  if (files.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(files.keys.toSet()).isNotEmpty) {
    _fail(
      'presetPackUnexpectedEntry',
      r'$',
      'Preset pack files must exactly match the manifest.',
    );
  }
  for (final entry in files.entries) {
    _validateArchivePath(
      entry.key,
      entry.key,
      entry.key.startsWith('assets/') ? 'assets' : 'licenses',
    );
    totalBytes += entry.value.length;
  }
  if (totalBytes > presentationPresetMaxArchiveBytes) {
    _fail(
      'presetPackPayloadTooLarge',
      r'$',
      'Preset pack payload exceeds the supported size.',
    );
  }
  final references = _profileAssetReferences(profile);
  if (!projectPaths.containsAll(references.assets) ||
      !manifest.assets
          .map((asset) => asset.licenseProjectPath!)
          .toSet()
          .containsAll(references.licenses)) {
    _fail(
      'presetPackProfileAssetMissing',
      r'$.profile',
      'Every profile asset and font license must be embedded in the pack.',
    );
  }
  return Map<String, Uint8List>.unmodifiable(
    Map<String, Uint8List>.fromEntries(
      files.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    ),
  );
}

({Set<String> assets, Set<String> licenses}) _profileAssetReferences(
  ProjectPresentationProfile profile,
) {
  final assets = <String>{};
  final licenses = <String>{};
  void add(String? value) {
    if (value != null) assets.add(value);
  }

  void addVideo(ProjectResponsiveVideoProfile? media) {
    if (media == null) return;
    for (final variant in <ProjectVideoVariantProfile>[
      media.landscape,
      if (media.portrait case final portrait?) portrait,
    ]) {
      add(variant.videoPath);
      add(variant.posterPath);
      add(variant.captionsPath);
    }
  }

  add(profile.branding.iconPath);
  add(profile.branding.coverPath);
  add(profile.branding.heroPath);
  add(profile.branding.titleMusicPath);
  addVideo(profile.intro?.media);
  addVideo(profile.titleMotion?.promptLoop);
  addVideo(profile.titleMotion?.menuLoop);
  if (profile.typography case final typography?) {
    for (final role in <ProjectTypographyRoleProfile>[
      typography.display,
      typography.body,
      typography.dialogue,
      typography.numbers,
    ]) {
      add(role.fontPath);
      if (role.licensePath case final path?) licenses.add(path);
    }
  }
  return (assets: assets, licenses: licenses);
}

void _validateMedia(PresentationPresetAsset asset, Uint8List bytes) {
  final valid = switch (asset.mediaType) {
    'image/png' => bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47,
    'image/jpeg' => bytes.length >= 2 && bytes[0] == 0xff && bytes[1] == 0xd8,
    'image/webp' => bytes.length >= 12 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP',
    'font/ttf' => bytes.length >= 4,
    'font/otf' => bytes.length >= 4,
    'audio/ogg' => bytes.length >= 4 &&
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'OggS',
    'audio/mpeg' => bytes.length >= 3,
    'audio/wav' => bytes.length >= 12,
    'audio/flac' => bytes.length >= 4,
    'audio/mp4' || 'video/mp4' => bytes.length >= 8 &&
        ascii.decode(bytes.sublist(4, 8), allowInvalid: true) == 'ftyp',
    'text/vtt' => utf8.decode(bytes, allowMalformed: true).startsWith('WEBVTT'),
    _ => false,
  };
  if (!valid) {
    _fail(
      'presetPackMimeMismatch',
      asset.archivePath,
      'Preset asset bytes do not match their declared MIME type.',
    );
  }
}

List<PresentationPresetAsset> _orderedAssets(
  Iterable<PresentationPresetAsset> values,
) {
  final assets = values.toList()
    ..sort((left, right) => left.projectPath.compareTo(right.projectPath));
  if (assets.length > presentationPresetMaxFiles ~/ 2) {
    _fail(
      'presetPackEntryCountExceeded',
      r'$.assets',
      'Preset packs contain too many assets.',
    );
  }
  return List<PresentationPresetAsset>.unmodifiable(assets);
}

void _validateProjectPath(String value, String path) {
  final segments = value.split('/');
  if (!value.startsWith('assets/') || _unsafeSegments(value, segments)) {
    _fail(
      'presetPackProjectPathInvalid',
      path,
      'Preset destinations must be safe project-relative asset paths.',
    );
  }
}

void _validateArchivePath(String value, String path, String root) {
  final segments = value.split('/');
  if (!value.startsWith('$root/') || _unsafeSegments(value, segments)) {
    _fail(
      'presetPackInvalidPath',
      path,
      'Preset archive paths must stay below assets/ or licenses/.',
    );
  }
}

bool _unsafeSegments(String value, List<String> segments) =>
    value.startsWith('/') ||
    value.contains(r'\') ||
    value.contains('\u0000') ||
    segments.any(
      (segment) =>
          segment.isEmpty ||
          segment == '.' ||
          segment == '..' ||
          segment.startsWith('.'),
    );

void _requireKeys(Map<String, dynamic> json, Set<String> keys, String path) {
  if (json.keys.toSet().difference(keys).isNotEmpty ||
      keys.difference(json.keys.toSet()).isNotEmpty) {
    _fail(
      'presetPackManifestInvalid',
      path,
      'Preset manifest keys are missing or unsupported.',
    );
  }
}

String _string(Object? value, String path) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    _fail('presetPackManifestInvalid', path, 'Expected a non-empty string.');
  }
  return value;
}

String? _optionalString(Object? value, String path) =>
    value == null ? null : _string(value, path);

int _integer(Object? value, String path) {
  if (value is! int) {
    _fail('presetPackManifestInvalid', path, 'Expected an integer.');
  }
  return value;
}

void _boundedText(String value, String path, int maximum) {
  if (value.trim().isEmpty || value != value.trim() || value.length > maximum) {
    _fail(
      'presetPackTextInvalid',
      path,
      'Preset text is empty or exceeds its supported length.',
    );
  }
}

Never _fail(String code, String path, String message) {
  throw PresentationPresetPackException(
    code: code,
    path: path,
    message: message,
  );
}

final RegExp _idPattern = RegExp(r'^[a-z][a-z0-9-]{0,63}$');
final RegExp _sha256Pattern = RegExp(r'^[a-f0-9]{64}$');
final RegExp _mediaTypePattern = RegExp(
  r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$',
);
