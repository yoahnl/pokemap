import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

final class PlayerSceneInteractionStrings {
  const PlayerSceneInteractionStrings._(this._languageCode);

  factory PlayerSceneInteractionStrings.of(BuildContext context) =>
      PlayerSceneInteractionStrings._(
        Localizations.localeOf(context).languageCode,
      );

  final String _languageCode;

  bool get _isFrench => _languageCode == 'fr';

  String get continueLabel => _isFrench ? 'Continuer' : 'Continue';
  String get cancel => _isFrench ? 'Annuler' : 'Cancel';
  String get yes => _isFrench ? 'Oui' : 'Yes';
  String get no => _isFrench ? 'Non' : 'No';
  String get submit => _isFrench ? 'Valider' : 'Submit';
  String get textFieldLabel => _isFrench ? 'Votre réponse' : 'Your answer';
  String get selected => _isFrench ? 'Sélectionné' : 'Selected';
  String get optionUnavailable => _isFrench
      ? 'Cette option est indisponible.'
      : 'This option is unavailable.';
  String get maximumReached => _isFrench
      ? 'Le nombre maximal de choix est atteint.'
      : 'The maximum number of choices is reached.';

  String characterCount(int current, int? maximum) => maximum == null
      ? (_isFrench ? '$current caractères' : '$current characters')
      : '$current / $maximum';

  String selectionCount(int current, int minimum, int maximum) => _isFrench
      ? '$current sélectionné(s), entre $minimum et $maximum requis'
      : '$current selected, between $minimum and $maximum required';

  String validation(SceneInteractionValidationIssue issue) {
    final arguments = issue.arguments;
    return switch (issue.code) {
      SceneInteractionValidationIssueCode.textTooShort => _isFrench
          ? 'Saisissez au moins ${arguments['minimum']} caractères.'
          : 'Enter at least ${arguments['minimum']} characters.',
      SceneInteractionValidationIssueCode.textTooLong => _isFrench
          ? 'Saisissez au maximum ${arguments['maximum']} caractères.'
          : 'Enter at most ${arguments['maximum']} characters.',
      SceneInteractionValidationIssueCode.tooFewSelections => _isFrench
          ? 'Sélectionnez au moins ${arguments['minimum']} options.'
          : 'Select at least ${arguments['minimum']} options.',
      SceneInteractionValidationIssueCode.tooManySelections => _isFrench
          ? 'Sélectionnez au maximum ${arguments['maximum']} options.'
          : 'Select at most ${arguments['maximum']} options.',
      SceneInteractionValidationIssueCode.optionDisabled => optionUnavailable,
      SceneInteractionValidationIssueCode.optionUnknown ||
      SceneInteractionValidationIssueCode.duplicateSelection ||
      SceneInteractionValidationIssueCode.requestMismatch ||
      SceneInteractionValidationIssueCode.resultKindMismatch =>
        _isFrench
            ? 'Cette réponse ne peut pas être envoyée.'
            : 'This answer cannot be submitted.',
    };
  }
}
