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
      final npc = MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: const MapEntityRuntimePredicate(
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
      expect(saved?.predicate?.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(saved?.predicate?.refId, 'step_intro_done');
    });

    test('hiddenWhen flag: round-trip', () {
      final npc = MapEntityNpcData(
        visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.hiddenWhen,
          predicate: const MapEntityRuntimePredicate(
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
      expect(saved?.predicate?.kind, MapEntityRuntimePredicateKind.storyFlagUnset);
    });
  });

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

    test('validateConditionalDialogueDrafts: dialogue sans cible -> erreur', () {
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

    test('validateConditionalDialogueDrafts: ligne vide (pas de dlg) -> ok', () {
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
