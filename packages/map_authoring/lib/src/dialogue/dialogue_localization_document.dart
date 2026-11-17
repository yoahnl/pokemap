import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import 'dialogue_document_identity.dart';
import 'dialogue_editor_model.dart';
import 'dialogue_yarn_codec.dart';

part 'dialogue_localization_mapping.dart';
part 'dialogue_runtime_localization.dart';

final class LocalizedDialogueDocument {
  const LocalizedDialogueDocument(this.document, this.localization);
  final DialogueEditorDocument document;
  final DialogueLocalization localization;
  String get source => emitDocumentToYarn(document);
}

final class ResolvedLocalizedDialogue {
  const ResolvedLocalizedDialogue(this.document);
  final DialogueEditorDocument document;
  String get source => emitDocumentToYarn(document);
}

LocalizedDialogueDocument readLocalizedDialogue({
  required String source,
  required String sourceLocale,
  DialogueLocalization? localization,
  String? entryNodeTitle,
}) {
  final document = reconcileDialogueDocumentIds(
      parseYarnToDocument(source, entryNodeTitle: entryNodeTitle));
  if (document.nodes.isEmpty) {
    throw const FormatException('The dialogue has no nodes.');
  }
  if (localization == null) {
    return writeLocalizedDialogue(document,
        previous: DialogueLocalization(sourceLocale: sourceLocale, units: []));
  }
  final byBinding = {for (final unit in localization.units) unit.binding: unit};
  final visited = <String>{};
  final bound = _mapDialogueTexts(document, (id, binding, kind, text) {
    final unit = byBinding[binding];
    if (unit == null || unit.kind != kind || unit.source != text) {
      throw FormatException(
          'Dialogue localization does not match its source at $binding.');
    }
    visited.add(unit.id);
    return (unit.id, text);
  });
  if (visited.length != localization.units.length) {
    throw const FormatException(
        'Dialogue localization contains unused text identities.');
  }
  return LocalizedDialogueDocument(bound, localization);
}

LocalizedDialogueDocument writeLocalizedDialogue(
  DialogueEditorDocument document, {
  required DialogueLocalization previous,
}) {
  final byId = {for (final unit in previous.units) unit.id: unit};
  final units = <DialogueTextUnit>[];
  final snapshot = _mapDialogueTexts(document, (id, binding, kind, text) {
    final old = byId[id];
    if (old != null && old.kind != kind) {
      throw ArgumentError('A dialogue text identity cannot change kind.');
    }
    units.add(old?.copyWith(binding: binding, source: text) ??
        DialogueTextUnit(id: id, binding: binding, kind: kind, source: text));
    return (id, text);
  });
  return LocalizedDialogueDocument(snapshot, previous.withUnits(units));
}

LocalizedDialogueDocument duplicateLocalizedDialogue(
    LocalizedDialogueDocument original) {
  final units = <DialogueTextUnit>[];
  final document =
      _mapDialogueTexts(original.document, (id, binding, kind, text) {
    final copied = newDialogueEditorId();
    units.add(original.localization
        .unit(id)
        .copyWith(id: copied, binding: binding, source: text));
    return (copied, text);
  }, independent: true);
  return LocalizedDialogueDocument(
      document, original.localization.withUnits(units));
}

ResolvedLocalizedDialogue resolveLocalizedDialogue(
  LocalizedDialogueDocument source, {
  required String preferredLocale,
  required Iterable<String> supportedLocales,
  required String fallbackLocale,
}) {
  final resolutions = source.localization.resolveAll(
      preferredLocale: preferredLocale,
      supportedLocales: supportedLocales,
      fallbackLocale: fallbackLocale);
  return ResolvedLocalizedDialogue(
      _mapDialogueTexts(source.document, (id, binding, kind, text) {
    final resolved = resolutions[id]!;
    return (id, resolved.text);
  }));
}

void validateDialogueLocalizationSource(
    DialogueLocalization localization, String source) {
  readLocalizedDialogue(
      source: source,
      sourceLocale: localization.sourceLocale,
      localization: localization);
}
