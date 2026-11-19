import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../localization/player_localizations.dart';

final class PlayerSaveRecoveryStrings {
  const PlayerSaveRecoveryStrings._(this._strings);

  factory PlayerSaveRecoveryStrings.of(BuildContext context) =>
      PlayerSaveRecoveryStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String cause(SaveLoadFailureCode code) => switch (code) {
    SaveLoadFailureCode.unreadable => _strings.saveRecoveryCauseUnreadable,
    SaveLoadFailureCode.unsupportedSchema =>
      _strings.saveRecoveryCauseUnsupportedSchema,
    SaveLoadFailureCode.invalidState => _strings.saveRecoveryCauseInvalidState,
  };

  String? versions({int? detected, int? expected}) {
    if (expected == null) return null;
    if (detected == null) {
      return _strings.saveRecoveryExpectedVersion(expected: expected);
    }
    return _strings.saveRecoveryVersionMismatch(
      detected: detected,
      expected: expected,
    );
  }

  String action(SaveRecoveryAction action) => switch (action) {
    SaveRecoveryAction.retry => _strings.saveRecoveryActionRetry,
    SaveRecoveryAction.restoreBackup =>
      _strings.saveRecoveryActionRestoreBackup,
    SaveRecoveryAction.migrate => _strings.saveRecoveryActionMigrate,
    SaveRecoveryAction.deleteSave => _strings.saveRecoveryActionDeleteSave,
    SaveRecoveryAction.returnToTitle => _strings.returnToTitle,
  };

  String get deleteConfirmTitle => _strings.saveRecoveryDeleteConfirmTitle;

  String get deleteConfirmBody => _strings.saveRecoveryDeleteConfirmBody;

  String get deleteConfirm => _strings.saveRecoveryDeleteConfirm;

  String get deleteCancel => _strings.cancel;
}
