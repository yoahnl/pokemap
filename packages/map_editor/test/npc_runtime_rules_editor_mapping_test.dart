import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart';
import 'package:map_editor/src/features/map_entities/application/npc_runtime_rules_editor_mapping.dart';

void main() {
  group('parseVisibilityRuleFromNpc / buildVisibilityRuleForSave', () {
    test('always: null rule -> always mode; save -> null', () {
      const npc = MapEntityNpcData();
      final parsed = parseVisibilityRuleFromNpc(npc);
      expect(parsed.mode, NpcRuntimeVisibilityUiMode.always);
      expect(
        buildVisibilityRuleForSave(
          uiMode: parsed.mode,
          predicateKind: parsed.kind,
          refMenuId: parsed.refId,
        ),
        isNull,
      );
    });

    test('visibleWhen step: round-trip', () {
      const npc = MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.stepCompleted,
            refId: 'step_intro_done',
          ),
        ),
      );
      final parsed = parseVisibilityRuleFromNpc(npc);
      expect(parsed.mode, NpcRuntimeVisibilityUiMode.visibleOnlyIf);
      expect(parsed.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(parsed.refId, 'step_intro_done');

      final saved = buildVisibilityRuleForSave(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: parsed.refId,
      );
      expect(saved?.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(
          saved?.predicate?.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(saved?.predicate?.refId, 'step_intro_done');
    });

    test('hiddenWhen flag: round-trip', () {
      const npc = MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: MapEntityRuntimePredicate(
            kind: MapEntityRuntimePredicateKind.storyFlagUnset,
            refId: 'boss_defeated',
          ),
        ),
      );
      final parsed = parseVisibilityRuleFromNpc(npc);
      expect(parsed.mode, NpcRuntimeVisibilityUiMode.hiddenIf);
      final saved = buildVisibilityRuleForSave(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: parsed.refId,
      );
      expect(saved?.mode, MapEntityNpcVisibilityMode.hiddenWhen);
      expect(
          saved?.predicate?.kind, MapEntityRuntimePredicateKind.storyFlagUnset);
    });
  });

  test('time visibility preserves the window without a reference', () {
    const npc = MapEntityNpcData(
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.hiddenWhen,
        predicate: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.localTimeWindow,
          timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 240),
        ),
      ),
    );
    final parsed = parseVisibilityRuleFromNpc(npc);
    expect(parsed.timeWindow, npc.visibilityRule!.predicate!.timeWindow);
    expect(
      validateNpcVisibilityDraft(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: kNpcRuntimeRefNoneMenuId,
        timeWindow: parsed.timeWindow,
      ),
      isNull,
    );
    expect(
      buildVisibilityRuleForSave(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: kNpcRuntimeRefNoneMenuId,
        timeWindow: parsed.timeWindow,
      ),
      npc.visibilityRule,
    );
    expect(
      validateNpcVisibilityDraft(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: kNpcRuntimeRefNoneMenuId,
        timeWindow: const LocalTimeWindow(startMinute: 240, endMinute: 240),
      ),
      isNotNull,
    );
    expect(
      buildVisibilityRuleForSave(
        uiMode: NpcRuntimeVisibilityUiMode.always,
        predicateKind: parsed.kind,
        refMenuId: '',
        timeWindow: parsed.timeWindow,
      ),
      isNull,
    );
  });

  test('party predicates retain their threshold during unrelated edits', () {
    const predicate = MapEntityRuntimePredicate(
      kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast,
      minimumCount: 2,
    );
    const npc = MapEntityNpcData(
      visibilityRule: MapEntityNpcVisibilityRule(
        mode: MapEntityNpcVisibilityMode.visibleWhen,
        predicate: predicate,
      ),
    );
    final parsed = parseVisibilityRuleFromNpc(npc);
    expect(parsed.minimumCount, 2);
    expect(
      buildVisibilityRuleForSave(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: kNpcRuntimeRefNoneMenuId,
        minimumCount: parsed.minimumCount,
      ),
      npc.visibilityRule,
    );
    expect(
      validateNpcVisibilityDraft(
        uiMode: parsed.mode,
        predicateKind: parsed.kind,
        refMenuId: kNpcRuntimeRefNoneMenuId,
        minimumCount: parsed.minimumCount,
      ),
      isNull,
    );
    const row = MapEntityConditionalDialogue(
      when: predicate,
      dialogue: DialogueRef(dialogueId: 'refusal', startNode: 'Start'),
    );
    expect(
      buildConditionalDialogueRowForSave(
        conditionKind: row.when.kind,
        refMenuId: kNpcRuntimeRefNoneMenuId,
        dialogueId: row.dialogue.dialogueId,
        startNode: row.dialogue.startNode,
        minimumCount: row.when.minimumCount,
      ),
      row,
    );
    expect(
      validateConditionalDialogueDrafts(
        rows: [(dialogueMenuId: 'refusal', refMenuId: kNpcRuntimeRefNoneMenuId)],
        dialogueNoneId: '__none__',
        predicateKinds: [row.when.kind],
        minimumCounts: [row.when.minimumCount],
      ),
      isNull,
    );
  });

  test(
    'conditional time dialogue retains path, start node and midnight window',
    () {
      const original = MapEntityConditionalDialogue(
        when: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.localTimeWindow,
          timeWindow: LocalTimeWindow(startMinute: 1200, endMinute: 1440),
        ),
        dialogue: DialogueRef(
          dialogueId: 'guard',
          scriptPathRelative: 'dialogues/guard.yarn',
          startNode: 'Night',
        ),
      );
      expect(
        validateConditionalDialogueDrafts(
          rows: [
            (dialogueMenuId: 'guard', refMenuId: kNpcRuntimeRefNoneMenuId),
          ],
          dialogueNoneId: '__none__',
          predicateKinds: [original.when.kind],
          timeWindows: [original.when.timeWindow],
        ),
        isNull,
      );
      expect(
        validateConditionalDialogueDrafts(
          rows: [
            (dialogueMenuId: 'guard', refMenuId: kNpcRuntimeRefNoneMenuId),
          ],
          dialogueNoneId: '__none__',
          predicateKinds: [original.when.kind],
          timeWindows: const [LocalTimeWindow(startMinute: 10, endMinute: 10)],
        ),
        isNotNull,
      );
      expect(
        buildConditionalDialogueRowForSave(
          conditionKind: original.when.kind,
          refMenuId: kNpcRuntimeRefNoneMenuId,
          dialogueId: original.dialogue.dialogueId,
          startNode: original.dialogue.startNode,
          scriptPathRelative: original.dialogue.scriptPathRelative,
          timeWindow: original.when.timeWindow,
        ),
        original,
      );
    },
  );

  group('validateNpcVisibilityDraft', () {
    test('always: ok même sans cible', () {
      expect(
        validateNpcVisibilityDraft(
          uiMode: NpcRuntimeVisibilityUiMode.always,
          refMenuId: kNpcRuntimeRefNoneMenuId,
        ),
        isNull,
      );
    });

    test('conditionnel sans cible: erreur', () {
      expect(
        validateNpcVisibilityDraft(
          uiMode: NpcRuntimeVisibilityUiMode.visibleOnlyIf,
          refMenuId: kNpcRuntimeRefNoneMenuId,
        ),
        isNotNull,
      );
    });
  });

  group('conditional dialogues save helpers', () {
    test('buildConditionalDialogueRowForSave reproduit le modèle', () {
      const original = MapEntityConditionalDialogue(
        when: MapEntityRuntimePredicate(
          kind: MapEntityRuntimePredicateKind.chapterCompleted,
          refId: 'ch1',
        ),
        dialogue: DialogueRef(
          dialogueId: 'dlg_shop',
          startNode: 'Start',
        ),
      );
      final built = buildConditionalDialogueRowForSave(
        conditionKind: original.when.kind,
        refMenuId: original.when.refId,
        dialogueId: original.dialogue.dialogueId,
        startNode: original.dialogue.startNode,
      );
      expect(built, original);
    });

    test('sans dialogue choisi -> null (ligne ignorée à la sauvegarde)', () {
      expect(
        buildConditionalDialogueRowForSave(
          conditionKind: MapEntityRuntimePredicateKind.storyFlagSet,
          refMenuId: 'f',
          dialogueId: '',
        ),
        isNull,
      );
    });

    test('validateConditionalDialogueDrafts: dialogue sans cible -> erreur',
        () {
      expect(
        validateConditionalDialogueDrafts(
          rows: [
            (
              dialogueMenuId: 'some_dlg',
              refMenuId: kNpcRuntimeRefNoneMenuId,
            ),
          ],
          dialogueNoneId: '__dialogue_none__',
        ),
        isNotNull,
      );
    });

    test('validateConditionalDialogueDrafts: ligne vide (pas de dlg) -> ok',
        () {
      expect(
        validateConditionalDialogueDrafts(
          rows: [
            (
              dialogueMenuId: '__dialogue_none__',
              refMenuId: kNpcRuntimeRefNoneMenuId,
            ),
          ],
          dialogueNoneId: '__dialogue_none__',
        ),
        isNull,
      );
    });
  });

  group('non-régression: sauvegarde logique ne vide pas les règles', () {
    test('reconstruire npc depuis état « formulaire » équivalent', () {
      final visibility = buildVisibilityRuleForSave(
        uiMode: NpcRuntimeVisibilityUiMode.visibleOnlyIf,
        predicateKind: MapEntityRuntimePredicateKind.cutsceneCompleted,
        refMenuId: 'local_cut_1',
      );
      final rows = <MapEntityConditionalDialogue>[
        buildConditionalDialogueRowForSave(
          conditionKind: MapEntityRuntimePredicateKind.stepNotCompleted,
          refMenuId: 's_a',
          dialogueId: 'd1',
          startNode: null,
        )!,
      ];
      final npc = MapEntityNpcData(
        visibilityRule: visibility,
        conditionalDialogues: rows,
      );

      final again = parseVisibilityRuleFromNpc(npc);
      final vis2 = buildVisibilityRuleForSave(
        uiMode: again.mode,
        predicateKind: again.kind,
        refMenuId: again.refId,
      );
      expect(vis2, npc.visibilityRule);

      final row0 = npc.conditionalDialogues.first;
      final rebuilt = buildConditionalDialogueRowForSave(
        conditionKind: row0.when.kind,
        refMenuId: row0.when.refId,
        dialogueId: row0.dialogue.dialogueId,
        startNode: row0.dialogue.startNode,
      );
      expect(rebuilt, row0);
    });
  });
}
