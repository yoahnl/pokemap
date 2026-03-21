import 'package:freezed_annotation/freezed_annotation.dart';
import 'enums.dart';

part 'project_manifest.freezed.dart';
part 'project_manifest.g.dart';

@freezed
class ProjectManifest with _$ProjectManifest {
  @JsonSerializable(explicitToJson: true)
  const factory ProjectManifest({
    required String name,
    @Default(ProjectVersion.v1) ProjectVersion version,
    required List<ProjectMapEntry> maps,
    required List<ProjectTilesetEntry> tilesets,
    @Default({}) Map<String, dynamic> globalProperties,
  }) = _ProjectManifest;

  factory ProjectManifest.fromJson(Map<String, dynamic> json) => _$ProjectManifestFromJson(json);
}

@freezed
class ProjectMapEntry with _$ProjectMapEntry {
  const factory ProjectMapEntry({
    required String id,
    required String name,
    required String relativePath,
  }) = _ProjectMapEntry;

  factory ProjectMapEntry.fromJson(Map<String, dynamic> json) => _$ProjectMapEntryFromJson(json);
}

@freezed
class ProjectTilesetEntry with _$ProjectTilesetEntry {
  const factory ProjectTilesetEntry({
    required String id,
    required String name,
    required String relativePath,
  }) = _ProjectTilesetEntry;

  factory ProjectTilesetEntry.fromJson(Map<String, dynamic> json) => _$ProjectTilesetEntryFromJson(json);
}
