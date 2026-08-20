import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/gameplay/items/item_effect_editor.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_gameplay/map_gameplay.dart';

/// Effets non exécutables dans l'Item Studio — BETA-ITM-007.
///
/// Le critère « unsupported effect UI » du ticket, et il portait sur un vrai
/// risque produit : `repel` et `semanticAction` sont AUTHORABLES mais le runtime
/// les refuse avec `PlayerItemUseFailure.unsupportedCapability`. Un auteur
/// pouvait donc fabriquer une Repousse, la livrer, et ne le découvrir qu'au
/// premier playtest.
///
/// L'éditeur n'avait aucun test. Ces cas sont les premiers, et ils vérifient la
/// seule chose qui compte ici : l'éditeur dit la même chose que le moteur.

ProjectItemDefinition _itemWithEffect(ProjectItemEffectDefinition effect) {
  return ProjectItemDefinition(
    id: 'probe',
    displayName: 'Probe',
    pocketId: 'medicine',
    uses: <ProjectItemUseDefinition>[
      ProjectItemUseDefinition(
        contexts: <ProjectItemUseContext>{ProjectItemUseContext.overworld},
        target: ProjectItemTargetKind.partyMember,
        consumption: ProjectItemConsumptionPolicy.onApplied,
        effect: effect,
      ),
    ],
  );
}

Future<void> _pumpEditor(
  WidgetTester tester,
  ProjectItemEffectDefinition effect,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ItemEffectEditor(
            definition: _itemWithEffect(effect),
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

const Key _notice = Key('item-effect-overworld-unsupported-notice');

void main() {
  group('BETA-ITM-007 the Item Studio warns about unrunnable effects', () {
    testWidgets('a Repel effect is called out as outside the beta', (
      tester,
    ) async {
      await _pumpEditor(
        tester,
        const ProjectItemEffectDefinition.repel(steps: 100),
      );

      expect(find.byKey(_notice), findsOneWidget);
      final callout = tester.widget<PokeMapDiagnosticCallout>(
        find.byKey(_notice),
      );
      expect(callout.severity, PokeMapDiagnosticSeverity.warning);
      expect(callout.message, contains('sans effet en jeu'));
    });

    testWidgets('a semantic action effect is called out too', (tester) async {
      await _pumpEditor(
        tester,
        const ProjectItemEffectDefinition.semanticAction(
          actionId: 'open_secret_door',
        ),
      );

      expect(find.byKey(_notice), findsOneWidget);
    });

    testWidgets('a healing effect carries no warning at all', (tester) async {
      // Le contre-exemple. Sans lui, un bandeau affiché en permanence passerait
      // pour un avertissement correct.
      await _pumpEditor(
        tester,
        const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      );

      expect(find.byKey(_notice), findsNothing);
    });

    testWidgets('an unrunnable effect is recognisable in the dropdown itself', (
      tester,
    ) async {
      // Le libellé disait « Effet actuel », ce qui ne renseignait pas l'auteur.
      // Le bandeau ne suffit pas : la liste est ce qu'on lit en choisissant.
      await _pumpEditor(
        tester,
        const ProjectItemEffectDefinition.repel(steps: 100),
      );

      expect(find.textContaining('hors périmètre bêta'), findsWidgets);
    });
  });

  group('BETA-ITM-007 the editor and the runtime share one verdict', () {
    test('every effect the editor warns about is one the runtime refuses', () {
      // LA parité qui compte. L'éditeur ne doit pas avertir de son côté : il lit
      // le même prédicat que `applyPlayerItemEffect`, qui refuse à l'entrée.
      //
      // Les six sous-classes du modèle sont énumérées ici parce que
      // ProjectItemEffectDefinition n'est PAS sealed : le compilateur ne peut pas
      // exiger l'exhaustivité du prédicat, donc c'est ce test qui l'exige. En
      // ajouter une septième sans la classer fait échouer ce cas au lieu de la
      // laisser tomber dans le repli « inexécutable ».
      const effects = <ProjectItemEffectDefinition>[
        ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
        ProjectItemEffectDefinition.cureStatus(
          mode: ProjectItemStatusCureMode.all,
        ),
        ProjectItemEffectDefinition.revive(
          rateNumerator: 1,
          rateDenominator: 2,
        ),
        ProjectItemEffectDefinition.restorePp(
          mode: ProjectItemAmountMode.full,
        ),
        ProjectItemEffectDefinition.repel(steps: 100),
        ProjectItemEffectDefinition.semanticAction(actionId: 'probe'),
      ];

      expect(effects, hasLength(6), reason: 'one case per model subclass');

      for (final effect in effects) {
        final unsupported =
            projectItemEffectRuntimeSupport(effect) ==
            ProjectItemEffectRuntimeSupport.unsupported;
        final reason = projectItemEffectUnsupportedReason(effect);

        expect(
          reason != null,
          unsupported,
          reason: 'the warning and the verdict must agree for $effect',
        );

        final application = applyPlayerItemEffect(
          const PlayerPokemon(
            speciesId: 'probe',
            natureId: 'hardy',
            abilityId: 'none',
            level: 5,
            currentHp: 1,
          ),
          use: ProjectItemUseDefinition(
            contexts: <ProjectItemUseContext>{ProjectItemUseContext.overworld},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: effect,
          ),
          maxHp: 20,
          moveId: null,
          maxPpByMoveId: const <String, int>{},
        );

        if (unsupported) {
          expect(
            application.failure,
            PlayerItemUseFailure.unsupportedCapability,
            reason: 'the runtime must refuse what the editor warns about',
          );
        }
      }
    });
  });
}
