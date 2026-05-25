# P5-09 — Beta Playability Validator V0

## 1. Résumé exécutif

P5-09 est exécuté comme un lot concret, non audit-only.

Résultat :

```text
BetaPlayabilityValidator V0 existe dans map_core.
Il produit des diagnostics purs, lisibles et actionnables.
Il ne lit pas le disque.
Il ne dépend pas de map_runtime.
Il ne modifie pas ProjectManifest, SaveData ou GameState.
Il ne crée aucune UI ni auto-fix.
```

Le validator couvre V0 :

```text
manifest sans map
map référencée mais non fournie
start map optionnelle via contexte
defaultSpawnId invalide
absence de player_start spawn
NPC trainerId vers trainer absent
trainer sans équipe
trainer Pokémon sans species / moves
species absente du catalogue connu optionnel
move absent du catalogue connu optionnel
absence de starter / initial party source sous forme de warning
prérequis capture sous forme de warning optionnel
prérequis save/load sous forme d'erreur optionnelle
```

Verdict : P5-09 est validable. Le prochain lot exact reste :

```text
P5-10 — Audio Minimal Runtime Proof V0
```

## 2. Scope du lot

Scope exécuté :

```text
validator bêta minimal
diagnostics purs map_core
tests ciblés
export API publique depuis map_core.dart
roadmap Phase 5 mise à jour
rapport Evidence Pack
```

Hors scope respecté :

```text
pas d'UI validator
pas d'auto-fix
pas de wizard
pas de starter catalog persistant
pas de modification ProjectManifest
pas de modification SaveData / GameState
pas de modification map_runtime
pas de Selbrume final
pas de Boot Flow complet
pas de XP persistée complète
pas de moves learned / evolution
pas de P5-10 exécuté
```

## 3. Sources lues

Fichiers et sources principaux lus :

```text
AGENTS.md
skills/README.md
pokemap_roadmap_mecaniques_fangame.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_5.md
reports/roadmap/phase_5/p5_08_beta_runtime_smoke_new_game_battle_reward_save_load.md
packages/map_core/lib/src/validation/validators.dart
packages/map_core/lib/src/validation/
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/models/pokemon_move.dart
packages/map_core/lib/map_core.dart
packages/map_gameplay/lib/src/player_spawn_resolver.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_core/test/project_trainer_validation_test.dart
packages/map_core/test/save_data_test.dart
packages/map_gameplay/test/capture_destination_operations_test.dart
packages/map_gameplay/test/battle_reward_operations_test.dart
```

Constats d'audit :

```text
ProjectValidator / MapValidator existent mais lèvent des exceptions techniques.
Il n'existait pas de validator bêta orienté diagnostics actionnables.
ProjectManifest ne définit pas de startMapId persistant.
MapMetadata.defaultSpawnId existe et peut pointer vers une entité spawn.
MapEntityNpcData.trainerId existe.
ProjectTrainerEntry.team porte les Pokémon adverses, speciesId et moves.
Les catalogues species / moves runtime ne doivent pas être chargés depuis map_core.
```

## 4. Validator ajouté ou consolidé

Nouveau fichier :

```text
packages/map_core/lib/src/validation/beta_playability_validator.dart
```

Export public ajouté :

```dart
export 'src/validation/beta_playability_validator.dart';
```

API publique complète ajoutée :

```dart
enum BetaPlayabilityDiagnosticSeverity {
  error,
  warning,
  info,
}

enum BetaPlayabilityDiagnosticKind {
  missingMap,
  missingStartMap,
  missingPlayerSpawn,
  invalidDefaultSpawn,
  missingTrainerReference,
  trainerHasEmptyTeam,
  trainerPokemonMissingSpecies,
  trainerPokemonMissingMoves,
  missingPokemonSpecies,
  missingPokemonMove,
  missingStarterOrInitialPartySource,
  missingCapturePrerequisite,
  missingSaveLoadPrerequisite,
}

class BetaPlayabilityDiagnostic {
  const BetaPlayabilityDiagnostic({
    required this.kind,
    required this.severity,
    required this.message,
    required this.actionHint,
    this.path,
    this.mapId,
    this.entityId,
    this.trainerId,
    this.speciesId,
    this.moveId,
  });

  final BetaPlayabilityDiagnosticKind kind;
  final BetaPlayabilityDiagnosticSeverity severity;
  final String message;
  final String actionHint;
  final String? path;
  final String? mapId;
  final String? entityId;
  final String? trainerId;
  final String? speciesId;
  final String? moveId;
}

class BetaPlayabilityValidationContext {
  const BetaPlayabilityValidationContext({
    this.mapsById = const <String, MapData>{},
    this.startMapId,
    this.knownSpeciesIds = const <String>{},
    this.knownMoveIds = const <String>{},
    this.initialPartySpeciesIds = const <String>{},
    this.initialPartyMoveIds = const <String>{},
    this.requiresInitialParty = true,
    this.requiresTrainerBattle = true,
    this.requiresCapture = false,
    this.hasCaptureItemSource = false,
    this.requiresSaveLoad = true,
    this.hasSaveLoadSupport = true,
  });

  final Map<String, MapData> mapsById;
  final String? startMapId;
  final Set<String> knownSpeciesIds;
  final Set<String> knownMoveIds;
  final Set<String> initialPartySpeciesIds;
  final Set<String> initialPartyMoveIds;
  final bool requiresInitialParty;
  final bool requiresTrainerBattle;
  final bool requiresCapture;
  final bool hasCaptureItemSource;
  final bool requiresSaveLoad;
  final bool hasSaveLoadSupport;
}

class BetaPlayabilityValidationResult {
  BetaPlayabilityValidationResult(
    Iterable<BetaPlayabilityDiagnostic> diagnostics,
  ) : diagnostics = List<BetaPlayabilityDiagnostic>.unmodifiable(diagnostics);

  final List<BetaPlayabilityDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
        (diagnostic) =>
            diagnostic.severity == BetaPlayabilityDiagnosticSeverity.error,
      );

  bool get isPlayable => !hasErrors;
}

BetaPlayabilityValidationResult validateBetaPlayability(
  ProjectManifest manifest, {
  BetaPlayabilityValidationContext context =
      const BetaPlayabilityValidationContext(),
});
```

Justification de placement :

```text
map_core est le bon niveau pour les diagnostics structurels purs.
Le validator accepte des contextes optionnels au lieu de lire le disque.
Les catalogues species/moves sont transmis comme sets connus optionnels.
Le startMapId est optionnel dans le contexte, sans modifier ProjectManifest.
```

## 5. Diagnostics map / spawn

Diagnostics prouvés :

```text
missingMap
missingStartMap
missingPlayerSpawn
invalidDefaultSpawn
```

Décision start map V0 :

```text
Si context.startMapId est fourni, il est utilisé comme start map candidate.
Sinon, la première ProjectMapEntry du manifest est utilisée.
```

Cette décision évite de créer un champ persistant prématuré dans ProjectManifest.

## 6. Diagnostics starter / initial party

P5-03 n'a pas créé de StarterCatalog persistant. P5-09 ne l'invente donc pas.

Le validator utilise :

```text
initialPartySpeciesIds
initialPartyMoveIds
requiresInitialParty
```

Comportement V0 :

```text
absence de source initial party => warning missingStarterOrInitialPartySource
species initiale inconnue si catalogue fourni => error missingPokemonSpecies
move initial inconnu si catalogue fourni => error missingPokemonMove
```

Le warning est volontaire : le projet peut encore dépendre d'un flow externe tant que le starter authoring complet n'est pas persistant.

## 7. Diagnostics trainers / battles

Diagnostics prouvés :

```text
missingTrainerReference
trainerHasEmptyTeam
trainerPokemonMissingSpecies
trainerPokemonMissingMoves
missingPokemonSpecies
missingPokemonMove
```

Le validator parcourt les maps fournies et inspecte les `MapEntityKind.npc` portant un `npc.trainerId`.

Limite V0 :

```text
Il valide les trainers référencés par les maps fournies.
Il ne certifie pas encore tous les trainers non placés dans le manifest.
```

## 8. Diagnostics species / moves

Le validator reste pur :

```text
knownSpeciesIds
knownMoveIds
```

Aucun loader runtime n'est appelé.

Comportement :

```text
set vide => le catalogue n'est pas disponible, pas de diagnostic de catalogue.
set non vide => species/moves référencés doivent exister.
```

## 9. Diagnostics capture / save-load prerequisites

Capture V0 :

```text
requiresCapture && !hasCaptureItemSource
=> warning missingCapturePrerequisite
```

Save/load V0 :

```text
requiresSaveLoad && !hasSaveLoadSupport
=> error missingSaveLoadPrerequisite
```

Le validator ne teste pas le filesystem. Les preuves disque restent celles de P5-07 et P5-08.

## 10. API et contexte de validation

L'API choisie est :

```dart
validateBetaPlayability(
  ProjectManifest manifest, {
  BetaPlayabilityValidationContext context =
      const BetaPlayabilityValidationContext(),
})
```

Raisons :

```text
évite un ProjectManifest plus gros
évite une migration
évite une dépendance runtime
permet aux futurs editor/runtime/CI d'injecter maps, catalogues et exigences bêta
reste testable en pur Dart
```

## 11. Ce qui est prouvé

P5-09 prouve :

```text
un validator bêta V0 existe dans map_core
les diagnostics map/spawn sont testés
les diagnostics trainers/battles sont testés
les diagnostics species/moves sont testés
le statut starter/initial party est diagnostiqué honnêtement
capture/save-load sont couverts en warning/error optionnels
l'API est publique via map_core.dart
les tests ciblés passent
les régressions SaveData/GameState persistence passent
dart analyze est clean
```

## 12. Ce qui n’est pas prouvé

Non prouvé volontairement :

```text
UI validator
auto-fix
wizard de correction
chargement disque des catalogues species/moves
validator runtime complet
validation exhaustive des encounters
validation complète du starter authoring persistant
validation officielle complète façon Pokémon
certification bêta finale sans checkpoint
```

## 13. Limites et reports vers P5-10 / checkpoint / Phase 7

Reports :

```text
P5-10 : audio runtime minimal.
P5-CHECKPOINT-01 : verdict global de clôture Phase 5.
Phase 7 : UI validator, wizard, expériences premium et Boot Flow complet.
```

Limites connues :

```text
Le startMapId reste un paramètre de contexte, pas un champ manifest.
Le starter/initial party est encore injecté par contexte.
Les catalogues species/moves sont des sets connus fournis par l'appelant.
Capture est diagnostiquée comme prérequis minimal, pas validée contre un système complet de ball/encounters.
```

## 14. Tests exécutés

Commande ciblée :

```bash
cd packages/map_core && dart test test/beta_playability_validator_test.dart
```

Résultat utile :

```text
+12: All tests passed!
```

Régressions ciblées :

```bash
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_core && dart test test/save_data_test.dart
```

Résultats utiles :

```text
game_state_persistence_test.dart : +8: All tests passed!
save_data_test.dart : +25: All tests passed!
```

Analyse :

```bash
cd packages/map_core && dart analyze
```

Résultat :

```text
No issues found!
```

Format :

```bash
cd packages/map_core && dart format --set-exit-if-changed lib/src/validation/beta_playability_validator.dart lib/map_core.dart test/beta_playability_validator_test.dart
```

Résultat final :

```text
Formatted 3 files (0 changed) in 0.01 seconds.
```

Note : un premier passage format a modifié les deux nouveaux fichiers, puis le format final est passé sans changement.

## 15. Modifications effectuées

Fichiers créés :

```text
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_core/test/beta_playability_validator_test.dart
reports/roadmap/phase_5/p5_09_beta_playability_validator.md
```

Fichiers modifiés :

```text
packages/map_core/lib/map_core.dart
MVP Selbrume/road_map_phase_5.md
```

Fichiers explicitement non modifiés par P5-09 :

```text
MVP Selbrume/road_map_global.md
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_runtime/**
packages/map_battle/**
packages/map_editor/**
```

## 16. Evidence Pack

### git status initial exact

```text
 M "MVP Selbrume/road_map_phase_5.md"
?? packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
?? reports/roadmap/phase_5/p5_08_beta_runtime_smoke_new_game_battle_reward_save_load.md
```

Ces deux fichiers non suivis P5-08 étaient présents avant P5-09 et n'ont pas été modifiés par ce lot.

### Commandes exécutées

```bash
git status --short --untracked-files=all
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,1200p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,340p' reports/roadmap/phase_5/p5_08_beta_runtime_smoke_new_game_battle_reward_save_load.md
sed -n '1,420p' packages/map_core/lib/src/validation/validators.dart
find packages/map_core/lib/src/validation -type f | sort
sed -n '1,360p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '1,320p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,260p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,260p' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '1,220p' packages/map_core/lib/map_core.dart
rg -n "ProjectValidator|MapValidator|Diagnostic|Validation|spawn|defaultSpawnId|trainerId|ProjectTrainerEntry|ProjectTrainerPokemonEntry|PokemonMove|speciesId|moves|knownSpecies|knownMove|playability|beta" packages/map_core packages/map_gameplay packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
find packages/map_core/test -maxdepth 2 -type f | sort | rg "validator|validation|project|map|beta|playability|trainer|pokemon"
sed -n '1,260p' packages/map_core/test/project_trainer_validation_test.dart
sed -n '1,220p' packages/map_core/test/save_data_test.dart
sed -n '1,260p' packages/map_gameplay/lib/src/player_spawn_resolver.dart
sed -n '1,260p' packages/map_gameplay/lib/src/new_game_state_builder.dart
sed -n '1,360p' packages/map_gameplay/lib/src/game_state_mutations.dart
cd packages/map_core && dart test test/beta_playability_validator_test.dart
cd packages/map_core && dart format --set-exit-if-changed lib/src/validation/beta_playability_validator.dart lib/map_core.dart test/beta_playability_validator_test.dart
cd packages/map_core && dart test test/game_state_persistence_test.dart
cd packages/map_core && dart test test/save_data_test.dart
cd packages/map_core && dart analyze
```

### Sorties utiles

Test rouge initial avant implémentation :

```text
Method not found: 'validateBetaPlayability'.
Method not found: 'BetaPlayabilityValidationContext'.
Undefined name: 'BetaPlayabilityDiagnosticKind'.
Undefined name: 'BetaPlayabilityDiagnosticSeverity'.
Type 'BetaPlayabilityValidationResult' not found.
```

Test ciblé final :

```text
00:00 +12: All tests passed!
```

Régressions finales :

```text
game_state_persistence_test.dart : 00:00 +8: All tests passed!
save_data_test.dart : 00:00 +25: All tests passed!
```

Analyse finale :

```text
Analyzing map_core...
No issues found!
```

Format final :

```text
Formatted 3 files (0 changed) in 0.01 seconds.
```

### Contenu complet des nouveaux tests ajoutés

Le test complet ajouté est `packages/map_core/test/beta_playability_validator_test.dart`. Il couvre 12 cas :

```text
1. accepts a minimal beta-ready project without blocking errors
2. diagnoses an empty manifest map list
3. diagnoses a manifest map missing from mapsById
4. diagnoses an invalid default spawn id
5. diagnoses a start map without a player spawn
6. diagnoses an NPC trainer reference missing from the manifest
7. diagnoses a referenced trainer with an empty team
8. diagnoses trainer pokemon species missing from known species
9. diagnoses trainer pokemon move missing from known moves
10. warns honestly when no starter or initial party source is provided
11. diagnoses capture and save-load prerequisites when requested
12. does not hardcode any Selbrume ids in diagnostics
```

Extrait exhaustif de la structure testée :

```dart
final result = validateBetaPlayability(
  _manifest(),
  context: BetaPlayabilityValidationContext(
    mapsById: <String, MapData>{_mapId: _map()},
    knownSpeciesIds: const <String>{_starterSpeciesId, _enemySpeciesId},
    knownMoveIds: const <String>{_starterMoveId, _enemyMoveId},
    initialPartySpeciesIds: const <String>{_starterSpeciesId},
    initialPartyMoveIds: const <String>{_starterMoveId},
    requiresCapture: true,
    hasCaptureItemSource: true,
  ),
);
```

Le fichier complet fait 348 lignes. Il est trop long pour être dupliqué intégralement sans rendre ce rapport moins lisible ; les cas de tests complets, les IDs génériques et les assertions principales sont listés ci-dessus. Aucun contenu Selbrume n'est utilisé.

### Diff complet des fichiers modifiés suivis

`packages/map_core/lib/map_core.dart` :

```diff
 export 'src/validation/validators.dart';
 export 'src/validation/dialogue_validation.dart';
 export 'src/validation/entity_editor_visual_validation.dart';
+export 'src/validation/beta_playability_validator.dart';
 export 'src/exceptions/map_exceptions.dart';
```

`MVP Selbrume/road_map_phase_5.md` :

```diff
-Lot courant : ➡️ P5-09 — Beta Playability Validator V0
+Lot courant : ➡️ P5-10 — Audio Minimal Runtime Proof V0

-Prochain lot exact : P5-09 — Beta Playability Validator V0
+Prochain lot exact : P5-10 — Audio Minimal Runtime Proof V0

-- ➡️ P5-09 — Beta Playability Validator V0
-- ⏳ P5-10 — Audio Minimal Runtime Proof V0
+- ✅ P5-09 — Beta Playability Validator V0
+- ➡️ P5-10 — Audio Minimal Runtime Proof V0

-P5-09 : ➡️ prochain lot exact
+P5-09 : ✅ terminé

-P5-10 : ⏳ à venir
+P5-10 : ➡️ prochain lot exact

-P5-09 — Beta Playability Validator V0
+P5-10 — Audio Minimal Runtime Proof V0

-### ➡️ P5-09 — Beta Playability Validator V0
+### ✅ P5-09 — Beta Playability Validator V0

-Statut : prochain lot exact.
+Statut : terminé.

-### ⏳ P5-10 — Audio Minimal Runtime Proof V0
+### ➡️ P5-10 — Audio Minimal Runtime Proof V0
+
+Statut : prochain lot exact.
```

La roadmap contenait déjà le suivi visuel demandé pendant le travail précédent ; P5-09 met uniquement le statut P5-09/P5-10 à jour dans ce suivi.

### Contrôles explicites

```text
road_map_global.md n'a pas été modifié.
P5-10 n'a pas été exécuté.
Aucun Boot Flow complet n'a été créé.
Selbrume final n'a pas été créé.
Aucune UI validator n'a été créée.
Aucun auto-fix n'a été créé.
Aucune XP persistée complète n'a été ajoutée.
Aucun moves learned / evolution system n'a été ajouté.
ProjectManifest n'a pas été modifié.
SaveData / GameState n'ont pas été modifiés.
map_runtime n'a pas été modifié par P5-09.
```

### git diff --check exact

```text
<aucune sortie>
```

### git diff --stat exact

```text
 MVP Selbrume/road_map_phase_5.md    | 95 +++++++++++++++++++++++++++----------
 packages/map_core/lib/map_core.dart |  1 +
 2 files changed, 72 insertions(+), 24 deletions(-)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis ; les nouveaux fichiers P5-09 sont visibles dans le status final.

### git diff --name-only exact

```text
MVP Selbrume/road_map_phase_5.md
packages/map_core/lib/map_core.dart
```

### git status final exact

```text
 M "MVP Selbrume/road_map_phase_5.md"
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/validation/beta_playability_validator.dart
?? packages/map_core/test/beta_playability_validator_test.dart
?? packages/map_runtime/test/p5_beta_runtime_smoke_test.dart
?? reports/roadmap/phase_5/p5_08_beta_runtime_smoke_new_game_battle_reward_save_load.md
?? reports/roadmap/phase_5/p5_09_beta_playability_validator.md
```

## 17. Auto-review critique

Points solides :

```text
Le validator est pur map_core.
Le startMapId n'est pas ajouté au manifest.
Les catalogues species/moves restent injectés par contexte.
Les diagnostics portent kind, severity, message, actionHint et ids utiles.
Les tests prouvent les branches V0 prioritaires.
```

Risques / limites :

```text
Le validator ne charge pas encore les catalogues runtime depuis disque.
Le validator ne certifie pas une UI interactive.
Le validator ne remplace pas le checkpoint final de Phase 5.
Le warning starter reflète une limite réelle : pas de StarterCatalog authoré persistant.
```

Décision : ces limites sont acceptables pour P5-09.

## 18. Regard critique sur le prompt

Le prompt était strict et utile : il empêche de transformer le validator en UI, auto-fix ou refonte runtime.

Point de vigilance : la liste de diagnostics demandée est large. Pour rester V0, le bon compromis a été de :

```text
mettre les diagnostics structurels dans map_core
injecter les catalogues connus par contexte
reporter le chargement runtime/disque complet
reporter l'UI validator
```

Le prochain lot exact est confirmé :

```text
P5-10 — Audio Minimal Runtime Proof V0
```
