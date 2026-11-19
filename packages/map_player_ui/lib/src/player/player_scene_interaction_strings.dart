import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

import '../localization/player_localizations.dart';

final class PlayerSceneInteractionStrings {
  const PlayerSceneInteractionStrings._(this._strings);

  factory PlayerSceneInteractionStrings.of(BuildContext context) =>
      PlayerSceneInteractionStrings._(context.playerL10n);

  final PokeMapPlayerLocalizations _strings;

  String get continueLabel => _strings.continueGame;
  String get cancel => _strings.cancel;
  String get yes => _strings.yes;
  String get no => _strings.no;
  String get submit => _strings.interactionSubmit;
  String get textFieldLabel => _strings.interactionTextFieldLabel;
  String get selected => _strings.interactionSelected;
  String get optionUnavailable => _strings.interactionOptionUnavailable;
  String get maximumReached => _strings.interactionMaximumReached;

  String characterCount(int current, int? maximum) => maximum == null
      ? _strings.interactionCharacterCount(current: current)
      : _strings.postBattleProgress(current, maximum);

  String selectionCount(int current, int minimum, int maximum) =>
      _strings.interactionSelectionCount(
        current: current,
        minimum: minimum,
        maximum: maximum,
      );

  String validation(SceneInteractionValidationIssue issue) {
    final minimum = issue.arguments['minimum'];
    final maximum = issue.arguments['maximum'];
    final minimumCount = int.tryParse(minimum ?? '');
    final maximumCount = int.tryParse(maximum ?? '');
    return switch (issue.code) {
      SceneInteractionValidationIssueCode.integerOutOfRange
          when minimum != null && maximum != null =>
        _strings.interactionIntegerOutOfRange(
          minimum: minimum,
          maximum: maximum,
        ),
      SceneInteractionValidationIssueCode.cancellationForbidden =>
        _strings.interactionCancellationForbidden,
      SceneInteractionValidationIssueCode.textTooShort
          when minimumCount != null =>
        _strings.interactionTextTooShort(minimum: minimumCount),
      SceneInteractionValidationIssueCode.textTooLong
          when maximumCount != null =>
        _strings.interactionTextTooLong(maximum: maximumCount),
      SceneInteractionValidationIssueCode.tooFewSelections
          when minimumCount != null =>
        _strings.interactionTooFewSelections(minimum: minimumCount),
      SceneInteractionValidationIssueCode.tooManySelections
          when maximumCount != null =>
        _strings.interactionTooManySelections(maximum: maximumCount),
      SceneInteractionValidationIssueCode.optionDisabled => optionUnavailable,
      _ => _strings.interactionCannotSubmit,
    };
  }
}
