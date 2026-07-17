# NS-EVENT-V2-19 — Map Enter Production Dispatch Bridge V0 — Evidence Pack

## 1. Identité et verdict proposé

```text
Lot exact : NS-EVENT-V2-19 — Map Enter Production Dispatch Bridge V0
Phase : F2 — Runtime Source Bridges
Date : 2026-07-15
Branche : main
Baseline : 2f68328a38bf218c843e497940f8dd24a7a9c194
Verdict proposé du jalon : PASS
Verdict proposé de la phase F2 : IN_PROGRESS
Prochain jalon : NS-EVENT-V2-20 — Entity Interaction Production Dispatch Bridge V0
Roadmap modifiée : non
Git write (add/commit/push/branch) : aucun
```

Le jalon V2-19 peut être proposé `PASS`. Il branche la seule source
`mapEnter` sur l'autorité F1, avec une activation unique et une raison explicite
par boot, warp, connection ou restauration. La phase F2 ne peut pas être close :
les bridges `entityInteract`, `triggerEnter` et `outcomeReceived` restent les
jalons V2-20 à V2-22.

## 2. Résumé exécutif

Le runtime dispose maintenant d'un contrat `MapActivation` explicite. Une
activation n'est installée qu'après un boot cohérent ou une transition réussie,
puis le bridge produit au maximum une occurrence canonique
`NarrativeEventSourceRef.mapEnter(mapId)`. Le même chemin arbitre Event V2 et
Scenario legacy : un claim valide mais inéligible ne réactive jamais le fallback.

Les quatre raisons ratifiées par ADR-EV2-015 sont prises en charge :

| Chemin | Raison | Point d'émission | Échec / rollback |
|---|---|---|---|
| démarrage normal ou seed de démonstration | `initialBoot` | monde monté, phase overworld, activation installée | aucune occurrence si `onLoad` échoue avant installation |
| warp | `warp` | swap map et placement joueur terminés | zéro si cible invalide, preload/load ou swap échoue |
| connection | `connection` | transition et éventuelle animation d'entrée terminées | zéro si entrée bloquée ou transition échoue |
| vraie save versionnée ou `loadGame` | `saveRestore` | état/map/joueur/NPC/occupancy/overworld cohérents | zéro avant activation ; résultat `false` si autorité/outbox échoue |

Une restauration sur la même map émet bien un `mapEnter saveRestore`. Les
deliveries outcome F1 déjà pending sont drainées FIFO avant cette occurrence.
Si une delivery provoque une autre activation, l'ancien `mapEnter` devient
`stale` et la nouvelle activation émet sa propre raison. Le whiteout même-map ne
fabrique aucune activation supplémentaire.

Le boot ne bloque plus le lifecycle Flame sur une Scene interactive :
`onLoad()` se termine, le dispatch reste in-flight et l'input overworld est
interlocké jusqu'à la fin. Les dialogues et combats déjà ouverts continuent à
recevoir leur input. Les tests historiques qui simulaient un input dès le retour
de `onLoad` attendent désormais explicitement cette frontière asynchrone.

## 3. Scope confirmé et non-objectifs

### Inclus

- contrat runtime `MapActivationReason` / `MapActivation` ;
- déduplication, staleness et résultat typé du bridge `mapEnter` ;
- composition réelle F1 dans `PlayableMapGame` ;
- snapshot d'autorité cohérent sur le manifest et le corpus de maps ;
- exécution de la Scene Event V2 avec commit transactionnel ;
- fallback Scenario legacy uniquement lorsque l'autorité l'autorise ;
- boot, warp, connection, restauration même-map et vraie save host ;
- drain FIFO de l'outbox restaurée avant `mapEnter saveRestore` ;
- interlocks contre transition/load/input concurrents ;
- non-régressions whiteout, P3, Scene V1 et interactions immédiates après boot.

### Volontairement hors scope

- V2-20 : aucun bridge Event V2 `entityInteract` ;
- V2-21 : aucun bridge Event V2 `triggerEnter` ;
- V2-22 : aucun bridge général live `outcomeReceived` ni saga complète de
  reentrancy ; le code outcome présent est uniquement le seam de restauration
  exigé par ADR-EV2-015 ;
- FG-014 : aucun rollback transactionnel complet de la phase destructive de
  `loadGame` ;
- aucune modification de schema core, d'authoring editor ou de roadmap ;
- aucune clôture de FG-082, FG-086 ou FG-088 ; ils restent `TODO`.

## 4. Audit initial

### 4.1 État Git initial

```text
pwd : /Users/karim/Project/pokemonProject
branch : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
origin/main : 2f68328a38bf218c843e497940f8dd24a7a9c194
git status --short --untracked-files=all : <empty>
git diff : <empty>
```

### 4.2 Documents et preuves lus

- `AGENTS.md` et `codex_rule.md` ;
- `pokemap_roadmap_mecaniques_fangame.md` ;
- `MVP Selbrume/road_map_event_builder_v2.md`, section Phase F2 / V2-19 ;
- `MVP Selbrume/event_builder_v2_architecture_decisions.md`, en particulier
  ADR-EV2-013, ADR-EV2-014 et ADR-EV2-015 ;
- clôtures et Evidence Packs des phases E, E-bis, F1-PREREQ et F1 ;
- historique Git jusqu'à `2f68328a feat(event-v2): close NS-EVENT-V2 Phase F1` ;
- implémentations F1 de l'autorité, du coordinator, des transactions, de
  l'activity gate et de l'outbox ;
- chemins runtime existants `onLoad`, warp, connection, `loadGame`, whiteout,
  Scenario mapEnter et Scene host callbacks ;
- host de lancement et distinction save versionnée / override / demo seed ;
- tests runtime P3, input, whiteout, Scene V1, save/load et host smokes.

Le serveur documentaire Flame attendu n'a pas fourni de résultat exploitable.
L'audit a donc vérifié la version installée (`flame ^1.35.0`) et réutilisé les
patterns lifecycle déjà présents dans le repo, sans inventer d'API Flame.

### 4.3 Constat avant changement

- boot, warp et connection appelaient directement le Scenario legacy
  `mapEnter` ;
- `loadGame` restaurait sans occurrence équivalente ;
- aucune identité d'activation ne permettait de dédupliquer ou d'invalider une
  occurrence devenue stale ;
- la save host était représentée par `SaveData`, comme les seeds manuels, donc
  `saveData != null` ne pouvait pas déterminer honnêtement `saveRestore` ;
- F1 fournissait déjà l'autorité, la progression, les transactions, l'outbox et
  les gates nécessaires ; V2-19 devait les composer, pas les réimplémenter ;
- la phase destructive de `loadGame` était déjà documentée non transactionnelle
  et appartient à FG-014.

### 4.4 Risques identifiés au Gate 0

- double boot/load ;
- mapEnter émis avant une transition réellement terminée ;
- fallback legacy malgré un claim inéligible ;
- outcome pending livré après mapEnter ou dans le désordre ;
- course load/warp/connection pendant un dispatch asynchrone ;
- deadlock de `onLoad` sur dialogue ou combat interactif ;
- overwrite d'un write-back combat par le snapshot Scene pré-combat ;
- tests historiques supposant implicitement un mapEnter synchrone.

## 5. Contrats et décisions d'implémentation

### 5.1 Identité d'activation

`MapActivation` contient un `activationId`, un `mapId` et une raison parmi les
quatre valeurs ADR. Son occurrence Event V2 ne contient que la source canonique
`mapEnter(mapId)` : la raison reste une métadonnée runtime et ne pollue pas le
contrat domaine F1.

### 5.2 Déduplication et staleness

Le bridge claim l'identité avant son premier `await`. Un second appel concurrent
sur la même activation retourne `Duplicate`. Des checks de staleness encadrent
chaque frontière asynchrone : transaction initiale, pre-hook restore, lecture
outbox, préparation d'autorité, Scene et fallback. Le set des IDs claimés est
borné à l'activation courante.

### 5.3 Autorité unique et fallback

Le bridge construit le coordinator F1 avec le snapshot runtime validé. Les
résultats `handled`, `claimedButIneligible`, `noMatch`, `failed`, `cancelled`,
`authorityBlocked` sont traduits sans second chemin concurrent. Le fallback
Scenario n'est exécuté que pour `noMatch` avec `legacyFallbackAllowed == true`.

### 5.4 Restauration et outbox

Pour `saveRestore`, le bridge synchronise d'abord l'état runtime dans la
transaction F1, draine l'outbox réelle FIFO, récupère l'état commité, puis
prépare le `mapEnter`. Un Scenario outcome restauré peut demander un
`transitionMap` : le runtime consomme précisément cette requête, installe la
nouvelle activation warp et laisse le mapEnter restore précédent devenir stale.

`loadGame()` acquiert son lock avant son premier `await`. Les inputs overworld,
warps et connections sont bloqués tant que le load ou un dispatch d'activation
est in-flight. Un résultat `Failed` ou `AuthorityBlocked` fait retourner `false`
et conserve une delivery retryable pending.

### 5.5 Scene, conséquences et write-back host

Les conséquences Event V2 sont bufferisées jusqu'au succès de la Scene, puis
appliquées au `GameState` host le plus récent. Cela conserve les PV, flags,
récompenses et métadonnées écrits par un combat. Un conflit d'état initial échoue
avant tout callback host.

La critique finale a trouvé que le refactor des callbacks Scene capturait un
`GameState` fixe pour les conditions V1. Le correctif final passe une closure
`GameState Function()` et lit `_gameState` à chaque branche, préservant les
write-backs dialogue/combat pour V1 comme V2.

### 5.6 Lifecycle du boot

Le dispatch boot est programmé après `super.onLoad()`, sans être attendu. Cela
évite qu'un dialogue ou combat Event V2 bloque le montage du `GameWidget`. Le
dispatch est immédiatement enregistré in-flight ; le runtime bloque seulement
les actions overworld concurrentes, pas les inputs du dialogue/combat actif.

### 5.7 Sélection host de la raison

Le host calcule la save sélectionnée une fois. Une save versionnée réellement
sélectionnée utilise `saveRestore`. Un override manuel ou seed de démonstration
reste `initialBoot`, même s'il est transporté par un objet `SaveData`. Aucun
heuristique `saveData != null` n'est utilisé.

## 6. Verdicts des sub-agents et passes contradictoires

| Passe | Verdict initial | Verdict final | Signal utile |
|---|---|---|---|
| Audit / Architecture | BLOCKED | PASS | ambiguïtés restore/seed/outbox résolues par ADR-EV2-015 : vraie save=`saveRestore`, seed=`initialBoot`, FIFO avant mapEnter, activation stale invalidée |
| Implémentation bridge | RED puis GREEN | PASS | bridge typé, déduplication, staleness, authority modes et outbox ; tests ciblés `+14` |
| Tests / intégration runtime | plusieurs races trouvées | GREEN | interlocks connection/load, transition outcome restaurée, boot interactif, failure outbox ; matrice `+64` |
| Review de spec | FAIL intermédiaire | PASS | courses activation/load et fallback transitionMap corrigées ; matrice raisons/échecs conforme |
| Review qualité | FAIL (3 findings) | QUALITY PASS | deadlock boot Scene, perte write-back combat et load faussement réussi corrigés ; aucun P0-P2 restant |
| Build / Validation | FAIL initial | BUILD / VALIDATION PASS | 6 runtime + 1 host supposaient le boot synchrone ; fixtures corrigées puis full runtime/host/build verts |
| Critique finale | P2 détecté | CRITIQUE PASS | condition Scene V1 lisait un snapshot figé ; closure dynamique ajoutée ; aucun P0-P2 restant |

La passe finale n'a pas masqué les échecs intermédiaires : ils sont conservés
ci-dessous avec leur correction et leur rerun.

## 7. Inventaire complet des fichiers

### 7.1 Fichiers de production créés

| Fichier | Lignes | Symboles / rôle |
|---|---:|---|
| `packages/map_runtime/lib/src/application/map_activation.dart` | 48 | `MapActivationReason`, `MapActivation`, occurrence canonique |
| `packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart` | 279 | résultats typés, `MapEnterProductionDispatchBridge`, dédup/stale/authority/fallback |
| `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart` | 152 | snapshot manifest/maps, catalog, facts et claims validés |
| `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart` | 111 | exécution Scene, conséquences bufferisées, rebase post-host |

### 7.2 Tests créés

| Fichier | Lignes | Couverture principale |
|---|---:|---|
| `packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart` | 45 | `legacyOnly` ne charge pas le corpus maps |
| `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart` | 882 | 14 tests : IDs, 4 raisons, concurrence, modes, claims, stale, fail-closed, Scene, FIFO restore |
| `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart` | 203 | conservation write-back combat + conséquences ; conflit initial fail-closed |
| `packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart` | 466 | boot V2, claim inéligible, dialogue interactif après onLoad |
| `packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart` | 177 | vraie restauration initiale map/pose puis une occurrence |
| `packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart` | 902 | races connection/load, outcome→warp stale, échec outbox retryable |
| `packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart` | 207 | load même-map et cible absente |
| `packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart` | 315 | outcomes A/B FIFO avant mapEnter C |

Le contenu complet de ces douze fichiers créés figure en annexe 16. Le présent
rapport, lui-même nouveau, est son propre contenu complet et n'est pas dupliqué
récursivement.

### 7.3 Fichiers modifiés et zones précises

| Fichier | Zones modifiées | Raison / impact |
|---|---|---|
| `examples/playable_runtime_host/lib/main.dart` | `_ProjectLoaderPageState` lors de la création de `PlayableMapGame` | calcule `selectedLaunchSave` une fois et passe la raison explicite |
| `examples/playable_runtime_host/lib/src/runtime_launch_save.dart` | imports et `resolveRuntimeHostInitialMapActivationReason` | distingue vraie save versionnée des overrides/seeds |
| `examples/playable_runtime_host/test/runtime_launch_save_test.dart` | groupe resolver | prouve `saveRestore` seulement pour la save réellement sélectionnée |
| `examples/playable_runtime_host/test/p3_narrative_smoke_slice_test.dart` | après `onLoad` + helper `_waitForInitialMapActivation` | adapte le smoke à la frontière boot asynchrone avant lecture du flag |
| `packages/map_runtime/lib/map_runtime.dart` | exports application | rend publics activation, bridge et résultats typés |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | imports, constructeur, composition F1, IDs, snapshot/Scene/outbox, debug getters, `onLoad`, input/update interlocks, transitionMap, callbacks Scene, `loadGame`, warp, connection | branche le bridge production, garantit l'ordre et empêche les courses/doubles dispatchs |
| `packages/map_runtime/test/playable_map_game_input_test.dart` | groupe warp/connection et fixtures | raisons `warp`/`connection`, zéro activation sur échec, attente boot |
| `packages/map_runtime/test/playable_map_game_whiteout_lite_test.dart` | attente initiale + assertions compteur/raison | prouve qu'un whiteout même-map n'émet pas un second mapEnter |
| `packages/map_runtime/test/item_pickup_give_item_readiness_test.dart` | test interaction playable + helper d'attente | non-régression input immédiat après boot asynchrone |
| `packages/map_runtime/test/ns_event_34_scene_target_handoff_smoke_test.dart` | setup runtime + helper d'attente | non-régression Scene target V1 après boot |
| `packages/map_runtime/test/ns_event_35_trigger_variants_lifecycle_gate_test.dart` | `_loadRuntimeCase` + helper d'attente | non-régression interaction/mouvement/lifecycle NS-EVENT-35 |

#### Découpage précis de `PlayableMapGame`

```text
lignes ~140-220     : paramètres reason/gate/test seam et champs de composition
lignes ~319-599     : activation IDs, snapshot authority, Scene, bridge, outbox restore
lignes ~690-710     : getters de preuve activation/load
lignes ~1775-1884   : boot initialBoot/saveRestore et dispatch post-onLoad
lignes ~2021-2189   : interlocks input/update et installation connection animée
lignes ~3255-3300   : transitionMap runtime-owned autorisée pendant restore
lignes ~5625-5970   : callbacks Scene V1/V2 et GameState dynamique
lignes ~6935-7084   : lock load, restauration cohérente et résultat du bridge
lignes ~7209-7410   : warp, rollback et activation après succès
lignes ~7560-7708   : connection, rollback et activation après succès
lignes ~9208-9217   : activation attachée à l'animation d'entrée connection
```

## 8. Matrice de comportement prouvée

| Cas | Résultat attendu | Preuve |
|---|---|---|
| boot legacy | un fallback legacy | bridge + P3 + input |
| boot V2 eligible | Scene V2, aucun legacy | boot integration |
| boot V2 dialogue | `onLoad` termine, dialogue interactif, commit après input | boot integration |
| dualRead claim inéligible | aucun fallback | bridge + boot integration |
| warp réussi | une activation `warp` | input suite |
| warp invalide | zéro nouvelle activation | input suite |
| connection réussie | une activation `connection` | input suite |
| connection bloquée | zéro nouvelle activation | input suite |
| load même map | une activation `saveRestore` | map-enter integration |
| vraie save host | une seule raison `saveRestore` | initial restore + resolver host |
| save absente / map absente | zéro activation terminée | integration négative |
| outbox A puis B puis mapEnter C | A→B→C FIFO | outbox integration |
| outcome restore provoque warp | restore stale, nouvelle activation warp | interlock integration |
| échec authority/outbox retry | load false, delivery pending, métriques inchangées | interlock négatif |
| whiteout même map | compteur inchangé | whiteout lite |
| Scene combat puis conséquence | write-back combat conservé | scene execution |
| conflit Scene initial | aucun callback host | scene execution |
| activation concurrente dupliquée | une seule exécution | bridge concurrency |

## 9. TDD et commandes ciblées

### 9.1 Baseline avant implémentation

```text
cd packages/map_runtime && flutter test \
  test/narrative_event_legacy_runtime_characterization_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/playable_map_game_input_test.dart
Résultat : exit 0, +37: All tests passed!
```

### 9.2 RED observés

- tests du bridge écrits avant production ;
- correction write-back Scene : exit 1, uniquement
  `No named parameter with the name 'currentGameState'` avant ajout du contrat ;
- première full suite : exit 1 avec six tests runtime et un host démontrant la
  nouvelle frontière boot non attendue par les fixtures.

### 9.3 Matrices GREEN ciblées

```text
cd packages/map_runtime && flutter test \
  test/narrative_event_runtime_snapshot_test.dart \
  test/narrative_map_enter_production_dispatch_bridge_test.dart \
  test/narrative_scene_runtime_execution_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart \
  test/playable_map_game_initial_save_restore_activation_test.dart \
  test/playable_map_game_map_activation_interlock_test.dart \
  test/playable_map_game_map_enter_v2_integration_test.dart \
  test/playable_map_game_save_restore_outbox_integration_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/playable_map_game_input_test.dart
Résultat : exit 0, +64: All tests passed!

cd packages/map_runtime && flutter test \
  test/item_pickup_give_item_readiness_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
Résultat après adaptation de la frontière boot : exit 0, +18: All tests passed!

cd examples/playable_runtime_host && \
  flutter test test/p3_narrative_smoke_slice_test.dart
Résultat après adaptation : exit 0, +1: All tests passed!

cd packages/map_runtime && flutter test \
  test/narrative_scene_runtime_execution_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart
Résultat après closure GameState dynamique : exit 0, +6: All tests passed!
```

### 9.4 Analyses ciblées

```text
flutter analyze [12 fichiers runtime V2-19 ciblés]
Résultat : exit 0, No issues found! (ran in 3.6s)

cd packages/map_runtime && flutter analyze \
  test/item_pickup_give_item_readiness_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/ns_event_35_trigger_variants_lifecycle_gate_test.dart
Résultat : exit 0, No issues found! (ran in 7.2s)

cd examples/playable_runtime_host && \
  flutter analyze test/p3_narrative_smoke_slice_test.dart
Résultat : exit 0, No issues found! (ran in 12.3s)

cd packages/map_runtime && flutter analyze \
  lib/src/presentation/flame/playable_map_game.dart \
  test/narrative_scene_runtime_execution_test.dart \
  test/ns_event_34_scene_target_handoff_smoke_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart
Résultat : exit 0, No issues found! (ran in 10.1s)
```

## 10. Échec de validation intermédiaire et correction

La première passe Build / Validation a honnêtement conclu `FAIL` :

```text
packages/map_runtime: flutter test
exit 1, +1669 ~1 -6

examples/playable_runtime_host: flutter test
exit 1, +49 -1
```

Échecs reproduits : pickup objet, NS-EVENT-34, quatre cas NS-EVENT-35 et P3
host. Tous simulaient une interaction ou lisaient le flag immédiatement après
`await game.onLoad()` alors que l'interlock map activation était encore actif.
Le runtime était volontairement asynchrone pour ne pas deadlocker les Scenes
interactives. Les fixtures ont donc été corrigées pour attendre explicitement
`debugIsMapActivationDispatchInFlight == false`. Aucun contournement production
n'a été ajouté.

La critique finale a ensuite trouvé le snapshot condition Scene V1 figé. La
validation complète précédemment verte a été invalidée, le callback a été
corrigé, puis les sept commandes ont été relancées depuis zéro.

## 11. Validation complète finale

| Répertoire | Commande exacte | Exit | Résultat exact utile |
|---|---|---:|---|
| `packages/map_runtime` | `flutter test` | 0 | `+1675 ~1: All tests passed!` |
| `packages/map_runtime` | `flutter analyze --no-fatal-infos` | 0 | 347 diagnostics info existants, aucune erreur |
| `packages/map_runtime` | `flutter test test/phase_a_golden_battle_slice_smoke_test.dart` | 0 | `+3: All tests passed!` |
| `examples/playable_runtime_host` | `flutter test` | 0 | `+50: All tests passed!` |
| `examples/playable_runtime_host` | `flutter analyze --no-fatal-infos` | 0 | 1 diagnostic info existant, aucune erreur |
| `examples/playable_runtime_host` | `flutter test test/phase_a_golden_slice_launch_test.dart` | 0 | `+1: All tests passed!` |
| `examples/playable_runtime_host` | `flutter build macos --debug` | 0 | `build/macos/Build/Products/Debug/playable_runtime_host.app` construit |

Le `~1` runtime est un test explicitement skipped par la suite ; il ne représente
pas un échec. Les analyses ciblées des fichiers modifiés sont à zéro issue. Les
diagnostics info globaux sont conservés et n'ont pas été nettoyés hors scope.

## 12. Compatibilité, rollback et observabilité

- `legacyOnly` reste le rollback fonctionnel prévu : le même bridge autorise le
  fallback Scenario sans double dispatch ;
- `dualRead` et `v2Only` restent arbitrés par l'autorité F1 et les claims ;
- aucun schema persistant nouveau n'est introduit par V2-19 ;
- les logs `[event_v2] mapEnter` portent activation, map, raison et type de
  résultat ;
- les compteurs/getters de test n'incrémentent que pour un résultat réellement
  terminé (`LegacyFallback`, `V2Handled`, `ClaimedIneligible`, `NoFallback`) ;
- `Failed`, `AuthorityBlocked`, `Stale` et `Duplicate` ne mentent pas en étant
  comptés comme activations dispatchées ;
- le rollback structurel du diff consiste à retirer les quatre fichiers
  application, les exports et la composition `PlayableMapGame`, puis restaurer
  les appels legacy directs. Aucune opération Git de rollback n'a été exécutée.

## 13. Auto-critique finale

### Points solides

- l'identité d'activation rend les courses visibles et testables ;
- l'autorité V2/legacy reste unique ;
- l'ordre saveRestore/outbox/mapEnter est prouvé avec états A/B/C ;
- les échecs et les activations stale sont fail-closed ;
- les reviews ont réellement trouvé quatre défauts production et sept
  régressions de fixtures avant la clôture ;
- full tests, analyzes, smokes et build sont frais après le dernier correctif.

### Ce qui pourrait être amélioré plus tard

- le snapshot charge et canonicalise tout le corpus maps hors `legacyOnly` ;
  un cache/version fingerprint plus fin pourra devenir nécessaire sur de gros
  projets ;
- `beforeNarrativeAuthorityPreparation` et les getters debug exposent des seams
  publics marqués `@visibleForTesting` ; une boundary test dédiée réduirait la
  surface ;
- un repository injecté ne partage le gate du runtime que si l'appelant injecte
  aussi le même `NarrativeRuntimeActivityGate` ;
- le rebase combat est testé au niveau contrat, pas encore avec un overlay de
  combat production complet dans une Golden Slice Event V2 ;
- le boot détaché ne modélise pas l'annulation lors d'une destruction très
  précoce du composant ;
- un input envoyé dans la très courte fenêtre boot in-flight est volontairement
  consommé/bloqué, pas mis en queue.

## 14. Risques et limites restantes

1. **FG-014 — rollback load destructif.** Après le début de la phase destructive,
   une erreur peut laisser l'état restauré en mémoire malgré `loadGame() == false`.
   V2-19 ne prétend pas corriger ce contrat.
2. **V2-22 — atomicité hosted battle complète.** Le write-back combat est
   conservé sur succès ; l'abandon total des effets host si la Scene parente
   échoue ensuite n'est pas garanti par ce lot.
3. **Outcome bridge.** Le drain restore satisfait ADR-EV2-015 mais ne ferme pas
   le bridge général `outcomeReceived`.
4. **Performance snapshot.** Le coût mémoire/démarrage doit être mesuré sur un
   projet multi-maps important avant release.
5. **Gate repository custom.** Une composition custom incohérente peut contourner
   le partage du gate ; la composition standard est correcte.

## 15. État Git final avant remise

```text
Branche : main
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Roadmap : non modifiée
Git write : aucun
Fichiers tracked modifiés : 11
Fichiers source/test créés : 12
Rapport créé : 1
git diff --check : exit 0, aucun output
```

L'état détaillé final est volontairement sale : il contient uniquement le lot
non commité et son Evidence Pack. Aucun fichier utilisateur préexistant n'était
modifié au Gate 0 et aucun `git add`, commit, push, branch, stash, reset, restore
ou checkout n'a été exécuté.

## 16. Contenu complet des fichiers créés

Les sections suivantes reproduisent intégralement les douze fichiers source et
test créés par le lot, conformément à `codex_rule.md`.

Une extraction `awk` de chaque fence suivie d'un `diff -u` contre son fichier
canonique a retourné exit 0 pour les douze annexes.

### 16.1 `packages/map_runtime/lib/src/application/map_activation.dart`

````dart
import 'package:map_core/map_core.dart';

/// Runtime-only reason for a successfully completed map activation.
///
/// This metadata deliberately stays outside [NarrativeEventOccurrence]: Event
/// V2 source identity is only the canonical map-enter source.
enum MapActivationReason {
  initialBoot,
  warp,
  connection,
  saveRestore,
}

/// Identifies one completed runtime activation of a map.
final class MapActivation {
  MapActivation({
    required String activationId,
    required String mapId,
    required this.reason,
  })  : activationId = _requireNonBlank(activationId, 'activationId'),
        mapId = _requireNonBlank(mapId, 'mapId');

  final String activationId;
  final String mapId;
  final MapActivationReason reason;

  NarrativeEventOccurrence get occurrence => NarrativeEventOccurrence(
        source: NarrativeEventSourceRef.mapEnter(mapId),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapActivation &&
          other.activationId == activationId &&
          other.mapId == mapId &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(activationId, mapId, reason);
}

String _requireNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return value;
}
````

### 16.2 `packages/map_runtime/lib/src/application/map_enter_production_dispatch_bridge.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'map_activation.dart';

sealed class MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchResult(this.activation);

  final MapActivation activation;
}

final class MapEnterProductionDispatchLegacyFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchLegacyFallback(super.activation);
}

final class MapEnterProductionDispatchDuplicate
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchDuplicate(super.activation);
}

final class MapEnterProductionDispatchNoFallback
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchNoFallback(
    super.activation, [
    this.reason,
  ]);

  final Object? reason;
}

final class MapEnterProductionDispatchV2Handled
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchV2Handled(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionSucceeded execution;
}

final class MapEnterProductionDispatchClaimedIneligible
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchClaimedIneligible(
    super.activation,
    this.execution,
  );

  final NarrativeEventExecutionClaimedButIneligible execution;
}

final class MapEnterProductionDispatchStale
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchStale(super.activation);
}

final class MapEnterProductionDispatchAuthorityBlocked
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchAuthorityBlocked(
    super.activation,
    this.authority,
  );

  final NarrativeEventDispatchAuthorityBlocked authority;
}

final class MapEnterProductionDispatchFailed
    extends MapEnterProductionDispatchResult {
  const MapEnterProductionDispatchFailed(
    super.activation,
    this.failure, [
    this.stackTrace,
  ]);

  final Object failure;
  final StackTrace? stackTrace;
}

/// Application boundary between completed map activations and Event V2.
///
/// V2-19 owns map-enter dispatch and runtime activation deduplication. Outcome
/// reentrancy stays in V2-22, while save/load orchestration remains FG-014; the
/// save-restore callback here is only the ordering seam between those lots.
final class MapEnterProductionDispatchBridge {
  MapEnterProductionDispatchBridge({
    required NarrativeEventStateTransactions stateTransactions,
    required GameState Function() currentGameState,
    required void Function(GameState gameState) onGameStateCommitted,
    required Future<NarrativeEventDispatchAuthorityPreparation> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
    ) prepareAuthority,
    required NarrativeSceneExecutionCallback executeScene,
    required Future<void> Function(
      MapActivation activation,
      NarrativeEventOccurrence occurrence,
      GameState gameState,
    ) legacyFallback,
    required NarrativeEventActivityPort activityPort,
    required Future<void> Function(MapActivation activation)
        beforeSaveRestoreDispatch,
    required bool Function(String activationId) isCurrentActivation,
    required NarrativeExecutionIdFactory executionIdFactory,
    required NarrativeCorrelationIdFactory correlationIdFactory,
    required NarrativeDeliveryIdFactory deliveryIdFactory,
  })  : _stateTransactions = stateTransactions,
        _currentGameState = currentGameState,
        _onGameStateCommitted = onGameStateCommitted,
        _prepareAuthority = prepareAuthority,
        _executeScene = executeScene,
        _legacyFallback = legacyFallback,
        _activityPort = activityPort,
        _beforeSaveRestoreDispatch = beforeSaveRestoreDispatch,
        _isCurrentActivation = isCurrentActivation,
        _executionIdFactory = executionIdFactory,
        _correlationIdFactory = correlationIdFactory,
        _deliveryIdFactory = deliveryIdFactory;

  final NarrativeEventStateTransactions _stateTransactions;
  final GameState Function() _currentGameState;
  final void Function(GameState gameState) _onGameStateCommitted;
  final Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) _prepareAuthority;
  final NarrativeSceneExecutionCallback _executeScene;
  final Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) _legacyFallback;
  final NarrativeEventActivityPort _activityPort;
  final Future<void> Function(MapActivation activation)
      _beforeSaveRestoreDispatch;
  final bool Function(String activationId) _isCurrentActivation;
  final NarrativeExecutionIdFactory _executionIdFactory;
  final NarrativeCorrelationIdFactory _correlationIdFactory;
  final NarrativeDeliveryIdFactory _deliveryIdFactory;

  // add() happens before the first await, so concurrent callers in the same
  // isolate cannot both claim the same completed activation.
  final Set<String> _claimedActivationIds = <String>{};

  Future<MapEnterProductionDispatchResult> dispatchCompletedActivation(
    MapActivation activation,
  ) async {
    late final String activationId;
    late final NarrativeEventOccurrence occurrence;
    try {
      activationId = activation.activationId;
      occurrence = activation.occurrence;

      // Only the current activation needs to stay claimed. This keeps the set
      // bounded across map transitions while retaining the current ID so a
      // concurrent or repeated dispatch remains a duplicate.
      _claimedActivationIds.removeWhere(
        (claimedId) => !_isCurrentActivation(claimedId),
      );
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (!_claimedActivationIds.add(activationId)) {
        return MapEnterProductionDispatchDuplicate(activation);
      }

      // The runtime GameState is authoritative at activation completion. Put
      // that exact snapshot behind the serialized F1 transaction boundary
      // before planning or executing Event V2.
      await _stateTransactions.transact<GameState>((_) {
        final current = _currentGameState();
        return NarrativeEventStateTransaction.commit(current, current);
      });
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (activation.reason == MapActivationReason.saveRestore) {
        await _beforeSaveRestoreDispatch(activation);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        final latestGameState = await _stateTransactions.read();
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
        _onGameStateCommitted(latestGameState);
        if (!_isCurrentActivation(activationId)) {
          return _stale(activation, activationId);
        }
      }

      final preparation = await _prepareAuthority(activation, occurrence);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      if (preparation is NarrativeEventDispatchAuthorityBlocked) {
        return MapEnterProductionDispatchAuthorityBlocked(
          activation,
          preparation,
        );
      }
      final authority = preparation as NarrativeEventDispatchAuthorityReady;
      final coordinator = NarrativeEventExecutionCoordinator(
        stateTransactions: _stateTransactions,
        planner: NarrativeEventDispatchPlanner(),
        executeScene: (request) async {
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale before Scene execution.',
            );
          }
          final result = await _executeScene(request);
          if (!_isCurrentActivation(activationId)) {
            return NarrativeSceneExecutionResult.cancelled(
              'Map activation became stale during Scene execution.',
            );
          }
          return result;
        },
        activityPort: _activityPort,
        executionIdFactory: _executionIdFactory,
        correlationIdFactory: _correlationIdFactory,
        deliveryIdFactory: _deliveryIdFactory,
      );
      final execution = await coordinator.execute(authority: authority);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }

      if (execution is NarrativeEventExecutionSucceeded) {
        _onGameStateCommitted(execution.updatedGameState);
        return MapEnterProductionDispatchV2Handled(activation, execution);
      }
      if (execution is NarrativeEventExecutionClaimedButIneligible) {
        return MapEnterProductionDispatchClaimedIneligible(
          activation,
          execution,
        );
      }
      if (execution is NarrativeEventExecutionFailed) {
        return MapEnterProductionDispatchFailed(
          activation,
          execution.failure,
          execution.failure.stackTrace,
        );
      }
      if (execution is NarrativeEventExecutionCancelled) {
        return MapEnterProductionDispatchNoFallback(activation, execution);
      }

      final noMatch = execution as NarrativeEventExecutionNoMatch;
      if (!noMatch.legacyFallbackAllowed) {
        return MapEnterProductionDispatchNoFallback(activation, noMatch);
      }

      final gameState = await _stateTransactions.read();
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      await _legacyFallback(activation, occurrence, gameState);
      if (!_isCurrentActivation(activationId)) {
        return _stale(activation, activationId);
      }
      return MapEnterProductionDispatchLegacyFallback(activation);
    } catch (error, stackTrace) {
      // Preparation, pre-hooks, callbacks and legacy failures all stay closed:
      // no secondary dispatch path is attempted after an infrastructure error.
      return MapEnterProductionDispatchFailed(activation, error, stackTrace);
    }
  }

  MapEnterProductionDispatchStale _stale(
    MapActivation activation,
    String activationId,
  ) {
    _claimedActivationIds.remove(activationId);
    return MapEnterProductionDispatchStale(activation);
  }
}
````

### 16.3 `packages/map_runtime/lib/src/application/narrative_event_runtime_snapshot.dart`

````dart
import 'package:map_core/map_core.dart';

/// Immutable Event V2 runtime view built from one project/map corpus.
///
/// The runtime deliberately refuses to combine maps loaded from a different
/// manifest revision. That keeps the registry, catalog and legacy-claim
/// evidence on the same authority snapshot.
final class NarrativeEventRuntimeSnapshot {
  const NarrativeEventRuntimeSnapshot._({
    required this.project,
    required this.mapsById,
    required this.registryResult,
    required this.factResolver,
    required this.projectCatalog,
    required this.legacyClaimIndex,
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final EventRegistryDecodeResult registryResult;
  final NarrativeFactRuntimeResolver factResolver;
  final NarrativeEventProjectCatalog projectCatalog;
  final ValidatedLegacyClaimIndex legacyClaimIndex;

  static Future<NarrativeEventRuntimeSnapshot> build({
    required ProjectManifest project,
    required Future<({ProjectManifest project, MapData map})> Function(
      String mapId,
    ) loadMap,
  }) async {
    final registry = project.eventRegistry ??
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: const [],
          legacyClaims: const [],
        );
    final structuralClaimIndex = buildValidatedLegacyClaimIndex(registry);
    final registryResult = project.eventRegistry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry);
    final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
    if (registry.mode == EventSystemMode.legacyOnly) {
      return NarrativeEventRuntimeSnapshot._(
        project: project,
        mapsById: const <String, MapData>{},
        registryResult: registryResult,
        factResolver: factResolver,
        projectCatalog: buildNarrativeEventProjectCatalog(
          project: project,
          maps: const <MapData>[],
        ),
        legacyClaimIndex: structuralClaimIndex,
      );
    }
    final projectFingerprint = canonicalizeNarrativeEventJson(project.toJson());
    final mapsById = <String, MapData>{};

    for (final mapEntry in project.maps) {
      if (mapsById.containsKey(mapEntry.id)) {
        throw StateError(
          'Event V2 runtime snapshot contains duplicate map id '
          '"${mapEntry.id}".',
        );
      }
      final loaded = await loadMap(mapEntry.id);
      if (canonicalizeNarrativeEventJson(loaded.project.toJson()) !=
          projectFingerprint) {
        throw StateError(
          'Event V2 runtime snapshot changed while loading map '
          '"${mapEntry.id}".',
        );
      }
      if (loaded.map.id != mapEntry.id) {
        throw StateError(
          'Event V2 runtime snapshot expected map "${mapEntry.id}" but '
          'loaded "${loaded.map.id}".',
        );
      }
      mapsById[mapEntry.id] = loaded.map;
    }

    final legacyMapProjections = <LegacyMapEventProjection>[
      for (final map in mapsById.values)
        for (final event in map.events)
          projectLegacyMapEventReadOnly(
            mapId: map.id,
            map: map,
            event: event,
            claimIndex: structuralClaimIndex,
            rawEventJson: Map<String, Object?>.from(event.toJson()),
          ),
    ];
    final legacyScenarioProjections = <LegacyScenarioSourceProjection>[
      for (final scenario in project.scenarios)
        for (final node in scenario.nodes)
          if (isLegacyScenarioSourceNode(node))
            projectLegacyScenarioSourceReadOnly(
              scenario: scenario,
              node: node,
              scenes: project.scenes,
              claimIndex: structuralClaimIndex,
            ),
    ];
    final runtimeEvidence = LegacyClaimRuntimeEvidence(
      entries: [
        for (final projection in legacyMapProjections)
          if (projection.confirmedSource != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.confirmedSource!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
        for (final projection in legacyScenarioProjections)
          if (projection.source != null)
            LegacyClaimRuntimeEvidenceEntry(
              provenance: projection.provenance,
              source: projection.source!,
              sourceFingerprint: projection.sourceFingerprint,
            ),
      ],
    );
    final referencedOutcomes = <NarrativeOutcomeRef>[
      for (final projection in legacyScenarioProjections)
        if (projection.source != null)
          ...projection.source!.when(
            entityInteract: (_, __) => const <NarrativeOutcomeRef>[],
            triggerEnter: (_, __) => const <NarrativeOutcomeRef>[],
            mapEnter: (_) => const <NarrativeOutcomeRef>[],
            outcomeReceived: (outcome) => <NarrativeOutcomeRef>[outcome],
          ),
    ];
    final projectCatalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: mapsById.values.toList(growable: false),
      legacyProjections: legacyMapProjections,
      referencedOutcomes: referencedOutcomes,
    );

    return NarrativeEventRuntimeSnapshot._(
      project: project,
      mapsById: Map<String, MapData>.unmodifiable(mapsById),
      registryResult: registryResult,
      factResolver: factResolver,
      projectCatalog: projectCatalog,
      legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
        registry,
        runtimeEvidence: runtimeEvidence,
      ),
    );
  }
}
````

### 16.4 `packages/map_runtime/lib/src/application/narrative_scene_runtime_execution.dart`

````dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_runtime/scene_consequence_runtime_writer.dart';
import 'scene_runtime/scene_runtime_host_callbacks.dart';

/// Executes the configured Event V2 Scene against the coordinator snapshot.
///
/// Consequences are buffered until the Scene completes. A failed Scene never
/// leaks a partial GameState update to the F1 transaction coordinator.
Future<NarrativeSceneExecutionResult> executeNarrativeEventScene({
  required NarrativeSceneExecutionRequest request,
  required ProjectManifest project,
  required Map<String, MapData> mapsById,
  required GameState Function() currentGameState,
  required SceneRuntimeHostCallbacks callbacks,
  int maxSteps = 100,
}) async {
  if (currentGameState() != request.gameState) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has an initial GameState '
        'conflict.',
      ),
    );
  }

  final matchingScenes = project.scenes
      .where((scene) => scene.id == request.sceneId)
      .toList(growable: false);
  if (matchingScenes.length != 1) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        matchingScenes.isEmpty
            ? 'Event V2 Scene "${request.sceneId}" was not found.'
            : 'Event V2 Scene "${request.sceneId}" is ambiguous.',
      ),
    );
  }
  final scene = matchingScenes.single;
  final diagnostics = diagnoseSceneAgainstProject(
    scene,
    project,
    mapsById: mapsById,
  );
  if (diagnostics.hasErrors) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" has blocking diagnostics.',
      ),
    );
  }
  final planResult = buildSceneRuntimePlan(scene);
  if (!planResult.canBuild) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        'Event V2 Scene "${request.sceneId}" cannot build a runtime plan.',
      ),
    );
  }

  // Only Scene consequences are buffered for the coordinator transaction.
  // Host callbacks (battle/dialogue) own their runtime side effects; once the
  // Scene completes, those authoritative writes are kept by rebasing the
  // buffered consequences onto the latest host GameState.
  final pendingConsequences = <SceneConsequence>[];
  final execution = await SceneRuntimeExecutor(
    callbacks: callbacks.toExecutionCallbacks(
      applyConsequence: (consequence) {
        pendingConsequences.add(consequence);
        return 'completed';
      },
    ),
    maxSteps: maxSteps,
  ).execute(planResult.plan!);
  if (execution.status != SceneRuntimeExecutionStatus.completed) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        execution.message ??
            'Event V2 Scene "${request.sceneId}" failed during execution.',
      ),
    );
  }

  final writeResult = SceneConsequenceRuntimeWriter(
    project: project,
    mapsById: mapsById,
  ).applyAll(currentGameState(), pendingConsequences);
  if (!writeResult.success) {
    return NarrativeSceneExecutionResult.failed(
      StateError(
        writeResult.message ??
            'Event V2 Scene "${request.sceneId}" consequence commit failed.',
      ),
    );
  }

  final sceneOutcomeId = execution.sceneOutcomeId;
  return NarrativeSceneExecutionResult.completed(
    updatedGameState: writeResult.gameState,
    qualifiedOutcomes: sceneOutcomeId == null
        ? const <NarrativeOutcomeRef>[]
        : <NarrativeOutcomeRef>[
            NarrativeOutcomeRef(
              producerKind: NarrativeOutcomeProducerKind.scene,
              producerId: scene.id,
              outcomeId: sceneOutcomeId,
            ),
          ],
  );
}
````

### 16.5 `packages/map_runtime/test/narrative_event_runtime_snapshot_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';

void main() {
  test('legacyOnly snapshot never loads the project map corpus', () async {
    var loadCalls = 0;
    final project = ProjectManifest(
      name: 'Legacy-only lightweight snapshot',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_a',
          name: 'Map A',
          relativePath: 'maps/map_a.json',
        ),
        ProjectMapEntry(
          id: 'map_b',
          name: 'Map B',
          relativePath: 'maps/map_b.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
      surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    );

    final snapshot = await NarrativeEventRuntimeSnapshot.build(
      project: project,
      loadMap: (_) async {
        loadCalls++;
        throw StateError('legacyOnly must not load maps');
      },
    );

    expect(loadCalls, 0);
    expect(snapshot.mapsById, isEmpty);
    expect(snapshot.registryResult.registryOrNull?.mode,
        EventSystemMode.legacyOnly);
  });
}
````

### 16.6 `packages/map_runtime/test/narrative_map_enter_production_dispatch_bridge_test.dart`

````dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _executionId = 'evx_019abcde-0000-7000-8000-000000000002';
const _correlationId = 'corr_019abcde-0000-7000-8000-000000000003';
const _generatedDeliveryId = 'outd_019abcde-0000-7000-8000-000000000004';
const _firstPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000005';
const _secondPendingDeliveryId = 'outd_019abcde-0000-7000-8000-000000000006';
const _legacyFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('NS-EVENT-V2-19 map-enter production dispatch bridge', () {
    test('rejects empty and whitespace-only activation identities', () {
      for (final invalid in ['', ' ', '\t\n']) {
        expect(
          () => MapActivation(
            activationId: invalid,
            mapId: 'map',
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
        expect(
          () => MapActivation(
            activationId: 'activation-valid',
            mapId: invalid,
            reason: MapActivationReason.initialBoot,
          ),
          throwsArgumentError,
        );
      }
    });

    test('all activation reasons keep runtime metadata and deduplicate by id',
        () async {
      for (final reason in MapActivationReason.values) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        final legacyTrace = <MapActivation>[];
        final activation = MapActivation(
          activationId: 'activation-${reason.name}',
          mapId: 'map-${reason.name}',
          reason: reason,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          ),
          legacyFallback: (value, occurrence, gameState) async {
            expect(occurrence, value.occurrence);
            expect(gameState.saveId, 'save');
            legacyTrace.add(value);
          },
          isCurrentActivation: (value) => value == activation.activationId,
        );

        expect(
          activation.occurrence,
          NarrativeEventOccurrence(
            source: NarrativeEventSourceRef.mapEnter(activation.mapId),
          ),
        );

        final first = await bridge.dispatchCompletedActivation(activation);
        final duplicate = await bridge.dispatchCompletedActivation(activation);

        expect(first, isA<MapEnterProductionDispatchLegacyFallback>());
        expect(duplicate, isA<MapEnterProductionDispatchDuplicate>());
        expect(legacyTrace, [activation]);
      }
    });

    test('concurrent dispatches of one current activation execute once',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-concurrent',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final firstDispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      final secondResult = await bridge.dispatchCompletedActivation(activation);
      releaseLegacy.complete();
      final firstResult = await firstDispatch;

      expect(firstResult, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(secondResult, isA<MapEnterProductionDispatchDuplicate>());
      expect(legacyCalls, 1);
    });

    test('legacyOnly falls back while v2Only no-match stays closed', () async {
      for (final testCase in <({
        EventSystemMode mode,
        int expectedLegacyCalls,
        Type expectedResult,
      })>[
        (
          mode: EventSystemMode.legacyOnly,
          expectedLegacyCalls: 1,
          expectedResult: MapEnterProductionDispatchLegacyFallback,
        ),
        (
          mode: EventSystemMode.v2Only,
          expectedLegacyCalls: 0,
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-authority-mode',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final registry = _registry(testCase.mode);
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(legacyCalls, testCase.expectedLegacyCalls);
      }
    });

    test('dualRead handled event executes V2 and never invokes legacy',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-dual-read-handled',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
          legacyClaimIndex: buildValidatedLegacyClaimIndex(registry),
        ),
        executeScene: (request) async {
          v2Calls++;
          expect(request.eventId, _eventId);
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchV2Handled>());
      expect(v2Calls, 1);
      expect(legacyCalls, 0);
    });

    test('stale activation during Scene rolls back its candidate state',
        () async {
      const originalState = GameState(
        saveId: 'save',
        metadata: {'runtime': 'original'},
      );
      var currentState = originalState;
      final transactions = NarrativeEventStateTransactions(currentState);
      final sceneStarted = Completer<void>();
      final releaseScene = Completer<void>();
      var currentActivationId = 'activation-stale-scene';
      var committedCalls = 0;
      var legacyCalls = 0;
      final source = NarrativeEventSourceRef.mapEnter('map');
      final registry = _registry(
        EventSystemMode.v2Only,
        records: [_record(source)],
      );
      final activation = MapActivation(
        activationId: 'activation-stale-scene',
        mapId: 'map',
        reason: MapActivationReason.warp,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) {
          committedCalls++;
          currentState = value;
        },
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: registry,
          occurrence: occurrence,
        ),
        executeScene: (request) async {
          sceneStarted.complete();
          await releaseScene.future;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState.copyWith(
              metadata: const {'scene': 'must-not-commit'},
            ),
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await sceneStarted.future;
      currentActivationId = 'activation-newer';
      releaseScene.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(await transactions.read(), originalState);
      expect(currentState, originalState);
      expect(committedCalls, 0);
      expect(legacyCalls, 0);
    });

    test('claimed but ineligible dualRead event never falls back', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final source = NarrativeEventSourceRef.mapEnter('map');
      final provenance = LegacySourceRef.mapEvent('map', 'legacy-map-enter');
      final registry = _registry(
        EventSystemMode.dualRead,
        records: [_record(source, enabled: false)],
        claims: [_claim(source, provenance)],
      );
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-claimed-ineligible',
        mapId: 'map',
        reason: MapActivationReason.connection,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, __) async => _prepareAuthority(
          registry: registry,
          occurrence: NarrativeEventOccurrence(
            source: source,
            provenance: provenance,
          ),
          legacyClaimIndex: buildRuntimeValidatedLegacyClaimIndex(
            registry,
            runtimeEvidence: LegacyClaimRuntimeEvidence(
              entries: [
                LegacyClaimRuntimeEvidenceEntry(
                  provenance: provenance,
                  source: source,
                  sourceFingerprint: _legacyFingerprint,
                ),
              ],
            ),
          ),
        ),
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchClaimedIneligible>());
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('blocked or failing authority preparation stays fail-closed',
        () async {
      for (final throwsDuringPreparation in [false, true]) {
        var currentState = const GameState(saveId: 'save');
        final transactions = NarrativeEventStateTransactions(currentState);
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId:
              'activation-authority-${throwsDuringPreparation ? 'error' : 'blocked'}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) => currentState = value,
          prepareAuthority: (_, __) async {
            if (throwsDuringPreparation) {
              throw StateError('authority preparation failed');
            }
            return NarrativeEventDispatchAuthorityBlocked(
              reason:
                  NarrativeEventDispatchAuthorityBlockReason.invalidRegistry,
              diagnostics: const ['blocked fixture'],
            );
          },
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(
          result.runtimeType,
          throwsDuringPreparation
              ? MapEnterProductionDispatchFailed
              : MapEnterProductionDispatchAuthorityBlocked,
        );
        expect(legacyCalls, 0);
      }
    });

    test('failed or cancelled Scene rolls back without legacy fallback',
        () async {
      for (final testCase in <({
        NarrativeSceneExecutionResult sceneResult,
        Type expectedResult,
      })>[
        (
          sceneResult: NarrativeSceneExecutionResult.failed('scene failed'),
          expectedResult: MapEnterProductionDispatchFailed,
        ),
        (
          sceneResult:
              NarrativeSceneExecutionResult.cancelled('scene cancelled'),
          expectedResult: MapEnterProductionDispatchNoFallback,
        ),
      ]) {
        const originalState = GameState(
          saveId: 'save',
          metadata: {'runtime': 'original'},
        );
        var currentState = originalState;
        final transactions = NarrativeEventStateTransactions(currentState);
        final source = NarrativeEventSourceRef.mapEnter('map');
        final registry = _registry(
          EventSystemMode.v2Only,
          records: [_record(source)],
        );
        var committedCalls = 0;
        var legacyCalls = 0;
        final activation = MapActivation(
          activationId: 'activation-scene-${testCase.expectedResult}',
          mapId: 'map',
          reason: MapActivationReason.initialBoot,
        );
        final bridge = _bridge(
          stateTransactions: transactions,
          currentGameState: () => currentState,
          onGameStateCommitted: (value) {
            committedCalls++;
            currentState = value;
          },
          prepareAuthority: (_, occurrence) async => _prepareAuthority(
            registry: registry,
            occurrence: occurrence,
          ),
          executeScene: (_) async => testCase.sceneResult,
          legacyFallback: (_, __, ___) async => legacyCalls++,
          isCurrentActivation: (value) => value == activation.activationId,
        );

        final result = await bridge.dispatchCompletedActivation(activation);

        expect(result.runtimeType, testCase.expectedResult);
        expect(await transactions.read(), originalState);
        expect(currentState, originalState);
        expect(committedCalls, 0);
        expect(legacyCalls, 0);
      }
    });

    test('saveRestore drains the real F1 outbox FIFO before mapEnter',
        () async {
      final trace = <String>[];
      GameState? legacyGameState;
      var currentState = GameState(
        saveId: 'save',
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: [
            _pendingDelivery(
              _firstPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'first',
            ),
            _pendingDelivery(
              _secondPendingDeliveryId,
              producerId: 'restore',
              outcomeId: 'second',
            ),
          ],
        ),
      );
      final transactions = NarrativeEventStateTransactions(currentState);
      final activityPort = NoopNarrativeEventActivityPort();
      final processor = NarrativeOutcomeOutboxProcessor(
        stateTransactions: transactions,
        activityPort: activityPort,
        dispatcher: (request) async {
          trace.add('outcome:${request.delivery.outcome.outcomeId}');
          return NarrativeOutcomeDispatchResult.delivered(
            updatedGameState: request.gameState,
          );
        },
        deliveryIdFactory: () => _generatedDeliveryId,
      );
      final activation = MapActivation(
        activationId: 'activation-save-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, gameState) async {
          legacyGameState = gameState;
          trace.add('mapEnter:saveRestore');
        },
        activityPort: activityPort,
        beforeSaveRestoreDispatch: (_) async {
          while (true) {
            final result = await processor.processNext();
            if (result is NarrativeOutcomeOutboxEmpty) {
              return;
            }
            expect(result, isA<NarrativeOutcomeOutboxDelivered>());
          }
        },
        isCurrentActivation: (value) => value == activation.activationId,
      );

      final result = await bridge.dispatchCompletedActivation(activation);
      final latestTransactionalState = await transactions.read();

      expect(result, isA<MapEnterProductionDispatchLegacyFallback>());
      expect(
        trace,
        ['outcome:first', 'outcome:second', 'mapEnter:saveRestore'],
      );
      expect(
        latestTransactionalState
            .narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(currentState, latestTransactionalState);
      expect(legacyGameState, latestTransactionalState);
    });

    test('newer activation suppresses stale saveRestore after async prehook',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final hookStarted = Completer<void>();
      final releaseHook = Completer<void>();
      var currentActivationId = 'activation-stale-restore';
      var authorityCalls = 0;
      var v2Calls = 0;
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-restore',
        mapId: 'map',
        reason: MapActivationReason.saveRestore,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        executeScene: (request) async {
          v2Calls++;
          return NarrativeSceneExecutionResult.completed(
            updatedGameState: request.gameState,
            qualifiedOutcomes: const [],
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        beforeSaveRestoreDispatch: (_) async {
          hookStarted.complete();
          await releaseHook.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await hookStarted.future;
      currentActivationId = 'activation-newer-warp';
      releaseHook.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(authorityCalls, 0);
      expect(v2Calls, 0);
      expect(legacyCalls, 0);
    });

    test('newer activation marks an awaited legacy fallback stale', () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      final legacyStarted = Completer<void>();
      final releaseLegacy = Completer<void>();
      var currentActivationId = 'activation-stale-legacy';
      var legacyCalls = 0;
      final activation = MapActivation(
        activationId: 'activation-stale-legacy',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (_, __, ___) async {
          legacyCalls++;
          legacyStarted.complete();
          await releaseLegacy.future;
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );

      final dispatch = bridge.dispatchCompletedActivation(activation);
      await legacyStarted.future;
      currentActivationId = 'activation-newer';
      releaseLegacy.complete();
      final result = await dispatch;

      expect(result, isA<MapEnterProductionDispatchStale>());
      expect(legacyCalls, 1);
    });

    test('stale attempts are unclaimed while the current id stays claimed',
        () async {
      var currentState = const GameState(saveId: 'save');
      final transactions = NarrativeEventStateTransactions(currentState);
      var currentActivationId = 'activation-a';
      final legacyTrace = <String>[];
      final bridge = _bridge(
        stateTransactions: transactions,
        currentGameState: () => currentState,
        onGameStateCommitted: (value) => currentState = value,
        prepareAuthority: (_, occurrence) async => _prepareAuthority(
          registry: _registry(EventSystemMode.legacyOnly),
          occurrence: occurrence,
        ),
        legacyFallback: (activation, _, __) async {
          legacyTrace.add(activation.activationId);
        },
        isCurrentActivation: (value) => value == currentActivationId,
      );
      final activationA = MapActivation(
        activationId: 'activation-a',
        mapId: 'map-a',
        reason: MapActivationReason.initialBoot,
      );
      final activationB = MapActivation(
        activationId: 'activation-b',
        mapId: 'map-b',
        reason: MapActivationReason.warp,
      );
      final staleActivation = MapActivation(
        activationId: 'activation-stale',
        mapId: 'map-stale',
        reason: MapActivationReason.connection,
      );

      expect(
        await bridge.dispatchCompletedActivation(activationA),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      currentActivationId = activationB.activationId;
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchLegacyFallback>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(staleActivation),
        isA<MapEnterProductionDispatchStale>(),
      );
      expect(
        await bridge.dispatchCompletedActivation(activationB),
        isA<MapEnterProductionDispatchDuplicate>(),
      );
      expect(legacyTrace, ['activation-a', 'activation-b']);
    });

    test('current activation lookup exception fails closed before claim',
        () async {
      var authorityCalls = 0;
      var legacyCalls = 0;
      final bridge = _bridge(
        stateTransactions: NarrativeEventStateTransactions(
          const GameState(saveId: 'save'),
        ),
        currentGameState: () => const GameState(saveId: 'save'),
        onGameStateCommitted: (_) {},
        prepareAuthority: (_, occurrence) async {
          authorityCalls++;
          return _prepareAuthority(
            registry: _registry(EventSystemMode.legacyOnly),
            occurrence: occurrence,
          );
        },
        legacyFallback: (_, __, ___) async => legacyCalls++,
        isCurrentActivation: (_) => throw StateError('current lookup failed'),
      );
      final activation = MapActivation(
        activationId: 'activation-current-error',
        mapId: 'map',
        reason: MapActivationReason.initialBoot,
      );

      final result = await bridge.dispatchCompletedActivation(activation);

      expect(result, isA<MapEnterProductionDispatchFailed>());
      expect(authorityCalls, 0);
      expect(legacyCalls, 0);
    });
  });
}

MapEnterProductionDispatchBridge _bridge({
  required NarrativeEventStateTransactions stateTransactions,
  required GameState Function() currentGameState,
  required void Function(GameState gameState) onGameStateCommitted,
  required Future<NarrativeEventDispatchAuthorityPreparation> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
  ) prepareAuthority,
  required Future<void> Function(
    MapActivation activation,
    NarrativeEventOccurrence occurrence,
    GameState gameState,
  ) legacyFallback,
  required bool Function(String activationId) isCurrentActivation,
  NarrativeSceneExecutionCallback? executeScene,
  NarrativeEventActivityPort? activityPort,
  Future<void> Function(MapActivation activation)? beforeSaveRestoreDispatch,
}) {
  return MapEnterProductionDispatchBridge(
    stateTransactions: stateTransactions,
    currentGameState: currentGameState,
    onGameStateCommitted: onGameStateCommitted,
    prepareAuthority: prepareAuthority,
    executeScene: executeScene ??
        (request) async => NarrativeSceneExecutionResult.completed(
              updatedGameState: request.gameState,
              qualifiedOutcomes: const [],
            ),
    legacyFallback: legacyFallback,
    activityPort: activityPort ?? NoopNarrativeEventActivityPort(),
    beforeSaveRestoreDispatch: beforeSaveRestoreDispatch ?? (_) async {},
    isCurrentActivation: isCurrentActivation,
    executionIdFactory: () => _executionId,
    correlationIdFactory: () => _correlationId,
    deliveryIdFactory: () => _generatedDeliveryId,
  );
}

NarrativeEventDispatchAuthorityPreparation _prepareAuthority({
  required NarrativeEventRegistry registry,
  required NarrativeEventOccurrence occurrence,
  ValidatedLegacyClaimIndex? legacyClaimIndex,
}) {
  return NarrativeEventDispatchAuthority.prepare(
    registryResult: EventRegistryDecodeResult.decoded(registry),
    occurrence: occurrence,
    factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
    legacyClaimIndex: legacyClaimIndex,
    projectCatalog: _catalog(registry, occurrence.source),
  );
}

NarrativeEventRegistry _registry(
  EventSystemMode mode, {
  List<NarrativeEventRecord> records = const [],
  List<LegacySourceClaim> claims = const [],
}) {
  return NarrativeEventRegistry(
    schemaVersion: 1,
    mode: mode,
    records: records,
    legacyClaims: claims,
  );
}

NarrativeEventRecord _record(
  NarrativeEventSourceRef source, {
  bool enabled = true,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Map enter event',
      source: source,
      conditions: const [],
      sceneId: 'scene_map_enter',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

LegacySourceClaim _claim(
  NarrativeEventSourceRef source,
  LegacySourceRef provenance,
) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _legacyFingerprint,
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt',
  );
}

NarrativeEventProjectCatalog _catalog(
  NarrativeEventRegistry registry,
  NarrativeEventSourceRef source,
) {
  final mapId = source.when(
    entityInteract: (value, _) => value,
    triggerEnter: (value, _) => value,
    mapEnter: (value) => value,
    outcomeReceived: (_) => 'map',
  );
  final sceneIds = {
    for (final record in registry.records)
      if (record.definitionOrNull case final definition?) definition.sceneId,
  };
  final project = ProjectManifest(
    name: 'Map enter bridge fixture',
    maps: [
      ProjectMapEntry(
        id: mapId,
        name: mapId,
        relativePath: 'maps/$mapId.json',
      ),
    ],
    tilesets: const [],
    eventRegistry: registry,
    scenes: [for (final sceneId in sceneIds) _scene(sceneId)],
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
  return buildNarrativeEventProjectCatalog(
    project: project,
    maps: [
      MapData(
        id: mapId,
        name: mapId,
        size: const GridSize(width: 1, height: 1),
        layers: const [MapLayer.object(id: 'objects', name: 'Objects')],
      ),
    ],
  );
}

SceneAsset _scene(String id) {
  return SceneAsset.fromJson({
    'id': id,
    'name': id,
    'graph': const {
      'startNodeId': 'start',
      'nodes': [
        {'id': 'start', 'kind': 'start'},
        {'id': 'end', 'kind': 'end'},
      ],
      'edges': [
        {
          'id': 'edge',
          'fromNodeId': 'start',
          'fromPortId': 'completed',
          'toNodeId': 'end',
          'kind': 'default',
        },
      ],
    },
  });
}

NarrativeOutcomeDelivery _pendingDelivery(
  String deliveryId, {
  required String producerId,
  required String outcomeId,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: producerId,
      outcomeId: outcomeId,
    ),
    causationExecutionId: _executionId,
    rootCorrelationId: _correlationId,
    depth: 0,
    attemptCount: 0,
  );
}
````

### 16.7 `packages/map_runtime/test/narrative_scene_runtime_execution_test.dart`

````dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('executeNarrativeEventScene', () {
    test('rebases buffered consequences onto host battle write-back', () async {
      const requestGameState = GameState(
        saveId: 'save_scene_runtime',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 12,
            ),
          ],
        ),
      );
      var runtimeGameState = requestGameState;
      var battleCalls = 0;

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition.'),
          showDialogue: (_) => throw StateError('Unexpected dialogue.'),
          startBattle: (intent) {
            battleCalls++;
            expect(intent.trainerId, 'trainer_scene_runtime');
            runtimeGameState = runtimeGameState.copyWith(
              party: PlayerParty(
                members: <PlayerPokemon>[
                  runtimeGameState.party.members.single.copyWith(currentHp: 3),
                ],
              ),
              metadata: const <String, String>{
                'battleWriteBack': 'committed',
              },
            );
            return 'victory';
          },
          playCinematic: (_) => throw StateError('Unexpected cinematic.'),
        ),
      );

      expect(result, isA<NarrativeSceneExecutionCompleted>());
      final completed = result as NarrativeSceneExecutionCompleted;
      expect(battleCalls, 1);
      expect(completed.updatedGameState.party.members.single.currentHp, 3);
      expect(
        completed.updatedGameState.metadata['battleWriteBack'],
        'committed',
      );
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_scene_runtime_completed'),
      );
      expect(
        completed.updatedGameState.narrativeFactRuntimeState.overridesByFactId,
        containsPair('fact_scene_runtime_completed', true),
      );
    });

    test('fails closed on an initial GameState conflict before host callbacks',
        () async {
      const requestGameState = GameState(saveId: 'save_scene_runtime');
      final runtimeGameState = requestGameState.copyWith(
        metadata: const <String, String>{'newerRuntimeState': 'true'},
      );
      var hostCallbackCalls = 0;
      String unexpectedCallback(SceneRuntimePlanIntent _) {
        hostCallbackCalls++;
        return 'victory';
      }

      final result = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_scene_runtime',
          sceneId: 'scene_battle_then_fact',
          executionId: 'execution_scene_runtime',
          gameState: requestGameState,
        ),
        project: _project(),
        mapsById: const <String, MapData>{},
        currentGameState: () => runtimeGameState,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: unexpectedCallback,
          showDialogue: unexpectedCallback,
          startBattle: unexpectedCallback,
          playCinematic: unexpectedCallback,
        ),
      );

      expect(result, isA<NarrativeSceneExecutionFailed>());
      final failed = result as NarrativeSceneExecutionFailed;
      expect(failed.failure, isA<StateError>());
      expect(failed.failure.toString(), contains('initial GameState conflict'));
      expect(hostCallbackCalls, 0);
    });
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Narrative Scene Runtime Execution Test',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: const <ProjectTrainerEntry>[
      ProjectTrainerEntry(
        id: 'trainer_scene_runtime',
        name: 'Runtime Trainer',
        trainerClass: 'Tester',
        team: <ProjectTrainerPokemonEntry>[
          ProjectTrainerPokemonEntry(speciesId: 'embercub', level: 5),
        ],
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: 'fact_scene_runtime_completed',
        label: 'Runtime scene completed',
      ),
    ],
    scenes: <SceneAsset>[_battleThenFactScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _battleThenFactScene() {
  return SceneAsset(
    id: 'scene_battle_then_fact',
    name: 'Battle then Fact',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: 'trainer_scene_runtime',
            declaredOutcomes: const <String>['victory', 'defeat'],
          ),
        ),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_scene_runtime_completed',
              value: true,
            ),
          ),
        ),
        SceneNode(id: 'victory_end', kind: SceneNodeKind.end),
        SceneNode(id: 'defeat_end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory_to_fact',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'fact_to_victory_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'victory_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'battle_defeat_to_end',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'defeat_end',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}
````

### 16.8 `packages/map_runtime/test/playable_map_game_event_v2_boot_integration_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';

const _mapId = 'event_v2_boot_map';
const _eventId = 'evt_019abcde-1000-7000-8000-000000000001';
const _sceneId = 'scene_event_v2_boot';
const _factId = 'fact.event_v2.boot_scene_completed';
const _legacyFlag = 'test.event_v2.legacy_fallback_must_not_run';
const _dialogueEventId = 'evt_019abcde-1000-7000-8000-000000000002';
const _dialogueSceneId = 'scene_event_v2_boot_dialogue';
const _dialogueId = 'dialogue_event_v2_boot';
const _dialogueFactId = 'fact.event_v2.boot_dialogue_completed';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('v2Only mapEnter executes the real Scene and suppresses legacy',
      () async {
    final bundle = _bundle();
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: '/tmp/event_v2_boot/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeFactRuntimeState.overridesByFactId[_factId], isTrue);
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      contains(_eventId),
      reason: 'The one-shot Event must be committed by the F1 coordinator.',
    );
    expect(
      state.storyFlags.activeFlags,
      isNot(contains(_legacyFlag)),
      reason: 'v2Only authority must never invoke the legacy Scenario.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });

  test('dualRead validated ineligible claim suppresses legacy fallback',
      () async {
    final game = PlayableMapGame(
      bundle: _dualReadClaimedBundle(),
      projectFilePath: '/tmp/event_v2_dual_read/project.json',
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      isNot(contains(_factId)),
      reason: 'The claimed Event is disabled and its Scene must not execute.',
    );
    expect(
      state.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_eventId)),
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
  });

  test('boot Scene dialogue starts after onLoad and remains interactive',
      () async {
    final game = _LifecycleTestPlayableMapGame(
      bundle: _dialogueBundle(),
      projectFilePath: '/tmp/event_v2_boot_dialogue/project.json',
      dialogueSessionLoader: (_) async => _singleLineDialogueSession(),
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad().timeout(const Duration(seconds: 2));

    expect(game.debugIsMapActivationDispatchInFlight, isTrue);
    await _waitUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    expect(game.debugCompletedMapActivationDispatchCount, 0);
    expect(
      game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
      isNot(contains(_dialogueEventId)),
    );

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(state.narrativeEventProgress.consumedNarrativeEventIds,
        contains(_dialogueEventId));
    expect(
      state.narrativeFactRuntimeState.overridesByFactId[_dialogueFactId],
      isTrue,
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
  });
}

final class _LifecycleTestPlayableMapGame extends PlayableMapGame {
  _LifecycleTestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.dialogueSessionLoader,
  });

  bool _onLoadCompleted = false;

  @override
  bool get isLoaded => _onLoadCompleted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _onLoadCompleted = true;
  }
}

RuntimeMapBundle _bundle() {
  final scene = _scene();
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _record(enabled: true),
    ],
    legacyClaims: const [],
  );
  return _bundleForRegistry(registry, scene);
}

RuntimeMapBundle _dialogueBundle() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _dialogueEventId,
          name: 'Boot dialogue Event V2',
          source: NarrativeEventSourceRef.mapEnter(_mapId),
          conditions: const <NarrativeEventCondition>[],
          sceneId: _dialogueSceneId,
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        enabled: true,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  final project = ProjectManifest(
    name: 'Event V2 boot dialogue integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: _dialogueId,
        name: 'Boot dialogue',
        relativePath: 'dialogues/boot.yarn',
      ),
    ],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _dialogueFactId,
        label: 'Boot dialogue completed',
      ),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[_dialogueScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot_dialogue',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

SceneAsset _dialogueScene() => SceneAsset(
      id: _dialogueSceneId,
      name: 'Event V2 boot dialogue Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(dialogueId: _dialogueId),
          ),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(
                factId: _dialogueFactId,
                value: true,
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_dialogue',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'dialogue',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'dialogue_to_fact',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'fact_to_end',
            fromNodeId: 'set_fact',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

DialogueSession _singleLineDialogueSession() {
  return DialogueSession.start(
    <YarnNode>[
      YarnNode(
        title: 'Start',
        steps: <YarnStep>[YarnStepLine('Bienvenue.')],
      ),
    ],
    'Start',
  )!;
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) {
  return _waitUntil(
    game,
    () => !game.debugIsMapActivationDispatchInFlight,
  );
}

Future<void> _waitUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime activation dispatch.');
}

RuntimeMapBundle _dualReadClaimedBundle() {
  final source = NarrativeEventSourceRef.mapEnter(_mapId);
  final provenance = LegacySourceRef.scenarioSourceNode(
    _legacyMapEnterScenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: _legacyMapEnterScenario.id,
      nodeId: 'source',
      scenario: _legacyMapEnterScenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, [provenance]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      [member],
    ),
    targetEventIds: const [_eventId],
    migrationReceiptId: 'receipt-event-v2-boot-dual-read',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[_record(enabled: false)],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundleForRegistry(registry, _scene());
}

NarrativeEventRecord _record({required bool enabled}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: _eventId,
      name: 'Boot Event V2',
      source: NarrativeEventSourceRef.mapEnter(_mapId),
      conditions: const <NarrativeEventCondition>[],
      sceneId: _sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: _sceneId,
    name: 'Event V2 boot Scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: _factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _bundleForRegistry(
  NarrativeEventRegistry registry,
  SceneAsset scene,
) {
  final project = ProjectManifest(
    name: 'Event V2 boot integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Boot Map',
        relativePath: 'maps/event_v2_boot.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Boot Scene completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyMapEnterScenario],
    eventRegistry: registry,
    scenes: <SceneAsset>[scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(),
    projectRootDirectory: '/tmp/event_v2_boot',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Event V2 Boot Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );

const _legacyMapEnterScenario = ScenarioAsset(
  id: 'legacy_map_enter_must_not_run',
  name: 'Legacy mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);
````

### 16.9 `packages/map_runtime/test/playable_map_game_initial_save_restore_activation_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _sourceMapId = 'initial_bundle_map';
const _restoredMapId = 'restored_boot_map';
const _restoredFlag = 'test.initial_save_restore.map_enter';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('explicit saveRestore boot restores map and pose before one mapEnter',
      () async {
    final project = _project();
    final bundles = <String, RuntimeMapBundle>{
      _sourceMapId: _bundle(project, _sourceMap()),
      _restoredMapId: _bundle(project, _restoredMap()),
    };
    Future<RuntimeMapBundle> loadBundle({
      required String projectFilePath,
      required String mapId,
    }) async {
      return bundles[mapId] ?? (throw StateError('Unknown map $mapId'));
    }

    final game = PlayableMapGame(
      bundle: bundles[_sourceMapId]!,
      projectFilePath: '/tmp/initial_save_restore/project.json',
      saveData: const SaveData(
        saveId: 'versioned-launch-save',
        currentMapId: _restoredMapId,
        playerPosition: GridPos(x: 2, y: 1),
        playerFacing: EntityFacing.west,
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
      runtimeMapBundleLoader: loadBundle,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(game.gameStateSnapshot.currentMapId, _restoredMapId);
    expect(game.debugPlayerGridPosition, const GridPos(x: 2, y: 1));
    expect(game.gameStateSnapshot.playerFacing, EntityFacing.west);
    expect(
        game.gameStateSnapshot.storyFlags.activeFlags, contains(_restoredFlag));
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _restoredMapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore activation dispatch.');
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Initial save restore integration',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: _sourceMapId,
        name: 'Initial Bundle Map',
        relativePath: 'maps/initial.json',
      ),
      ProjectMapEntry(
        id: _restoredMapId,
        name: 'Restored Boot Map',
        relativePath: 'maps/restored.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
    scenarios: <ScenarioAsset>[_restoredMapEnterScenario],
    surfaceCatalog: ProjectSurfaceCatalog.empty(),
  );
}

RuntimeMapBundle _bundle(ProjectManifest project, MapData map) {
  return RuntimeMapBundle(
    manifest: project,
    map: map,
    projectRootDirectory: '/tmp/initial_save_restore',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Initial Bundle Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'source_spawn',
          name: 'Source Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'source_spawn'),
    );

MapData _restoredMap() => const MapData(
      id: _restoredMapId,
      name: 'Restored Boot Map',
      size: GridSize(width: 4, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'restored_spawn',
          name: 'Restored Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'restored_spawn'),
    );

const _restoredMapEnterScenario = ScenarioAsset(
  id: 'restored_boot_map_enter_scenario',
  name: 'Restored boot map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _restoredMapId),
    ),
    ScenarioNode(
      id: 'set_restored_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _restoredFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_restored_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_restored_flag',
      toNodeId: 'end',
    ),
  ],
);
````

### 16.10 `packages/map_runtime/test/playable_map_game_map_activation_interlock_test.dart`

````dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

const _sourceMapId = 'activation_interlock_source';
const _targetMapId = 'activation_interlock_target';
const _eventId = 'evt_019abcde-2000-7000-8000-000000000001';
const _sceneId = 'scene_activation_interlock_target_enter';
const _factId = 'fact.activation_interlock.target_enter_completed';
const _legacyFlag = 'test.activation_interlock.legacy_must_not_run';
const _legacyOutcomeId = 'activation_interlock_transition_requested';
const _legacyOutcomeProducerSceneId =
    'scene_activation_interlock_outcome_producer';
const _legacyMapEnterAFlag = 'test.activation_interlock.map_enter_a';
const _legacyMapEnterBFlag = 'test.activation_interlock.map_enter_b';
const _legacyDeliveryId = 'outd_019abcde-4000-7000-8000-000000000001';
const _legacyExecutionId = 'evx_019abcde-4000-7000-8000-000000000002';
const _legacyCorrelationId = 'corr_019abcde-4000-7000-8000-000000000003';
const _retryOutcomeId = 'activation_interlock_retry_outcome';
const _retryDeliveryId = 'outd_019abcde-4000-7000-8000-000000000011';
const _retryExecutionId = 'evx_019abcde-4000-7000-8000-000000000012';
const _retryCorrelationId = 'corr_019abcde-4000-7000-8000-000000000013';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'connection mapEnter dispatch interlocks movement, transitions and load',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_map_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var targetPreparationCount = 0;
      final repository = _CountingGameSaveRepository(
        const GameState(
          saveId: 'load-must-not-run',
          currentMapId: _sourceMapId,
          playerPosition: GridPos(x: 1, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source !=
              NarrativeEventSourceRef.mapEnter(_targetMapId)) {
            return;
          }
          targetPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      await _runSingleMove(game, RuntimeInputControl.right);
      await preparationStarted.future.timeout(const Duration(seconds: 2));

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugFlowPhaseName, 'overworld');
      expect(game.debugIsMapActivationDispatchInFlight, isTrue);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.initialBoot,
      );
      expect(
        game.gameStateSnapshot.narrativeFactRuntimeState
            .overridesByFactId[_factId],
        isNot(isTrue),
      );

      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 0);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            !game.debugIsMapActivationDispatchInFlight &&
            game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[_factId] ==
                true,
      );

      final state = game.gameStateSnapshot;
      expect(targetPreparationCount, 1);
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds
            .where((id) => id == _eventId),
        hasLength(1),
      );
      expect(state.storyFlags.activeFlags, isNot(contains(_legacyFlag)));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
    },
  );

  test(
    'load interlocks movement and connection until saveRestore dispatch',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_load_activation_interlock_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final repository = _BlockingLoadGameSaveRepository(
        const GameState(
          saveId: 'blocked-load',
          currentMapId: _targetMapId,
          playerPosition: GridPos(x: 0, y: 0),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivationId =
          game.debugLastCompletedMapActivation?.activationId;

      final loadFuture = game.loadGame();
      await repository.loadStarted.future.timeout(const Duration(seconds: 2));

      expect(game.debugIsLoadActivationWorkInFlight, isTrue);
      expect(game.debugIsMapActivationDispatchInFlight, isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.loadCount, 1);

      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.press(RuntimeInputControl.right),
        ),
        isTrue,
      );
      for (var i = 0; i < 30; i++) {
        game.update(0.016);
        await Future<void>.delayed(Duration.zero);
      }
      expect(
        game.handleRuntimeInputEvent(
          const RuntimeInputEvent.release(RuntimeInputControl.right),
        ),
        isTrue,
      );

      expect(game.gameStateSnapshot.currentMapId, _sourceMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 1, y: 0));
      expect(game.debugHasPendingMapTransition, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        initialActivationId,
      );

      repository.releaseLoad();
      expect(await loadFuture, isTrue);

      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.gameStateSnapshot.currentMapId, _targetMapId);
      expect(game.debugPlayerGridPosition, const GridPos(x: 0, y: 0));
      expect(game.debugCompletedMapActivationDispatchCount, 2);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.saveRestore,
      );
      expect(
        game.debugLastCompletedMapActivation?.activationId,
        isNot(initialActivationId),
      );
    },
  );

  test(
    'restored legacy outcome transition supersedes stale mapEnter activation',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_transition_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeLegacyOutcomeTransitionProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: _legacyOutcomeProducerSceneId,
        outcomeId: _legacyOutcomeId,
      );
      final game = PlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveData: SaveData(
          saveId: 'restore-outcome-transition',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _legacyDeliveryId,
                outcome: outcome,
                causationExecutionId: _legacyExecutionId,
                rootCorrelationId: _legacyCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
        initialMapActivationReason: MapActivationReason.saveRestore,
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad().timeout(
            const Duration(seconds: 2),
          );
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );

      final state = game.gameStateSnapshot;
      expect(state.currentMapId, _targetMapId);
      expect(
          state.storyFlags.activeFlags, isNot(contains(_legacyMapEnterAFlag)));
      expect(state.storyFlags.activeFlags, contains(_legacyMapEnterBFlag));
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(_legacyDeliveryId),
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(
        game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.warp,
      );
    },
  );

  test(
    'failed restored outcome authority keeps pending delivery and load fails',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'runtime_restore_outcome_retry_',
      );
      addTearDown(() async {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      });
      final projectFilePath = await _writeProject(root);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: _sourceMapId,
      );
      final retryOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_activation_interlock_retry_producer',
        outcomeId: _retryOutcomeId,
      );
      final repository = _CountingGameSaveRepository(
        GameState(
          saveId: 'restore-outcome-retry',
          currentMapId: _sourceMapId,
          playerPosition: const GridPos(x: 1, y: 0),
          narrativeEventProgress: NarrativeEventProgress(
            pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
              NarrativeOutcomeDelivery(
                deliveryId: _retryDeliveryId,
                outcome: retryOutcome,
                causationExecutionId: _retryExecutionId,
                rootCorrelationId: _retryCorrelationId,
                depth: 0,
                attemptCount: 0,
              ),
            ],
          ),
        ),
      );
      final game = _TestPlayableMapGame(
        bundle: bundle,
        projectFilePath: projectFilePath,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.outcomeReceived) {
            throw StateError('Injected restored outcome authority failure.');
          }
        },
      );

      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await _pumpUntil(
        game,
        () => !game.debugIsMapActivationDispatchInFlight,
      );
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      final initialActivation = game.debugLastCompletedMapActivation;

      expect(await game.loadGame(), isFalse);

      final state = game.gameStateSnapshot;
      expect(game.debugIsLoadActivationWorkInFlight, isFalse);
      expect(game.debugCompletedMapActivationDispatchCount, 1);
      expect(game.debugLastCompletedMapActivation, initialActivation);
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        hasLength(1),
      );
      expect(
        state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries.single
            .deliveryId,
        _retryDeliveryId,
      );
      expect(
        state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        isNot(contains(_retryDeliveryId)),
      );
    },
  );
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
    super.beforeNarrativeAuthorityPreparation,
  });

  @override
  bool get isLoaded => true;
}

final class _BlockingLoadGameSaveRepository implements GameSaveRepository {
  _BlockingLoadGameSaveRepository(this._state);

  final GameState _state;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<GameState?> _loadResult = Completer<GameState?>();
  int loadCount = 0;

  void releaseLoad() {
    if (!_loadResult.isCompleted) {
      _loadResult.complete(_state);
    }
  }

  @override
  Future<void> save(GameState state) async {}

  @override
  Future<GameState?> load() {
    loadCount++;
    if (!loadStarted.isCompleted) {
      loadStarted.complete();
    }
    return _loadResult.future;
  }

  @override
  Future<bool> exists() async => true;

  @override
  Future<void> delete() async {}
}

final class _CountingGameSaveRepository implements GameSaveRepository {
  _CountingGameSaveRepository(this._state);

  GameState? _state;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async {
    loadCount++;
    return _state;
  }

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}

Future<void> _runSingleMove(
  PlayableMapGame game,
  RuntimeInputControl control,
) async {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.update(0.016);
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
    isTrue,
  );
  await _pumpUntil(
    game,
    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
  );
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the runtime game to settle.');
}

Future<String> _writeProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Map activation interlock integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(
        id: _factId,
        label: 'Target map enter completed',
      ),
    ],
    scenarios: const <ScenarioAsset>[_legacyTargetMapEnterScenario],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: <NarrativeEventRecord>[
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
            id: _eventId,
            name: 'Target map enter',
            source: NarrativeEventSourceRef.mapEnter(_targetMapId),
            conditions: const <NarrativeEventCondition>[],
            sceneId: _sceneId,
            reusePolicy: NarrativeEventReusePolicy.oneShot,
            priority: 0,
            order: 0,
          ),
          enabled: true,
        ),
      ],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenes: <SceneAsset>[_scene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

Future<String> _writeLegacyOutcomeTransitionProject(Directory root) async {
  final maps = <MapData>[_sourceMap(), _targetMap()];
  final manifest = ProjectManifest(
    name: 'Restored legacy outcome transition integration',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: maps
        .map(
          (map) => ProjectMapEntry(
            id: map.id,
            name: map.name,
            relativePath: 'maps/${map.id}.json',
          ),
        )
        .toList(growable: false),
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: const <ScenarioAsset>[
      _legacyOutcomeTransitionScenario,
      _legacyMapEnterAScenario,
      _legacyMapEnterBScenario,
    ],
    scenes: <SceneAsset>[_legacyOutcomeProducerScene()],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
  final mapsDirectory = Directory(p.join(root.path, 'maps'));
  await mapsDirectory.create(recursive: true);
  for (final map in maps) {
    await File(p.join(mapsDirectory.path, '${map.id}.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(map.toJson()),
    );
  }
  final projectFile = File(p.join(root.path, 'project.json'));
  await projectFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
  );
  return projectFile.path;
}

SceneAsset _legacyOutcomeProducerScene() => SceneAsset(
      id: _legacyOutcomeProducerSceneId,
      name: 'Legacy transition outcome producer',
      declaredOutcomes: <SceneOutcome>[
        SceneOutcome(
          id: _legacyOutcomeId,
          label: 'Transition requested',
        ),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: _legacyOutcomeId,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );

MapData _sourceMap() => const MapData(
      id: _sourceMapId,
      name: 'Activation interlock source',
      size: GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_source',
          name: 'Source spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      connections: <MapConnection>[
        MapConnection(
          direction: MapConnectionDirection.east,
          targetMapId: _targetMapId,
          offset: 0,
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_source'),
    );

MapData _targetMap() => const MapData(
      id: _targetMapId,
      name: 'Activation interlock target',
      size: GridSize(width: 3, height: 2),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_target',
          name: 'Target spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
      ],
      warps: <MapWarp>[
        MapWarp(
          id: 'warp_back_to_source',
          pos: GridPos(x: 1, y: 0),
          targetMapId: _sourceMapId,
          targetPos: GridPos(x: 1, y: 0),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_target'),
    );

SceneAsset _scene() => SceneAsset(
      id: _sceneId,
      name: 'Target map enter Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'set_fact',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: _factId, value: true),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_to_fact',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'set_fact',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'fact_to_end',
            fromNodeId: 'set_fact',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted,
          ),
        ],
      ),
    );

const _legacyTargetMapEnterScenario = ScenarioAsset(
  id: 'legacy_target_map_enter_must_not_run',
  name: 'Legacy target mapEnter must not run',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_legacy_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source',
    ),
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source',
      toNodeId: 'set_legacy_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_legacy_flag',
      toNodeId: 'end',
    ),
  ],
);

const _legacyOutcomeTransitionScenario = ScenarioAsset(
  id: 'legacy_restored_outcome_transition',
  name: 'Legacy restored outcome transition',
  scope: ScenarioScope.globalStory,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_outcome',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceOutcome),
      binding: ScenarioNodeBinding(outcomeId: _legacyOutcomeId),
    ),
    ScenarioNode(
      id: 'transition_to_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionTransitionMap),
      binding: ScenarioNodeBinding(
        mapId: _targetMapId,
        warpId: 'warp_back_to_source',
      ),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source',
      fromNodeId: 'start',
      toNodeId: 'source_outcome',
    ),
    ScenarioEdge(
      id: 'source_to_transition',
      fromNodeId: 'source_outcome',
      toNodeId: 'transition_to_b',
    ),
    ScenarioEdge(
      id: 'transition_to_end',
      fromNodeId: 'transition_to_b',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterAScenario = ScenarioAsset(
  id: 'legacy_map_enter_a',
  name: 'Legacy map enter A',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_a',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _sourceMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_a',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterAFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_a',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_a',
    ),
    ScenarioEdge(
      id: 'source_to_flag_a',
      fromNodeId: 'source_map_enter_a',
      toNodeId: 'set_map_enter_a',
    ),
    ScenarioEdge(
      id: 'flag_to_end_a',
      fromNodeId: 'set_map_enter_a',
      toNodeId: 'end',
    ),
  ],
);

const _legacyMapEnterBScenario = ScenarioAsset(
  id: 'legacy_map_enter_b',
  name: 'Legacy map enter B',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'start',
  nodes: <ScenarioNode>[
    ScenarioNode(id: 'start', type: ScenarioNodeType.start),
    ScenarioNode(
      id: 'source_map_enter_b',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _targetMapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_b',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _legacyMapEnterBFlag),
    ),
    ScenarioNode(id: 'end', type: ScenarioNodeType.end),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'start_to_source_b',
      fromNodeId: 'start',
      toNodeId: 'source_map_enter_b',
    ),
    ScenarioEdge(
      id: 'source_to_flag_b',
      fromNodeId: 'source_map_enter_b',
      toNodeId: 'set_map_enter_b',
    ),
    ScenarioEdge(
      id: 'flag_to_end_b',
      fromNodeId: 'set_map_enter_b',
      toNodeId: 'end',
    ),
  ],
);
````

### 16.11 `packages/map_runtime/test/playable_map_game_map_enter_v2_integration_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'test_map_enter_load';
const _mapEnterFlag = 'test.map_enter.after_load';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadGame dispatches legacy mapEnter after restoring the same map',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'restored-save',
        currentMapId: _mapId,
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'The fixture must prove that the legacy mapEnter Scenario runs.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);

    expect(await game.loadGame(), isTrue);
    expect(game.gameStateSnapshot.saveId, 'restored-save');
    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      contains(_mapEnterFlag),
      reason: 'A successful load must dispatch mapEnter after state restore.',
    );
    expect(game.debugCompletedMapActivationDispatchCount, 2);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });

  test('missing save target never creates a completed map activation',
      () async {
    final repository = _MemoryGameSaveRepository(
      const GameState(
        saveId: 'missing-map-save',
        currentMapId: 'missing_save_target',
        playerPosition: GridPos(x: 1, y: 1),
      ),
    );
    var loaderCalls = 0;
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/test_map_enter_load/project.json',
      saveRepository: repository,
      runtimeMapBundleLoader: ({
        required String projectFilePath,
        required String mapId,
      }) async {
        loaderCalls++;
        throw StateError('Map $mapId is unavailable');
      },
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    expect(await game.loadGame(), isFalse);
    expect(loaderCalls, 1);
    expect(game.gameStateSnapshot.currentMapId, _mapId);
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.initialBoot,
    );
    expect(game.debugLastCompletedMapActivation?.mapId, _mapId);
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the initial map activation dispatch.');
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Map Enter Load Integration Test',
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: _mapId,
          name: 'Map Enter Load',
          relativePath: 'maps/test_map_enter_load.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      scenarios: const <ScenarioAsset>[_mapEnterScenario],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: _mapId,
      name: 'Map Enter Load',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn_start',
          name: 'Spawn Start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn_start'),
    ),
    projectRootDirectory: '/tmp/test_map_enter_load',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

const _mapEnterScenario = ScenarioAsset(
  id: 'test_map_enter_load_scenario',
  name: 'Set flag on map enter',
  scope: ScenarioScope.localEventFlow,
  entryNodeId: 'source_map_enter',
  nodes: <ScenarioNode>[
    ScenarioNode(
      id: 'source_map_enter',
      type: ScenarioNodeType.reference,
      payload: ScenarioNodePayload(actionKind: kScenarioSourceMapEnter),
      binding: ScenarioNodeBinding(mapId: _mapId),
    ),
    ScenarioNode(
      id: 'set_map_enter_flag',
      type: ScenarioNodeType.action,
      payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
      binding: ScenarioNodeBinding(flagName: _mapEnterFlag),
    ),
    ScenarioNode(
      id: 'end',
      type: ScenarioNodeType.end,
    ),
  ],
  edges: <ScenarioEdge>[
    ScenarioEdge(
      id: 'source_to_flag',
      fromNodeId: 'source_map_enter',
      toNodeId: 'set_map_enter_flag',
    ),
    ScenarioEdge(
      id: 'flag_to_end',
      fromNodeId: 'set_map_enter_flag',
      toNodeId: 'end',
    ),
  ],
);

final class _MemoryGameSaveRepository implements GameSaveRepository {
  _MemoryGameSaveRepository(this._state);

  GameState? _state;

  @override
  Future<void> save(GameState state) async {
    _state = state;
  }

  @override
  Future<GameState?> load() async => _state;

  @override
  Future<bool> exists() async => _state != null;

  @override
  Future<void> delete() async {
    _state = null;
  }
}
````

### 16.12 `packages/map_runtime/test/playable_map_game_save_restore_outbox_integration_test.dart`

````dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

const _mapId = 'save_restore_outbox_map';

const _outcomeOneProducerSceneId = 'scene_restore_producer_one';
const _outcomeTwoProducerSceneId = 'scene_restore_producer_two';
const _outcomeOneId = 'restore_outcome_one';
const _outcomeTwoId = 'restore_outcome_two';

const _outcomeOneEventId = 'evt_019abcde-3000-7000-8000-000000000001';
const _outcomeTwoEventId = 'evt_019abcde-3000-7000-8000-000000000002';
const _mapEnterEventId = 'evt_019abcde-3000-7000-8000-000000000003';

const _outcomeOneConsumerSceneId = 'scene_restore_sets_fact_a';
const _outcomeTwoConsumerSceneId = 'scene_restore_sets_fact_b';
const _mapEnterConsumerSceneId = 'scene_restore_sets_fact_c';

const _factA = 'fact.restore.outcome_one_processed';
const _factB = 'fact.restore.outcome_two_processed_after_a';
const _factC = 'fact.restore.map_enter_processed_after_b';

const _deliveryOneId = 'outd_019abcde-3000-7000-8000-000000000011';
const _deliveryTwoId = 'outd_019abcde-3000-7000-8000-000000000012';
const _causationExecutionId = 'evx_019abcde-3000-7000-8000-000000000013';
const _rootCorrelationId = 'corr_019abcde-3000-7000-8000-000000000014';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saveRestore drains pending outcomes FIFO before mapEnter', () async {
    final project = _project();
    final game = PlayableMapGame(
      bundle: RuntimeMapBundle(
        manifest: project,
        map: _map(),
        projectRootDirectory: '/tmp/save_restore_outbox',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      projectFilePath: '/tmp/save_restore_outbox/project.json',
      saveData: SaveData(
        saveId: 'save-restore-outbox',
        currentMapId: _mapId,
        playerPosition: const GridPos(x: 1, y: 1),
        narrativeEventProgress: NarrativeEventProgress(
          pendingNarrativeOutcomeDeliveries: <NarrativeOutcomeDelivery>[
            _delivery(
              deliveryId: _deliveryOneId,
              outcome: _outcomeOne,
            ),
            _delivery(
              deliveryId: _deliveryTwoId,
              outcome: _outcomeTwo,
            ),
          ],
        ),
      ),
      initialMapActivationReason: MapActivationReason.saveRestore,
    );

    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    await _waitForActivationDispatch(game);

    final state = game.gameStateSnapshot;
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factA, true),
      reason: 'The FIFO head must execute the first outcome Event.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factB, true),
      reason: 'The second outcome is eligible only after fact A is committed.',
    );
    expect(
      state.narrativeFactRuntimeState.overridesByFactId,
      containsPair(_factC, true),
      reason: 'mapEnter is eligible only after fact B is committed.',
    );
    expect(
      state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
      isEmpty,
    );
    expect(
      state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
      {_deliveryOneId, _deliveryTwoId},
    );
    expect(game.debugCompletedMapActivationDispatchCount, 1);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.saveRestore,
    );
  });
}

Future<void> _waitForActivationDispatch(PlayableMapGame game) async {
  for (var i = 0; i < 240; i++) {
    if (!game.debugIsMapActivationDispatchInFlight) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the saveRestore outbox dispatch.');
}

final NarrativeOutcomeRef _outcomeOne = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeOneProducerSceneId,
  outcomeId: _outcomeOneId,
);

final NarrativeOutcomeRef _outcomeTwo = NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: _outcomeTwoProducerSceneId,
  outcomeId: _outcomeTwoId,
);

ProjectManifest _project() {
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(
        id: _outcomeOneEventId,
        name: 'Restore outcome one',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeOne),
        sceneId: _outcomeOneConsumerSceneId,
      ),
      _eventRecord(
        id: _outcomeTwoEventId,
        name: 'Restore outcome two after A',
        source: NarrativeEventSourceRef.outcomeReceived(_outcomeTwo),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factA, true),
        ],
        sceneId: _outcomeTwoConsumerSceneId,
      ),
      _eventRecord(
        id: _mapEnterEventId,
        name: 'Map enter after restored outcomes',
        source: NarrativeEventSourceRef.mapEnter(_mapId),
        conditions: <NarrativeEventCondition>[
          NarrativeEventCondition.fact(_factB, true),
        ],
        sceneId: _mapEnterConsumerSceneId,
      ),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );

  return ProjectManifest(
    name: 'Save restore outbox integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Save Restore Outbox Map',
        relativePath: 'maps/save_restore_outbox_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: _factA, label: 'Outcome one processed'),
      NarrativeFactDefinition(id: _factB, label: 'Outcome two processed'),
      NarrativeFactDefinition(id: _factC, label: 'Map enter processed'),
    ],
    eventRegistry: registry,
    scenes: <SceneAsset>[
      _outcomeProducerScene(
        id: _outcomeOneProducerSceneId,
        outcomeId: _outcomeOneId,
      ),
      _outcomeProducerScene(
        id: _outcomeTwoProducerSceneId,
        outcomeId: _outcomeTwoId,
      ),
      _factScene(id: _outcomeOneConsumerSceneId, factId: _factA),
      _factScene(id: _outcomeTwoConsumerSceneId, factId: _factB),
      _factScene(id: _mapEnterConsumerSceneId, factId: _factC),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

NarrativeEventRecord _eventRecord({
  required String id,
  required String name,
  required NarrativeEventSourceRef source,
  required String sceneId,
  List<NarrativeEventCondition> conditions = const <NarrativeEventCondition>[],
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: 0,
    ),
    enabled: true,
  );
}

SceneAsset _outcomeProducerScene({
  required String id,
  required String outcomeId,
}) {
  return SceneAsset(
    id: id,
    name: 'Outcome producer $outcomeId',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: outcomeId, label: outcomeId),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _factScene({required String id, required String factId}) {
  return SceneAsset(
    id: id,
    name: 'Set $factId',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

NarrativeOutcomeDelivery _delivery({
  required String deliveryId,
  required NarrativeOutcomeRef outcome,
}) {
  return NarrativeOutcomeDelivery(
    deliveryId: deliveryId,
    outcome: outcome,
    causationExecutionId: _causationExecutionId,
    rootCorrelationId: _rootCorrelationId,
    depth: 0,
    attemptCount: 0,
  );
}

MapData _map() => const MapData(
      id: _mapId,
      name: 'Save Restore Outbox Map',
      size: GridSize(width: 3, height: 3),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    );
````

---

Fin de l'Evidence Pack NS-EVENT-V2-19.
