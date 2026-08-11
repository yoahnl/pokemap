import 'package:freezed_annotation/freezed_annotation.dart';

import 'project_item_capabilities.dart';

part 'project_item_definition.freezed.dart';
part 'project_item_definition.g.dart';

@freezed
abstract class ProjectItemDefinition with _$ProjectItemDefinition {
  const ProjectItemDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemDefinition({
    required String id,
    required String displayName,
    @Default(<String>[]) List<String> aliases,
    required String pocketId,
    String? description,
    int? buyPrice,
    int? sellPrice,
    @Default(<String>{}) Set<String> tags,
    @Default(<ProjectItemUseDefinition>[]) List<ProjectItemUseDefinition> uses,
    ProjectCaptureItemDefinition? capture,
    ProjectMoveMachineItemDefinition? machine,
    String? heldEffectId,
  }) = _ProjectItemDefinition;

  factory ProjectItemDefinition.fromJson(Map<String, dynamic> json) =>
      _$ProjectItemDefinitionFromJson(json).normalized();

  ProjectItemDefinition normalized() {
    final normalizedId = id.trim();
    final normalizedDisplayName = displayName.trim();
    final normalizedPocketId = pocketId.trim();
    if (normalizedId.isEmpty) {
      throw StateError('ProjectItemDefinition id must not be empty');
    }
    if (normalizedDisplayName.isEmpty) {
      throw StateError('ProjectItemDefinition displayName must not be empty');
    }
    if (buyPrice != null && buyPrice! < 0) {
      throw StateError('ProjectItemDefinition buyPrice must not be negative');
    }
    if (sellPrice != null && sellPrice! < 0) {
      throw StateError('ProjectItemDefinition sellPrice must not be negative');
    }

    final normalizedAliases = aliases
        .map((alias) => alias.trim())
        .where((alias) => alias.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final normalizedTags = tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final normalizedUses = uses
        .map((use) => use.normalized())
        .toList(growable: false);
    final occupiedContexts = <ProjectItemUseContext>{};
    for (final use in normalizedUses) {
      if (occupiedContexts.intersection(use.contexts).isNotEmpty) {
        throw StateError(
          'ProjectItemDefinition uses must not overlap contexts',
        );
      }
      occupiedContexts.addAll(use.contexts);
    }

    final normalizedDescription = description?.trim();
    final normalizedHeldEffectId = heldEffectId?.trim();
    return copyWith(
      id: normalizedId,
      displayName: normalizedDisplayName,
      aliases: normalizedAliases,
      pocketId: normalizedPocketId,
      description: normalizedDescription?.isEmpty ?? true
          ? null
          : normalizedDescription,
      tags: normalizedTags,
      uses: normalizedUses,
      capture: capture?.normalized(),
      machine: machine?.normalized(),
      heldEffectId: normalizedHeldEffectId?.isEmpty ?? true
          ? null
          : normalizedHeldEffectId,
    );
  }
}
