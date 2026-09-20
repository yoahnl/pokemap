part of 'scene_command_payload_builder.dart';

String _staticEncounterTrainerId(Map<String, String> parameters) {
  final battleRefId = parameters['staticEncounterId']?.trim() ?? '';
  final trainerId = parameters['trainerId']?.trim() ?? '';
  if (trainerId.isEmpty || battleRefId != 'static:$trainerId') {
    throw ArgumentError.value(
      battleRefId,
      'staticEncounterId',
      'Choisissez une rencontre statique publiée dans le projet.',
    );
  }
  return trainerId;
}

String _staticEncounterBattleTemplateId(Map<String, String> parameters) {
  final battleTemplateId = parameters['battleTemplateId']?.trim() ?? '';
  if (battleTemplateId.isEmpty) {
    throw ArgumentError.value(
      battleTemplateId,
      'battleTemplateId',
      'La rencontre statique doit conserver son template de combat stable.',
    );
  }
  return battleTemplateId;
}

(String, String) _parseNpcRef(String? value) {
  final parts = value?.trim().split('::') ?? const <String>[];
  if (parts.length != 2 ||
      parts.first.trim().isEmpty ||
      parts.last.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      'npcRef',
      'Choisissez un PNJ dans la liste guidée.',
    );
  }
  return (parts.first.trim(), parts.last.trim());
}

SceneFinishGameConsequence _buildFinishGameConsequence(
  Map<String, String> parameters,
) {
  String required(String id) {
    final value = parameters[id]?.trim();
    if (value == null || value.isEmpty) {
      throw ArgumentError.value(value, id, 'Ce champ est obligatoire.');
    }
    return value;
  }

  SceneLocalizedText localized(String fallbackId, String englishId) {
    final english = parameters[englishId]?.trim();
    return SceneLocalizedText(
      fallback: required(fallbackId),
      translations: {if (english != null && english.isNotEmpty) 'en': english},
    );
  }

  final outcome = SceneGameCompletionOutcome.values.firstWhere(
    (candidate) => candidate.name == required('outcome'),
    orElse: () => throw ArgumentError.value(
      parameters['outcome'],
      'outcome',
      'Issue de partie inconnue.',
    ),
  );
  final postGamePolicy = ScenePostGamePolicy.values.firstWhere(
    (candidate) => candidate.name == required('postGamePolicy'),
    orElse: () => throw ArgumentError.value(
      parameters['postGamePolicy'],
      'postGamePolicy',
      'Politique postgame inconnue.',
    ),
  );
  final includeCredits = parameters['includeCredits'] == 'true';

  return SceneFinishGameConsequence(
    endingId: _endingIdFromFriendlyName(required('endingName')),
    outcome: outcome,
    result: SceneFinishGameResult(
      title: localized('resultTitle', 'resultTitleEn'),
      summary: localized('resultSummary', 'resultSummaryEn'),
    ),
    credits: includeCredits
        ? SceneFinishGameCredits(
            title: localized('creditsTitle', 'creditsTitleEn'),
            author: required('creditsAuthor'),
            endingLabel: localized(
              'creditsEndingLabel',
              'creditsEndingLabelEn',
            ),
            skippable: parameters['creditsSkippable'] != 'false',
          )
        : null,
    postGamePolicy: postGamePolicy,
  );
}

String _endingIdFromFriendlyName(String name) {
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
  };
  final normalized = name
      .trim()
      .toLowerCase()
      .split('')
      .map((character) => accents[character] ?? character)
      .join()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (normalized.isEmpty) {
    throw ArgumentError.value(name, 'endingName', 'Nom de fin invalide.');
  }
  return 'ending.$normalized';
}

FieldAbility _fieldAbilityFromId(String id) {
  final normalized = id.trim();
  for (final ability in FieldAbility.values) {
    if (ability.moveId == normalized) return ability;
  }
  throw ArgumentError.value(
    id,
    'abilityId',
    'Unknown canonical field ability.',
  );
}
