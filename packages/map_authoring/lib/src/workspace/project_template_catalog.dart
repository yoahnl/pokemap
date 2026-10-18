final class ProjectTemplateCatalog {
  const ProjectTemplateCatalog.empty() : templates = const [];

  ProjectTemplateCatalog._(List<ProjectTemplateDescriptor> values)
      : templates = List.unmodifiable(values);

  factory ProjectTemplateCatalog.fromJson(Object? value) {
    final json = _object(value, const {'schemaVersion', 'templates'});
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['templates'] is! List) {
      throw const FormatException('Invalid project template catalogue.');
    }
    final templates = (json['templates'] as List)
        .map(ProjectTemplateDescriptor.fromJson)
        .toList();
    if (templates.map((item) => item.id).toSet().length != templates.length) {
      throw const FormatException('Duplicate project template ID.');
    }
    return ProjectTemplateCatalog._(templates);
  }

  final List<ProjectTemplateDescriptor> templates;

  ProjectTemplateDescriptor require(String id) => templates.firstWhere(
        (item) => item.id == id,
        orElse: () => throw FormatException('Unknown project template: $id.'),
      );

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'templates': templates.map((item) => item.toJson()).toList(),
      };
}

final class ProjectTemplateDescriptor {
  ProjectTemplateDescriptor._({
    required this.id,
    required this.label,
    required this.description,
    required this.revision,
    required this.archiveUri,
    required this.archiveSha256,
    required this.previewUri,
    required this.previewSha256,
    required this.tileSize,
    required this.mapWidth,
    required this.mapHeight,
    required this.projectPaths,
  });

  factory ProjectTemplateDescriptor.fromJson(Object? value) {
    final json = _object(value, const {
      'id',
      'label',
      'description',
      'revision',
      'archive',
      'preview',
      'geometry',
      'projectPaths'
    });
    final id = _text(json['id']);
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(id)) {
      throw const FormatException('Invalid project template ID.');
    }
    final archive = _object(json['archive'], const {'uri', 'sha256'});
    final preview = _object(json['preview'], const {'uri', 'sha256'});
    final geometry =
        _object(json['geometry'], const {'tileSize', 'mapWidth', 'mapHeight'});
    final tileSize = geometry['tileSize'];
    final width = geometry['mapWidth'];
    final height = geometry['mapHeight'];
    if (tileSize is! int ||
        !const [16, 32, 48].contains(tileSize) ||
        width is! int ||
        width < 3 ||
        width > 256 ||
        height is! int ||
        height < 3 ||
        height > 256) {
      throw const FormatException('Invalid project template geometry.');
    }
    return ProjectTemplateDescriptor._(
      id: id,
      label: _text(json['label']),
      description: _text(json['description']),
      revision: _text(json['revision']),
      archiveUri: _uri(archive['uri']),
      archiveSha256: _hash(archive['sha256']),
      previewUri: _uri(preview['uri']),
      previewSha256: _hash(preview['sha256']),
      tileSize: tileSize,
      mapWidth: width,
      mapHeight: height,
      projectPaths: _paths(json['projectPaths']),
    );
  }

  final String id, label, description, revision;
  final Uri archiveUri, previewUri;
  final String archiveSha256, previewSha256;
  final int tileSize, mapWidth, mapHeight;
  final List<String> projectPaths;

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'description': description,
        'revision': revision,
        'projectPaths': projectPaths,
        'archive': {'uri': archiveUri.toString(), 'sha256': archiveSha256},
        'preview': {'uri': previewUri.toString(), 'sha256': previewSha256},
        'geometry': {
          'tileSize': tileSize,
          'mapWidth': mapWidth,
          'mapHeight': mapHeight
        },
      };
}

List<String> _paths(Object? value) {
  if (value is! List || value.isEmpty || value.any((item) => item is! String)) {
    throw const FormatException(
        'Project template paths must be a non-empty string list.');
  }
  final paths = List<String>.from(value);
  if (!paths.contains('project.json') ||
      paths.toSet().length != paths.length ||
      paths.any((path) =>
          path.isEmpty ||
          path.startsWith('/') ||
          path.contains('\\') ||
          path.contains(':') ||
          path.contains('\u0000') ||
          path.contains('*') ||
          path.trim() != path ||
          path.split('/').any((part) => part == '.' || part == '..') ||
          (path.endsWith('/') ? path.substring(0, path.length - 1) : path)
              .split('/')
              .any((part) => part.isEmpty))) {
    throw const FormatException(
        'Project template paths must be canonical files or directory prefixes and include project.json.');
  }
  return List.unmodifiable(paths);
}

Map<String, dynamic> _object(Object? value, Set<String> keys) {
  if (value is! Map ||
      value.length != keys.length ||
      value.keys.any((key) => key is! String || !keys.contains(key))) {
    throw const FormatException('Invalid project template fields.');
  }
  return Map<String, dynamic>.from(value);
}

String _text(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.trim() != value ||
      value.contains('\u0000')) {
    throw const FormatException('Expected non-empty project template text.');
  }
  return value;
}

String _hash(Object? value) {
  final hash = _text(value);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
    throw const FormatException('Invalid project template SHA-256.');
  }
  return hash;
}

Uri _uri(Object? value) {
  final text = _text(value);
  final uri = Uri.parse(text);
  if (uri.scheme != 'https' ||
      uri.toString() != text ||
      Uri.decodeComponent(text)
          .split('/')
          .any((part) => part == '.' || part == '..') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.port != 443 ||
      uri.pathSegments.any((part) =>
          part == '.' ||
          part == '..' ||
          part.contains('\u0000') ||
          part.contains('\\'))) {
    throw const FormatException(
        'Project template URLs require safe HTTPS origins.');
  }
  return uri;
}
