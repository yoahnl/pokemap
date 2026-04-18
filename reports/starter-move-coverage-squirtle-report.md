# Starter Move Coverage — Squirtle / Carapuce

## 1. Résumé exécutif honnête

Mini lot réussi, mais pas au sens maximaliste “4 moves visibles quoi qu'il arrive”.

Diagnostic réel :
- `tail_whip` était déjà honnêtement exécutable côté moteur/bridge, mais pouvait être sous-déclaré à cause d'une mauvaise lecture du champ Showdown `zMove` dans le pipeline de conversion.
- `withdraw` était dans la même famille que `tail_whip` : la mécanique locale est déjà supportée, mais certains catalogues convertis pouvaient le dégrader à tort en `structuredPartial` pour une mauvaise raison.
- `water_gun` était déjà un contrôle sain : aucun patch moteur n'était nécessaire.
- `bubble` ne peut pas encore être rendu honnêtement jouable dans ce mini lot, parce que son vrai comportement utile repose sur un rider probabiliste de baisse de Vitesse, et ce contrat n'existe pas encore honnêtement dans le bridge battle local.

Décision retenue :
- corriger la vérité source au niveau du converter Showdown ;
- autoriser au bridge uniquement le sous-cas legacy `structuredPartial + unsupported_mechanic:zMove` quand la forme réelle du move est déjà un `modifyStats` déterministe supporté ;
- garder `bubble` explicitement non bridgeable ;
- verrouiller le résultat produit par tests : Squirtle voit `tail_whip`, `water_gun`, `withdraw` en combat, mais pas `bubble`.

Conclusion nette :
- le mini lot est **réussi** ;
- **Squirtle n'a pas 4 moves en combat honnêtement après ce passage** ;
- il en a **3/4** (`tail_whip`, `water_gun`, `withdraw`) ;
- `bubble` reste bloqué honnêtement car son rider probabiliste n'est pas encore dans le contrat supporté.

## 2. Pré-gates réellement exécutés + résultats

Pré-gates read-only exécutés au début du passage, dans une seule invocation shell groupée qui contenait exactement les trois commandes demandées.

Commandes exécutées :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat réellement observé au début :

- `git status --short --untracked-files=all` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie

Interprétation :
- le repo était **propre** au début de ce mini lot ;
- contrairement à l'hypothèse prudente du prompt, il n'y avait pas de reste dirty de `R1` / fermeture `R1` / `R2` au moment exact du départ ;
- j'ai traité cet état comme baseline réelle.

## 3. État git initial exact et interprétation

État initial exact : worktree clean.

Conséquence méthodologique :
- aucun reset requis ;
- aucune ambiguïté sur la provenance des modifications de ce mini lot ;
- toutes les modifications listées en fin de report proviennent de ce passage.

## 4. Méthode réellement suivie

Mini passage en 5 temps :

1. pré-gates read-only ;
2. audit ciblé catalogue -> converter -> bridge -> filtering -> battle execution ;
3. classification explicite des sujets move par move ;
4. implémentation minimale bornée ;
5. validations ciblées + review séparée.

Compétences/plugins réellement mobilisés :
- `Superpowers` : `using-superpowers`, `brainstorming`, `dispatching-parallel-agents`, `verification-before-completion`
- `Game Studio` : usage orientant le raisonnement produit/runtime, sans playtest navigateur car le symptôme était d'abord un problème de truth/bridge/catalog

Sub-agents réellement utilisés :
- `Laplace` : audit support-truth / catalogue
- `Pasteur` : audit runtime bridge / filtering
- `Dirac` : audit battle-execution minimal
- `Huygens` : review séparée finale

## 5. Périmètre inclus / exclu

Inclus :
- vérité support réelle de `tail_whip`, `withdraw`, `bubble`, `water_gun`
- convertisseur Showdown -> catalogue local
- bridge runtime -> battle
- tests runtime / converter pour verrouiller le résultat produit ciblé

Exclus volontairement :
- `R3` condition lifecycle large
- widening request / targeting / replacement
- `Struggle`
- abilities / items / doubles
- docs canoniques larges
- patch moteur battle pour ouvrir un vrai rider probabiliste de baisse de stat

## 6. Classification initiale des sujets

- vérité support `tail_whip` : `required_now`
- vérité support `withdraw` : `required_now`
- vérité support `bubble` : `required_now`
- vérité support `water_gun` : `document_now_only`
- filtering runtime/bridge de ces moves : `required_now`
- éventuel patch battle strictement nécessaire : `defer_not_this_pass`
- éventuelle mise à jour de catalogue / converter : `required_now`
- éventuelle mise à jour doc canonique : `document_now_only`
- test produit ciblé Squirtle en combat : `required_now`

## 7. Fichiers lus

Docs canoniques :
- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/r1-battleable-slice-hardening-report.md`
- `reports/r1-closure-polish-report.md`
- `reports/r2-scheduler-consolidation-report.md`

Runtime / bridge :
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

Battle core strictement utile :
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_move_effects_test.dart`

Host / produit :
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- `examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- `examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`
- `examples/playable_runtime_host/golden_battle_slice/project.json`
- `examples/playable_runtime_host/golden_battle_slice/data/pokemon/catalogs/moves.json`

Catalogue / conversion / fixtures :
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/test/showdown_move_catalog_converter_test.dart`
- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`
- `packages/map_editor/test/fixtures/manual_pokemon_import_pack_10/learnsets/squirtle.json`

Showdown local :
- `pokemon-showdown-master/data/moves.ts`

## 8. Diagnostic réel par move cible

### `tail_whip`

1. Le moteur battle sait déjà le porter honnêtement ?
- Oui.
- C'est un `modifyStats` déterministe sur la cible.
- Comparateurs locaux honnêtes : `growl`, `leer`.

2. Le bridge runtime -> battle sait déjà le projeter honnêtement ?
- Oui, si le move arrive avec une truth correcte.

3. Le vrai problème venait-il surtout de la vérité support ?
- Oui.
- Le converter pouvait dégrader à tort `tail_whip` à cause du champ top-level Showdown `zMove`, qui ne décrit pas le move de base local.

4. Décision finale
- Corrigé maintenant.

### `withdraw`

1. Le moteur battle sait déjà le porter honnêtement ?
- Oui.
- C'est un `modifyStats` déterministe sur soi.
- Comparateur local honnête : `swords_dance`.

2. Le bridge runtime -> battle sait-il le projeter honnêtement ?
- Oui sur le fond mécanique.
- Non pas toujours sur les vieux catalogues si le label `structuredPartial` venait uniquement de `zMove`.

3. Le vrai problème venait-il surtout de la vérité support / gate bridge ?
- Oui.

4. Décision finale
- Corrigé maintenant.

### `bubble`

1. Le moteur battle sait-il déjà le porter honnêtement aujourd'hui ?
- Non, pas complètement.
- Le dégât standard existe, mais le rider utile Showdown est une baisse de Vitesse à 10%.
- Le moteur/bridge local ne porte pas encore honnêtement les `modifyStats` probabilistes.

2. Le bridge runtime -> battle sait-il déjà le projeter honnêtement ?
- Non.
- Il le refuse explicitement quand il voit `chance` sur `modifyStats`.

3. Le problème est-il seulement un label faux ?
- Non.
- Il y avait bien aussi un problème de label, mais dans l'autre sens : le converter pouvait faire croire que `bubble` était déjà `structuredSupported` alors que le bridge ne pouvait pas le projeter honnêtement.

4. Comparateur proche
- `bubble_beam` porte le même rider Showdown de baisse de Vitesse à 10%.
- Les deux doivent donc rester hors support honnête complet dans ce mini lot.

5. Décision finale
- Vérité corrigée maintenant.
- Support gameplay complet différé hors de ce mini lot.

### `water_gun`

1. Le moteur battle sait-il déjà le porter honnêtement ?
- Oui.

2. Le bridge runtime -> battle sait-il déjà le projeter honnêtement ?
- Oui.

3. Le problème venait-il de lui ?
- Non.
- `water_gun` sert de contrôle sain / baseline.

4. Décision finale
- Aucun patch fonctionnel requis.
- Contrôle conservé par tests produit.

## 9. Stratégie retenue

Goulot réel identifié : mix de deux problèmes distincts.

1. problème de vérité source :
- `tail_whip` / `withdraw` pouvaient être déclassés à tort par la présence de `zMove` ;
- `bubble` / `bubble_beam` pouvaient au contraire être sur-vendus comme déjà bridgeables alors que leur rider probabiliste ne l'est pas.

2. problème runtime legacy ciblé :
- certains catalogues déjà convertis peuvent encore contenir des `structuredPartial` causés uniquement par `zMove` ;
- le bridge devait donc tolérer ce sous-cas legacy, mais seulement si la forme réelle du move est déjà honnêtement exécutable.

Stratégie retenue, unique et minimale :
- corriger le converter ;
- resserrer le bridge sur une tolérance `zMove` ultra bornée ;
- prouver le résultat produit sur un Squirtle de fixture ;
- ne pas toucher `map_battle`.

## 10. Décisions retenues / rejetées sujet par sujet

### Décisions retenues

- Ignorer `zMove` comme métadonnée top-level côté converter.
- Marquer explicitement `probabilistic_modify_stats` comme unsupported reason côté converter.
- Autoriser côté bridge seulement les `structuredPartial` dont la seule raison est `unsupported_mechanic:zMove` **et** dont la forme réelle est un `modifyStats` déterministe `self/target`.
- Ajouter un test produit Squirtle prouvant que `tail_whip`, `water_gun`, `withdraw` apparaissent en combat, mais pas `bubble`.

### Décisions rejetées

- Implémenter `bubble` en ignorant son rider.
- Réétiqueter `bubble` en `structuredSupported` “pour débloquer l'UI combat”.
- Toucher `map_battle` pour ajouter un mini contrat chance-based stat drop.
- Modifier la doc canonique large : la vérité structurelle n'a pas changé, seulement la vérité support locale sur ce lot.

## 11. Justification précise des fichiers modifiés

### `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`

Pourquoi :
- c'est la vraie source de vérité du passage Showdown -> catalogue local ;
- le faux négatif `zMove` et le faux positif `bubble` naissaient ici.

Type de modification :
- recadrage honnête du support level ;
- aucun élargissement mécanique du moteur.

### `packages/map_editor/test/showdown_move_catalog_converter_test.dart`

Pourquoi :
- verrouiller les deux corrections de vérité au bon seam source.

### `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

Pourquoi :
- réparer le cas legacy `structuredPartial + zMove-only` pour des moves déjà réellement bridgeables ;
- empêcher que ce correctif ne rouvre des no-op status comme `teleport`.

### `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

Pourquoi :
- verrouiller `withdraw` bridgeable et `bubble` toujours refusé.

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

Pourquoi :
- prouver le résultat observable de combat sur un vrai setup runtime, pas seulement au niveau du bridge unitaire.

## 12. Justification des fichiers volontairement non touchés

- `packages/map_battle/**` : volontairement non touchés, car le moteur supporte déjà `tail_whip` / `withdraw` / `water_gun` et ne supporte pas encore honnêtement `bubble`.
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart` : non touché, car le filtering existant était déjà honnête ; il avait besoin d'un meilleur input truth/bridge, pas d'une rustine.
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` : non touché, même raison.
- docs canoniques : non touchées, car la vérité structurelle du repo ne change pas ; seul un mini lot de support truth local est corrigé.
- golden slice host data : non touché, car le golden slice repo ne porte pas ces moves Squirtle ; mentir en le modifiant “pour la démo” aurait brouillé la vérité produit.

## 13. Validations réellement relancées

### Relancées

`map_editor` ciblé :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub \
  lib/src/application/services/showdown_move_catalog_converter.dart \
  test/showdown_move_catalog_converter_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test \
  test/showdown_move_catalog_converter_test.dart
```

`map_runtime` ciblé :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/battle_overlay_component_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/battle_overlay_component_test.dart
```

Host :

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

### Non relancées volontairement

- `packages/map_battle && dart analyze`
- `packages/map_battle && dart test`

Justification :
- aucun fichier `map_battle` n'a été modifié ;
- ce mini lot a explicitement choisi de **ne pas** ouvrir le moteur pour `bubble` ;
- relancer battle complet ici aurait surtout coché une case sans signal additionnel proportionné.

## 14. Résultats réellement obtenus

- `map_editor flutter analyze` : vert
- `map_editor flutter test showdown_move_catalog_converter_test.dart` : vert
- `map_runtime flutter analyze` ciblé : vert
- `map_runtime flutter test` ciblé : vert
- `examples/playable_runtime_host flutter test` ciblé : vert

Résultat produit verrouillé par test :
- Squirtle de fixture avec `tail_whip`, `water_gun`, `withdraw`, `bubble`
- expose en combat : `tail_whip`, `water_gun`, `withdraw`
- n'expose pas `bubble`
- ceci est volontaire et honnête

## 15. Incidents rencontrés

- `flutter analyze` sur `map_runtime` a d'abord signalé deux `unnecessary_const` dans les nouveaux tests. Correction immédiate, puis analyse verte.
- le premier `wait_agent` du reviewer a timeout sans résultat ; la seconde attente a renvoyé la review complète.

## 16. Retour des sub-agents

### Laplace — support truth / catalog audit

Retenu :
- `tail_whip` / `withdraw` étaient des faux partiels liés à `zMove`.
- `bubble_beam` révélait que `bubble` n'était pas un simple oubli de label.

### Pasteur — runtime bridge / filtering

Retenu :
- le goulot n'était pas `runtime_battle_setup_mapper.dart` ;
- le filtering du seed builder était déjà honnête ;
- il fallait réaligner le truth et la gate bridge.

### Dirac — battle execution minimal

Retenu partiellement :
- correct sur `tail_whip`, `withdraw`, `water_gun`.

Rejeté partiellement :
- son intuition “Bubble est proche donc probablement supportable” n'a pas été suivie, car elle sous-estimait le vrai rider probabiliste Showdown.

## 17. Retour du reviewer séparé

Reviewer : `Huygens`

Findings retenus :
- aucun finding bloquant sur le mini lot.
- la correction converter est honnête : `zMove` devient bien une métadonnée ignorée, et `probabilistic_modify_stats` reste un vrai motif de partial.
- le bridge ne dérive pas vers `R3` : seuls les partials `zMove` dont la forme réelle est déjà un `modifyStats` déterministe passent.
- le test produit Squirtle est jugé honnête : `bubble` n'apparaît pas en combat, donc pas de faux support visuel.

Réserve résiduelle retenue :
- il n'existe pas un test unique “sortie réelle du converter -> runtime complet -> combat choice” ;
- ce n'est pas bloquant pour ce lot, mais c'est le seul angle mort résiduel identifié.

## 18. Critique explicite du prompt lui-même

### Parties utiles

- insister sur la vérité du code réel plutôt que sur les screenshots ;
- exiger une décision par move ;
- interdire le faux support ;
- interdire la dérive vers `R3`.

### Parties discutables

- l'expression “retrouve le ou les fichiers réels du catalogue moves consommés par le playable host / golden slice / projet courant” suppose qu'un projet Squirtle battle-ready existe dans le repo. Ce n'est pas le cas :
  - le golden slice versionné ne contient pas ces moves ;
  - le host démo Squirtle reste une fixture synthétique ;
  - il a donc fallu raisonner honnêtement à partir des seams repo réels, pas à partir d'un “projet courant Squirtle” versionné qui n'existe pas dans l'arbre.

### Parties trop rigides

- la liste de “fichiers probablement autorisés” n'incluait pas explicitement le converter Showdown côté `map_editor`, alors que c'était le plus petit vrai point de vérité à corriger.

### Ce que j'ai volontairement resserré

- j'ai refusé d'ouvrir un patch battle pour `bubble` ;
- j'ai refusé de toucher la doc canonique ;
- j'ai refusé de modifier le golden slice.

Pourquoi :
- ces trois directions auraient soit sur-vendu le support, soit dérivé vers une autre phase.

## 19. Autocritique finale

Ce que je n'ai pas pu prouver depuis le repo seul :
- un vrai projet utilisateur externe au repo où Squirtle menu + combat reproduit exactement le symptôme UI initial.

Ce que j'ai néanmoins pu prouver honnêtement :
- la vérité technique des quatre moves ciblés ;
- la correction du pipeline source ;
- la correction du bridge legacy ;
- le résultat produit ciblé via fixture Squirtle runtime.

Ce qui reste hors scope mais réel :
- supporter `bubble` honnêtement exigera au minimum un seam local pour `modifyStats` probabiliste côté battle/bridge ;
- ce n'est pas encore un gros `R3`, mais ce n'est déjà plus ce mini lot.

## 20. État git final utile

```text
 M packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
 M packages/map_editor/test/showdown_move_catalog_converter_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? reports/starter-move-coverage-squirtle-report.md
```

`git diff --stat` final :

```text
 .../services/showdown_move_catalog_converter.dart  |  22 +++
 .../test/showdown_move_catalog_converter_test.dart | 157 ++++++++++++++++
 .../application/runtime_battle_move_bridge.dart    |  86 ++++++++-
 .../test/runtime_battle_move_bridge_test.dart      | 108 +++++++++++
 .../test/runtime_battle_setup_mapper_test.dart     | 199 +++++++++++++++++++++
 5 files changed, 571 insertions(+), 1 deletion(-)
```

`git ls-files --others --exclude-standard` final :

```text
reports/starter-move-coverage-squirtle-report.md
```

## 21. Checklist finale

- ai-je évité de transformer ce mini lot en `R3` ? oui
- ai-je gardé le périmètre très ciblé ? oui
- ai-je audité la vérité support réelle des 4 moves visés ? oui
- ai-je corrigé un vrai problème de support truth / bridge si c’était bien le cas ? oui
- ai-je évité de relabeler mensongèrement un move ? oui
- ai-je évité de faire apparaître un move non exécutable ? oui
- ai-je réellement relancé les validations utiles ? oui
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? oui
- ai-je inclus le contenu complet de tous les fichiers touchés ? oui, sauf le report lui-même pour éviter la récursion absurde
- ai-je évité toute écriture Git interdite ? oui

## 22. Décision finale nette

- ce mini lot est-il réussi ou non ? **oui**
- Squirtle a-t-il désormais ses 4 moves en combat honnêtement ou non ? **non**
- lesquels restent bloqués et pourquoi ? **`bubble` seulement**, parce que son rider probabiliste de baisse de Vitesse n'est pas encore porté honnêtement par le contrat runtime -> battle local

Formulation la plus honnête :
- `tail_whip` : oui
- `withdraw` : oui
- `water_gun` : oui
- `bubble` : non, volontairement filtré tant que le repo ne sait pas l'exécuter honnêtement

## 23. Contenu complet de TOUS les fichiers modifiés/créés/supprimés

Le report lui-même n'est pas recopié ici en entier pour éviter une récursion absurde. Tous les autres fichiers touchés sont recopiés ci-dessous intégralement.

### `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit un snapshot Showdown `moves.json` vers le catalogue local `moves`.
///
/// M3 change volontairement la nature de la sortie :
/// - on ne produit plus un petit JSON ad hoc de catalogue "lisible" ;
/// - on construit de vrais objets `PokemonMove` du modèle canonique `map_core` ;
/// - puis on sérialise `PokemonMove.toJson()` dans `PokemonCatalogFile.entries`.
///
/// Cette décision borne proprement la suite :
/// - le convertisseur reste l'unique pipeline Showdown -> projet ;
/// - la normalisation du modèle canonique protège la sortie ;
/// - `map_editor` ne crée aucune structure parallèle ;
/// - `map_battle` ne lit toujours pas le JSON projet brut.
class ShowdownMoveCatalogConverter {
  const ShowdownMoveCatalogConverter();

  /// Produit un [PokemonCatalogFile] moves complet à partir du snapshot brut.
  ///
  /// Invariants M3 :
  /// - les entrées sont triées par id pour garder des diffs stables ;
  /// - chaque entrée provient d'un vrai `PokemonMove` ;
  /// - les limites de conversion sont matérialisées dans :
  ///   - `engineSupportLevel`
  ///   - `unsupportedReasons`
  ///   - `sourceRefs.showdownHooksPresent`
  PokemonCatalogFile convert(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) {
      throw const EditorValidationException(
        'Showdown moves snapshot cannot be empty',
      );
    }

    final entries = snapshot.entries
        .map(
          (snapshotEntry) => _convertEntry(
            rawId: snapshotEntry.key,
            rawEntry: snapshotEntry.value,
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) => ((left['id'] as String?) ?? '').compareTo(
          (right['id'] as String?) ?? '',
        ),
      );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(
        description:
            'Moves catalog synchronized from the Pokémon Showdown moves snapshot.',
        sourcePriority: <String>['showdown', 'local_merge'],
        notes: <String>[
          'M3 converts Showdown move entries through the canonical PokemonMove model.',
          'The converter never derives battle logic from prose descriptions.',
          'Engine support limits are stored explicitly per move.',
        ],
      ),
      entries: entries,
    );
  }

  Map<String, dynamic> _convertEntry({
    required String rawId,
    required Object? rawEntry,
  }) {
    if (rawEntry is! Map) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" must be an object',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    final displayName = _readDisplayName(rawId, entry);
    final localId = _normalizeSnakeCaseId(displayName);
    if (localId.isEmpty) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" does not expose a usable local id',
      );
    }

    final unsupportedReasons = <String>[];
    final seenUnsupportedReasons = <String>{};
    void addUnsupportedReason(String reason) {
      final normalized = reason.trim();
      if (normalized.isEmpty || !seenUnsupportedReasons.add(normalized)) {
        return;
      }
      unsupportedReasons.add(normalized);
    }

    // La capture des hooks Showdown doit être déterministe et honnête.
    //
    // Important :
    // - le snapshot HTTP JSON réel perd déjà les fonctions JS de Showdown ;
    // - mais le convertisseur doit rester capable de signaler ces hooks quand
    //   une source en mémoire les fournit encore (tests, outillage futur,
    //   audits plus riches à partir des sources TS).
    final hooksPresent = _collectShowdownHooks(entry);
    for (final hook in hooksPresent) {
      addUnsupportedReason('showdown_callback:$hook');
    }

    final type = _readRequiredLowerCaseString(
      rawId: rawId,
      fieldName: 'type',
      rawValue: entry['type'],
    );
    final category = _readRequiredCategory(rawId, entry['category']);
    final rawTarget = _readTrimmedString(entry['target']);
    if (rawTarget == null) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" is missing a target',
      );
    }
    final target = _parseTarget(rawTarget);
    final resolvedTarget = target ?? PokemonMoveTarget.scripted;
    if (target == null) {
      addUnsupportedReason('unsupported_target:$rawTarget');
    }

    final flags = _mapFlags(entry['flags'], addUnsupportedReason);
    final effects = _buildStructuredEffects(
      entry: entry,
      rawTarget: rawTarget,
      addUnsupportedReason: addUnsupportedReason,
    );

    _collectUnsupportedTopLevelFields(
      entry: entry,
      addUnsupportedReason: addUnsupportedReason,
    );

    final move = PokemonMove(
      id: localId,
      name: displayName,
      names: <String, String>{'en': displayName},
      generation: _readOptionalInt(entry['gen']),
      source: 'showdown',
      type: type,
      category: category,
      target: resolvedTarget,
      basePower: _readBasePower(entry['basePower']),
      accuracy: _readAccuracy(rawId, entry['accuracy']),
      pp: _readOptionalInt(entry['pp']) ?? 0,
      noPpBoosts: _readBool(entry['noPPBoosts']),
      priority: _readOptionalInt(entry['priority']) ?? 0,
      critRatio: _readOptionalInt(entry['critRatio']) ?? 1,
      flags: flags,
      effects: _dedupeEffects(effects),
      shortDescription: _readTrimmedString(entry['shortDesc']) ?? '',
      description: _readTrimmedString(entry['desc']) ?? '',
      engineSupportLevel: _inferEngineSupportLevel(
        unsupportedReasons: unsupportedReasons,
        usesStandardDamageFlow: category != PokemonMoveCategory.status &&
            _readBasePower(entry['basePower']) > 0,
        effectsAreEmpty: effects.isEmpty,
      ),
      unsupportedReasons: unsupportedReasons,
      sourceRefs: PokemonMoveSourceRefs(
        showdownMoveId: rawId.trim().isEmpty ? null : rawId.trim(),
        showdownHooksPresent: hooksPresent,
      ),
    ).normalized();

    return move.toJson();
  }

  List<PokemonMoveEffect> _buildStructuredEffects({
    required Map<String, dynamic> entry,
    required String rawTarget,
    required void Function(String reason) addUnsupportedReason,
  }) {
    final effects = <PokemonMoveEffect>[];

    void addEffect(PokemonMoveEffect effect) {
      effects.add(effect);
    }

    // M3 assume explicitement que le flow de dégâts standards n'est plus un
    // effet structuré. `basePower` + `category` + `usesStandardDamageFlow`
    // suffisent à porter cette sémantique.
    _appendFixedDamageEffect(
      entry['damage'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendMultiHitEffect(
      entry['multihit'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    _appendDirectStatusEffect(
      rawStatus: entry['status'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendDirectVolatileStatusEffect(
      rawVolatileStatus: entry['volatileStatus'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendModifyStatsEffect(
      rawBoosts: entry['boosts'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['heal'],
      kind: _FractionEffectKind.heal,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['drain'],
      kind: _FractionEffectKind.drain,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['recoil'],
      kind: _FractionEffectKind.recoil,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFieldStringEffect(
      rawValue: entry['weather'],
      fieldName: 'weather',
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: entry['terrain'],
      fieldName: 'terrain',
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: entry['pseudoWeather'],
      fieldName: 'pseudoWeather',
      addEffect: addEffect,
    );
    _appendSelfSwitchEffect(entry['selfSwitch'], addEffect: addEffect);
    _appendForceSwitchEffect(entry['forceSwitch'], addEffect: addEffect);
    _appendBreakProtectEffect(entry['breaksProtect'], addEffect: addEffect);
    _appendSideConditionEffect(
      rawConditionId: entry['sideCondition'],
      targetScope: _sideConditionScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendSlotConditionEffect(
      rawConditionId: entry['slotCondition'],
      addEffect: addEffect,
    );

    // Les payloads `self` et `selfBoost` sont des seams non triviaux :
    // - ils modélisent des conséquences sur le lanceur, pas sur la cible ;
    // - certaines valeurs (`mustrecharge`) ont désormais un effet dédié ;
    // - d'autres payloads internes de Showdown restent volontairement hors
    //   scope et sont tracés comme limites explicites.
    _appendSelfPayloadEffects(
      rawSelf: entry['self'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSelfBoostEffects(
      rawSelfBoost: entry['selfBoost'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSecondaryEffects(
      rawSecondary: entry['secondary'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSecondariesEffects(
      rawSecondaries: entry['secondaries'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    // Les moves à charge sur deux tours sont un cas classique de faux positif
    // si on "simplifie" trop fort.
    //
    // On ne fabrique donc pas `charge_then_strike` à partir d'une simple
    // intuition sur les callbacks. En revanche, on marque la limite quand la
    // donnée source expose déjà des signaux suffisants (`flags.charge`,
    // callbacks, `condition`).
    if (_hasChargeThenStrikeSignal(entry)) {
      addUnsupportedReason('unsupported_mechanic:charge_then_strike');
    }

    return effects;
  }

  void _appendFixedDamageEffect(
    Object? rawDamage, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawDamage == null) {
      return;
    }
    if (rawDamage is num) {
      final value = rawDamage.toInt();
      if (value > 0) {
        addEffect(
          PokemonMoveEffect.fixedDamage(value: value),
        );
      } else {
        addUnsupportedReason('unsupported_mechanic:fixed_damage');
      }
      return;
    }
    if (rawDamage is String && rawDamage.trim().toLowerCase() == 'level') {
      addEffect(
        const PokemonMoveEffect.fixedDamage(usesUserLevel: true),
      );
      return;
    }
    addUnsupportedReason('unsupported_mechanic:fixed_damage');
  }

  void _appendMultiHitEffect(
    Object? rawMultiHit, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawMultiHit == null) {
      return;
    }
    if (rawMultiHit is num) {
      final hits = rawMultiHit.toInt();
      if (hits > 0) {
        addEffect(
          PokemonMoveEffect.multiHit(minHits: hits, maxHits: hits),
        );
      } else {
        addUnsupportedReason('unsupported_mechanic:multi_hit');
      }
      return;
    }
    if (rawMultiHit is List && rawMultiHit.length == 2) {
      final min = rawMultiHit[0];
      final max = rawMultiHit[1];
      if (min is num && max is num) {
        addEffect(
          PokemonMoveEffect.multiHit(
            minHits: min.toInt(),
            maxHits: max.toInt(),
          ),
        );
        return;
      }
    }
    addUnsupportedReason('unsupported_mechanic:multi_hit');
  }

  void _appendDirectStatusEffect({
    required Object? rawStatus,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    int? chance,
  }) {
    final statusId = _readLowerCaseString(rawStatus);
    if (statusId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.applyStatus(
        targetScope: targetScope,
        chance: chance,
        statusId: statusId,
      ),
    );
  }

  void _appendDirectVolatileStatusEffect({
    required Object? rawVolatileStatus,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    int? chance,
  }) {
    final volatileStatusId = _readLowerCaseString(rawVolatileStatus);
    if (volatileStatusId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.applyVolatileStatus(
        targetScope: targetScope,
        chance: chance,
        volatileStatusId: volatileStatusId,
      ),
    );
  }

  void _appendModifyStatsEffect({
    required Object? rawBoosts,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    int? chance,
  }) {
    final stageChanges = _readStageChanges(
      rawBoosts,
      addUnsupportedReason: addUnsupportedReason,
    );
    if (stageChanges.isEmpty) {
      return;
    }
    // Mini-lot starter coverage :
    // - le modèle canonique sait déjà décrire un rider probabiliste de baisse /
    //   hausse de stats ;
    // - mais le slice runtime -> battle actuel ne sait toujours pas le projeter
    //   honnêtement, car `map_battle` ne consomme pour l'instant que des
    //   changements d'étages déterministes ;
    // - on garde donc la donnée structurée, utile pour le catalogue et les
    //   audits, tout en marquant explicitement la limite de support ;
    // - cela évite le faux positif où `bubble` / `bubble_beam` paraîtraient
    //   déjà bridgeables alors que le moteur local n'a pas encore ce contrat.
    if (chance != null) {
      addUnsupportedReason('unsupported_mechanic:probabilistic_modify_stats');
    }
    addEffect(
      PokemonMoveEffect.modifyStats(
        targetScope: targetScope,
        chance: chance,
        stageChanges: stageChanges,
      ),
    );
  }

  void _appendFractionEffect({
    required Object? rawFraction,
    required _FractionEffectKind kind,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawFraction == null) {
      return;
    }
    if (rawFraction is List && rawFraction.length == 2) {
      final numerator = rawFraction[0];
      final denominator = rawFraction[1];
      if (numerator is num && denominator is num) {
        final normalizedNumerator = numerator.toInt();
        final normalizedDenominator = denominator.toInt();
        switch (kind) {
          case _FractionEffectKind.heal:
            addEffect(
              PokemonMoveEffect.heal(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
          case _FractionEffectKind.drain:
            addEffect(
              PokemonMoveEffect.drain(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
          case _FractionEffectKind.recoil:
            addEffect(
              PokemonMoveEffect.recoil(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
        }
        return;
      }
    }
    addUnsupportedReason('unsupported_mechanic:${kind.reasonLabel}');
  }

  void _appendFieldStringEffect({
    required Object? rawValue,
    required String fieldName,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final normalizedId = _readLowerCaseString(rawValue);
    if (normalizedId == null) {
      return;
    }

    switch (fieldName) {
      case 'weather':
        addEffect(
          PokemonMoveEffect.setWeather(weatherId: normalizedId),
        );
      case 'terrain':
        addEffect(
          PokemonMoveEffect.setTerrain(terrainId: normalizedId),
        );
      case 'pseudoWeather':
        addEffect(
          PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: normalizedId),
        );
    }
  }

  void _appendSelfSwitchEffect(
    Object? rawSelfSwitch, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawSelfSwitch == true) {
      addEffect(const PokemonMoveEffect.selfSwitch());
      return;
    }
    final mode = _readLowerCaseString(rawSelfSwitch);
    if (mode != null) {
      addEffect(PokemonMoveEffect.selfSwitch(mode: mode));
    }
  }

  void _appendForceSwitchEffect(
    Object? rawForceSwitch, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawForceSwitch == true) {
      addEffect(const PokemonMoveEffect.forceSwitch());
    }
  }

  void _appendBreakProtectEffect(
    Object? rawBreaksProtect, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawBreaksProtect == true) {
      addEffect(const PokemonMoveEffect.breakProtect());
    }
  }

  void _appendSideConditionEffect({
    required Object? rawConditionId,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final conditionId = _readLowerCaseString(rawConditionId);
    if (conditionId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.setSideCondition(
        targetScope: targetScope,
        conditionId: conditionId,
      ),
    );
  }

  void _appendSlotConditionEffect({
    required Object? rawConditionId,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final conditionId = _readLowerCaseString(rawConditionId);
    if (conditionId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.setSlotCondition(conditionId: conditionId),
    );
  }

  void _appendSelfPayloadEffects({
    required Object? rawSelf,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    int? chance,
  }) {
    if (rawSelf is! Map) {
      return;
    }

    final self = rawSelf.cast<String, dynamic>();
    final supportedKeys = <String>{
      'boosts',
      'volatileStatus',
      'sideCondition',
      'pseudoWeather',
      'status',
    };

    _appendModifyStatsEffect(
      rawBoosts: self['boosts'],
      targetScope: PokemonMoveEffectTargetScope.self,
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    final selfVolatileStatus = _readLowerCaseString(self['volatileStatus']);
    if (selfVolatileStatus == 'mustrecharge') {
      addEffect(
        const PokemonMoveEffect.requireRecharge(),
      );
    } else if (selfVolatileStatus != null) {
      _appendDirectVolatileStatusEffect(
        rawVolatileStatus: selfVolatileStatus,
        targetScope: PokemonMoveEffectTargetScope.self,
        chance: chance,
        addEffect: addEffect,
      );
    }

    _appendDirectStatusEffect(
      rawStatus: self['status'],
      targetScope: PokemonMoveEffectTargetScope.self,
      chance: chance,
      addEffect: addEffect,
    );
    _appendSideConditionEffect(
      rawConditionId: self['sideCondition'],
      targetScope: PokemonMoveEffectTargetScope.allySide,
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: self['pseudoWeather'],
      fieldName: 'pseudoWeather',
      addEffect: addEffect,
    );

    for (final entry in self.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (supportedKeys.contains(entry.key) ||
          !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:self.${entry.key}');
    }
  }

  void _appendSelfBoostEffects({
    required Object? rawSelfBoost,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSelfBoost is! Map) {
      return;
    }

    final selfBoost = rawSelfBoost.cast<String, dynamic>();
    _appendModifyStatsEffect(
      rawBoosts: selfBoost['boosts'],
      targetScope: PokemonMoveEffectTargetScope.self,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    for (final entry in selfBoost.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (entry.key == 'boosts' || !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:selfBoost.${entry.key}');
    }
  }

  void _appendSecondaryEffects({
    required Object? rawSecondary,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSecondary is! Map) {
      return;
    }
    _appendSecondaryPayloadEffects(
      rawSecondary.cast<String, dynamic>(),
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
      reasonPrefix: 'secondary',
    );
  }

  void _appendSecondariesEffects({
    required Object? rawSecondaries,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSecondaries is! List) {
      return;
    }

    for (var index = 0; index < rawSecondaries.length; index++) {
      final secondary = rawSecondaries[index];
      if (secondary is! Map) {
        addUnsupportedReason(
            'unsupported_secondary_payload:secondaries[$index]');
        continue;
      }
      _appendSecondaryPayloadEffects(
        secondary.cast<String, dynamic>(),
        addEffect: addEffect,
        addUnsupportedReason: addUnsupportedReason,
        reasonPrefix: 'secondaries[$index]',
      );
    }
  }

  void _appendSecondaryPayloadEffects(
    Map<String, dynamic> secondary, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    required String reasonPrefix,
  }) {
    final chance = _readSecondaryChance(
      secondary['chance'],
      addUnsupportedReason: addUnsupportedReason,
      reasonLabel: '$reasonPrefix.chance',
    );

    _appendDirectStatusEffect(
      rawStatus: secondary['status'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
    );
    _appendDirectVolatileStatusEffect(
      rawVolatileStatus: secondary['volatileStatus'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
    );
    _appendModifyStatsEffect(
      rawBoosts: secondary['boosts'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSelfPayloadEffects(
      rawSelf: secondary['self'],
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    const supportedKeys = <String>{
      'chance',
      'status',
      'volatileStatus',
      'boosts',
      'self',
    };

    for (final entry in secondary.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (supportedKeys.contains(entry.key) ||
          !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_secondary_payload:${entry.key}');
    }
  }

  int? _readSecondaryChance(
    Object? rawChance, {
    required void Function(String reason) addUnsupportedReason,
    required String reasonLabel,
  }) {
    if (rawChance == null) {
      return null;
    }
    if (rawChance is num) {
      final chance = rawChance.toInt();
      if (chance >= 1 && chance <= 100) {
        return chance;
      }
    }
    addUnsupportedReason('unsupported_secondary_payload:$reasonLabel');
    return null;
  }

  List<PokemonMoveStatStageChange> _readStageChanges(
    Object? rawBoosts, {
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawBoosts is! Map) {
      return const <PokemonMoveStatStageChange>[];
    }

    final changes = <PokemonMoveStatStageChange>[];
    final sortedEntries = rawBoosts.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));

    for (final entry in sortedEntries) {
      final rawStat = '${entry.key}'.trim();
      final stat = _parseStatId(rawStat);
      final rawStages = entry.value;
      if (stat == null || rawStages is! num) {
        addUnsupportedReason('unsupported_mechanic:boosts');
        continue;
      }
      final stages = rawStages.toInt();
      if (stages == 0) {
        continue;
      }
      changes.add(
        PokemonMoveStatStageChange(stat: stat, stages: stages),
      );
    }

    return changes;
  }

  void _collectUnsupportedTopLevelFields({
    required Map<String, dynamic> entry,
    required void Function(String reason) addUnsupportedReason,
  }) {
    for (final mapEntry in entry.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      final key = mapEntry.key;
      final value = mapEntry.value;
      if (_handledTopLevelFields.contains(key) ||
          _ignoredTopLevelMetadataFields.contains(key) ||
          !_hasMeaningfulValue(value)) {
        continue;
      }
      if (value is Function) {
        // Déjà tracé via `showdown_callback:<hookPath>`.
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:$key');
    }
  }

  List<String> _collectShowdownHooks(Map<String, dynamic> entry) {
    final hooks = <String>[];
    final seen = <String>{};

    void visit(Object? value, String path) {
      if (value is Function) {
        if (seen.add(path)) {
          hooks.add(path);
        }
        return;
      }
      if (value is Map) {
        final entries = value.entries.toList()
          ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
        for (final nested in entries) {
          final key = '${nested.key}'.trim();
          if (key.isEmpty) {
            continue;
          }
          final nestedPath = path.isEmpty ? key : '$path.$key';
          visit(nested.value, nestedPath);
        }
        return;
      }
      if (value is List) {
        for (var index = 0; index < value.length; index++) {
          visit(value[index], '$path[$index]');
        }
      }
    }

    for (final key in entry.keys.toList()..sort()) {
      visit(entry[key], key);
    }

    hooks.sort();
    return hooks;
  }

  List<PokemonMoveFlag> _mapFlags(
    Object? rawFlags,
    void Function(String reason) addUnsupportedReason,
  ) {
    if (rawFlags is! Map) {
      return const <PokemonMoveFlag>[];
    }

    final flags = <PokemonMoveFlag>[];
    final seen = <PokemonMoveFlag>{};
    final sortedEntries = rawFlags.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));

    for (final entry in sortedEntries) {
      if (!_isTruthyFlagValue(entry.value)) {
        continue;
      }
      final flag = _parseFlag('${entry.key}');
      if (flag == null) {
        addUnsupportedReason('unknown_flag:${entry.key}');
        continue;
      }
      if (seen.add(flag)) {
        flags.add(flag);
      }
    }

    return flags;
  }

  PokemonMoveEngineSupportLevel _inferEngineSupportLevel({
    required List<String> unsupportedReasons,
    required bool usesStandardDamageFlow,
    required bool effectsAreEmpty,
  }) {
    // Politique M3 :
    // - `structured_supported` si rien d'important n'est perdu ;
    // - `structured_partial` si la structure principale est utile mais qu'il
    //   reste des limites honnêtement tracées ;
    // - `catalog_only` si réduire le move à ce squelette deviendrait trompeur.
    if (unsupportedReasons.isEmpty) {
      return PokemonMoveEngineSupportLevel.structuredSupported;
    }

    final hasCatalogOnlyBlockingReason = unsupportedReasons.any((reason) {
      return reason == 'unsupported_mechanic:charge_then_strike' ||
          reason == 'unsupported_mechanic:condition' ||
          reason == 'unsupported_mechanic:damage' ||
          reason == 'unsupported_mechanic:damageCallback' ||
          reason == 'showdown_callback:basePowerCallback' ||
          reason == 'showdown_callback:damageCallback';
    });

    if (hasCatalogOnlyBlockingReason) {
      return PokemonMoveEngineSupportLevel.catalogOnly;
    }

    // Si le move n'a ni flow de dégâts standard ni effet structuré utile, mais
    // dépend malgré tout de hooks ou de mécaniques non portées, on préfère
    // rester honnête et le signaler comme catalogue seulement.
    if (!usesStandardDamageFlow && effectsAreEmpty) {
      return PokemonMoveEngineSupportLevel.catalogOnly;
    }

    return PokemonMoveEngineSupportLevel.structuredPartial;
  }

  List<PokemonMoveEffect> _dedupeEffects(List<PokemonMoveEffect> effects) {
    final uniqueEffects = <PokemonMoveEffect>[];
    final seen = <String>{};
    for (final effect in effects) {
      final fingerprint = effect.normalized().toJson().toString();
      if (!seen.add(fingerprint)) {
        continue;
      }
      uniqueEffects.add(effect);
    }
    return uniqueEffects;
  }

  PokemonMoveAccuracy _readAccuracy(String rawId, Object? rawAccuracy) {
    if (rawAccuracy == true) {
      return const PokemonMoveAccuracy.alwaysHits();
    }
    if (rawAccuracy is num) {
      return PokemonMoveAccuracy.percent(value: rawAccuracy.toInt());
    }
    throw EditorPersistenceException(
      'Showdown move entry "$rawId" does not expose a supported accuracy payload',
    );
  }

  PokemonMoveCategory _readRequiredCategory(String rawId, Object? rawValue) {
    final normalized = _readLowerCaseString(rawValue);
    switch (normalized) {
      case 'physical':
        return PokemonMoveCategory.physical;
      case 'special':
        return PokemonMoveCategory.special;
      case 'status':
        return PokemonMoveCategory.status;
      default:
        throw EditorPersistenceException(
          'Showdown move entry "$rawId" exposes an unsupported category "$rawValue"',
        );
    }
  }

  PokemonMoveTarget? _parseTarget(String rawValue) {
    switch (rawValue.trim()) {
      case 'adjacentAlly':
        return PokemonMoveTarget.adjacentAlly;
      case 'adjacentAllyOrSelf':
        return PokemonMoveTarget.adjacentAllyOrSelf;
      case 'adjacentFoe':
        return PokemonMoveTarget.adjacentFoe;
      case 'all':
        return PokemonMoveTarget.all;
      case 'allAdjacent':
        return PokemonMoveTarget.allAdjacent;
      case 'allAdjacentFoes':
        return PokemonMoveTarget.allAdjacentFoes;
      case 'allies':
        return PokemonMoveTarget.allies;
      case 'allySide':
        return PokemonMoveTarget.allySide;
      case 'allyTeam':
        return PokemonMoveTarget.allyTeam;
      case 'any':
        return PokemonMoveTarget.any;
      case 'foeSide':
        return PokemonMoveTarget.foeSide;
      case 'normal':
        return PokemonMoveTarget.normal;
      case 'randomNormal':
        return PokemonMoveTarget.randomNormal;
      case 'scripted':
        return PokemonMoveTarget.scripted;
      case 'self':
        return PokemonMoveTarget.self;
    }
    return null;
  }

  PokemonMoveFlag? _parseFlag(String rawValue) {
    switch (rawValue.trim()) {
      case 'allyanim':
        return PokemonMoveFlag.allyAnim;
      case 'bypasssub':
        return PokemonMoveFlag.bypassSubstitute;
      case 'bite':
        return PokemonMoveFlag.bite;
      case 'bullet':
        return PokemonMoveFlag.bullet;
      case 'cantusetwice':
        return PokemonMoveFlag.cantUseTwice;
      case 'charge':
        return PokemonMoveFlag.charge;
      case 'contact':
        return PokemonMoveFlag.contact;
      case 'dance':
        return PokemonMoveFlag.dance;
      case 'defrost':
        return PokemonMoveFlag.defrost;
      case 'distance':
        return PokemonMoveFlag.distance;
      case 'failcopycat':
        return PokemonMoveFlag.failCopycat;
      case 'failencore':
        return PokemonMoveFlag.failEncore;
      case 'failinstruct':
        return PokemonMoveFlag.failInstruct;
      case 'failmefirst':
        return PokemonMoveFlag.failMeFirst;
      case 'failmimic':
        return PokemonMoveFlag.failMimic;
      case 'futuremove':
        return PokemonMoveFlag.futureMove;
      case 'gravity':
        return PokemonMoveFlag.gravity;
      case 'heal':
        return PokemonMoveFlag.heal;
      case 'metronome':
        return PokemonMoveFlag.metronome;
      case 'minimize':
        return PokemonMoveFlag.minimize;
      case 'mirror':
        return PokemonMoveFlag.mirror;
      case 'mustpressure':
        return PokemonMoveFlag.mustPressure;
      case 'noassist':
        return PokemonMoveFlag.noAssist;
      case 'nonsky':
        return PokemonMoveFlag.nonSky;
      case 'noparentalbond':
        return PokemonMoveFlag.noParentalBond;
      case 'nosketch':
        return PokemonMoveFlag.noSketch;
      case 'nosleeptalk':
        return PokemonMoveFlag.noSleepTalk;
      case 'pledgecombo':
        return PokemonMoveFlag.pledgeCombo;
      case 'powder':
        return PokemonMoveFlag.powder;
      case 'protect':
        return PokemonMoveFlag.protect;
      case 'pulse':
        return PokemonMoveFlag.pulse;
      case 'punch':
        return PokemonMoveFlag.punch;
      case 'recharge':
        return PokemonMoveFlag.recharge;
      case 'reflectable':
        return PokemonMoveFlag.reflectable;
      case 'slicing':
        return PokemonMoveFlag.slicing;
      case 'snatch':
        return PokemonMoveFlag.snatch;
      case 'sound':
        return PokemonMoveFlag.sound;
      case 'wind':
        return PokemonMoveFlag.wind;
    }
    return null;
  }

  PokemonMoveStatId? _parseStatId(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'atk':
        return PokemonMoveStatId.attack;
      case 'def':
        return PokemonMoveStatId.defense;
      case 'spa':
        return PokemonMoveStatId.specialAttack;
      case 'spd':
        return PokemonMoveStatId.specialDefense;
      case 'spe':
        return PokemonMoveStatId.speed;
      case 'accuracy':
        return PokemonMoveStatId.accuracy;
      case 'evasion':
        return PokemonMoveStatId.evasion;
    }
    return null;
  }

  PokemonMoveEffectTargetScope _primaryTargetScopeForMoveTarget(
    String rawTarget,
  ) {
    if (rawTarget == 'self') {
      return PokemonMoveEffectTargetScope.self;
    }
    return PokemonMoveEffectTargetScope.target;
  }

  PokemonMoveEffectTargetScope _sideConditionScopeForMoveTarget(
    String rawTarget,
  ) {
    switch (rawTarget) {
      case 'allySide':
      case 'allyTeam':
        return PokemonMoveEffectTargetScope.allySide;
      default:
        return PokemonMoveEffectTargetScope.foeSide;
    }
  }

  String _readDisplayName(String rawId, Map<String, dynamic> entry) {
    final explicitName = _readTrimmedString(entry['name']);
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }
    return _humanizeIdentifier(rawId);
  }

  String _readRequiredLowerCaseString({
    required String rawId,
    required String fieldName,
    required Object? rawValue,
  }) {
    final value = _readLowerCaseString(rawValue);
    if (value == null) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" is missing a supported $fieldName',
      );
    }
    return value;
  }

  String? _readLowerCaseString(Object? rawValue) {
    final value = _readTrimmedString(rawValue);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  String? _readTrimmedString(Object? rawValue) {
    final value = rawValue as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  int? _readOptionalInt(Object? rawValue) {
    return (rawValue as num?)?.toInt();
  }

  int _readBasePower(Object? rawValue) {
    return (rawValue as num?)?.toInt() ?? 0;
  }

  bool _readBool(Object? rawValue) => rawValue == true;

  bool _isTruthyFlagValue(Object? value) {
    if (value == true) {
      return true;
    }
    return value is num && value != 0;
  }

  bool _hasChargeThenStrikeSignal(Map<String, dynamic> entry) {
    final flags = entry['flags'];
    final hasChargeFlag = flags is Map && _isTruthyFlagValue(flags['charge']);
    if (!hasChargeFlag) {
      return false;
    }

    if (_hasMeaningfulValue(entry['condition'])) {
      return true;
    }

    for (final hook in _collectShowdownHooks(entry)) {
      if (hook == 'onTryMove' ||
          hook == 'onTry' ||
          hook == 'beforeMoveCallback' ||
          hook == 'onPrepareHit') {
        return true;
      }
    }

    return false;
  }

  bool _hasMeaningfulValue(Object? value) {
    if (value == null || value == false) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is List) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    return true;
  }

  String _normalizeSnakeCaseId(String rawValue) {
    final lowerCase = rawValue.trim().toLowerCase();
    if (lowerCase.isEmpty) {
      return '';
    }

    final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
    final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _humanizeIdentifier(String rawId) {
    final prepared = rawId
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (prepared.isEmpty) {
      return rawId;
    }

    return prepared
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

enum _FractionEffectKind {
  heal('heal'),
  drain('drain'),
  recoil('recoil');

  const _FractionEffectKind(this.reasonLabel);

  final String reasonLabel;
}

const Set<String> _handledTopLevelFields = <String>{
  'name',
  'type',
  'category',
  'target',
  'gen',
  'pp',
  'priority',
  'basePower',
  'accuracy',
  'shortDesc',
  'desc',
  'noPPBoosts',
  'critRatio',
  'flags',
  'status',
  'volatileStatus',
  'boosts',
  'selfBoost',
  'self',
  'secondary',
  'secondaries',
  'drain',
  'recoil',
  'heal',
  'multihit',
  'damage',
  'weather',
  'terrain',
  'pseudoWeather',
  'selfSwitch',
  'forceSwitch',
  'breaksProtect',
  'sideCondition',
  'slotCondition',
};

const Set<String> _ignoredTopLevelMetadataFields = <String>{
  'num',
  'contestType',
  // Mini-lot starter coverage :
  // - `zMove` décrit uniquement le comportement Z-Move historique du move ;
  // - cette métadonnée n'altère pas l'exécution du move de base dans le slice
  //   singles local actuellement supporté ;
  // - la conserver comme "unsupported reason" déclassait à tort des moves déjà
  //   honnêtement portables comme `tailwhip` ou `withdraw` ;
  // - on l'ignore donc ici comme métadonnée de catalogue, au même titre que
  //   `num` et `contestType`, sans prétendre ouvrir le moindre support Z-Move.
  'zMove',
};

```

### `packages/map_editor/test/showdown_move_catalog_converter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/showdown_move_catalog_converter.dart';

void main() {
  const converter = ShowdownMoveCatalogConverter();

  test('converts standard offensive, drain, multi-hit and direct status moves',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'absorb': <String, dynamic>{
        'name': 'Absorb',
        'type': 'Grass',
        'category': 'Special',
        'basePower': 20,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'drain': <int>[1, 2],
        'shortDesc': 'Heals the user by half the damage dealt.',
        'desc': 'A nutrient-draining attack.',
        'gen': 1,
      },
      'doubleslap': <String, dynamic>{
        'name': 'Double Slap',
        'type': 'Normal',
        'category': 'Physical',
        'basePower': 15,
        'accuracy': 85,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'multihit': <int>[2, 5],
        'shortDesc': 'Hits 2-5 times in one turn.',
        'desc': 'Repeatedly slaps 2 to 5 times.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
      'thunderwave': <String, dynamic>{
        'name': 'Thunder Wave',
        'type': 'Electric',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'status': 'par',
        'shortDesc': 'Paralyzes the target.',
        'desc': 'A weak electric charge is launched at the target.',
        'gen': 1,
      },
      'swordsdance': <String, dynamic>{
        'name': 'Swords Dance',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'self',
        'boosts': <String, int>{'atk': 2},
        'shortDesc': 'Raises the user\'s Attack by 2.',
        'desc': 'A frenetic dance to uplift the fighting spirit.',
        'gen': 1,
      },
      'leer': <String, dynamic>{
        'name': 'Leer',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'boosts': <String, int>{'def': -1},
        'shortDesc': 'Lowers the target\'s Defense by 1.',
        'desc': 'The user gives opposing Pokémon an intimidating leer.',
        'gen': 1,
      },
    });

    final thunderbolt = _move(catalog, 'thunderbolt');
    expect(thunderbolt.source, 'showdown');
    expect(thunderbolt.basePower, 90);
    expect(thunderbolt.usesStandardDamageFlow, isTrue);
    expect(
      thunderbolt.accuracy,
      const PokemonMoveAccuracy.percent(value: 100),
    );
    expect(
      thunderbolt.effects,
      contains(
        const PokemonMoveEffect.applyStatus(
          chance: 10,
          statusId: 'par',
        ),
      ),
    );
    expect(
      thunderbolt.effects.map((effect) => effect.toJson()['kind']),
      isNot(contains('deal_damage')),
    );
    expect(
      thunderbolt.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredSupported,
    );

    final absorb = _move(catalog, 'absorb');
    expect(
      absorb.effects,
      contains(
        const PokemonMoveEffect.drain(numerator: 1, denominator: 2),
      ),
    );

    final doubleSlap = _move(catalog, 'double_slap');
    expect(
      doubleSlap.effects,
      contains(
        const PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
      ),
    );

    final swift = _move(catalog, 'swift');
    expect(swift.accuracy, const PokemonMoveAccuracy.alwaysHits());

    final thunderWave = _move(catalog, 'thunder_wave');
    expect(
      thunderWave.effects,
      contains(
        const PokemonMoveEffect.applyStatus(statusId: 'par'),
      ),
    );

    final swordsDance = _move(catalog, 'swords_dance');
    expect(
      swordsDance.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: 2,
            ),
          ],
        ),
      ),
    );

    final leer = _move(catalog, 'leer');
    expect(
      leer.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ),
    );
  });

  test('converts weather, terrain, pseudo-weather, side and slot conditions',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'raindance': <String, dynamic>{
        'name': 'Rain Dance',
        'type': 'Water',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 5,
        'priority': 0,
        'target': 'self',
        'weather': 'raindance',
        'shortDesc': 'For 5 turns, heavy rain powers Water moves.',
        'desc': 'The user summons a heavy rain.',
        'gen': 2,
      },
      'electricterrain': <String, dynamic>{
        'name': 'Electric Terrain',
        'type': 'Electric',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 10,
        'priority': 0,
        'target': 'self',
        'terrain': 'electricterrain',
        'shortDesc': 'For 5 turns, the terrain becomes electric.',
        'desc': 'The user electrifies the ground.',
        'gen': 6,
      },
      'trickroom': <String, dynamic>{
        'name': 'Trick Room',
        'type': 'Psychic',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 5,
        'priority': -7,
        'target': 'all',
        'pseudoWeather': 'trickroom',
        'shortDesc': 'For 5 turns, slower Pokémon move first.',
        'desc':
            'The user creates a bizarre area in which slower Pokémon get to move first.',
        'gen': 4,
      },
      'stealthrock': <String, dynamic>{
        'name': 'Stealth Rock',
        'type': 'Rock',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'foeSide',
        'sideCondition': 'stealthrock',
        'shortDesc': 'Sets a hazard on the foes\' side of the field.',
        'desc':
            'The user lays a trap of levitating stones around the opposing team.',
        'gen': 4,
      },
      'healingwish': <String, dynamic>{
        'name': 'Healing Wish',
        'type': 'Psychic',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 10,
        'priority': 0,
        'target': 'self',
        'slotCondition': 'healingwish',
        'shortDesc': 'The user faints and heals its replacement.',
        'desc': 'The user faints and the Pokémon switched in is fully healed.',
        'gen': 4,
      },
    });

    expect(
      _move(catalog, 'rain_dance').effects,
      contains(
        const PokemonMoveEffect.setWeather(weatherId: 'raindance'),
      ),
    );
    expect(
      _move(catalog, 'electric_terrain').effects,
      contains(
        const PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
      ),
    );
    expect(
      _move(catalog, 'trick_room').effects,
      contains(
        const PokemonMoveEffect.setPseudoWeather(
          pseudoWeatherId: 'trickroom',
        ),
      ),
    );
    expect(
      _move(catalog, 'stealth_rock').effects,
      contains(
        const PokemonMoveEffect.setSideCondition(
          conditionId: 'stealthrock',
        ),
      ),
    );
    expect(
      _move(catalog, 'healing_wish').effects,
      contains(
        const PokemonMoveEffect.setSlotCondition(
          conditionId: 'healingwish',
        ),
      ),
    );
  });

  test(
      'keeps Tail Whip and Withdraw fully supported when Showdown only adds zMove metadata',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'tailwhip': <String, dynamic>{
        'name': 'Tail Whip',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'boosts': <String, int>{'def': -1},
        'zMove': <String, Object>{
          'boost': <String, int>{'atk': 1},
        },
        'shortDesc': 'Lowers the foe(s) Defense by 1.',
        'desc': 'Lowers the target Defense by 1 stage.',
        'gen': 1,
      },
      'withdraw': <String, dynamic>{
        'name': 'Withdraw',
        'type': 'Water',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 40,
        'priority': 0,
        'target': 'self',
        'boosts': <String, int>{'def': 1},
        'zMove': <String, Object>{
          'boost': <String, int>{'def': 1},
        },
        'shortDesc': 'Raises the user Defense by 1.',
        'desc': 'The user withdraws into its shell to raise Defense by 1.',
        'gen': 1,
      },
    });

    final tailWhip = _move(catalog, 'tail_whip');
    expect(
      tailWhip.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ),
    );
    expect(
      tailWhip.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredSupported),
    );
    expect(tailWhip.unsupportedReasons, isEmpty);

    final withdraw = _move(catalog, 'withdraw');
    expect(
      withdraw.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: 1,
            ),
          ],
        ),
      ),
    );
    expect(
      withdraw.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredSupported),
    );
    expect(withdraw.unsupportedReasons, isEmpty);
  });

  test(
      'marks probabilistic stat stage riders as partial instead of pretending they already bridge to battle',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'bubble': <String, dynamic>{
        'name': 'Bubble',
        'type': 'Water',
        'category': 'Special',
        'basePower': 40,
        'accuracy': 100,
        'pp': 30,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'secondary': <String, dynamic>{
          'chance': 10,
          'boosts': <String, int>{'spe': -1},
        },
        'shortDesc': '10% chance to lower the target Speed by 1.',
        'desc': 'A spray of bubbles may lower the target Speed by 1 stage.',
        'gen': 1,
      },
      'bubblebeam': <String, dynamic>{
        'name': 'Bubble Beam',
        'type': 'Water',
        'category': 'Special',
        'basePower': 65,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'boosts': <String, int>{'spe': -1},
        },
        'shortDesc': '10% chance to lower the target Speed by 1.',
        'desc': 'A spray of bubbles may lower the target Speed by 1 stage.',
        'gen': 1,
      },
    });

    final bubble = _move(catalog, 'bubble');
    expect(
      bubble.effects,
      contains(
        const PokemonMoveEffect.modifyStats(
          chance: 10,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.speed,
              stages: -1,
            ),
          ],
        ),
      ),
    );
    expect(
      bubble.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredPartial),
    );
    expect(
      bubble.unsupportedReasons,
      contains('unsupported_mechanic:probabilistic_modify_stats'),
    );

    final bubbleBeam = _move(catalog, 'bubble_beam');
    expect(
      bubbleBeam.engineSupportLevel,
      equals(PokemonMoveEngineSupportLevel.structuredPartial),
    );
    expect(
      bubbleBeam.unsupportedReasons,
      contains('unsupported_mechanic:probabilistic_modify_stats'),
    );
  });

  test('tracks callbacks and downgrades support level honestly', () {
    final catalog = converter.convert(<String, dynamic>{
      'thunder': <String, dynamic>{
        'name': 'Thunder',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 110,
        'accuracy': 70,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 30,
          'status': 'par',
        },
        'onModifyMove': () {},
        'shortDesc': 'May paralyze the target. Accuracy changes in weather.',
        'desc': 'A wicked thunderbolt is dropped on the target.',
        'gen': 1,
      },
      'weatherball': <String, dynamic>{
        'name': 'Weather Ball',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 50,
        'accuracy': 100,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'basePowerCallback': () => 100,
        'shortDesc': 'Power and type change based on the weather.',
        'desc':
            'An attack move that varies in power and type depending on the weather.',
        'gen': 3,
      },
      'mysterymove': <String, dynamic>{
        'name': 'Mystery Move',
        'type': 'Normal',
        'category': 'Physical',
        'basePower': 40,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'mystery': 1},
        'shortDesc': 'Unsupported test move.',
        'desc': 'A move used to prove unknown flags are not ignored.',
        'gen': 9,
      },
    });

    final thunder = _move(catalog, 'thunder');
    expect(
      thunder.sourceRefs.showdownHooksPresent,
      contains('onModifyMove'),
    );
    expect(
      thunder.unsupportedReasons,
      contains('showdown_callback:onModifyMove'),
    );
    expect(
      thunder.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredPartial,
    );

    final weatherBall = _move(catalog, 'weather_ball');
    expect(
      weatherBall.sourceRefs.showdownHooksPresent,
      contains('basePowerCallback'),
    );
    expect(
      weatherBall.unsupportedReasons,
      contains('showdown_callback:basePowerCallback'),
    );
    expect(
      weatherBall.engineSupportLevel,
      PokemonMoveEngineSupportLevel.catalogOnly,
    );

    final mysteryMove = _move(catalog, 'mystery_move');
    expect(
      mysteryMove.unsupportedReasons,
      contains('unknown_flag:mystery'),
    );
    expect(
      mysteryMove.engineSupportLevel,
      PokemonMoveEngineSupportLevel.structuredPartial,
    );
  });

  test(
      'converts fixed damage and keeps charge-based moves honest without fabricating effects',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'sonicboom': <String, dynamic>{
        'name': 'Sonic Boom',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 0,
        'damage': 20,
        'accuracy': 90,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Always does 20 HP of damage.',
        'desc': 'The target is hit with a destructive shock wave.',
        'gen': 1,
      },
      'solarbeam': <String, dynamic>{
        'name': 'Solar Beam',
        'type': 'Grass',
        'category': 'Special',
        'basePower': 120,
        'accuracy': 100,
        'pp': 10,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'charge': 1, 'protect': 1},
        'condition': <String, dynamic>{'duration': 2},
        'onTryMove': () {},
        'shortDesc': 'Charges on the first turn, attacks on the second.',
        'desc': 'In this two-turn attack, the user gathers light, then blasts.',
        'gen': 1,
      },
    });

    final sonicBoom = _move(catalog, 'sonic_boom');
    expect(
      sonicBoom.effects,
      contains(
        const PokemonMoveEffect.fixedDamage(value: 20),
      ),
    );

    final solarBeam = _move(catalog, 'solar_beam');
    expect(
      solarBeam.unsupportedReasons,
      contains('unsupported_mechanic:charge_then_strike'),
    );
    expect(
      solarBeam.sourceRefs.showdownHooksPresent,
      contains('onTryMove'),
    );
    expect(
      solarBeam.engineSupportLevel,
      PokemonMoveEngineSupportLevel.catalogOnly,
    );
    expect(
      solarBeam.effects.map((effect) => effect.toJson()['kind']),
      isNot(contains('charge_then_strike')),
    );
  });

  test('converts self switch, force switch, recharge and canonical json safely',
      () {
    final catalog = converter.convert(<String, dynamic>{
      'uturn': <String, dynamic>{
        'name': 'U-turn',
        'type': 'Bug',
        'category': 'Physical',
        'basePower': 70,
        'accuracy': 100,
        'pp': 20,
        'priority': 0,
        'target': 'normal',
        'selfSwitch': true,
        'shortDesc': 'User switches out after damaging the target.',
        'desc': 'After making its attack, the user rushes back.',
        'gen': 4,
      },
      'roar': <String, dynamic>{
        'name': 'Roar',
        'type': 'Normal',
        'category': 'Status',
        'basePower': 0,
        'accuracy': true,
        'pp': 20,
        'priority': -6,
        'target': 'normal',
        'forceSwitch': true,
        'shortDesc': 'Forces the target to switch to a random ally.',
        'desc': 'The target is scared off and replaced.',
        'gen': 1,
      },
      'hyperbeam': <String, dynamic>{
        'name': 'Hyper Beam',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 150,
        'accuracy': 90,
        'pp': 5,
        'priority': 0,
        'target': 'normal',
        'flags': <String, int>{'recharge': 1, 'protect': 1},
        'self': <String, dynamic>{'volatileStatus': 'mustrecharge'},
        'shortDesc': 'User must recharge next turn.',
        'desc': 'The target is attacked with a powerful beam.',
        'gen': 1,
      },
    });

    final uTurn = _move(catalog, 'u_turn');
    expect(
      uTurn.effects,
      contains(const PokemonMoveEffect.selfSwitch()),
    );

    final roar = _move(catalog, 'roar');
    expect(
      roar.effects,
      contains(const PokemonMoveEffect.forceSwitch()),
    );

    final hyperBeam = _move(catalog, 'hyper_beam');
    expect(
      hyperBeam.effects,
      contains(const PokemonMoveEffect.requireRecharge()),
    );

    for (final entry in catalog.entries) {
      expect(() => PokemonMove.fromJson(entry), returnsNormally);
    }
  });
}

PokemonMove _move(PokemonCatalogFile catalog, String id) {
  final entry = catalog.entries.firstWhere((entry) => entry['id'] == id);
  return PokemonMove.fromJson(entry);
}

```

### `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_setup_exception.dart';

/// Bridge runtime -> battle pour un sous-ensemble honnête de `PokemonMove`.
///
/// Frontière volontaire de M8 :
/// - le loader runtime charge le canonique sans faire de policy d'exécution ;
/// - ce bridge décide si un move canonique peut être projeté honnêtement vers
///   le moteur battle MVP actuel ;
/// - `map_battle` exécute ensuite uniquement ce petit contrat battle enrichi.
///
/// Le but n'est pas de "supporter un peu tout" :
/// - on garde le standard damage flow ;
/// - on supporte `modifyStats` déterministe pour un petit sous-ensemble utile ;
/// - on refuse explicitement le reste.
///
/// BE1 durcit ce bridge sur un autre axe :
/// - certaines dimensions canoniques étaient encore perdues silencieusement ;
/// - on transporte maintenant le petit supplément de contrat battle qui évite
///   cette perte (`type`, `target`, `pp`) ;
/// - et on refuse explicitement les dimensions non neutres qui resteraient
///   encore mensongères sans nouvelle couche moteur (`priority`, cibles hors
///   1v1 simple honnête).
///
/// BE3 recadre ensuite ce point :
/// - `priority` n'est plus refusée, parce que `map_battle` sait enfin
///   ordonner honnêtement deux actions `Fight` ;
/// - `speed` stage devient également supportée pour ce même besoin ;
/// - puis BE4 ouvre enfin l'accuracy battle minimale et les PP réels ;
/// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
/// - puis BE7 ouvre un petit sous-ensemble `applyStatus` pour les statuts
///   majeurs `par`, `brn`, `psn`, `tox` ;
/// - puis BE8 ouvre seulement quelques volatiles utiles strictement bornés :
///   `protect`, `breakProtect`, `requireRecharge`, `chargeThenStrike` ;
/// - puis BE9 ouvre seulement un petit sous-ensemble field réellement
///   consommé : `raindance`, `sandstorm`, `trickroom` ;
/// - le reste reste explicitement hors scope et donc refusé.
class RuntimeBattleMoveBridge {
  const RuntimeBattleMoveBridge();

  /// Projette un move canonique vers le contrat `BattleMoveData`.
  ///
  /// Le refus est explicite et descriptif :
  /// - pas de fallback silencieux ;
  /// - pas de `power: 0` mensonger pour un move que le moteur n'exécute pas ;
  /// - pas de mutation opportuniste de `engineSupportLevel`.
  BattleMoveData toBattleMoveData({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    _ensureEngineSupportLevelAllowsBridge(
      move: move,
      combatantLabel: combatantLabel,
    );
    final target = _translateSupportedTarget(
      move: move,
      combatantLabel: combatantLabel,
    );
    final type = _translateType(
      move: move,
      combatantLabel: combatantLabel,
    );
    final accuracy = _translateAccuracy(move.accuracy);

    final selfChanges = <BattleStatStageChange>[];
    final targetChanges = <BattleStatStageChange>[];
    BattleMoveMajorStatusEffect? majorStatusEffect;
    BattleVolatileStatusId? selfVolatileStatus;
    BattleWeatherId? weatherEffect;
    BattlePseudoWeatherId? pseudoWeatherEffect;
    var setsStealthRock = false;
    var setsSpikes = false;
    var breaksProtect = false;
    var requiresRecharge = false;
    BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:fixed_damage',
        ),
        multiHit: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:multi_hit',
        ),
        applyStatus: (effect) {
          if (majorStatusEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_apply_status_effects_not_supported',
            );
          }

          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_apply_status_target:${target.name}',
            );
          }

          if (effect.chance case final chance?) {
            if (chance < 1 || chance > 100) {
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit: 'invalid_apply_status_chance:$chance',
              );
            }
          }

          majorStatusEffect = BattleMoveMajorStatusEffect(
            status: _translateSupportedMajorStatus(
              move: move,
              combatantLabel: combatantLabel,
              statusId: effect.statusId,
            ),
            chancePercent: effect.chance,
          );
        },
        applyVolatileStatus: (effect) {
          // BE8 n'ouvre surtout pas tout `applyVolatileStatus`.
          // Le bridge accepte uniquement le plus petit seam devenu exécutable :
          // - `protect` auto-appliqué au lanceur ;
          // - déterministe ;
          // - aucune autre taxonomie de volatile.
          if (selfVolatileStatus != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'multiple_apply_volatile_status_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_apply_volatile_status_not_supported',
            );
          }

          selfVolatileStatus = _translateSupportedSelfVolatileStatus(
            move: move,
            combatantLabel: combatantLabel,
            volatileStatusId: effect.volatileStatusId,
          );
        },
        modifyStats: (effect) {
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_modify_stats_not_supported',
            );
          }
          if (effect.stageChanges.isEmpty) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'empty_modify_stats_not_supported',
            );
          }

          final translated = effect.stageChanges
              .map(
                (change) => _translateStageChange(
                  change: change,
                  move: move,
                  combatantLabel: combatantLabel,
                ),
              )
              .toList(growable: false);

          switch (effect.targetScope) {
            case PokemonMoveEffectTargetScope.self:
              selfChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.target:
              targetChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.field:
            case PokemonMoveEffectTargetScope.allySide:
            case PokemonMoveEffectTargetScope.foeSide:
            case PokemonMoveEffectTargetScope.slot:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_modify_stats_scope:${effect.targetScope.name}',
              );
          }
        },
        heal: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:heal',
        ),
        drain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:drain',
        ),
        recoil: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:recoil',
        ),
        setWeather: (effect) {
          if (weatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_move_shape',
            );
          }
          weatherEffect = _translateSupportedWeather(
            move: move,
            combatantLabel: combatantLabel,
            weatherId: effect.weatherId,
          );
        },
        setTerrain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_terrain',
        ),
        setPseudoWeather: (effect) {
          if (pseudoWeatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_pseudo_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_pseudo_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_pseudo_weather_move_shape',
            );
          }
          pseudoWeatherEffect = _translateSupportedPseudoWeather(
            move: move,
            combatantLabel: combatantLabel,
            pseudoWeatherId: effect.pseudoWeatherId,
          );
        },
        selfSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:self_switch',
        ),
        forceSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:force_switch',
        ),
        breakProtect: (effect) {
          if (breaksProtect) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_break_protect_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_break_protect_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_break_protect_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_break_protect_not_supported',
            );
          }
          breaksProtect = true;
        },
        requireRecharge: (effect) {
          if (requiresRecharge) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_require_recharge_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_require_recharge_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_require_recharge_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_require_recharge_move_shape',
            );
          }
          requiresRecharge = true;
        },
        chargeThenStrike: (effect) {
          if (chargeThenStrikeEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_charge_then_strike_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_charge_then_strike_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_charge_then_strike_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_charge_then_strike_move_shape',
            );
          }
          chargeThenStrikeEffect = BattleChargeThenStrikeEffect(
            chargeStateId: _normalizeOptionalId(effect.chargeStateId),
          );
        },
        setSideCondition: (effect) {
          if (setsStealthRock || setsSpikes) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_side_condition_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.foeSide) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_side_condition_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponentSide) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_side_condition_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_side_condition_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_side_condition_move_shape',
            );
          }
          final normalizedConditionId = effect.conditionId.trim().toLowerCase();
          switch (normalizedConditionId) {
            case 'stealthrock':
              setsStealthRock = true;
            case 'spikes':
              setsSpikes = true;
            default:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_side_condition:$normalizedConditionId',
              );
          }
        },
        setSlotCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_slot_condition',
        ),
      );
    }

    // BE8 revendique un sous-ensemble exact, pas une "approximation large".
    // On refuse donc explicitement les combinaisons d'effets qui ne font pas
    // partie du petit contrat local ouvert par ce lot, même si chaque brique
    // isolée serait supportée séparément.
    if (requiresRecharge && chargeThenStrikeEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_charge_then_recharge',
      );
    }
    if ((weatherEffect != null || pseudoWeatherEffect != null) &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_field_effect_move',
      );
    }
    if (weatherEffect != null && pseudoWeatherEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'multiple_field_effect_kinds_not_supported',
      );
    }
    if ((setsStealthRock || setsSpikes) &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            weatherEffect != null ||
            pseudoWeatherEffect != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_side_condition_move',
      );
    }

    // Un move battle exécutable doit avoir au moins un chemin d'exécution
    // réel pour le moteur actuel :
    // - soit des dégâts standards ;
    // - soit des changements d'étages de stats déterministes ;
    // - soit un effet `applyStatus` BE7 réellement supporté ;
    // - soit une pose de champ réellement consommée en BE9 ;
    // - soit une combinaison de ces chemins-là quand elle est explicitement
    //   autorisée plus haut.
    if (!move.usesStandardDamageFlow &&
        selfChanges.isEmpty &&
        targetChanges.isEmpty &&
        majorStatusEffect == null &&
        selfVolatileStatus == null &&
        weatherEffect == null &&
        pseudoWeatherEffect == null &&
        !setsStealthRock &&
        !setsSpikes) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'no_supported_execution_path',
      );
    }

    // Le moteur battle actuel sait seulement :
    // - infliger des dégâts à l'adversaire actif ;
    // - ou appliquer des boosts/baisses déterministes sur `self` / target.
    //
    // Un move auto-ciblé qui ferait malgré tout des dégâts standards serait
    // donc encore projeté mensongèrement : `map_battle` le résoudrait contre
    // l'adversaire faute de vrai contrat "self damage".
    //
    // On préfère refuser explicitement ce cas tant qu'un lot ultérieur n'ouvre
    // pas une sémantique battle claire pour ce type d'exécution.
    if (move.usesStandardDamageFlow && target == BattleMoveTarget.self) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_standard_damage_target:self',
      );
    }

    return BattleMoveData(
      id: move.id,
      name: move.name,
      power: move.usesStandardDamageFlow ? move.basePower : 0,
      type: type,
      category: _translateCategory(move.category),
      target: target,
      accuracy: accuracy,
      pp: move.pp,
      priority: move.priority,
      critRatio: move.critRatio,
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      setsStealthRock: setsStealthRock,
      setsSpikes: setsSpikes,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
      selfStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(selfChanges),
      targetStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(targetChanges),
    );
  }

  void _ensureEngineSupportLevelAllowsBridge({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
            PokemonMoveEngineSupportLevel.structuredSupported ||
        _allowsBridgeableStructuredPartialMove(move)) {
      return;
    }
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'engine_support_level_not_bridgeable',
    );
  }

  BattleMoveAccuracy _translateAccuracy(PokemonMoveAccuracy accuracy) {
    return accuracy.map(
      percent: (accuracy) => BattleMoveAccuracy.percent(value: accuracy.value),
      alwaysHits: (_) => const BattleMoveAccuracy.alwaysHits(),
    );
  }

  String _translateType({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final normalizedType = move.type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'invalid_type:empty',
      );
    }

    // Même règle qu'au chargement des espèces :
    // - la liste des types réellement supportés ne doit vivre qu'à un seul
    //   endroit ;
    // - le bridge réutilise donc `BattleTypeChart.supportedTypes` au lieu de
    //   maintenir une seconde liste locale ;
    // - cela permet de rejeter le move au bon seam runtime -> battle, avec
    //   une erreur actionnable, plutôt que de laisser `map_battle` exploser
    //   plus tard par `StateError`.
    if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_type:$normalizedType',
      );
    }

    return normalizedType;
  }

  BattleMoveCategory _translateCategory(PokemonMoveCategory category) {
    return switch (category) {
      PokemonMoveCategory.physical => BattleMoveCategory.physical,
      PokemonMoveCategory.special => BattleMoveCategory.special,
      PokemonMoveCategory.status => BattleMoveCategory.status,
    };
  }

  BattleMoveTarget _translateSupportedTarget({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // BE1 ne promet toujours pas un système de targeting complet.
    // En revanche, on peut déjà arrêter de perdre silencieusement l'intention
    // canonique quand elle reste honnête en 1v1 simple actif :
    // - `self` -> self ;
    // - `normal`, `adjacentFoe`, `allAdjacentFoes`, `randomNormal`
    //   -> opponent.
    //
    // Les autres formes (`all`, `allySide`, `foeSide`, etc.) exigent une
    // sémantique de terrain/sides/slots ou de multibattle absente aujourd'hui.
    if (_isPureFieldMoveCandidate(move)) {
      return switch (move.target) {
        // Recadrage BE9 après review :
        // - le sous-ensemble honnête réellement seedé dans ce repo pose la
        //   météo / Trick Room avec `target: all` ;
        // - accepter aussi `self` élargissait inutilement le contrat et
        //   laissait passer un faux field move malformé ;
        // - on garde donc un bridge strict au lieu d'une tolérance qui ne
        //   sert aucun cas réel confirmé par l'audit.
        PokemonMoveTarget.all => BattleMoveTarget.field,
        _ => _rejectMove(
            move: move,
            combatantLabel: combatantLabel,
            bridgeLimit: 'unsupported_field_target:${move.target.name}',
          ),
      };
    }

    return switch (move.target) {
      PokemonMoveTarget.self => BattleMoveTarget.self,
      PokemonMoveTarget.normal ||
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.allAdjacentFoes ||
      PokemonMoveTarget.randomNormal =>
        BattleMoveTarget.opponent,
      PokemonMoveTarget.foeSide
          when _isPureFoeSideConditionMoveCandidate(move) =>
        BattleMoveTarget.opponentSide,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_target:${move.target.name}',
        ),
    };
  }

  BattleStatStageChange _translateStageChange({
    required PokemonMoveStatStageChange change,
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final stat = switch (change.stat) {
      PokemonMoveStatId.attack => BattleStatId.attack,
      PokemonMoveStatId.defense => BattleStatId.defense,
      PokemonMoveStatId.specialAttack => BattleStatId.specialAttack,
      PokemonMoveStatId.specialDefense => BattleStatId.specialDefense,
      // BE3 ouvre ici la plus petite extension honnête possible :
      // - `speed` stage devient enfin utile car le moteur ordonne désormais
      //   les deux actions `Fight` par vitesse effective ;
      // - on ne profite pas de cette ouverture pour accepter accuracy/evasion,
      //   qui resteraient mensongères sans hit pipeline réel.
      PokemonMoveStatId.speed => BattleStatId.speed,
      PokemonMoveStatId.accuracy => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
      PokemonMoveStatId.evasion => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
    };

    return BattleStatStageChange(
      stat: stat,
      stages: change.stages,
    );
  }

  BattleMajorStatusId _translateSupportedMajorStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String statusId,
  }) {
    final normalizedStatusId = statusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'par' => BattleMajorStatusId.par,
      'brn' => BattleMajorStatusId.brn,
      'psn' => BattleMajorStatusId.psn,
      'tox' => BattleMajorStatusId.tox,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_major_status:$normalizedStatusId',
        ),
    };
  }

  BattleVolatileStatusId _translateSupportedSelfVolatileStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String volatileStatusId,
  }) {
    final normalizedStatusId = volatileStatusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'protect' => BattleVolatileStatusId.protect,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_volatile_status:$normalizedStatusId',
        ),
    };
  }

  BattleWeatherId _translateSupportedWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String weatherId,
  }) {
    final normalizedWeatherId = weatherId.trim().toLowerCase();
    return switch (normalizedWeatherId) {
      'raindance' => BattleWeatherId.rain,
      'sandstorm' => BattleWeatherId.sandstorm,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_weather:$normalizedWeatherId',
        ),
    };
  }

  BattlePseudoWeatherId _translateSupportedPseudoWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String pseudoWeatherId,
  }) {
    final normalizedPseudoWeatherId = pseudoWeatherId.trim().toLowerCase();
    return switch (normalizedPseudoWeatherId) {
      'trickroom' => BattlePseudoWeatherId.trickRoom,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_pseudo_weather:$normalizedPseudoWeatherId',
        ),
    };
  }

  bool _isPureFieldMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow) {
      return false;
    }
    if (move.effects.isEmpty) {
      return false;
    }
    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => true,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => true,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );
  }

  bool _allowsBridgeableStructuredPartialMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }

    // Ce seam reste volontairement très fermé :
    // - R2 puis ce mini-lot n'ouvrent pas un bridge "un peu permissif" pour
    //   tous les moves partiels ;
    // - on autorise seulement deux sous-cas explicitement prouvés par le repo :
    //   1. les vieux field moves type `Trick Room` déjà réellement exécutables ;
    //   2. les catalogues locaux plus anciens qui ont déclassé à tort un move
    //      simple uniquement à cause de la métadonnée Showdown `zMove`.
    // - tout autre `structuredPartial` continue à être refusé par défaut.
    return _allowsStructuredPartialFieldMove(move) ||
        _allowsStructuredPartialMetadataOnlyMove(move);
  }

  bool _allowsStructuredPartialFieldMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }
    if (!_isPureFieldMoveCandidate(move)) {
      return false;
    }

    // Recadrage BE9 :
    // - on n'ouvre pas globalement tous les moves `structuredPartial` ;
    // - on autorise uniquement les vieux catalogues qui marquaient encore
    //   `Trick Room` comme partiel faute de couche de champ/durée ;
    // - tout autre motif de partial support reste refusé par défaut.
    const allowedReasons = <String>{
      'unsupported_mechanic:turn_order_inversion',
      'unsupported_mechanic:condition',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
    };
    return move.unsupportedReasons.every(allowedReasons.contains);
  }

  bool _allowsStructuredPartialMetadataOnlyMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }

    // Mini-lot starter coverage :
    // - certains catalogues locaux déjà convertis portent encore
    //   `unsupported_mechanic:zMove` sur des moves de base pourtant déjà
    //   totalement compatibles avec le bridge (`tail_whip`, `withdraw`, etc.) ;
    // - cette raison n'exprime pas une limite du move de base dans le slice
    //   singles local, mais seulement l'absence volontaire de support Z-Move ;
    // - autoriser ce cas précis répare donc une sous-déclaration de support
    //   sans élargir la famille de mécaniques réellement exécutées.
    const allowedReasons = <String>{
      'unsupported_mechanic:zMove',
    };
    if (move.unsupportedReasons.isEmpty ||
        !move.unsupportedReasons.every(allowedReasons.contains)) {
      return false;
    }

    // Garde-fou de périmètre :
    // - on ne rouvre surtout pas "tous les partials zMove-only" ;
    // - certains vieux labels locaux peuvent aussi toucher des status moves
    //   vides ou non-op comme `teleport`, qui ne deviendraient pas honnêtes
    //   juste parce que la cause du partial est une métadonnée Showdown ;
    // - ce mini-lot starter coverage n'autorise donc que le sous-ensemble
    //   déjà réellement exécutable aujourd'hui : un `modifyStats`
    //   déterministe sur `self` ou `target`.
    return _isPureDeterministicStatMoveCandidate(move);
  }

  bool _isPureDeterministicStatMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow || move.effects.isEmpty) {
      return false;
    }

    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (effect) =>
            effect.chance == null &&
            effect.stageChanges.isNotEmpty &&
            (effect.targetScope == PokemonMoveEffectTargetScope.self ||
                effect.targetScope == PokemonMoveEffectTargetScope.target),
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => false,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => false,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );
  }

  bool _isPureFoeSideConditionMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow || move.effects.isEmpty) {
      return false;
    }

    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => false,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => false,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (effect) =>
            effect.targetScope == PokemonMoveEffectTargetScope.foeSide &&
            effect.chance == null,
        setSlotCondition: (_) => false,
      ),
    );
  }

  String? _normalizeOptionalId(String? value) {
    if (value == null) {
      return null;
    }
    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  Never _rejectUnsupportedStat({
    required PokemonMove move,
    required String combatantLabel,
    required PokemonMoveStatId stat,
  }) {
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'unsupported_stat_stage:${stat.name}',
    );
  }

  Never _rejectMove({
    required PokemonMove move,
    required String combatantLabel,
    required String bridgeLimit,
  }) {
    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons, bridgeLimit=$bridgeLimit',
    );
  }
}

```

### `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';

void main() {
  group('RuntimeBattleMoveBridge', () {
    const bridge = RuntimeBattleMoveBridge();

    test('projects a standard damage move without destroying canonical data',
        () {
      const move = PokemonMove(
        id: 'vine_whip',
        name: 'Vine Whip',
        names: <String, String>{'en': 'Vine Whip'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 45,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('vine_whip'));
      expect(battleMove.power, equals(45));
      expect(battleMove.type, equals('grass'));
      expect(battleMove.category, equals(BattleMoveCategory.physical));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(100));
      expect(battleMove.pp, equals(25));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test('projects a deterministic target stat drop move honestly', () {
      const move = PokemonMove(
        id: 'growl',
        name: 'Growl',
        names: <String, String>{'en': 'Growl'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.type, equals('normal'));
      expect(battleMove.category, equals(BattleMoveCategory.status));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(battleMove.pp, equals(40));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, hasLength(1));
      expect(
        battleMove.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.targetStatStageChanges.single.stages,
        equals(-1),
      );
    });

    test('projects a deterministic self stat boost move honestly', () {
      const move = PokemonMove(
        id: 'swords_dance',
        name: 'Swords Dance',
        names: <String, String>{'en': 'Swords Dance'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.pp, equals(20));
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test(
        'accepts a zMove-only partial label when the underlying move is just a deterministic self stat boost already supported by battle',
        () {
      const move = PokemonMove(
        id: 'withdraw',
        name: 'Withdraw',
        names: <String, String>{'en': 'Withdraw'},
        generation: 1,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.defense,
                stages: 1,
              ),
            ],
          ),
        ],
        // Mini-lot starter coverage :
        // - certains catalogues déjà convertis portent encore ce partial à
        //   cause de la seule métadonnée Showdown `zMove` ;
        // - on veut prouver ici que le bridge ne rouvre pas "les partials"
        //   en général, mais seulement ce cas legacy déjà exécutable.
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>['unsupported_mechanic:zMove'],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('withdraw'));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.defense),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(1),
      );
    });

    test(
        'still rejects Bubble honestly because a probabilistic speed drop rider is not part of the current bridge contract',
        () {
      const move = PokemonMove(
        id: 'bubble',
        name: 'Bubble',
        names: <String, String>{'en': 'Bubble'},
        generation: 1,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:probabilistic_modify_stats',
        ],
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=bubble'),
              contains('engineSupportLevel=structuredPartial'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:probabilistic_modify_stats]',
              ),
              contains('bridgeLimit=engine_support_level_not_bridgeable'),
            ),
          ),
        ),
      );
    });

    test(
        'rejects a self-target damage move that map_battle would still resolve against the opponent',
        () {
      const move = PokemonMove(
        id: 'mind_blown_self',
        name: 'Mind Blown Self',
        names: <String, String>{'en': 'Mind Blown Self'},
        generation: 9,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.self,
        basePower: 50,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=mind_blown_self'),
              contains('bridgeLimit=unsupported_standard_damage_target:self'),
            ),
          ),
        ),
      );
    });

    test(
        'projects a move with non-zero priority once battle order consumes it honestly',
        () {
      const move = PokemonMove(
        id: 'quick_attack',
        name: 'Quick Attack',
        names: <String, String>{'en': 'Quick Attack'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        priority: 1,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('quick_attack'));
      expect(battleMove.priority, equals(1));
      expect(battleMove.power, equals(40));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('projects a deterministic speed boost move honestly', () {
      const move = PokemonMove(
        id: 'agility',
        name: 'Agility',
        names: <String, String>{'en': 'Agility'},
        generation: 1,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.speed),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
    });

    test(
        'projects a move with non-trivial percent accuracy once battle owns the hit check',
        () {
      const move = PokemonMove(
        id: 'fire_blast',
        name: 'Fire Blast',
        names: <String, String>{'en': 'Fire Blast'},
        generation: 1,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 110,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('fire_blast'));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(85));
      expect(battleMove.pp, equals(5));
    });

    test(
        'rejects a move whose type is not actually supported by the current battle type chart',
        () {
      const move = PokemonMove(
        id: 'typo_bolt',
        name: 'Typo Bolt',
        names: <String, String>{'en': 'Typo Bolt'},
        generation: 1,
        source: 'test',
        type: 'electrik',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 80,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=typo_bolt'),
              contains('moveName=Typo Bolt'),
              contains('bridgeLimit=unsupported_type:electrik'),
            ),
          ),
        ),
      );
    });

    test(
        'accepts a move whose non-neutral crit ratio is now transported honestly to battle',
        () {
      const move = PokemonMove(
        id: 'razor_leaf',
        name: 'Razor Leaf',
        names: <String, String>{'en': 'Razor Leaf'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        critRatio: 2,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('razor_leaf'));
      expect(battleMove.critRatio, equals(2));
    });

    test(
        'rejects a target shape that is still outside the honest 1v1 bridge subset',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=stealth_rock'),
              contains('bridgeLimit=unsupported_target:foeSide'),
            ),
          ),
        ),
      );
    });

    test('supports a deterministic major status move in the BE7 subset', () {
      const move = PokemonMove(
        id: 'thunder_wave',
        name: 'Thunder Wave',
        names: <String, String>{'en': 'Thunder Wave'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, isNull);
    });

    test(
        'supports a probabilistic major status effect once battle owns the RNG',
        () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: <String, String>{'en': 'Thunderbolt'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(90));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, equals(10));
    });

    test(
        'supports the exact protect volatile subset instead of reopening all applyVolatileStatus',
        () {
      const move = PokemonMove(
        id: 'protect',
        name: 'Protect',
        names: <String, String>{'en': 'Protect'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.self,
            volatileStatusId: 'protect',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(
        battleMove.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
    });

    test('supports a breakProtect damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'feint',
        name: 'Feint',
        names: <String, String>{'en': 'Feint'},
        generation: 4,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 30,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.breakProtect(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.breaksProtect, isTrue);
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('supports a requireRecharge damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'hyper_beam',
        name: 'Hyper Beam',
        names: <String, String>{'en': 'Hyper Beam'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 150,
        accuracy: PokemonMoveAccuracy.percent(value: 90),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.requiresRecharge, isTrue);
      expect(battleMove.power, equals(150));
    });

    test('supports a chargeThenStrike damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'solar_beam',
        name: 'Solar Beam',
        names: <String, String>{'en': 'Solar Beam'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(
        battleMove.chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test(
        'still rejects a noncanonical move that combines chargeThenStrike and requireRecharge',
        () {
      const move = PokemonMove(
        id: 'bad_combo_beam',
        name: 'Bad Combo Beam',
        names: <String, String>{'en': 'Bad Combo Beam'},
        generation: 9,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
          PokemonMoveEffect.chargeThenStrike(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains(
              'bridgeLimit=unsupported_combined_charge_then_recharge',
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported major statuses even when applyStatus is now partially bridgeable',
        () {
      const move = PokemonMove(
        id: 'sleep_powder',
        name: 'Sleep Powder',
        names: <String, String>{'en': 'Sleep Powder'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 75),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'slp',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_major_status:slp'),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported applyVolatileStatus outside the protect subset',
        () {
      const move = PokemonMove(
        id: 'confuse_ray',
        name: 'Confuse Ray',
        names: <String, String>{'en': 'Confuse Ray'},
        generation: 1,
        source: 'test',
        type: 'ghost',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            volatileStatusId: 'confusion',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains(
              'bridgeLimit=unsupported_apply_volatile_status_scope:target',
            ),
          ),
        ),
      );
    });

    test('supports the exact Rain Dance weather subset in BE9', () {
      const move = PokemonMove(
        id: 'rain_dance',
        name: 'Rain Dance',
        names: <String, String>{'en': 'Rain Dance'},
        generation: 2,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.rain));
      expect(battleMove.pseudoWeatherEffect, isNull);
    });

    test(
        'rejects a malformed self-target field move instead of widening the BE9 field contract',
        () {
      const move = PokemonMove(
        id: 'bad_self_rain',
        name: 'Bad Self Rain',
        names: <String, String>{'en': 'Bad Self Rain'},
        generation: 9,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_field_target:self'),
          ),
        ),
      );
    });

    test('supports the exact Sandstorm weather subset in BE9', () {
      const move = PokemonMove(
        id: 'sandstorm',
        name: 'Sandstorm',
        names: <String, String>{'en': 'Sandstorm'},
        generation: 2,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sandstorm',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.sandstorm));
    });

    test(
        'supports the exact Trick Room pseudoWeather subset without reopening all structuredPartial moves',
        () {
      const move = PokemonMove(
        id: 'trick_room',
        name: 'Trick Room',
        names: <String, String>{'en': 'Trick Room'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        priority: -7,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'trickroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:turn_order_inversion',
          'showdown_callback:condition.durationCallback',
          'showdown_callback:condition.onFieldEnd',
        ],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(
        battleMove.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(battleMove.priority, equals(-7));
    });

    test('still rejects unsupported weather ids outside the BE9 subset', () {
      const move = PokemonMove(
        id: 'sunny_day',
        name: 'Sunny Day',
        names: <String, String>{'en': 'Sunny Day'},
        generation: 2,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sunnyday',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_weather:sunnyday'),
          ),
        ),
      );
    });

    test('still rejects unsupported pseudoWeather ids outside the BE9 subset',
        () {
      const move = PokemonMove(
        id: 'magic_room',
        name: 'Magic Room',
        names: <String, String>{'en': 'Magic Room'},
        generation: 5,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'magicroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_pseudo_weather:magicroom'),
          ),
        ),
      );
    });

    test('still rejects setTerrain because BE9 does not open terrains', () {
      const move = PokemonMove(
        id: 'electric_terrain',
        name: 'Electric Terrain',
        names: <String, String>{'en': 'Electric Terrain'},
        generation: 6,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setTerrain(
            targetScope: PokemonMoveEffectTargetScope.field,
            terrainId: 'electricterrain',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:all'),
              contains('bridgeLimit=unsupported_effect_kind:set_terrain'),
            ),
          ),
        ),
      );
    });

    test('supports Stealth Rock as the first honest side-level hazard slice',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'stealthrock',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.opponentSide));
      expect(battleMove.setsStealthRock, isTrue);
    });

    test('supports Spikes as the second honest side-level hazard slice', () {
      const move = PokemonMove(
        id: 'spikes',
        name: 'Spikes',
        names: <String, String>{'en': 'Spikes'},
        generation: 2,
        source: 'test',
        type: 'ground',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'spikes',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.opponentSide));
      expect(battleMove.setsSpikes, isTrue);
    });

    test(
        'still rejects unsupported side conditions beyond Stealth Rock and Spikes',
        () {
      const move = PokemonMove(
        id: 'toxic_spikes',
        name: 'Toxic Spikes',
        names: <String, String>{'en': 'Toxic Spikes'},
        generation: 4,
        source: 'test',
        type: 'poison',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'toxicspikes',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_side_condition:toxicspikes'),
          ),
        ),
      );
    });

    test('still rejects setSlotCondition because BE9 does not open slot state',
        () {
      const move = PokemonMove(
        id: 'healing_wish',
        name: 'Healing Wish',
        names: <String, String>{'en': 'Healing Wish'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSlotCondition(
            targetScope: PokemonMoveEffectTargetScope.slot,
            conditionId: 'healingwish',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:self'),
              contains(
                  'bridgeLimit=unsupported_effect_kind:set_slot_condition'),
              contains('bridgeLimit=unsupported_target:slot'),
            ),
          ),
        ),
      );
    });
  });
}

```

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.playerPokemon.typing!.primaryType, equals('grass'));
      expect(setup.playerPokemon.typing!.secondaryType, isNull);
      expect(setup.playerPokemon.stats.attack, equals(16));
      expect(setup.playerPokemon.stats.specialAttack, equals(20));
      expect(setup.playerPokemon.stats.speed, equals(15));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'tail_whip'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test(
        'maps player reserves from the real party and excludes bench members already KO',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-reserve',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 23,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 17,
              ),
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'rash',
                abilityId: 'blaze',
                level: 16,
                knownMoveIds: <String>['ember'],
                currentHp: 0,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerReservePokemon, hasLength(1));
      expect(setup.playerReservePokemon.single.speciesId, equals('aquafi'));
      expect(setup.playerReservePokemon.single.lineupIndex, equals(1));
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('fire'));
      expect(setup.enemyPokemon.typing!.secondaryType, isNull);
      expect(setup.enemyPokemon.stats.attack, equals(15));
      expect(setup.enemyPokemon.stats.specialAttack, equals(17));
      expect(setup.enemyPokemon.stats.speed, equals(18));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .targetStatStageChanges
            .single
            .stat,
        equals(BattleStatId.defense),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test(
        'preserves typing through to battle so STAB and effectiveness are really consumed',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-type-bridge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 12,
                knownMoveIds: <String>['ember'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sproutle',
          level: 10,
        ),
      );

      final session = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );

      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(execution.move.id, equals('ember'));
      expect(execution.didHit, isTrue);
      expect(execution.stabMultiplier, equals(1.5));
      expect(execution.typeEffectivenessMultiplier, equals(2.0));
      expect(execution.damage, greaterThan(0));
    });

    test(
        'maps a non-trivial accuracy move honestly through to battle, where it can miss deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-accuracy',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['mud_slap'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(
        setup.playerPokemon.moves.single.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(setup.playerPokemon.moves.single.accuracy.value, equals(85));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 100]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('mud_slap'));
      expect(execution.didHit, isFalse);
      expect(session.state.enemy.currentHp, equals(setup.enemyPokemon.maxHp));
    });

    test(
        'maps a non-neutral crit ratio honestly through to battle, where it can crit deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-crits',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['razor_leaf'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(setup.playerPokemon.moves.single.id, equals('razor_leaf'));
      expect(setup.playerPokemon.moves.single.critRatio, equals(2));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 1]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('razor_leaf'));
      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isTrue);
      expect(execution.criticalMultiplier, equals(1.5));
      expect(execution.damage, greaterThan(0));
    });

    test('falls back to the species id when the species has no learnset ref',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-species-id-fallback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'tail_whip'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('water'));
      expect(setup.enemyPokemon.typing!.secondaryType, equals('fairy'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
      expect(setup.enemyReservePokemon, isEmpty);
    });

    test('maps trainer reserves instead of stopping at trainer.team.first',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun'],
              ),
              ProjectTrainerPokemonEntry(
                speciesId: 'sparkitten',
                level: 17,
                moves: <String>['ember'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyReservePokemon, hasLength(1));
      expect(setup.enemyReservePokemon.single.speciesId, equals('sparkitten'));
      expect(setup.enemyReservePokemon.single.lineupIndex, equals(1));
    });

    test(
        'maps a trainer with explicit mixed moves by keeping only the bridgeable subset',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['teleport', 'water_gun'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun']),
      );
    });

    test(
        'mapped trainer multi-mon battle auto-replaces the enemy instead of ending on the first KO',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['growl'],
              ),
              ProjectTrainerPokemonEntry(
                speciesId: 'sparkitten',
                level: 17,
                moves: <String>['ember'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trainer-reserve',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 40,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 99,
              ),
            ],
          ),
        ),
        request: _trainerRequest(),
      );

      final afterTurn = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('sparkitten'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .where((event) => event.actor == 'enemy'),
        hasLength(1),
      );
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'keeps a battle setup honest when explicit known moves mix unsupported and supported entries',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-known-move-filtering',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['teleport', 'vine_whip'],
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves
            .map((move) => move.id)
            .toList(growable: false),
        equals(<String>['vine_whip']),
      );

      final session = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );

      expect(execution.move.id, equals('vine_whip'));
    });

    test(
        'keeps Squirtle starter coverage honest by exposing only the starter moves the current battle slice can really execute',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _writeSquirtleStarterCoverageFixture(tempProjectRoot);
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-squirtle-starter-coverage',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'squirtle',
                natureId: 'bold',
                abilityId: 'torrent',
                level: 12,
                knownMoveIds: <String>[
                  'tail_whip',
                  'water_gun',
                  'withdraw',
                  'bubble',
                ],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      // Ce test verrouille le résultat produit attendu de ce mini-lot :
      // - `tail_whip`, `water_gun` et `withdraw` ne doivent plus disparaître
      //   à cause d'un truth/filtering décalé ;
      // - `bubble` reste volontairement absent tant que le moteur/bridge ne
      //   savent pas porter honnêtement son rider probabiliste de baisse de
      //   vitesse ;
      // - on améliore donc la vérité des choix de combat sans rouvrir R3.
      expect(
        setup.playerPokemon.moves
            .map((move) => move.id)
            .toList(growable: false),
        equals(<String>['tail_whip', 'water_gun', 'withdraw']),
      );

      final request = createBattleSession(setup).decisionRequest;
      expect(request, isA<BattleTurnChoiceRequest>());
      final moveChoices = (request as BattleTurnChoiceRequest)
          .moveChoices
          .map((choice) => setup.playerPokemon.moves[choice.moveIndex].id)
          .toList(growable: false);

      expect(
          moveChoices, equals(<String>['tail_whip', 'water_gun', 'withdraw']));
      expect(moveChoices, isNot(contains('bubble')));
    });

    test(
        'fails explicitly when explicit known moves leave no bridgeable move after filtering',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-no-bridgeable-known-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['teleport'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('aucun move bridgeable restant après filtrage'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('candidateMoveIds=[teleport]'),
                  contains('rejectedMoveIds=[teleport]'),
                  contains('moveId=teleport'),
                  contains('moveName=Teleport'),
                  contains('unsupportedReasons=[unsupported_mechanic:zMove]'),
                  contains(
                    'resolutionHint=assign_at_least_one_bridgeable_move',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'filters learnset-derived moves and keeps the bridgeable subset when at least one move remains',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-derived-filtered-move',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves
            .map((move) => move.id)
            .toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
    });

    test(
        'fails explicitly when a learnset-derived move list has no bridgeable move after filtering',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'vine_whip',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-derived-no-bridgeable-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('aucun move bridgeable restant après filtrage'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('candidateMoveIds=[tackle, growl, vine_whip]'),
                  contains('rejectedMoveIds=[tackle, growl, vine_whip]'),
                  contains('moveId=tackle'),
                  contains('moveId=growl'),
                  contains('moveId=vine_whip'),
                  contains(
                    'resolutionHint=assign_at_least_one_bridgeable_move',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'maps a supported major status move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-major-status',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['thunder_wave'],
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves.single.id, equals('thunder_wave'));
      expect(
        setup.playerPokemon.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );

      final session = createBattleSession(setup);
      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.majorStatus?.id,
          equals(BattleMajorStatusId.par));
      expect(
        afterTurn.state.currentTurn?.statusEvents
            .where((event) => event.kind == BattleStatusEventKind.applied)
            .single
            .sourceMoveId,
        equals('thunder_wave'),
      );
    });

    test(
        'maps a supported requireRecharge move and keeps the forced follow-up honest in battle',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-recharge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 80,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 120,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'aquafi',
          level: 80,
        ),
      );

      expect(setup.playerPokemon.moves.single.requiresRecharge, isTrue);

      final afterAttack = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[1, 24, 24, 24]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterAttack.state.player.volatileState.mustRecharge, isTrue);
      expect(afterAttack.getAvailableChoices().single,
          isA<PlayerBattleChoiceContinue>());

      final afterRecharge =
          afterAttack.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterRecharge.state.player.volatileState.mustRecharge, isFalse);
      expect(
        afterRecharge.state.currentTurn?.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeTurnSpent)
            .single
            .actor,
        equals('player'),
      );
    });

    test('maps a supported weather move and lets battle consume rain honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final rainySetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-dance',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['rain_dance', 'water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        rainySetup.playerPokemon.moves.first.weatherEffect,
        equals(BattleWeatherId.rain),
      );

      final rainySession = createBattleSession(rainySetup);
      final afterRain =
          rainySession.applyChoice(const PlayerBattleChoiceFight(0));
      final rainyAttack =
          afterRain.applyChoice(const PlayerBattleChoiceFight(1));
      final rainyDamage = rainyAttack.state.currentTurn!.executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      final neutralSetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-neutral',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      final neutralDamage = createBattleSession(neutralSetup)
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      expect(afterRain.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterRain.state.currentTurn!.fieldEvents
            .where((event) => event.kind == BattleFieldEventKind.weatherSet)
            .single
            .weather,
        equals(BattleWeatherId.rain),
      );
      expect(rainyDamage, greaterThan(neutralDamage));
    });

    test('maps a supported Trick Room move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trick-room',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['trick_room', 'tackle'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.first.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(setup.playerPokemon.moves.first.priority, equals(-7));

      final session = createBattleSession(setup);
      final afterRoom = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterAttack =
          afterRoom.applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        afterRoom.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterAttack.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'tail_whip',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry(
          'teleport',
          'Teleport',
          0,
          target: PokemonMoveTarget.self,
          pp: 20,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>['unsupported_mechanic:zMove'],
        ),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        // Mini-lot starter coverage :
        // - `withdraw` reste bridgeable malgré un vieux partial `zMove` ;
        // - `bubble` reste visible dans le catalogue de test, mais marqué
        //   partiel pour que le runtime le filtre honnêtement tant que le
        //   rider probabiliste de baisse de vitesse n'est pas supporté.
        _moveEntry(
          'withdraw',
          'Withdraw',
          0,
          type: 'water',
          target: PokemonMoveTarget.self,
          pp: 40,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>['unsupported_mechanic:zMove'],
        ),
        _moveEntry(
          'bubble',
          'Bubble',
          40,
          type: 'water',
          target: PokemonMoveTarget.allAdjacentFoes,
          pp: 30,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:probabilistic_modify_stats',
          ],
        ),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  int priority = 0,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    priority: priority,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  // Ces fixtures de mapper restent volontairement petites et canoniques :
  // - on encode seulement les effets déjà réellement consommés par le moteur ;
  // - BE9 ajoute ici juste assez de champ pour pluie / tempête de sable /
  //   Trick Room ;
  // - on ne crée pas un faux mini-catalogue parallèle plus riche que le repo.
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'withdraw' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.self,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: 1,
            ),
          ],
        ),
      ],
    'bubble' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          chance: 10,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.speed,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _writeSquirtleStarterCoverageFixture(Directory projectRoot) async {
  // Cette fixture locale sert uniquement à verrouiller le symptôme produit
  // visé par ce mini-lot :
  // - un Squirtle avec quatre moves connus côté menu ;
  // - trois moves réellement bridgeables aujourd'hui ;
  // - `bubble` toujours visible dans les données connues, mais filtré avant
  //   le combat tant que son rider probabiliste n'est pas porté honnêtement.
  //
  // On reste volontairement loin d'un chantier R3 :
  // - pas de nouvelle famille de conditions ;
  // - pas de widening de contrat ;
  // - juste un cas lisible qui prouve la cohérence menu -> runtime -> battle.
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/999-squirtle.json',
    <String, dynamic>{
      'id': 'squirtle',
      'slug': 'squirtle',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Squirtle'},
      'speciesName': <String, String>{'en': 'Tiny Turtle'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'squirtle',
        'evolution': 'squirtle',
        'media': 'squirtle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/squirtle.json',
    <String, dynamic>{
      'speciesId': 'squirtle',
      'startingMoves': <String>['tail_whip'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'bubble',
          'level': 8,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'withdraw',
          'level': 10,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  // Le helper reste volontairement minimal :
  // - il ne change que le niveau de support/runtime reasons d'une entrée déjà
  //   canonique ;
  // - il évite de dupliquer un second seed de test complet juste pour deux
  //   cas M5-bis ;
  // - il garde les fixtures globales existantes lisibles et stables.
  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason: 'Expected to find move "$moveId" in the canonical runtime fixture.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{
        'primary': primaryAbilityId,
      },
      // Ce helper retire volontairement `refs.learnset` pour vérifier que le
      // mapper, via le loader learnset, retombe bien sur l'id de l'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

```
