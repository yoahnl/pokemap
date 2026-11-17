import 'dart:convert';

import 'package:map_authoring/map_authoring_narrative.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../../story_draft/domain/story_dialogue_source.dart';
import '../../story_draft/domain/story_draft_entry.dart';
import '../domain/narrative_index_port.dart';

typedef GameMemoryFactUse = ({String factId, NarrativeOwner owner});

NarrativeOwnerKind gameMemoryOwnerKind(StoryDraftKind<Object> kind) =>
    switch (kind) {
      StoryDraftKind.event => NarrativeOwnerKind.event,
      StoryDraftKind.scene => NarrativeOwnerKind.scene,
      StoryDraftKind.story => NarrativeOwnerKind.storyline,
      StoryDraftKind.worldRule => NarrativeOwnerKind.worldRule,
      StoryDraftKind.dialogue => NarrativeOwnerKind.dialogue,
      _ => throw ArgumentError.value(kind),
    };

Set<GameMemoryFactUse> gameMemoryOwnerUsages(StoryDraftRef ref, Object? value) {
  if (value == null) return const {};
  final kind = gameMemoryOwnerKind(ref.kind);
  if (value is StoryDialogueSource) {
    final RuntimeDialogueDocument document;
    if (value.relativePath.toLowerCase().endsWith('.json')) {
      document = const RuntimeDialogueDocumentCodec().decodeUtf8(
        utf8.encode(value.source),
      );
    } else {
      final compiled = const DialogueAuthoringCompiler().compile(
        entry: value.entry,
        source: value.source,
      );
      if (!compiled.canPublish || compiled.document == null) {
        throw const FormatException('Unsupported dialogue');
      }
      document = compiled.document!;
    }
    final ids = dialogueDocumentFactIds(document);
    if (value.entry.localization case final localization?) {
      readLocalizedDialogue(
        source: value.source,
        sourceLocale: localization.sourceLocale,
        localization: localization,
        entryNodeTitle: value.entry.defaultStartNode,
      );
      for (final unit in localization.units) {
        ids.addAll(dialogueTextFactIds(unit.source));
        for (final translation in unit.translations.values) {
          ids.addAll(dialogueTextFactIds(translation.text));
        }
      }
    }
    return {
      for (final id in ids)
        (
          factId: id,
          owner: NarrativeOwner(
            kind: kind,
            id: ref.id,
            role: NarrativeFactRole.read,
          ),
        ),
    };
  }
  final analysed = switch (value) {
    NarrativeEventRecord() => CatalogNarrativeOwnerAnalysis.ofEvent(value),
    SceneAsset() => CatalogNarrativeOwnerAnalysis.ofDefinition(
      'scenes',
      value.toJson(),
    ),
    WorldRuleDefinition() => CatalogNarrativeOwnerAnalysis.ofDefinition(
      'worldRules',
      value.toJson(),
    ),
    StorylineAsset() => CatalogNarrativeOwnerAnalysis.ofDefinition(
      'storylines',
      value.toJson(),
    ),
    _ => throw ArgumentError.value(value),
  };
  return {
    for (final use in analysed.facts)
      (
        factId: use.factId,
        owner: NarrativeOwner(
          kind: kind,
          id: ref.id,
          role: switch (use.role) {
            'read' => NarrativeFactRole.read,
            'write' => NarrativeFactRole.write,
            _ => null,
          },
        ),
      ),
  };
}
