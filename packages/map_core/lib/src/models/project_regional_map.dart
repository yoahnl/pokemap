import '../localization/localized_names.dart';
import 'project_presentation_profile.dart';

enum ProjectRegionPointVisibility { hidden, discoveredOnly, always }

enum ProjectRegionPointDiscovery { always, onMapVisit }

final class ProjectRegionalMapCatalog {
  ProjectRegionalMapCatalog({
    this.schemaVersion = 1,
    List<ProjectRegionDefinition> regions = const [],
    List<ProjectRegionPointOfInterest> pointsOfInterest = const [],
  }) : regions = List.unmodifiable(regions),
       pointsOfInterest = List.unmodifiable(pointsOfInterest) {
    if (schemaVersion != 1) {
      throw const FormatException('Unsupported regional map schemaVersion.');
    }
    _unique(regions.map((region) => region.id), 'regions');
    _unique(pointsOfInterest.map((point) => point.id), 'pointsOfInterest');
  }

  factory ProjectRegionalMapCatalog.fromJson(Map<String, dynamic> json) {
    _keys(json, const {'schemaVersion', 'regions', 'pointsOfInterest'});
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Regional map schemaVersion must be 1.');
    }
    return ProjectRegionalMapCatalog(
      regions: _objects(
        json['regions'],
        'regions',
      ).map(ProjectRegionDefinition.fromJson).toList(),
      pointsOfInterest: _objects(
        json['pointsOfInterest'],
        'pointsOfInterest',
      ).map(ProjectRegionPointOfInterest.fromJson).toList(),
    );
  }

  final int schemaVersion;
  final List<ProjectRegionDefinition> regions;
  final List<ProjectRegionPointOfInterest> pointsOfInterest;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'regions': regions.map((region) => region.toJson()).toList(),
    'pointsOfInterest': pointsOfInterest
        .map((point) => point.toJson())
        .toList(),
  };
}

final class ProjectRegionDefinition {
  ProjectRegionDefinition({
    required String id,
    required String label,
    Map<String, String> labels = const {},
    String? imagePath,
    this.sampling = ProjectMenuImageSampling.smooth,
    this.sortOrder = 0,
  }) : id = _identity(id, 'region.id'),
       label = _text(label, 'region.label'),
       labels = _translations(labels),
       imagePath = _imagePath(imagePath);

  factory ProjectRegionDefinition.fromJson(Map<String, dynamic> json) {
    _keys(json, const {
      'id',
      'label',
      'labels',
      'imagePath',
      'sampling',
      'sortOrder',
    });
    return ProjectRegionDefinition(
      id: _string(json['id'], 'id'),
      label: _string(json['label'], 'label'),
      labels: _stringMap(json['labels']),
      imagePath: _optionalString(json['imagePath'], 'imagePath'),
      sampling: _enum(
        json['sampling'],
        ProjectMenuImageSampling.values,
        ProjectMenuImageSampling.smooth,
      ),
      sortOrder: _integer(json['sortOrder']),
    );
  }

  final String id;
  final String label;
  final Map<String, String> labels;
  final String? imagePath;
  final ProjectMenuImageSampling sampling;
  final int sortOrder;

  String labelFor(String locale) =>
      resolveLocalizedName(names: labels, locale: locale, fallback: label);

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    if (labels.isNotEmpty) 'labels': labels,
    if (imagePath != null) 'imagePath': imagePath,
    'sampling': sampling.name,
    'sortOrder': sortOrder,
  };
}

final class ProjectRegionDestination {
  ProjectRegionDestination({required String mapId, String? spawnId})
    : mapId = _identity(mapId, 'destination.mapId'),
      spawnId = spawnId == null
          ? null
          : _identity(spawnId, 'destination.spawnId');

  factory ProjectRegionDestination.fromJson(Map<String, dynamic> json) {
    _keys(json, const {'mapId', 'spawnId'});
    return ProjectRegionDestination(
      mapId: _string(json['mapId'], 'mapId'),
      spawnId: _optionalString(json['spawnId'], 'spawnId'),
    );
  }

  final String mapId;
  final String? spawnId;

  Map<String, dynamic> toJson() => {
    'mapId': mapId,
    if (spawnId != null) 'spawnId': spawnId,
  };
}

final class ProjectRegionPointOfInterest {
  ProjectRegionPointOfInterest({
    required String id,
    required String regionId,
    required String label,
    Map<String, String> labels = const {},
    required double u,
    required double v,
    this.visibility = ProjectRegionPointVisibility.always,
    this.discovery = ProjectRegionPointDiscovery.onMapVisit,
    List<String> mapIds = const [],
    String? description,
    Map<String, String> descriptions = const {},
    String? thumbnailPath,
    this.destination,
    this.sortOrder = 0,
  }) : id = _identity(id, 'poi.id'),
       regionId = _identity(regionId, 'poi.regionId'),
       label = _text(label, 'poi.label'),
       labels = _translations(labels),
       u = _coordinate(u, 'u'),
       v = _coordinate(v, 'v'),
       mapIds = List.unmodifiable(
         mapIds.map((id) => _identity(id, 'poi.mapIds')),
       ),
       description = description == null
           ? null
           : _text(description, 'poi.description'),
       descriptions = _translations(descriptions),
       thumbnailPath = _imagePath(thumbnailPath) {
    if (discovery == ProjectRegionPointDiscovery.onMapVisit && mapIds.isEmpty) {
      throw const FormatException('onMapVisit requires at least one mapId.');
    }
    _unique(mapIds, 'poi.mapIds');
    if (description == null && descriptions.isNotEmpty) {
      throw const FormatException(
        'Localized descriptions require a fallback description.',
      );
    }
  }

  factory ProjectRegionPointOfInterest.fromJson(Map<String, dynamic> json) {
    _keys(json, const {
      'id',
      'regionId',
      'label',
      'labels',
      'u',
      'v',
      'visibility',
      'discovery',
      'mapIds',
      'description',
      'descriptions',
      'thumbnailPath',
      'destination',
      'sortOrder',
    });
    return ProjectRegionPointOfInterest(
      id: _string(json['id'], 'id'),
      regionId: _string(json['regionId'], 'regionId'),
      label: _string(json['label'], 'label'),
      labels: _stringMap(json['labels']),
      u: _number(json['u'], 'u'),
      v: _number(json['v'], 'v'),
      visibility: _enum(
        json['visibility'],
        ProjectRegionPointVisibility.values,
        ProjectRegionPointVisibility.always,
      ),
      discovery: _enum(
        json['discovery'],
        ProjectRegionPointDiscovery.values,
        ProjectRegionPointDiscovery.onMapVisit,
      ),
      mapIds: _strings(json['mapIds'], 'mapIds'),
      description: _optionalString(json['description'], 'description'),
      descriptions: _stringMap(json['descriptions']),
      thumbnailPath: _optionalString(json['thumbnailPath'], 'thumbnailPath'),
      destination: json['destination'] == null
          ? null
          : ProjectRegionDestination.fromJson(
              _object(json['destination'], 'destination'),
            ),
      sortOrder: _integer(json['sortOrder']),
    );
  }

  final String id;
  final String regionId;
  final String label;
  final Map<String, String> labels;
  final double u;
  final double v;
  final ProjectRegionPointVisibility visibility;
  final ProjectRegionPointDiscovery discovery;
  final List<String> mapIds;
  final String? description;
  final Map<String, String> descriptions;
  final String? thumbnailPath;
  final ProjectRegionDestination? destination;
  final int sortOrder;

  String labelFor(String locale) =>
      resolveLocalizedName(names: labels, locale: locale, fallback: label);
  String? descriptionFor(String locale) => description == null
      ? null
      : resolveLocalizedName(
          names: descriptions,
          locale: locale,
          fallback: description!,
        );

  Map<String, dynamic> toJson() => {
    'id': id,
    'regionId': regionId,
    'label': label,
    if (labels.isNotEmpty) 'labels': labels,
    'u': u,
    'v': v,
    'visibility': visibility.name,
    'discovery': discovery.name,
    'mapIds': mapIds,
    if (description != null) 'description': description,
    if (descriptions.isNotEmpty) 'descriptions': descriptions,
    if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
    if (destination != null) 'destination': destination!.toJson(),
    'sortOrder': sortOrder,
  };
}

void _keys(Map<String, dynamic> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown regional map fields.');
  }
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field must be an object.');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _objects(Object? value, String field) {
  if (value is! List) throw FormatException('$field must be a list.');
  return value.map((item) => _object(item, field)).toList();
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

String? _optionalString(Object? value, String field) =>
    value == null ? null : _string(value, field);

String _text(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$field must be nonblank and trimmed.');
  }
  return value;
}

String _identity(String value, String field) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(value)) {
    throw FormatException('$field must be a stable identity.');
  }
  return value;
}

Map<String, String> _stringMap(Object? value) {
  if (value == null) return const {};
  final object = _object(value, 'translations');
  return object.map(
    (key, value) => MapEntry(key, _string(value, 'translation')),
  );
}

Map<String, String> _translations(Map<String, String> values) {
  final result = <String, String>{};
  for (final entry in values.entries) {
    final locale = entry.key.replaceAll('_', '-').toLowerCase();
    if (!RegExp(r'^[a-z]{2,3}(-[a-z0-9]{2,8})*$').hasMatch(locale) ||
        result.containsKey(locale)) {
      throw const FormatException('Invalid or duplicate locale.');
    }
    result[locale] = _text(entry.value, 'translation');
  }
  return Map.unmodifiable(result);
}

String? _imagePath(String? value) {
  if (value == null) return null;
  if (!value.startsWith('assets/') ||
      value != value.trim() ||
      value.contains('\\') ||
      value.contains(':') ||
      value
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..')) {
    throw const FormatException(
      'Image must reference a project-owned assets path.',
    );
  }
  return value;
}

double _number(Object? value, String field) {
  if (value is! num) throw FormatException('$field must be numeric.');
  return value.toDouble();
}

double _coordinate(double value, String field) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw FormatException('$field must be finite and within [0, 1].');
  }
  return value;
}

int _integer(Object? value) {
  if (value == null) return 0;
  if (value is! int) {
    throw const FormatException('sortOrder must be an integer.');
  }
  return value;
}

T _enum<T extends Enum>(Object? value, List<T> values, T fallback) {
  if (value == null) return fallback;
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw const FormatException('Unsupported regional map enum value.');
}

void _unique(Iterable<String> values, String field) {
  final ids = <String>{};
  if (values.any((value) => !ids.add(value))) {
    throw FormatException('$field contains duplicate identities.');
  }
}

List<String> _strings(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('$field must be a list.');
  return value.map((item) => _string(item, field)).toList();
}
