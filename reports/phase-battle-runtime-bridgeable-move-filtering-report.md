# 1. Résumé exécutif honnête

Ce lot corrige un vrai problème de handoff runtime -> battle, sans ouvrir de nouvelle mécanique battle.

Le bug confirmé était le suivant :
- `RuntimeBattleCombatantSeedBuilder` annulait tout le combat dès que le premier move candidat ne passait pas le bridge runtime -> battle ;
- cela faisait échouer des combats pourtant honnêtement jouables dès lors qu’au moins un autre move restait bridgeable ;
- le cas observé en runtime avec `teleport` sur le Pokémon actif du joueur était donc un vrai bug de sélection/assemblage des seeds, pas un besoin d’élargir le moteur battle.

Le fix retenu est strictement local :
- on garde la politique métier existante de sélection des moves candidates ;
- on filtre localement les moves non bridgeables lors de l’assemblage des seeds ;
- on n’invente jamais de move de remplacement ;
- on n’élargit pas `RuntimeBattleMoveBridge` de manière large et risquée ;
- on échoue explicitement seulement s’il ne reste aucun move bridgeable après filtrage ;
- on garde un hard fail pour les vrais problèmes de données/canonique non filtrables.

Verdict honnête :
- oui, c’est un vrai fix de code ;
- non, ce n’est pas un élargissement général de `structuredPartial` ;
- non, ce n’est pas un toilettage cosmétique ;
- le combat ne s’annule plus juste parce qu’un move comme `teleport` est présent, tant qu’un move réellement bridgeable reste disponible.

# 2. Pré-gates exécutés + résultats

## Pré-gates git lecture seule

Commandes exécutées avant modification :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Résultat initial :
- `git status --short` a montré un worktree déjà non propre à cause d’un report non tracké préexistant :
  - `?? reports/phase-battle-post-be10a-consistency-audit-report.md`
- `git diff --stat` était vide au départ
- `git ls-files --others --exclude-standard` montrait le même report non tracké

Conclusion honnête :
- il y avait bien du bruit préexistant dans le worktree ;
- ce bruit n’était pas causé par ce lot ;
- il a été conservé tel quel et distingué explicitement du travail BE10A-bis.

## Pré-gates runtime ciblés

Commandes demandées :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Résultat honnête :
- j’ai bien lancé ces validations au début ;
- je les ai d’abord lancées en parallèle ;
- cela a provoqué un incident d’outillage Flutter (`startup lock`) ;
- le lot n’a pas été validé sur cette première tentative brute ;
- j’ai ensuite relancé les validations utiles en séquentiel après implémentation et après correction review ;
- l’état final utile est vert, documenté en section 12.

Classification honnête :
- pré-gates git : exécutés proprement avant code ;
- pré-gates runtime : tentés avant code, mais pollués par un incident d’outillage ; état final rerun proprement plus tard.

# 3. État initial audité réel

Fichiers audités en priorité :
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_exception.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

Constats confirmés avant modification :
- `RuntimeBattleCombatantSeedBuilder._resolveBattleMoves(...)` résolvait les moves candidates puis appelait `battleMoveBridge.toBattleMoveData(...)` en laissant remonter la première `RuntimeBattleSetupException`.
- Cela faisait échouer tout le seed assembly du combattant même si le move suivant était honnêtement bridgeable.
- La logique de sélection métier existante était déjà :
  - normalisation des ids ;
  - unicité préservant l’ordre ;
  - limite à 4 moves.
- Le bridge contenait déjà des refus explicites détaillés :
  - `engineSupportLevel`
  - `unsupportedReasons`
  - `bridgeLimit`
- `RuntimeBattleSetupMapper` orchestrait correctement actif/réserves, mais n’apportait pas la bonne granularité d’échec pour les réserves joueur : sans label spécifique, une réserve non bridgeable risquait encore de se présenter comme “Le Pokémon actif du joueur”.

Constats non confirmés :
- je n’ai trouvé aucune nécessité réelle d’élargir `RuntimeBattleMoveBridge` pour corriger le cas `teleport`.
- je n’ai trouvé aucun besoin de modifier `map_battle`.
- je n’ai trouvé aucun besoin de backfill depuis le learnset quand `knownMoveIds` explicites sont fournis.

# 4. Problèmes confirmés / non confirmés

## Problèmes confirmés

1. Le handoff runtime -> battle échouait trop tôt.
   - Un seul move non bridgeable annulait le combat entier.

2. Le seam de sélection des moves n’était pas assez honnête.
   - Il manquait une étape locale “garder le sous-ensemble bridgeable de la liste déjà choisie”.

3. Le message d’échec final était insuffisant quand aucun move ne restait.
   - Il fallait expliciter :
     - le combattant concerné ;
     - les moveIds candidats ;
     - les moveIds rejetés ;
     - les raisons utiles déjà connues du bridge ;
     - le fait qu’aucun move bridgeable ne restait après filtrage.

4. Les labels d’erreur côté réserves joueur étaient trop génériques.
   - Une réserve non bridgeable devait être identifiée comme réserve, pas comme actif.

## Points non confirmés

1. “Il faut élargir le bridge pour laisser passer `teleport`.”
   - Faux pour ce lot.
   - Le besoin réel était de filtrer localement les moves non bridgeables au seed assembly.

2. “Il faut transformer globalement les `structuredPartial` en bridgeables.”
   - Faux et dangereux.
   - Le bridge devait rester strict.

3. “Il suffit de patcher uniquement `RuntimeBattleSetupMapper`.”
   - Incomplet.
   - Le point central réel était `RuntimeBattleCombatantSeedBuilder`.

# 5. Cause racine réelle

La cause racine n’était pas un manque de mécanique battle.

La vraie cause racine était un mauvais emplacement du fail-fast :
- la frontière runtime -> battle décidait correctement qu’un move n’était pas bridgeable ;
- mais le builder traitait ce refus comme une raison d’annuler tout le combattant ;
- il manquait une étape de filtrage locale au seam d’assemblage des moves.

Autrement dit :
- le bridge savait déjà dire “ce move-là ne passe pas honnêtement” ;
- le builder ne savait pas encore dire “très bien, on enlève ce move et on continue avec les autres tant qu’au moins un reste”.

# 6. Décisions retenues / rejetées

## Décisions retenues

1. Filtrer localement dans `RuntimeBattleCombatantSeedBuilder`.
   - C’est l’endroit où la liste candidate existe déjà.
   - C’est le seam le plus petit.
   - Cela évite d’élargir le bridge.

2. Préserver strictement la politique métier existante.
   - ordre existant conservé ;
   - unicité existante conservée ;
   - limite à 4 conservée.

3. Ne jamais backfiller.
   - si `knownMoveIds` explicites existent, seuls ces moves sont considérés ;
   - si certains sont rejetés, on ne complète pas avec le learnset ;
   - si tous sont rejetés, on échoue explicitement.

4. Garder les erreurs de données non filtrables en hard fail.
   - le filtrage ne doit pas masquer une corruption ou une incohérence canonique/runtime.

5. Améliorer le message d’erreur final.
   - ajout de `candidateMoveIds`
   - ajout de `rejectedMoveIds`
   - ajout du détail de chaque move rejeté
   - ajout du marqueur `filterResult=no_bridgeable_moves_remaining_after_filtering`

6. Raffiner le label du combattant pour les réserves joueur.
   - améliore l’honnêteté du message sans ouvrir de refactor.

## Décisions rejetées

1. Rendre `teleport` bridgeable.
   - hors scope ;
   - mécaniquement faux ;
   - plus risqué que le fix local.

2. Marquer globalement certains `structuredPartial` comme supportés.
   - trop large ;
   - potentiellement mensonger ;
   - non nécessaire.

3. Backfill automatique avec des moves learnset quand des `knownMoveIds` explicites échouent.
   - contraire à la contrainte utilisateur ;
   - masque l’état réel du Pokémon runtime.

4. Filtrer absolument toute `RuntimeBattleSetupException` venant du bridge.
   - trop large ;
   - la review a montré que cela pouvait masquer un rejet non filtrable.

# 7. Critique explicite du prompt

## Ce qui était juste

- La préférence pour un fix local au niveau de l’assemblage des seeds était la bonne.
- La consigne de ne pas élargir le bridge globalement était juste.
- Les cas de test demandés étaient pertinents.
- L’exigence “pas de move inventé, pas de backfill” était juste.

## Ce qui était discutable

- La mention “Test Driven Development” comme méthode imposée était raisonnable comme intention, mais je n’ai pas tenu un pur cycle red -> green sur chaque micro-étape. J’ai d’abord audité, puis posé l’implémentation locale, puis durci/complété les tests avant la validation finale. Je le signale explicitement.
- La mention “Using Git Worktrees si pertinent” était discutable ici : le lot était trop petit et trop local pour qu’un worktree apporte une vraie valeur.

## Ce qui aurait été dangereux si suivi aveuglément

- Interpréter “filtrer les moves non bridgeables” comme “avaler n’importe quelle erreur bridge” aurait été dangereux.
- Cela aurait pu masquer des problèmes de données invalides au lieu de les signaler honnêtement.

## Recadrage retenu

- Le filtrage n’avale que les refus réellement “bridgeables mais non supportés” dans ce lot.
- Les erreurs non filtrables restent des hard fails explicites.
- Le bridge reste strict.

# 8. Périmètre inclus / exclu

## Inclus

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- le présent report

## Exclus

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
  - audité, mais non élargi sur le fond.
- `/Users/karim/Project/pokemonProject/packages/map_core`
- `/Users/karim/Project/pokemonProject/packages/map_editor`
- `map_battle`
- nouvelles mécaniques battle
- `selfSwitch`
- `forceSwitch`
- hazards
- doubles
- items
- abilities
- refactor cosmétique large

# 9. Liste exacte des fichiers modifiés / créés / supprimés

## Modifiés par ce lot

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

## Créé par ce lot

- `/Users/karim/Project/pokemonProject/reports/phase-battle-runtime-bridgeable-move-filtering-report.md`

## Supprimé par ce lot

- aucun

## Bruit préexistant explicitement non causé par ce lot

- `/Users/karim/Project/pokemonProject/reports/phase-battle-post-be10a-consistency-audit-report.md`
  - déjà non tracké avant modification ;
  - laissé intact ;
  - non compté comme modification de ce lot.

# 10. Justification fichier par fichier

## `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

Fichier principal du fix.

Rôle des changements :
- filtrer localement les moves non bridgeables ;
- conserver ordre/unicité/limite à 4 ;
- échouer seulement si aucun move bridgeable ne reste ;
- conserver un hard fail pour les erreurs non filtrables ;
- enrichir le message final.

## `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

Changement minimal d’orchestration.

Rôle des changements :
- fournir des labels de combattants plus honnêtes ;
- distinguer l’actif joueur des réserves joueur dans les messages d’échec ;
- ne pas changer la logique battle globale.

## `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`

Tests unitaires ciblés sur le seam principal.

Rôle des changements :
- prouver le filtrage sur `knownMoveIds` explicites ;
- prouver l’échec quand aucun move bridgeable ne reste ;
- prouver le cas learnset dérivé ;
- prouver qu’un rejet bridge non filtrable n’est pas avalé.

## `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

Tests d’intégration runtime plus haut niveau.

Rôle des changements :
- prouver que le setup battle ne s’annule plus sur un mix supporté/non supporté ;
- prouver le cas trainer explicite mixte ;
- prouver le cas learnset mixte ;
- prouver un vrai handoff runtime -> battle avec sous-ensemble bridgeable restant.

## `/Users/karim/Project/pokemonProject/reports/phase-battle-runtime-bridgeable-move-filtering-report.md`

Report complet exigé par la tâche.

# 11. Commandes réellement exécutées

## Git lecture seule

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## Audit / recherche

```bash
rg --files -g 'AGENTS.md'
rg -n "teleport|structuredPartial|unsupportedReasons|engineSupportLevel|bridgeLimit" packages/map_runtime
rg -n "bridgeLimit:|invalid_|empty_modify_stats_not_supported|engine_support_level_not_bridgeable|unsupported_effect_kind|unsupported_" lib/src/application/runtime_battle_move_bridge.dart
wc -l packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
sed -n '...p' <fichiers audités>
cat <fichiers modifiés>
nl -ba test/runtime_battle_combatant_seed_builder_test.dart | sed -n '398,415p'
```

## Validation / format

Tentatives initiales parallèles qui ont provoqué un lock Flutter :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Format exécuté pendant le lot :

```bash
cd packages/map_runtime && /opt/homebrew/bin/dart format \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart

cd packages/map_runtime && /opt/homebrew/bin/dart format \
  test/runtime_battle_combatant_seed_builder_test.dart
```

Tests ciblés intermédiaires :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart
```

Validation finale séquentielle :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

# 12. Résultats réels de format / analyze / tests

## Format

Résultat final :
- `dart format` sur les 4 fichiers runtime touchés : vert, aucun changement final restant.

## Analyze

Résultat final utile :

```text
No issues found! (ran in 0.9s)
```

Surface validée :
- `runtime_battle_move_bridge.dart`
- `runtime_battle_combatant_seed_builder.dart`
- `runtime_battle_setup_mapper.dart`
- tests runtime ciblés utiles

## Tests

Résultat final utile :
- `flutter test` sur la surface runtime ciblée élargie : vert
- tous les tests listés dans la validation finale sont passés

Résultat intermédiaire important :
- un run test intermédiaire a échoué parce que le premier test “malformed move data” cassait le loader canonique avant le bridge ;
- ce test a été recadré vers un faux bridge ciblé, puis la suite finale est redevenue verte.

# 13. Incidents rencontrés

1. Worktree déjà sale au départ.
   - report non tracké préexistant.

2. Lock Flutter au lancement parallèle des validations.
   - incident d’outillage ;
   - pas un bug du fix ;
   - corrigé en relançant séquentiellement.

3. Premier jet du test reviewer mal ciblé.
   - j’ai d’abord essayé de produire un cas `invalid_*` via une corruption du catalogue ;
   - cela faisait tomber `RuntimeMoveCatalogLoader` avant le bridge ;
   - ce test ne démontrait donc pas le point reviewer ;
   - il a été remplacé par un faux bridge injecté au seam correct.

4. Petit incident de matcher sur `allOf`.
   - compile error intermédiaire ;
   - corrigé localement dans le test.

5. Deux petits lints analyze sur le test injecté.
   - `prefer_const_*`
   - corrigés avant validation finale.

# 14. État git utile final

## `git status --short`

```text
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? reports/phase-battle-post-be10a-consistency-audit-report.md
?? reports/phase-battle-runtime-bridgeable-move-filtering-report.md
```

## `git diff --stat`

```text
 .../runtime_battle_combatant_seed_builder.dart     | 164 +++++++++++++--
 .../application/runtime_battle_setup_mapper.dart   |  10 +-
 ...runtime_battle_combatant_seed_builder_test.dart | 222 +++++++++++++++++++--
 .../test/runtime_battle_setup_mapper_test.dart     | 210 ++++++++++++++++---
 4 files changed, 543 insertions(+), 63 deletions(-)
```

## `git ls-files --others --exclude-standard`

```text
reports/phase-battle-post-be10a-consistency-audit-report.md
reports/phase-battle-runtime-bridgeable-move-filtering-report.md
```

# 15. Checklist finale

- [x] j’ai audité le code réel avant de modifier
- [x] j’ai challengé le prompt au lieu de l’appliquer aveuglément
- [x] j’ai confirmé que le vrai problème était un fail-fast au seed assembly
- [x] je n’ai pas élargi `RuntimeBattleMoveBridge` de manière large et risquée
- [x] j’ai conservé l’ordre métier existant
- [x] j’ai conservé l’unicité existante
- [x] j’ai conservé la limite actuelle à 4 moves
- [x] je n’ai inventé aucun move de remplacement
- [x] je n’ai fait aucun backfill learnset quand `knownMoveIds` explicites existent
- [x] j’échoue explicitement quand aucun move bridgeable ne reste après filtrage
- [x] le message d’erreur final est plus honnête et plus détaillé
- [x] j’ai gardé le scope strictement local à `map_runtime`
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai pas touché `map_battle`
- [x] j’ai ajouté / ajusté des tests ciblés utiles
- [x] j’ai fait une vraie review séparée
- [x] j’ai intégré les remarques valides
- [x] j’ai relancé format
- [x] j’ai relancé analyze
- [x] j’ai relancé les tests utiles
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report dit explicitement ce qui était préexistant dans le worktree
- [x] le report contient le contenu complet des fichiers touchés

# 16. Retour du sub-agent d’audit/design

Agent utilisé :
- `Helmholtz` (`019d97d0-49de-7172-a349-737b28b47290`)

Retour utile retenu :
- le bon seam est le builder, pas le bridge ;
- il faut filtrer sur la liste déjà retenue, pas aller piocher ailleurs ;
- il faut préserver le comportement “known moves explicites = source de vérité locale”.

Retour rejeté :
- aucun finding utile rejeté ; le retour était aligné avec l’audit local.

# 17. Retour du reviewer séparé

Reviewer utilisé :
- `Cicero` (`019d97d6-0846-78b0-934a-fa29cdfa50bc`)

Retour utile retenu :
- le premier jet filtrait toutes les `RuntimeBattleSetupException` du bridge ;
- cela élargissait trop le comportement ;
- il fallait conserver un hard fail pour les erreurs non filtrables.

Retour non exploitable / incidents reviewer :
- la première attente a expiré ;
- un second retour exploitable est bien arrivé ensuite.

# 18. Corrections appliquées après review

Corrections réellement appliquées après review :
- ajout de `_RejectedBridgeMove.isFilterableDuringSeedAssembly`
- arrêt du filtrage aveugle de toutes les erreurs bridge
- conservation des hard fails pour :
  - `bridgeLimit == null`
  - `bridgeLimit.startsWith('invalid_')`
  - `bridgeLimit == 'empty_modify_stats_not_supported'`
- ajout d’un test dédié pour prouver qu’un rejet bridge non filtrable n’est pas avalé

# 19. Autocritique finale

Ce qui est bien :
- le fix est resté local ;
- le bridge n’a pas été élargi artificiellement ;
- le message d’erreur final est nettement plus utile ;
- la review a réellement amélioré le bornage du filtrage.

Ce qui aurait pu être mieux :
- je n’ai pas tenu un cycle TDD pur dès la première minute ; j’ai d’abord sécurisé la lecture du seam et posé le fix, puis élargi les tests avant validation finale.
- j’ai perdu un peu de temps sur un faux bon test “malformed data” qui attaquait le loader au lieu du bridge.
- j’ai lancé trop tôt deux commandes Flutter en parallèle alors que le lock outillage était un risque connu.

Conclusion autocritique honnête :
- le résultat final est correct et bien borné ;
- la méthode aurait gagné à être plus disciplinée sur l’ordre exact “test rouge ciblé -> patch -> rerun” dès le premier essai ;
- la review séparée a été utile, pas décorative.

# 20. Annexe — contenu complet de tous les fichiers texte touchés

Important :
- cette annexe inclut le contenu complet des fichiers modifiés par ce lot ;
- elle exclut volontairement ce report lui-même pour éviter une récursion infinie.

## `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

/// Builder runtime spécialisé des seeds de combattants injectés dans
/// `BattleSetup`.
///
/// M7 extrait ce seam pour éviter que `RuntimeBattleSetupMapper` concentre
/// encore :
/// - la sélection du membre joueur ;
/// - la lecture species/learnsets déjà extraite en M6 ;
/// - la dérivation du move set ;
/// - le gate M5-bis vers `BattleMoveData` ;
/// - le calcul de HP max ;
/// - et la construction finale des seeds de combattants.
///
/// Frontière intentionnelle :
/// - ce builder assemble des données runtime locales vers un seed battle ;
/// - il ne crée pas un framework générique de combat ;
/// - il ne modifie pas le contrat `BattleSetup` ;
/// - il ne rouvre pas M8 et n’essaie pas d’exécuter les `effects`.
class RuntimeBattleCombatantSeedBuilder {
  const RuntimeBattleCombatantSeedBuilder({
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
    this.battleMoveBridge = const RuntimeBattleMoveBridge(),
  });

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
    String combatantLabel = 'Le Pokémon actif du joueur',
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: playerPokemon.speciesId,
    );
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: combatantLabel,
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );
    final stats = _calculateStatsSnapshot(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      stats: stats,
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildWildCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: request.speciesId,
    );
    final moveIds = await _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: request.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectTrainerPokemonEntry teamMember,
    required String trainerName,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: teamMember.speciesId,
    );
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: teamMember.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    // On conserve strictement la policy M6 :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    // - unicité préservant l'ordre
    // - 4 derniers moves maximum
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    final candidateMoveIds = List<String>.unmodifiable(
      _normalizeUniqueIdsPreserveOrder(moveIds).take(4).toList(growable: false),
    );

    if (candidateMoveIds.isEmpty) {
      throw RuntimeBattleSetupException(
        '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
      );
    }

    final moves = <BattleMoveData>[];
    final rejectedMoves = <_RejectedBridgeMove>[];

    // Fix local volontaire :
    // - le bridge continue à décider ce qui est réellement exécutable ;
    // - le builder, lui, cesse d'annuler tout le handoff dès le premier move
    //   non bridgeable ;
    // - on filtre donc uniquement les refus de projection bridge -> battle,
    //   sans jamais inventer de move de remplacement ;
    // - la liste candidate reste strictement celle déjà décidée en amont :
    //   ordre métier existant, unicité existante, limite actuelle à 4.
    //
    // Conséquence métier importante :
    // - si `knownMoveIds` est explicite, on ne backfill jamais avec un learnset ;
    // - si le move set vient d'un learnset, on ne va pas chercher un cinquième
    //   move "plus loin" pour compenser un rejet ;
    // - on accepte simplement le sous-ensemble bridgeable de la liste déjà
    //   retenue, puis on échoue seulement s'il ne reste plus rien.
    for (final moveId in candidateMoveIds) {
      final move = movesCatalog.lookup(moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques ne contient pas "$moveId".',
          debugDetails: 'combatant=$combatantLabel',
        );
      }

      try {
        // M8 sort enfin la policy de projection du builder brut :
        // - le builder assemble des seeds de combattants ;
        // - le bridge décide ce qui est réellement exécutable par `map_battle` ;
        // - BE10A-bis garde cette frontière intacte et se contente ici de
        //   filtrer localement les refus bridgeables au lieu d'élargir le
        //   bridge de manière risquée.
        moves.add(
          battleMoveBridge.toBattleMoveData(
            move: move,
            combatantLabel: combatantLabel,
          ),
        );
      } on RuntimeBattleSetupException catch (error) {
        final rejectedMove = _RejectedBridgeMove.fromBridgeRejection(
          move: move,
          debugDetails: error.debugDetails,
        );

        // Le filtrage BE10A-bis doit rester borné :
        // - on accepte de retirer les moves honnêtement non bridgeables du
        //   sous-ensemble courant ;
        // - on ne doit surtout pas masquer une donnée runtime/canonique
        //   corrompue comme si c'était un simple manque de support moteur ;
        // - les `bridgeLimit=invalid_*` et assimilés restent donc des hard
        //   failures explicites, même si un autre move du combattant serait
        //   par ailleurs exécutable.
        if (!rejectedMove.isFilterableDuringSeedAssembly) {
          rethrow;
        }

        rejectedMoves.add(rejectedMove);
      }
    }

    if (moves.isNotEmpty) {
      return List<BattleMoveData>.unmodifiable(moves);
    }

    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" n’a aucun move bridgeable restant après filtrage.',
      debugDetails: 'combatant=$combatantLabel, '
          'candidateMoveIds=${_formatDebugList(candidateMoveIds)}, '
          'rejectedMoveIds=${_formatDebugList(rejectedMoves.map((move) => move.moveId).toList(growable: false))}, '
          'rejectedMoves=[${rejectedMoves.map((move) => move.toDebugDetails()).join('; ')}], '
          'filterResult=no_bridgeable_moves_remaining_after_filtering',
    );
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
    final out = <String>[];
    final seen = <String>{};
    for (final rawId in rawIds) {
      final normalizedId = rawId.trim();
      if (normalizedId.isEmpty || !seen.add(normalizedId)) {
        continue;
      }
      out.add(normalizedId);
    }
    return List<String>.unmodifiable(out);
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  BattleStatsSnapshot _calculateStatsSnapshot({
    required RuntimePokemonSpecies species,
    required int level,
    PokemonStatSpread ivs = const PokemonStatSpread(),
    PokemonStatSpread evs = const PokemonStatSpread(),
  }) {
    // BE2 résout ici les stats battle non-HP pour une raison simple :
    // - `map_runtime` possède encore la donnée projet (species, niveau, IV/EV) ;
    // - `map_battle` ne doit jamais relire le JSON projet brut ;
    // - le handoff battle doit donc déjà recevoir un snapshot typé, prêt à
    //   l'emploi, au lieu d'un bricolage `power + stages`.
    //
    // Politique volontairement bornée :
    // - joueur : on utilise les IV/EV réellement présents dans la sauvegarde ;
    // - sauvage / trainer : IV/EV par défaut à 0, déterministes, documentés ;
    // - nature neutre pour tout le monde dans BE2 ;
    // - `speed` est déjà transportée pour préparer la suite, sans être
    //   consommée pour l'ordre d'action dans ce lot.
    return BattleStatsSnapshot(
      attack: _calculateResolvedNonHpStat(
        baseStat: species.baseAttack,
        level: level,
        iv: ivs.attack,
        ev: evs.attack,
      ),
      defense: _calculateResolvedNonHpStat(
        baseStat: species.baseDefense,
        level: level,
        iv: ivs.defense,
        ev: evs.defense,
      ),
      specialAttack: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialAttack,
        level: level,
        iv: ivs.specialAttack,
        ev: evs.specialAttack,
      ),
      specialDefense: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialDefense,
        level: level,
        iv: ivs.specialDefense,
        ev: evs.specialDefense,
      ),
      speed: _calculateResolvedNonHpStat(
        baseStat: species.baseSpeed,
        level: level,
        iv: ivs.speed,
        ev: evs.speed,
      ),
    );
  }

  BattleTypingSnapshot _buildBattleTypingSnapshot(
    RuntimePokemonSpecies species,
  ) {
    // BE5 garde la frontière propre :
    // - le loader species lit et valide le typing projet ;
    // - le builder l'adapte vers le petit contrat battle ;
    // - `map_battle` reçoit ensuite une donnée déjà prête à consommer sans
    //   jamais relire le JSON projet brut.
    return BattleTypingSnapshot(
      primaryType: species.typing.first,
      secondaryType: species.typing.length > 1 ? species.typing[1] : null,
    );
  }

  int _calculateResolvedNonHpStat({
    required int baseStat,
    required int level,
    int iv = 0,
    int ev = 0,
  }) {
    final safeBaseStat = _clampInt(baseStat, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(iv, min: 0, max: 31);
    final safeEv = _clampInt(ev, min: 0, max: 252);

    // Formule volontairement Pokémon-like, mais limitée et déterministe :
    // floor(((2 * base + iv + floor(ev / 4)) * level) / 100) + 5
    //
    // BE2 ne gère pas encore les natures. On garde donc ici un multiplicateur
    // neutre implicite de 1.0 au lieu d'introduire une mécanique partielle.
    final resolved =
        (((2 * safeBaseStat + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) + 5;
    return _clampInt(resolved, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  String _formatDebugList(List<String> values) {
    if (values.isEmpty) {
      return '[]';
    }
    return '[${values.join(', ')}]';
  }
}

/// Snapshot local d'un move candidat rejeté par le bridge runtime -> battle.
///
/// Ce type reste volontairement petit et local au builder :
/// - il évite d'ouvrir un nouveau contrat public juste pour un message
///   d'erreur de handoff ;
/// - il garde tout le contexte nécessaire pour expliquer pourquoi aucun move
///   bridgeable n'est finalement resté après filtrage ;
/// - il permet d'améliorer le message final sans élargir le bridge lui-même.
final class _RejectedBridgeMove {
  const _RejectedBridgeMove({
    required this.moveId,
    required this.moveName,
    required this.engineSupportLevel,
    required this.unsupportedReasons,
    this.bridgeLimit,
  });

  factory _RejectedBridgeMove.fromBridgeRejection({
    required PokemonMove move,
    required String? debugDetails,
  }) {
    return _RejectedBridgeMove(
      moveId: move.id,
      moveName: move.name,
      engineSupportLevel: move.engineSupportLevel.name,
      unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
      bridgeLimit: _extractBridgeLimit(debugDetails),
    );
  }

  final String moveId;
  final String moveName;
  final String engineSupportLevel;
  final List<String> unsupportedReasons;
  final String? bridgeLimit;

  bool get isFilterableDuringSeedAssembly {
    final limit = bridgeLimit;
    if (limit == null) {
      return false;
    }
    if (limit.startsWith('invalid_')) {
      return false;
    }
    if (limit == 'empty_modify_stats_not_supported') {
      return false;
    }
    return true;
  }

  String toDebugDetails() {
    final reasons = unsupportedReasons.isEmpty
        ? '[]'
        : '[${unsupportedReasons.join(', ')}]';
    final limit = bridgeLimit == null ? '' : ', bridgeLimit=$bridgeLimit';
    return 'moveId=$moveId, '
        'moveName=$moveName, '
        'engineSupportLevel=$engineSupportLevel, '
        'unsupportedReasons=$reasons$limit';
  }

  static String? _extractBridgeLimit(String? debugDetails) {
    if (debugDetails == null || debugDetails.trim().isEmpty) {
      return null;
    }
    final match =
        RegExp(r'bridgeLimit=([^,]+)$').firstMatch(debugDetails.trim());
    return match?.group(1);
  }
}

/// Seed runtime intermédiaire d'un combattant avant projection finale vers
/// `BattleCombatantData`.
///
/// On garde ce type séparé du mapper pour documenter explicitement la frontière
/// M7 :
/// - le builder assemble un seed runtime battle-ready ;
/// - le mapper assemble ensuite le `BattleSetup` global.
class RuntimeBattleCombatantSeed {
  const RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    required this.typing,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData({
    int lineupIndex = 0,
  }) {
    // BE10 garde la frontière propre :
    // - le seed builder ne connaît toujours pas la vraie party runtime ;
    // - mais le mapper peut maintenant lui demander de projeter ce seed vers
    //   un `BattleCombatantData` portant une identité de lineup stable ;
    // - cela évite de dupliquer à la main tout le DTO battle dans le mapper.
    return BattleCombatantData(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}
```

## `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_combatant_seed_builder.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// M6 poursuit cette extraction pour les espèces et learnsets :
/// - le mapper ne relit plus lui-même ces JSON projet ;
/// - il délègue à de petits loaders runtime spécialisés ;
/// - il reste centré sur la composition combat, pas sur la plomberie locale.
///
/// M7 poursuit dans la même direction :
/// - le mapper ne construit plus lui-même les seeds de combattants ;
/// - il délègue cette projection à un builder spécialisé ;
/// - il garde seulement l'orchestration de haut niveau, la politique de
///   capture et les sélections exactes qui appartiennent encore au runtime.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
    this.combatantSeedBuilder = const RuntimeBattleCombatantSeedBuilder(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimeBattleCombatantSeedBuilder combatantSeedBuilder;

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final playerSelection = selectPlayerBattleLineup(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final playerPokemon = gameState.party.members[playerSelection.activeIndex];

    final playerSeed = await combatantSeedBuilder.buildPlayerCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      playerPokemon: playerPokemon,
      combatantLabel: 'Le Pokémon actif du joueur',
    );
    final playerReserveSeeds = <RuntimeBattleCombatantSeed>[];
    for (final reserveIndex in playerSelection.reserveIndices) {
      final reservePokemon = gameState.party.members[reserveIndex];
      playerReserveSeeds.add(
        await combatantSeedBuilder.buildPlayerCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          playerPokemon: reservePokemon,
          // BE10 a ouvert de vraies réserves battle.
          // Si une réserve joueur ne peut pas être bridgeée honnêtement, le
          // handoff doit le dire explicitement au lieu de prétendre que
          // l'actif seul est en cause.
          combatantLabel:
              'Le Pokémon de réserve du joueur (${reservePokemon.speciesId})',
        ),
      );
    }

    final enemyLineup = await switch (request) {
      WildBattleStartRequest() => combatantSeedBuilder
          .buildWildCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            request: request,
          )
          .then(
            (seed) => _RuntimeBattleEnemyLineup(
              active: seed,
              reserve: const <RuntimeBattleCombatantSeed>[],
            ),
          ),
      TrainerBattleStartRequest() => () async {
          final trainer = _findTrainer(bundle.manifest, request.trainerId);
          if (trainer.team.isEmpty) {
            throw RuntimeBattleSetupException(
              'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
              debugDetails: 'trainerId=${trainer.id}',
            );
          }

          final activeSeed =
              await combatantSeedBuilder.buildTrainerCombatantSeed(
            projectRootDirectory: bundle.projectRootDirectory,
            pokemonConfig: bundle.manifest.pokemon,
            movesCatalog: movesCatalog,
            teamMember: trainer.team.first,
            trainerName: trainer.name,
          );
          final reserveSeeds = <RuntimeBattleCombatantSeed>[];
          for (final teamMember in trainer.team.skip(1)) {
            reserveSeeds.add(
              await combatantSeedBuilder.buildTrainerCombatantSeed(
                projectRootDirectory: bundle.projectRootDirectory,
                pokemonConfig: bundle.manifest.pokemon,
                movesCatalog: movesCatalog,
                teamMember: teamMember,
                trainerName: trainer.name,
              ),
            );
          }
          return _RuntimeBattleEnemyLineup(
            active: activeSeed,
            reserve:
                List<RuntimeBattleCombatantSeed>.unmodifiable(reserveSeeds),
          );
        }(),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(lineupIndex: 0),
      playerReservePokemon: List<BattleCombatantData>.unmodifiable(
        playerReserveSeeds.asMap().entries.map(
              (entry) => entry.value.toBattleCombatantData(
                lineupIndex: entry.key + 1,
              ),
            ),
      ),
      enemyPokemon: enemyLineup.active.toBattleCombatantData(lineupIndex: 0),
      enemyReservePokemon: List<BattleCombatantData>.unmodifiable(
        enemyLineup.reserve.asMap().entries.map(
              (entry) => entry.value.toBattleCombatantData(
                lineupIndex: entry.key + 1,
              ),
            ),
      ),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  /// Sélectionne la lineup battle minimale du joueur : actif + réserves.
  ///
  /// Politique BE10 volontairement bornée :
  /// - l'actif reste soit l'index explicitement demandé, soit le premier
  ///   membre jouable ;
  /// - la réserve ne contient que les autres membres encore vivants ;
  /// - les membres déjà K.O. restent dans la save runtime, mais ne sont pas
  ///   injectés dans la lineup battle puisqu'ils ne seraient jamais
  ///   switchables honnêtement ;
  /// - l'ordre de réserve suit l'ordre de party réel, de façon stable.
  RuntimePlayerBattleLineupSelection selectPlayerBattleLineup(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final activeIndex = playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (activeIndex < 0 || activeIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$activeIndex, partyLength=${party.members.length}',
      );
    }

    final activeMember = party.members[activeIndex];
    if (activeMember.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$activeIndex, speciesId=${activeMember.speciesId}',
      );
    }

    final reserveIndices = <int>[];
    for (var i = 0; i < party.members.length; i++) {
      if (i == activeIndex || party.members[i].isFainted) {
        continue;
      }
      reserveIndices.add(i);
    }

    return RuntimePlayerBattleLineupSelection(
      activeIndex: activeIndex,
      reserveIndices: List<int>.unmodifiable(reserveIndices),
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    // Cette sélection reste volontairement dans le mapper :
    // - `PlayableMapGame` l'utilise déjà pour mémoriser le slot à réécrire
    //   après le combat ;
    // - elle relève d'une décision d'orchestration runtime de haut niveau,
    //   pas d'un assemblage de seed de combattant ;
    // - l'extraire dans le builder brouillerait la frontière M7 pour peu de
    //   valeur réelle dans ce repo.
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
    );
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
    );
  }
}

/// Sélection runtime de lineup battle du joueur.
///
/// Ce petit type évite de faire circuler des tuples implicites :
/// - `activeIndex` identifie le slot réellement actif au handoff ;
/// - `reserveIndices` garde l'ordre stable des réserves injectées dans
///   `BattleSetup` ;
/// - le runtime peut ensuite réutiliser exactement cette projection pour le
///   write-back post-combat.
final class RuntimePlayerBattleLineupSelection {
  const RuntimePlayerBattleLineupSelection({
    required this.activeIndex,
    required this.reserveIndices,
  });

  final int activeIndex;
  final List<int> reserveIndices;

  List<int> get lineupPartyIndices => <int>[activeIndex, ...reserveIndices];
}

final class _RuntimeBattleEnemyLineup {
  const _RuntimeBattleEnemyLineup({
    required this.active,
    required this.reserve,
  });

  final RuntimeBattleCombatantSeed active;
  final List<RuntimeBattleCombatantSeed> reserve;
}

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}
```

## `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleCombatantSeedBuilder', () {
    late Directory tempProjectRoot;
    const builder = RuntimeBattleCombatantSeedBuilder();
    const moveCatalogLoader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_combatant_seed_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('builds a player combatant seed from explicit knownMoveIds', () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(
            hp: 31,
            attack: 31,
            specialAttack: 15,
            speed: 7,
          ),
          evs: PokemonStatSpread(
            hp: 8,
            attack: 12,
            specialAttack: 20,
            speed: 16,
          ),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(seed.speciesId, equals('sproutle'));
      expect(seed.level, equals(12));
      expect(seed.maxHp, equals(36));
      expect(seed.currentHp, equals(23));
      expect(seed.abilityId, equals('overgrow'));
      expect(seed.typing.primaryType, equals('grass'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.stats.attack, equals(20));
      expect(seed.stats.defense, equals(16));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(20));
      expect(seed.stats.speed, equals(17));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stages,
        equals(-1),
      );
      expect(seed.moves[1].power, equals(45));
    });

    test(
        'toBattleCombatantData can stamp a stable lineupIndex for BE10 write-back',
        () {
      const seed = RuntimeBattleCombatantSeed(
        speciesId: 'sproutle',
        level: 12,
        maxHp: 36,
        stats: BattleStatsSnapshot(
          attack: 20,
          defense: 16,
          specialAttack: 23,
          specialDefense: 20,
          speed: 17,
        ),
        typing: BattleTypingSnapshot(primaryType: 'grass'),
        abilityId: 'overgrow',
        currentHp: 23,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'growl', name: 'Growl', power: 0),
        ],
      );

      final battleData = seed.toBattleCombatantData(lineupIndex: 2);

      expect(battleData.lineupIndex, equals(2));
      expect(battleData.speciesId, equals('sproutle'));
      expect(battleData.currentHp, equals(23));
    });

    test('preserves the BE8 move subset through the combatant seed contract',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>[
            'protect',
            'hyper_beam',
            'solar_beam',
            'feint',
          ],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['protect', 'hyper_beam', 'solar_beam', 'feint']),
      );
      expect(
        seed.moves[0].selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(seed.moves[1].requiresRecharge, isTrue);
      expect(
        seed.moves[2].chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(seed.moves[3].breaksProtect, isTrue);
    });

    test(
        'preserves the BE9 field move subset through the combatant seed contract',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['rain_dance', 'sandstorm', 'trick_room'],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['rain_dance', 'sandstorm', 'trick_room']),
      );
      expect(seed.moves[0].target, equals(BattleMoveTarget.field));
      expect(seed.moves[0].weatherEffect, equals(BattleWeatherId.rain));
      expect(seed.moves[1].target, equals(BattleMoveTarget.field));
      expect(seed.moves[1].weatherEffect, equals(BattleWeatherId.sandstorm));
      expect(seed.moves[2].target, equals(BattleMoveTarget.field));
      expect(
        seed.moves[2].pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(seed.moves[2].priority, equals(-7));
    });

    test(
        'derives player moves from the learnset, falls back to species id and keeps the last four unique moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'calm',
          abilityId: 'overgrow',
          level: 25,
          currentHp: 30,
        ),
      );

      // Le seam M7 doit conserver exactement la policy historique :
      // - concat starting/relearn/levelUp<=niveau ;
      // - unicité dans l'ordre d'apparition ;
      // - puis conservation des quatre derniers si la liste déborde.
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip', 'leer', 'razor_leaf']),
      );
    });

    test('builds a wild combatant seed from species and learnset data',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildWildCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(seed.speciesId, equals('sparkitten'));
      expect(seed.level, equals(10));
      expect(seed.currentHp, isNull);
      expect(seed.abilityId, equals('blaze'));
      expect(seed.typing.primaryType, equals('fire'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.maxHp, equals(27));
      expect(seed.stats.attack, equals(15));
      expect(seed.stats.defense, equals(13));
      expect(seed.stats.specialAttack, equals(17));
      expect(seed.stats.specialDefense, equals(15));
      expect(seed.stats.speed, equals(18));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
    });

    test('builds a trainer combatant seed from explicit trainer moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildTrainerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        teamMember: const ProjectTrainerPokemonEntry(
          speciesId: 'aquafi',
          level: 18,
          moves: <String>['water_gun', 'tail_whip'],
          heldItemId: 'mystic_water',
        ),
        trainerName: 'Ace Jules',
      );

      expect(seed.speciesId, equals('aquafi'));
      expect(seed.level, equals(18));
      expect(seed.abilityId, equals('torrent'));
      expect(seed.typing.primaryType, equals('water'));
      expect(seed.typing.secondaryType, equals('fairy'));
      expect(seed.stats.attack, equals(22));
      expect(seed.stats.defense, equals(28));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(28));
      expect(seed.stats.speed, equals(20));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test(
        'filters an explicit known move that is not bridgeable when another known move remains usable',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['teleport', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['vine_whip']),
      );
    });

    test(
        'fails explicitly when explicit known moves leave no bridgeable move after filtering',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['teleport'],
            currentHp: 23,
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
                  contains('engineSupportLevel=structuredPartial'),
                  allOf(
                    contains(
                      'unsupportedReasons=[unsupported_mechanic:zMove]',
                    ),
                    contains(
                      'filterResult=no_bridgeable_moves_remaining_after_filtering',
                    ),
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'does not silently filter malformed move data just because another move is bridgeable',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      const builderWithRejectingBridge = RuntimeBattleCombatantSeedBuilder(
        battleMoveBridge: _RejectingRuntimeBattleMoveBridge(
          rejectedMoveId: 'thunder_wave',
          rejection: RuntimeBattleSetupException(
            'Le combat ne peut pas démarrer car "Le Pokémon actif du joueur" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
            debugDetails:
                'combatant=Le Pokémon actif du joueur, moveId=thunder_wave, moveName=Thunder Wave, bridgeLimit=invalid_apply_status_scope:self',
          ),
        ),
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builderWithRejectingBridge.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['thunder_wave', 'vine_whip'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=invalid_apply_status_scope:self'),
          ),
        ),
      );
    });

    test('fails explicitly when a requested move is absent from the catalog',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['move_that_does_not_exist'],
            currentHp: 23,
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
        'fails explicitly when a learnset-derived move list has no bridgeable moves left after filtering',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
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
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            currentHp: 23,
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
                    'filterResult=no_bridgeable_moves_remaining_after_filtering',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'keeps a structured supported major status move once BE7 opens applyStatus honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['thunder_wave'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('thunder_wave'));
      expect(
        seed.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test(
        'keeps a non-zero priority move once battle order consumes it honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['quick_attack'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('quick_attack'));
      expect(seed.moves.single.priority, equals(1));
    });

    test('keeps a non-trivial accuracy move once battle owns the hit check',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['mud_slap'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('mud_slap'));
      expect(seed.moves.single.accuracy.kind,
          equals(BattleMoveAccuracyKind.percent));
      expect(seed.moves.single.accuracy.value, equals(85));
    });

    test(
        'keeps a non-neutral crit ratio once battle owns minimal critical hits',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['razor_leaf'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('razor_leaf'));
      expect(seed.moves.single.critRatio, equals(2));
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
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

## `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

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
