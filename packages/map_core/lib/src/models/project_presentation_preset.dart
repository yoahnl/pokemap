import 'project_presentation_profile.dart';

final class ProjectPresentationPresetAssetReference {
  const ProjectPresentationPresetAssetReference({
    required this.projectPath,
    required this.mediaType,
    required this.sizeBytes,
    required this.sha256,
    required this.licenseProjectPath,
  });

  factory ProjectPresentationPresetAssetReference.fromJson(
    Map<String, dynamic> json,
  ) {
    _requireKeys(json, const <String>{
      'projectPath',
      'mediaType',
      'sizeBytes',
      'sha256',
      'licenseProjectPath',
    });
    final sizeBytes = json['sizeBytes'];
    if (sizeBytes is! int || sizeBytes < 1) {
      throw const FormatException('Invalid presentation preset asset size.');
    }
    final sha256 = _string(json['sha256'], 'sha256');
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException(
        'Invalid presentation preset asset checksum.',
      );
    }
    return ProjectPresentationPresetAssetReference(
      projectPath: _projectPath(json['projectPath'], 'projectPath'),
      mediaType: _mediaType(json['mediaType']),
      sizeBytes: sizeBytes,
      sha256: sha256,
      licenseProjectPath: _projectPath(
        json['licenseProjectPath'],
        'licenseProjectPath',
      ),
    );
  }

  final String projectPath;
  final String mediaType;
  final int sizeBytes;
  final String sha256;
  final String licenseProjectPath;

  Map<String, Object?> toJson() => <String, Object?>{
    'projectPath': projectPath,
    'mediaType': mediaType,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    'licenseProjectPath': licenseProjectPath,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPresentationPresetAssetReference &&
          other.projectPath == projectPath &&
          other.mediaType == mediaType &&
          other.sizeBytes == sizeBytes &&
          other.sha256 == sha256 &&
          other.licenseProjectPath == licenseProjectPath;

  @override
  int get hashCode => Object.hash(
    projectPath,
    mediaType,
    sizeBytes,
    sha256,
    licenseProjectPath,
  );
}

final class ProjectPresentationPresetRecord {
  const ProjectPresentationPresetRecord({
    required this.id,
    required this.label,
    required this.description,
    required this.profile,
    this.assets = const <ProjectPresentationPresetAssetReference>[],
  });

  factory ProjectPresentationPresetRecord.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, const <String>{
      'id',
      'label',
      'description',
      'profile',
      'assets',
    });
    final id = _string(json['id'], 'id');
    final label = _string(json['label'], 'label');
    final description = _string(json['description'], 'description');
    final profile = json['profile'];
    final assets = json['assets'];
    if (!RegExp(r'^[a-z][a-z0-9-]{0,63}$').hasMatch(id) ||
        label.length > 64 ||
        description.length > 240 ||
        profile is! Map ||
        assets is! List) {
      throw const FormatException('Invalid presentation preset record.');
    }
    final decodedAssets = <ProjectPresentationPresetAssetReference>[];
    final projectPaths = <String>{};
    for (final raw in assets) {
      if (raw is! Map) {
        throw const FormatException('Invalid presentation preset asset.');
      }
      final asset = ProjectPresentationPresetAssetReference.fromJson(
        Map<String, dynamic>.from(raw),
      );
      if (!projectPaths.add(asset.projectPath)) {
        throw const FormatException(
          'Duplicate presentation preset asset path.',
        );
      }
      decodedAssets.add(asset);
    }
    decodedAssets.sort(
      (left, right) => left.projectPath.compareTo(right.projectPath),
    );
    return ProjectPresentationPresetRecord(
      id: id,
      label: label,
      description: description,
      profile: ProjectPresentationProfile.fromJson(
        Map<String, dynamic>.from(profile),
      ),
      assets: List<ProjectPresentationPresetAssetReference>.unmodifiable(
        decodedAssets,
      ),
    );
  }

  final String id;
  final String label;
  final String description;
  final ProjectPresentationProfile profile;
  final List<ProjectPresentationPresetAssetReference> assets;

  List<ProjectPresentationCategory> get configuredCategories =>
      List<ProjectPresentationCategory>.unmodifiable(
        profile.configuredCategories.toList()
          ..sort((left, right) => left.index.compareTo(right.index)),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'label': label,
    'description': description,
    'profile': profile.toJson(),
    'assets': <Object?>[for (final asset in assets) asset.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectPresentationPresetRecord &&
          other.id == id &&
          other.label == label &&
          other.description == description &&
          other.profile == profile &&
          _listEquals(other.assets, assets);

  @override
  int get hashCode =>
      Object.hash(id, label, description, profile, Object.hashAll(assets));
}

void _requireKeys(Map<String, dynamic> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Invalid presentation preset keys.');
  }
}

String _string(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('Invalid presentation preset $field.');
  }
  return value;
}

String _projectPath(Object? value, String field) {
  final path = _string(value, field);
  final segments = path.split('/');
  if (!path.startsWith('assets/') ||
      path.contains(r'\') ||
      segments.any(
        (segment) =>
            segment.isEmpty ||
            segment == '.' ||
            segment == '..' ||
            segment.startsWith('.'),
      )) {
    throw FormatException('Invalid presentation preset $field.');
  }
  return path;
}

String _mediaType(Object? value) {
  final mediaType = _string(value, 'mediaType');
  if (!RegExp(
    r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$',
  ).hasMatch(mediaType)) {
    throw const FormatException('Invalid presentation preset mediaType.');
  }
  return mediaType;
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
