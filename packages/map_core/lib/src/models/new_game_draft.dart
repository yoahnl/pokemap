import 'package:meta/meta.dart' show immutable;

import 'narrative_value.dart';
import 'project_new_game_config.dart';
import 'save_data.dart';

const int newGameDraftSchemaVersion = 1;

enum NewGameDraftIssueCode {
  staleRevision,
  playerNameEmpty,
  avatarRequired,
  avatarUnknown,
  starterRequired,
  starterUnknown,
  variableUnknown,
  variableKindMismatch,
}

enum NewGameDraftCommandStatus { applied, stale, rejected, cancelled }

enum NewGameDraftCommandKind {
  setPlayerName,
  selectAvatar,
  setPronouns,
  selectStarter,
  assignVariable,
  cancel,
}

@immutable
final class NewGameDraftIssue {
  NewGameDraftIssue({
    required this.code,
    required this.field,
    Map<String, String> arguments = const <String, String>{},
  }) : arguments = Map<String, String>.unmodifiable(arguments);

  final NewGameDraftIssueCode code;
  final String field;
  final Map<String, String> arguments;

  String get diagnosticCode => switch (code) {
    NewGameDraftIssueCode.staleRevision => 'new_game.draft_stale',
    NewGameDraftIssueCode.playerNameEmpty => 'new_game.draft_player_name_empty',
    NewGameDraftIssueCode.avatarRequired => 'new_game.draft_avatar_required',
    NewGameDraftIssueCode.avatarUnknown => 'new_game.draft_avatar_unknown',
    NewGameDraftIssueCode.starterRequired => 'new_game.draft_starter_required',
    NewGameDraftIssueCode.starterUnknown => 'new_game.draft_starter_unknown',
    NewGameDraftIssueCode.variableUnknown => 'new_game.draft_variable_unknown',
    NewGameDraftIssueCode.variableKindMismatch =>
      'new_game.draft_variable_kind_mismatch',
  };

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code.name,
    'diagnosticCode': diagnosticCode,
    'field': field,
    if (arguments.isNotEmpty) 'arguments': arguments,
  };

  @override
  String toString() => 'NewGameDraftIssue(code: ${code.name}, field: $field)';
}

@immutable
sealed class NewGameDraftCommand {
  const NewGameDraftCommand({required this.expectedRevision});

  factory NewGameDraftCommand.setPlayerName({
    required int expectedRevision,
    required String playerName,
  }) = _SetNewGameDraftPlayerNameCommand;

  factory NewGameDraftCommand.selectAvatar({
    required int expectedRevision,
    required String? avatarCharacterId,
  }) = _SelectNewGameDraftAvatarCommand;

  factory NewGameDraftCommand.setPronouns({
    required int expectedRevision,
    required PlayerPronounSet pronounSet,
  }) = _SetNewGameDraftPronounsCommand;

  factory NewGameDraftCommand.selectStarter({
    required int expectedRevision,
    required String? starterOptionId,
  }) = _SelectNewGameDraftStarterCommand;

  factory NewGameDraftCommand.assignVariable({
    required int expectedRevision,
    required String variableId,
    required NarrativeValue value,
  }) = _AssignNewGameDraftVariableCommand;

  factory NewGameDraftCommand.cancel({required int expectedRevision}) =
      _CancelNewGameDraftCommand;

  final int expectedRevision;

  NewGameDraftCommandKind get kind;

  @override
  String toString() =>
      'NewGameDraftCommand(kind: ${kind.name}, '
      'expectedRevision: $expectedRevision)';
}

final class _SetNewGameDraftPlayerNameCommand extends NewGameDraftCommand {
  const _SetNewGameDraftPlayerNameCommand({
    required super.expectedRevision,
    required this.playerName,
  });

  final String playerName;

  @override
  NewGameDraftCommandKind get kind => NewGameDraftCommandKind.setPlayerName;
}

final class _SelectNewGameDraftAvatarCommand extends NewGameDraftCommand {
  const _SelectNewGameDraftAvatarCommand({
    required super.expectedRevision,
    required this.avatarCharacterId,
  });

  final String? avatarCharacterId;

  @override
  NewGameDraftCommandKind get kind => NewGameDraftCommandKind.selectAvatar;
}

final class _SetNewGameDraftPronounsCommand extends NewGameDraftCommand {
  const _SetNewGameDraftPronounsCommand({
    required super.expectedRevision,
    required this.pronounSet,
  });

  final PlayerPronounSet pronounSet;

  @override
  NewGameDraftCommandKind get kind => NewGameDraftCommandKind.setPronouns;
}

final class _SelectNewGameDraftStarterCommand extends NewGameDraftCommand {
  const _SelectNewGameDraftStarterCommand({
    required super.expectedRevision,
    required this.starterOptionId,
  });

  final String? starterOptionId;

  @override
  NewGameDraftCommandKind get kind => NewGameDraftCommandKind.selectStarter;
}

final class _AssignNewGameDraftVariableCommand extends NewGameDraftCommand {
  const _AssignNewGameDraftVariableCommand({
    required super.expectedRevision,
    required this.variableId,
    required this.value,
  });

  final String variableId;
  final NarrativeValue value;

  @override
  NewGameDraftCommandKind get kind => NewGameDraftCommandKind.assignVariable;
}

final class _CancelNewGameDraftCommand extends NewGameDraftCommand {
  const _CancelNewGameDraftCommand({required super.expectedRevision});

  @override
  NewGameDraftCommandKind get kind => NewGameDraftCommandKind.cancel;
}

@immutable
final class NewGameDraftCommandResult {
  NewGameDraftCommandResult._({
    required this.status,
    required this.draft,
    List<NewGameDraftIssue> issues = const <NewGameDraftIssue>[],
  }) : issues = List<NewGameDraftIssue>.unmodifiable(issues);

  final NewGameDraftCommandStatus status;
  final NewGameDraft draft;
  final List<NewGameDraftIssue> issues;

  @override
  String toString() =>
      'NewGameDraftCommandResult(status: ${status.name}, '
      'revision: ${draft.revision}, '
      'issues: ${issues.map((issue) => issue.code.name).join(',')})';
}

@immutable
final class NewGameDraft {
  NewGameDraft._({
    required this.draftId,
    required this.projectRevision,
    required this.slotId,
    required this.revision,
    required this.playerName,
    required this.avatarCharacterId,
    required this.pronounSet,
    required this.starterOptionId,
    required bool starterSelectionRequired,
    required List<String> allowedAvatarCharacterIds,
    required List<String> allowedStarterOptionIds,
    required Map<String, NarrativeValueKind> variableKinds,
    required Map<String, NarrativeValue> variables,
  }) : _starterSelectionRequired = starterSelectionRequired,
       allowedAvatarCharacterIds = List<String>.unmodifiable(
         allowedAvatarCharacterIds,
       ),
       allowedStarterOptionIds = List<String>.unmodifiable(
         allowedStarterOptionIds,
       ),
       variableKinds = Map<String, NarrativeValueKind>.unmodifiable(
         variableKinds,
       ),
       variables = Map<String, NarrativeValue>.unmodifiable(variables);

  factory NewGameDraft.start({
    required String draftId,
    required String projectRevision,
    required String slotId,
    required ProjectNewGameConfig config,
    Map<String, NarrativeValueKind> variableKinds =
        const <String, NarrativeValueKind>{},
  }) {
    return NewGameDraft._(
      draftId: _requiredIdentity(draftId, 'draftId'),
      projectRevision: _requiredIdentity(projectRevision, 'projectRevision'),
      slotId: _requiredIdentity(slotId, 'slotId'),
      revision: 0,
      playerName: config.playerName.trim(),
      avatarCharacterId: null,
      pronounSet: config.playerPronounSet,
      starterOptionId: null,
      starterSelectionRequired:
          config.preSessionSceneId == null ||
          config.preSessionSceneId!.trim().isEmpty,
      allowedAvatarCharacterIds: _normalizedIds(
        config.playerAvatarCharacterIds,
        'playerAvatarCharacterIds',
      ),
      allowedStarterOptionIds: _normalizedIds(
        config.starterOptions.map((option) => option.id),
        'starterOptions',
      ),
      variableKinds: _normalizedVariableKinds(variableKinds),
      variables: const <String, NarrativeValue>{},
    );
  }

  final int schemaVersion = newGameDraftSchemaVersion;
  final String draftId;
  final String projectRevision;
  final String slotId;
  final int revision;
  final String playerName;
  final String? avatarCharacterId;
  final PlayerPronounSet pronounSet;
  final String? starterOptionId;
  final bool _starterSelectionRequired;
  final List<String> allowedAvatarCharacterIds;
  final List<String> allowedStarterOptionIds;
  final Map<String, NarrativeValueKind> variableKinds;
  final Map<String, NarrativeValue> variables;

  NewGameDraftCommandResult apply(NewGameDraftCommand command) {
    if (command.expectedRevision != revision) {
      return NewGameDraftCommandResult._(
        status: NewGameDraftCommandStatus.stale,
        draft: this,
        issues: <NewGameDraftIssue>[
          NewGameDraftIssue(
            code: NewGameDraftIssueCode.staleRevision,
            field: 'revision',
            arguments: <String, String>{
              'expected': command.expectedRevision.toString(),
              'actual': revision.toString(),
            },
          ),
        ],
      );
    }
    return switch (command) {
      _SetNewGameDraftPlayerNameCommand() => _setPlayerName(command),
      _SelectNewGameDraftAvatarCommand() => _selectAvatar(command),
      _SetNewGameDraftPronounsCommand() => NewGameDraftCommandResult._(
        status: NewGameDraftCommandStatus.applied,
        draft: _next(pronounSet: command.pronounSet),
      ),
      _SelectNewGameDraftStarterCommand() => _selectStarter(command),
      _AssignNewGameDraftVariableCommand() => _assignVariable(command),
      _CancelNewGameDraftCommand() => NewGameDraftCommandResult._(
        status: NewGameDraftCommandStatus.cancelled,
        draft: this,
      ),
    };
  }

  List<NewGameDraftIssue> validate() {
    final issues = <NewGameDraftIssue>[];
    if (playerName.trim().isEmpty) {
      issues.add(
        NewGameDraftIssue(
          code: NewGameDraftIssueCode.playerNameEmpty,
          field: 'playerName',
        ),
      );
    }
    if (allowedAvatarCharacterIds.isNotEmpty && avatarCharacterId == null) {
      issues.add(
        NewGameDraftIssue(
          code: NewGameDraftIssueCode.avatarRequired,
          field: 'avatarCharacterId',
        ),
      );
    }
    if (_starterSelectionRequired &&
        allowedStarterOptionIds.isNotEmpty &&
        starterOptionId == null) {
      issues.add(
        NewGameDraftIssue(
          code: NewGameDraftIssueCode.starterRequired,
          field: 'starterOptionId',
        ),
      );
    }
    return List<NewGameDraftIssue>.unmodifiable(issues);
  }

  NewGameDraftCommandResult _setPlayerName(
    _SetNewGameDraftPlayerNameCommand command,
  ) {
    final value = command.playerName.trim();
    if (value.isEmpty) {
      return _rejected(NewGameDraftIssueCode.playerNameEmpty, 'playerName');
    }
    return NewGameDraftCommandResult._(
      status: NewGameDraftCommandStatus.applied,
      draft: _next(playerName: value),
    );
  }

  NewGameDraftCommandResult _selectAvatar(
    _SelectNewGameDraftAvatarCommand command,
  ) {
    final value = _optionalIdentity(command.avatarCharacterId);
    if (value != null && !allowedAvatarCharacterIds.contains(value)) {
      return _rejected(
        NewGameDraftIssueCode.avatarUnknown,
        'avatarCharacterId',
      );
    }
    return NewGameDraftCommandResult._(
      status: NewGameDraftCommandStatus.applied,
      draft: _next(avatarCharacterId: value),
    );
  }

  NewGameDraftCommandResult _selectStarter(
    _SelectNewGameDraftStarterCommand command,
  ) {
    final value = _optionalIdentity(command.starterOptionId);
    if (value != null && !allowedStarterOptionIds.contains(value)) {
      return _rejected(NewGameDraftIssueCode.starterUnknown, 'starterOptionId');
    }
    return NewGameDraftCommandResult._(
      status: NewGameDraftCommandStatus.applied,
      draft: _next(starterOptionId: value),
    );
  }

  NewGameDraftCommandResult _assignVariable(
    _AssignNewGameDraftVariableCommand command,
  ) {
    final variableId = command.variableId.trim();
    final expectedKind = variableKinds[variableId];
    if (expectedKind == null) {
      return _rejected(NewGameDraftIssueCode.variableUnknown, 'variables');
    }
    if (expectedKind != command.value.kind) {
      return _rejected(NewGameDraftIssueCode.variableKindMismatch, 'variables');
    }
    return NewGameDraftCommandResult._(
      status: NewGameDraftCommandStatus.applied,
      draft: _next(
        variables: <String, NarrativeValue>{
          ...variables,
          variableId: command.value,
        },
      ),
    );
  }

  NewGameDraftCommandResult _rejected(
    NewGameDraftIssueCode code,
    String field,
  ) => NewGameDraftCommandResult._(
    status: NewGameDraftCommandStatus.rejected,
    draft: this,
    issues: <NewGameDraftIssue>[NewGameDraftIssue(code: code, field: field)],
  );

  NewGameDraft _next({
    String? playerName,
    Object? avatarCharacterId = _unchanged,
    PlayerPronounSet? pronounSet,
    Object? starterOptionId = _unchanged,
    Map<String, NarrativeValue>? variables,
  }) => NewGameDraft._(
    draftId: draftId,
    projectRevision: projectRevision,
    slotId: slotId,
    revision: revision + 1,
    playerName: playerName ?? this.playerName,
    avatarCharacterId: identical(avatarCharacterId, _unchanged)
        ? this.avatarCharacterId
        : avatarCharacterId as String?,
    pronounSet: pronounSet ?? this.pronounSet,
    starterOptionId: identical(starterOptionId, _unchanged)
        ? this.starterOptionId
        : starterOptionId as String?,
    starterSelectionRequired: _starterSelectionRequired,
    allowedAvatarCharacterIds: allowedAvatarCharacterIds,
    allowedStarterOptionIds: allowedStarterOptionIds,
    variableKinds: variableKinds,
    variables: variables ?? this.variables,
  );

  @override
  String toString() =>
      'NewGameDraft(draftId: $draftId, schemaVersion: $schemaVersion, '
      'revision: $revision, hasPlayerName: ${playerName.isNotEmpty}, '
      'hasAvatar: ${avatarCharacterId != null}, '
      'hasStarter: ${starterOptionId != null}, '
      'variableCount: ${variables.length})';
}

const Object _unchanged = Object();

String _requiredIdentity(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be empty');
  }
  return normalized;
}

String? _optionalIdentity(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

List<String> _normalizedIds(Iterable<String> values, String name) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final id = value.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(value, name, 'must not contain empty ids');
    }
    if (!seen.add(id)) {
      throw ArgumentError.value(value, name, 'must not contain duplicate ids');
    }
    normalized.add(id);
  }
  return normalized;
}

Map<String, NarrativeValueKind> _normalizedVariableKinds(
  Map<String, NarrativeValueKind> values,
) {
  final normalized = <String, NarrativeValueKind>{};
  for (final entry in values.entries) {
    final id = entry.key.trim();
    if (id.isEmpty) {
      throw ArgumentError.value(entry.key, 'variableKinds');
    }
    if (normalized.containsKey(id)) {
      throw ArgumentError.value(entry.key, 'variableKinds');
    }
    normalized[id] = entry.value;
  }
  return normalized;
}
