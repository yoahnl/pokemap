part of 'dialogue_localization_document.dart';

DialogueLocalization compileRuntimeDialogueLocalization({
  required String source,
  required RuntimeDialogueDocument document,
  required DialogueLocalization localization,
}) {
  final opened = readLocalizedDialogue(
      source: source,
      sourceLocale: localization.sourceLocale,
      localization: localization);
  final ordered = <DialogueTextUnit>[];
  final byId = {for (final unit in localization.units) unit.id: unit};
  _mapDialogueTexts(opened.document, (id, binding, kind, text) {
    ordered.add(byId[id]!);
    return (id, text);
  });
  final encoded = jsonEncode(document.toJson());
  var nonce = 0;
  while (encoded.contains('__AVELUNE_TEXT_${nonce}_')) {
    nonce++;
  }
  final markers = {
    for (final (index, unit) in ordered.indexed)
      unit.id: '__AVELUNE_TEXT_${nonce}_${index}__',
  };
  final marked = _mapDialogueTexts(
      opened.document, (id, binding, kind, text) => (id, markers[id]!));
  final probe =
      const YarnDialogueCompiler().compile(emitDocumentToYarn(marked));
  if (jsonEncode(runtimeDialogueTextShape(document)) !=
      jsonEncode(runtimeDialogueTextShape(probe))) {
    throw const FormatException(
        'Dialogue text projection changed the compiled structure.');
  }
  final originals = {
    for (final scope in runtimeDialogueTextScopes(document))
      scope.binding: scope,
  };
  final pattern = RegExp('__AVELUNE_TEXT_${nonce}_(\\d+)__');
  final visited = <String>{};
  final units = <DialogueTextUnit>[];
  for (final scope in runtimeDialogueTextScopes(probe)) {
    final matches = pattern.allMatches(scope.text).toList();
    if (matches.length != 1) {
      throw const FormatException(
          'A compiled text must identify exactly one source text.');
    }
    final match = matches.single;
    final index = int.parse(match.group(1)!);
    if (index >= ordered.length) {
      throw const FormatException('Unknown compiled dialogue text identity.');
    }
    final unit = ordered[index];
    final original = originals[scope.binding]!;
    final prefix = scope.text.substring(0, match.start);
    final suffix = scope.text.substring(match.end);
    if (!visited.add(unit.id) ||
        original.text != '$prefix${unit.source}$suffix') {
      throw const FormatException(
          'Compiled dialogue source text is not preserved.');
    }
    units.add(DialogueTextUnit(
      id: unit.id,
      binding: scope.binding,
      kind: unit.kind,
      source: original.text,
      translations: {
        for (final entry in unit.translations.entries)
          entry.key: DialogueTranslation(
            text: '$prefix${entry.value.text}$suffix',
            source: '$prefix${entry.value.source}$suffix',
          ),
      },
    ));
  }
  if (visited.length != localization.units.length) {
    throw const FormatException(
        'Unused source text identities after dialogue compilation.');
  }
  final result = DialogueLocalization(
      sourceLocale: localization.sourceLocale, units: units);
  validateRuntimeDialogueLocalization(document, result);
  return result;
}
