# Lot 2 — Contextual Backgrounds Report

## 1. Résumé exécutif honnête

Le lot 2 est **réussi**.

Le combat ne repose plus sur un seul fond statique : la scène runtime choisit désormais une famille de fond à partir du **contexte runtime réel**, sans toucher au battle-core, sans créer d’asset, et sans ouvrir la moindre logique IA.

Implémentation retenue :

- un seam runtime minimal `BattleBackgroundResolver`
- une spec minimale `BattleBackgroundSpec` pilotée par une seule clé `BattleBackgroundKey`
- une injection locale dans `PlayableMapGame` au moment où l’overlay s’ouvre
- un `BattleSceneBackdropComponent` qui consomme cette spec et peint plusieurs familles visuelles réellement distinctes

Décision nette :

- pas de modification de `BattleStartRequest`
- pas de modification de `runtime_battle_setup_mapper.dart`
- pas de modification de `map_battle`
- pas d’asset battle background réutilisable, parce qu’aucun asset pertinent n’existe réellement dans le repo
- pas de faux framework de theming

Variation réellement introduite :

- `fallbackField`
- `wildOutdoor`
- `trainerOutdoor`
- `indoor`

Le lot 1 n’a pas été re-détruit : la scène reste la même, seul le layer de fond devient piloté par une petite résolution de contexte côté runtime.

## 2. Pré-gates réellement exécutés + résultats

Commandes exécutées exactement au début du lot :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats réellement observés au début du lot :

- `git status --short --untracked-files=all`
  - aucune sortie
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - aucune sortie

Interprétation :

- le repo était propre au début du lot 2 ;
- le travail a bien été exécuté sur une baseline propre ;
- aucun reset ni discard n’a été tenté.

## 3. Méthode réellement suivie

Méthode suivie :

1. pré-gates read-only exacts
2. relecture des docs canoniques et des reports UI/IA déjà produits
3. audit ciblé du seam de scène lot 1, du point d’ouverture de l’overlay dans `PlayableMapGame`, et du contexte runtime réellement disponible (`BattleStartRequest`, `RuntimeMapBundle`, `MapMetadata`, `ProjectMapEntry`, `ProjectTrainerEntry`)
4. recherche repo sur d’éventuels assets battle backgrounds existants et audit des champs tentants mais peu fiables
5. classification explicite des sujets du lot 2
6. TDD ciblée : tests rouges sur le resolver, sur l’injection du fond dans l’overlay, et sur le golden slice wild/trainer
7. implémentation minimale strictement côté runtime
8. relance des validations demandées
9. tentative de review séparée finale
10. rédaction du report final complet

Skills/plugins réellement utilisés :

- `superpowers:brainstorming`
- `superpowers:test-driven-development`
- `superpowers:requesting-code-review`
- `game-studio:game-ui-frontend`

Adaptation explicite :

- `brainstorming` impose normalement une étape d’aller-retour design plus formelle ;
- ici j’ai resserré cette étape en design interne documenté, parce que ton prompt demandait d’exécuter sans pause de confort ;
- j’ai gardé l’esprit du skill : audit du contexte, choix d’un seul design, puis TDD avant implémentation.

## 4. Périmètre inclus / exclu

### Inclus

- runtime présentation sous `packages/map_runtime/lib/src/presentation/flame/`
- un seam minimal de résolution de fond battle
- la peinture du backdrop runtime
- le point d’injection local qui ouvre l’overlay battle
- des tests runtime ciblés sur la résolution et le golden slice

### Exclus

- tout `packages/map_battle/lib/src/**`
- toute logique IA, difficulté ou `BattleOpponentPolicy`
- tout asset nouveau
- tout resolver contextuel large de biome universel
- tout élargissement de `BattleStartRequest`
- toute modification des mappers runtime application battle
- tout changement du host source

## 5. Classification initiale des sujets du lot 2

- seam `BattleBackgroundResolver` ou équivalent : `required_now`
- `BattleBackgroundSpec` ou équivalent : `required_now`
- contexte map/metadata : `required_now`
- contexte wild/trainer : `required_now`
- fallback chain : `required_now`
- fond statique par défaut : `fix_now_small`
- nombre minimal de familles visuelles : `required_now`
- éventuel usage d’assets existants : `document_now_only`
- éventuelle modification de `BattleStartRequest` : `defer_not_lot2`
- éventuelle modification de `PlayableMapGame` : `fix_now_small`
- éventuelle modification de `battle_overlay_component.dart` : `fix_now_small`
- éventuelle modification du lot 1 backdrop component : `required_now`
- éventuelles modifications runtime application hors présentation : `defer_not_lot2`

## 6. Fichiers lus

Docs / reports :

- `/Users/karim/Project/pokemonProject/docs/combat/battle-canonical-state-v3.1.md`
- `/Users/karim/Project/pokemonProject/docs/combat/battle-roadmap-canonical-v3.1.md`
- `/Users/karim/Project/pokemonProject/reports/combat-ui-ai-audit-and-roadmap.md`
- `/Users/karim/Project/pokemonProject/reports/combat-ui-ai-implementation-roadmap.md`
- `/Users/karim/Project/pokemonProject/reports/lot-1-battle-scene-ui-pass-report.md`

Runtime / présentation :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_debug_panel_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_transition_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Runtime / application / contexte :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/encounter_to_battle_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`

Modèles / données :

- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_trainer.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_metadata.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`

Tests vérité produit :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/project_loader_page_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

Recherches repo ciblées :

- recherche d’assets battle backgrounds ou textures réutilisables
- recherche de `battleThemeId`, `portraitElementId`, `mapType`, `isIndoor`, `tags`, `trainerClass`
- recherche du point exact d’ouverture de `BattleOverlayComponent`

## 7. Validations réellement relancées

Commandes réellement relancées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/battle_scene_backdrop_component.dart \
  lib/src/presentation/flame/battle_transition_overlay_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

Commandes volontairement non relancées :

- `dart analyze` / `dart test` dans `packages/map_battle`

Justification :

- aucun fichier `map_battle` n’a été touché ;
- le lot 2 est resté strictement côté runtime.

## 8. Résultats réellement obtenus

Résultats observés :

- `flutter analyze --no-pub ...`
  - `No issues found!`
- `flutter test ...` dans `packages/map_runtime`
  - `All tests passed!`
- `flutter test ...` dans `examples/playable_runtime_host`
  - `All tests passed!`

Résultat TDD intermédiaire réellement observé :

- premier rouge : import du resolver introuvable, clé/spec inexistantes, injection overlay absente
- deuxième rouge : même absence côté golden slice smoke
- puis retour au vert complet après implémentation minimale

## 9. Décisions retenues / rejetées sujet par sujet

### 9.1 Seam de résolution

Décision retenue :

- créer `BattleBackgroundResolver` dans `map_runtime` présentation/runtime
- lui faire retourner une `BattleBackgroundSpec` minimale

Décision rejetée :

- pousser la logique dans `map_battle`
- créer un framework de theming générique
- élargir `BattleStartRequest`

### 9.2 Spec de fond

Décision retenue :

- une spec réduite à `BattleBackgroundKey`
- clés réellement utiles : `fallbackField`, `wildOutdoor`, `trainerOutdoor`, `indoor`

Décision rejetée :

- catalogue de 20 backgrounds
- objet de thème riche rempli de knobs “pour plus tard”

### 9.3 Contexte utilisé

Décision retenue :

- indoor explicite via `MapMetadata.isIndoor`
- indoor implicite via `MapMetadata.mapType`
- indoor implicite via `ProjectMapEntry.role`
- wild vs trainer via `BattleStartRequest`

Décision rejetée :

- `MapMetadata.tags`
- `ProjectTrainerEntry.trainerClass`
- `ProjectTrainerEntry.battleThemeId`
- `ProjectEncounterTable.tags`

Justification :

- ces champs sont tentants mais trop sémantiques, trop libres ou trop liés à un futur pipeline d’assets qui n’existe pas encore.

### 9.4 Point d’injection

Décision retenue :

- résoudre la spec dans `PlayableMapGame` juste avant la construction de l’overlay

Décision rejetée :

- modifier les mappers runtime battle
- faire résoudre le fond par le backdrop lui-même à partir de la session

Justification :

- `PlayableMapGame` est déjà le point où le runtime possède simultanément la requête de combat et la map active ;
- c’est le plus petit point d’injection repo-réel ;
- cela n’élargit aucun contrat battle.

### 9.5 Variation visuelle

Décision retenue :

- peindre quatre familles réellement distinctes en pur Flutter/Flame
- garder le layout lot 1 intact

Décision rejetée :

- simple recolorisation quasi invisible du fond lot 1
- refonte large des HUD/command panels pour “harmoniser” le décor

## 10. Justification des fichiers modifiés

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart`
  - nouveau seam minimal du lot 2
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart`
  - vrai rendu différencié des familles visuelles
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - consommation explicite d’une spec de fond et fallback stable de lot 1
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - unique point d’injection runtime où la requête et la map active coexistent déjà
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
  - verrouille la résolution de contexte et le plumbing overlay/backdrop
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
  - verrouille la vérité produit du golden slice wild vs trainer

## 11. Justification des fichiers volontairement non touchés

- `packages/map_battle/lib/src/**`
  - hors périmètre strict ; aucune nécessité battle-core n’a été trouvée
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
  - le mapper n’a pas à porter de logique de décor
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
  - sans rapport avec le fond
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
  - sans rapport avec le fond
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
  - sans rapport avec le fond
- `examples/playable_runtime_host/lib/**`
  - le host n’est pas le bon lieu pour résoudre le décor battle
- `battle_transition_overlay_component.dart`
  - la transition battle n’avait pas besoin de variation contextuelle pour ce lot

## 12. Description précise du seam de résolution retenu

Seam retenu :

- `BattleBackgroundResolver.resolve({required BattleStartRequest request, required RuntimeMapBundle bundle}) -> BattleBackgroundSpec`

Propriétés importantes :

- vit uniquement côté runtime
- consomme uniquement du contexte runtime déjà existant
- ne dépend pas du battle-core
- renvoie une spec minimale immédiatement consommable par le backdrop
- ne promet pas de système de theming plus vaste que ce lot

Spec retenue :

- `BattleBackgroundSpec`
- un seul champ structurant : `BattleBackgroundKey key`

Ce choix est volontaire :

- assez petit pour rester honnête
- assez riche pour produire une vraie variation visible
- pas assez large pour devenir un framework mort

## 13. Description précise du fallback chain retenu

Fallback chain réelle retenue :

1. `MapMetadata.isIndoor`
2. `MapMetadata.mapType` indoor-like (`building`, `interior`, `cave`, `facility`)
3. `ProjectMapEntry.role` indoor-like (`interior`, `basement`, `upper_floor`, `gate`, `room`, `connector`)
4. si la map n’est pas indoor-like :
   - `TrainerBattleStartRequest` -> `trainerOutdoor`
   - `WildBattleStartRequest` -> `wildOutdoor`
5. si l’overlay est construit sans contexte runtime injecté : `fallbackField`

Pourquoi cette chaîne est défendable :

- elle part d’abord du lieu réel ;
- elle n’utilise la nature du combat qu’après avoir déterminé si le lieu doit être indoor ;
- elle garde un fallback stable et lisible ;
- elle évite les champs sémantiques trop libres.

## 14. Nombre de familles visuelles réellement introduites

Nombre réellement introduit : **4**.

Familles :

- `fallbackField`
- `wildOutdoor`
- `trainerOutdoor`
- `indoor`

Différenciation réellement introduite :

- palettes différentes
- glow/horizon différents
- midground différent selon la famille
- composition différente pour `wildOutdoor`, `trainerOutdoor` et `indoor`

## 15. Ce qui reste volontairement pour le lot 3

Tout ce qui touche à l’IA reste hors lot :

- `BattleOpponentPolicy`
- difficulté
- choix ennemi
- profils `1..10`
- scripts trainer/boss

Ce qui reste aussi hors lot 2, même si ce n’est pas le lot 3 :

- un resolver contextuel plus riche basé sur tags sémantiques ou pipeline d’assets battle
- toute taxonomie plus fine type forêt/cité/plage/etc.
- toute personnalisation trainer basée sur `battleThemeId`

## 16. Incidents rencontrés

- les pré-gates Git ont donné un silence complet au début ; contrôle confirmé : repo propre
- exécution parallèle de deux commandes `flutter test` : lock de démarrage Flutter ; correction : retour à une exécution séquentielle pour les suites utiles
- les reviewers séparés sollicités n’ont pas répondu dans le délai imparti

## 17. Retour des sub-agents

### Sub-agent runtime/presentation

Retour utile :

- le bon seam reste un variant de backdrop piloté par l’overlay/runtime
- il faut éviter de toucher HUD, command panel et layout lot 1

### Sub-agent data/context resolution

Retour utile :

- aucun asset battle background pertinent n’existe dans le repo
- les champs fiables sont surtout `BattleStartRequest`, `MapMetadata`, `ProjectMapEntry.role`
- `trainerClass`, `battleThemeId`, `tags` sont tentants mais mauvais pour ce lot

### Sub-agent product/readability

Retour utile :

- il faut au moins quelques familles très contrastées
- simple changement de teinte = gain trop faible
- il faut éviter un faux framework de theming

## 18. Retour du reviewer séparé

Review séparée réellement tentée :

- `Huygens` sollicité comme reviewer principal
- `Carson` sollicité en secours

Retours réellement obtenus :

- `Huygens`
  - aucun finding prioritaire
  - confirme que le seam reste borné, que la dérive vers le lot 3 n’existe pas, et que `PlayableMapGame` est bien le point d’injection runtime le plus honnête pour ce lot
- `Carson`
  - remonte deux critiques
  - critique 1 : l’ambiguïté ancienne autour de `narrationPanelMounted` / `commandPanelMounted` dans `BattleOverlayComponent`
  - critique 2 : soupçon que le seam `BattleBackgroundResolver` pourrait être plus gros que sa valeur livrée

Disposition retenue :

- critique 1 : **retenue comme remarque de vérité locale, mais non traitée dans ce lot**
  - ce point préexiste au lot 2 ;
  - il vient surtout du fait que les tests montent l’overlay hors cycle Flame complet ;
  - corriger honnêtement ce point demanderait soit un ajustement du harness de test du lot 1, soit une refonte plus nette des surfaces de test de la command box ;
  - j’ai donc choisi de ne pas rouvrir un mini-chantier lot 1 déguisé dans ce lot 2
- critique 2 : **rejetée**
  - le seam reste petit ;
  - il ne transporte qu’une clé de fond ;
  - il répond directement à l’objectif visible du lot ;
  - il évite précisément la magie implicite dans `BattleSceneBackdropComponent` ou un widening de contrat runtime

Conclusion reviewer :

- aucune correction bloquante restante sur le périmètre lot 2 lui-même
- une réserve documentée persiste sur un getter de test lot 1, non aggravé par ce lot

## 19. Critique explicite du prompt lui-même

### Parties utiles

- frontière très claire runtime vs battle-core
- interdiction nette du lot 3
- exigence d’un fallback chain explicite
- exigence d’auditer d’abord les vrais champs de contexte disponibles
- exigence de variation visible et pas seulement symbolique

### Parties discutables

- l’exigence “fichiers à éviter sauf nécessité stricte” sur `PlayableMapGame` est un peu trop rigide : c’est précisément le point d’injection repo-réel le plus propre pour ce lot
- le libellé “`BattleBackgroundResolver` ou équivalent” est bon, mais le prompt aurait pu dire plus explicitement qu’un seam de présentation lisant du contexte runtime est encore conforme au périmètre

### Parties trop rigides

- exiger le contenu complet de tous les fichiers touchés, y compris un gros fichier comme `playable_map_game.dart`, améliore l’exhaustivité mais alourdit énormément le report
- la contrainte “1 à 4 nouveaux fichiers” est utile contre la dérive, mais un peu arbitraire ; ici elle n’a pas bloqué le bon design

### Parties que j’ai volontairement resserrées

- je n’ai pas exploité `trainerClass`, `battleThemeId` ou `tags` malgré leur disponibilité, parce que ce serait déjà sur-vendre le contexte
- j’ai limité la taxonomie à 4 familles, alors que le repo contient plus de signaux possibles (`mapType`, rôles, tags)

Pourquoi :

- le lot 2 doit rester petit, honnête et visible ;
- le bon risque à éviter ici est un resolver “magique” qui prétend connaître le monde mieux que le repo ne le permet réellement.

## 20. Autocritique finale

Points forts réels :

- le seam est petit et défendable ;
- la variation de fond est visible ;
- le lot 1 reste intact structurellement ;
- la vérité produit golden slice est verrouillée par test ;
- aucune dérive IA ou battle-core n’a été ouverte.

Limites réelles :

- `PlayableMapGame` a bien été touché, même si le blast radius reste petit ;
- la variation ne repose que sur des formes/gradients, pas sur de vrais assets battle ;
- la famille `indoor` est testée synthétiquement, pas encore sur un exemple indoor versionné du golden slice ;
- une ambiguïté de surface de test héritée du lot 1 reste en place sur les getters de montage du panneau bas ; elle n’est pas aggravée ici, mais elle ne doit pas être survendue comme une séparation plus riche qu’elle ne l’est réellement

## 21. État git final utile

Commandes réellement relancées en fin de lot :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats réellement observés en fin de lot :

### git status --short --untracked-files=all

```text
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart
?? packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart
?? reports/lot-2-contextual-backgrounds-report.md
```

### git diff --stat

```text
 .../flame/battle_overlay_component.dart            |  17 +-
 .../flame/battle_scene_backdrop_component.dart     | 293 +++++++++++++++++++--
 .../src/presentation/flame/playable_map_game.dart  |  14 +
 .../test/battle_overlay_component_test.dart        | 173 ++++++++++++
 .../phase_a_golden_battle_slice_smoke_test.dart    |  60 +++++
 5 files changed, 529 insertions(+), 28 deletions(-)
```

### git ls-files --others --exclude-standard

```text
packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart
reports/lot-2-contextual-backgrounds-report.md
```

## 22. Checklist finale

- [x] ai-je gardé le périmètre dans le lot 2 et pas au-delà ?
- [x] ai-je réellement introduit une variation de fond visible ?
- [x] ai-je gardé la responsabilité côté runtime ?
- [x] ai-je évité d’introduire le lot 3 ?
- [x] ai-je évité de toucher `map_battle` sans nécessité ?
- [x] ai-je choisi un fallback chain lisible et défendable ?
- [x] ai-je évité un faux framework de theming ?
- [x] ai-je relancé les validations utiles ?
- [x] ai-je utilisé des sub-agents ?
- [x] ai-je fait une review séparée ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés ?
- [x] ai-je évité toute écriture Git interdite ?

## 23. Décision finale nette

- lot 2 réussi : **oui**
- variation de fond réellement visible : **oui**
- préparation saine du lot 3 : **oui**, parce que le seam reste strictement décor/runtime et n’ouvre ni IA ni battle-core

## 24. Contenu complet des fichiers touchés

Ce report exclut volontairement sa propre recopie intégrale, pour éviter une récursion absurde.

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_background_resolver.dart

```dart
import 'package:map_core/map_core.dart';

import '../../application/battle_start_request.dart';
import '../../application/runtime_map_bundle.dart';

/// Clé minimale de fond de combat pour le lot 2.
///
/// Garde-fous de périmètre :
/// - on ne construit pas un système générique de theming ;
/// - on ne transporte que des familles visuelles immédiatement utiles ;
/// - on garde la vraie logique de peinture dans le backdrop runtime, pas dans
///   le battle-core ni dans un registre global de palettes.
enum BattleBackgroundKey {
  fallbackField,
  wildOutdoor,
  trainerOutdoor,
  indoor,
}

/// Spec minimale de fond de combat consommée par la scène runtime.
///
/// Le contrat reste volontairement petit :
/// - une seule clé résolue ;
/// - pas de taxonomie de biome large ;
/// - pas de dépendance à des assets non présents ;
/// - pas de promesse de personnalisation future plus large que ce lot.
final class BattleBackgroundSpec {
  const BattleBackgroundSpec({
    required this.key,
  });

  const BattleBackgroundSpec.fallbackField()
      : key = BattleBackgroundKey.fallbackField;

  final BattleBackgroundKey key;

  String get debugLabel => switch (key) {
        BattleBackgroundKey.fallbackField => 'fallback_field',
        BattleBackgroundKey.wildOutdoor => 'wild_outdoor',
        BattleBackgroundKey.trainerOutdoor => 'trainer_outdoor',
        BattleBackgroundKey.indoor => 'indoor',
      };
}

/// Résout le fond de combat à partir du contexte runtime déjà disponible.
///
/// Frontière volontairement stricte :
/// - ce seam vit dans `map_runtime` parce qu'il traduit un contexte overworld
///   vers une ambiance de scène ;
/// - il ne dépend pas du moteur battle ;
/// - il ne modifie aucun contrat battle-core ;
/// - il n'essaie pas de devenir un moteur universel de biome ou de thème.
///
/// Chaîne de résolution retenue pour le lot 2 :
/// 1. vérité indoor explicite de la map actuelle ;
/// 2. type indoor-like de la map actuelle ;
/// 3. rôle indoor-like dans le manifeste projet ;
/// 4. nature trainer vs wild de la requête ;
/// 5. fallback stable côté overlay si aucun contexte n'est injecté.
///
/// Champs volontairement NON utilisés maintenant :
/// - `MapMetadata.tags` : trop libres, pas assez canoniques pour un lot borné ;
/// - `ProjectTrainerEntry.trainerClass` : utile produit plus tard, mais trop
///   instable pour piloter honnêtement le décor maintenant ;
/// - `ProjectTrainerEntry.battleThemeId` : tentant, mais ce repo n'a pas
///   encore de pipeline d'assets battle dédiée à respecter ici ;
/// - `ProjectEncounterTable.tags` : décrivent les rencontres, pas forcément la
///   scène de combat.
final class BattleBackgroundResolver {
  const BattleBackgroundResolver();

  BattleBackgroundSpec resolve({
    required BattleStartRequest request,
    required RuntimeMapBundle bundle,
  }) {
    if (_isIndoorMap(bundle)) {
      return const BattleBackgroundSpec(
        key: BattleBackgroundKey.indoor,
      );
    }

    return switch (request) {
      TrainerBattleStartRequest() => const BattleBackgroundSpec(
          key: BattleBackgroundKey.trainerOutdoor,
        ),
      WildBattleStartRequest() => const BattleBackgroundSpec(
          key: BattleBackgroundKey.wildOutdoor,
        ),
    };
  }

  bool _isIndoorMap(RuntimeMapBundle bundle) {
    final metadata = bundle.map.mapMetadata;
    if (metadata.isIndoor) {
      return true;
    }
    if (_isIndoorMapType(metadata.mapType)) {
      return true;
    }

    final mapEntry = _findMapEntry(
      manifest: bundle.manifest,
      mapId: bundle.map.id,
    );
    if (mapEntry == null) {
      return false;
    }
    return _isIndoorMapRole(mapEntry.role);
  }

  ProjectMapEntry? _findMapEntry({
    required ProjectManifest manifest,
    required String mapId,
  }) {
    for (final entry in manifest.maps) {
      if (entry.id == mapId) {
        return entry;
      }
    }
    return null;
  }

  bool _isIndoorMapType(MapType mapType) {
    return switch (mapType) {
      MapType.building ||
      MapType.interior ||
      MapType.cave ||
      MapType.facility =>
        true,
      _ => false,
    };
  }

  bool _isIndoorMapRole(MapRole role) {
    return switch (role) {
      MapRole.interior ||
      MapRole.basement ||
      MapRole.upper_floor ||
      MapRole.gate ||
      MapRole.room ||
      MapRole.connector =>
        true,
      _ => false,
    };
  }
}

```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_scene_backdrop_component.dart

```dart
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'battle_background_resolver.dart';

/// Fond de scène par défaut pour le lot 1.
///
/// Garde-fous de périmètre :
/// - ce composant vit côté `map_runtime` parce qu'il ne transporte aucune
///   vérité métier battle ; il ne fait que peindre une ambiance de scène ;
/// - après le lot 2, il reste volontairement borné à la consommation d'une
///   petite spec déjà résolue ;
/// - il ne résout lui-même ni biome, ni map, ni trainer, ni encounter ;
/// - ce vrai seam de résolution appartient explicitement au runtime amont.
class BattleSceneBackdropComponent extends PositionComponent {
  BattleSceneBackdropComponent({
    required Vector2 size,
    BattleBackgroundSpec backgroundSpec =
        const BattleBackgroundSpec.fallbackField(),
  })  : _backgroundSpec = backgroundSpec,
        super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 0,
        );

  BattleBackgroundSpec _backgroundSpec;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => _backgroundSpec.key;

  /// Le backdrop reste un consommateur passif de spec.
  ///
  /// Pourquoi ce setter existe déjà :
  /// - il garde le composant localement testable ;
  /// - il laisse le lot 2 injecter une variation de contexte visible ;
  /// - il ne promet pas pour autant un système de theming plus large.
  void sync({
    required BattleBackgroundSpec backgroundSpec,
  }) {
    _backgroundSpec = backgroundSpec;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = Offset.zero & Size(size.x, size.y);
    final palette = _paletteFor(_backgroundSpec.key);

    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.y),
        palette.skyColors,
        const <double>[0.0, 0.36, 0.72, 1.0],
      );
    canvas.drawRect(rect, skyPaint);

    final horizonGlowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * palette.glowCenterDx, size.y * palette.glowCenterDy),
        size.x * palette.glowRadiusScale,
        <Color>[
          palette.glowColor,
          palette.glowColor.withValues(alpha: 0.08),
          const Color(0x00000000),
        ],
        const <double>[0.0, 0.45, 1.0],
      );
    canvas.drawRect(rect, horizonGlowPaint);

    _renderMidground(canvas, palette);
    _renderFloor(canvas, palette);
    _renderForegroundAccent(canvas, palette);
  }

  void _renderMidground(Canvas canvas, _BattleBackdropPalette palette) {
    switch (_backgroundSpec.key) {
      case BattleBackgroundKey.fallbackField:
        _renderFallbackBands(canvas, palette);
      case BattleBackgroundKey.wildOutdoor:
        _renderWildHills(canvas, palette);
      case BattleBackgroundKey.trainerOutdoor:
        _renderTrainerBanners(canvas, palette);
      case BattleBackgroundKey.indoor:
        _renderIndoorPanels(canvas, palette);
    }
  }

  void _renderFallbackBands(Canvas canvas, _BattleBackdropPalette palette) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.08, size.y * 0.18, size.x * 0.62, 22),
        const Radius.circular(14),
      ),
      Paint()..color = palette.bandColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.28, size.x * 0.52, 18),
        const Radius.circular(12),
      ),
      Paint()..color = palette.softBandColor,
    );
  }

  void _renderWildHills(Canvas canvas, _BattleBackdropPalette palette) {
    final hillPaint = Paint()..color = palette.bandColor;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.22, size.y * 0.55),
        width: size.x * 0.48,
        height: size.y * 0.22,
      ),
      hillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.66, size.y * 0.5),
        width: size.x * 0.66,
        height: size.y * 0.28,
      ),
      Paint()..color = palette.softBandColor,
    );
  }

  void _renderTrainerBanners(Canvas canvas, _BattleBackdropPalette palette) {
    final leftPath = Path()
      ..moveTo(0, size.y * 0.16)
      ..lineTo(size.x * 0.2, size.y * 0.12)
      ..lineTo(size.x * 0.34, size.y * 0.46)
      ..lineTo(0, size.y * 0.42)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = palette.bandColor);

    final rightPath = Path()
      ..moveTo(size.x, size.y * 0.12)
      ..lineTo(size.x * 0.78, size.y * 0.08)
      ..lineTo(size.x * 0.6, size.y * 0.42)
      ..lineTo(size.x, size.y * 0.38)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = palette.softBandColor);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x * 0.28, size.y * 0.22, size.x * 0.44, 14),
        const Radius.circular(10),
      ),
      Paint()..color = palette.ribbonColor,
    );
  }

  void _renderIndoorPanels(Canvas canvas, _BattleBackdropPalette palette) {
    final wallRect = Rect.fromLTWH(
        size.x * 0.08, size.y * 0.14, size.x * 0.84, size.y * 0.34);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wallRect, const Radius.circular(26)),
      Paint()..color = palette.bandColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        wallRect.deflate(12),
        const Radius.circular(18),
      ),
      Paint()..color = palette.softBandColor,
    );

    final spotlightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.x * 0.5, size.y * 0.62),
        size.x * 0.24,
        <Color>[
          palette.ribbonColor,
          palette.ribbonColor.withValues(alpha: 0.0),
        ],
      );
    canvas.drawRect(Offset.zero & Size(size.x, size.y), spotlightPaint);
  }

  void _renderFloor(Canvas canvas, _BattleBackdropPalette palette) {
    final floorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, size.y * 0.58),
        Offset(0, size.y),
        palette.floorColors,
        const <double>[0.0, 0.34, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, size.y * 0.58, size.x, size.y * 0.42),
      floorPaint,
    );
  }

  void _renderForegroundAccent(Canvas canvas, _BattleBackdropPalette palette) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.24, size.y * 0.73),
        width: size.x * 0.24,
        height: size.y * 0.06,
      ),
      Paint()..color = palette.floorAccentColor,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.x * 0.74, size.y * 0.41),
        width: size.x * 0.18,
        height: size.y * 0.05,
      ),
      Paint()..color = palette.softBandColor.withValues(alpha: 0.45),
    );
  }

  _BattleBackdropPalette _paletteFor(BattleBackgroundKey key) {
    return switch (key) {
      BattleBackgroundKey.fallbackField => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF16243B),
            Color(0xFF263B5D),
            Color(0xFF4F7A79),
            Color(0xFF99A56E),
          ],
          floorColors: <Color>[
            Color(0x14000000),
            Color(0x4411161E),
            Color(0xCC0B0E14),
          ],
          glowColor: Color(0x55FFF7C8),
          bandColor: Color(0x12FFFFFF),
          softBandColor: Color(0x10FFFFFF),
          ribbonColor: Color(0x16FFFFFF),
          floorAccentColor: Color(0x24000000),
          glowCenterDx: 0.52,
          glowCenterDy: 0.42,
          glowRadiusScale: 0.42,
        ),
      BattleBackgroundKey.wildOutdoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF10304D),
            Color(0xFF215F6B),
            Color(0xFF5A9A6F),
            Color(0xFFB9C97A),
          ],
          floorColors: <Color>[
            Color(0x18050C08),
            Color(0x66151F12),
            Color(0xD012140F),
          ],
          glowColor: Color(0x6BFFF2B4),
          bandColor: Color(0x4C3E6F58),
          softBandColor: Color(0x384FA172),
          ribbonColor: Color(0x26E6FFD0),
          floorAccentColor: Color(0x38456A35),
          glowCenterDx: 0.44,
          glowCenterDy: 0.38,
          glowRadiusScale: 0.34,
        ),
      BattleBackgroundKey.trainerOutdoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF2A163C),
            Color(0xFF6D3151),
            Color(0xFFB75A45),
            Color(0xFFE0AE61),
          ],
          floorColors: <Color>[
            Color(0x180B0608),
            Color(0x6B2D1517),
            Color(0xD0140D12),
          ],
          glowColor: Color(0x75FFD4A4),
          bandColor: Color(0x523E1B43),
          softBandColor: Color(0x4FA33E57),
          ribbonColor: Color(0x40FFE2A0),
          floorAccentColor: Color(0x42321A25),
          glowCenterDx: 0.5,
          glowCenterDy: 0.32,
          glowRadiusScale: 0.3,
        ),
      BattleBackgroundKey.indoor => const _BattleBackdropPalette(
          skyColors: <Color>[
            Color(0xFF141729),
            Color(0xFF232742),
            Color(0xFF394063),
            Color(0xFF6B6A78),
          ],
          floorColors: <Color>[
            Color(0x1A020305),
            Color(0x8036374A),
            Color(0xD0111219),
          ],
          glowColor: Color(0x4CC9D9FF),
          bandColor: Color(0x5B252A3B),
          softBandColor: Color(0x643C435D),
          ribbonColor: Color(0x3838F0FF),
          floorAccentColor: Color(0x3B727A95),
          glowCenterDx: 0.5,
          glowCenterDy: 0.24,
          glowRadiusScale: 0.24,
        ),
    };
  }
}

final class _BattleBackdropPalette {
  const _BattleBackdropPalette({
    required this.skyColors,
    required this.floorColors,
    required this.glowColor,
    required this.bandColor,
    required this.softBandColor,
    required this.ribbonColor,
    required this.floorAccentColor,
    required this.glowCenterDx,
    required this.glowCenterDy,
    required this.glowRadiusScale,
  });

  final List<Color> skyColors;
  final List<Color> floorColors;
  final Color glowColor;
  final Color bandColor;
  final Color softBandColor;
  final Color ribbonColor;
  final Color floorAccentColor;
  final double glowCenterDx;
  final double glowCenterDy;
  final double glowRadiusScale;
}

```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart

```dart
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_command_panel_component.dart';
import 'battle_background_resolver.dart';
import 'battle_debug_panel_component.dart';
import 'battle_scene_backdrop_component.dart';
import 'battle_scene_combatant_component.dart';
import 'battle_scene_hud_component.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Ce helper reste volontairement pur parce que le lot 1 ne doit surtout pas
/// recréer une logique de commande parallèle dans la présentation :
/// - la vérité de ce qu'on attend du joueur reste `BattleDecisionRequest` ;
/// - l'UI ne fait que reformuler cette vérité de manière plus lisible.
String buildBattleDecisionPromptForOverlay(BattleDecisionRequest request) {
  return switch (request) {
    BattleTurnChoiceRequest() => 'Que doit faire le joueur ?',
    BattleForcedReplacementRequest() =>
      'Le joueur doit remplacer son Pokémon K.O.',
    BattleContinueRequest() => 'Le joueur doit continuer un tour forcé',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible',
      },
  };
}

/// Construit les lignes de restitution d'un tour pour l'overlay runtime.
///
/// La vraie source de vérité de narration reste `BattleTurnResult.timeline`.
/// Le lot 1 améliore uniquement la composition visuelle de cette narration.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.stealthRockEvents.isNotEmpty ||
          turnResult.spikesEvents.isNotEmpty ||
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnExecutionEvent(:final execution):
        final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
        lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts',
        );
      case BattleTurnStatusEvent(:final event):
        lines.add(_formatOverlayStatusEvent(event));
      case BattleTurnVolatileEvent(:final event):
        lines.add(_formatOverlayVolatileEvent(event));
      case BattleTurnFieldEvent(:final event):
        lines.add(_formatOverlayFieldEvent(event));
      case BattleTurnStealthRockEvent(:final event):
        lines.add(_formatOverlayStealthRockEvent(event));
      case BattleTurnSpikesEvent(:final event):
        lines.add(_formatOverlaySpikesEvent(event));
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
    }
  }

  return List<String>.unmodifiable(lines);
}

/// Construit les lignes de narration visibles dans la command box.
///
/// Invariant important du lot 1 :
/// - on reste adossé à la timeline observable du moteur ;
/// - quand aucun tour n'est disponible, on retombe sur la requête courante ;
/// - on n'invente pas de narration "UI-only".
List<String> buildBattleNarrationLinesForOverlay(BattleSession session) {
  final currentTurn = session.state.currentTurn;
  if (currentTurn != null) {
    final lines = buildBattleTurnLinesForOverlay(currentTurn);
    if (lines.isNotEmpty) {
      final startIndex = lines.length > 4 ? lines.length - 4 : 0;
      return List<String>.unmodifiable(lines.sublist(startIndex));
    }
  }

  if (session.state.isFinished && session.state.outcome != null) {
    return List<String>.unmodifiable(<String>[
      _buildOutcomeHeadline(session.state.outcome!),
    ]);
  }

  return List<String>.unmodifiable(<String>[
    buildBattleDecisionPromptForOverlay(session.decisionRequest),
  ]);
}

/// Construit les lignes du panneau debug optionnel.
///
/// Ce panneau ne sert qu'au diagnostic local. Il doit rester :
/// - explicitement dérivé de la vérité battle/runtime déjà existante ;
/// - explicitement séparé de l'UI de combat normale.
List<String> buildBattleDebugLinesForOverlay(
  BattleSession session, {
  required int selectedIndex,
}) {
  return List<String>.unmodifiable(<String>[
    'phase: ${session.state.phase.name}',
    'request: ${session.decisionRequest.runtimeType}',
    'choix: ${session.decisionRequest.allowedChoices.length}',
    'selection: $selectedIndex',
    'joueur: ${session.state.player.speciesId} ${session.state.player.currentHp}/${session.state.player.maxHp}',
    'ennemi: ${session.state.enemy.speciesId} ${session.state.enemy.currentHp}/${session.state.enemy.maxHp}',
  ]);
}

String _formatOverlaySwitchEvent(BattleSwitchEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleSwitchEventKind.switched => event.wasForced
        ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
        : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
    BattleSwitchEventKind.replacementRequired =>
      '$actor doit remplacer ${event.fromSpeciesId} K.O.',
  };
}

String _formatOverlayStatusEvent(BattleStatusEvent event) {
  final actor = _overlayCombatantLabelForSide(event.targetSide);
  final status = event.status.name.toUpperCase();
  return switch (event.kind) {
    BattleStatusEventKind.applied =>
      '$actor reçoit le statut $status (${event.sourceMoveId})',
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '$actor garde déjà ${event.existingStatus!.name.toUpperCase()} '
          'et ignore $status',
    BattleStatusEventKind.preventedAction =>
      '$actor ne peut pas agir à cause de $status',
    BattleStatusEventKind.residualDamage =>
      '$actor subit ${event.damage} dégâts résiduels ($status'
          '${event.toxicCounter == null ? '' : ', compteur ${event.toxicCounter}'}'
          ')',
  };
}

String _formatOverlayVolatileEvent(BattleVolatileEvent event) {
  final actor = _overlayCombatantLabelForSide(event.actorSide);
  final target = event.targetSide == null
      ? null
      : _overlayCombatantLabelForSide(event.targetSide!);

  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated => '$actor active Protect',
    BattleVolatileEventKind.protectBlocked =>
      '${target ?? 'La cible'} bloque l’attaque avec Protect',
    BattleVolatileEventKind.protectBroken =>
      '$actor perce Protect sur ${target ?? 'la cible'}',
    BattleVolatileEventKind.rechargeRequired =>
      '$actor doit recharger au tour suivant',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '$actor passe son tour pour recharger',
    BattleVolatileEventKind.chargeStarted =>
      '$actor commence à charger ${event.sourceMoveId ?? 'son attaque'}',
    BattleVolatileEventKind.chargeReleased =>
      '$actor libère ${event.sourceMoveId ?? 'son attaque chargée'}',
  };
}

String _formatOverlayFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet =>
      'Le champ passe à ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherResidualDamage =>
      '${_overlayCombatantLabelForSide(event.targetSide!)} subit ${event.damage} dégâts de ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherExpired =>
      '${_overlayWeatherLabel(event.weather!)} prend fin',
    BattleFieldEventKind.pseudoWeatherSet =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} devient actif',
    BattleFieldEventKind.pseudoWeatherCleared =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
    BattleFieldEventKind.pseudoWeatherExpired =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} prend fin',
  };
}

String _formatOverlayStealthRockEvent(BattleStealthRockEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleStealthRockEventKind.set => 'Stealth Rock est posé du côté $actor',
    BattleStealthRockEventKind.alreadyPresent =>
      'Stealth Rock est déjà posé du côté $actor',
    BattleStealthRockEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Stealth Rock à l’entrée',
  };
}

String _formatOverlaySpikesEvent(BattleSpikesEvent event) {
  final actor = event.targetSlot == null
      ? _overlayCombatantLabelForSide(event.side)
      : _overlayCombatantLabelForSide(event.targetSlot!.side);
  return switch (event.kind) {
    BattleSpikesEventKind.setLayer =>
      'Spikes monte à ${event.layers} couche(s) du côté $actor',
    BattleSpikesEventKind.alreadyAtMaxLayers =>
      'Spikes est déjà à ${event.layers} couche(s) du côté $actor',
    BattleSpikesEventKind.damagedOnEntry =>
      '$actor subit ${event.damage} dégâts de Spikes à l’entrée (${event.layers} couche(s))',
  };
}

String _overlayCombatantLabelForSide(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}

String _overlayWeatherLabel(BattleWeatherId weather) {
  return switch (weather) {
    BattleWeatherId.rain => 'la pluie',
    BattleWeatherId.sandstorm => 'la tempête de sable',
  };
}

String _overlayPseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
  return switch (pseudoWeather) {
    BattlePseudoWeatherId.trickRoom => 'Trick Room',
  };
}

String _buildOutcomeHeadline(BattleOutcome outcome) {
  return switch (outcome.type) {
    BattleOutcomeType.victory => 'Victoire !',
    BattleOutcomeType.defeat => 'Défaite...',
    BattleOutcomeType.runaway => 'Fuite réussie !',
    BattleOutcomeType.captured => 'Capture réussie !',
  };
}

/// Overlay de combat lot 1.
///
/// Responsabilité :
/// - garder le runtime battle branché sur les mêmes vérités métier ;
/// - composer une scène de combat lisible ;
/// - déléguer le rendu concret aux composants de présentation du runtime.
///
/// Garde-fous :
/// - aucune logique battle n'entre ici ;
/// - aucune logique parallèle aux requests ou à la timeline n'est créée ;
/// - aucun resolver de background contextuel n'est introduit ici ;
/// - aucun seam IA n'est introduit ici.
class BattleOverlayComponent extends PositionComponent {
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
    this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
    this.showDebugPanel = false,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  BattleSession _session;

  final void Function(PlayerBattleChoice choice) onPlayerChoice;
  final BattleBackgroundSpec backgroundSpec;

  /// Le debug reste volontairement opt-in.
  ///
  /// Le lot 1 doit sortir l'UI normale du mode "debug panel". On garde donc un
  /// interrupteur explicite au lieu de laisser le debug redéfinir l'apparence
  /// par défaut du combat.
  final bool showDebugPanel;

  BattleSceneBackdropComponent? _backdrop;
  BattleSceneCombatantComponent? _enemyCombatant;
  BattleSceneCombatantComponent? _playerCombatant;
  BattleSceneHudComponent? _enemyHud;
  BattleSceneHudComponent? _playerHud;
  BattleCommandPanelComponent? _commandPanel;
  BattleDebugPanelComponent? _debugPanel;
  TextComponent? _outcomeBanner;

  int _selectedIndex = 0;

  @visibleForTesting
  bool get commandPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get narrationPanelMounted => _commandPanel != null;

  @visibleForTesting
  bool get debugPanelMounted => _debugPanel != null;

  @visibleForTesting
  BattleBackgroundKey get currentBackgroundKey => backgroundSpec.key;

  @visibleForTesting
  String get currentPromptText =>
      buildBattleDecisionPromptForOverlay(_session.decisionRequest);

  @visibleForTesting
  String get currentNarrationText =>
      buildBattleNarrationLinesForOverlay(_session).join('\n');

  @override
  Future<void> onLoad() async {
    // Le layout du lot 1 reste volontairement local et concret :
    // - on assume une scène plein écran ;
    // - on place des zones stables joueur/ennemi ;
    // - on garde un seul panneau bas pour narration + commandes ;
    // - on évite volontairement un système de layout générique.
    const padding = 28.0;
    final commandPanelHeight = (size.y * 0.31).clamp(188.0, 232.0).toDouble();
    final commandPanelY = size.y - commandPanelHeight - padding;

    final enemyHudSize = Vector2(
      (size.x * 0.31).clamp(240.0, 320.0).toDouble(),
      98,
    );
    final playerHudSize = Vector2(
      (size.x * 0.34).clamp(250.0, 340.0).toDouble(),
      106,
    );

    final enemyCombatantSize = Vector2(
      (size.x * 0.27).clamp(220.0, 320.0).toDouble(),
      (size.y * 0.28).clamp(140.0, 190.0).toDouble(),
    );
    final playerCombatantSize = Vector2(
      (size.x * 0.31).clamp(250.0, 360.0).toDouble(),
      (size.y * 0.32).clamp(170.0, 230.0).toDouble(),
    );

    _backdrop = BattleSceneBackdropComponent(
      size: size.clone(),
      backgroundSpec: backgroundSpec,
    );
    await add(_backdrop!);

    _enemyCombatant = BattleSceneCombatantComponent(
      position: Vector2(size.x - enemyCombatantSize.x - 88, 82),
      size: enemyCombatantSize,
      isPlayerSide: false,
      speciesLabel: _session.state.enemy.speciesId,
    );
    await add(_enemyCombatant!);

    _playerCombatant = BattleSceneCombatantComponent(
      position: Vector2(72, commandPanelY - playerCombatantSize.y - 26),
      size: playerCombatantSize,
      isPlayerSide: true,
      speciesLabel: _session.state.player.speciesId,
    );
    await add(_playerCombatant!);

    _enemyHud = BattleSceneHudComponent(
      position: Vector2(padding, padding),
      size: enemyHudSize,
      ownerLabel: 'ENNEMI',
      combatant: _session.state.enemy,
      isPlayerSide: false,
    );
    await add(_enemyHud!);

    _playerHud = BattleSceneHudComponent(
      position: Vector2(
        size.x - playerHudSize.x - padding,
        commandPanelY - playerHudSize.y - 18,
      ),
      size: playerHudSize,
      ownerLabel: 'JOUEUR',
      combatant: _session.state.player,
      isPlayerSide: true,
    );
    await add(_playerHud!);

    _commandPanel = BattleCommandPanelComponent(
      position: Vector2(padding, commandPanelY),
      size: Vector2(size.x - (padding * 2), commandPanelHeight),
      onChoiceSelected: onPlayerChoice,
    );
    await add(_commandPanel!);

    if (showDebugPanel) {
      _debugPanel = BattleDebugPanelComponent(
        position: Vector2(size.x - 248, 32),
        size: Vector2(216, 148),
      );
      await add(_debugPanel!);
    }

    _syncVisualState();
  }

  /// Met à jour l'overlay avec une nouvelle session immutable.
  ///
  /// Invariants runtime préservés :
  /// - `BattleSession` reste la seule source de vérité d'état ;
  /// - `BattleDecisionRequest` reste la seule source de vérité des commandes ;
  /// - `BattleTurnResult.timeline` reste la seule source de vérité narrative.
  ///
  /// Le fond n'est volontairement pas recalculé ici :
  /// - le lot 2 le résout à l'ouverture du combat à partir du contexte runtime ;
  /// - l'évolution du tour ne doit pas recréer une logique parallèle de décor ;
  /// - un vrai resolver contextuel plus riche restera un sujet futur côté
  ///   runtime, pas un effet secondaire de `BattleSession`.
  void updateState(BattleSession newSession) {
    _session = newSession;
    _clampSelectionToCurrentChoices();
    _syncVisualState();
  }

  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      _syncPanelsOnly();
      return true;
    }
    return false;
  }

  bool moveSelectionDown() {
    final choices = _session.decisionRequest.allowedChoices;
    if (_selectedIndex < choices.length - 1) {
      _selectedIndex++;
      _syncPanelsOnly();
      return true;
    }
    return false;
  }

  PlayerBattleChoice? getSelectedChoice() {
    final choices = _session.decisionRequest.allowedChoices;
    if (choices.isEmpty) {
      return null;
    }
    if (_selectedIndex < 0 || _selectedIndex >= choices.length) {
      return null;
    }
    return choices[_selectedIndex];
  }

  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice == null) {
      return false;
    }
    onPlayerChoice(selectedChoice);
    return true;
  }

  void _syncVisualState() {
    _enemyCombatant?.sync(speciesLabel: _session.state.enemy.speciesId);
    _playerCombatant?.sync(speciesLabel: _session.state.player.speciesId);
    _enemyHud?.sync(combatant: _session.state.enemy);
    _playerHud?.sync(combatant: _session.state.player);
    _syncPanelsOnly();
    _syncOutcomeBanner();
  }

  void _syncPanelsOnly() {
    _clampSelectionToCurrentChoices();

    _commandPanel?.sync(
      battleLabel: _titleForSession(),
      prompt: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      narrationLines: buildBattleNarrationLinesForOverlay(_session),
      choices: _buildChoiceEntries(_session.decisionRequest),
      selectedIndex: _selectedIndex,
    );

    _debugPanel?.sync(
      lines: buildBattleDebugLinesForOverlay(
        _session,
        selectedIndex: _selectedIndex,
      ),
    );
  }

  void _syncOutcomeBanner() {
    if (!_session.state.isFinished || _session.state.outcome == null) {
      _outcomeBanner?.removeFromParent();
      _outcomeBanner = null;
      return;
    }

    final outcome = _session.state.outcome!;
    final bannerText = _buildOutcomeHeadline(outcome);
    final bannerColor = outcome.isVictory || outcome.isCaptured
        ? const Color(0xFF8AE36A)
        : const Color(0xFFFF8E75);

    if (_outcomeBanner == null) {
      _outcomeBanner = TextComponent(
        text: bannerText,
        position: Vector2(size.x / 2, size.y * 0.17),
        anchor: Anchor.center,
        textRenderer: TextPaint(
          style: TextStyle(
            color: bannerColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
          ),
        ),
        priority: 45,
      );
      add(_outcomeBanner!);
      return;
    }

    _outcomeBanner!.text = bannerText;
    _outcomeBanner!.textRenderer = TextPaint(
      style: TextStyle(
        color: bannerColor,
        fontSize: 32,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  List<BattleCommandChoiceEntry> _buildChoiceEntries(
    BattleDecisionRequest request,
  ) {
    return List<BattleCommandChoiceEntry>.unmodifiable(
      request.allowedChoices.map(
        (choice) => BattleCommandChoiceEntry(
          choice: choice,
          label: _labelForChoice(request, choice),
        ),
      ),
    );
  }

  String _labelForChoice(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      final move = _session.state.player.moves[choice.moveIndex];
      final moveKind = switch (move.category) {
        BattleMoveCategory.physical => 'Physique',
        BattleMoveCategory.special => 'Speciale',
        BattleMoveCategory.status => 'Statut',
        null => 'Technique',
      };
      final powerLabel = move.power > 0 ? ' · Puissance ${move.power}' : '';
      return '${move.name} · $moveKind$powerLabel';
    }

    if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final verb = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '$verb ${reserve.speciesId} · ${reserve.currentHp}/${reserve.maxHp} PV';
    }

    if (choice is PlayerBattleChoiceContinue) {
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return 'Continuer · liberer la charge';
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return 'Continuer · tour de recharge';
        }
      }
      return 'Continuer';
    }

    if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    }

    if (choice is PlayerBattleChoiceRun) {
      return 'Fuir';
    }

    return 'Action inconnue';
  }

  void _clampSelectionToCurrentChoices() {
    final choices = _session.decisionRequest.allowedChoices;
    if (choices.isEmpty) {
      _selectedIndex = 0;
      return;
    }
    if (_selectedIndex >= choices.length) {
      _selectedIndex = choices.length - 1;
    }
    if (_selectedIndex < 0) {
      _selectedIndex = 0;
    }
  }

  String _titleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat dresseur';
    }
    return 'Combat sauvage';
  }
}

```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart

```dart
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../../domain/repositories/game_save_repository.dart';
import '../../../src/application/load_game_use_case.dart';
import '../../../src/application/save_game_use_case.dart';
import '../../../src/infrastructure/file_game_save_repository.dart';
import '../../application/battle_start_request.dart';
import '../../application/cutscene_runtime_models.dart';
import '../../application/cutscene_runtime_runner.dart';
import '../../application/dialogue_runtime_models.dart';
import '../../application/encounter_to_battle_request.dart';
import '../../application/field_move_dialogue.dart';
import '../../application/global_story_chapter_runtime.dart';
import '../../application/load_dialogue_content.dart';
import '../../application/load_runtime_map_bundle.dart';
import '../../application/map_entity_runtime_predicate_evaluator.dart';
import '../../application/movement_feedback.dart';
import '../../application/npc_overworld_movement_defaults.dart';
import '../../application/npc_runtime_presence.dart';
import '../../application/placed_behavior_runtime_cooldown.dart';
import '../../application/resolve_dialogue.dart';
import '../../application/runtime_battle_setup_mapper.dart';
import '../../application/runtime_battle_outcome_apply.dart';
import '../../application/runtime_character_refs.dart';
import '../../application/runtime_map_bundle.dart';
import '../../application/runtime_story_branching.dart';
import '../../application/scenario_runtime/scenario_runtime_executor.dart';
import '../../application/scenario_runtime/scenario_runtime_models.dart';
import '../../application/scenario_runtime_completion_gate.dart';
import '../../application/script_runtime_controller.dart';
import '../../application/script_runtime_state.dart';
import '../../application/scripted_entity_movement_controller.dart';
import '../../application/scripted_entity_movement_models.dart';
import '../../application/scripted_npc_anchor_passability.dart';
import '../../application/step_studio_completion_runtime.dart';
import '../../application/step_studio_world_presence_runtime.dart';
import '../../application/story_flags_manager.dart';
import '../../application/trainer_battle_request.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'battle_overlay_component.dart';
import 'battle_background_resolver.dart';
import 'battle_transition_overlay_component.dart';
import 'dialogue_overlay_component.dart';
import 'map_layers_component.dart';
import 'overworld_actor_component.dart';
import 'player_component.dart';
import 'warp_transition_overlay_component.dart';

const double _kViewportTilesX = 15.0;
const double _kViewportTilesY = 11.0;
const double _kWaterRequiresSurfMessageCooldownMs = 900;
const GameplayEncounterPolicy _kEncounterPolicy = GameplayEncounterPolicy(
  chancePerStep: 0.12,
);

enum _RuntimeFlowPhase {
  overworld,
  dialogue,
  mapTransition,
  battleTransition,
  battle,
}

class PlayableMapGame extends FlameGame with KeyboardEvents {
  PlayableMapGame({
    required RuntimeMapBundle bundle,
    required this.projectFilePath,
    SaveData? saveData,
    GameSaveRepository? saveRepository,
    this.bundleTransformer,
    this.runtimeCutscenes = const <RuntimeCutsceneAsset>[],
  })  : _bundle = bundle,
        _gameState = normalizeLoadedGameState(
          saveData == null
              ? const GameState(saveId: 'default')
              : gameStateFromSaveData(saveData),
        ),
        _saveRepo = saveRepository ?? FileGameSaveRepository() {
    if (bundleTransformer != null) {
      _bundle = bundleTransformer!(_bundle);
    }
    _saveGameUseCase = SaveGameUseCase(_saveRepo);
    _loadGameUseCase = LoadGameUseCase(_saveRepo);
  }

  final String projectFilePath;
  final RuntimeMapBundle Function(RuntimeMapBundle bundle)? bundleTransformer;
  final List<RuntimeCutsceneAsset> runtimeCutscenes;
  RuntimeMapBundle _bundle;
  GameState _gameState;
  late GameplayWorldState _world;
  late PlayerComponent _player;
  String _activeMapId = '';
  String? _previousMapId;
  _RuntimeFlowPhase _flowPhase = _RuntimeFlowPhase.overworld;
  final Set<LogicalKeyboardKey> _pressedKeys = <LogicalKeyboardKey>{};
  LogicalKeyboardKey? _lastMoveKey;
  TriggeredWarp? _pendingWarp;
  TriggeredConnection? _pendingConnection;
  BattleStartRequest? _pendingBattleRequest;
  PlacedElementInteracted? _pendingPlacedElementBehavior;
  DialogueOverlayComponent? _dialogueOverlay;
  BattleTransitionOverlayComponent? _battleTransitionOverlay;
  BattleOverlayComponent? _battleOverlay;
  WarpTransitionOverlayComponent? _warpTransitionOverlay;
  TextComponent? _notification;
  final List<OverworldActorComponent> _npcActors = [];
  final Map<String, _LoadedPlayableMap> _loadedMapsById = {};
  final Map<String, Future<_LoadedPlayableMap?>> _loadMapFutureById = {};
  final math.Random _encounterRandom = math.Random();
  final GridPathfinder _followPathfinder = const GridPathfinder();
  final RuntimeBattleSetupMapper _battleSetupMapper =
      const RuntimeBattleSetupMapper();
  final BattleBackgroundResolver _battleBackgroundResolver =
      const BattleBackgroundResolver();
  final PlacedBehaviorCooldownGate _placedBehaviorCooldownGate =
      PlacedBehaviorCooldownGate();
  final StoryFlagsManager _storyFlags = const StoryFlagsManager();
  final RuntimeStoryBranching _storyBranching = const RuntimeStoryBranching();
  final ScenarioRuntimeExecutor _scenarioRuntime =
      const ScenarioRuntimeExecutor();

  /// Cache de l’index Step Studio ↔ cutscenes locales (invalidé quand [_bundle] change).
  StepCompletionCutsceneIndex? _cachedStepCompletionIndex;
  RuntimeMapBundle? _cachedStepCompletionBundleForIndex;

  /// Cache des `worldChanges` parsés (une entrée par ligne JSON) pour le manifeste courant.
  List<StepStudioWorldPresenceRule> _cachedStepStudioWorldRules =
      const <StepStudioWorldPresenceRule>[];
  ProjectManifest? _cachedStepStudioWorldRulesManifest;

  void _ensureStepStudioWorldRulesForManifest(ProjectManifest manifest) {
    if (identical(_cachedStepStudioWorldRulesManifest, manifest)) {
      return;
    }
    _cachedStepStudioWorldRulesManifest = manifest;
    _cachedStepStudioWorldRules =
        buildStepStudioWorldPresenceRuleList(manifest.scenarios);
  }

  late final CutsceneRuntimeRunner _cutsceneRunner =
      _buildCutsceneRuntimeRunner();
  CutsceneChoiceRequest? _pendingCutsceneChoiceRequest;
  ScriptedEntityMovementController? _scriptedEntityMovementController;
  final Map<String, GridPos> _runtimeNpcPositions = <String, GridPos>{};
  // Réservations temporaires d'occupation pour PNJ scriptés en cours de pas.
  //
  // Frontière intentionnelle:
  // - `GameplayWorldState` reste la source canonique des positions *commitées*.
  // - pendant une interpolation visuelle d'un pas PNJ, on réserve aussi les
  //   cellules de destination pour éviter les traversées joueur<->PNJ / PNJ<->PNJ.
  final Map<String, Set<GridPos>> _scriptedNpcReservedOccupiedCellsByEntity =
      <String, Set<GridPos>>{};
  double _runtimeClockMs = 0;
  double _lastWaterRequiresSurfMessageAtMs = -1000000000;
  void Function()? _pendingPostDialogueAction;
  bool _awaitingSurfConfirmation = false;
  bool _showCollisionOverlay = false;
  bool _showNpcCollisionDebugOverlay = false;
  bool _showBehaviorDebugOverlay = false;
  bool _showFpsOverlay = false;
  TextComponent? _behaviorDebugOverlay;
  TextComponent? _fpsOverlay;
  double _fpsAccumulatorSeconds = 0.0;
  int _fpsFrameCount = 0;
  double _currentFps = 0.0;
  String _lastBehaviorDebugLine = 'Aucun behavior déclenché';
  GridPos? _debugTileMarkerPos;
  String? _debugTileMarkerLabel;
  RectangleComponent? _debugTileMarkerFill;
  RectangleComponent? _debugTileMarkerBorder;
  TextComponent? _debugTileMarkerText;
  final Map<String, _NpcCollisionDebugVisual> _npcCollisionDebugByEntityId =
      <String, _NpcCollisionDebugVisual>{};

  ScriptRuntimeController? _activeScriptController;
  bool _isAwaitingScriptResume = false;
  Set<String> _activeScenarioTriggerIds = <String>{};
  _PendingScenarioFollowRequest? _pendingScenarioFollowRequest;
  _PendingScenarioTransitionMapRequest? _pendingScenarioTransitionMapRequest;
  final Map<String, _PendingScenarioNpcWarpEntry>
      _pendingScenarioNpcWarpEntries = <String, _PendingScenarioNpcWarpEntry>{};
  final Map<String, _PendingScenarioMoveContinuation>
      _pendingScenarioMoveContinuationsByEntity =
      <String, _PendingScenarioMoveContinuation>{};
  // File d'attente des scénarios ayant atteint `end` mais dont la complétion
  // doit attendre la fin réelle des effets runtime visibles.
  final List<_PendingScenarioReachedEnd> _pendingScenarioReachedEndQueue =
      <_PendingScenarioReachedEnd>[];
  String? _lastScenarioCompletionBlockReason;

  // Save/Load system
  final GameSaveRepository _saveRepo;
  late SaveGameUseCase _saveGameUseCase;
  late LoadGameUseCase _loadGameUseCase;

  // Battle system (map_battle integration)
  BattleSession? _battleSession;
  RuntimeActiveBattleContext? _activeBattleContext;

  // Battle flow hardening
  bool _isBattleResolving =
      false; // Lock pour empêcher spam clavier pendant résolution

  // Line of Sight (LoS) trainer detection
  final Set<String> _triggeredTrainerBattles = {}; // Anti-retrigger lock

  bool get showCollisionOverlay => _showCollisionOverlay;

  void setCollisionOverlayVisible(bool visible) {
    _showCollisionOverlay = visible;
    for (final loaded in _loadedMapsById.values) {
      loaded.backgroundLayers.showCollisionOverlay = visible;
    }
  }

  bool get showNpcCollisionDebugOverlay => _showNpcCollisionDebugOverlay;

  void setNpcCollisionDebugOverlayVisible(bool visible) {
    _showNpcCollisionDebugOverlay = visible;
    if (!isLoaded) {
      return;
    }
    _syncNpcCollisionDebugOverlay();
  }

  bool get showBehaviorDebugOverlay => _showBehaviorDebugOverlay;
  bool get showFpsOverlay => _showFpsOverlay;
  double get currentFps => _currentFps;

  /// Active/désactive l'affichage du compteur FPS dans le viewport runtime.
  ///
  /// Ce toggle est utilisé par l'example host pour un contrôle manuel.
  /// Le compteur est volontairement optionnel pour éviter toute pollution
  /// visuelle par défaut.
  void setFpsOverlayVisible(bool visible) {
    _showFpsOverlay = visible;
    if (!_showFpsOverlay) {
      _fpsOverlay?.removeFromParent();
      _fpsOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureFpsOverlay();
  }

  MovementMode get playerMovementMode {
    if (isLoaded) {
      return _world.player.movementMode;
    }
    return _gameState.playerMovementMode;
  }

  bool get isSurfing => playerMovementMode == MovementMode.surf;

  ({String mapId, int playerX, int playerY, String facing, String movementMode})
      get saveLoadInfo {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return (
      mapId: _gameState.currentMapId,
      playerX: _gameState.playerPosition.x,
      playerY: _gameState.playerPosition.y,
      facing: _gameState.playerFacing.name,
      movementMode: _gameState.playerMovementMode.name,
    );
  }

  GameState get gameStateSnapshot {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    return _gameState;
  }

  @visibleForTesting
  String get debugFlowPhaseName => _flowPhase.name;

  @visibleForTesting
  void debugApplyBattleOutcomeForTest({
    required RuntimeActiveBattleContext context,
    required BattleOutcome outcome,
  }) {
    // Seam de test volontairement fin :
    // - on ne contourne pas la logique réelle de fin de combat ;
    // - on évite en revanche de devoir piloter tout l'overlay Flame au clavier
    //   pour prouver les garanties lot 15 ;
    // - le runtime garde donc un point d'entrée stable pour tester le write-back
    //   + la reprise overworld sans créer d'API produit parallèle.
    _activeBattleContext = context;
    _flowPhase = _RuntimeFlowPhase.battle;
    _onBattleFinished(outcome);
  }

  @visibleForTesting
  void debugSetPlayerStateForTest({
    required GridPos position,
    required Direction facing,
    MovementMode movementMode = MovementMode.walk,
  }) {
    // Petit seam de test volontaire :
    // - il permet de placer le joueur sur une cellule précise avant un scénario
    //   de reprise runtime ;
    // - il évite d'écrire un test d'input Flame plus fragile que la logique que
    //   l'on cherche réellement à prouver ici ;
    // - il ne sert pas au produit, uniquement à valider la cohérence du lot 15.
    _world = _world.withPlayer(
      _world.player.copyWith(
        pos: position,
        facing: facing,
        movementMode: movementMode,
      ),
    );
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _syncCameraToPlayer();
  }

  void _syncGameStateFromWorld({String? mapIdOverride}) {
    final mapId = mapIdOverride ?? _activeMapId;
    _gameState = _gameState.copyWith(
      currentMapId: mapId,
      playerPosition: _world.player.pos,
      playerFacing: _world.player.facing.asFacing,
      playerMovementMode: _world.player.movementMode,
    );
  }

  /// Filtre spatial PNJ : d’abord [MapEntityNpcData.visibilityRule], puis
  /// les `worldChanges` Step Studio (même [mapId] / [entity.id] que l’authoring).
  ///
  /// Les règles Step Studio sont relues via [_ensureStepStudioWorldRulesForManifest]
  /// **à chaque évaluation** pour éviter une liste [worldRules] capturée une fois
  /// et obsolète si le cache manifeste est invalidé.
  NpcMapPresencePredicate _npcPresencePredicateFor(ProjectManifest manifest) {
    return (String mapId, MapEntity npcEntity) {
      _ensureStepStudioWorldRulesForManifest(manifest);
      return isNpcRuntimePresentOnMap(
        gameState: _gameState,
        manifest: manifest,
        stepStudioWorldRules: _cachedStepStudioWorldRules,
        mapId: mapId,
        entity: npcEntity,
      );
    };
  }

  /// Dialogue effectif : variantes ordonnées puis dialogue par défaut du PNJ.
  DialogueRef? _resolveNpcDialogueRef(MapEntity entity) {
    final npc = entity.npc;
    if (npc == null) {
      return null;
    }
    return MapEntityRuntimePredicateEvaluator(
      gameState: _gameState,
      chapterIndex:
          buildGlobalStoryChapterStepIndex(_bundle.manifest.scenarios),
    ).resolveNpcDialogue(npc);
  }

  void _refreshWorldNpcPresence() {
    if (!isLoaded) {
      return;
    }
    _world = _world.withNpcMapPresencePredicate(
      _npcPresencePredicateFor(_bundle.manifest),
    );
    // Retirer les acteurs Flame des PNJ désormais absents (évite toute dérive
    // visuelle / hit test si un composant repasse « visible » par défaut).
    _detachAbsentNpcActorsFromAllLoadedMaps();
    _syncNpcRenderVisibility();
    _syncNpcCollisionDebugOverlay();
    // Patrouilles / réservations / LoS trainer : mêmes règles que le gameplay
    // (un PNJ « absent » ne doit plus consommer ces systèmes parallèles).
    _stopGameplaySideEffectsForAbsentNpcs();
  }

  /// Retire les [OverworldActorComponent] pour tout PNJ avec personnage dont le
  /// prédicat de présence est faux (cartes chargées / voisines incluses).
  void _detachAbsentNpcActorsFromAllLoadedMaps() {
    for (final loaded in _loadedMapsById.values) {
      final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
      final mapId = loaded.bundle.map.id;
      final toRemove = <String>[];
      for (final entity in loaded.bundle.map.entities) {
        if (entity.kind != MapEntityKind.npc) {
          continue;
        }
        final charId = resolveNpcCharacterId(entity, loaded.bundle.manifest);
        if (charId == null || charId.isEmpty) {
          continue;
        }
        if (npcPred(mapId, entity)) {
          continue;
        }
        if (loaded.npcActorByEntityId.containsKey(entity.id)) {
          toRemove.add(entity.id);
        }
      }
      for (final rawId in toRemove) {
        final id = rawId.trim();
        if (id.isEmpty) {
          continue;
        }
        _scriptedEntityMovementController?.stopPatrol(id);
        _scriptedEntityMovementController?.untrackEntity(id);
        _scriptedNpcReservedOccupiedCellsByEntity.remove(id);
        _runtimeNpcPositions.remove(id);
        _triggeredTrainerBattles.remove(id);
        if (_pendingScenarioFollowRequest?.leaderEntityId == id) {
          _pendingScenarioFollowRequest = null;
        }
        _pendingScenarioNpcWarpEntries.remove(id);
        _pendingScenarioMoveContinuationsByEntity.remove(id);
        _purgeMountedNpcActorForEntity(entityId: id, loaded: loaded);
      }
    }
  }

  void _purgeMountedNpcActorForEntity({
    required String entityId,
    required _LoadedPlayableMap loaded,
  }) {
    final actor = loaded.npcActorByEntityId.remove(entityId);
    if (actor != null) {
      loaded.npcActors.remove(actor);
      _npcActors.remove(actor);
      actor.removeFromParent();
    }
    final visual = _npcCollisionDebugByEntityId.remove(entityId);
    visual?.spriteRect.removeFromParent();
    visual?.collisionRect.removeFromParent();
    visual?.anchorMarker.removeFromParent();
  }

  /// Arrête tout effet runtime **hors** [GameplayWorldState] qui pourrait encore
  /// cibler un PNJ filtré par [NpcMapPresencePredicate] (patrouille, réservation
  /// de cases, lock trainer).
  void _stopGameplaySideEffectsForAbsentNpcs() {
    final controller = _scriptedEntityMovementController;
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (pred(mapId, entity)) {
        continue;
      }
      controller?.stopPatrol(entity.id);
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entity.id);
      _runtimeNpcPositions.remove(entity.id);
      _triggeredTrainerBattles.remove(entity.id);
    }
    _applyNpcOverworldDefaultMovement();
  }

  void _syncNpcRenderVisibility() {
    for (final loaded in _loadedMapsById.values) {
      _applyNpcVisibilityToLoadedMap(loaded);
    }
  }

  void _applyNpcVisibilityToLoadedMap(_LoadedPlayableMap loaded) {
    final npcPred = _npcPresencePredicateFor(loaded.bundle.manifest);
    loaded.backgroundLayers.npcMapPresencePredicate = npcPred;
    loaded.foregroundLayers.npcMapPresencePredicate = npcPred;
    for (final entity in loaded.bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final present = npcPred(loaded.bundle.map.id, entity);
      // Trace "source de vérité -> rendu" :
      // on journalise la décision finale de présence pour chaque PNJ afin de
      // diagnostiquer rapidement un cas "la règle existe mais l'acteur reste visible".
      debugPrint(
        '[step_studio_trace] npc_presence_applied map=${loaded.bundle.map.id} entity=${entity.id} present=$present',
      );
      loaded.npcActorByEntityId[entity.id]?.setGameplayVisible(present);
    }
  }

  RuntimeMapBundle _resolveRuntimeBundle(RuntimeMapBundle bundle) {
    final transform = bundleTransformer;
    if (transform == null) {
      return bundle;
    }
    return transform(bundle);
  }

  void setPlayerMovementMode(MovementMode movementMode) {
    if (!isLoaded) {
      return;
    }
    if (_world.player.movementMode == movementMode) {
      return;
    }
    _world = _world.withPlayer(
      _world.player.copyWith(movementMode: movementMode),
    );
    _syncGameStateFromWorld();
    _player.syncState(_world.player);
  }

  void setSurfingEnabled(bool enabled) {
    setPlayerMovementMode(enabled ? MovementMode.surf : MovementMode.walk);
  }

  /// Lance un déplacement scripté ponctuel pour un PNJ.
  ///
  /// API runtime publique pensée pour une future orchestration cutscene:
  /// - start movement
  /// - poll status
  /// - wait until completed/failed
  ScriptedEntityMovementStatus startScriptedNpcMove({
    required String entityId,
    required GridPos destination,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        targetPos: destination,
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.moveEntityTo(
      entityId: entityId,
      destination: destination,
    );
  }

  /// Active une patrouille simple (waypoints) pour un PNJ.
  ScriptedEntityMovementStatus startScriptedNpcPatrol({
    required String entityId,
    required List<GridPos> waypoints,
    bool loop = true,
    int pauseDurationMs = 0,
    int stepDurationMs = 200,
  }) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.startPatrol(
      ScriptedEntityPatrolRoute(
        entityId: entityId,
        waypoints: waypoints,
        loop: loop,
        pauseDurationMs: pauseDurationMs,
        stepDurationMs: stepDurationMs,
      ),
    );
  }

  void stopScriptedNpcPatrol(String entityId) {
    _scriptedEntityMovementController?.stopPatrol(entityId);
  }

  ScriptedEntityMovementStatus scriptedNpcMovementStatus(String entityId) {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return ScriptedEntityMovementStatus(
        entityId: entityId,
        state: ScriptedEntityMovementState.failed,
        currentPos: const GridPos(x: 0, y: 0),
        failureReason: 'Scripted movement controller is not initialized.',
      );
    }
    return controller.statusOf(entityId);
  }

  /// true si une cutscene runtime est en cours d'exécution.
  bool get isCutsceneRunning => _cutsceneRunner.isRunning;

  /// Identifiant de la cutscene active, `null` si aucune.
  String? get activeCutsceneId => _cutsceneRunner.activeCutsceneId;

  /// Snapshot détaillé du runner cutscene.
  CutsceneRuntimeStatus get cutsceneStatus => _cutsceneRunner.status;

  /// Requête de choix en attente (si la cutscene attend une décision joueur).
  CutsceneChoiceRequest? get pendingCutsceneChoiceRequest =>
      _pendingCutsceneChoiceRequest;

  bool get hasPendingCutsceneChoice => _pendingCutsceneChoiceRequest != null;

  /// Dernier choix résolu pendant la cutscene active.
  CutsceneChoiceResult? get lastCutsceneChoiceResult =>
      _cutsceneRunner.lastChoiceResult;

  /// Démarre une cutscene fournie explicitement.
  ///
  /// Cette API est utile pour des déclenchements runtime directs (tests,
  /// scripts d'initialisation, futur bridge Step -> Cutscene).
  bool startCutscene(RuntimeCutsceneAsset cutscene) {
    if (!isLoaded) {
      return false;
    }
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  /// Démarre une cutscene depuis le registre runtime injecté au game host.
  ///
  /// Retourne `false` si l'ID est introuvable ou si une cutscene est déjà active.
  bool startCutsceneById(String cutsceneId) {
    if (!isLoaded) {
      return false;
    }
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final cutscene = _findRuntimeCutsceneById(normalized);
    if (cutscene == null) {
      return false;
    }
    _pendingCutsceneChoiceRequest = null;
    return _cutsceneRunner.start(cutscene);
  }

  bool resolvePendingCutsceneChoiceByIndex(int selectedIndex) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByIndex(selectedIndex);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  bool resolvePendingCutsceneChoiceByValue(String selectedValue) {
    final resolved = _cutsceneRunner.resolveActiveChoiceByValue(selectedValue);
    if (resolved) {
      _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    }
    return resolved;
  }

  void setBehaviorDebugOverlayVisible(bool visible) {
    _showBehaviorDebugOverlay = visible;
    if (!visible) {
      _behaviorDebugOverlay?.removeFromParent();
      _behaviorDebugOverlay = null;
      return;
    }
    if (!isLoaded) {
      return;
    }
    _ensureBehaviorDebugOverlay();
  }

  void setDebugTileMarker({
    required GridPos? position,
    String? label,
  }) {
    _debugTileMarkerPos = position;
    _debugTileMarkerLabel = label;
    if (!isLoaded) {
      return;
    }
    _applyDebugTileMarker();
  }

  @override
  Future<void> onLoad() async {
    try {
      _world = GameplayWorldState.fromMap(
        _bundle.map,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      debugPrint(
        '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } on GameplaySpawnResolutionException catch (e) {
      debugPrint(
          '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
      _world = GameplayWorldState.initial(
        map: _bundle.map,
        playerPos: const GridPos(x: 0, y: 0),
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
    }
    final images =
        await loadTilesetImagesById(_bundle.tilesetAbsolutePathsById);
    _activeMapId = _bundle.map.id;
    final rootMap = await _mountLoadedMap(
      bundle: _bundle,
      tileImagesById: images,
      originCellX: 0,
      originCellY: 0,
    );
    final playerChar = _resolvePlayerCharacter(_bundle);
    _player = PlayerComponent(
      bundle: _bundle,
      state: _world.player,
      characterEntry: playerChar,
      tileImages: images,
      mapOrigin: _originPixelsOf(rootMap),
    );
    await world.add(_player);
    _syncGameStateFromWorld();
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _ensureBehaviorDebugOverlay();
    _ensureFpsOverlay();
    _applyDebugTileMarker();
    _resetScriptedNpcMovementController();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
    );
    return super.onLoad();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;
    final key = event.logicalKey;

    // IMPORTANT: Handle battle phase FIRST before movement keys
    // Otherwise arrow keys will be captured by movement handler
    if (_flowPhase == _RuntimeFlowPhase.battle) {
      // Navigation dans les choix du combat
      // ↑/↓ pour naviguer, E/Space/Enter pour valider, Escape pour fuir
      final overlay = _battleOverlay;
      if (overlay != null) {
        // ↑ : sélection précédente (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowUp && event is KeyDownEvent) {
          final changed = overlay.moveSelectionUp();
          debugPrint('[battle] ArrowUp pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // ↓ : sélection suivante (KeyDownEvent ONLY, pas KeyRepeatEvent)
        if (key == LogicalKeyboardKey.arrowDown && event is KeyDownEvent) {
          final changed = overlay.moveSelectionDown();
          debugPrint('[battle] ArrowDown pressed, selection changed=$changed');
          return KeyEventResult.handled;
        }
        // E / Space / Enter : validation du choix sélectionné
        // CRITICAL: Only process KeyDownEvent, NOT KeyRepeatEvent!
        // KeyRepeatEvent is sent when key is held down, which causes multiple validations
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.enter)) {
          // CRITICAL: Re-check phase AFTER getting into this block
          // Because the phase might have changed during this same key event processing
          // (e.g., last attack of the battle finished it)
          if (_flowPhase != _RuntimeFlowPhase.battle) {
            debugPrint(
                '[battle] Validate key pressed but phase changed to $_flowPhase, IGNORING');
            return KeyEventResult.ignored;
          }
          // Also check if overlay is still valid (might have been removed)
          if (_battleOverlay == null) {
            debugPrint(
                '[battle] Validate key pressed but overlay is null, IGNORING');
            return KeyEventResult.ignored;
          }
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint(
              '[battle] Validate key pressed (E/Space/Enter), selectedChoice=$selectedChoice');
          final validated = overlay.validateSelectedChoice();
          debugPrint('[battle] validateSelectedChoice returned=$validated');
          return KeyEventResult.handled;
        }
        // Escape : tentative de fuite (seulement si l'action est disponible)
        if (event is KeyDownEvent && key == LogicalKeyboardKey.escape) {
          // Vérifier si l'action "Fuir" est disponible dans les choix
          final selectedChoice = overlay.getSelectedChoice();
          debugPrint('[battle] Escape pressed, selectedChoice=$selectedChoice');
          if (selectedChoice is PlayerBattleChoiceRun) {
            overlay.validateSelectedChoice();
            debugPrint('[battle] Escape validated (run selected)');
            return KeyEventResult.handled;
          }
          // Si "Fuir" n'est pas sélectionné, ne rien faire
          debugPrint('[battle] Escape ignored (run not selected)');
          return KeyEventResult.ignored;
        }
      } else {
        debugPrint('[battle] Keyboard event but overlay is null!');
      }
      return KeyEventResult.ignored;
    }

    // Pendant une cutscene active en overworld, on bloque les entrées joueur
    // directes (déplacement/interact) pour garder la scène déterministe.
    if (isCutsceneRunning && _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Déplacement scripté joueur (scénario / cutscene): pas d’entrées clavier.
    if (_suppressOverworldInputForScriptedPlayerMovement() &&
        _flowPhase == _RuntimeFlowPhase.overworld) {
      if (_isMovementKey(key)) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (event is KeyDownEvent &&
          (key == LogicalKeyboardKey.keyE ||
              key == LogicalKeyboardKey.space ||
              key == LogicalKeyboardKey.enter)) {
        return KeyEventResult.handled;
      }
    }

    // Handle movement keys (but NOT during battle)
    if (_isMovementKey(key)) {
      if (_flowPhase == _RuntimeFlowPhase.dialogue) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        if ((_dialogueOverlay?.isShowingChoices ?? false) && isDown) {
          if (key == LogicalKeyboardKey.arrowUp) {
            _moveChoiceCursor(-1);
          } else if (key == LogicalKeyboardKey.arrowDown) {
            _moveChoiceCursor(1);
          }
        }
        return KeyEventResult.handled;
      }
      if (_flowPhase != _RuntimeFlowPhase.overworld) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
        return KeyEventResult.handled;
      }
      if (isDown) {
        _pressedKeys.add(key);
        _lastMoveKey = key;
      } else if (isUp) {
        _pressedKeys.remove(key);
        if (_lastMoveKey == key) {
          _lastMoveKey = null;
        }
      }
      return KeyEventResult.handled;
    }

    if (_flowPhase == _RuntimeFlowPhase.mapTransition ||
        _flowPhase == _RuntimeFlowPhase.battleTransition) {
      return KeyEventResult.ignored;
    }
    if (!isDown) return KeyEventResult.ignored;

    if (_flowPhase == _RuntimeFlowPhase.dialogue) {
      final overlay = _dialogueOverlay!;
      if (overlay.isShowingChoices) {
        if (key == LogicalKeyboardKey.arrowUp) {
          _moveChoiceCursor(-1);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          _moveChoiceCursor(1);
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _confirmDialogueChoice();
          return KeyEventResult.handled;
        }
      } else {
        if (event is KeyDownEvent &&
            (key == LogicalKeyboardKey.keyE ||
                key == LogicalKeyboardKey.space)) {
          _advanceDialogue();
          return KeyEventResult.handled;
        }
      }
      return KeyEventResult.ignored;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.keyE || key == LogicalKeyboardKey.space)) {
      _handleInteract();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateFps(dt);
    _runtimeClockMs += dt * 1000;
    _placedBehaviorCooldownGate.prune(nowMs: _runtimeClockMs);
    _updateActorDepthOrdering();
    _syncCameraToPlayer();
    _syncNpcCollisionDebugOverlay();

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }

    final pendingWarp = _pendingWarp;
    if (pendingWarp != null && !_player.isStepping) {
      _pendingWarp = null;
      _handleWarp(pendingWarp);
      return;
    }

    final pendingConnection = _pendingConnection;
    if (pendingConnection != null && !_player.isStepping) {
      _pendingConnection = null;
      _handleConnection(pendingConnection);
      return;
    }

    final pendingBattleRequest = _pendingBattleRequest;
    if (pendingBattleRequest != null && !_player.isStepping) {
      _pendingBattleRequest = null;
      _startBattleHandoff(pendingBattleRequest);
      return;
    }

    final pendingPlacedElementBehavior = _pendingPlacedElementBehavior;
    if (pendingPlacedElementBehavior != null && !_player.isStepping) {
      _pendingPlacedElementBehavior = null;
      _executePlacedElementBehavior(
        element: pendingPlacedElementBehavior.element,
        behavior: pendingPlacedElementBehavior.behavior,
        trigger: pendingPlacedElementBehavior.trigger,
      );
      return;
    }

    // Tick du système de déplacement scripté PNJ.
    //
    // Ce tick reste dans le flux overworld pour ce MVP:
    // - pas d'exécution pendant dialogue/battle transition;
    // - base propre pour un futur "wait movement" en cutscene.
    _scriptedEntityMovementController?.update(dt);
    _processPendingScenarioNpcWarpEntries();
    _processPendingScenarioMoveContinuations();
    _processPendingScenarioFollowRequest();
    _processPendingScenarioTransitionMapRequest();
    _processPendingScenarioReachedEndCompletions();

    // Tick runner cutscene MVP (séquentiel).
    _cutsceneRunner.update(dt);
    _pendingCutsceneChoiceRequest = _cutsceneRunner.activeChoiceRequest;
    if (isCutsceneRunning) {
      // Tant que la cutscene n'est pas terminée, on ne laisse pas la boucle
      // input joueur déplacer le player.
      return;
    }

    _driveMovement();
  }

  void _updateActorDepthOrdering() {
    _player.priority = 1000 + _player.footPoint.y.round();
    for (final actor in _npcActors) {
      actor.priority = 1000 + actor.depthSortY.round();
    }
  }

  bool _isMovementKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyS ||
        key == LogicalKeyboardKey.keyD;
  }

  GameplayIntent? _intentFromPressedKeys() {
    Direction? dirFor(LogicalKeyboardKey key) {
      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        return Direction.north;
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        return Direction.south;
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        return Direction.west;
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        return Direction.east;
      }
      return null;
    }

    final preferred = _lastMoveKey;
    if (preferred != null && _pressedKeys.contains(preferred)) {
      final d = dirFor(preferred);
      if (d != null) {
        return MoveIntent(d);
      }
    }

    for (final key in _pressedKeys) {
      final d = dirFor(key);
      if (d != null) {
        return MoveIntent(d);
      }
    }
    return null;
  }

  void _driveMovement() {
    if (_suppressOverworldInputForScriptedPlayerMovement()) {
      _clearPressedMovementKeys();
      return;
    }
    if (_player.isStepping) {
      return;
    }

    final intent = _intentFromPressedKeys();
    if (intent == null) {
      _player.syncState(_world.player);
      return;
    }
    final attemptedDirection = intent is MoveIntent ? intent.direction : null;
    final attemptedX = attemptedDirection == null
        ? null
        : _world.player.pos.x + attemptedDirection.dx;
    final attemptedY = attemptedDirection == null
        ? null
        : _world.player.pos.y + attemptedDirection.dy;
    final attemptedOutOfBounds = attemptedX != null &&
        attemptedY != null &&
        (attemptedX < 0 ||
            attemptedY < 0 ||
            attemptedX >= _world.map.size.width ||
            attemptedY >= _world.map.size.height);

    // Collision runtime stricte contre les destinations PNJ réservées.
    //
    // Sans ce garde-fou, un joueur peut entrer dans la case cible d'un PNJ en
    // interpolation (avant commit canonique), créant un effet de traversée.
    if (attemptedDirection != null &&
        attemptedX != null &&
        attemptedY != null &&
        _isCellReservedByScriptedNpc(
          GridPos(x: attemptedX, y: attemptedY),
        )) {
      _world =
          _world.withPlayer(_world.player.copyWith(facing: attemptedDirection));
      _player.syncState(_world.player);
      return;
    }

    final previousPlayerPos = _world.player.pos;
    final result = stepGameplayWorld(_world, intent);
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);

    if (result is Blocked) {
      if (result.reason == GameplayMovementBlockReason.waterRequiresSurf) {
        _handleWaterBlocked();
      }
      if (attemptedOutOfBounds && attemptedDirection != null) {
        final direction = switch (attemptedDirection) {
          Direction.north => MapConnectionDirection.north,
          Direction.south => MapConnectionDirection.south,
          Direction.east => MapConnectionDirection.east,
          Direction.west => MapConnectionDirection.west,
        };
        debugPrint(
          '[connection] no connection for direction=${direction.name} map=${_bundle.map.id}',
        );
      }
      _player.syncState(_world.player);
      return;
    }

    if (result is Moved) {
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _checkStepEncounter();
      _checkTrainerLineOfSight(); // Check LoS only when player position changes
      _dispatchScenarioTriggerEnterFromMovement(
        previousPos: previousPlayerPos,
        currentPos: _world.player.pos,
      );
      return;
    }

    if (result is WarpTriggered) {
      if (result.warp.triggerMode == MapWarpTriggerMode.onEnter) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player, snapToGrid: true);
      }
      _pendingWarp = result.warp;
      debugPrint(
        '[warp] Triggered warp ${result.warp.warpId} mode=${result.warp.triggerMode.name} -> map=${result.warp.targetMapId} pos=(${result.warp.targetPos.x}, ${result.warp.targetPos.y})',
      );
      return;
    }

    if (result is ConnectionTriggered) {
      _player.syncState(_world.player);
      _pendingConnection = result.connection;
      debugPrint(
        '[connection] exit detected map=${_bundle.map.id} direction=${result.connection.direction.name} target=${result.connection.targetMapId} offset=${result.connection.offset} source=(${result.connection.sourcePos.x}, ${result.connection.sourcePos.y})',
      );
      return;
    }

    if (result is PlacedElementInteracted) {
      final isMovementTrigger =
          result.trigger == MapPlacedElementTriggerType.onEnter ||
              result.trigger == MapPlacedElementTriggerType.onExit ||
              result.trigger == MapPlacedElementTriggerType.onNear;
      if (isMovementTrigger) {
        _player.startStep(
          _world.player,
          durationSeconds: PlayerComponent.kDefaultStepSeconds,
        );
      } else {
        _player.syncState(_world.player);
      }
      _pendingPlacedElementBehavior = result;
      final behaviorId = result.behavior.id.trim().isEmpty
          ? 'legacy'
          : result.behavior.id.trim();
      debugPrint(
        '[placed_behavior] queued trigger=${result.trigger.name} scope=${result.behavior.triggerScope.name} instance=${result.element.id} behavior=$behaviorId effect=${result.behavior.effect.type.name}',
      );
      _updateBehaviorDebugLine(
        'Queued ${result.trigger.name}/${result.behavior.triggerScope.name} · ${result.behavior.effect.type.name} · ${result.element.id}#$behaviorId',
      );
      return;
    }
  }

  void _checkStepEncounter() {
    final encounterKind = _world.player.movementMode == MovementMode.surf
        ? EncounterKind.surf
        : EncounterKind.walk;
    final pos = _world.player.pos;
    debugPrint(
      '[encounter] checking at x=${pos.x} y=${pos.y} kind=${encounterKind.name}',
    );
    final check = checkEncounterAtPlayerPosition(
      world: _world,
      project: _bundle.manifest,
      encounterKind: encounterKind,
      random: _encounterRandom,
      policy: _kEncounterPolicy,
    );
    _logEncounterCheck(check);
    if (!check.triggered) {
      return;
    }
    final encounter = check.encounter;
    if (encounter == null) {
      return;
    }
    final request = buildBattleStartRequestFromEncounter(
      encounter: encounter,
      world: _world,
    );
    _pendingBattleRequest = request;
    debugPrint(
      '[battle] battle request created kind=${request.kind.name} source=${request.source.name} requestId=${request.requestId}',
    );
    debugPrint(
      '[battle] wild payload species=${encounter.speciesId} level=${encounter.level} map=${encounter.mapId} zone=${encounter.zoneId}',
    );
  }

  /// Détecte les entrées dans des triggers de map pour alimenter les sources
  /// scénario `sourceTriggerEnter`.
  ///
  /// Le calcul est local et déterministe:
  /// - on lit les triggers couvrant l'ancienne position,
  /// - on lit les triggers couvrant la nouvelle position,
  /// - on déclenche uniquement les IDs présents dans "nouvelle - ancienne".
  void _dispatchScenarioTriggerEnterFromMovement({
    required GridPos previousPos,
    required GridPos currentPos,
  }) {
    // On privilégie l'état mémorisé pour éviter de recalculer l'ancienne
    // couverture à chaque tick. Un fallback de sécurité reste possible.
    final previousIds = _activeScenarioTriggerIds.isEmpty
        ? _scenarioRuntime.triggerIdsAtPosition(
            map: _bundle.map,
            pos: previousPos,
          )
        : _activeScenarioTriggerIds;
    final currentIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: currentPos,
    );
    _activeScenarioTriggerIds = currentIds;
    final enteredIds =
        currentIds.difference(previousIds).toList(growable: false)..sort();
    for (final triggerId in enteredIds) {
      _dispatchScenarioRuntimeSource(
        ScenarioRuntimeSourceEvent.triggerEnter(
          mapId: _activeMapId,
          triggerId: triggerId,
        ),
      );
    }
  }

  /// Point d'entrée unique pour les déclenchements runtime du Scenario Graph.
  ///
  /// Cette méthode centralise:
  /// - le guard de phase (overworld/script actif),
  /// - l'appel à l'exécuteur scénario,
  /// - le branchement vers les effets runtime (dialogue/script/message),
  /// - la synchronisation de GameState lorsque le flow mutera des flags.
  ScenarioRuntimeExecutionResult _dispatchScenarioRuntimeSource(
    ScenarioRuntimeSourceEvent sourceEvent,
  ) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: flow is not in overworld phase.',
      );
    }
    final activeScript = _activeScriptController;
    if (activeScript != null && !activeScript.isTerminated) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'Ignored: a script is already running.',
      );
    }
    final scenarios = _bundle.manifest.scenarios;
    if (scenarios.isEmpty) {
      return const ScenarioRuntimeExecutionResult(
        status: ScenarioRuntimeExecutionStatus.noMatchingSource,
        effect: ScenarioRuntimeEffect.none(),
        message: 'No scenario available in current manifest.',
      );
    }

    final result = _scenarioRuntime.dispatch(
      scenarios: scenarios,
      sourceEvent: sourceEvent,
      context: _buildScenarioRuntimeExecutionContext(),
    );

    // Step Studio : on ne complète pas sur "flow reached end" uniquement.
    // La completion est validée quand les effets runtime visibles sont terminés.
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'dispatch:${sourceEvent.type.name}',
    );

    // On maintient une trace explicite en logs pour faciliter le debug.
    if (result.status == ScenarioRuntimeExecutionStatus.noMatchingSource) {
      return result;
    }
    debugPrint(
      '[scenario_runtime] source=${sourceEvent.type.name} map=${sourceEvent.mapId} trigger=${sourceEvent.triggerId ?? '-'} entity=${sourceEvent.entityId ?? '-'} status=${result.status.name} scenario=${result.scenarioId ?? '-'} sourceNode=${result.sourceNodeId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
    return result;
  }

  /// Contexte partagé dispatch / continuation : inclut le filtre Step Studio
  /// pour ne pas relancer une cutscene locale dont la step est déjà complétée.
  ScenarioRuntimeExecutionContext _buildScenarioRuntimeExecutionContext() {
    return ScenarioRuntimeExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      shouldSkipScenario: _shouldSkipLocalScenarioForCompletedStep,
      openDialogue: _openScenarioDialogueById,
      runScript: _runScenarioScriptById,
      showMessage: (message) => _showNotification(message),
      moveCharacter: ({
        required entityId,
        required targetKind,
        required targetId,
        required waitForCompletion,
        runtimeSourceId,
      }) {
        return _runScenarioMoveCharacter(
          entityId: entityId,
          targetKind: targetKind,
          targetId: targetId,
          waitForCompletion: waitForCompletion,
          runtimeSourceId: runtimeSourceId,
        );
      },
      followCharacter: ({
        required leaderEntityId,
      }) {
        return _runScenarioFollowCharacter(leaderEntityId: leaderEntityId);
      },
      faceCharacter: ({
        required entityId,
        required direction,
      }) {
        return _runScenarioFaceCharacter(
          entityId: entityId,
          direction: direction,
        );
      },
      transitionMap: ({
        required mapId,
        required warpId,
      }) {
        return _runScenarioTransitionMap(
          mapId: mapId,
          warpId: warpId,
        );
      },
    );
  }

  /// Index Step Studio mis en cache tant que le bundle courant est inchangé
  /// (évite de re-parser le JSON à chaque déclencheur).
  StepCompletionCutsceneIndex _stepCompletionIndexForCurrentBundle() {
    if (!identical(_cachedStepCompletionBundleForIndex, _bundle)) {
      _cachedStepCompletionBundleForIndex = _bundle;
      _cachedStepCompletionIndex =
          buildStepCompletionCutsceneIndex(_bundle.manifest.scenarios);
    }
    return _cachedStepCompletionIndex!;
  }

  /// Si la cutscene [scenarioId] est la condition de fin d’une step déjà
  /// enregistrée dans [PlayerProgression.completedStepIds], on ignore ce
  /// scénario pour permettre à un autre candidat de matcher (ou aucun).
  bool _shouldSkipLocalScenarioForCompletedStep(String scenarioId) {
    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId == null) {
      return false;
    }
    return _gameState.progression.completedStepIds.contains(stepId);
  }

  /// Capture un résultat scénario et décide si la completion doit être :
  /// - appliquée immédiatement;
  /// - ou différée jusqu'à la fin réelle des effets runtime visibles.
  void _handleScenarioRuntimeCompletionResult(
    ScenarioRuntimeExecutionResult result, {
    required String origin,
  }) {
    if (result.status != ScenarioRuntimeExecutionStatus.reachedEnd) {
      return;
    }
    final scenarioId = result.scenarioId?.trim();
    if (scenarioId == null || scenarioId.isEmpty) {
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason == null) {
      _applyScenarioReachedEndCompletion(
          scenarioId: scenarioId, origin: origin);
      return;
    }
    for (final pending in _pendingScenarioReachedEndQueue) {
      if (pending.scenarioId == scenarioId) {
        debugPrint(
          '[step_studio_trace] completion_deferred_duplicate scenario=$scenarioId origin=$origin reason="$blockingReason"',
        );
        return;
      }
    }
    _pendingScenarioReachedEndQueue.add(
      _PendingScenarioReachedEnd(
        scenarioId: scenarioId,
        origin: origin,
        queuedAtMs: _runtimeClockMs,
      ),
    );
    debugPrint(
      '[step_studio_trace] completion_deferred scenario=$scenarioId origin=$origin reason="$blockingReason"',
    );
  }

  /// Applique réellement la completion progression pour un scénario qui a
  /// atteint `end` ET dont la mise en scène runtime est terminée.
  void _applyScenarioReachedEndCompletion({
    required String scenarioId,
    required String origin,
  }) {
    var progression = _gameState.progression;
    var changed = false;

    final index = _stepCompletionIndexForCurrentBundle();
    final stepId = index.stepIdToCompleteWhenCutsceneEnds(scenarioId);
    if (stepId != null) {
      debugPrint(
        '[step_studio_trace] runtime_mark_step_completed_candidate scenario=$scenarioId step=$stepId before=${progression.completedStepIds}',
      );
      final nextSteps = appendCompletedStepIdIfAbsent(
        progression.completedStepIds,
        stepId,
      );
      if (!identical(nextSteps, progression.completedStepIds)) {
        progression = progression.copyWith(completedStepIds: nextSteps);
        changed = true;
        debugPrint(
          '[step_studio] step "$stepId" completed (cutscene "$scenarioId" reached end).',
        );
        debugPrint(
          '[step_studio_trace] runtime_completed_steps_updated scenario=$scenarioId step=$stepId after=${progression.completedStepIds}',
        );
      }
    }

    ScenarioAsset? scenarioAsset;
    for (final s in _bundle.manifest.scenarios) {
      if (s.id == scenarioId) {
        scenarioAsset = s;
        break;
      }
    }
    if (scenarioAsset != null &&
        scenarioAsset.scope == ScenarioScope.localEventFlow) {
      final nextCut = appendCompletedCutsceneIdIfAbsent(
        progression.completedCutsceneIds,
        scenarioId,
      );
      if (!identical(nextCut, progression.completedCutsceneIds)) {
        progression = progression.copyWith(completedCutsceneIds: nextCut);
        changed = true;
        debugPrint(
          '[runtime] local scenario "$scenarioId" marked completed (predicate cutsceneCompleted).',
        );
      }
    }

    if (changed) {
      _gameState = _gameState.copyWith(progression: progression);
      _refreshWorldNpcPresence();
    }
    debugPrint(
      '[step_studio_trace] completion_applied scenario=$scenarioId origin=$origin completedSteps=${_gameState.progression.completedStepIds} completedCutscenes=${_gameState.progression.completedCutsceneIds}',
    );
  }

  /// Retourne la raison bloquante empêchant de finaliser la cutscene.
  ///
  /// Tant qu'une raison existe, on ne matérialise pas les effects de progression
  /// (`completedStepIds`, `completedCutsceneIds`).
  String? _scenarioCompletionBlockingReason() {
    return scenarioRuntimeCompletionBlockingReason(
      isOverworldFlow: _flowPhase == _RuntimeFlowPhase.overworld,
      flowPhaseName: _flowPhase.name,
      isDialogueOpen: _dialogueOverlay != null,
      isCutsceneRunnerActive: isCutsceneRunning,
      hasPendingFollowCharacter: _pendingScenarioFollowRequest != null,
      hasPendingMoveContinuations:
          _pendingScenarioMoveContinuationsByEntity.isNotEmpty,
      hasPendingNpcWarpEntries: _pendingScenarioNpcWarpEntries.isNotEmpty,
      hasPendingTransitionMapRequest:
          _pendingScenarioTransitionMapRequest != null,
      hasPendingRuntimeWarp: _pendingWarp != null,
      hasPendingRuntimeConnection: _pendingConnection != null,
      isPlayerStepInProgress: _player.isStepping,
    );
  }

  /// Dès que les effets visibles sont terminés, on applique les complétions
  /// différées dans l'ordre d'arrivée.
  void _processPendingScenarioReachedEndCompletions() {
    if (_pendingScenarioReachedEndQueue.isEmpty) {
      _lastScenarioCompletionBlockReason = null;
      return;
    }
    final blockingReason = _scenarioCompletionBlockingReason();
    if (blockingReason != null) {
      if (_lastScenarioCompletionBlockReason != blockingReason) {
        debugPrint(
          '[step_studio_trace] completion_gate_blocked reason="$blockingReason" queue=${_pendingScenarioReachedEndQueue.length}',
        );
        _lastScenarioCompletionBlockReason = blockingReason;
      }
      return;
    }
    if (_lastScenarioCompletionBlockReason != null) {
      debugPrint(
        '[step_studio_trace] completion_gate_unblocked queue=${_pendingScenarioReachedEndQueue.length}',
      );
      _lastScenarioCompletionBlockReason = null;
    }
    final pendingItems =
        List<_PendingScenarioReachedEnd>.from(_pendingScenarioReachedEndQueue);
    _pendingScenarioReachedEndQueue.clear();
    for (final pending in pendingItems) {
      final waitMs = (_runtimeClockMs - pending.queuedAtMs).round();
      debugPrint(
        '[step_studio_trace] completion_deferred_flush scenario=${pending.scenarioId} waitedMs=$waitMs origin=${pending.origin}',
      );
      _applyScenarioReachedEndCompletion(
        scenarioId: pending.scenarioId,
        origin: 'deferred:${pending.origin}',
      );
    }
  }

  /// Ouvre un dialogue projet à partir d'un `dialogueId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _openScenarioDialogueById(
    String dialogueId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedDialogueId = dialogueId.trim();
    if (normalizedDialogueId.isEmpty) {
      return false;
    }
    final opened = _tryOpenDialogue(
      runtimeSourceId ?? 'scenario',
      DialogueRef(
        dialogueId: normalizedDialogueId,
        startNode: startNode,
      ),
      'Dialogue introuvable: $normalizedDialogueId',
    );
    if (opened && runtimeSourceId != null && runtimeSourceId.isNotEmpty) {
      _scheduleScenarioContinuationAfterDialogue(runtimeSourceId);
    }
    return opened;
  }

  void _scheduleScenarioContinuationAfterDialogue(String runtimeSourceId) {
    if (!runtimeSourceId.startsWith('scenario:')) {
      return;
    }
    final previous = _pendingPostDialogueAction;
    _pendingPostDialogueAction = () {
      previous?.call();
      _resumeScenarioAfterRuntimeSource(runtimeSourceId);
    };
  }

  void _resumeScenarioAfterRuntimeSource(String runtimeSourceId) {
    final parts = runtimeSourceId.split(':');
    if (parts.length != 4) {
      return;
    }
    final scenarioId = parts[1].trim();
    final sourceNodeId = parts[2].trim();
    final resumeAfterNodeId = parts[3].trim();
    if (scenarioId.isEmpty ||
        sourceNodeId.isEmpty ||
        resumeAfterNodeId.isEmpty) {
      return;
    }
    final result = _scenarioRuntime.dispatchContinuation(
      scenarios: _bundle.manifest.scenarios,
      scenarioId: scenarioId,
      sourceNodeId: sourceNodeId,
      resumeAfterNodeId: resumeAfterNodeId,
      context: _buildScenarioRuntimeExecutionContext(),
    );
    _handleScenarioRuntimeCompletionResult(
      result,
      origin: 'continuation:$runtimeSourceId',
    );
    debugPrint(
      '[scenario_runtime] continuation source=$runtimeSourceId status=${result.status.name} scenario=${result.scenarioId ?? '-'} stopNode=${result.stopNodeId ?? '-'} message=${result.message}',
    );
  }

  bool _runScenarioMoveCharacter({
    required String entityId,
    required String targetKind,
    required String targetId,
    required bool waitForCompletion,
    String? runtimeSourceId,
  }) {
    final trimmedEntity = entityId.trim();
    if (trimmedEntity == 'player') {
      _scriptedEntityMovementController?.syncTrackedEntityPosition(
        trimmedEntity,
        _world.player.pos,
      );
    }
    final destination = _resolveScenarioMoveTarget(
      targetKind: targetKind,
      targetId: targetId,
    );
    if (destination == null) {
      debugPrint(
        '[scenario_runtime] moveCharacter target unresolved kind=$targetKind targetId=$targetId',
      );
      return false;
    }
    var resolvedDestination = destination;
    var entityApproachCandidates = const <GridPos>[];
    if (targetKind == 'entity') {
      entityApproachCandidates = _resolveScenarioEntityApproachCandidates(
        moverEntityId: entityId,
        targetEntityId: targetId,
        primaryDestination: destination,
      );
      if (entityApproachCandidates.isEmpty) {
        debugPrint(
          '[scenario_runtime] moveCharacter entity target has no reachable adjacent cell entity=$entityId target=$targetId',
        );
        return false;
      }
      resolvedDestination = entityApproachCandidates.first;
    }
    var started = startScriptedNpcMove(
      entityId: entityId,
      destination: resolvedDestination,
    );
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        final fallbackCandidates = _resolveScenarioWarpApproachCandidates(
          entityId: entityId,
          warp: warp,
          primaryDestination: destination,
        );
        for (final candidate in fallbackCandidates) {
          final fallbackStarted = startScriptedNpcMove(
            entityId: entityId,
            destination: candidate,
          );
          if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
            resolvedDestination = candidate;
            started = fallbackStarted;
            debugPrint(
              '[scenario_runtime] moveCharacter warp fallback entity=$entityId warp=${warp.id} destination=(${candidate.x},${candidate.y})',
            );
            break;
          }
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed &&
        targetKind == 'entity') {
      final fallbackCandidates = entityApproachCandidates.isNotEmpty
          ? entityApproachCandidates.skip(1)
          : _resolveScenarioEntityApproachCandidates(
              moverEntityId: entityId,
              targetEntityId: targetId,
              primaryDestination: destination,
            );
      for (final candidate in fallbackCandidates) {
        final fallbackStarted = startScriptedNpcMove(
          entityId: entityId,
          destination: candidate,
        );
        if (fallbackStarted.state != ScriptedEntityMovementState.failed) {
          resolvedDestination = candidate;
          started = fallbackStarted;
          debugPrint(
            '[scenario_runtime] moveCharacter entity fallback entity=$entityId target=$targetId destination=(${candidate.x},${candidate.y})',
          );
          break;
        }
      }
    }
    if (started.state == ScriptedEntityMovementState.failed) {
      debugPrint(
        '[scenario_runtime] moveCharacter failed entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y})',
      );
      return false;
    }
    if (targetKind == 'warp') {
      final warp = _findMapWarpById(targetId);
      if (warp != null) {
        _pendingScenarioNpcWarpEntries[entityId] = _PendingScenarioNpcWarpEntry(
          entityId: entityId,
          warpId: warp.id,
          warpPos: warp.pos,
          approachPos: resolvedDestination,
        );
      }
    } else {
      _pendingScenarioNpcWarpEntries.remove(entityId);
    }
    if (waitForCompletion) {
      final runtimeSource = runtimeSourceId?.trim() ?? '';
      if (runtimeSource.startsWith('scenario:') && trimmedEntity.isNotEmpty) {
        _pendingScenarioMoveContinuationsByEntity[trimmedEntity] =
            _PendingScenarioMoveContinuation(
          entityId: trimmedEntity,
          runtimeSourceId: runtimeSource,
          targetKind: targetKind,
        );
      }
      debugPrint(
        '[scenario_runtime] moveCharacter started entity=$entityId destination=(${resolvedDestination.x},${resolvedDestination.y}) waitForCompletion=true',
      );
    } else {
      _pendingScenarioMoveContinuationsByEntity.remove(trimmedEntity);
    }
    return true;
  }

  bool _runScenarioTransitionMap({
    required String mapId,
    required String warpId,
  }) {
    final normalizedMapId = mapId.trim();
    final normalizedWarpId = warpId.trim();
    if (normalizedMapId.isEmpty || normalizedWarpId.isEmpty) {
      debugPrint(
        '[scenario_runtime] transitionMap invalid mapId="$mapId" warpId="$warpId"',
      );
      return false;
    }
    _pendingScenarioTransitionMapRequest = _PendingScenarioTransitionMapRequest(
      mapId: normalizedMapId,
      warpId: normalizedWarpId,
    );
    debugPrint(
      '[scenario_runtime] transitionMap scheduled map=$normalizedMapId warp=$normalizedWarpId',
    );
    return true;
  }

  void _processPendingScenarioTransitionMapRequest() {
    final pending = _pendingScenarioTransitionMapRequest;
    if (pending == null) {
      return;
    }

    // On attend la fin du suivi (followCharacter) pour ne pas couper la scène.
    if (_pendingScenarioFollowRequest != null) {
      return;
    }
    if (_player.isStepping) {
      return;
    }

    _pendingScenarioTransitionMapRequest = null;
    unawaited(_executeScenarioTransitionMapRequest(pending));
  }

  Future<void> _executeScenarioTransitionMapRequest(
    _PendingScenarioTransitionMapRequest request,
  ) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint(
        '[scenario_runtime] transitionMap ignored: flow=${_flowPhase.name}',
      );
      return;
    }
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: request.mapId,
      );
      final targetBundle = _resolveRuntimeBundle(loadedBundle);
      MapWarp? targetWarp;
      for (final candidate in targetBundle.map.warps) {
        if (candidate.id == request.warpId) {
          targetWarp = candidate;
          break;
        }
      }
      if (targetWarp == null) {
        debugPrint(
          '[scenario_runtime] transitionMap failed: warp "${request.warpId}" not found on map "${request.mapId}"',
        );
        _showNotification('Transition impossible (warp introuvable)');
        return;
      }

      final transition = TriggeredWarp(
        warpId: 'scenario:${request.warpId}',
        targetMapId: targetBundle.map.id,
        targetPos: targetWarp.pos,
        triggerMode: MapWarpTriggerMode.onEnter,
      );
      debugPrint(
        '[scenario_runtime] transitionMap start map=${transition.targetMapId} warp=${request.warpId} pos=(${transition.targetPos.x},${transition.targetPos.y})',
      );
      await _handleWarp(transition);
    } catch (e, st) {
      debugPrint(
        '[scenario_runtime] transitionMap failed map=${request.mapId} warp=${request.warpId}: $e\n$st',
      );
      _showNotification('Transition impossible');
    }
  }

  MapWarp? _findMapWarpById(String warpId) {
    final normalized = warpId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final warp in _world.map.warps) {
      if (warp.id == normalized) {
        return warp;
      }
    }
    return null;
  }

  List<GridPos> _resolveScenarioWarpApproachCandidates({
    required String entityId,
    required MapWarp warp,
    required GridPos primaryDestination,
  }) {
    final currentPos = _resolveScenarioEntityPosition(entityId) ?? warp.pos;
    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};

    // Anneaux autour du warp: on essaie de rester proche de la porte tout en
    // respectant le footprint collision réel du PNJ (souvent 2x2).
    const maxRadius = 4;
    for (var radius = 1; radius <= maxRadius; radius++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final top = GridPos(x: warp.pos.x + dx, y: warp.pos.y - radius);
        if (_addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: top,
          entityId: entityId,
        )) {
          // no-op
        }
        final bottom = GridPos(x: warp.pos.x + dx, y: warp.pos.y + radius);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: bottom,
          entityId: entityId,
        );
      }
      for (var dy = -radius + 1; dy <= radius - 1; dy++) {
        final left = GridPos(x: warp.pos.x - radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: left,
          entityId: entityId,
        );
        final right = GridPos(x: warp.pos.x + radius, y: warp.pos.y + dy);
        _addWarpApproachCandidate(
          seen: seen,
          out: candidates,
          candidate: right,
          entityId: entityId,
        );
      }
    }

    candidates.sort((a, b) {
      final aDoor = (a.x - warp.pos.x).abs() + (a.y - warp.pos.y).abs();
      final bDoor = (b.x - warp.pos.x).abs() + (b.y - warp.pos.y).abs();
      if (aDoor != bDoor) {
        return aDoor.compareTo(bDoor);
      }
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      return aCurrent.compareTo(bCurrent);
    });
    return candidates;
  }

  List<GridPos> _resolveScenarioEntityApproachCandidates({
    required String moverEntityId,
    required String targetEntityId,
    required GridPos primaryDestination,
  }) {
    final currentPos =
        _resolveScenarioEntityPosition(moverEntityId) ?? primaryDestination;

    MapRect targetRect;
    if (targetEntityId == 'player') {
      targetRect = MapRect(
        pos: _world.player.pos,
        size: const GridSize(width: 1, height: 1),
      );
    } else {
      MapEntity? targetEntity;
      for (final entry in _world.map.entities) {
        if (entry.id == targetEntityId) {
          targetEntity = entry;
          break;
        }
      }
      if (targetEntity == null) {
        return const <GridPos>[];
      }
      targetRect = resolveEntityCollisionFootprint(targetEntity);
    }

    final candidates = <GridPos>[];
    final seen = <GridPos>{primaryDestination};
    for (final cell in _adjacentCellsAroundRect(targetRect)) {
      if (!seen.add(cell)) {
        continue;
      }
      if (!_isWithinMapBounds(_world.map, cell)) {
        continue;
      }
      if (!_isScenarioNpcAnchorPassable(
          entityId: moverEntityId, anchor: cell)) {
        continue;
      }
      candidates.add(cell);
    }

    candidates.sort((a, b) {
      final aCurrent = (a.x - currentPos.x).abs() + (a.y - currentPos.y).abs();
      final bCurrent = (b.x - currentPos.x).abs() + (b.y - currentPos.y).abs();
      if (aCurrent != bCurrent) {
        return aCurrent.compareTo(bCurrent);
      }
      final aTarget =
          (a.x - targetRect.pos.x).abs() + (a.y - targetRect.pos.y).abs();
      final bTarget =
          (b.x - targetRect.pos.x).abs() + (b.y - targetRect.pos.y).abs();
      return aTarget.compareTo(bTarget);
    });
    return candidates;
  }

  bool _addWarpApproachCandidate({
    required Set<GridPos> seen,
    required List<GridPos> out,
    required GridPos candidate,
    required String entityId,
  }) {
    if (!seen.add(candidate)) {
      return false;
    }
    if (!_isWithinMapBounds(_world.map, candidate)) {
      return false;
    }
    if (!_isScenarioNpcAnchorPassable(entityId: entityId, anchor: candidate)) {
      return false;
    }
    out.add(candidate);
    return true;
  }

  bool _isScenarioNpcAnchorPassable({
    required String entityId,
    required GridPos anchor,
  }) {
    if (entityId.trim() == 'player') {
      return _isPlayerScriptedMoveAnchorPassable(anchor);
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: anchor,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    return probe.passable;
  }

  bool _isPlayerScriptedMoveAnchorPassable(GridPos anchor) {
    final mode = _world.player.movementMode;
    if (_world.movementBlockReasonAt(
          x: anchor.x,
          y: anchor.y,
          movementMode: mode,
        ) !=
        null) {
      return false;
    }
    for (final cell
        in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
      if (cell.x == anchor.x && cell.y == anchor.y) {
        return false;
      }
    }
    return true;
  }

  GridPos? _resolveScenarioEntityPosition(String entityId) {
    if (entityId == 'player') {
      return _world.player.pos;
    }
    final runtimePos = _runtimeNpcPositions[entityId];
    if (runtimePos != null) {
      return runtimePos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == entityId) {
        return entity.pos;
      }
    }
    return null;
  }

  GridPos? _resolveScenarioMoveTarget({
    required String targetKind,
    required String targetId,
  }) {
    final map = _world.map;
    switch (targetKind) {
      case 'warp':
        for (final warp in map.warps) {
          if (warp.id == targetId) {
            return warp.pos;
          }
        }
        return null;
      case 'spawn':
        for (final entity in map.entities) {
          if (entity.kind == MapEntityKind.spawn && entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      case 'entity':
        if (targetId == 'player') {
          return _world.player.pos;
        }
        for (final entity in map.entities) {
          if (entity.id == targetId) {
            return entity.pos;
          }
        }
        return null;
      default:
        return null;
    }
  }

  bool _suppressOverworldInputForScriptedPlayerMovement() {
    final status = scriptedNpcMovementStatus('player');
    return status.state == ScriptedEntityMovementState.moving;
  }

  void _clearPressedMovementKeys() {
    _pressedKeys.removeWhere(_isMovementKey);
    if (_lastMoveKey != null && !_pressedKeys.contains(_lastMoveKey!)) {
      _lastMoveKey = null;
    }
  }

  void _processPendingScenarioNpcWarpEntries() {
    if (_pendingScenarioNpcWarpEntries.isEmpty) {
      return;
    }
    final entityIds =
        _pendingScenarioNpcWarpEntries.keys.toList(growable: false)..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioNpcWarpEntries[entityId];
      if (pending == null) {
        continue;
      }
      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        debugPrint(
          '[scenario_runtime] npc warp canceled entity=$entityId warp=${pending.warpId} reason="${status.failureReason ?? 'move failed'}"',
        );
        _pendingScenarioNpcWarpEntries.remove(entityId);
        continue;
      }
      if (status.state != ScriptedEntityMovementState.completed) {
        final stillPresent = _resolveScenarioEntityPosition(entityId) != null;
        if (!stillPresent) {
          _pendingScenarioNpcWarpEntries.remove(entityId);
        }
        continue;
      }
      _pendingScenarioNpcWarpEntries.remove(entityId);
      _completeScenarioNpcWarpEntry(pending);
    }
  }

  void _processPendingScenarioMoveContinuations() {
    if (_pendingScenarioMoveContinuationsByEntity.isEmpty) {
      return;
    }
    final entityIds = _pendingScenarioMoveContinuationsByEntity.keys
        .toList(growable: false)
      ..sort();
    for (final entityId in entityIds) {
      final pending = _pendingScenarioMoveContinuationsByEntity[entityId];
      if (pending == null) {
        continue;
      }

      if (pending.targetKind == 'warp' && _pendingWarp != null) {
        // Le déplacement est "fini" uniquement après consommation effective du
        // warp joueur et retour en overworld.
        continue;
      }

      final status = scriptedNpcMovementStatus(entityId);
      if (status.state == ScriptedEntityMovementState.moving) {
        continue;
      }
      if (status.state == ScriptedEntityMovementState.failed) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        continue;
      }
      if (status.state == ScriptedEntityMovementState.completed ||
          status.state == ScriptedEntityMovementState.idle) {
        _pendingScenarioMoveContinuationsByEntity.remove(entityId);
        _resumeScenarioAfterRuntimeSource(pending.runtimeSourceId);
      }
    }
  }

  void _completeScenarioNpcWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    if (pending.entityId.trim() == 'player') {
      _completeScenarioPlayerWarpEntry(pending);
      return;
    }
    final removed = _despawnNpcFromActiveMap(pending.entityId);
    if (!removed) {
      debugPrint(
        '[scenario_runtime] npc warp failed to remove entity=${pending.entityId} warp=${pending.warpId}',
      );
      return;
    }
    debugPrint(
      '[scenario_runtime] npc entered warp entity=${pending.entityId} warp=${pending.warpId} approach=(${pending.approachPos.x},${pending.approachPos.y})',
    );
  }

  void _completeScenarioPlayerWarpEntry(_PendingScenarioNpcWarpEntry pending) {
    final warp = _findMapWarpById(pending.warpId);
    if (warp == null) {
      debugPrint(
        '[scenario_runtime] player warp failed: warp "${pending.warpId}" not found on map "${_bundle.map.id}"',
      );
      return;
    }
    _pendingWarp = TriggeredWarp(
      warpId: warp.id,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      triggerMode: warp.triggerMode,
    );
    debugPrint(
      '[scenario_runtime] player reached warp=${warp.id} -> map=${warp.targetMapId} target=(${warp.targetPos.x},${warp.targetPos.y})',
    );
  }

  bool _despawnNpcFromActiveMap(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == normalized);
    if (index < 0) {
      return false;
    }

    final updatedEntities = List<MapEntity>.from(entities)..removeAt(index);
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );

    final loaded = _loadedMapsById[_activeMapId];
    if (loaded != null) {
      _purgeMountedNpcActorForEntity(entityId: normalized, loaded: loaded);
    }

    _scriptedNpcReservedOccupiedCellsByEntity.remove(normalized);
    _runtimeNpcPositions.remove(normalized);
    _triggeredTrainerBattles.remove(normalized);
    if (_pendingScenarioFollowRequest?.leaderEntityId == normalized) {
      _pendingScenarioFollowRequest = null;
    }
    _pendingScenarioNpcWarpEntries.remove(normalized);
    _pendingScenarioMoveContinuationsByEntity.remove(normalized);
    _scriptedEntityMovementController?.untrackEntity(normalized);
    _syncGameStateFromWorld();
    return true;
  }

  bool _runScenarioFollowCharacter({
    required String leaderEntityId,
  }) {
    _pendingScenarioFollowRequest = _PendingScenarioFollowRequest(
      leaderEntityId: leaderEntityId,
      requestedAtMs: _runtimeClockMs,
    );
    debugPrint(
      '[scenario_runtime] followCharacter activated leader=$leaderEntityId',
    );
    // On traite la première itération immédiatement pour éviter un frame de latence.
    _processPendingScenarioFollowRequest();
    return true;
  }

  void _processPendingScenarioFollowRequest() {
    final pending = _pendingScenarioFollowRequest;
    if (pending == null) {
      return;
    }
    final leaderPos = _resolveScenarioLeaderPosition(pending.leaderEntityId);
    if (leaderPos == null) {
      debugPrint(
        '[scenario_runtime] followCharacter canceled leader unresolved=${pending.leaderEntityId}',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: pending.leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final leaderMovement = scriptedNpcMovementStatus(pending.leaderEntityId);
    final leaderTravelDirection = _resolveLeaderTravelDirection(
      pending: pending,
      leaderPos: leaderPos,
      movementStatus: leaderMovement,
    );
    final preferredTrailingSide = leaderTravelDirection == null
        ? null
        : _oppositeDirection(leaderTravelDirection);
    final playerPos = _world.player.pos;
    final playerAdjacentToLeader = _isPosAdjacentToRect(playerPos, leaderRect);

    // Condition de fin:
    // - leader immobile
    // - joueur déjà adjacent au footprint réel du leader.
    if (leaderMovement.state != ScriptedEntityMovementState.moving &&
        playerAdjacentToLeader) {
      debugPrint(
        '[scenario_runtime] followCharacter completed leader=${pending.leaderEntityId} player=(${playerPos.x},${playerPos.y})',
      );
      _pendingScenarioFollowRequest = null;
      return;
    }

    // Si le joueur est déjà en interpolation, on attend le prochain tick.
    if (_player.isStepping) {
      return;
    }

    final canReuseCachedPath = pending.cachedPath != null &&
        pending.cachedPathDestination != null &&
        pending.cachedPathLeaderPos != null &&
        pending.cachedPathLeaderPos!.x == leaderPos.x &&
        pending.cachedPathLeaderPos!.y == leaderPos.y;
    if (canReuseCachedPath) {
      final nextPos = _nextFollowPathStep(
        path: pending.cachedPath!,
        currentPos: playerPos,
      );
      if (nextPos != null) {
        final stepped = _stepPlayerAlongFollowPath(
          leaderEntityId: pending.leaderEntityId,
          leaderPos: leaderPos,
          destination: pending.cachedPathDestination!,
          nextPos: nextPos,
          preferredTrailingSide: preferredTrailingSide,
        );
        if (stepped) {
          pending.consecutiveBlockedSteps = 0;
          return;
        }
        pending.consecutiveBlockedSteps += 1;
        _clearPendingFollowPathCache(pending);
        if (leaderMovement.state != ScriptedEntityMovementState.moving &&
            pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
        return;
      }
      _clearPendingFollowPathCache(pending);
    }

    final followPlan = _resolveFollowPathPlanNearLeader(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      preferredSide: preferredTrailingSide,
      strictPreferredSide:
          leaderMovement.state == ScriptedEntityMovementState.moving,
    );
    if (followPlan == null) {
      if (leaderMovement.state != ScriptedEntityMovementState.moving) {
        pending.consecutiveBlockedSteps += 1;
        if (pending.consecutiveBlockedSteps >= 10) {
          debugPrint(
            '[scenario_runtime] followCharacter canceled no reachable trailing path leader=${pending.leaderEntityId}',
          );
          _pendingScenarioFollowRequest = null;
        }
      }
      return;
    }
    pending.consecutiveBlockedSteps = 0;

    // Si on est déjà au meilleur point, on attend la prochaine évolution leader.
    if (followPlan.path.length <= 1 ||
        (followPlan.destination.x == playerPos.x &&
            followPlan.destination.y == playerPos.y)) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    pending.cachedPath = followPlan.path;
    pending.cachedPathDestination = followPlan.destination;
    pending.cachedPathLeaderPos = leaderPos;
    final nextPos = _nextFollowPathStep(
      path: followPlan.path,
      currentPos: playerPos,
    );
    if (nextPos == null) {
      _clearPendingFollowPathCache(pending);
      return;
    }

    final stepped = _stepPlayerAlongFollowPath(
      leaderEntityId: pending.leaderEntityId,
      leaderPos: leaderPos,
      destination: followPlan.destination,
      nextPos: nextPos,
      preferredTrailingSide: preferredTrailingSide,
    );
    if (!stepped) {
      pending.consecutiveBlockedSteps += 1;
      _clearPendingFollowPathCache(pending);
      if (leaderMovement.state != ScriptedEntityMovementState.moving &&
          pending.consecutiveBlockedSteps >= 10) {
        debugPrint(
          '[scenario_runtime] followCharacter canceled repeated blocked steps leader=${pending.leaderEntityId}',
        );
        _pendingScenarioFollowRequest = null;
      }
    }
  }

  bool _stepPlayerAlongFollowPath({
    required String leaderEntityId,
    required GridPos leaderPos,
    required GridPos destination,
    required GridPos nextPos,
    required Direction? preferredTrailingSide,
  }) {
    final currentPos = _world.player.pos;
    final direction = _directionBetweenAdjacent(
      from: currentPos,
      to: nextPos,
    );
    if (direction == null) {
      debugPrint(
        '[scenario_runtime] followCharacter invalid non-adjacent path step leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }

    final result = stepGameplayWorld(_world, MoveIntent(direction));
    if (result is! Moved) {
      debugPrint(
        '[scenario_runtime] followCharacter path step blocked leader=$leaderEntityId from=(${currentPos.x},${currentPos.y}) to=(${nextPos.x},${nextPos.y})',
      );
      return false;
    }
    _world = result.world;
    _syncGameStateFromWorld();
    _consumePathAnimationSignals(result.pathAnimationSignals);
    _player.startStep(
      _world.player,
      durationSeconds: PlayerComponent.kDefaultStepSeconds,
    );
    _dispatchScenarioTriggerEnterFromMovement(
      previousPos: currentPos,
      currentPos: _world.player.pos,
    );
    debugPrint(
      '[scenario_runtime] followCharacter stepping leader=$leaderEntityId leaderPos=(${leaderPos.x},${leaderPos.y}) trailingSide=${preferredTrailingSide?.name ?? '-'} destination=(${destination.x},${destination.y}) next=(${nextPos.x},${nextPos.y}) playerPos=(${_world.player.pos.x},${_world.player.pos.y})',
    );
    return true;
  }

  bool _runScenarioFaceCharacter({
    required String entityId,
    required String direction,
  }) {
    final facing = _parseEntityFacing(direction);
    if (facing == null) {
      debugPrint(
        '[scenario_runtime] faceCharacter invalid direction="$direction"',
      );
      return false;
    }
    if (entityId == 'player') {
      final next =
          _world.player.copyWith(facing: _directionFromEntityFacing(facing));
      _world = _world.withPlayer(next);
      _syncGameStateFromWorld();
      _player.syncState(_world.player, snapToGrid: true);
      return true;
    }
    final normalizedEntityId = entityId.trim();
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[normalizedEntityId];
    if (actor != null) {
      final movement = scriptedNpcMovementStatus(normalizedEntityId);
      if (movement.state == ScriptedEntityMovementState.moving ||
          actor.isStepping) {
        debugPrint(
          '[scenario_runtime] faceCharacter deferred entity=$normalizedEntityId while moving',
        );
        return true;
      }
      actor.setMotion(facing, CharacterAnimationState.idle);
      return true;
    }

    // Tolérance runtime: si l’entité n’a pas d’acteur visuel actuellement
    // monté (ex: map context différente), on tente au moins de persister
    // l’orientation dans l’état map; sinon on ignore sans bloquer le flow.
    if (_setEntityFacingStateOnly(normalizedEntityId, facing)) {
      debugPrint(
        '[scenario_runtime] faceCharacter applied state-only entity="$normalizedEntityId"',
      );
      return true;
    }
    debugPrint(
      '[scenario_runtime] faceCharacter entity unresolved="$normalizedEntityId" (ignored)',
    );
    return true;
  }

  bool _setEntityFacingStateOnly(String entityId, EntityFacing facing) {
    if (entityId.isEmpty) {
      return false;
    }
    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return false;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return false;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    final playerState = _world.player;
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: playerState.pos,
      playerFacing: playerState.facing,
      playerMovementMode: playerState.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    _syncGameStateFromWorld();
    return true;
  }

  EntityFacing? _parseEntityFacing(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'north':
        return EntityFacing.north;
      case 'south':
        return EntityFacing.south;
      case 'east':
        return EntityFacing.east;
      case 'west':
        return EntityFacing.west;
      default:
        return null;
    }
  }

  Direction _directionFromEntityFacing(EntityFacing facing) {
    switch (facing) {
      case EntityFacing.north:
        return Direction.north;
      case EntityFacing.south:
        return Direction.south;
      case EntityFacing.east:
        return Direction.east;
      case EntityFacing.west:
        return Direction.west;
    }
  }

  GridPos? _resolveScenarioLeaderPosition(String leaderEntityId) {
    final movementStatus = scriptedNpcMovementStatus(leaderEntityId);
    if (movementStatus.entityId == leaderEntityId) {
      return movementStatus.currentPos;
    }
    final active = _loadedMapsById[_activeMapId];
    final actor = active?.npcActorByEntityId[leaderEntityId];
    final actorGridPos = actor?.gridPos;
    if (actorGridPos != null) {
      return actorGridPos;
    }
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        return entity.pos;
      }
    }
    return null;
  }

  _FollowPathPlan? _resolveFollowPathPlanNearLeader({
    required String leaderEntityId,
    required GridPos leaderPos,
    required Direction? preferredSide,
    required bool strictPreferredSide,
  }) {
    final currentPlayerPos = _world.player.pos;
    final leaderRect = _resolveScenarioLeaderCollisionFootprint(
      leaderEntityId: leaderEntityId,
      fallbackAnchor: leaderPos,
    );
    final candidates = <GridPos>[];
    final preferredCandidates = <GridPos>{};
    if (preferredSide != null) {
      final trailing = _cellsAlongRectSide(leaderRect, preferredSide).toList();
      candidates.addAll(trailing);
      preferredCandidates.addAll(trailing);
    }
    if (!strictPreferredSide) {
      candidates.addAll(_adjacentCellsAroundRect(leaderRect));
    }
    final deduplicated = candidates.toSet().toList(growable: false);
    deduplicated.sort((a, b) {
      final aPreferred = preferredCandidates.contains(a) ? 0 : 1;
      final bPreferred = preferredCandidates.contains(b) ? 0 : 1;
      if (aPreferred != bPreferred) {
        return aPreferred.compareTo(bPreferred);
      }
      final da =
          (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
      final db =
          (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
      return da.compareTo(db);
    });
    for (final candidate in deduplicated) {
      if (!_canPlacePlayerAt(candidate)) {
        continue;
      }
      final path = _computeFollowPlayerPath(
        start: currentPlayerPos,
        goal: candidate,
      );
      if (path == null) {
        continue;
      }
      return _FollowPathPlan(
        destination: candidate,
        path: path,
      );
    }

    // Si la cible "derrière" est impossible en déplacement, on autorise un
    // fallback adjacent pour éviter les blocages durs dans les couloirs.
    if (strictPreferredSide) {
      final relaxedCandidates =
          _adjacentCellsAroundRect(leaderRect).toSet().toList(growable: false);
      relaxedCandidates.sort((a, b) {
        final da =
            (a.x - currentPlayerPos.x).abs() + (a.y - currentPlayerPos.y).abs();
        final db =
            (b.x - currentPlayerPos.x).abs() + (b.y - currentPlayerPos.y).abs();
        return da.compareTo(db);
      });
      for (final candidate in relaxedCandidates) {
        if (!_canPlacePlayerAt(candidate)) {
          continue;
        }
        final path = _computeFollowPlayerPath(
          start: currentPlayerPos,
          goal: candidate,
        );
        if (path == null) {
          continue;
        }
        return _FollowPathPlan(
          destination: candidate,
          path: path,
        );
      }
    }

    if (_isPosAdjacentToRect(currentPlayerPos, leaderRect) &&
        _canPlacePlayerAt(currentPlayerPos)) {
      return _FollowPathPlan(
        destination: currentPlayerPos,
        path: <GridPos>[currentPlayerPos],
      );
    }
    return null;
  }

  List<GridPos>? _computeFollowPlayerPath({
    required GridPos start,
    required GridPos goal,
  }) {
    final result = _followPathfinder.findPath(
      bounds: _world.map.size,
      start: start,
      goal: goal,
      isPassable: (x, y) {
        if (x == start.x && y == start.y) {
          return true;
        }
        final cell = GridPos(x: x, y: y);
        if (!_isWithinMapBounds(_world.map, cell)) {
          return false;
        }
        if (_isCellReservedByScriptedNpc(cell)) {
          return false;
        }
        final trial = _world.withPlayer(_world.player.copyWith(pos: cell));
        return !trial.isBlocked(x, y);
      },
    );
    if (!result.foundPath) {
      return null;
    }
    return result.path;
  }

  Direction? _directionBetweenAdjacent({
    required GridPos from,
    required GridPos to,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    if (dx == 0 && dy == -1) return Direction.north;
    if (dx == 0 && dy == 1) return Direction.south;
    if (dx == 1 && dy == 0) return Direction.east;
    if (dx == -1 && dy == 0) return Direction.west;
    return null;
  }

  GridPos? _nextFollowPathStep({
    required List<GridPos> path,
    required GridPos currentPos,
  }) {
    if (path.length < 2) {
      return null;
    }
    final currentIndex = path.indexWhere(
      (cell) => cell.x == currentPos.x && cell.y == currentPos.y,
    );
    if (currentIndex < 0 || currentIndex + 1 >= path.length) {
      return null;
    }
    return path[currentIndex + 1];
  }

  void _clearPendingFollowPathCache(_PendingScenarioFollowRequest pending) {
    pending.cachedPath = null;
    pending.cachedPathDestination = null;
    pending.cachedPathLeaderPos = null;
  }

  MapRect _resolveScenarioLeaderCollisionFootprint({
    required String leaderEntityId,
    required GridPos fallbackAnchor,
  }) {
    for (final entity in _world.map.entities) {
      if (entity.id == leaderEntityId) {
        final footprint = resolveEntityCollisionFootprint(entity);
        final offsetX = footprint.pos.x - entity.pos.x;
        final offsetY = footprint.pos.y - entity.pos.y;
        return MapRect(
          pos: GridPos(
            x: fallbackAnchor.x + offsetX,
            y: fallbackAnchor.y + offsetY,
          ),
          size: footprint.size,
        );
      }
    }
    return MapRect(
      pos: fallbackAnchor,
      size: const GridSize(width: 1, height: 1),
    );
  }

  Iterable<GridPos> _adjacentCellsAroundRect(MapRect rect) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final yielded = <GridPos>{};

    for (var x = left; x <= right; x++) {
      final north = GridPos(x: x, y: top - 1);
      if (yielded.add(north)) {
        yield north;
      }
      final south = GridPos(x: x, y: bottom + 1);
      if (yielded.add(south)) {
        yield south;
      }
    }
    for (var y = top; y <= bottom; y++) {
      final west = GridPos(x: left - 1, y: y);
      if (yielded.add(west)) {
        yield west;
      }
      final east = GridPos(x: right + 1, y: y);
      if (yielded.add(east)) {
        yield east;
      }
    }
  }

  Iterable<GridPos> _cellsAlongRectSide(MapRect rect, Direction side) sync* {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    switch (side) {
      case Direction.north:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: top - 1);
        }
      case Direction.south:
        for (var x = left; x <= right; x++) {
          yield GridPos(x: x, y: bottom + 1);
        }
      case Direction.east:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: right + 1, y: y);
        }
      case Direction.west:
        for (var y = top; y <= bottom; y++) {
          yield GridPos(x: left - 1, y: y);
        }
    }
  }

  Direction? _resolveLeaderTravelDirection({
    required _PendingScenarioFollowRequest pending,
    required GridPos leaderPos,
    required ScriptedEntityMovementStatus movementStatus,
  }) {
    final previous = pending.lastLeaderPos;
    pending.lastLeaderPos = leaderPos;
    if (previous != null) {
      final dx = leaderPos.x - previous.x;
      final dy = leaderPos.y - previous.y;
      final fromDelta = _directionFromDelta(dx, dy);
      if (fromDelta != null) {
        pending.lastLeaderTravelDirection = fromDelta;
        return fromDelta;
      }
    }
    if (movementStatus.state == ScriptedEntityMovementState.moving &&
        movementStatus.targetPos != null) {
      final target = movementStatus.targetPos!;
      final dx = target.x - leaderPos.x;
      final dy = target.y - leaderPos.y;
      final fromTargetVector = _directionFromDelta(dx, dy);
      if (fromTargetVector != null) {
        pending.lastLeaderTravelDirection = fromTargetVector;
        return fromTargetVector;
      }
    }
    return pending.lastLeaderTravelDirection;
  }

  Direction? _directionFromDelta(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      return null;
    }
    if (dx.abs() >= dy.abs()) {
      return dx >= 0 ? Direction.east : Direction.west;
    }
    return dy >= 0 ? Direction.south : Direction.north;
  }

  Direction _oppositeDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }

  bool _isPosAdjacentToRect(GridPos pos, MapRect rect) {
    final left = rect.pos.x;
    final top = rect.pos.y;
    final right = left + rect.size.width - 1;
    final bottom = top + rect.size.height - 1;
    final isInside =
        pos.x >= left && pos.x <= right && pos.y >= top && pos.y <= bottom;
    if (isInside) {
      return false;
    }
    final dx =
        pos.x < left ? left - pos.x : (pos.x > right ? pos.x - right : 0);
    final dy =
        pos.y < top ? top - pos.y : (pos.y > bottom ? pos.y - bottom : 0);
    return math.max(dx, dy) == 1;
  }

  bool _canPlacePlayerAt(GridPos pos) {
    if (!_isWithinMapBounds(_world.map, pos)) {
      return false;
    }
    final trial = _world.withPlayer(_world.player.copyWith(pos: pos));
    return !trial.isBlocked(pos.x, pos.y);
  }

  /// Lance un script projet à partir d'un `scriptId`.
  ///
  /// Callback utilisé par le bridge scénario.
  bool _runScenarioScriptById(
    String scriptId, {
    String? startNode,
    String? runtimeSourceId,
  }) {
    final normalizedScriptId = scriptId.trim();
    if (normalizedScriptId.isEmpty) {
      return false;
    }
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      return false;
    }
    ScriptAsset? scriptAsset;
    for (final entry in _bundle.manifest.scripts) {
      if (entry.id == normalizedScriptId) {
        scriptAsset = entry.asset;
        break;
      }
    }
    if (scriptAsset == null) {
      debugPrint('[scenario_runtime] script not found: $normalizedScriptId');
      return false;
    }
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: startNode,
      runtimeSourceId: runtimeSourceId ?? 'scenario',
    );
    return true;
  }

  void _logEncounterCheck(GameplayEncounterCheckResult check) {
    final kind = check.encounterKind?.name ?? EncounterKind.walk.name;
    switch (check.status) {
      case GameplayEncounterCheckStatus.noZone:
        debugPrint('[encounter] no compatible zone');
        return;
      case GameplayEncounterCheckStatus.noEncounterTableId:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} has no encounter table id (kind=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.encounterTableNotFound:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} not found',
        );
        return;
      case GameplayEncounterCheckStatus.encounterKindMismatch:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} kind mismatch (expected=$kind)',
        );
        return;
      case GameplayEncounterCheckStatus.emptyEncounterTable:
        debugPrint(
          '[encounter] zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'} has no valid entries',
        );
        return;
      case GameplayEncounterCheckStatus.rollFailed:
        debugPrint(
          '[encounter] matched zone=${check.zoneId ?? 'unknown'} table=${check.tableId ?? 'unknown'}',
        );
        debugPrint(
          '[encounter] rolled no encounter roll=${check.roll?.toStringAsFixed(3) ?? 'n/a'}',
        );
        return;
      case GameplayEncounterCheckStatus.triggered:
        final encounter = check.encounter;
        if (encounter == null) {
          debugPrint('[encounter] triggered status without payload');
          return;
        }
        debugPrint(
          '[encounter] matched zone=${encounter.zoneId} table=${encounter.tableId}',
        );
        debugPrint(
          '[encounter] triggered species=${encounter.speciesId} level=${encounter.level} kind=${encounter.encounterKind.name}',
        );
        return;
    }
  }

  /// Démarre le handoff de combat.
  ///
  /// [request] - La requête de combat (wild ou trainer).
  ///
  /// Cette méthode :
  /// 1. Stocke la requête pour le mapping vers BattleSetup
  /// 2. Passe en phase battleTransition
  /// 3. Affiche l'overlay de transition
  void _startBattleHandoff(BattleStartRequest request) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      return;
    }
    _flowPhase = _RuntimeFlowPhase.battleTransition;
    _notification?.removeFromParent();
    _notification = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    debugPrint(
      '[battle] transition started requestId=${request.requestId} kind=${request.kind.name}',
    );
    final overlay = BattleTransitionOverlayComponent(
      request: request,
      viewportSize: camera.viewport.size,
      onFinished: () {
        // Le mapping vers BattleSetup peut maintenant lire le vrai projet et
        // échouer explicitement. On déclenche donc l'ouverture de manière async
        // au lieu de supposer qu'un setup placeholder sera toujours disponible.
        unawaited(_openBattleOverlay(request));
      },
    );
    camera.viewport.add(overlay);
    _battleTransitionOverlay = overlay;
  }

  /// Ouvre l'overlay de combat après la transition.
  ///
  /// [request] - La requête de combat.
  ///
  /// Cette méthode :
  /// 1. Mappe BattleStartRequest → BattleSetup
  /// 2. Crée la BattleSession
  /// 3. Affiche BattleOverlayComponent avec la session
  Future<void> _openBattleOverlay(BattleStartRequest request) async {
    if (_flowPhase != _RuntimeFlowPhase.battleTransition) {
      return;
    }
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    try {
      // BE10 recadré élargit légèrement cet invariant runtime :
      // - on mémorise toujours le slot actif exact utilisé au handoff ;
      // - mais on mémorise aussi l'ordre actif + réserves réellement injecté
      //   dans le combat ;
      // - cela permet ensuite un write-back honnête si le joueur switch.
      //
      // Pourquoi ici :
      // - la sélection se fait sur le vrai GameState runtime, juste avant le
      //   mapping vers BattleSetup ;
      // - on réutilise ensuite ce mapping stable au moment du write-back ;
      // - on évite ainsi le bug classique "recalculer le premier Pokémon
      //   jouable après le combat", qui casserait la cohérence dès qu'un
      //   switch a déplacé l'actif.
      final playerLineup =
          _battleSetupMapper.selectPlayerBattleLineup(_gameState.party);

      // Le lot 9 remplace enfin le setup placeholder par un mapping réel
      // depuis la save runtime et les données projet.
      final setup = await _toBattleSetup(
        request,
        playerPartyIndex: playerLineup.activeIndex,
      );

      // Lot 12 pose le premier write runtime honnête du "seen" :
      // l'espèce ennemie n'est marquée vue qu'une fois le handoff réellement
      // résolu et le combat effectivement prêt à s'ouvrir.
      //
      // On évite volontairement de marquer plus tôt :
      // - une simple case d'herbe ne suffit pas ;
      // - un setup qui échoue ne doit rien écrire ;
      // - aucune capture n'est ouverte ici.
      _gameState = markSpeciesSeenInGameState(
        _gameState,
        setup.enemyPokemon.speciesId,
      );
      _flowPhase = _RuntimeFlowPhase.battle;

      // Créer la session de combat
      _battleSession = createBattleSession(setup);
      _activeBattleContext = RuntimeActiveBattleContext(
        request: request,
        playerPartyIndex: playerLineup.activeIndex,
        playerPartySlotIndicesByLineupIndex: playerLineup.lineupPartyIndices,
      );

      // Lot 2 garde la résolution de fond intégralement côté runtime :
      // - le battle-core n'a aucune connaissance de décor ;
      // - on se limite au contexte déjà disponible ici (request + map active) ;
      // - on n'introduit pas encore de resolver contextuel plus large que ce
      //   besoin visible immédiat.
      final backgroundSpec = _battleBackgroundResolver.resolve(
        request: request,
        bundle: _bundle,
      );

      // Afficher l'overlay de combat avec la session
      final overlay = BattleOverlayComponent(
        session: _battleSession!,
        viewportSize: camera.viewport.size,
        backgroundSpec: backgroundSpec,
        onPlayerChoice: _onPlayerBattleChoice,
      );
      camera.viewport.add(overlay);
      _battleOverlay = overlay;
      debugPrint(
        '[battle] overlay opened requestId=${request.requestId} kind=${request.kind.name}',
      );
    } on RuntimeBattleSetupException catch (error) {
      _cancelBattleHandoff(
        userMessage: error.message,
        debugDetails: error.debugDetails,
      );
    } catch (error, stackTrace) {
      _cancelBattleHandoff(
        userMessage:
            'Impossible de démarrer le combat avec les données locales du projet.',
        debugDetails: '$error\n$stackTrace',
      );
    }
  }

  /// Mappe BattleStartRequest → BattleSetup.
  ///
  /// [request] - La requête de combat depuis le runtime.
  ///
  /// Retourne un BattleSetup pur pour le moteur de combat.
  Future<BattleSetup> _toBattleSetup(
    BattleStartRequest request, {
    int? playerPartyIndex,
  }) {
    return _battleSetupMapper.map(
      bundle: _bundle,
      gameState: _gameState,
      request: request,
      playerPartyIndex: playerPartyIndex,
    );
  }

  void _cancelBattleHandoff({
    required String userMessage,
    String? debugDetails,
  }) {
    // On nettoie explicitement tout état battle partiellement initialisé.
    // Ce helper évite qu'un mapping KO laisse le runtime coincé en transition.
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false;
    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint(
      '[battle] handoff cancelled message="$userMessage" details=${debugDetails ?? 'n/a'}',
    );
    _showNotification(userMessage);
  }

  /// Gère le choix du joueur pendant le combat.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode :
  /// 1. Applique le choix via BattleSession.applyChoice()
  /// 2. Met à jour l'UI
  /// 3. Vérifie si le combat est fini
  /// 4. Si fini, appelle _onBattleFinished()
  ///
  /// **Lock anti-spam** : `_isBattleResolving` empêche le spam clavier
  /// pendant la résolution d'un tour.
  void _onPlayerBattleChoice(PlayerBattleChoice choice) {
    if (_battleSession == null) {
      return;
    }

    // Lock anti-spam : empêcher traitement multiple pendant résolution
    if (_isBattleResolving) {
      debugPrint('[battle] choice ignored: already resolving');
      return;
    }
    _isBattleResolving = true;

    try {
      // Appliquer le choix (retourne une nouvelle session immutable)
      _battleSession = _battleSession!.applyChoice(choice);

      // Mettre à jour l'UI avec le nouvel état
      final overlay = _battleOverlay;
      overlay?.updateState(_battleSession!);

      // Vérifier si le combat est fini
      if (_battleSession!.state.isFinished) {
        _onBattleFinished(_battleSession!.state.outcome!);
      }
    } finally {
      // Unlock après résolution (ou après fin de combat)
      // Si combat fini, _onBattleFinished() va reset l'état de toute façon
      if (_flowPhase == _RuntimeFlowPhase.battle) {
        _isBattleResolving = false;
      }
    }
  }

  /// Gère la fin du combat.
  ///
  /// [outcome] - Le résultat du combat.
  ///
  /// Cette méthode :
  /// 1. Applique le résultat au vrai GameState runtime
  /// 2. Nettoie l'overlay (SUPPRIME du parent)
  /// 3. Retourne à l'overworld
  void _onBattleFinished(BattleOutcome outcome) {
    debugPrint('[battle] battle finished outcome=${outcome.type.name}');

    // Le lot 10 normalise ici tout le write-back post-combat :
    // - PV du lineup joueur écrits sur les slots exacts mémorisés ;
    // - flag trainer_defeated uniquement sur une vraie victoire trainer ;
    // - aucune tentative de recalcul du Pokémon actif après la fin du combat.
    final activeBattleContext = _activeBattleContext;
    if (activeBattleContext != null) {
      final previousState = _gameState;
      _gameState = applyRuntimeBattleOutcomeToGameState(
        gameState: _gameState,
        context: activeBattleContext,
        outcome: outcome,
        storyFlagsManager: _storyFlags,
      );

      if (outcome.isDefeat) {
        _applyWhiteoutLiteAfterPlayerDefeat(
          activeBattleContext,
          activePlayerLineupIndex: outcome.finalState.player.lineupIndex,
        );
      }

      if (outcome.isVictory &&
          activeBattleContext.request is TrainerBattleStartRequest) {
        final trainerRequest =
            activeBattleContext.request as TrainerBattleStartRequest;
        debugPrint(
          '[battle] trainer marked as defeated: ${trainerRequest.trainerId}',
        );
      }

      // On ne refresh la présence PNJ que si les story flags ont réellement
      // changé ; cela garde le retour overworld minimal pour wild/defeat/run.
      if (!identical(previousState.storyFlags, _gameState.storyFlags) &&
          previousState.storyFlags != _gameState.storyFlags) {
        _refreshWorldNpcPresence();
      }
    }

    // Nettoyer et retourner à l'overworld
    // IMPORTANT: Il faut SUPPRIMER l'overlay du parent, pas juste mettre à null
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleSession = null;
    _activeBattleContext = null;
    _isBattleResolving = false; // Reset lock anti-spam

    // NOTE: NE PAS clear _triggeredTrainerBattles ici!
    // Le lock doit rester actif tant que le joueur est dans la LoS du trainer.
    // Si on clear le lock ici, le trainer sera re-déclenché immédiatement
    // car le joueur est probablement encore dans sa zone de LoS.
    //
    // Le lock sera clear automatiquement quand le joueur quittera la LoS,
    // via le mécanisme de réarmement dans _checkTrainerLineOfSight():
    //   if (_triggeredTrainerBattles.contains(entity.id)) {
    //     if (!inLoS) _triggeredTrainerBattles.remove(entity.id);
    //   }
    //
    // Et même si le lock est encore actif, le trainer ne sera pas re-déclenché
    // car il est marqué defeated dans storyFlags (guard dans _checkTrainerLineOfSight).

    _flowPhase = _RuntimeFlowPhase.overworld;
    _pressedKeys.clear();
    _lastMoveKey = null;
    debugPrint('[battle] overworld resumed');
  }

  void _applyWhiteoutLiteAfterPlayerDefeat(
    RuntimeActiveBattleContext activeBattleContext, {
    required int activePlayerLineupIndex,
  }) {
    // Le whiteout-lite reste volontairement plus petit que BE10 :
    // - le moteur battle sait maintenant switcher et porter une vraie réserve ;
    // - mais cette reprise overworld ne cherche toujours pas à ouvrir un vrai
    //   centre Pokémon, ni une politique riche de défaite ;
    // - on garde donc un simple filet de sécurité post-combat.
    //
    // Le lot 15 reste donc volontairement borné :
    // 1. on garde le write-back lot 10 fidèle aux PV réellement sortis du combat ;
    // 2. puis on évite seulement le softlock total avec une reprise minimale ;
    // 3. on n'ouvre ni centre Pokémon, ni économie, ni pénalité complexe.
    _gameState = applyRuntimeDefeatRecoveryToGameState(
      gameState: _gameState,
      playerPartyIndex: activeBattleContext.playerPartyIndex,
      activePlayerLineupIndex: activePlayerLineupIndex,
      playerPartySlotIndicesByLineupIndex:
          activeBattleContext.playerPartySlotIndicesByLineupIndex,
    );

    final respawn = _resolveWhiteoutLiteRespawn(activeBattleContext);
    _world = _buildSafeWorldState(
      map: _bundle.map,
      project: _bundle.manifest,
      preferredPos: respawn.pos,
      fallbackFacing: respawn.facing,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
    );

    // On reste volontairement sur la carte courante :
    // - aucun "last heal center" persistant n'existe encore dans l'architecture ;
    // - aucun warp multi-map spécial whiteout n'est authoré ;
    // - réutiliser le spawn joueur déjà défini sur la map courante est donc le
    //   point de reprise le plus honnête disponible aujourd'hui.
    _player.syncState(_world.player, snapToGrid: true);
    _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    _configureCameraViewport();
    _syncCameraToPlayer();
    _preloadActiveMapConnections();
    _pruneLoadedMapsToActiveNeighborhood();
    _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
      map: _bundle.map,
      pos: _world.player.pos,
    );
    _refreshWorldNpcPresence();
    _showNotification('Défaite... retour au point de reprise');
  }

  GameplayPlayerState _resolveWhiteoutLiteRespawn(
    RuntimeActiveBattleContext activeBattleContext,
  ) {
    try {
      return resolveInitialPlayerSpawn(_bundle.map);
    } catch (_) {
      // Fallback minimal :
      // - si la map courante n'a pas de spawn joueur exploitable, on repart de
      //   la position overworld mémorisée au moment du handoff combat ;
      // - `_buildSafeWorldState` gardera ensuite le dernier mot pour éviter une
      //   cellule bloquée et trouver un point sûr si nécessaire.
      return GameplayPlayerState(
        pos: activeBattleContext.request.returnContext.playerPos,
        facing: activeBattleContext.request.returnContext.playerFacing,
      );
    }
  }

  void _handleInteract() {
    final result = stepGameplayWorld(_world, const InteractIntent());
    _world = result.world;
    _consumePathAnimationSignals(result.pathAnimationSignals);
    var scenarioHandledEntityInteraction = false;

    switch (result) {
      case NothingToInteract():
        if (result.pathAnimationSignals.isNotEmpty) {
          debugPrint('[interact] Path animation trigger');
          return;
        }
        debugPrint('[interact] Nothing to interact with');
        _showNotification('...');
      case NpcInteracted(:final entity):
        debugPrint('[interact] NPC: ${entity.id}');
        _faceNpcTowardPlayer(entity.id);
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _handleNpcInteraction(entity);
        }
      case SignInteracted(:final entity):
        debugPrint('[interact] Sign: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _tryOpenDialogue(
              entity.id, entity.sign?.dialogue, entity.inspectorHeadline);
        }
      case ItemInteracted(:final entity):
        debugPrint('[interact] Item: ${entity.id}');
        _showNotification(entity.inspectorHeadline);
      case EntityInteracted(:final entity):
        debugPrint('[interact] Entity: ${entity.id}');
        scenarioHandledEntityInteraction =
            _tryDispatchScenarioEntityInteraction(
          entity.id,
        );
        if (!scenarioHandledEntityInteraction) {
          _showNotification(entity.inspectorHeadline);
        }
      case PlacedElementInteracted(
          :final element,
          :final behavior,
          :final trigger,
        ):
        debugPrint('[interact] PlacedElement: ${element.id}');
        _executePlacedElementBehavior(
          element: element,
          behavior: behavior,
          trigger: trigger,
        );
      default:
        break;
    }

    if (result is NothingToInteract ||
        (result is EntityInteracted && !scenarioHandledEntityInteraction)) {
      _tryInteractWithMapEvent();
    }
  }

  bool _tryDispatchScenarioEntityInteraction(String entityId) {
    final result = _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.entityInteract(
        mapId: _activeMapId,
        entityId: entityId,
      ),
    );
    return result.handled;
  }

  void _tryInteractWithMapEvent() {
    if (_activeScriptController != null &&
        !_activeScriptController!.isTerminated) {
      debugPrint('[interact] blocked: script is active');
      return;
    }

    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[interact] blocked: flow phase is $_flowPhase');
      return;
    }

    final facing = _world.player.facing;
    final tx = _world.player.pos.x + facing.dx;
    final ty = _world.player.pos.y + facing.dy;

    final map = _bundle.map;
    MapEventDefinition? event;
    for (final e in map.events) {
      if (e.position.x == tx && e.position.y == ty) {
        event = e;
        break;
      }
    }

    if (event == null) return;

    final activePage = _storyBranching.resolveEventPage(event, _gameState);

    if (activePage == null) return;

    if (activePage.page.isDisabled) return;

    debugPrint('[interact] MapEvent: ${event.id} page=${activePage.pageIndex}');
    _handleMapEventInteraction(event, activePage);
  }

  void _handleMapEventInteraction(
    MapEventDefinition event,
    ActiveEventPage page,
  ) {
    if (page.page.script != null) {
      final message = page.page.message?.trim();
      if (message != null && message.isNotEmpty) {
        _showNotification(message);
      }
      _executeEventScript(event, page, page.page.script!);
    } else if (page.page.message != null && page.page.message!.isNotEmpty) {
      _showNotification(page.page.message!);
    } else {
      _showNotification('...');
    }
  }

  void _executeEventScript(
    MapEventDefinition event,
    ActiveEventPage page,
    ScriptRef scriptRef,
  ) {
    final scriptAsset = _bundle.manifest.scripts
        .firstWhere(
          (s) => s.id == scriptRef.scriptId,
          orElse: () =>
              throw StateError('Script not found: ${scriptRef.scriptId}'),
        )
        .asset;
    _startScriptExecution(
      script: scriptAsset,
      startNodeId: scriptRef.startNode,
      runtimeSourceId: event.id,
    );
  }

  /// Démarrage générique d'exécution script.
  ///
  /// Cette méthode factorise le chemin script:
  /// - scripts de pages d'event map,
  /// - scripts déclenchés par le Scenario Runtime Bridge.
  void _startScriptExecution({
    required ScriptAsset script,
    String? startNodeId,
    required String runtimeSourceId,
  }) {
    final context = ScriptExecutionContext(
      gameState: _gameState,
      onGameStateUpdated: (state) {
        _gameState = state;
        _refreshWorldNpcPresence();
      },
      onDialogueOpened: (dialogue) {
        _openDialogueForScriptSource(runtimeSourceId, dialogue);
      },
      onWarpRequested: (mapId, x, y) {
        _pendingWarp = TriggeredWarp(
          warpId: 'script_warp',
          targetMapId: mapId,
          targetPos: GridPos(x: x, y: y),
          triggerMode: MapWarpTriggerMode.onEnter,
        );
      },
    );

    _activeScriptController = ScriptRuntimeController(
      script: script,
      context: context,
      startNodeId: startNodeId,
    );
    _isAwaitingScriptResume = false;
    _runScriptStep();
  }

  void _runScriptStep() {
    final controller = _activeScriptController;
    if (controller == null) {
      return;
    }

    if (controller.isTerminated) {
      _activeScriptController = null;
      _isAwaitingScriptResume = false;
      return;
    }

    if (controller.isSuspended) {
      _isAwaitingScriptResume = true;
      return;
    }

    final result = controller.step();

    if (result is ScriptCommandResultSuspended) {
      _isAwaitingScriptResume = true;
      if (result.reason == ScriptSuspendReason.waitingForDialogue) {
        _flowPhase = _RuntimeFlowPhase.dialogue;
      }
      return;
    }

    _runScriptStep();
  }

  void _openDialogueForScriptSource(
      String runtimeSourceId, YarnDialogueRef dialogueRef) {
    final resolved = resolveDialogue(
      entityId: runtimeSourceId,
      ref: DialogueRef(
        dialogueId: '',
        scriptPathRelative: dialogueRef.filePath,
        startNode: dialogueRef.startNode,
      ),
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      debugPrint(
          '[script] failed to resolve dialogue: ${dialogueRef.filePath}');
      _runScriptStep();
      return;
    }

    loadDialogueContent(resolved).then((session) {
      if (session == null) {
        debugPrint('[script] failed to load dialogue');
        _runScriptStep();
        return;
      }

      _pendingPostDialogueAction = () {
        _flowPhase = _RuntimeFlowPhase.overworld;
        if (_isAwaitingScriptResume) {
          _isAwaitingScriptResume = false;
          _runScriptStep();
        }
      };

      _openDialogue(session);
    });
  }

  void _consumePathAnimationSignals(List<PathAnimationSignal> signals) {
    if (signals.isEmpty) {
      return;
    }
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final signal in signals) {
      switch (signal.kind) {
        case PathAnimationSignalKind.trigger:
          final backgroundApplied =
              active.backgroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.triggerPathAnimationRule(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            mode: signal.mode,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] trigger ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] trigger layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} mode=${signal.mode.name} source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
        case PathAnimationSignalKind.setActive:
          final activeValue = signal.active ?? false;
          final backgroundApplied =
              active.backgroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          final foregroundApplied =
              active.foregroundLayers.setPathAnimationRuleActive(
            layerId: signal.layerId,
            ruleId: signal.ruleId,
            active: activeValue,
            scope: signal.scope,
            cellX: signal.sourcePos.x,
            cellY: signal.sourcePos.y,
          );
          if (!backgroundApplied && !foregroundApplied) {
            debugPrint(
              '[path_anim] active ignored layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
            );
            continue;
          }
          debugPrint(
            '[path_anim] active layer=${signal.layerId} preset=${signal.presetId} rule=${signal.ruleId} trigger=${signal.trigger.name} active=$activeValue source=(${signal.sourcePos.x}, ${signal.sourcePos.y})',
          );
      }
    }
  }

  void _executePlacedElementBehavior({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    if (!behavior.enabled) {
      return;
    }
    final effect = behavior.effect;
    final cooldownKey = _buildPlacedBehaviorCooldownKey(
      element: element,
      behavior: behavior,
      trigger: trigger,
    );
    final cooldownOverride = _resolvePlacedBehaviorCooldownOverride(behavior);
    if (!_placedBehaviorCooldownGate.canTrigger(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
    )) {
      final remainingMs = _placedBehaviorCooldownGate.remainingMs(
        key: cooldownKey,
        nowMs: _runtimeClockMs,
      );
      debugPrint(
        '[placed_behavior] cooldown blocked trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name} remainingMs=${remainingMs.toStringAsFixed(0)}',
      );
      _updateBehaviorDebugLine(
        'Cooldown ${effect.type.name} (${remainingMs.toStringAsFixed(0)} ms) · ${element.id}#${cooldownKey.behaviorId} (${behavior.triggerScope.name})',
      );
      return;
    }
    debugPrint(
      '[placed_behavior] trigger=${trigger.name} scope=${behavior.triggerScope.name} instance=${element.id} behavior=${cooldownKey.behaviorId} effect=${effect.type.name}',
    );
    var effectApplied = false;
    switch (effect.type) {
      case MapPlacedElementEffectType.showMessage:
        final text = effect.message?.trim() ?? '';
        if (text.isEmpty) {
          debugPrint(
            '[placed_behavior] showMessage ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=empty_message',
          );
          return;
        }
        _showNotification(text);
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.openDialogue:
        effectApplied =
            _tryOpenDialogue(element.id, effect.dialogue, element.elementId);
        break;
      case MapPlacedElementEffectType.setAnimationEnabled:
        final enabled = effect.animationEnabled;
        if (enabled == null) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=missing_value',
          );
          return;
        }
        final currentEnabled = _resolvePlacedElementAnimationEnabled(
          element.id,
        );
        if (currentEnabled == enabled) {
          debugPrint(
            '[placed_behavior] setAnimationEnabled ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_change value=$enabled',
          );
          _updateBehaviorDebugLine(
            'Animation déjà ${enabled ? 'active' : 'inactive'} · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        }
        _applyPlacedElementAnimationEnabled(
          instanceId: element.id,
          enabled: enabled,
        );
        effectApplied = true;
        break;
      case MapPlacedElementEffectType.playAnimationOnce:
        final triggered =
            _playPlacedElementAnimationOnce(instanceId: element.id);
        if (!triggered) {
          debugPrint(
            '[placed_behavior] playAnimationOnce ignored instance=${element.id} behavior=${cooldownKey.behaviorId} reason=no_animatable_frames',
          );
          _updateBehaviorDebugLine(
            'Animation 1x indisponible · ${element.id}#${cooldownKey.behaviorId}',
          );
          return;
        } else {
          debugPrint(
            '[placed_behavior] playAnimationOnce started instance=${element.id} behavior=${cooldownKey.behaviorId} strategy=restart',
          );
        }
        effectApplied = true;
        break;
    }
    if (!effectApplied) {
      return;
    }
    _placedBehaviorCooldownGate.markTriggered(
      key: cooldownKey,
      nowMs: _runtimeClockMs,
      overrideDuration: cooldownOverride,
    );
    _updateBehaviorDebugLine(
      'Triggered ${trigger.name}/${behavior.triggerScope.name} -> ${effect.type.name} · ${element.id}#${cooldownKey.behaviorId}',
    );
  }

  bool _playPlacedElementAnimationOnce({
    required String instanceId,
  }) {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return false;
    }
    final fromBackground =
        loaded.backgroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    final fromForeground =
        loaded.foregroundLayers.playPlacedElementAnimationOnce(
      instanceId: instanceId,
    );
    return fromBackground || fromForeground;
  }

  void _applyPlacedElementAnimationEnabled({
    required String instanceId,
    required bool enabled,
  }) {
    try {
      final updatedMap = setMapPlacedElementAnimationEnabled(
        _world.map,
        instanceId: instanceId,
        enabled: enabled,
      );
      _world = GameplayWorldState.initial(
        map: updatedMap,
        playerPos: _world.player.pos,
        playerFacing: _world.player.facing,
        playerMovementMode: _world.player.movementMode,
        project: _bundle.manifest,
        tileWidth: _bundle.manifest.settings.tileWidth,
        tileHeight: _bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
      );
      _bundle = RuntimeMapBundle(
        manifest: _bundle.manifest,
        map: updatedMap,
        projectRootDirectory: _bundle.projectRootDirectory,
        tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
      );
      final activeLoaded = _loadedMapsById[_activeMapId];
      if (activeLoaded != null) {
        activeLoaded.backgroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        activeLoaded.foregroundLayers.setPlacedElementAnimationEnabledOverride(
          instanceId: instanceId,
          enabled: enabled,
        );
        _loadedMapsById[_activeMapId] = _LoadedPlayableMap(
          bundle: _bundle,
          originCellX: activeLoaded.originCellX,
          originCellY: activeLoaded.originCellY,
          backgroundLayers: activeLoaded.backgroundLayers,
          foregroundLayers: activeLoaded.foregroundLayers,
          npcActors: activeLoaded.npcActors,
          npcActorByEntityId: activeLoaded.npcActorByEntityId,
        );
      }
      debugPrint(
        '[placed_behavior] setAnimationEnabled applied instance=$instanceId enabled=$enabled',
      );
    } catch (e, st) {
      debugPrint(
        '[placed_behavior] setAnimationEnabled failed instance=$instanceId enabled=$enabled error=$e\n$st',
      );
      _showNotification('Animation update failed');
    }
  }

  bool _tryOpenDialogue(
      String entityId, DialogueRef? ref, String fallbackLabel) {
    if (_flowPhase != _RuntimeFlowPhase.overworld) return false;
    if (_dialogueOverlay != null) return false;
    if (!_npcEntityAllowedOnActiveMapForDialogue(entityId)) {
      debugPrint('[dialogue] blocked: npc absent entityId=$entityId');
      return false;
    }

    final resolved = resolveDialogue(
      entityId: entityId,
      ref: ref,
      projectRootDirectory: _bundle.projectRootDirectory,
      dialogues: _bundle.manifest.dialogues,
    );

    if (resolved == null) {
      _showNotification(fallbackLabel);
      return false;
    }

    loadDialogueContent(resolved).then((session) {
      if (_dialogueOverlay != null) return;
      if (session == null) {
        debugPrint('[dialogue] failed to load session for entity=$entityId');
        _showNotification(fallbackLabel);
        return;
      }
      debugPrint('[dialogue] opening dialogue for entity=$entityId');
      _openDialogue(session);
    });
    return true;
  }

  void _openDialogue(DialogueSession session) {
    _notification?.removeFromParent();
    _notification = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
    _flowPhase = _RuntimeFlowPhase.dialogue;

    final overlay = DialogueOverlayComponent(
      session: session,
      viewportSize: camera.viewport.size,
      onFinished: () {
        debugPrint('[dialogue] dialogue closed');
        _dialogueOverlay = null;
        _flowPhase = _RuntimeFlowPhase.overworld;
        _awaitingSurfConfirmation = false;
        final action = _pendingPostDialogueAction;
        _pendingPostDialogueAction = null;
        action?.call();
      },
    );
    camera.viewport.add(overlay);
    _dialogueOverlay = overlay;
    final openedState = session.state;
    if (openedState is DialogueShowingLine) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} text="${openedState.text}"');
    } else if (openedState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] opened node=${session.currentNodeTitle} choice count=${openedState.choices.length}');
    }
  }

  void _advanceDialogue() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.advance();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  void _moveChoiceCursor(int delta) {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    overlay.moveCursor(delta);
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      debugPrint('[dialogue] choice moved selected=${state.selectedIndex}');
    }
  }

  void _confirmDialogueChoice() {
    final overlay = _dialogueOverlay;
    if (overlay == null) return;
    final state = overlay.currentSession.state;
    if (state is DialogueWaitingForChoice) {
      final idx = state.selectedIndex;
      debugPrint(
          '[dialogue] choice confirmed index=$idx text="${state.choices[idx].text}"');
      if (_awaitingSurfConfirmation) {
        if (idx == 0) {
          _pendingPostDialogueAction = () {
            setSurfingEnabled(true);
            debugPrint('[surf] mode activated via dialogue choice');
          };
        }
        _awaitingSurfConfirmation = false;
      }
    }
    final prevNode = overlay.currentSession.currentNodeTitle;
    final stillOpen = overlay.confirmChoice();
    if (!stillOpen) {
      debugPrint('[dialogue] finished');
      return;
    }
    final newNode = overlay.currentSession.currentNodeTitle;
    if (newNode != null && newNode != prevNode) {
      debugPrint('[dialogue] jump to=$newNode');
    }
    final newState = overlay.currentSession.state;
    if (newState is DialogueShowingLine) {
      debugPrint('[dialogue] line text="${newState.text}"');
    } else if (newState is DialogueWaitingForChoice) {
      debugPrint(
          '[dialogue] choice opened count=${newState.choices.length} selected=0');
    }
  }

  /// Garde-fou : tout dialogue / combat PNJ passe par ici ou [_tryOpenDialogue].
  bool _npcEntityAllowedOnActiveMapForDialogue(String entityId) {
    final normalized = entityId.trim();
    if (normalized.isEmpty) {
      return true;
    }
    MapEntity? found;
    for (final e in _world.map.entities) {
      if (e.id == normalized) {
        found = e;
        break;
      }
    }
    if (found == null) {
      return true;
    }
    if (found.kind != MapEntityKind.npc) {
      return true;
    }
    return _npcPresencePredicateFor(_bundle.manifest)(
      _world.map.id,
      found,
    );
  }

  void _handleNpcInteraction(MapEntity entity) {
    if (!_npcPresencePredicateFor(_bundle.manifest)(_world.map.id, entity)) {
      debugPrint('[interact] ignored absent npc=${entity.id}');
      return;
    }
    final trainerId = entity.npc?.trainerId?.trim();

    // Cas 1: pas de trainerId → dialogue normal
    if (trainerId == null || trainerId.isEmpty) {
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 2: trainer déjà battu → defeat dialogue ou fallback
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint(
        '[interact] trainer already defeated trainer=$trainerId npc=${entity.id}',
      );
      _openDefeatDialogue(entity);
      return;
    }

    // Cas 3: trainerId invalide → log + fallback dialogue
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint(
        '[battle] trainer not found: $trainerId for npc=${entity.id}, fallback to dialogue',
      );
      _showNotification('Dresseur introuvable.');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
      return;
    }

    // Cas 4: trainer non battu → battle normal
    // Vérifier aussi _triggeredTrainerBattles pour éviter double déclenchement
    if (_triggeredTrainerBattles.contains(entity.id)) {
      debugPrint(
        '[interact] trainer battle already triggered (LoS lock) trainer=$trainerId npc=${entity.id}',
      );
      // Ne pas déclencher un autre battle, mais ne pas bloquer l'interaction non plus
      // Juste ignorer silencieusement
      return;
    }

    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
        '[battle] trainer battle triggered npc=${entity.id} trainer=$trainerId',
      );
      // Lock ANTI-RETRIGGER avant de déclencher
      _triggeredTrainerBattles.add(entity.id);
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    }
  }

  void _openDefeatDialogue(MapEntity entity) {
    final defeatRef = entity.npc?.defeatDialogueRef;
    if (defeatRef != null) {
      debugPrint('[interact] opening defeat dialogue npc=${entity.id}');
      _tryOpenDialogue(entity.id, defeatRef, entity.inspectorHeadline);
    } else if (_resolveNpcDialogueRef(entity) != null) {
      debugPrint(
          '[interact] no defeat dialogue, fallback to normal dialogue npc=${entity.id}');
      _tryOpenDialogue(
        entity.id,
        _resolveNpcDialogueRef(entity),
        entity.inspectorHeadline,
      );
    } else {
      debugPrint(
          '[interact] no dialogue for defeated trainer npc=${entity.id}');
      _showNotification('Le dresseur est déjà vaincu.');
    }
  }

  /// DEBUG-ONLY: Marque un trainer comme battu.
  ///
  /// **À n'utiliser qu'en debug/dev pour tester le flux de défaite.**
  /// Tant que le gameplay de combat n'est pas implémenté, ce mécanisme
  /// permet de simuler une victoire pour vérifier le defeat dialogue.
  ///
  /// En production, ce flag devrait être positionné automatiquement
  /// après une vraie victoire en combat.
  void debugMarkTrainerAsDefeated(String trainerId) {
    final trimmedId = trainerId.trim();
    if (trimmedId.isEmpty) {
      debugPrint('[debug] invalid trainerId, ignored');
      return;
    }
    _gameState = _storyFlags.markTrainerDefeated(_gameState, trimmedId);
    debugPrint('[debug] trainer $trimmedId marked as defeated');
    _refreshWorldNpcPresence();
  }

  /// Vérifie la Line of Sight (LoS) des trainers et déclenche automatiquement
  /// le battle si le joueur est détecté.
  ///
  /// **Conditions de déclenchement :**
  /// 1. Runtime stable : overworld, pas de dialogue, pas de battle pending
  /// 2. Trainer avec trainerId valide et lineOfSightRange > 0
  /// 3. Trainer non déjà battu (flag trainer_defeated:{id})
  /// 4. Joueur dans la LoS du trainer (checkLineOfSight)
  /// 5. Trainer pas déjà dans _triggeredTrainerBattles (anti-retrigger)
  ///
  /// **Réarmement :**
  /// - Quand le joueur sort de la LoS → lock retirée
  /// - Sur changement de map → toutes les locks retirées
  ///
  /// **Origine du calcul :**
  /// - Depuis entity.pos du NPC
  /// - Axe cardinal uniquement (nord/sud/est/ouest)
  /// - Aucune diagonale
  /// - Obstacles via world.isBlocked() sur les cases STRICTEMENT entre
  ///   le NPC et le joueur (exclut case du NPC et case du joueur)
  void _checkTrainerLineOfSight() {
    // Condition de stabilité runtime stricte
    if (_flowPhase != _RuntimeFlowPhase.overworld) return;
    if (_dialogueOverlay != null) return;
    if (_pendingBattleRequest != null) return;

    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!_npcPresencePredicateFor(_bundle.manifest)(
        _world.map.id,
        entity,
      )) {
        continue;
      }

      final trainerId = entity.npc?.trainerId;
      if (trainerId == null || trainerId.isEmpty) continue;

      final losRange = entity.npc?.lineOfSightRange ?? 0;
      if (losRange <= 0) continue;

      // Vérifier si déjà battu
      if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) continue;

      // Anti-retrigger : ignorer si déjà déclenché dans cette session
      if (_triggeredTrainerBattles.contains(entity.id)) {
        // Réarmement : si joueur sort de LoS, retirer le lock
        final inLoS = checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: losRange,
          playerPos: _world.player.pos,
          world: _world,
        );
        if (!inLoS) {
          _triggeredTrainerBattles.remove(entity.id);
        }
        continue;
      }

      // Check LoS
      final inLoS = checkLineOfSight(
        npcPos: entity.pos,
        npcFacing: entity.npc!.facing,
        lineOfSightRange: losRange,
        playerPos: _world.player.pos,
        world: _world,
      );

      if (inLoS) {
        // Lock anti-retrigger AVANT de déclencher
        _triggeredTrainerBattles.add(entity.id);
        _triggerTrainerBattle(entity);
      }
    }
  }

  /// Déclenche un battle trainer (appelé par interaction manuelle OU LoS auto).
  ///
  /// **Factorisation :** Cette méthode factorise UNIQUEMENT le démarrage du battle.
  /// Elle ne gère PAS :
  /// - La vérification trainer déjà battu (déjà fait par l'appelant)
  /// - Le defeat dialogue (géré par _handleNpcInteraction pour interaction manuelle)
  ///
  /// **Gestion d'erreur :**
  /// - trainerId invalide → log + notification + pas de crash
  /// - Battle request null → log + pas de battle
  void _triggerTrainerBattle(MapEntity entity) {
    final trainerId = entity.npc?.trainerId;
    if (trainerId == null || trainerId.isEmpty) {
      debugPrint('[trainer] no trainerId for entity=${entity.id}');
      return;
    }

    // Vérifier si déjà battu (pour LoS — interaction manuelle a déjà son check)
    if (_storyBranching.isTrainerDefeated(_gameState, trainerId)) {
      debugPrint('[trainer] already defeated trainer=$trainerId');
      return;
    }

    // Vérifier trainer valide
    final trainer =
        _bundle.manifest.trainers.cast<ProjectTrainerEntry?>().firstWhere(
              (t) => t?.id == trainerId,
              orElse: () => null,
            );
    if (trainer == null) {
      debugPrint('[trainer] not found trainer=$trainerId entity=${entity.id}');
      _showNotification('Dresseur introuvable.');
      return;
    }

    // Créer battle request
    final request = buildTrainerBattleRequestFromNpc(
      entity: entity,
      manifest: _bundle.manifest,
      world: _world,
    );
    if (request != null) {
      debugPrint(
          '[trainer] battle triggered trainer=$trainerId entity=${entity.id}');
      // UNIFIED PATTERN: Store in _pendingBattleRequest, let update() consume it
      // This is consistent with wild encounters and allows proper timing
      _pendingBattleRequest = request;
    } else {
      debugPrint(
          '[trainer] battle request failed trainer=$trainerId entity=${entity.id}');
    }
  }

  void _showNotification(String text) {
    _notification?.removeFromParent();
    final paint = TextPaint(
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        backgroundColor: Color(0xAA000000),
      ),
    );
    final component = TextComponent(
      text: text,
      textRenderer: paint,
      anchor: Anchor.topCenter,
    );
    component.position = Vector2(
      camera.viewport.size.x / 2,
      camera.viewport.size.y - 48,
    );
    camera.viewport.add(component);
    _notification = component;
    Future.delayed(const Duration(seconds: 2), () {
      if (_notification == component) {
        component.removeFromParent();
        _notification = null;
      }
    });
  }

  void _handleWaterBlocked() {
    final delta = _runtimeClockMs - _lastWaterRequiresSurfMessageAtMs;
    if (delta < _kWaterRequiresSurfMessageCooldownMs) {
      return;
    }
    _lastWaterRequiresSurfMessageAtMs = _runtimeClockMs;

    final evaluation = evaluateSurfAttempt(
      gameState: _gameState,
      isTargetWater: true,
    );
    final yarnNode = surfEvaluationToYarnNode(evaluation);
    if (yarnNode == null) {
      return;
    }

    final session = loadSurfDialogueSession(yarnNode);
    if (session == null) {
      debugPrint('[surf] failed to load dialogue node=$yarnNode');
      _showNotification(waterRequiresSurfFeedbackMessage);
      return;
    }

    debugPrint(
        '[surf] evaluation=${evaluation.runtimeType} -> dialogue=$yarnNode');

    if (evaluation is CanPromptSurf) {
      _awaitingSurfConfirmation = true;
    }
    _openDialogue(session);
  }

  /// Sauvegarde l'état actuel de la partie.
  ///
  /// Retourne `true` si la sauvegarde a réussi.
  Future<bool> saveGame() async {
    if (isLoaded) {
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
    }
    debugPrint(
      '[step_studio_trace] runtime_save_requested map=$_activeMapId completedStepIds=${_gameState.progression.completedStepIds} completedCutsceneIds=${_gameState.progression.completedCutsceneIds}',
    );
    return _saveGameUseCase.execute(_gameState);
  }

  /// Charge l'état de la partie et resync complètement le runtime.
  ///
  /// Retourne `true` si le chargement a réussi.
  /// Retourne `false` si aucune sauvegarde n'existe ou en cas d'échec.
  ///
  /// Effets de bord :
  /// - Modifie `_gameState`
  /// - Modifie `_activeMapId`
  /// - Recharge la map courante
  /// - Reconstruit `_world` avec la position/facing du joueur
  /// - Resync `_player` avec le nouveau `_world`
  /// - Resync caméra / streaming / bounds
  ///
  /// **Note** : Cette méthode ne restaure pas les overlays actifs (dialogue,
  /// battle transition) ni les états transitoires. Elle restaure uniquement
  /// l'état principal du runtime.
  ///
  /// **Limitation** : La phase destructive (à partir de `_gameState = loadedState`)
  /// n'est pas transactionnelle. En cas d'échec pendant le chargement de la map
  /// ou le remontage des layers, le runtime peut rester dans un état partiellement
  /// modifié. Aucun rollback n'est implémenté dans ce lot. Cette limitation sera
  /// adressée dans un futur lot si nécessaire.
  Future<bool> loadGame() async {
    // 1. Charger loadedState
    final rawLoadedState = await _loadGameUseCase.execute();
    if (rawLoadedState == null) {
      debugPrint('[load] no save found');
      return false;
    }
    final loadedState = normalizeLoadedGameState(rawLoadedState);

    // 2. Charger newBundle (avec error handling)
    RuntimeMapBundle newBundle;
    try {
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: loadedState.currentMapId,
      );
      newBundle = _resolveRuntimeBundle(loadedBundle);
    } catch (e, st) {
      debugPrint('[load] failed to load map: $e\n$st');
      return false;
    }

    // 3. Charger newImages (avec error handling)
    Map<String, ui.Image> newImages;
    try {
      newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
    } catch (e, st) {
      debugPrint('[load] failed to load tileset images: $e\n$st');
      return false;
    }

    // 4-16. Phase destructive (protégée par try/catch)
    try {
      // 4. Restaurer GameState
      _gameState = loadedState;

      // 5. Nettoyer l'état transitoire
      _clearTransientUiState();

      // 6. Unmount anciennes maps
      _unmountAllLoadedMaps();

      // 7. Assigner _bundle = newBundle
      _bundle = newBundle;

      // 8. Monter nouvelle map
      await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );

      // 9. Reconstruire _world
      _world = GameplayWorldState.initial(
        map: newBundle.map,
        project: newBundle.manifest,
        playerPos: loadedState.playerPosition,
        playerFacing: loadedState.playerFacing.asDirection,
        playerMovementMode: loadedState.playerMovementMode,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );

      // 10. Mettre _activeMapId + reset contrôleur PNJ scripté
      _activeMapId = loadedState.currentMapId;
      _resetScriptedNpcMovementController();

      // 10. Resync _player
      _player.setMapOrigin(Vector2(0, 0), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);

      // 11. Synchroniser GameState
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);

      // 12-15. Resync caméra / streaming / bounds
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _applyDebugTileMarker();
      _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
        map: _bundle.map,
        pos: _world.player.pos,
      );

      _refreshWorldNpcPresence();

      debugPrint('[load] game loaded from saveId=${loadedState.saveId}');
      return true;
    } catch (e, st) {
      debugPrint('[load] failed during destructive phase: $e\n$st');
      return false;
    }
  }

  PlacedBehaviorRuntimeKey _buildPlacedBehaviorCooldownKey({
    required MapPlacedElement element,
    required MapPlacedElementBehavior behavior,
    required MapPlacedElementTriggerType trigger,
  }) {
    final trimmedBehaviorId = behavior.id.trim();
    final behaviorId = trimmedBehaviorId.isEmpty ? 'legacy' : trimmedBehaviorId;
    return PlacedBehaviorRuntimeKey(
      instanceId: element.id,
      behaviorId: behaviorId,
      trigger: trigger,
      effectType: behavior.effect.type,
    );
  }

  Duration? _resolvePlacedBehaviorCooldownOverride(
    MapPlacedElementBehavior behavior,
  ) {
    final cooldownMs = behavior.cooldownMs;
    if (cooldownMs == null) {
      return null;
    }
    if (cooldownMs <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: cooldownMs);
  }

  bool _resolvePlacedElementAnimationEnabled(String instanceId) {
    for (final instance in _world.map.placedElements) {
      if (instance.id != instanceId) {
        continue;
      }
      return instance.animation?.enabled ?? false;
    }
    return false;
  }

  void _ensureBehaviorDebugOverlay() {
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    final existing = _behaviorDebugOverlay;
    if (existing != null) {
      existing.text = _lastBehaviorDebugLine;
      return;
    }
    final overlay = TextComponent(
      text: _lastBehaviorDebugLine,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          backgroundColor: Color(0xAA111111),
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 10),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _behaviorDebugOverlay = overlay;
  }

  void _ensureFpsOverlay() {
    if (!_showFpsOverlay) {
      return;
    }
    final existing = _fpsOverlay;
    if (existing != null) {
      existing.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
      return;
    }
    final overlay = TextComponent(
      text: 'FPS ${_currentFps.toStringAsFixed(1)}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 12,
          color: Colors.lightGreenAccent,
          backgroundColor: Color(0xAA111111),
          fontWeight: FontWeight.w600,
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(10, 28),
      priority: 30000,
    );
    camera.viewport.add(overlay);
    _fpsOverlay = overlay;
  }

  void _updateFps(double dt) {
    _fpsAccumulatorSeconds += dt;
    _fpsFrameCount += 1;

    // Fenêtre courte de 250ms: stable sans être trop lente.
    if (_fpsAccumulatorSeconds < 0.25) {
      return;
    }
    _currentFps = _fpsFrameCount / _fpsAccumulatorSeconds;
    _fpsAccumulatorSeconds = 0.0;
    _fpsFrameCount = 0;

    if (_showFpsOverlay) {
      _ensureFpsOverlay();
      _fpsOverlay?.text = 'FPS ${_currentFps.toStringAsFixed(1)}';
    }
  }

  void _updateBehaviorDebugLine(String line) {
    _lastBehaviorDebugLine = line;
    if (!_showBehaviorDebugOverlay) {
      return;
    }
    _ensureBehaviorDebugOverlay();
    final overlay = _behaviorDebugOverlay;
    if (overlay == null) {
      return;
    }
    overlay.text = line;
  }

  Future<void> _handleWarp(TriggeredWarp warp) async {
    if (_flowPhase != _RuntimeFlowPhase.overworld) {
      debugPrint('[warp] ignored: flow=${_flowPhase.name}');
      return;
    }
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    final sourceBundle = _bundle;
    final sourceWorld = _world;
    final sourceMapId = _activeMapId;
    final sourcePos = _world.player.pos;
    final sourceFacing = _world.player.facing;
    WarpTransitionOverlayComponent? overlay;
    var swapCompleted = false;
    try {
      _clearTransientUiState();
      overlay = WarpTransitionOverlayComponent(
        viewportSize: camera.viewport.size,
      );
      camera.viewport.add(overlay);
      _warpTransitionOverlay = overlay;
      debugPrint(
        '[warp] start transition warp=${warp.warpId} map=$sourceMapId -> ${warp.targetMapId} target=(${warp.targetPos.x}, ${warp.targetPos.y})',
      );
      final loadedBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: warp.targetMapId,
      );
      final newBundle = _resolveRuntimeBundle(loadedBundle);
      debugPrint('[warp] target map loaded id=${newBundle.map.id}');
      final transitionSpec = _resolveWarpTransitionSpec(
        sourceMap: sourceBundle.map,
        targetMap: newBundle.map,
      );
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade out durationMs=${transitionSpec.fadeOut.inMilliseconds}',
        );
        await overlay.fadeOut(duration: transitionSpec.fadeOut);
      }
      if (!_isWithinMapBounds(newBundle.map, warp.targetPos)) {
        throw StateError(
          'warp target out of bounds map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y}) size=${newBundle.map.size.width}x${newBundle.map.size.height}',
        );
      }
      final newWorld = GameplayWorldState.initial(
        map: newBundle.map,
        playerPos: warp.targetPos,
        playerFacing: sourceFacing,
        project: newBundle.manifest,
        tileWidth: newBundle.manifest.settings.tileWidth,
        tileHeight: newBundle.manifest.settings.tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(newBundle.manifest),
      );
      if (newWorld.isBlocked(warp.targetPos.x, warp.targetPos.y)) {
        throw StateError(
          'warp target blocked map=${newBundle.map.id} pos=(${warp.targetPos.x}, ${warp.targetPos.y})',
        );
      }
      debugPrint('[warp] loading target map visuals id=${newBundle.map.id}');
      final newImages =
          await loadTilesetImagesById(newBundle.tilesetAbsolutePathsById);
      _unmountAllLoadedMaps();
      final root = await _mountLoadedMap(
        bundle: newBundle,
        tileImagesById: newImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = newBundle;
      _world = newWorld;
      _activeMapId = newBundle.map.id;
      _previousMapId = null;
      _triggeredTrainerBattles.clear(); // Reset LoS locks on map change
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      swapCompleted = true;
      debugPrint(
        '[warp] player placed at map=${newBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      if (transitionSpec.style == _WarpTransitionStyle.fade) {
        debugPrint(
          '[warp] fade in durationMs=${transitionSpec.fadeIn.inMilliseconds}',
        );
        await overlay.fadeIn(duration: transitionSpec.fadeIn);
      }
      debugPrint('[warp] transition completed');
    } catch (e, st) {
      debugPrint('[warp] transition failed: $e\n$st');
      _showNotification('Warp failed');
      if (!swapCompleted) {
        await _recoverFromWarpFailure(
          sourceBundle: sourceBundle,
          sourceWorld: sourceWorld,
          sourceMapId: sourceMapId,
        );
      }
      if (overlay != null) {
        await overlay.fadeIn(duration: const Duration(milliseconds: 140));
      }
    } finally {
      _warpTransitionOverlay?.close();
      _warpTransitionOverlay = null;
      _flowPhase = _RuntimeFlowPhase.overworld;
      debugPrint(
        '[warp] gameplay unlocked map=$_activeMapId pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
      if (swapCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
      if (_activeMapId == sourceMapId &&
          _world.player.pos.x == sourcePos.x &&
          _world.player.pos.y == sourcePos.y) {
        _player.syncState(_world.player, snapToGrid: true);
      }
    }
  }

  _WarpTransitionSpec _resolveWarpTransitionSpec({
    required MapData sourceMap,
    required MapData targetMap,
  }) {
    final sourceIndoor = sourceMap.mapMetadata.isIndoor ||
        sourceMap.mapMetadata.mapType == MapType.building ||
        sourceMap.mapMetadata.mapType == MapType.interior ||
        sourceMap.mapMetadata.mapType == MapType.cave ||
        sourceMap.mapMetadata.mapType == MapType.facility;
    final targetIndoor = targetMap.mapMetadata.isIndoor ||
        targetMap.mapMetadata.mapType == MapType.building ||
        targetMap.mapMetadata.mapType == MapType.interior ||
        targetMap.mapMetadata.mapType == MapType.cave ||
        targetMap.mapMetadata.mapType == MapType.facility;
    final duration = sourceIndoor == targetIndoor
        ? const Duration(milliseconds: 170)
        : const Duration(milliseconds: 230);
    return _WarpTransitionSpec(
      style: _WarpTransitionStyle.fade,
      fadeOut: duration,
      fadeIn: duration,
    );
  }

  Future<void> _recoverFromWarpFailure({
    required RuntimeMapBundle sourceBundle,
    required GameplayWorldState sourceWorld,
    required String sourceMapId,
  }) async {
    if (_loadedMapsById.isNotEmpty && _activeMapId == sourceMapId) {
      _bundle = sourceBundle;
      _world = sourceWorld;
      _syncGameStateFromWorld(mapIdOverride: sourceMapId);
      _player.syncState(_world.player, snapToGrid: true);
      _configureCameraViewport();
      _syncCameraToPlayer();
      debugPrint('[warp] rollback no-op (source map still mounted)');
      return;
    }

    try {
      _unmountAllLoadedMaps();
      final loadedFallbackBundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: sourceMapId,
      );
      final fallbackBundle = _resolveRuntimeBundle(loadedFallbackBundle);
      final fallbackWorld = _buildSafeWorldState(
        map: fallbackBundle.map,
        project: fallbackBundle.manifest,
        preferredPos: sourceWorld.player.pos,
        fallbackFacing: sourceWorld.player.facing,
        tileWidth: fallbackBundle.manifest.settings.tileWidth,
        tileHeight: fallbackBundle.manifest.settings.tileHeight,
      );
      final fallbackImages =
          await loadTilesetImagesById(fallbackBundle.tilesetAbsolutePathsById);
      final root = await _mountLoadedMap(
        bundle: fallbackBundle,
        tileImagesById: fallbackImages,
        originCellX: 0,
        originCellY: 0,
      );
      _bundle = fallbackBundle;
      _world = fallbackWorld;
      _activeMapId = fallbackBundle.map.id;
      _previousMapId = null;
      _resetScriptedNpcMovementController();
      _player.setMapOrigin(_originPixelsOf(root), snapToGrid: false);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      _configureCameraViewport();
      _syncCameraToPlayer();
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      debugPrint(
        '[warp] rollback restored map=${fallbackBundle.map.id} pos=(${_world.player.pos.x}, ${_world.player.pos.y})',
      );
    } catch (e, st) {
      debugPrint('[warp] rollback failed: $e\n$st');
    }
  }

  GameplayWorldState _buildSafeWorldState({
    required MapData map,
    required ProjectManifest project,
    required GridPos preferredPos,
    required Direction fallbackFacing,
    required int tileWidth,
    required int tileHeight,
  }) {
    final safePos = _isWithinMapBounds(map, preferredPos)
        ? preferredPos
        : const GridPos(x: 0, y: 0);
    final world = GameplayWorldState.initial(
      map: map,
      playerPos: safePos,
      playerFacing: fallbackFacing,
      project: project,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(project),
    );
    if (!world.isBlocked(safePos.x, safePos.y)) {
      return world;
    }

    try {
      final spawn = resolveInitialPlayerSpawn(map);
      final spawnWorld = GameplayWorldState.initial(
        map: map,
        playerPos: spawn.pos,
        playerFacing: fallbackFacing,
        project: project,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        npcMapPresencePredicate: _npcPresencePredicateFor(project),
      );
      if (!spawnWorld.isBlocked(spawn.pos.x, spawn.pos.y)) {
        return spawnWorld;
      }
    } catch (_) {}

    for (var y = 0; y < map.size.height; y++) {
      for (var x = 0; x < map.size.width; x++) {
        if (!world.isBlocked(x, y)) {
          return GameplayWorldState.initial(
            map: map,
            playerPos: GridPos(x: x, y: y),
            playerFacing: fallbackFacing,
            project: project,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            npcMapPresencePredicate: _npcPresencePredicateFor(project),
          );
        }
      }
    }

    return world;
  }

  bool _isWithinMapBounds(MapData map, GridPos pos) {
    return pos.x >= 0 &&
        pos.y >= 0 &&
        pos.x < map.size.width &&
        pos.y < map.size.height;
  }

  Future<void> _handleConnection(TriggeredConnection connection) async {
    _flowPhase = _RuntimeFlowPhase.mapTransition;
    var transitionCompleted = false;
    try {
      _clearTransientUiState();
      debugPrint(
        '[connection] attempting map=${_bundle.map.id} direction=${connection.direction.name} target=${connection.targetMapId} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y})',
      );
      final source = _loadedMapsById[_activeMapId];
      if (source == null) {
        debugPrint(
            '[connection] source map visuals missing for id=$_activeMapId');
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      final target = await _ensureConnectionTargetLoaded(
        source: source,
        connection: connection,
      );
      if (target == null) {
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection failed');
        return;
      }
      debugPrint('[connection] resolved target map=${target.bundle.map.id}');
      final targetPos = resolveConnectedMapTargetPos(
        sourcePos: connection.sourcePos,
        sourceSize: source.bundle.map.size,
        targetSize: target.bundle.map.size,
        direction: connection.direction,
        offset: connection.offset,
      );
      if (targetPos == null) {
        debugPrint(
          '[connection] invalid entry coordinates direction=${connection.direction.name} offset=${connection.offset} source=(${connection.sourcePos.x}, ${connection.sourcePos.y}) sourceSize=${source.bundle.map.size.width}x${source.bundle.map.size.height} targetSize=${target.bundle.map.size.width}x${target.bundle.map.size.height}',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection invalid');
        return;
      }
      debugPrint(
        '[connection] computed entry pos=(${targetPos.x}, ${targetPos.y})',
      );
      final newWorld = GameplayWorldState.initial(
        map: target.bundle.map,
        playerPos: targetPos,
        playerFacing: _world.player.facing,
        project: target.bundle.manifest,
        tileWidth: target.bundle.manifest.settings.tileWidth,
        tileHeight: target.bundle.manifest.settings.tileHeight,
        npcMapPresencePredicate:
            _npcPresencePredicateFor(target.bundle.manifest),
      );
      if (newWorld.isBlocked(targetPos.x, targetPos.y)) {
        debugPrint(
          '[connection] blocked entry map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
        );
        _player.syncState(_world.player, snapToGrid: true);
        _showNotification('Connection blocked');
        return;
      }
      _bundle = target.bundle;
      _world = newWorld;
      _previousMapId = _activeMapId;
      _activeMapId = target.bundle.map.id;
      _resetScriptedNpcMovementController();
      _syncGameStateFromWorld(mapIdOverride: _activeMapId);
      final fromPx = _player.position.clone();
      final targetOriginPx = _originPixelsOf(target);
      final toPx = Vector2(
        targetOriginPx.x + targetPos.x * _cellWidth,
        targetOriginPx.y + targetPos.y * _cellHeight,
      );
      debugPrint(
        '[connection] player step pixels from=(${fromPx.x.toStringAsFixed(1)}, ${fromPx.y.toStringAsFixed(1)}) to=(${toPx.x.toStringAsFixed(1)}, ${toPx.y.toStringAsFixed(1)})',
      );
      _player.setMapOrigin(targetOriginPx, snapToGrid: false);
      _player.startStep(
        _world.player,
        durationSeconds: PlayerComponent.kDefaultStepSeconds,
      );
      _configureCameraViewport();
      final visibleSize = camera.viewfinder.visibleGameSize;
      debugPrint(
        '[connection] camera after transition focus=(${_player.focusPoint.x.toStringAsFixed(1)}, ${_player.focusPoint.y.toStringAsFixed(1)}) viewport=(${(visibleSize?.x ?? 0).toStringAsFixed(1)}, ${(visibleSize?.y ?? 0).toStringAsFixed(1)})',
      );
      debugPrint(
        '[connection] transition complete -> map=${target.bundle.map.id} pos=(${targetPos.x}, ${targetPos.y})',
      );
      _preloadActiveMapConnections();
      _pruneLoadedMapsToActiveNeighborhood();
      _refreshWorldNpcPresence();
      transitionCompleted = true;
    } catch (e, st) {
      debugPrint('[connection] transition failed: $e\n$st');
      _player.syncState(_world.player, snapToGrid: true);
      _showNotification('Connection failed');
    } finally {
      _flowPhase = _RuntimeFlowPhase.overworld;
      if (transitionCompleted) {
        _activeScenarioTriggerIds = _scenarioRuntime.triggerIdsAtPosition(
          map: _bundle.map,
          pos: _world.player.pos,
        );
        _dispatchScenarioRuntimeSource(
          ScenarioRuntimeSourceEvent.mapEnter(mapId: _activeMapId),
        );
      }
    }
  }

  void _clearTransientUiState() {
    _pendingWarp = null;
    _pendingConnection = null;
    // CRITICAL: Do NOT clear _pendingBattleRequest if a battle is active!
    // This would cancel a pending wild encounter battle.
    // Only clear if we're in overworld phase (no battle in progress).
    if (_flowPhase == _RuntimeFlowPhase.overworld) {
      _pendingBattleRequest = null;
    }
    _pendingPlacedElementBehavior = null;
    _notification?.removeFromParent();
    _notification = null;
    _dialogueOverlay?.removeFromParent();
    _dialogueOverlay = null;
    _battleTransitionOverlay?.removeFromParent();
    _battleTransitionOverlay = null;
    _battleOverlay?.removeFromParent();
    _battleOverlay = null;
    // Blindage défensif lot 10 :
    // ce reset central est utilisé par plusieurs chemins runtime (load, warp,
    // connection). Si un contexte battle survivait ici, on garderait en
    // mémoire un slot party et une requête de combat qui ne correspondent plus
    // à l'état overworld courant. On l'efface donc explicitement avec le reste
    // de l'UI transitoire.
    _activeBattleContext = null;
    _warpTransitionOverlay?.removeFromParent();
    _warpTransitionOverlay = null;
    _pressedKeys.clear();
    _lastMoveKey = null;
  }

  void _unmountAllLoadedMaps() {
    final ids = _loadedMapsById.keys.toList(growable: false);
    for (final id in ids) {
      _unmountLoadedMap(id);
    }
    _loadedMapsById.clear();
    _loadMapFutureById.clear();
  }

  void _applyDebugTileMarker() {
    _debugTileMarkerFill?.removeFromParent();
    _debugTileMarkerFill = null;
    _debugTileMarkerBorder?.removeFromParent();
    _debugTileMarkerBorder = null;
    _debugTileMarkerText?.removeFromParent();
    _debugTileMarkerText = null;

    final pos = _debugTileMarkerPos;
    if (pos == null) {
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return;
    }
    final origin = _originPixelsOf(loaded);
    final x = origin.x + pos.x * _cellWidth;
    final y = origin.y + pos.y * _cellHeight;
    final size = Vector2(_cellWidth, _cellHeight);

    final fill = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()..color = const ui.Color(0x66FF9800),
      priority: 150000,
    );
    final border = RectangleComponent(
      position: Vector2(x, y),
      size: size,
      paint: ui.Paint()
        ..color = const ui.Color(0xFFFF6D00)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2,
      priority: 150001,
    );
    world.add(fill);
    world.add(border);
    _debugTileMarkerFill = fill;
    _debugTileMarkerBorder = border;

    final label = _debugTileMarkerLabel?.trim();
    if (label == null || label.isEmpty) {
      return;
    }
    final text = TextComponent(
      text: label,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(x + 2, y + 2),
      priority: 150002,
    );
    world.add(text);
    _debugTileMarkerText = text;
  }

  void _clearNpcCollisionDebugOverlay() {
    final ids = _npcCollisionDebugByEntityId.keys.toList(growable: false);
    for (final id in ids) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _syncNpcCollisionDebugOverlay() {
    if (!_showNpcCollisionDebugOverlay) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      _clearNpcCollisionDebugOverlay();
      return;
    }
    final origin = _originPixelsOf(loaded);
    final seen = <String>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      final actor = loaded.npcActorByEntityId[entity.id];
      if (actor == null) {
        continue;
      }
      seen.add(entity.id);
      final visual = _npcCollisionDebugByEntityId.putIfAbsent(entity.id, () {
        final spriteRect = RectangleComponent(
          priority: 200000,
          paint: ui.Paint()
            ..color = const ui.Color(0xAA00E5FF)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final collisionRect = RectangleComponent(
          priority: 200001,
          paint: ui.Paint()
            ..color = const ui.Color(0xAAFF1744)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final anchorMarker = CircleComponent(
          radius: 3.0,
          priority: 200002,
          paint: ui.Paint()..color = const ui.Color(0xFFFFEA00),
        );
        world.add(spriteRect);
        world.add(collisionRect);
        world.add(anchorMarker);
        return _NpcCollisionDebugVisual(
          spriteRect: spriteRect,
          collisionRect: collisionRect,
          anchorMarker: anchorMarker,
        );
      });

      // 1) Bounding box visuelle réelle du sprite.
      visual.spriteRect
        ..position = actor.position.clone()
        ..size = actor.size.clone();

      // 2) Footprint collision gameplay (grille -> pixels).
      final footprint = resolveEntityCollisionFootprint(entity);
      visual.collisionRect
        ..position = Vector2(
          origin.x + footprint.pos.x * _cellWidth,
          origin.y + footprint.pos.y * _cellHeight,
        )
        ..size = Vector2(
          footprint.size.width * _cellWidth,
          footprint.size.height * _cellHeight,
        );

      // 3) Point d'ancrage logique MapEntity.pos (top-left cellule logique).
      visual.anchorMarker.position = Vector2(
        origin.x + entity.pos.x * _cellWidth + (_cellWidth / 2) - 3,
        origin.y + entity.pos.y * _cellHeight + (_cellHeight / 2) - 3,
      );
    }

    final stale = _npcCollisionDebugByEntityId.keys
        .where((id) => !seen.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      final visual = _npcCollisionDebugByEntityId.remove(id);
      visual?.spriteRect.removeFromParent();
      visual?.collisionRect.removeFromParent();
      visual?.anchorMarker.removeFromParent();
    }
  }

  void _unmountLoadedMap(String mapId) {
    _clearNpcCollisionDebugOverlay();
    final loaded = _loadedMapsById.remove(mapId);
    if (loaded == null) {
      return;
    }
    loaded.backgroundLayers.removeFromParent();
    loaded.foregroundLayers.removeFromParent();
    for (final actor in loaded.npcActors) {
      actor.removeFromParent();
      _npcActors.remove(actor);
    }
  }

  Future<_LoadedPlayableMap> _mountLoadedMap({
    required RuntimeMapBundle bundle,
    required Map<String, ui.Image> tileImagesById,
    required int originCellX,
    required int originCellY,
  }) async {
    final npcPred = _npcPresencePredicateFor(bundle.manifest);
    final backgroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      showCollisionOverlay: _showCollisionOverlay,
      npcMapPresencePredicate: npcPred,
    );
    backgroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    backgroundLayers.priority = 0;
    await world.add(backgroundLayers);

    final foregroundLayers = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: tileImagesById,
      renderPass: MapLayerRenderPass.foreground,
      showCollisionOverlay: false,
      npcMapPresencePredicate: npcPred,
    );
    foregroundLayers.position = _originPixels(
      originCellX: originCellX,
      originCellY: originCellY,
    );
    foregroundLayers.priority = 100000;
    await world.add(foregroundLayers);

    final npcActors = <OverworldActorComponent>[];
    final npcActorByEntityId = <String, OverworldActorComponent>{};
    final charById = {for (final c in bundle.manifest.characters) c.id: c};
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final originPx =
        _originPixels(originCellX: originCellX, originCellY: originCellY);
    for (final entity in bundle.map.entities) {
      if (entity.kind != MapEntityKind.npc) continue;
      if (!npcPred(bundle.map.id, entity)) {
        // Pas de création d'acteur si la règle runtime dit "absent".
        debugPrint(
          '[step_studio_trace] npc_mount_skipped map=${bundle.map.id} entity=${entity.id} reason=presence_predicate_false',
        );
        continue;
      }
      final charId = resolveNpcCharacterId(entity, bundle.manifest);
      if (charId == null || charId.isEmpty) continue;
      final char = charById[charId];
      if (char == null) continue;
      final actor = OverworldActorComponent(
        character: char,
        tileImages: tileImagesById,
        tileWidth: bundle.manifest.settings.tileWidth,
        tileHeight: bundle.manifest.settings.tileHeight,
        cellWidth: cw,
        cellHeight: ch,
        facing: entity.npc?.facing ?? EntityFacing.south,
      );
      actor.configureGridPlacement(
        pos: entity.pos,
        footprint: entity.size,
        mapOrigin: originPx,
        snapToGrid: true,
      );
      npcActors.add(actor);
      npcActorByEntityId[entity.id] = actor;
      _npcActors.add(actor);
      await world.add(actor);
      debugPrint(
        '[step_studio_trace] npc_mount_added map=${bundle.map.id} entity=${entity.id}',
      );
    }

    final loaded = _LoadedPlayableMap(
      bundle: bundle,
      originCellX: originCellX,
      originCellY: originCellY,
      backgroundLayers: backgroundLayers,
      foregroundLayers: foregroundLayers,
      npcActors: npcActors,
      npcActorByEntityId: npcActorByEntityId,
    );
    _loadedMapsById[bundle.map.id] = loaded;
    _applyNpcVisibilityToLoadedMap(loaded);
    return loaded;
  }

  Future<_LoadedPlayableMap?> _ensureConnectionTargetLoaded({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
  }) async {
    final targetMapId = connection.targetMapId;
    final existing = _loadedMapsById[targetMapId];
    if (existing != null) {
      final expected = _computeConnectedOriginCells(
        source: source,
        connection: connection,
        targetSize: existing.bundle.map.size,
      );
      if (expected.x != existing.originCellX ||
          expected.y != existing.originCellY) {
        debugPrint(
          '[connection] origin mismatch target=$targetMapId existing=(${existing.originCellX}, ${existing.originCellY}) expected=(${expected.x}, ${expected.y})',
        );
      }
      return existing;
    }
    final inFlight = _loadMapFutureById[targetMapId];
    if (inFlight != null) {
      return await inFlight;
    }

    Future<_LoadedPlayableMap?> load() async {
      try {
        final loadedBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFilePath,
          mapId: targetMapId,
        );
        final bundle = _resolveRuntimeBundle(loadedBundle);
        final origin = _computeConnectedOriginCells(
          source: source,
          connection: connection,
          targetSize: bundle.map.size,
        );
        final images =
            await loadTilesetImagesById(bundle.tilesetAbsolutePathsById);
        final loaded = await _mountLoadedMap(
          bundle: bundle,
          tileImagesById: images,
          originCellX: origin.x,
          originCellY: origin.y,
        );
        debugPrint(
          '[connection] loaded map=${bundle.map.id} origin=(${origin.x}, ${origin.y})',
        );
        return loaded;
      } catch (e, st) {
        debugPrint(
            '[connection] load failed target=$targetMapId error=$e\n$st');
        return null;
      }
    }

    final future = load();
    _loadMapFutureById[targetMapId] = future;
    try {
      return await future;
    } finally {
      final current = _loadMapFutureById[targetMapId];
      if (identical(current, future)) {
        _loadMapFutureById.remove(targetMapId);
      }
    }
  }

  _GridCellPos _computeConnectedOriginCells({
    required _LoadedPlayableMap source,
    required TriggeredConnection connection,
    required GridSize targetSize,
  }) {
    return switch (connection.direction) {
      MapConnectionDirection.east => _GridCellPos(
          x: source.originCellX + source.bundle.map.size.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.west => _GridCellPos(
          x: source.originCellX - targetSize.width,
          y: source.originCellY + connection.offset,
        ),
      MapConnectionDirection.north => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY - targetSize.height,
        ),
      MapConnectionDirection.south => _GridCellPos(
          x: source.originCellX + connection.offset,
          y: source.originCellY + source.bundle.map.size.height,
        ),
    };
  }

  void _preloadActiveMapConnections() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    for (final connection in active.bundle.map.connections) {
      _ensureConnectionTargetLoaded(
        source: active,
        connection: TriggeredConnection(
          direction: connection.direction,
          targetMapId: connection.targetMapId,
          offset: connection.offset,
          sourcePos: _world.player.pos,
        ),
      );
    }
  }

  void _pruneLoadedMapsToActiveNeighborhood() {
    final active = _loadedMapsById[_activeMapId];
    if (active == null) {
      return;
    }
    final keep = <String>{
      active.bundle.map.id,
      ...active.bundle.map.connections.map((c) => c.targetMapId),
    };
    final previousMapId = _previousMapId;
    if (previousMapId != null && previousMapId.isNotEmpty) {
      keep.add(previousMapId);
    }
    final toRemove = _loadedMapsById.keys
        .where((id) => !keep.contains(id))
        .toList(growable: false);
    for (final id in toRemove) {
      _unmountLoadedMap(id);
    }
  }

  Vector2 _originPixels({
    required int originCellX,
    required int originCellY,
  }) {
    return Vector2(originCellX * _cellWidth, originCellY * _cellHeight);
  }

  Vector2 _originPixelsOf(_LoadedPlayableMap map) {
    return _originPixels(
      originCellX: map.originCellX,
      originCellY: map.originCellY,
    );
  }

  ProjectCharacterEntry? _resolvePlayerCharacter(RuntimeMapBundle bundle) {
    return resolveDefaultPlayerCharacter(bundle.manifest);
  }

  void _faceNpcTowardPlayer(String entityId) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return;
    }
    final playerFacing = _world.player.facing;
    final npcFacing = switch (playerFacing) {
      Direction.north => EntityFacing.south,
      Direction.south => EntityFacing.north,
      Direction.east => EntityFacing.west,
      Direction.west => EntityFacing.east,
    };
    actor.setMotion(npcFacing, CharacterAnimationState.idle);
  }

  /// Construit le runner cutscene MVP avec callbacks runtime concrets.
  ///
  /// Le runner reste découplé de Flame; `PlayableMapGame` lui injecte juste
  /// les opérations nécessaires.
  CutsceneRuntimeRunner _buildCutsceneRuntimeRunner() {
    return CutsceneRuntimeRunner(
      context: CutsceneRuntimeContext(
        openDialogue: (dialogueId, {startNode}) {
          return _openScenarioDialogueById(
            dialogueId,
            startNode: startNode,
            runtimeSourceId: 'cutscene',
          );
        },
        isDialogueOpen: () => _dialogueOverlay != null,
        requestChoice: (request) {
          _pendingCutsceneChoiceRequest = request;
          return true;
        },
        resolveCutsceneById: _findRuntimeCutsceneById,
        moveNpcTo: ({required entityId, required destination}) {
          return startScriptedNpcMove(
            entityId: entityId,
            destination: destination,
          );
        },
        readNpcMovementStatus: (entityId) {
          return scriptedNpcMovementStatus(entityId);
        },
        faceNpc: ({required entityId, required facing}) {
          return _setNpcFacing(entityId, facing);
        },
        emitOutcome: (outcomeId) {
          _emitCutsceneOutcome(outcomeId);
        },
        setFlag: (flagName) {
          _gameState = _storyFlags.set(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        clearFlag: (flagName) {
          _gameState = _storyFlags.clear(_gameState, flagName);
          _refreshWorldNpcPresence();
        },
        isFlagSet: (flagName) => _storyFlags.isSet(_gameState, flagName),
        isOutcomeSet: (outcomeId) =>
            _storyFlags.isSet(_gameState, scenarioOutcomeFlagName(outcomeId)),
      ),
    );
  }

  RuntimeCutsceneAsset? _findRuntimeCutsceneById(String cutsceneId) {
    final normalized = cutsceneId.trim();
    if (normalized.isEmpty) {
      return null;
    }
    for (final candidate in runtimeCutscenes) {
      if (candidate.id == normalized) {
        return candidate;
      }
    }
    return null;
  }

  /// Oriente explicitement un PNJ (étape `faceNpc` de cutscene).
  ///
  /// On met à jour:
  /// - l'acteur visuel (immédiat),
  /// - la map runtime en mémoire (facing npc), pour rester cohérent avec les
  ///   futures logiques gameplay lisant l'orientation d'entité.
  bool _setNpcFacing(String entityId, EntityFacing facing) {
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    actor.setMotion(facing, CharacterAnimationState.idle);

    final entities = _world.map.entities;
    final index = entities.indexWhere((entity) => entity.id == entityId);
    if (index < 0) {
      return true;
    }
    final entity = entities[index];
    final npc = entity.npc;
    if (npc == null) {
      return true;
    }
    final updatedEntities = List<MapEntity>.from(entities);
    updatedEntities[index] = entity.copyWith(
      npc: npc.copyWith(facing: facing),
    );
    final updatedMap = _world.map.copyWith(entities: updatedEntities);
    _world = GameplayWorldState.initial(
      map: updatedMap,
      playerPos: _world.player.pos,
      playerFacing: _world.player.facing,
      playerMovementMode: _world.player.movementMode,
      project: _bundle.manifest,
      tileWidth: _bundle.manifest.settings.tileWidth,
      tileHeight: _bundle.manifest.settings.tileHeight,
      npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
    );
    _bundle = RuntimeMapBundle(
      manifest: _bundle.manifest,
      map: updatedMap,
      projectRootDirectory: _bundle.projectRootDirectory,
      tilesetAbsolutePathsById: _bundle.tilesetAbsolutePathsById,
    );
    return true;
  }

  /// Émet un outcome depuis une cutscene.
  ///
  /// MVP:
  /// 1) on persiste l'outcome comme flag `scenario.outcome.*`,
  /// 2) on tente une transition vers un scénario global via `sourceOutcome`.
  void _emitCutsceneOutcome(String outcomeId) {
    final normalized = outcomeId.trim();
    if (normalized.isEmpty) {
      return;
    }
    _gameState =
        _storyFlags.set(_gameState, scenarioOutcomeFlagName(normalized));
    _refreshWorldNpcPresence();
    _dispatchScenarioRuntimeSource(
      ScenarioRuntimeSourceEvent.outcomeReceived(
        outcomeId: normalized,
      ),
    );
  }

  /// (Re)crée le contrôleur de déplacement scripté pour la map active.
  ///
  /// Cette méthode est appelée:
  /// - au chargement initial,
  /// - après warp/connection/load game (changement de map).
  ///
  /// On repart à chaque fois d'un snapshot propre des PNJ actifs pour éviter
  /// toute dérive d'état entre maps.
  void _resetScriptedNpcMovementController() {
    _runtimeNpcPositions
      ..clear()
      ..addAll(_collectCurrentNpcPositions());
    _runtimeNpcPositions['player'] = _world.player.pos;
    _scriptedNpcReservedOccupiedCellsByEntity.clear();

    final controller = ScriptedEntityMovementController(
      mapSize: _world.map.size,
      isCellBlocked: _isNpcCellBlockedForRoutePlanning,
      startEntityStep: _startScriptedNpcStep,
      isEntityStepping: _isScriptedNpcStepping,
      onEntityPositionCommitted: _commitScriptedNpcPosition,
      validateEntityStep: _validateScriptedNpcStepRuntimeCollision,
    );
    controller.replaceTrackedEntities(_runtimeNpcPositions);
    _scriptedEntityMovementController = controller;
    _applyNpcOverworldDefaultMovement();
  }

  void _applyNpcOverworldDefaultMovement() {
    final controller = _scriptedEntityMovementController;
    if (controller == null) {
      return;
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        controller.stopPatrol(entity.id);
        continue;
      }
      final route = resolveNpcDefaultPatrolRoute(entity);
      if (route == null) {
        controller.stopPatrol(entity.id);
        continue;
      }
      controller.startPatrol(route);
    }
  }

  Map<String, GridPos> _collectCurrentNpcPositions() {
    final loaded = _loadedMapsById[_activeMapId];
    if (loaded == null) {
      return const <String, GridPos>{};
    }
    final pred = _npcPresencePredicateFor(_bundle.manifest);
    final mapId = _world.map.id;
    final byId = <String, GridPos>{};
    for (final entity in _world.map.entities) {
      if (entity.kind != MapEntityKind.npc) {
        continue;
      }
      if (!pred(mapId, entity)) {
        continue;
      }
      // On ne suit que les PNJ présents **et** encore montés en acteur.
      if (!loaded.npcActorByEntityId.containsKey(entity.id)) {
        continue;
      }
      byId[entity.id] = entity.pos;
    }
    return byId;
  }

  bool _isNpcCellBlockedForRoutePlanning(
    int x,
    int y, {
    String? ignoreEntityId,
  }) {
    final normalizedIgnore = ignoreEntityId?.trim();
    if (normalizedIgnore == null || normalizedIgnore.isEmpty) {
      return _world.isBlocked(x, y);
    }
    if (normalizedIgnore == 'player') {
      final mode = _world.player.movementMode;
      if (_world.movementBlockReasonAt(
            x: x,
            y: y,
            movementMode: mode,
          ) !=
          null) {
        return true;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == x && cell.y == y) {
          return true;
        }
      }
      return false;
    }

    // Pathfinding anchor validation:
    // - `x,y` est la position logique MapEntity.pos (top-left),
    // - on valide le footprint collision réel (important pour NPC 2x2),
    // - on ignore l'auto-collision de l'entité courante.
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: normalizedIgnore,
      anchorPos: GridPos(x: x, y: y),
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: normalizedIgnore,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] blocked anchor entity=$normalizedIgnore anchor=($x,$y) reason="${probe.reason}" footprint=${probe.evaluatedCollisionCells.map((c) => '(${c.x},${c.y})').join(',')}',
      );
    }
    return !probe.passable;
  }

  String? _validateScriptedNpcStepRuntimeCollision({
    required String entityId,
    required GridPos from,
    required GridPos to,
  }) {
    if (entityId.trim() == 'player') {
      final mode = _world.player.movementMode;
      final block = _world.movementBlockReasonAt(
        x: to.x,
        y: to.y,
        movementMode: mode,
      );
      if (block != null) {
        debugPrint(
          '[npc_patrol] runtime step rejected entity=player from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason=${block.name}',
        );
        return block.name;
      }
      for (final cell
          in _scriptedNpcDynamicBlockedCells(ignoreEntityId: 'player')) {
        if (cell.x == to.x && cell.y == to.y) {
          debugPrint(
            '[npc_patrol] runtime step rejected entity=player to=(${to.x},${to.y}) reason=dynamic_blocker',
          );
          return 'Dynamic blocker at destination.';
        }
      }
      return null;
    }
    final probe = evaluateScriptedNpcAnchorPassability(
      world: _world,
      entityId: entityId,
      anchorPos: to,
      movementMode: MovementMode.walk,
      dynamicBlockedCells: _scriptedNpcDynamicBlockedCells(
        ignoreEntityId: entityId,
      ),
    );
    if (!probe.passable) {
      debugPrint(
        '[npc_patrol] runtime step rejected entity=$entityId from=(${from.x},${from.y}) to=(${to.x},${to.y}) reason="${probe.reason}"',
      );
      return probe.reason;
    }
    return null;
  }

  /// Cellules dynamiques à bloquer pour un pas NPC scripté.
  ///
  /// Frontière conceptuelle:
  /// - collision "statique" (layers + entités map) => via GameplayWorldState;
  /// - collision "dynamique" hors map entities (joueur) => injectée ici.
  ///
  /// On inclut volontairement:
  /// 1) la cellule logique canonique du joueur (`_world.player.pos`);
  /// 2) la cellule visuelle actuelle au niveau des pieds du player pendant
  ///    l'interpolation de pas.
  ///
  /// Le point (2) évite les traversées visuelles quand la simulation logique a
  /// déjà commité un déplacement joueur mais que le sprite est encore en train
  /// d'animer son pas.
  Iterable<GridPos> _scriptedNpcDynamicBlockedCells({
    String? ignoreEntityId,
  }) sync* {
    final activeFollowLeader = _pendingScenarioFollowRequest?.leaderEntityId;
    final ignorePlayerForLeader = activeFollowLeader != null &&
        ignoreEntityId != null &&
        ignoreEntityId == activeFollowLeader;

    if (!ignorePlayerForLeader) {
      final canonical = _world.player.pos;
      yield canonical;

      final rendered = _renderedPlayerFootGridCell();
      if (rendered != null &&
          (rendered.x != canonical.x || rendered.y != canonical.y)) {
        yield rendered;
      }
    }

    // Réservations de destination des autres PNJ en cours de pas.
    for (final entry in _scriptedNpcReservedOccupiedCellsByEntity.entries) {
      if (ignoreEntityId != null && entry.key == ignoreEntityId) {
        continue;
      }
      yield* entry.value;
    }
  }

  GridPos? _renderedPlayerFootGridCell() {
    final origin = _player.mapOrigin;
    if (_cellWidth <= 0 || _cellHeight <= 0) {
      return null;
    }
    final foot = _player.footPoint;
    final cellX = ((foot.x - origin.x) / _cellWidth).floor();
    final cellY = ((foot.y - 1 - origin.y) / _cellHeight).floor();
    if (cellX < 0 ||
        cellY < 0 ||
        cellX >= _world.map.size.width ||
        cellY >= _world.map.size.height) {
      return null;
    }
    return GridPos(x: cellX, y: cellY);
  }

  bool _startScriptedNpcStep({
    required String entityId,
    required GridPos from,
    required GridPos to,
    required EntityFacing facing,
    double? durationSeconds,
  }) {
    if (entityId.trim() == 'player') {
      final walkFacing = _directionFromEntityFacing(facing);
      final nextState = _world.player.copyWith(pos: to, facing: walkFacing);
      _player.startStep(
        nextState,
        durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
      );
      _reserveScriptedNpcStepOccupiedCells(
        entityId: entityId,
        fromAnchorPos: from,
        toAnchorPos: to,
      );
      return true;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    if (actor == null) {
      return false;
    }
    final started = actor.startGridStep(
      to: to,
      facing: facing,
      durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
    );
    if (!started) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return false;
    }
    _reserveScriptedNpcStepOccupiedCells(
      entityId: entityId,
      fromAnchorPos: from,
      toAnchorPos: to,
    );
    return true;
  }

  bool _isScriptedNpcStepping(String entityId) {
    if (entityId.trim() == 'player') {
      return _player.isStepping;
    }
    final loaded = _loadedMapsById[_activeMapId];
    final actor = loaded?.npcActorByEntityId[entityId];
    return actor?.isStepping ?? false;
  }

  void _commitScriptedNpcPosition(String entityId, GridPos position) {
    if (entityId.trim() == 'player') {
      final from = _world.player.pos;
      final facing = _directionBetweenAdjacent(from: from, to: position) ??
          _world.player.facing;
      _world = _world.withPlayer(
        _world.player.copyWith(pos: position, facing: facing),
      );
      _runtimeNpcPositions['player'] = position;
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      _player.syncState(_world.player, snapToGrid: true);
      _syncGameStateFromWorld();
      return;
    }
    _runtimeNpcPositions[entityId] = position;
    _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
    _world = _world.withEntityPosition(entityId, position);
  }

  bool _isCellReservedByScriptedNpc(GridPos cell) {
    for (final cells in _scriptedNpcReservedOccupiedCellsByEntity.values) {
      if (cells.contains(cell)) {
        return true;
      }
    }
    return false;
  }

  void _reserveScriptedNpcStepOccupiedCells({
    required String entityId,
    required GridPos fromAnchorPos,
    required GridPos toAnchorPos,
  }) {
    if (entityId.trim() == 'player') {
      _scriptedNpcReservedOccupiedCellsByEntity[entityId] = <GridPos>{
        GridPos(x: fromAnchorPos.x, y: fromAnchorPos.y),
        GridPos(x: toAnchorPos.x, y: toAnchorPos.y),
      };
      return;
    }
    final entity = _world.map.entities
        .where((candidate) => candidate.id == entityId)
        .cast<MapEntity?>()
        .firstWhere((candidate) => candidate != null, orElse: () => null);
    if (entity == null) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }

    // Réservation "anti-traversée visuelle":
    // - footprint collision de la destination (cohérence gameplay stricte),
    // - footprint visuel grille du NPC sur source + destination (cohérence
    //   perceptuelle pendant l'interpolation visuelle du sprite).
    final reserved = <GridPos>{}
      ..addAll(_resolveEntityCollisionCellsAtAnchor(entity, toAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, fromAnchorPos))
      ..addAll(_resolveEntityVisualCellsAtAnchor(entity, toAnchorPos));
    if (reserved.isEmpty) {
      _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
      return;
    }
    _scriptedNpcReservedOccupiedCellsByEntity[entityId] = reserved;
  }

  Set<GridPos> _resolveEntityCollisionCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final moved = entity.copyWith(pos: anchorPos);
    return resolveEntityCollisionCells(moved).where(_isInMapBounds).toSet();
  }

  Set<GridPos> _resolveEntityVisualCellsAtAnchor(
    MapEntity entity,
    GridPos anchorPos,
  ) {
    final cells = <GridPos>{};
    for (var dy = 0; dy < entity.size.height; dy++) {
      for (var dx = 0; dx < entity.size.width; dx++) {
        final cell = GridPos(
          x: anchorPos.x + dx,
          y: anchorPos.y + dy,
        );
        if (_isInMapBounds(cell)) {
          cells.add(cell);
        }
      }
    }
    return cells;
  }

  bool _isInMapBounds(GridPos cell) {
    return cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < _world.map.size.width &&
        cell.y < _world.map.size.height;
  }

  double get _cellWidth =>
      _bundle.manifest.settings.tileWidth *
      _bundle.manifest.settings.displayScale;

  double get _cellHeight =>
      _bundle.manifest.settings.tileHeight *
      _bundle.manifest.settings.displayScale;

  void _configureCameraViewport() {
    final cw = _bundle.cellWidth;
    final ch = _bundle.cellHeight;
    final mw = _bundle.map.size.width * cw;
    final mh = _bundle.map.size.height * ch;
    final vw = math.min(_kViewportTilesX * cw, mw);
    final vh = math.min(_kViewportTilesY * ch, mh);
    camera.viewfinder.visibleGameSize = Vector2(vw, vh);
  }

  void _syncCameraToPlayer() {
    if (!isLoaded) {
      return;
    }
    final focus = _player.focusPoint;
    camera.viewfinder.position = Vector2(
      focus.x.roundToDouble(),
      focus.y.roundToDouble(),
    );
  }
}

class _LoadedPlayableMap {
  _LoadedPlayableMap({
    required this.bundle,
    required this.originCellX,
    required this.originCellY,
    required this.backgroundLayers,
    required this.foregroundLayers,
    required this.npcActors,
    required this.npcActorByEntityId,
  });

  final RuntimeMapBundle bundle;
  final int originCellX;
  final int originCellY;
  final MapLayersComponent backgroundLayers;
  final MapLayersComponent foregroundLayers;
  final List<OverworldActorComponent> npcActors;
  final Map<String, OverworldActorComponent> npcActorByEntityId;
}

class _NpcCollisionDebugVisual {
  _NpcCollisionDebugVisual({
    required this.spriteRect,
    required this.collisionRect,
    required this.anchorMarker,
  });

  final RectangleComponent spriteRect;
  final RectangleComponent collisionRect;
  final CircleComponent anchorMarker;
}

class _GridCellPos {
  const _GridCellPos({
    required this.x,
    required this.y,
  });

  final int x;
  final int y;
}

class _PendingScenarioFollowRequest {
  _PendingScenarioFollowRequest({
    required this.leaderEntityId,
    required this.requestedAtMs,
  });

  final String leaderEntityId;
  final double requestedAtMs;
  GridPos? lastLeaderPos;
  Direction? lastLeaderTravelDirection;
  List<GridPos>? cachedPath;
  GridPos? cachedPathDestination;
  GridPos? cachedPathLeaderPos;
  int consecutiveBlockedSteps = 0;
}

class _PendingScenarioTransitionMapRequest {
  const _PendingScenarioTransitionMapRequest({
    required this.mapId,
    required this.warpId,
  });

  final String mapId;
  final String warpId;
}

class _PendingScenarioNpcWarpEntry {
  const _PendingScenarioNpcWarpEntry({
    required this.entityId,
    required this.warpId,
    required this.warpPos,
    required this.approachPos,
  });

  final String entityId;
  final String warpId;
  final GridPos warpPos;
  final GridPos approachPos;
}

class _PendingScenarioMoveContinuation {
  const _PendingScenarioMoveContinuation({
    required this.entityId,
    required this.runtimeSourceId,
    required this.targetKind,
  });

  final String entityId;
  final String runtimeSourceId;
  final String targetKind;
}

class _PendingScenarioReachedEnd {
  const _PendingScenarioReachedEnd({
    required this.scenarioId,
    required this.origin,
    required this.queuedAtMs,
  });

  final String scenarioId;
  final String origin;
  final double queuedAtMs;
}

class _FollowPathPlan {
  const _FollowPathPlan({
    required this.destination,
    required this.path,
  });

  final GridPos destination;
  final List<GridPos> path;
}

enum _WarpTransitionStyle {
  fade,
}

class _WarpTransitionSpec {
  const _WarpTransitionSpec({
    required this.style,
    required this.fadeOut,
    required this.fadeIn,
  });

  final _WarpTransitionStyle style;
  final Duration fadeOut;
  final Duration fadeIn;
}

```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_debug_panel_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_backdrop_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_hud_component.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
  );
}

RuntimeMapBundle _runtimeBundle({
  MapMetadata mapMetadata = const MapMetadata(),
  MapRole mapRole = MapRole.exterior,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Lot 2 Battle Background Tests',
      maps: <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'field_map',
          name: 'Field Map',
          relativePath: 'maps/field_map.json',
          role: mapRole,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
    ),
    map: MapData(
      id: 'field_map',
      name: 'Field Map',
      size: const GridSize(width: 4, height: 3),
      mapMetadata: mapMetadata,
    ),
    projectRootDirectory: '/tmp/lot2_battle_backgrounds',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest() {
  return const WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.north,
    ),
    mapId: 'field_map',
    zoneId: 'grass_zone',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: 'sparkitten',
    level: 6,
    minLevel: 6,
    maxLevel: 6,
    weight: 1,
    playerPos: GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.north,
    ),
    trainerId: 'trainer_rookie',
    npcEntityId: 'npc_rookie',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

void main() {
  group('BattleBackgroundResolver lot 2 context resolution', () {
    const resolver = BattleBackgroundResolver();

    test('resolves an outdoor wild family from a real wild request', () {
      final spec = resolver.resolve(
        request: _wildRequest(),
        bundle: _runtimeBundle(),
      );

      expect(spec.key, equals(BattleBackgroundKey.wildOutdoor));
    });

    test('resolves an outdoor trainer family from a real trainer request', () {
      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: _runtimeBundle(),
      );

      expect(spec.key, equals(BattleBackgroundKey.trainerOutdoor));
    });

    test('prioritizes indoor map truth over the battle kind when needed', () {
      final spec = resolver.resolve(
        request: _trainerRequest(),
        bundle: _runtimeBundle(
          mapMetadata: const MapMetadata(
            isIndoor: true,
            mapType: MapType.interior,
          ),
          mapRole: MapRole.interior,
        ),
      );

      expect(spec.key, equals(BattleBackgroundKey.indoor));
    });
  });

  group('BattleOverlayComponent Phase C decision prompts', () {
    test('uses the request type instead of a flat choice list heuristic', () {
      final freeTurnSession = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(freeTurnSession.decisionRequest),
        equals('Que doit faire le joueur ?'),
      );

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(
          forcedReplacementSession.decisionRequest,
        ),
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );

      final continueSession = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(continueSession.decisionRequest),
        equals('Le joueur doit continuer un tour forcé'),
      );
    });
  });

  group('BattleOverlayComponent BE10A chronology', () {
    test('renders a voluntary switch before the later enemy attack', () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final switchIndex =
          lines.indexWhere((line) => line.contains('Joueur switch de'));
      final attackIndex =
          lines.indexWhere((line) => line.contains('Ennemi utilise Tackle'));

      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(attackIndex, greaterThanOrEqualTo(0));
      expect(switchIndex, lessThan(attackIndex));
    });

    test('rejects bucket-only turn results because chronology would be false',
        () {
      const bucketOnlyTurn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(id: 'tackle', name: 'Tackle', power: 40),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 12,
            didHit: true,
          ),
        ],
      );

      expect(
        () => buildBattleTurnLinesForOverlay(bucketOnlyTurn),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'renders end-of-turn residuals before forced replacement markers after a double KO',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        isTrainerBattle: true,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final residualIndex = lines.indexWhere(
        (line) => line.contains('dégâts résiduels (PSN)'),
      );
      final enemyReplacementIndex = lines.indexWhere(
        (line) => line.contains('Ennemi remplace lead_enemy par bench_enemy'),
      );
      final playerReplacementIndex = lines.indexWhere(
        (line) => line.contains('Joueur doit remplacer lead_player K.O.'),
      );

      expect(residualIndex, greaterThanOrEqualTo(0));
      expect(enemyReplacementIndex, greaterThan(residualIndex));
      expect(playerReplacementIndex, greaterThan(enemyReplacementIndex));
    });

    test('renders Stealth Rock set and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'stealth_rock',
            name: 'Stealth Rock',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsStealthRock: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'stealth_rock',
              name: 'Stealth Rock',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsStealthRock: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        stealthRockEvents: <BattleStealthRockEvent>[
          BattleStealthRockEvent.set(
            side: BattleSideId.enemy,
            sourceMoveId: 'stealth_rock',
          ),
          BattleStealthRockEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 10,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'stealth_rock',
                name: 'Stealth Rock',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsStealthRock: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.set(
              side: BattleSideId.enemy,
              sourceMoveId: 'stealth_rock',
            ),
          ),
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 10,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Stealth Rock est posé du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 10 dégâts de Stealth Rock à l’entrée'),
      );
    });

    test(
        'renders Spikes layer growth and switch-in damage from timeline events',
        () {
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'spikes',
            name: 'Spikes',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsSpikes: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'spikes',
              name: 'Spikes',
              power: 0,
              target: BattleMoveTarget.opponentSide,
              setsSpikes: true,
            ),
            targetKind: BattleMoveExecutionTargetKind.side,
            targetSideRef: BattleSideId.enemy,
            damage: 0,
            didHit: true,
          ),
        ],
        spikesEvents: <BattleSpikesEvent>[
          BattleSpikesEvent.setLayer(
            side: BattleSideId.enemy,
            layers: 2,
          ),
          BattleSpikesEvent.damagedOnEntry(
            side: BattleSideId.enemy,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 13,
            layers: 2,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'spikes',
                name: 'Spikes',
                power: 0,
                target: BattleMoveTarget.opponentSide,
                setsSpikes: true,
              ),
              targetKind: BattleMoveExecutionTargetKind.side,
              targetSideRef: BattleSideId.enemy,
              damage: 0,
              didHit: true,
            ),
          ),
          BattleTurnSpikesEvent(
            BattleSpikesEvent.setLayer(
              side: BattleSideId.enemy,
              layers: 2,
            ),
          ),
          BattleTurnSpikesEvent(
            BattleSpikesEvent.damagedOnEntry(
              side: BattleSideId.enemy,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 13,
              layers: 2,
            ),
          ),
        ],
      );

      final lines = buildBattleTurnLinesForOverlay(turn);

      expect(
        lines,
        contains('Spikes monte à 2 couche(s) du côté Ennemi'),
      );
      expect(
        lines,
        contains('Ennemi subit 13 dégâts de Spikes à l’entrée (2 couche(s))'),
      );
    });
  });

  group('BattleOverlayComponent lot 1 scene composition', () {
    test(
        'uses a stable fallback background when no runtime context is injected',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.currentBackgroundKey,
        equals(BattleBackgroundKey.fallbackField),
      );
    });

    test(
        'mounts a structured battle scene with backdrop, battler zones, huds, command box and narration box by default',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.children.whereType<BattleSceneBackdropComponent>(),
        hasLength(1),
      );
      expect(
        overlay.children.whereType<BattleSceneCombatantComponent>(),
        hasLength(2),
      );
      expect(
        overlay.children.whereType<BattleSceneHudComponent>(),
        hasLength(2),
      );
      expect(overlay.commandPanelMounted, isTrue);
      expect(overlay.narrationPanelMounted, isTrue);
      expect(overlay.children.whereType<BattleDebugPanelComponent>(), isEmpty);
      expect(overlay.debugPanelMounted, isFalse);
    });

    test('mounts the resolved background family inside the backdrop layer',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        backgroundSpec: const BattleBackgroundSpec(
          key: BattleBackgroundKey.trainerOutdoor,
        ),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      final backdrop =
          overlay.children.whereType<BattleSceneBackdropComponent>().single;

      expect(
        overlay.currentBackgroundKey,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
      expect(
        backdrop.currentBackgroundKey,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
    });

    test('keeps the debug panel opt-in and separate from the normal battle UI',
        () async {
      final overlay = BattleOverlayComponent(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
          enemy: _combatant(
            speciesId: 'sparkitten',
            lineupIndex: 0,
            moves: <BattleMoveData>[_tackle()],
          ),
        ),
        viewportSize: Vector2(960, 540),
        showDebugPanel: true,
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(
        overlay.children.whereType<BattleDebugPanelComponent>(),
        hasLength(1),
      );
      expect(overlay.debugPanelMounted, isTrue);
      expect(overlay.commandPanelMounted, isTrue);
      expect(overlay.narrationPanelMounted, isTrue);
    });

    test('updateState refreshes the visible prompt and selected choice source',
        () async {
      final initialSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );
      final overlay = BattleOverlayComponent(
        session: initialSession,
        viewportSize: Vector2(960, 540),
        onPlayerChoice: (_) {},
      );

      await overlay.onLoad();

      expect(overlay.currentPromptText, equals('Que doit faire le joueur ?'));
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceFight>());

      final forcedReplacementSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmate',
            lineupIndex: 1,
            moves: <BattleMoveData>[_tackle()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_tackle()],
        ),
      );

      overlay.updateState(forcedReplacementSession);

      expect(
        overlay.currentPromptText,
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );
      expect(overlay.getSelectedChoice(), isA<PlayerBattleChoiceSwitch>());
    });
  });
}

```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/encounter_to_battle_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/trainer_battle_request.dart';
import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase A golden battle-ready slice smoke', () {
    const mapper = RuntimeBattleSetupMapper();
    const backgroundResolver = BattleBackgroundResolver();

    test('the versioned golden slice starts a real wild battle', () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );
      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.north),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: bundle.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter;

      expect(encounter, isNotNull);
      final request = buildBattleStartRequestFromEncounter(
        encounter: encounter!,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request,
      );
      final session = createBattleSession(setup);

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });

    test('the versioned golden slice starts a real trainer battle', () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );
      final trainer = bundle.map.entities.firstWhere(
        (entity) => entity.id == 'npc_trainer_rookie',
      );
      final request = buildTrainerBattleRequestFromNpc(
        entity: trainer,
        manifest: bundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      );

      expect(request, isNotNull);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: gameState,
        request: request!,
      );
      expect(setup.isTrainerBattle, isTrue);
      final session = createBattleSession(setup);

      expect(session.state.isFinished, isFalse);
      expect(session.state.player.speciesId, equals('sproutle'));
      expect(session.state.enemy.speciesId, equals('sparkitten'));
    });

    test(
        'the versioned golden slice resolves distinct wild and trainer backgrounds',
        () async {
      final projectFilePath = _goldenProjectFilePath();
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: 'golden_field',
      );
      final save = await _loadGoldenSave(projectFilePath);
      final gameState = gameStateFromSaveData(save);

      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: gameState.playerPosition,
        playerFacing: Direction.east,
        project: bundle.manifest,
      );

      final movedWorld = stepGameplayWorld(
        world,
        const MoveIntent(Direction.north),
      ).world;
      final encounter = checkEncounterAtPlayerPosition(
        world: movedWorld,
        project: bundle.manifest,
        encounterKind: EncounterKind.walk,
        random: _FixedEncounterRandom(
          nextDoubleValues: const <double>[0.0],
          nextIntValues: const <int>[0, 0],
        ),
        policy: const GameplayEncounterPolicy(chancePerStep: 1),
      ).encounter!;
      final wildRequest = buildBattleStartRequestFromEncounter(
        encounter: encounter,
        world: movedWorld,
        createdAtEpochMs: 1,
      );

      final trainer = bundle.map.entities.firstWhere(
        (entity) => entity.id == 'npc_trainer_rookie',
      );
      final trainerRequest = buildTrainerBattleRequestFromNpc(
        entity: trainer,
        manifest: bundle.manifest,
        world: world,
        createdAtEpochMs: 1,
      )!;

      expect(
        backgroundResolver.resolve(request: wildRequest, bundle: bundle).key,
        equals(BattleBackgroundKey.wildOutdoor),
      );
      expect(
        backgroundResolver.resolve(request: trainerRequest, bundle: bundle).key,
        equals(BattleBackgroundKey.trainerOutdoor),
      );
    });
  });
}

String _goldenProjectFilePath() {
  // Le smoke doit consommer le vrai slice versionné du repo, pas une fixture
  // temporaire en /tmp. On résout donc explicitement le chemin vers l'example
  // host battleready pour que le test protège cette vérité produit.
  return p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'examples',
      'playable_runtime_host',
      'golden_battle_slice',
      'project.json',
    ),
  );
}

Future<SaveData> _loadGoldenSave(String projectFilePath) async {
  final saveFile = File(
    p.join(
      File(projectFilePath).parent.path,
      'runtime_host_launch_save.json',
    ),
  );
  final decoded = jsonDecode(await saveFile.readAsString());
  return SaveData.fromJson(decoded as Map<String, dynamic>).normalized();
}

class _FixedEncounterRandom implements Random {
  _FixedEncounterRandom({
    required this.nextDoubleValues,
    required this.nextIntValues,
  });

  final List<double> nextDoubleValues;
  final List<int> nextIntValues;
  var _doubleIndex = 0;
  var _intIndex = 0;

  @override
  bool nextBool() => nextInt(2) == 0;

  @override
  double nextDouble() {
    final value = nextDoubleValues[_doubleIndex % nextDoubleValues.length];
    _doubleIndex++;
    return value;
  }

  @override
  int nextInt(int max) {
    final value = nextIntValues[_intIndex % nextIntValues.length];
    _intIndex++;
    return max == 0 ? 0 : value % max;
  }
}

```
