import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'badge_definition.freezed.dart';
part 'badge_definition.g.dart';

@freezed
class BadgeDefinition with _$BadgeDefinition {
  const BadgeDefinition._();

  const factory BadgeDefinition({
    required String id,
    required String label,
    String? iconRelativePath,
    FieldAbility? fieldAbilityUnlock,
  }) = _BadgeDefinition;

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) =>
      _$BadgeDefinitionFromJson(json).normalized();

  BadgeDefinition normalized() {
    final normalizedId = id.trim();
    final normalizedLabel = label.trim();
    final normalizedIconPath = iconRelativePath?.trim();
    if (normalizedId.isEmpty) {
      throw StateError('BadgeDefinition id must not be empty');
    }
    if (normalizedLabel.isEmpty) {
      throw StateError('BadgeDefinition label must not be empty');
    }
    if (iconRelativePath != null && normalizedIconPath!.isEmpty) {
      throw StateError(
        'BadgeDefinition iconRelativePath must not be empty when provided',
      );
    }
    if (normalizedIconPath != null && normalizedIconPath.startsWith('/')) {
      throw StateError('BadgeDefinition iconRelativePath must be relative');
    }
    return copyWith(
      id: normalizedId,
      label: normalizedLabel,
      iconRelativePath: normalizedIconPath,
    );
  }
}
