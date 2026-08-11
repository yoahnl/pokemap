import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_item_definition.dart';

part 'project_item_catalog.freezed.dart';
part 'project_item_catalog.g.dart';

@freezed
abstract class ProjectItemCatalog with _$ProjectItemCatalog {
  const ProjectItemCatalog._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemCatalog({
    required int schemaVersion,
    required List<ProjectItemDefinition> entries,
  }) = _ProjectItemCatalog;

  factory ProjectItemCatalog.fromJson(Map<String, dynamic> json) =>
      _$ProjectItemCatalogFromJson(json).normalized();

  ProjectItemCatalog normalized() {
    if (schemaVersion != 1) {
      throw StateError('ProjectItemCatalog schemaVersion must be 1');
    }
    return copyWith(
      entries: entries
          .map((entry) => entry.normalized())
          .toList(growable: false),
    );
  }
}
