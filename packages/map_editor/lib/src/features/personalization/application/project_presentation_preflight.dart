import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'personalization_publish_readiness.dart';

abstract interface class ProjectPresentationPreflight {
  Future<ProjectPresentationPreflightResult> inspect({
    required Directory projectRoot,
    required ProjectPresentationProfile profile,
  });
}

final class ProjectPresentationPreflightResult {
  const ProjectPresentationPreflightResult({
    required this.report,
    required this.checkedAssetCount,
  });

  final PersonalizationPublishReadiness report;
  final int checkedAssetCount;
}

/// Verifies authoring assets before the package-level export inspection.
///
/// Paths are always resolved below [projectRoot] and symbolic links are never
/// followed. The package builder remains the final authority after export.
final class FileSystemProjectPresentationPreflight
    implements ProjectPresentationPreflight {
  const FileSystemProjectPresentationPreflight();

  @override
  Future<ProjectPresentationPreflightResult> inspect({
    required Directory projectRoot,
    required ProjectPresentationProfile profile,
  }) async {
    final issues = <PersonalizationReadinessIssue>[
      ...PersonalizationPublishReadiness.fromProfile(profile).issues,
    ];
    var checkedAssetCount = 0;

    for (final reference in _references(profile)) {
      final resolved = _resolveProjectFile(projectRoot, reference.relativePath);
      if (resolved == null) {
        // The pure profile validator already reports unsafe authoring paths.
        continue;
      }
      final type = await FileSystemEntity.type(
        resolved.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.notFound) {
        issues.add(
          _issue(
            reference,
            code: 'presentationAssetMissing',
            message: 'The referenced presentation asset does not exist.',
          ),
        );
        continue;
      }
      if (type != FileSystemEntityType.file) {
        issues.add(
          _issue(
            reference,
            code: 'presentationAssetNotRegular',
            message:
                'The referenced presentation asset must be a regular file.',
          ),
        );
        continue;
      }

      checkedAssetCount += 1;
      try {
        final bytes = await resolved.readAsBytes();
        final validation = _validateAsset(reference, bytes);
        if (validation != null) issues.add(validation);
      } on FileSystemException {
        issues.add(
          _issue(
            reference,
            code: 'presentationAssetUnreadable',
            message: 'The referenced presentation asset cannot be read.',
          ),
        );
      }
    }

    return ProjectPresentationPreflightResult(
      report: PersonalizationPublishReadiness.fromIssues(
        profile: profile,
        issues: issues,
      ),
      checkedAssetCount: checkedAssetCount,
    );
  }
}

enum _PresentationAssetKind {
  brandingImage,
  titleMusic,
  introVideo,
  introPoster,
  introCaptions,
  font,
  fontLicense,
}

final class _PresentationAssetReference {
  const _PresentationAssetReference({
    required this.category,
    required this.relativePath,
    required this.profilePath,
    required this.kind,
    this.declaredAudioCodec,
  });

  final ProjectPresentationCategory category;
  final String relativePath;
  final String profilePath;
  final _PresentationAssetKind kind;
  final String? declaredAudioCodec;
}

Iterable<_PresentationAssetReference> _references(
  ProjectPresentationProfile profile,
) sync* {
  final branding = profile.branding;
  for (final entry in <({String field, String? path})>[
    (field: 'iconPath', path: branding.iconPath),
    (field: 'coverPath', path: branding.coverPath),
    (field: 'heroPath', path: branding.heroPath),
  ]) {
    if (entry.path case final path?) {
      yield _PresentationAssetReference(
        category: ProjectPresentationCategory.branding,
        relativePath: path,
        profilePath: '\$.presentation.branding.${entry.field}',
        kind: _PresentationAssetKind.brandingImage,
      );
    }
  }
  if (branding.titleMusicPath case final titleMusicPath?) {
    yield _PresentationAssetReference(
      category: ProjectPresentationCategory.branding,
      relativePath: titleMusicPath,
      profilePath: r'$.presentation.branding.titleMusicPath',
      kind: _PresentationAssetKind.titleMusic,
    );
  }

  if (profile.intro case final intro?) {
    yield _PresentationAssetReference(
      category: ProjectPresentationCategory.intro,
      relativePath: intro.videoPath,
      profilePath: r'$.presentation.intro.videoPath',
      kind: _PresentationAssetKind.introVideo,
      declaredAudioCodec: intro.audioCodec,
    );
    yield _PresentationAssetReference(
      category: ProjectPresentationCategory.intro,
      relativePath: intro.posterPath,
      profilePath: r'$.presentation.intro.posterPath',
      kind: _PresentationAssetKind.introPoster,
    );
    if (intro.captionsPath case final captionsPath?) {
      yield _PresentationAssetReference(
        category: ProjectPresentationCategory.intro,
        relativePath: captionsPath,
        profilePath: r'$.presentation.intro.captionsPath',
        kind: _PresentationAssetKind.introCaptions,
      );
    }
  }

  if (profile.typography case final typography?) {
    final roles = <String, ProjectTypographyRoleProfile>{
      'display': typography.display,
      'body': typography.body,
      'dialogue': typography.dialogue,
      'numbers': typography.numbers,
    };
    for (final entry in roles.entries) {
      final role = entry.value;
      if (role.fontPath case final fontPath?) {
        yield _PresentationAssetReference(
          category: ProjectPresentationCategory.typography,
          relativePath: fontPath,
          profilePath: '\$.presentation.typography.${entry.key}.fontPath',
          kind: _PresentationAssetKind.font,
        );
      }
      if (role.licensePath case final licensePath?) {
        yield _PresentationAssetReference(
          category: ProjectPresentationCategory.typography,
          relativePath: licensePath,
          profilePath: '\$.presentation.typography.${entry.key}.licensePath',
          kind: _PresentationAssetKind.fontLicense,
        );
      }
    }
  }
}

File? _resolveProjectFile(Directory projectRoot, String relativePath) {
  final value = relativePath.trim();
  if (value.isEmpty ||
      p.isAbsolute(value) ||
      value.contains(r'\') ||
      value.split('/').any((segment) => segment.isEmpty || segment == '..')) {
    return null;
  }
  final rootPath = p.normalize(p.absolute(projectRoot.path));
  final filePath = p.normalize(p.absolute(p.join(rootPath, value)));
  if (!p.isWithin(rootPath, filePath)) return null;
  return File(filePath);
}

PersonalizationReadinessIssue? _validateAsset(
  _PresentationAssetReference reference,
  List<int> bytes,
) =>
    switch (reference.kind) {
      _PresentationAssetKind.brandingImage =>
        _validateImage(reference, bytes, isIntroPoster: false),
      _PresentationAssetKind.titleMusic =>
        _validateTitleMusic(reference, bytes),
      _PresentationAssetKind.introVideo =>
        _validateIntroVideo(reference, bytes),
      _PresentationAssetKind.introPoster =>
        _validateImage(reference, bytes, isIntroPoster: true),
      _PresentationAssetKind.introCaptions =>
        _validateCaptions(reference, bytes),
      _PresentationAssetKind.font => _validateFont(reference, bytes),
      _PresentationAssetKind.fontLicense => _validateLicense(reference, bytes),
    };

PersonalizationReadinessIssue? _validateImage(
  _PresentationAssetReference reference,
  List<int> bytes, {
  required bool isIntroPoster,
}) {
  final extension = p.extension(reference.relativePath).toLowerCase();
  if (!const <String>{'.png', '.jpg', '.jpeg', '.webp'}.contains(extension) ||
      !_canDecodeImage(bytes)) {
    return _issue(
      reference,
      code: isIntroPoster ? 'introPosterInvalid' : 'brandingImageCorrupt',
      message: isIntroPoster
          ? 'The intro poster must be a valid PNG, JPEG, or WebP image.'
          : 'The branding image must be a valid PNG, JPEG, or WebP image.',
    );
  }
  return null;
}

bool _canDecodeImage(List<int> bytes) {
  try {
    return image.decodeImage(Uint8List.fromList(bytes)) != null;
  } on image.ImageException {
    return false;
  } on RangeError {
    return false;
  }
}

PersonalizationReadinessIssue? _validateTitleMusic(
  _PresentationAssetReference reference,
  List<int> bytes,
) {
  final extension = p.extension(reference.relativePath).toLowerCase();
  if (!_matchesAudioSignature(extension, bytes)) {
    return _issue(
      reference,
      code: 'titleMusicSignatureInvalid',
      message: 'The title music signature does not match its extension.',
    );
  }
  return null;
}

PersonalizationReadinessIssue? _validateIntroVideo(
  _PresentationAssetReference reference,
  List<int> bytes,
) {
  final signature = latin1.decode(bytes, allowInvalid: true);
  if (!reference.relativePath.toLowerCase().endsWith('.mp4') ||
      !signature.contains('ftyp') ||
      !(signature.contains('avc1') || signature.contains('avc3'))) {
    return _issue(
      reference,
      code: 'introCodecSignatureInvalid',
      message: 'The intro file must contain H.264 video in an MP4 container.',
    );
  }
  final containsAac = signature.contains('mp4a');
  if ((reference.declaredAudioCodec == 'aac' && !containsAac) ||
      (reference.declaredAudioCodec == 'none' && containsAac)) {
    return _issue(
      reference,
      code: 'introAudioSignatureMismatch',
      message: 'The intro audio track does not match its declared codec.',
    );
  }
  return null;
}

PersonalizationReadinessIssue? _validateCaptions(
  _PresentationAssetReference reference,
  List<int> bytes,
) {
  try {
    final captions = utf8.decode(bytes, allowMalformed: false);
    if (captions.startsWith('WEBVTT')) return null;
  } on FormatException {
    // Reported below with the same author-facing correction.
  }
  return _issue(
    reference,
    code: 'introCaptionsInvalid',
    message: 'The intro captions must contain UTF-8 WebVTT.',
  );
}

PersonalizationReadinessIssue? _validateFont(
  _PresentationAssetReference reference,
  List<int> bytes,
) {
  final extension = p.extension(reference.relativePath).toLowerCase();
  final valid = switch (extension) {
    '.ttf' => _startsWith(bytes, const <int>[0x00, 0x01, 0x00, 0x00]) ||
        _startsWith(bytes, ascii.encode('true')),
    '.otf' => _startsWith(bytes, ascii.encode('OTTO')),
    _ => false,
  };
  if (!valid) {
    return _issue(
      reference,
      code: 'fontSignatureInvalid',
      message: 'The font signature does not match its TTF or OTF extension.',
    );
  }
  return null;
}

PersonalizationReadinessIssue? _validateLicense(
  _PresentationAssetReference reference,
  List<int> bytes,
) {
  if (bytes.isNotEmpty && bytes.length <= 1024 * 1024) {
    try {
      if (utf8.decode(bytes, allowMalformed: false).trim().isNotEmpty) {
        return null;
      }
    } on FormatException {
      // Reported below with the same author-facing correction.
    }
  }
  return _issue(
    reference,
    code: 'fontLicenseInvalid',
    message: 'The font license must contain readable UTF-8 text.',
  );
}

bool _matchesAudioSignature(String extension, List<int> bytes) =>
    switch (extension) {
      '.ogg' => _startsWith(bytes, const <int>[0x4f, 0x67, 0x67, 0x53]),
      '.wav' => _startsWith(bytes, const <int>[0x52, 0x49, 0x46, 0x46]) &&
          bytes.length >= 12 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x41 &&
          bytes[10] == 0x56 &&
          bytes[11] == 0x45,
      '.mp3' => _startsWith(bytes, const <int>[0x49, 0x44, 0x33]) ||
          (bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0),
      '.flac' => _startsWith(bytes, const <int>[0x66, 0x4c, 0x61, 0x43]),
      '.m4a' => bytes.length >= 12 &&
          bytes[4] == 0x66 &&
          bytes[5] == 0x74 &&
          bytes[6] == 0x79 &&
          bytes[7] == 0x70,
      _ => false,
    };

bool _startsWith(List<int> bytes, List<int> signature) {
  if (bytes.length < signature.length) return false;
  for (var index = 0; index < signature.length; index += 1) {
    if (bytes[index] != signature[index]) return false;
  }
  return true;
}

PersonalizationReadinessIssue _issue(
  _PresentationAssetReference reference, {
  required String code,
  required String message,
}) =>
    PersonalizationReadinessIssue(
      code: code,
      category: reference.category,
      severity: ProjectPresentationDiagnosticSeverity.error,
      path: reference.profilePath,
      message: message,
    );
