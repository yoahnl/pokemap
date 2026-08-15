import 'package:meta/meta.dart' show immutable;

import '../diagnostics/scene_diagnostics.dart';
import '../exceptions/map_exceptions.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../validation/validators.dart';

enum NewGameEntrypointMigrationStatus { ready, noChanges, blocked }

enum NewGameEntrypointMigrationApplyStatus {
  applied,
  noChanges,
  stale,
  blocked,
}

enum NewGameEntrypointMigrationIssueCode {
  ambiguousEntrypoint,
  legacyEntrypointInvalid,
  sceneMissing,
  sceneProfileIncompatible,
  sceneInvalid,
  projectInvalid,
  staleRevision,
  projectChanged,
}

@immutable
final class NewGameEntrypointMigrationIssue {
  const NewGameEntrypointMigrationIssue({
    required this.code,
    required this.path,
    required this.message,
    required this.suggestedFix,
  });

  final NewGameEntrypointMigrationIssueCode code;
  final String path;
  final String message;
  final String suggestedFix;

  String get diagnosticCode => switch (code) {
        NewGameEntrypointMigrationIssueCode.ambiguousEntrypoint =>
          'new_game.migration_ambiguous_entrypoint',
        NewGameEntrypointMigrationIssueCode.legacyEntrypointInvalid =>
          'new_game.migration_legacy_entrypoint_invalid',
        NewGameEntrypointMigrationIssueCode.sceneMissing =>
          'new_game.migration_scene_missing',
        NewGameEntrypointMigrationIssueCode.sceneProfileIncompatible =>
          'new_game.migration_scene_profile_incompatible',
        NewGameEntrypointMigrationIssueCode.sceneInvalid =>
          'new_game.migration_scene_invalid',
        NewGameEntrypointMigrationIssueCode.projectInvalid =>
          'new_game.migration_project_invalid',
        NewGameEntrypointMigrationIssueCode.staleRevision =>
          'new_game.migration_stale',
        NewGameEntrypointMigrationIssueCode.projectChanged =>
          'new_game.migration_project_changed',
      };

  Map<String, Object?> toJson() => <String, Object?>{
        'code': code.name,
        'diagnosticCode': diagnosticCode,
        'path': path,
        'message': message,
        'suggestedFix': suggestedFix,
      };

  @override
  String toString() =>
      'NewGameEntrypointMigrationIssue(code: ${code.name}, path: $path)';
}

@immutable
final class NewGameEntrypointMigrationChange {
  const NewGameEntrypointMigrationChange({
    required this.path,
    required this.before,
    required this.after,
  });

  final String path;
  final Object? before;
  final Object? after;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewGameEntrypointMigrationChange &&
          other.path == path &&
          other.before == before &&
          other.after == after;

  @override
  int get hashCode => Object.hash(path, before, after);
}

@immutable
final class NewGameEntrypointMigrationPlan {
  NewGameEntrypointMigrationPlan._({
    required this.status,
    required this.sourceRevision,
    required this.sourceSceneId,
    required List<NewGameEntrypointMigrationChange> changes,
    required List<NewGameEntrypointMigrationIssue> issues,
    required Map<String, dynamic>? migratedProjectJson,
  })  : changes = List<NewGameEntrypointMigrationChange>.unmodifiable(changes),
        issues = List<NewGameEntrypointMigrationIssue>.unmodifiable(issues),
        _migratedProjectJson = migratedProjectJson == null
            ? null
            : Map<String, dynamic>.unmodifiable(migratedProjectJson);

  final NewGameEntrypointMigrationStatus status;
  final String sourceRevision;
  final String? sourceSceneId;
  final List<NewGameEntrypointMigrationChange> changes;
  final List<NewGameEntrypointMigrationIssue> issues;
  final Map<String, dynamic>? _migratedProjectJson;
}

@immutable
final class NewGameEntrypointMigrationApplyResult {
  NewGameEntrypointMigrationApplyResult._({
    required this.status,
    required this.projectJson,
    required List<NewGameEntrypointMigrationIssue> issues,
  }) : issues = List<NewGameEntrypointMigrationIssue>.unmodifiable(issues);

  final NewGameEntrypointMigrationApplyStatus status;
  final Map<String, dynamic> projectJson;
  final List<NewGameEntrypointMigrationIssue> issues;
}

NewGameEntrypointMigrationPlan planNewGameEntrypointMigration({
  required Map<String, dynamic> projectJson,
  required String projectRevision,
}) {
  final revision = _requiredRevision(projectRevision);
  final rawNewGame = projectJson['newGame'];
  if (rawNewGame == null) {
    return _noChanges(revision);
  }
  if (rawNewGame is! Map) {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.projectInvalid,
        r'$.newGame',
        'La configuration New Game doit être un objet.',
        'Réparer la configuration New Game avant de relancer la migration.',
      ),
    );
  }
  final newGame = Map<String, dynamic>.from(rawNewGame);
  if (!newGame.containsKey('starterSelectionSceneId')) {
    return _noChanges(revision);
  }
  if (newGame.containsKey('preSessionSceneId')) {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.ambiguousEntrypoint,
        r'$.newGame',
        'Les deux entrypoints New Game sont présents.',
        'Conserver une seule intention puis relancer le dry-run.',
      ),
    );
  }
  final sourceValue = newGame['starterSelectionSceneId'];
  if (sourceValue is! String || sourceValue.trim().isEmpty) {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.legacyEntrypointInvalid,
        r'$.newGame.starterSelectionSceneId',
        'L’entrypoint legacy doit contenir un identifiant de Scene.',
        'Choisir une Scene preSession existante ou supprimer l’entrypoint.',
      ),
    );
  }
  final sceneId = sourceValue.trim();
  final candidateNewGame = <String, dynamic>{...newGame}
    ..remove('starterSelectionSceneId')
    ..['preSessionSceneId'] = sceneId;
  final candidate = <String, dynamic>{
    ...projectJson,
    'version': 'v7',
    'newGame': candidateNewGame,
  };

  late final ProjectManifest manifest;
  try {
    manifest = ProjectManifest.fromJson(candidate);
  } on Object {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.projectInvalid,
        r'$',
        'Le projet ne peut pas être décodé avec le contrat V7.',
        'Corriger les erreurs de manifeste avant de relancer la migration.',
      ),
      sourceSceneId: sceneId,
    );
  }

  final scene =
      manifest.scenes.where((entry) => entry.id == sceneId).firstOrNull;
  if (scene == null) {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.sceneMissing,
        r'$.newGame.starterSelectionSceneId',
        'La Scene référencée est absente du projet.',
        'Choisir une Scene existante ou supprimer l’entrypoint.',
      ),
      sourceSceneId: sceneId,
    );
  }
  if (scene.executionProfile != SceneExecutionProfile.preSession) {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.sceneProfileIncompatible,
        '\$.scenes[$sceneId]',
        'La Scene référencée n’utilise pas le profil preSession.',
        'Convertir explicitement la Scene au profil preSession et corriger ses capacités.',
      ),
      sourceSceneId: sceneId,
    );
  }
  final diagnostics = diagnoseSceneAgainstProject(scene, manifest);
  if (diagnostics.hasErrors) {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.sceneInvalid,
        '\$.scenes[$sceneId]',
        'La Scene ne respecte pas le contrat preSession.',
        'Corriger les diagnostics de la Scene avant de relancer la migration.',
      ),
      sourceSceneId: sceneId,
    );
  }
  try {
    ProjectValidator.validate(manifest);
  } on ValidationException {
    return _blocked(
      revision,
      _issue(
        NewGameEntrypointMigrationIssueCode.projectInvalid,
        r'$',
        'Le projet migré échoue à la validation canonique.',
        'Corriger les diagnostics projet avant de relancer la migration.',
      ),
      sourceSceneId: sceneId,
    );
  }

  final changes = <NewGameEntrypointMigrationChange>[
    if (projectJson['version'] != 'v7')
      NewGameEntrypointMigrationChange(
        path: r'$.version',
        before: projectJson['version'],
        after: 'v7',
      ),
    NewGameEntrypointMigrationChange(
      path: r'$.newGame.starterSelectionSceneId',
      before: sourceValue,
      after: null,
    ),
    NewGameEntrypointMigrationChange(
      path: r'$.newGame.preSessionSceneId',
      before: null,
      after: sceneId,
    ),
  ];
  return NewGameEntrypointMigrationPlan._(
    status: NewGameEntrypointMigrationStatus.ready,
    sourceRevision: revision,
    sourceSceneId: sceneId,
    changes: changes,
    issues: const <NewGameEntrypointMigrationIssue>[],
    migratedProjectJson: candidate,
  );
}

NewGameEntrypointMigrationApplyResult applyNewGameEntrypointMigration({
  required Map<String, dynamic> projectJson,
  required String currentProjectRevision,
  required NewGameEntrypointMigrationPlan plan,
}) {
  final revision = _requiredRevision(currentProjectRevision);
  if (revision != plan.sourceRevision) {
    return NewGameEntrypointMigrationApplyResult._(
      status: NewGameEntrypointMigrationApplyStatus.stale,
      projectJson: projectJson,
      issues: <NewGameEntrypointMigrationIssue>[
        _issue(
          NewGameEntrypointMigrationIssueCode.staleRevision,
          r'$.revision',
          'Le projet a changé depuis le dry-run.',
          'Relancer le dry-run sur la révision actuelle.',
        ),
      ],
    );
  }
  if (plan.status == NewGameEntrypointMigrationStatus.noChanges) {
    return NewGameEntrypointMigrationApplyResult._(
      status: NewGameEntrypointMigrationApplyStatus.noChanges,
      projectJson: projectJson,
      issues: const <NewGameEntrypointMigrationIssue>[],
    );
  }
  if (plan.status == NewGameEntrypointMigrationStatus.blocked) {
    return NewGameEntrypointMigrationApplyResult._(
      status: NewGameEntrypointMigrationApplyStatus.blocked,
      projectJson: projectJson,
      issues: plan.issues,
    );
  }
  final currentPlan = planNewGameEntrypointMigration(
    projectJson: projectJson,
    projectRevision: revision,
  );
  if (currentPlan.status != NewGameEntrypointMigrationStatus.ready ||
      currentPlan.sourceSceneId != plan.sourceSceneId ||
      !_changesEqual(currentPlan.changes, plan.changes)) {
    return NewGameEntrypointMigrationApplyResult._(
      status: NewGameEntrypointMigrationApplyStatus.stale,
      projectJson: projectJson,
      issues: <NewGameEntrypointMigrationIssue>[
        _issue(
          NewGameEntrypointMigrationIssueCode.projectChanged,
          r'$',
          'Le contenu du projet ne correspond plus au dry-run.',
          'Relancer le dry-run sur le contenu actuel.',
        ),
      ],
    );
  }
  return NewGameEntrypointMigrationApplyResult._(
    status: NewGameEntrypointMigrationApplyStatus.applied,
    projectJson: Map<String, dynamic>.from(currentPlan._migratedProjectJson!),
    issues: const <NewGameEntrypointMigrationIssue>[],
  );
}

String _requiredRevision(String value) {
  final revision = value.trim();
  if (revision.isEmpty) {
    throw ArgumentError.value(value, 'projectRevision', 'must not be empty');
  }
  return revision;
}

NewGameEntrypointMigrationPlan _noChanges(String revision) =>
    NewGameEntrypointMigrationPlan._(
      status: NewGameEntrypointMigrationStatus.noChanges,
      sourceRevision: revision,
      sourceSceneId: null,
      changes: const <NewGameEntrypointMigrationChange>[],
      issues: const <NewGameEntrypointMigrationIssue>[],
      migratedProjectJson: null,
    );

NewGameEntrypointMigrationPlan _blocked(
  String revision,
  NewGameEntrypointMigrationIssue issue, {
  String? sourceSceneId,
}) =>
    NewGameEntrypointMigrationPlan._(
      status: NewGameEntrypointMigrationStatus.blocked,
      sourceRevision: revision,
      sourceSceneId: sourceSceneId,
      changes: const <NewGameEntrypointMigrationChange>[],
      issues: <NewGameEntrypointMigrationIssue>[issue],
      migratedProjectJson: null,
    );

NewGameEntrypointMigrationIssue _issue(
  NewGameEntrypointMigrationIssueCode code,
  String path,
  String message,
  String suggestedFix,
) =>
    NewGameEntrypointMigrationIssue(
      code: code,
      path: path,
      message: message,
      suggestedFix: suggestedFix,
    );

bool _changesEqual(
  List<NewGameEntrypointMigrationChange> left,
  List<NewGameEntrypointMigrationChange> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
