import 'package:json_annotation/json_annotation.dart';

import '../exceptions/map_exceptions.dart';
import '../models/shadow.dart';
import '../models/shadow_catalog.dart';
import 'project_shadow_profile_json_codec.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

/// Encodes a [ProjectShadowCatalog] using the external Shadow V0 JSON shape.
Map<String, Object?> encodeProjectShadowCatalog(ProjectShadowCatalog catalog) {
  return <String, Object?>{
    'profiles': <Object?>[
      for (final profile in catalog.profiles)
        encodeProjectShadowProfile(profile),
    ],
  };
}

/// Decodes a [ProjectShadowCatalog] from the external Shadow V0 JSON shape.
///
/// A `null` catalog, an empty object, or an object without `profiles` decodes
/// to an empty catalog. Unknown top-level keys are ignored.
ProjectShadowCatalog decodeProjectShadowCatalog(Object? json) {
  if (json == null) {
    return ProjectShadowCatalog();
  }
  if (json is! Map) {
    throw ValidationException(
      'ProjectShadowCatalog JSON must be an Object, got ${json.runtimeType}',
    );
  }

  final map = _stringKeyMapFrom(json);
  if (!map.containsKey('profiles')) {
    return ProjectShadowCatalog();
  }

  final rawProfiles = map['profiles'];
  if (rawProfiles is! List) {
    throw const ValidationException(
      'ProjectShadowCatalog.profiles must be a List',
    );
  }

  final profiles = <ProjectShadowProfile>[];
  for (var index = 0; index < rawProfiles.length; index += 1) {
    final item = rawProfiles[index];
    if (item is! Map) {
      throw ValidationException(
        'ProjectShadowCatalog.profiles[$index] must be an Object',
      );
    }
    profiles.add(decodeProjectShadowProfile(item));
  }

  return ProjectShadowCatalog(profiles: profiles);
}

class ProjectShadowCatalogJsonConverter
    implements JsonConverter<ProjectShadowCatalog, Object?> {
  const ProjectShadowCatalogJsonConverter();

  @override
  ProjectShadowCatalog fromJson(Object? json) {
    return decodeProjectShadowCatalog(json);
  }

  @override
  Object? toJson(ProjectShadowCatalog catalog) {
    return encodeProjectShadowCatalog(catalog);
  }
}
