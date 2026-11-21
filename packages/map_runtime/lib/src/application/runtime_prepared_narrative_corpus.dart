import 'package:map_core/map_core.dart';

final class RuntimePreparedNarrativeCorpus {
  RuntimePreparedNarrativeCorpus({
    required Iterable<NarrativeMapProjection> maps,
    this.visualDefinitions,
  }) : maps = List.unmodifiable(maps);

  final List<NarrativeMapProjection> maps;
  final RuntimeNarrativeVisualDefinitions? visualDefinitions;
}

final class RuntimeNarrativeVisualDefinitions {
  RuntimeNarrativeVisualDefinitions.fromProject(ProjectManifest project)
    : models3d = List.unmodifiable(project.models3d),
      elements = List.unmodifiable(project.elements),
      characters = List.unmodifiable(project.characters),
      tilesets = List.unmodifiable(project.tilesets),
      elementCategories = List.unmodifiable(project.elementCategories);

  RuntimeNarrativeVisualDefinitions.fromJson(Map<String, Object?> json)
    : models3d = _decodeList(json['models3d'], ProjectModel3dEntry.fromJson),
      elements = _decodeList(json['elements'], ProjectElementEntry.fromJson),
      characters = _decodeList(
        json['characters'],
        ProjectCharacterEntry.fromJson,
      ),
      tilesets = _decodeList(json['tilesets'], ProjectTilesetEntry.fromJson),
      elementCategories = _decodeList(
        json['elementCategories'],
        ProjectElementCategory.fromJson,
      );

  final List<ProjectModel3dEntry> models3d;
  final List<ProjectElementEntry> elements;
  final List<ProjectCharacterEntry> characters;
  final List<ProjectTilesetEntry> tilesets;
  final List<ProjectElementCategory> elementCategories;

  Map<String, Object?> toJson() => {
    'models3d': [for (final entry in models3d) entry.toJson()],
    'elements': [for (final entry in elements) entry.toJson()],
    'characters': [for (final entry in characters) entry.toJson()],
    'tilesets': [for (final entry in tilesets) entry.toJson()],
    'elementCategories': [
      for (final entry in elementCategories) entry.toJson(),
    ],
  };
}

List<T> _decodeList<T>(Object? json, T Function(Map<String, Object?>) decode) {
  if (json is! List<Object?>) {
    throw const FormatException('Expected a narrative definition list.');
  }
  return List.unmodifiable([
    for (final entry in json) decode(entry as Map<String, Object?>),
  ]);
}
