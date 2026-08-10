import 'package:map_core/map_core.dart';

enum CharacterAnimationDefinitionKind { system, custom }

enum CharacterAnimationSlotStatus {
  defined,
  missingRequired,
  missingOptional,
  invalid,
}

enum CharacterAnimationMatrixFilter { all, missing, ready }

final class CharacterAnimationSlotKey {
  const CharacterAnimationSlotKey.system({
    required CharacterAnimationState state,
    required this.direction,
  }) : kind = CharacterAnimationDefinitionKind.system,
       systemState = state,
       definitionId = null;

  const CharacterAnimationSlotKey.custom({
    required this.definitionId,
    required this.direction,
  }) : kind = CharacterAnimationDefinitionKind.custom,
       systemState = null;

  final CharacterAnimationDefinitionKind kind;
  final CharacterAnimationState? systemState;
  final String? definitionId;
  final EntityFacing? direction;

  String get stableId => switch (kind) {
    CharacterAnimationDefinitionKind.system =>
      'system-${systemState!.name}-${direction!.name}',
    CharacterAnimationDefinitionKind.custom =>
      'custom-$definitionId-${direction?.name ?? 'single'}',
  };

  Map<String, Object?> get actionParameters => switch (kind) {
    CharacterAnimationDefinitionKind.system => <String, Object?>{
      'kind': 'system',
      'state': systemState!.name,
      'direction': direction!.name,
    },
    CharacterAnimationDefinitionKind.custom => <String, Object?>{
      'kind': 'custom',
      'definitionId': definitionId!,
      'direction': ?direction?.name,
    },
  };

  @override
  bool operator ==(Object other) {
    return other is CharacterAnimationSlotKey &&
        other.kind == kind &&
        other.systemState == systemState &&
        other.definitionId == definitionId &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(kind, systemState, definitionId, direction);
}

final class CharacterAnimationMatrixSlot {
  const CharacterAnimationMatrixSlot({
    required this.key,
    required this.label,
    required this.status,
    required this.frames,
    required this.sourceAssetId,
    required this.loop,
    this.issue,
  });

  final CharacterAnimationSlotKey key;
  final String label;
  final CharacterAnimationSlotStatus status;
  final List<CharacterAnimationFrame> frames;
  final String? sourceAssetId;
  final bool loop;
  final String? issue;

  int get frameCount => frames.length;
}

final class CharacterAnimationMatrixRow {
  const CharacterAnimationMatrixRow({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.required,
    required this.mode,
    required this.slots,
  });

  final String id;
  final String displayName;
  final CharacterAnimationDefinitionKind kind;
  final bool required;
  final CharacterCustomAnimationMode mode;
  final List<CharacterAnimationMatrixSlot> slots;
}

final class CharacterAnimationMatrixModel {
  CharacterAnimationMatrixModel._(this.rows)
    : _slots = <CharacterAnimationSlotKey, CharacterAnimationMatrixSlot>{
        for (final row in rows)
          for (final slot in row.slots) slot.key: slot,
      };

  factory CharacterAnimationMatrixModel.build({
    required ProjectManifest project,
    required ProjectCharacterEntry character,
  }) {
    final rows = <CharacterAnimationMatrixRow>[
      _systemRow(
        character,
        id: 'base',
        displayName: 'Base',
        state: CharacterAnimationState.idle,
        required: true,
      ),
      _systemRow(
        character,
        id: 'walk',
        displayName: 'Marche',
        state: CharacterAnimationState.walk,
        required: false,
      ),
      _systemRow(
        character,
        id: 'run',
        displayName: 'Course',
        state: CharacterAnimationState.run,
        required: false,
      ),
    ];
    final definitions =
        project.characterStudioCatalog.customAnimationDefinitions.toList()
          ..sort((left, right) {
            final order = left.sortOrder.compareTo(right.sortOrder);
            return order != 0 ? order : left.id.compareTo(right.id);
          });
    for (final definition in definitions) {
      rows.add(_customRow(character, definition));
    }
    return CharacterAnimationMatrixModel._(List.unmodifiable(rows));
  }

  final List<CharacterAnimationMatrixRow> rows;
  final Map<CharacterAnimationSlotKey, CharacterAnimationMatrixSlot> _slots;

  CharacterAnimationMatrixSlot slot(CharacterAnimationSlotKey key) {
    final result = _slots[key];
    if (result == null) {
      throw StateError('Unknown animation slot ${key.stableId}');
    }
    return result;
  }

  List<CharacterAnimationMatrixSlot> slotsFor(
    CharacterAnimationMatrixFilter filter,
  ) {
    return <CharacterAnimationMatrixSlot>[
      for (final row in rows)
        for (final slot in row.slots)
          if (_matchesFilter(slot, filter)) slot,
    ];
  }

  static bool _matchesFilter(
    CharacterAnimationMatrixSlot slot,
    CharacterAnimationMatrixFilter filter,
  ) {
    return switch (filter) {
      CharacterAnimationMatrixFilter.all => true,
      CharacterAnimationMatrixFilter.missing =>
        slot.status != CharacterAnimationSlotStatus.defined,
      CharacterAnimationMatrixFilter.ready =>
        slot.status == CharacterAnimationSlotStatus.defined,
    };
  }
}

const _directions = <EntityFacing>[
  EntityFacing.north,
  EntityFacing.south,
  EntityFacing.east,
  EntityFacing.west,
];

CharacterAnimationMatrixRow _systemRow(
  ProjectCharacterEntry character, {
  required String id,
  required String displayName,
  required CharacterAnimationState state,
  required bool required,
}) {
  return CharacterAnimationMatrixRow(
    id: id,
    displayName: displayName,
    kind: CharacterAnimationDefinitionKind.system,
    required: required,
    mode: CharacterCustomAnimationMode.directional,
    slots: <CharacterAnimationMatrixSlot>[
      for (final direction in _directions)
        _systemSlot(character, state, direction, required: required),
    ],
  );
}

CharacterAnimationMatrixSlot _systemSlot(
  ProjectCharacterEntry character,
  CharacterAnimationState state,
  EntityFacing direction, {
  required bool required,
}) {
  final clip = character.animations
      .where(
        (animation) =>
            animation.state == state && animation.direction == direction,
      )
      .firstOrNull;
  return _slot(
    key: CharacterAnimationSlotKey.system(state: state, direction: direction),
    label: _directionLabel(direction),
    frames: clip?.frames,
    sourceAssetId: clip?.sourceAssetId,
    loop: clip?.loop ?? true,
    required: required,
    sourceRequired: false,
  );
}

CharacterAnimationMatrixRow _customRow(
  ProjectCharacterEntry character,
  CharacterCustomAnimationDefinition definition,
) {
  final directions = definition.mode == CharacterCustomAnimationMode.single
      ? const <EntityFacing?>[null]
      : _directions;
  return CharacterAnimationMatrixRow(
    id: definition.id,
    displayName: definition.displayName,
    kind: CharacterAnimationDefinitionKind.custom,
    required: false,
    mode: definition.mode,
    slots: <CharacterAnimationMatrixSlot>[
      for (final direction in directions)
        _customSlot(character, definition, direction),
    ],
  );
}

CharacterAnimationMatrixSlot _customSlot(
  ProjectCharacterEntry character,
  CharacterCustomAnimationDefinition definition,
  EntityFacing? direction,
) {
  final clip = character.customAnimations
      .where(
        (animation) =>
            animation.definitionId == definition.id &&
            animation.direction == direction,
      )
      .firstOrNull;
  return _slot(
    key: CharacterAnimationSlotKey.custom(
      definitionId: definition.id,
      direction: direction,
    ),
    label: direction == null ? 'Unique' : _directionLabel(direction),
    frames: clip?.frames,
    sourceAssetId: clip?.sourceAssetId,
    loop: clip?.loop ?? true,
    required: false,
    sourceRequired: true,
  );
}

CharacterAnimationMatrixSlot _slot({
  required CharacterAnimationSlotKey key,
  required String label,
  required List<CharacterAnimationFrame>? frames,
  required String? sourceAssetId,
  required bool loop,
  required bool required,
  required bool sourceRequired,
}) {
  if (frames == null) {
    return CharacterAnimationMatrixSlot(
      key: key,
      label: label,
      status: required
          ? CharacterAnimationSlotStatus.missingRequired
          : CharacterAnimationSlotStatus.missingOptional,
      frames: const <CharacterAnimationFrame>[],
      sourceAssetId: sourceAssetId,
      loop: loop,
    );
  }
  final issue = _clipIssue(
    frames,
    sourceAssetId: sourceAssetId,
    sourceRequired: sourceRequired,
  );
  return CharacterAnimationMatrixSlot(
    key: key,
    label: label,
    status: issue == null
        ? CharacterAnimationSlotStatus.defined
        : CharacterAnimationSlotStatus.invalid,
    frames: List.unmodifiable(frames),
    sourceAssetId: sourceAssetId,
    loop: loop,
    issue: issue,
  );
}

String? _clipIssue(
  List<CharacterAnimationFrame> frames, {
  required String? sourceAssetId,
  required bool sourceRequired,
}) {
  if (sourceRequired &&
      (sourceAssetId == null || sourceAssetId.trim().isEmpty)) {
    return 'Source PNG manquante';
  }
  if (frames.isEmpty) return 'Aucune frame';
  for (final frame in frames) {
    final source = frame.source;
    if (source.x < 0 ||
        source.y < 0 ||
        source.width <= 0 ||
        source.height <= 0) {
      return 'Rectangle de frame invalide';
    }
    if (frame.durationMs <= 0) return 'Durée de frame invalide';
  }
  return null;
}

String _directionLabel(EntityFacing direction) => switch (direction) {
  EntityFacing.north => 'Nord',
  EntityFacing.south => 'Sud',
  EntityFacing.east => 'Est',
  EntityFacing.west => 'Ouest',
};
