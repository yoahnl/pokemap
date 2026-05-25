# P2-06 — Battle Reference / Outcome Contract

## 1. Résumé exécutif

P2-06 reste design-only : aucun code, aucun modèle persistant, aucun JSON,
aucune migration et aucune modification de package ne sont produits.

La vérité technique observée est suffisante pour décider une trajectoire
prudente :

- une Scene référence aujourd'hui un combat via un node `startTrainerBattle`
  dans `ScenarioAsset` ;
- le node porte `binding.trainerId`, `binding.entityId` comme `npcEntityId`, et
  `payload.params['battleId']` optionnel avec fallback runtime sur `trainerId` ;
- le runtime renvoie un `ScenarioRuntimeEffectType.battle` contenant
  `battleId`, `trainerId` et `npcEntityId`, puis suspend le graphe ;
- les helpers runtime savent nommer des flags `battle:<battleId>:victory`,
  `battle:<battleId>:defeat`, `battle:<battleId>:flee` et
  `battle:<battleId>:captured` ;
- le moteur battle propre expose `victory`, `defeat` et `fled`, mais ne doit pas
  connaître le Narrative Studio ;
- le write-back runtime marque déjà `trainer_defeated:<trainerId>` en cas de
  victoire trainer, et gère une capture sauvage minimale ailleurs, hors contrat
  narratif V0.

Décision recommandée :

- ne pas créer de `BattleRegistry` ;
- ne pas modifier `ProjectManifest` ;
- ne pas modifier `map_battle` ;
- ne pas fusionner battle outcome et scenario outcome ;
- limiter le contrat conceptuel V0 à `victory` / `defeat` ;
- reconnaître `flee` / `captured` comme suffixes techniques existants, mais hors
  contrat narratif V0 ;
- reporter rewards, money, XP, level-up, capture authoring, flee authoring et
  static wild authoring hors P2-06 ;
- recommander un futur `BattleReferenceReadModel` non persistant, dérivé de
  `ScenarioAsset` + `ProjectManifest.trainers`, si P2-09/P2-10 justifient des
  diagnostics ou pickers.

Le prochain lot exact est :

```text
P2-07 — Fact Descriptor / Presentation Layer
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports Phase 1 / Phase 2 pertinents ;
- audit ciblé de `startTrainerBattle`, runtime battle effect, flags de battle
  outcome, validators et trainers ;
- comparaison des options de contrat ;
- décision d'implémentation P2-06 ;
- proposition de contrat conceptuel non implémenté ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- modification de `map_battle` ;
- couplage battle vers Narrative Studio ;
- modèle `map_core` ;
- JSON, migration, Freezed, JsonSerializable, build_runner ;
- modification `ProjectManifest` ;
- `BattleRegistry` persistant ;
- Reward Model ;
- money / XP / level-up ;
- static wild authoring ;
- capture / flee comme V0 narratif ;
- FactDescriptor ;
- P2-07 ;
- UI ;
- Selbrume final.

## 3. Sources lues

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md` : contexte global, reports Phase 5 pour
  rewards/money/XP et interdiction de couplage battle -> narration.
- `MVP Selbrume/road_map_phase_2.md` : lot courant, lots précédents et prochain
  lot exact.
- `MVP Selbrume/road_map_phase_1.md` : clôture Phase 1.
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
  : cadrage Phase 2 audit-first.
- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` :
  inventaire technique initial.
- `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`
  : décision adapter/read model non persistant pour Story/Step.
- `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md` : Event
  design-only et source adapter future.
- `reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md` :
  Scene comme vue produit dérivée de `ScenarioAsset`.
- `reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md` : séparation
  scenario outcomes / battle outcomes.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  : clôture Phase 1.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` :
  proposition initiale des contrats Phase 2.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` :
  workflows no-code.
- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` :
  mapping conceptuel Selbrume.
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` :
  frontières Event / Scene / Cinematic.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` :
  grammaire produit canonique.

Code lu en lecture seule :

- `packages/map_core/lib/src/models/scenario_asset.dart` : `ScenarioAsset`,
  `ScenarioNodeBinding`, `ScenarioNodePayload`.
- `packages/map_core/lib/src/models/project_manifest.dart` :
  `ProjectManifest.trainers`.
- `packages/map_core/lib/src/models/project_trainer.dart` :
  `ProjectTrainerEntry`.
- `packages/map_core/lib/src/operations/narrative_validator.dart` :
  diagnostics narratifs `startTrainerBattle`.
- `packages/map_core/lib/src/validation/validators.dart` :
  validation projet des trainers et références scenario.
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
  : `ScenarioRuntimeEffectType.battle` et champs d'effet battle.
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
  : exécution `startTrainerBattle`.
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
  : helpers de flags `battle:<battleId>:<suffix>`.
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` :
  write-back battle vers `GameState`.
- `packages/map_runtime/lib/src/application/scenario_conditions.dart` :
  condition `trainerDefeated`.
- `packages/map_runtime/lib/src/application/story_flags_manager.dart` :
  flag `trainer_defeated:<trainerId>`.
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`
  : projection editor narrative et outcomes.
- `packages/map_battle/lib/src/domain/battle/battle_outcome.dart` :
  outcome engine propre.
- `packages/map_battle/lib/src/battle_state.dart` : état battle terminal.
- Zones `packages/map_battle/lib`, `packages/map_runtime/lib/src/application`
  inspectées par recherche ciblée pour les termes battle/outcome.

## 4. Rappel Phase 1 / P2-01 à P2-05

Phase 1 a figé :

```text
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
Validator diagnostique.
```

P2-01 a montré que `ScenarioAsset` est le graphe scénario persistant principal,
que `ProjectManifest` agrège les trainers, que `ScenarioRuntimeExecutor` sait
produire un battle handoff, et que les flags de battle outcome existent déjà
côté runtime.

P2-02 a refusé une persistence Storyline / Chapter / Step prématurée.

P2-03 a décidé que Event reste source + condition + cible, sans orchestration.

P2-04 a décidé que Scene est une vue produit d'orchestration dérivée de
`ScenarioAsset`, sans wrapper persistant.

P2-05 a séparé les scenario outcomes des battle outcomes : un outcome scénario
est porté par `declaredOutcomes`, `emitOutcome`, `sourceOutcome` et
`scenario.outcome.*`; un battle outcome reste lié au résultat du moteur de
combat et aux flags `battle:<battleId>:<suffix>`.

## 5. Problème à résoudre

Le repo sait déjà lancer un combat trainer depuis un scénario et sait écrire
des conséquences runtime. Le problème P2-06 n'est donc pas de créer un nouveau
moteur narratif battle, mais de clarifier :

- comment une Scene référence un combat ;
- quel identifiant est stable pour les outcomes de combat ;
- quels outcomes sont sûrs pour un V0 narratif ;
- comment diagnostiquer les références cassées ;
- comment éviter que `map_battle` dépende du Narrative Studio ;
- comment éviter d'aspirer rewards, money, XP, capture, flee et static wild.

La décision doit protéger deux frontières :

- `map_battle` résout un combat, sans lire Storyline/Scene/Fact ;
- Scene interprète le résultat, sans devenir Battle Engine.

## 6. Inventaire startTrainerBattle

Observé :

- l'action runtime canonique est `startTrainerBattle` ;
- dans `ScenarioAsset`, la référence battle passe par un node action dont
  `payload.actionKind` vaut `startTrainerBattle` ;
- `ScenarioNodeBinding.trainerId` porte l'identifiant du trainer ;
- `ScenarioNodeBinding.entityId` est utilisé comme `npcEntityId` par le
  runtime ;
- `ScenarioNodePayload.params['battleId']` peut porter un identifiant battle
  stable ;
- si `battleId` est absent, le runtime utilise `trainerId` comme fallback.

Interprétation prudente :

- la Scene référence aujourd'hui un combat trainer, pas un combat générique ;
- `trainerId` rattache la Scene à `ProjectManifest.trainers` ;
- `battleId` sert surtout à nommer les flags d'outcome ;
- l'absence d'un vrai modèle battle persistant séparé ne bloque pas P2-06.

Risques :

- confondre `trainerId` et `battleId` ;
- créer un `BattleRegistry` qui dupliquerait `ProjectManifest.trainers` ;
- faire croire que static wild/capture/flee authoring sont couverts par
  `startTrainerBattle`.

## 7. Inventaire runtime battle effect

Observé :

- `ScenarioRuntimeEffectType.battle` représente l'effet concret de handoff ;
- `ScenarioRuntimeEffect` contient `battleId`, `trainerId` et `npcEntityId` ;
- le runtime suspend le graphe avec un message de type :
  `Combat trainer "<trainerId>" (battle=<battleId>) lancé. Graphe suspendu.` ;
- la reprise post-battle est décrite côté runtime comme un retour après
  `BattleOutcome`, avec pose d'un flag déterministe puis continuation.

Interprétation prudente :

- le handoff runtime est déjà un consumer clair d'une future vue battle ;
- cette vue doit rester dérivée : elle peut exposer ce que le runtime utilise,
  mais ne doit pas déplacer la logique battle dans `map_core` ;
- `ScenarioRuntimeEffect` est un effet d'exécution, pas un modèle authoring.

Risque :

- enrichir l'effet runtime pour satisfaire l'UI auteur. Cela ferait du runtime
  la source de vérité authoring.

## 8. Inventaire battle outcome flags

Observé dans `scenario_battle_outcome_flags.dart` :

```text
battle:<battleId>:victory
battle:<battleId>:defeat
battle:<battleId>:flee
battle:<battleId>:captured
```

Les suffixes constants existent :

```text
victory
defeat
flee
captured
```

Le helper `scenarioBattleOutcomeFlagName(String battleId, String outcomeSuffix)`
normalise les deux valeurs et retourne le flag `battle:<battleId>:<suffix>`.

Observé dans `map_battle` propre :

- `BattleEngineOutcomeKind` expose `victory`, `defeat`, `fled` ;
- le commentaire indique que capture, run et draw restent des sujets legacy /
  runtime tant qu'un lot explicite ne les migre pas.

Décision V0 :

- `victory` et `defeat` sont le minimum narratif clair ;
- `flee` / `captured` existent techniquement dans des chemins runtime/legacy,
  mais ne sont pas retenus comme contrat narratif V0 P2-06 ;
- `captured` dépend de wild battle, bag et party capacity, donc relève de
  mécanismes runtime/gameplay hors P2-06 ;
- `flee` dépend de règles battle/runtime non stabilisées comme authoring
  narratif.

## 9. Inventaire validators existants

Observé dans `NarrativeValidator` :

- `startTrainerBattleMissingTrainerId` ;
- `startTrainerBattleReferencesUnknownTrainer` ;
- `startTrainerBattleMissingNpcEntityId` ;
- `startTrainerBattleBlankBattleId`.

Le validateur vérifie :

- `binding.trainerId` présent ;
- `trainerId` connu dans l'ensemble des trainers ;
- `binding.entityId` présent comme `npcEntityId` ;
- `payload.params['battleId']` non vide si la clé existe.

Observé dans `ProjectValidator` :

- duplicate trainer ID ;
- trainer ID non vide ;
- trainer name non vide ;
- trainer class non vide ;
- `battleDifficulty` dans `1..10` si présent ;
- `battleBackgroundRelativePath` comme chemin relatif ;
- scénario qui référence un trainer inconnu via `binding.trainerId`.

Ce qui manque pour P2-09 :

- diagnostics d'ambiguïté `battleId` absent et fallback sur `trainerId` ;
- diagnostic de `battleId` dupliqué entre nodes si cela devient risqué ;
- diagnostic post-battle absent : aucune branche/condition ne lit victory ou
  defeat ;
- diagnostic de suffixe non supporté dans un contrat V0 ;
- diagnostic de trainer sans équipe, si le gameplay veut bloquer l'authoring.

## 10. Inventaire ProjectManifest trainers

Observé :

- `ProjectManifest` contient `@Default([]) List<ProjectTrainerEntry> trainers` ;
- `ProjectTrainerEntry` porte `id`, `name`, `trainerClass`,
  `battleDifficulty`, `battleBackgroundRelativePath`, `characterId`,
  `portraitElementId`, `battleThemeId`, `victoryThemeId`, `team` et `tags` ;
- `ProjectTrainerPokemonEntry` porte `speciesId`, `level`, `moves`,
  `heldItemId`, `formId`, `gender`, `shiny`.

Interprétation prudente :

- la référence battle V0 peut être dérivée de `ScenarioAsset` +
  `ProjectManifest.trainers` ;
- `ProjectManifest.trainers` est déjà le registre projet des trainers ;
- créer un `BattleRegistry` persistant maintenant dupliquerait cette source.

## 11. Relation Battle outcome / Scenario outcome

Scenario outcome :

- déclaré par `ScenarioAsset.declaredOutcomes` ;
- émis par `emitOutcome` ;
- consommé par `sourceOutcome` / `outcomeReceived` ;
- persisté sous flag technique `scenario.outcome.<outcomeId>`.

Battle outcome :

- produit par le moteur battle ou par le bridge runtime ;
- rattaché à un `battleId` ;
- exprimé sous flag `battle:<battleId>:<suffix>` ;
- interprété par la Scene ou par des conditions ultérieures.

Décision :

- ne pas fusionner les deux familles ;
- ne pas exposer battle outcome comme un scenario outcome générique ;
- permettre plus tard un mapping explicite, par exemple une Scene qui convertit
  victory en conséquence narrative, mais sans automatisme en P2-06.

## 12. Relation Battle outcome / Fact / Rewards

Battle outcome n'est pas automatiquement un Fact.

Exemples :

- `battle:<id>:victory` est un résultat technique durable de combat ;
- `trainer_defeated:<trainerId>` est déjà un flag runtime de trainer battu ;
- un Fact auteur futur pourrait présenter "Rival battu au port" si P2-07
  décide une couche de présentation ;
- reward/money/XP/level-up ne sont pas des Facts P2-06.

Observed runtime write-back :

- la victoire trainer marque `trainer_defeated:<trainerId>` ;
- la capture sauvage minimale existe dans un chemin runtime avec garde-fous
  bag/party, mais ce n'est pas un contrat narratif V0 ;
- aucun reward, bag UI, switch ou reward unifié n'est ouvert par ce helper.

Décision :

- P2-06 ne crée pas de Reward Model ;
- P2-06 ne transforme pas victory en Fact ;
- P2-07 décidera la présentation Fact ;
- Phase 5 traitera rewards, money, XP et level-up.

## 13. Consumers explicites

| Consumer | Besoin | Immédiat ? | Nécessite persistence ? |
|---|---|---:|---:|
| `NarrativeValidator` | Diagnostiquer trainer/battle refs cassées | Oui, futur P2-09 | Non |
| `ProjectValidator` | Préserver cohérence manifest/scenarios/trainers | Déjà partiel | Non |
| `SceneReadModel` futur | Exposer battles référencés par Scene | Futur | Non |
| `Fact Descriptor` P2-07 | Distinguer battle outcome, trainer defeated et Fact présenté | Oui, décision | Non |
| `World Rule Predicate Adapter` P2-08 | Lire victory/defeat/trainer defeated comme conditions possibles | Futur | Non |
| `Reference Picker Read Models` P2-10 | Lister trainers/battle refs avec labels humains | Futur | Non |
| Runtime battle handoff | Lancer combat et reprendre post-battle | Déjà existant | Non nouveau |
| Phase 4 authoring minimal | Choisir un trainer et voir outcomes disponibles | Futur | Non au départ |

Ces consumers justifient une trajectoire adapter/read model non persistant,
mais pas une implémentation immédiate en P2-06.

## 14. Options de contrat

### Option A — Garder l'existant + diagnostics futurs

Utiliser `startTrainerBattle`, `ProjectManifest.trainers`,
`ScenarioRuntimeEffect.battle` et les flags `battle:<id>:suffix`.

Avantages :

- aucun risque de migration ;
- aucun couplage battle -> narration ;
- respecte l'existant prouvé ;
- suffit pour P2-07 à distinguer outcome technique et Fact.

Risques :

- labels auteur encore techniques ;
- pickers futurs non servis directement ;
- diagnostics battle plus pauvres avant P2-09.

Verdict :

Acceptable immédiatement, mais insuffisant seul pour Phase 4 authoring.

### Option B — Adapter/read model non persistant

Créer plus tard un `BattleReferenceReadModel` dérivé de `ScenarioAsset` et
`ProjectManifest.trainers`.

Avantages :

- sert validators, pickers et SceneReadModel sans persistence ;
- expose un vocabulaire auteur ;
- centralise labels, diagnostics et supported outcomes ;
- évite de toucher `ProjectManifest`.

Risques :

- peut devenir modèle persistant déguisé ;
- doit rester strictement dérivé ;
- dépend de P2-09/P2-10 pour prouver les usages concrets.

Verdict :

Trajectoire recommandée, mais pas à implémenter dans P2-06.

### Option C — Contrat pur minimal dans `map_core`

Créer maintenant ou plus tard un type pur représentant une battle reference.

Champs possibles :

- `battleReferenceId` ;
- `battleId` ;
- `sourceScenarioId` ;
- `sourceNodeId` ;
- `trainerId` ;
- `trainerLabel` ;
- `npcEntityId` ;
- outcomes supportés ;
- diagnostics.

Avantages :

- API testable ;
- peut servir P2-09/P2-10.

Risques :

- pas de consumer immédiat codé dans ce lot ;
- risque de figer trop tôt la relation `battleId` / `trainerId` ;
- tests seraient artificiels sans adapter réellement utilisé.

Verdict :

Possible plus tard, refusé maintenant.

### Option D — BattleRegistry persistant

Créer un registre persistant des battles narratifs.

Risques :

- duplique `ProjectManifest.trainers` ;
- impose migration ;
- mélange trainer data, battle setup, outcomes et narration ;
- ouvre rewards/money/XP trop tôt.

Verdict :

Refusé maintenant.

### Option E — Fusionner Battle outcome avec Scenario outcome

Traiter battle outcomes et scenario outcomes comme le même modèle.

Risques :

- masque leur source différente ;
- confond `scenario.outcome.*` et `battle:<id>:suffix` ;
- force P2-05 à absorber P2-06 ;
- rend la présentation Fact plus confuse.

Verdict :

Refusé maintenant. Un mapping explicite pourra exister plus tard.

### Option F — Inclure rewards / money / XP maintenant

Ajouter récompenses, argent, XP ou level-up au contrat.

Risques :

- ouvre Phase 5 dans Phase 2 ;
- mélange outcome et reward ;
- crée un Reward Model prématuré ;
- exige des tests et migrations gameplay hors scope.

Verdict :

Refusé. Phase future recommandée : Phase 5.

## 15. Matrice comparative

| Option | Complexité | Migration | Couplage battle | Support diagnostics | Support pickers | Recommandation |
|---|---:|---:|---:|---:|---:|---|
| A — Existant + diagnostics futurs | Faible | Non | Non | Moyen | Faible | Garder maintenant |
| B — Read model non persistant futur | Moyenne | Non | Non | Fort | Fort | Trajectoire principale |
| C — Contrat pur `map_core` | Moyenne | Non | Faible si bien borné | Fort | Fort | Plus tard seulement |
| D — `BattleRegistry` persistant | Forte | Oui | Risque élevé | Moyen | Moyen | Refuser |
| E — Fusion avec scenario outcome | Moyenne | Possible | Risque conceptuel | Moyen | Moyen | Refuser |
| F — Rewards/money/XP | Forte | Probable | Hors scope | Hors sujet | Hors sujet | Reporter Phase 5 |

## 16. Décision d'implémentation P2-06

Verdict :

```text
B — Adapter/read model recommandé plus tard : aucun code maintenant.
```

Réponses au gate :

- Un `BattleReference` / `BattleOutcome` adapter est-il nécessaire maintenant ?
  Non. La décision conceptuelle suffit pour P2-07.
- Quels consumers explicites le justifient ? P2-09 diagnostics, P2-10 pickers,
  SceneReadModel futur et Phase 4 authoring minimal.
- Peut-il être dérivé de `ScenarioAsset` + `ProjectManifest.trainers` sans
  persistence ? Oui.
- Peut-il attendre P2-09 / P2-10 ? Oui.
- Comment éviter de coupler `map_battle` au Narrative Studio ? Le read model
  futur lit des références projet et flags runtime ; `map_battle` ne dépend de
  rien côté Narrative Studio.
- Comment éviter de créer un `BattleRegistry` ? Utiliser
  `ProjectManifest.trainers` comme source trainer et `ScenarioAsset` comme
  source des nodes `startTrainerBattle`.
- Quels diagnostics deviennent possibles ? Trainer manquant, trainer inconnu,
  NPC manquant, `battleId` vide/ambigu, outcome post-battle jamais lu, suffixe
  hors V0.
- La persistence est-elle nécessaire ? Non.

Conditions C non remplies :

- aucun consumer codé immédiat ;
- P2-09/P2-10 doivent encore définir diagnostics et picker sources ;
- P2-07 doit d'abord décider la couche Fact/Presentation.

Donc P2-06 ne produit aucun code.

## 17. Contrat conceptuel recommandé

Contrat conceptuel non implémenté :

```text
BattleReferenceReadModel
```

Champs conceptuels possibles :

- `battleReferenceId` ;
- `battleId` ;
- `humanLabel` ;
- `sourceScenarioId` ;
- `sourceNodeId` ;
- `trainerId` ;
- `trainerLabel` ;
- `npcEntityId` ;
- `isTrainerKnown` ;
- `isNpcEntityKnown` ;
- `declaredOutcomeKinds` ;
- `supportedOutcomeKinds` ;
- `persistedOutcomeFlagNames` ;
- `victoryFlagName` ;
- `defeatFlagName` ;
- `fleeFlagName` ;
- `capturedFlagName` ;
- `diagnostics`.

Règles :

- ce contrat n'est pas créé par P2-06 ;
- il ne duplique pas `ScenarioAsset` ;
- il ne crée pas de `BattleRegistry` ;
- il est dérivé de `ScenarioAsset` + `ProjectManifest.trainers` autant que
  possible ;
- il ne couple pas `map_battle` au Narrative Studio ;
- il ne gère pas rewards, money, XP, capture authoring ou static wild authoring.

Statut V0 des outcomes :

- `victory` : inclus conceptuellement ;
- `defeat` : inclus conceptuellement ;
- `flee` : reconnu techniquement, hors V0 narratif ;
- `captured` : reconnu techniquement, hors V0 narratif.

## 18. Diagnostics possibles

Diagnostics déjà présents ou proches :

- `startTrainerBattleMissingTrainerId` ;
- `startTrainerBattleReferencesUnknownTrainer` ;
- `startTrainerBattleMissingNpcEntityId` ;
- `startTrainerBattleBlankBattleId` ;
- trainer ID dupliqué ;
- trainer vide ou incomplet dans `ProjectManifest`.

Diagnostics futurs possibles :

- `startTrainerBattleUsesTrainerIdAsBattleIdFallback` si ce fallback devient
  source d'ambiguïté auteur ;
- `battleReferenceDuplicateBattleId` si plusieurs nodes partagent un `battleId`
  de façon non intentionnelle ;
- `battleReferenceVictoryNeverRead` ;
- `battleReferenceDefeatNeverRead` ;
- `battleReferenceUnsupportedOutcomeKind` pour `flee` / `captured` en V0 ;
- `battleReferenceMissingPostBattleBranch` ;
- `battleReferenceTrainerHasEmptyTeam` si le gameplay veut bloquer les combats
  sans équipe ;
- `battleOutcomePresentedAsFactWithoutDescriptor` à traiter avec P2-07/P2-09.

Le Validator diagnostique ; il ne corrige pas.

## 19. Impacts sur P2-07 à P2-10

P2-07 — Fact Descriptor / Presentation Layer :

- devra distinguer `battle:<id>:victory`, `trainer_defeated:<trainerId>` et un
  Fact auteur ;
- ne devra pas transformer automatiquement battle outcome en Fact.

P2-08 — World Rule Predicate Adapter Contract :

- pourra traiter des conditions post-battle via flags ou trainer defeated ;
- devra éviter que World Rule déclenche un combat.

P2-09 — Narrative Validator Diagnostic Expansion :

- pourra ajouter les diagnostics battle listés ;
- devra rester dans le validator existant, sans deuxième validateur concurrent.

P2-10 — Reference Picker Read Models :

- pourra construire une source de picker battle dérivée des trainers et nodes
  `startTrainerBattle` ;
- devra afficher labels humains sans exposer uniquement `battle:<id>:suffix`.

## 20. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| Coupler `map_battle` au Narrative Studio | Le read model futur vit côté domaine/adapters, jamais dans `map_battle`. |
| Créer un `BattleRegistry` prématuré | Dériver depuis `ScenarioAsset` + `ProjectManifest.trainers`. |
| Confondre `battleId` et `trainerId` | Documenter le fallback et diagnostiquer les ambiguïtés en P2-09. |
| Fusionner battle outcome et scenario outcome | Garder les namespaces `battle:<id>:suffix` et `scenario.outcome.*` séparés. |
| Transformer victory en Fact automatique | P2-07 décide la présentation Fact explicitement. |
| Aspirer rewards/money/XP | Reporter Phase 5. |
| Présenter `flee` / `captured` comme V0 supporté | Les reconnaître comme suffixes techniques, hors V0 narratif. |
| Faire de `map_editor` la source de vérité | Les projections editor restent dérivées. |
| Modifier `ProjectManifest` trop tôt | Aucun champ nouveau sans consumer + migration prouvés. |

## 21. Ce que P2-06 décide

- Pas de code dans P2-06.
- Pas de modèle persistant.
- Pas de modification `ProjectManifest`.
- Pas de `BattleRegistry`.
- Pas de modification `map_battle`.
- Battle outcome et scenario outcome restent séparés.
- V0 conceptuel battle outcome = `victory` / `defeat`.
- `flee` / `captured` restent hors V0 narratif.
- `startTrainerBattle` + `ProjectManifest.trainers` + flags
  `battle:<battleId>:suffix` sont les sources techniques actuelles.
- Trajectoire recommandée : futur `BattleReferenceReadModel` non persistant si
  P2-09/P2-10 le justifient.

## 22. Ce que P2-06 ne décide pas

- Structure finale d'un modèle `map_core`.
- JSON final.
- Migration `ProjectManifest`.
- BattleRegistry.
- Reward Model.
- Money / XP / level-up.
- Capture authoring.
- Flee authoring.
- Static wild authoring.
- FactDescriptor final.
- UI picker.
- SceneReadModel implémenté.
- Selbrume réel.

## 23. Implémentation éventuelle

Aucune implémentation.

Justification :

- les consumers sont futurs et documentaires ;
- le runtime sait déjà lancer le battle handoff ;
- les validators ont déjà des diagnostics de base ;
- P2-07 doit d'abord clarifier Fact / Presentation ;
- P2-09/P2-10 sont les lots naturels pour diagnostics et read models.

## 24. Tests / validations éventuels

Tests Dart/Flutter non exécutés et non requis : P2-06 est design-first et ne
modifie aucun code.

Validations exécutées :

- `git diff --check` ;
- `git diff --stat` ;
- `git diff --name-only` ;
- contrôles hors scope sur roadmaps globales, packages battle et packages code.

Tests futurs possibles si un read model est créé :

- battle reference dérivée depuis `ScenarioAsset` ;
- trainer inconnu ;
- `battleId` absent avec fallback ;
- victory/defeat flag names ;
- exclusion de `flee` / `captured` du V0 narratif ;
- tri stable et labels humains pour pickers.

## 25. Recommandation pour P2-07

P2-07 doit traiter :

```text
P2-07 — Fact Descriptor / Presentation Layer
```

Recommandation :

- distinguer Fact, story flag, completed step, scenario outcome et battle
  outcome ;
- ne pas créer de `FactRegistry` prématuré ;
- considérer `trainer_defeated:<trainerId>` et `battle:<id>:victory` comme
  vérités techniques existantes, pas comme labels auteur suffisants ;
- décider si une Fact Presentation Layer peut exposer ces vérités sans dupliquer
  `GameState`.

## 26. Mise à jour de road_map_phase_2.md

Mise à jour attendue :

- `P2-06` passe à `✅ terminé` ;
- `P2-07` devient `🔜 prochain lot exact` ;
- résumé P2-06 ajouté ;
- fichiers créés / modifiés, commandes, décisions et changements de périmètre
  documentés.

## 27. Evidence Pack

### 27.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 27.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_trainer.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/scenario_conditions.dart
packages/map_runtime/lib/src/application/story_flags_manager.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_battle/lib/src/domain/battle/battle_outcome.dart
packages/map_battle/lib/src/battle_state.dart
skills/README.md
AGENTS.md
```

### 27.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
```

### 27.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 27.5 Commandes exécutées

```text
git status --short --untracked-files=all
find .. -name AGENTS.md -print
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,260p' AGENTS.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
ctx_search(sort="timeline", source="session-events", queries=["P2-05 final status P2-06 next", "P2-06 initial git status current", "P2-06 work resumed report roadmap"], limit=3)
ctx_batch_execute(commands=[cd /Users/karim/Project/pokemonProject && grep -nE "P2-06|P2-07|Battle|battle|startTrainerBattle|victory|defeat|flee|captured|Reward|money|XP|Fact|Outcome|ScenarioAsset|ProjectManifest|trainer" "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md" "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md || true; cd /Users/karim/Project/pokemonProject && grep -nE "startTrainerBattle|battleId|trainerId|npcEntityId|ScenarioRuntimeEffectType\\.battle|ScenarioRuntimeEffect\\(|scenarioBattleOutcomeFlagName|battle:|victory|defeat|flee|captured|ProjectTrainerEntry|startTrainerBattleMissingTrainerId|startTrainerBattleReferencesUnknownTrainer|startTrainerBattleMissingNpcEntityId" packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart || true; cd /Users/karim/Project/pokemonProject && sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart && sed -n '260,560p' packages/map_core/lib/src/models/scenario_asset.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,220p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart && sed -n '220,520p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart && sed -n '520,900p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,220p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart; cd /Users/karim/Project/pokemonProject && grep -nE "startTrainerBattle|trainerId|npcEntityId|battleId|MissingTrainer|UnknownTrainer|MissingNpc|BlankBattle" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart || true && sed -n '1,260p' packages/map_core/lib/src/operations/narrative_validator.dart && sed -n '260,620p' packages/map_core/lib/src/operations/narrative_validator.dart; cd /Users/karim/Project/pokemonProject && grep -nE "class ProjectTrainerEntry|ProjectTrainerEntry|trainers|trainer" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/validation/validators.dart || true && sed -n '1,240p' packages/map_core/lib/src/models/project_manifest.dart; cd /Users/karim/Project/pokemonProject && find packages/map_battle/lib packages/map_runtime/lib/src/application -maxdepth 3 -type f \( -name '*.dart' \) -print | xargs grep -nE "BattleOutcome|outcome|victory|defeat|flee|captured|capture|reward|money|xp|level" || true; cd /Users/karim/Project/pokemonProject && grep -nE "battle|Battle|trainer|Trainer|outcome|Outcome|startTrainerBattle" packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart || true && sed -n '1,260p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart && sed -n '260,620p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart], queries=["startTrainerBattle trainerId npcEntityId battleId ScenarioNodePayload actionKind", "ScenarioRuntimeEffectType battle battleId trainerId npcEntityId graph suspended", "scenarioBattleOutcomeFlagName battle victory defeat flee captured", "NarrativeValidator startTrainerBattleMissingTrainerId references unknown trainer missing npc blank battleId", "ProjectManifest trainers ProjectTrainerEntry trainer references validation", "scenario outcomes declaredOutcomes emitOutcome sourceOutcome battle outcomes separate", "P2-06 Battle Reference Outcome Contract roadmap next P2-07 Fact Reward money XP out of scope", "map_battle outcome victory defeat flee captured independent Narrative Studio"])
ctx_search(queries=["scenario runtime executor startTrainerBattle battleId trainerId npcEntityId effect", "ProjectManifest ProjectTrainerEntry fields trainers", "map_battle battle_outcome enum victory defeat", "runtime map battle outcome maps BattleOutcome to flags", "Narrative workspace projection battle startTrainerBattle trainer"], limit=5)
sed -n '1,420p' "MVP Selbrume/road_map_phase_2.md"
grep -nE "class ProjectTrainerEntry|ProjectTrainerEntry|trainerClass|team|party|pokemon|name" packages/map_core/lib/src/models/project_trainer.dart packages/map_core/lib/src/models/project_manifest.dart
grep -nE "enum BattleOutcome|class BattleOutcome|isVictory|isDefeat|victory|defeat|flee|captured|capture" packages/map_battle/lib/src/domain/battle/battle_outcome.dart packages/map_battle/lib/src/battle_state.dart packages/map_runtime/lib/src/application/map_battle* packages/map_runtime/lib/src/application/scenario_runtime/*
sed -n '420,820p' "MVP Selbrume/road_map_phase_2.md"
find packages/map_runtime/lib/src/application packages/map_battle/lib -type f -name '*.dart' -print | xargs grep -nE "BattleOutcome|outcome|victory|defeat|flee|captured|capture|reward|money|xp|level|ScenarioRuntimeEffectType\\.battle|scenarioBattleOutcomeFlagName" || true
sed -n '1,120p' packages/map_core/lib/src/models/project_trainer.dart
sed -n '1,220p' packages/map_battle/lib/src/domain/battle/battle_outcome.dart
grep -nE "scenarioBattleOutcomeFlagName|kBattleOutcomeSuffix|battle:<|BattleOutcome|isVictory|isDefeat|victory|defeat|flee|captured|capture|trainer_defeated|onBattleFinished|BattleOutcome" packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart packages/map_runtime/lib/src/application/story_flags_manager.dart packages/map_runtime/lib/src/application/scenario_conditions.dart packages/map_runtime/lib/src/application/runtime_battle*.dart packages/map_battle/lib/src/domain/battle/battle_outcome.dart packages/map_battle/lib/src/battle_state.dart
grep -nE "startTrainerBattle|trainerId|battleId|npcEntityId|ScenarioRuntimeEffectType\\.battle|Graphe suspendu|battle handoff" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
sed -n '160,240p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '1,110p' packages/map_runtime/lib/src/application/scenario_conditions.dart && sed -n '1,80p' packages/map_runtime/lib/src/application/story_flags_manager.dart
sed -n '760,890p' packages/map_core/lib/src/validation/validators.dart && sed -n '1110,1155p' packages/map_core/lib/src/validation/validators.dart
grep -nE "^## [0-9]+\\." reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md || true
git diff -- "MVP Selbrume/road_map_phase_2.md"
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Note : une commande de recherche avec le glob non quoté
`packages/map_runtime/lib/src/application/map_battle*` a échoué en lecture
seule (`zsh: no matches found`). Elle a été remplacée par la commande
exploitable `find packages/map_runtime/lib/src/application packages/map_battle/lib -type f -name '*.dart' -print | xargs grep ...`.

### 27.6 git diff --check

```text
```

### 27.6-bis git diff --no-index --check du rapport créé

```text
```

### 27.6-ter Contrôle hors scope global / phase 1 / battle / host

```text
```

### 27.6-quater Contrôle hors scope packages code

```text
```

### 27.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 75 ++++++++++++++++++++++++++++++++++++----
 1 file changed, 68 insertions(+), 7 deletions(-)
```

### 27.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 27.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
```

### 27.10 Tests / analyze

```text
Non exécutés — P2-06 est design-first/documentaire et ne modifie aucun code.
```

## 28. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

- Oui : rapport P2-06 et roadmap Phase 2 uniquement.

Le rapport P2-06 existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md`.

`road_map_phase_2.md` a-t-elle été mise à jour ?

- Oui : P2-06 terminé et P2-07 prochain lot exact.

`road_map_global.md` est-elle restée intacte ?

- Oui : contrôle hors scope final sans sortie.

Aucun code n'a-t-il été modifié, ou le code modifié est-il justifié ?

- Aucun code n'a été modifié.

`map_battle` est-il resté indépendant ?

- Oui. Lecture seule uniquement ; aucune modification ni dépendance narrative.

Aucun build_runner n'a-t-il été lancé ?

- Oui.

P2-07 n'a-t-il pas été commencé ?

- Oui. P2-07 est uniquement recommandé comme prochain lot.

Battle reste-t-il résolu par le moteur combat ?

- Oui. Le moteur battle résout ; P2-06 ne lui ajoute aucune notion narrative.

Scene reste-t-elle l'interprète narrative ?

- Oui. Scene interprète les outcomes, sans piloter le moteur battle.

Le contrat recommandé évite-t-il BattleRegistry prématuré ?

- Oui. La trajectoire est un read model non persistant dérivé.

Les consumers sont-ils explicites ?

- Oui : Validator, ProjectValidator, SceneReadModel futur, Fact Presentation,
  World Rule adapter, picker read models, Phase 4 authoring minimal.

La décision d'implémentation est-elle claire ?

- Oui : design-only, aucun code.

Le prochain lot exact est-il clair ?

- Oui : `P2-07 — Fact Descriptor / Presentation Layer`.

### Regard critique sur le prompt

Le prompt autorise une implémentation minimale conditionnelle, mais les
conditions sont volontairement strictes et les consumers immédiats restent
principalement futurs. La formulation la plus sûre est donc design-only. Le seul
point potentiellement ambigu est la présence technique de `flee` / `captured` :
le repo contient des chemins runtime associés, mais le prompt demande de ne pas
les traiter comme support V0 sans preuve. P2-06 les documente donc comme
existants techniquement et explicitement hors contrat narratif V0.
