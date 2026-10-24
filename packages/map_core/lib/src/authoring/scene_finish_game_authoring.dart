part of 'scene_command_payload_builder.dart';

Map<String, String> sceneFinishGameAuthoringParameters(
  SceneFinishGameConsequence consequence,
) => {
  'endingName': consequence.endingId.startsWith('ending.')
      ? consequence.endingId.substring('ending.'.length)
      : consequence.endingId,
  'outcome': consequence.outcome.name,
  'recordParty': '${consequence.recordParty}',
  'resultTitle': consequence.result.title.fallback,
  'resultTitleEn': consequence.result.title.translations['en'] ?? '',
  'resultSummary': consequence.result.summary.fallback,
  'resultSummaryEn': consequence.result.summary.translations['en'] ?? '',
  'includeCredits': '${consequence.credits != null}',
  'creditsTitle': consequence.credits?.title.fallback ?? '',
  'creditsTitleEn': consequence.credits?.title.translations['en'] ?? '',
  'creditsAuthor': consequence.credits?.author ?? '',
  'creditsEndingLabel': consequence.credits?.endingLabel.fallback ?? '',
  'creditsEndingLabelEn':
      consequence.credits?.endingLabel.translations['en'] ?? '',
  'creditsSkippable': '${consequence.credits?.skippable ?? true}',
  'postGamePolicy': consequence.postGamePolicy.name,
};

SceneFinishGameConsequence updateSceneFinishGameAuthoringParameters(
  SceneFinishGameConsequence original,
  Map<String, String> parameters,
) {
  final before = sceneFinishGameAuthoringParameters(original);
  if (parameters.keys.any((key) => !before.containsKey(key))) {
    throw const FormatException('Unknown finishGame authoring parameter.');
  }
  final values = {...before, ...parameters};
  final changed = values.keys
      .where((key) => values[key] != before[key])
      .toSet();
  if (changed.isEmpty) return original;
  final edited = _buildFinishGameConsequence(values).toJson();
  final result = original.toJson();
  for (final key in ['outcome', 'postGamePolicy', 'recordParty']) {
    if (!changed.contains(key)) continue;
    if (edited.containsKey(key)) {
      result[key] = edited[key];
    } else {
      result.remove(key);
    }
  }
  if (changed.contains('endingName')) result['endingId'] = edited['endingId'];
  void localize(
    Map<String, dynamic> target,
    Map<String, dynamic> fresh,
    String field,
    String fallbackParameter,
    String englishParameter,
  ) {
    final text = Map<String, dynamic>.from(target[field] as Map);
    final replacement = fresh[field] as Map;
    if (changed.contains(fallbackParameter)) {
      text['fallback'] = replacement['fallback'];
    }
    if (changed.contains(englishParameter)) {
      final translations = Map<String, dynamic>.from(
        text['translations'] as Map? ?? const {},
      )..remove('en');
      final english = (replacement['translations'] as Map?)?['en'];
      if (english != null) translations['en'] = english;
      if (translations.isEmpty) {
        text.remove('translations');
      } else {
        text['translations'] = translations;
      }
    }
    target[field] = text;
  }

  final oldResult = Map<String, dynamic>.from(result['result'] as Map);
  final newResult = Map<String, dynamic>.from(edited['result'] as Map);
  localize(oldResult, newResult, 'title', 'resultTitle', 'resultTitleEn');
  localize(oldResult, newResult, 'summary', 'resultSummary', 'resultSummaryEn');
  result['result'] = oldResult;
  final oldCredits = result['credits'];
  final newCredits = edited['credits'];
  if (newCredits == null) {
    result.remove('credits');
  } else if (oldCredits == null) {
    result['credits'] = newCredits;
  } else {
    final preserved = Map<String, dynamic>.from(oldCredits as Map);
    final replacement = Map<String, dynamic>.from(newCredits as Map);
    localize(preserved, replacement, 'title', 'creditsTitle', 'creditsTitleEn');
    localize(
      preserved,
      replacement,
      'endingLabel',
      'creditsEndingLabel',
      'creditsEndingLabelEn',
    );
    for (final entry in {
      'creditsAuthor': 'author',
      'creditsSkippable': 'skippable',
    }.entries) {
      if (changed.contains(entry.key)) {
        preserved[entry.value] = replacement[entry.value];
      }
    }
    result['credits'] = preserved;
  }
  return SceneFinishGameConsequence.fromJson(result);
}
