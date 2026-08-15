import 'project_presentation_profile.dart';

final class PlayerPauseMenuState {
  const PlayerPauseMenuState.empty()
      : visibilityOverrides = const <ProjectPauseActionId, bool>{};

  PlayerPauseMenuState({
    Map<ProjectPauseActionId, bool> visibilityOverrides = const {},
  }) : visibilityOverrides = Map.unmodifiable(
          _validatedVisibilityOverrides(visibilityOverrides),
        );

  factory PlayerPauseMenuState.fromJson(Map<String, dynamic> json) {
    final rawOverrides = json['visibilityOverrides'];
    if (rawOverrides == null) {
      return const PlayerPauseMenuState.empty();
    }
    if (rawOverrides is! Map<String, dynamic>) {
      throw const FormatException(
        'PlayerPauseMenuState.visibilityOverrides must be an object',
      );
    }

    return PlayerPauseMenuState(
      visibilityOverrides: <ProjectPauseActionId, bool>{
        for (final entry in rawOverrides.entries)
          _actionIdFromJson(entry.key): _visibilityFromJson(
            entry.key,
            entry.value,
          ),
      },
    );
  }

  final Map<ProjectPauseActionId, bool> visibilityOverrides;

  bool isActionVisible(
    ProjectPauseActionId actionId, {
    required bool projectDefaultVisibility,
  }) {
    if (actionId == ProjectPauseActionId.resume) {
      return true;
    }
    return visibilityOverrides[actionId] ?? projectDefaultVisibility;
  }

  PlayerPauseMenuState setActionVisibility(
    ProjectPauseActionId actionId, {
    required bool visible,
  }) {
    if (actionId == ProjectPauseActionId.resume) {
      throw ArgumentError.value(
        actionId,
        'actionId',
        'Resume visibility cannot be overridden',
      );
    }
    return PlayerPauseMenuState(
      visibilityOverrides: <ProjectPauseActionId, bool>{
        ...visibilityOverrides,
        actionId: visible,
      },
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'visibilityOverrides': <String, bool>{
          for (final entry in _sortedEntries(visibilityOverrides))
            entry.key.name: entry.value,
        },
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PlayerPauseMenuState &&
        visibilityOverrides.length == other.visibilityOverrides.length &&
        visibilityOverrides.entries.every(
          (entry) => other.visibilityOverrides[entry.key] == entry.value,
        );
  }

  @override
  int get hashCode => Object.hashAll(
        _sortedEntries(visibilityOverrides)
            .map((entry) => Object.hash(entry.key, entry.value)),
      );
}

Map<ProjectPauseActionId, bool> _validatedVisibilityOverrides(
  Map<ProjectPauseActionId, bool> overrides,
) {
  if (overrides.containsKey(ProjectPauseActionId.resume)) {
    throw ArgumentError.value(
      overrides,
      'visibilityOverrides',
      'Resume visibility cannot be overridden',
    );
  }
  return overrides;
}

ProjectPauseActionId _actionIdFromJson(String value) {
  for (final actionId in ProjectPauseActionId.values) {
    if (actionId.name == value) {
      return actionId;
    }
  }
  throw FormatException('Unknown pause menu action id: $value');
}

bool _visibilityFromJson(String actionId, Object? value) {
  if (value is bool) {
    return value;
  }
  throw FormatException(
    'Pause menu visibility for $actionId must be a boolean',
  );
}

List<MapEntry<ProjectPauseActionId, bool>> _sortedEntries(
  Map<ProjectPauseActionId, bool> overrides,
) =>
    overrides.entries.toList(growable: false)
      ..sort((a, b) => a.key.index.compareTo(b.key.index));
