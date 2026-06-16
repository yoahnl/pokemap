# NS-EVENT-01 — Event Builder Existing Surface / Contract Alignment Audit

Date : 2026-06-16

Statut : DONE — audit / cadrage / contrat produit-technique uniquement.

## 1. Résumé exécutif

Le futur Event Builder peut et doit réutiliser l'existant. Le repo possède déjà le socle nécessaire pour un MVP strict :

- `MapEventDefinition` et `MapEventPage` comme racine de stockage des événements de map ;
- `MapEventSceneTarget` comme lien authoring Event -> Scene ;
- `ScriptCondition` et `EventPageResolver` comme base de résolution de page active ;
- `SceneAsset` et `SceneEventRuntimeHook` comme exécution Scene V1 depuis un event ;
- `SceneConsequence` et `SceneConsequenceRuntimeWriter` comme mécanisme de conséquences persistantes ;
- `GameState.consumedEventIds`, `StoryFlags` et `PlayerProgression.completedStepIds` comme état runtime persistant ;
- `WorldRuleDefinition` comme projection visible du monde depuis facts / steps / consumed events ;
- `EventPropertiesPanel` comme surface legacy actuelle de configuration de page/event.

Verdict principal :

```text
Event Builder MVP : réutiliser MapEventDefinition / MapEventPage.
Action principale MVP : lancer une Scene via MapEventSceneTarget.
Conséquences MVP : déclarées par la Scene et appliquées via SceneConsequenceRuntimeWriter.
World Rules : projection et preview, pas édition complète dans l'Event Builder.
Dialogue / Cinematic / Battle directs : hors MVP, passer par Scene.
```

Estimation précédente confirmée :

| Périmètre | Estimation confirmée | Commentaire |
|---|---:|---|
| MVP ultra-minimal | 6-8 lots | Possible seulement si le MVP se limite à Event -> Scene + conditions simples + diagnostics. |
| MVP honnête utilisable | 10-14 lots | Estimation réaliste pour une UI no-code, sauvegarde, diagnostics et runtime bridge propre. |
| V1 proche de l'image | 18-24 lots | Nécessite outcomes, réactions par outcome, bibliothèque de blocs, inspector riche et polish. |
| Version prudente PokeMap | 24-32 lots | Inclut Visual Gates, bis probables, validator, smoke Selbrume-like et dette legacy. |

## 2. Verdict : Event Builder peut-il réutiliser l'existant ?

Oui.

La bonne trajectoire n'est pas de créer un `EventAsset` parallèle ni un mini moteur de script. Le stockage actuel `MapEventDefinition` + `MapEventPage` porte déjà la source spatiale, le type d'event, les pages, les conditions et le lien vers une Scene V1. Le runtime possède déjà un hook qui exécute une Scene ciblée par une page d'event et applique ses conséquences.

Le risque principal est de confondre l'Event Builder avec un Scene Builder bis. L'Event Builder doit répondre à :

```text
Quand démarre-t-on ?
Sous quelles conditions ?
Quelle Scene démarre ?
Quand l'événement est-il consommé ?
Quels changements persistants l'utilisateur doit-il comprendre ?
```

Il ne doit pas porter :

```text
les nodes de dialogue,
les blocks de cinématique,
le déroulé battle,
les outcomes internes complexes,
les règles de projection du monde,
un script libre.
```

## 3. État actuel des surfaces Event

| Surface | Statut | Rôle actuel | Réutilisable pour MVP ? | Risque | Décision recommandée |
|---|---|---|---|---|---|
| `MapEventDefinition` | DONE | Event de map avec `id`, `title`, `pages`, `position`, `type`, `metadata`. | Oui | Trop bas niveau si exposé tel quel. | Racine de stockage canonique MVP. |
| `MapEventPage` | DONE | Page active avec condition, script legacy, message, Scene target, disabled/hidden, metadata. | Oui | Mélange legacy script/message et Scene V1. | Garder, mais exposer via read model no-code. |
| `MapEventSceneTarget` | DONE | Lien Event page -> SceneAsset. | Oui | Aujourd'hui wording UI dit encore "runtime Scene à venir" côté editor. | Action principale MVP : "Jouer une Scene". |
| `MapEventPage.condition` | PARTIAL | `ScriptCondition` runtime-compatible. | Oui | Vocabulaire technique `flag`, `variable`, JSON brut. | Encapsuler avec conditions no-code Fact / Step / Event consommé. |
| `MapEventPage.script` | LEGACY | Référence script ancienne. | Non pour MVP | Peut recréer un moteur libre si promu. | Garder en compatibilité avancée, ne pas promouvoir. |
| `MapEventPage.message` | LEGACY | Message direct sur event/page. | Non pour MVP | Peut court-circuiter Dialogue/Scene. | Garder legacy, avertir si coexiste avec Scene target. |
| `MapEventPage.metadata` | PARTIAL | Extension flexible. | Oui avec prudence | Risque de modèle caché non typé. | Seulement comme stockage backward-compatible si NS-EVENT-02 le justifie, avec helpers typés. |
| `SceneAsset` | DONE/PARTIAL | Graphe Scene V1, nodes, runtime plan. | Oui | Event Builder pourrait dupliquer ses responsabilités. | L'Event lance une Scene, la Scene orchestre le déroulé. |
| `SceneConsequence` | PARTIAL | `setFact`, `markEventConsumed`. | Oui | Pas encore `completeStep` comme consequence canonique. | Réutiliser, étendre plus tard si nécessaire. |
| `SceneConsequenceRuntimeWriter` | DONE/PARTIAL | Applique `setFact` et `markEventConsumed` dans `GameState`. | Oui | Ne couvre pas encore toutes les conséquences V1 souhaitées. | Moteur de commit post-Scene MVP. |
| `SceneEventRuntimeHook` | DONE/PARTIAL | Exécute une Scene ciblée par event/page, applique consequences. | Oui | Nécessite contexte runtime et GameState pour consequences. | Runtime bridge canonique, pas un nouveau bridge Event. |
| `WorldRuleDefinition` | DONE/PARTIAL | Projection depuis fact / step / consumed event vers entité/dialogue/event. | Oui en lecture | Event Builder pourrait devenir World Rules Builder. | Montrer les effets visibles liés, édition complète ailleurs. |
| `GameState.consumedEventIds` | DONE | Persistance des events consommés. | Oui | Consommation au mauvais moment = pertes de progression. | Consommer après succès Scene/consequence commit, pas au trigger. |
| `EventPropertiesPanel` | PARTIAL/LEGACY | Inspector actuel de map event, Scene V1, conditions, World Rules ciblées. | Oui comme source | UI dense, JSON brut, labels techniques. | Conserver temporairement, encapsuler/remplacer progressivement. |
| `EventSceneLinkDiagnostics` | DONE | Diagnostics Event -> Scene : cible manquante, page disabled, content legacy mixé, runtime plan. | Oui | Couvre le lien Scene, pas tout le futur Event Builder. | Réutiliser et étendre par read model Event Builder. |
| `NarrativeValidator` | PARTIAL | Analyse flags/facts/story steps et références narratives. | Oui indirectement | Pas un validator global "projet jouable" complet. | Brancher plus tard dans validator Event. |
| `BetaPlayabilityValidator` | PARTIAL | Diagnostics bêta gameplay/projet. | Oui indirectement | Trop large pour l'Event Builder MVP. | Garder pour validation globale, pas MVP editor. |

## 4. Analyse `MapEventDefinition` / `MapEventPage`

Preuve lue :

- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/operations/map_events.dart`
- `packages/map_core/test/map_events_test.dart`

`MapEventDefinition` porte déjà l'identité de l'événement, son type (`actor`, `object`, `triggerZone`, `effect`), sa position et ses pages. `MapEventPage` porte déjà le comportement activable via condition et la compatibilité legacy.

Décision recommandée :

```text
NS-EVENT-02 ne doit pas créer de second modèle Event.
NS-EVENT-02 doit définir un contrat typé par-dessus MapEventDefinition/MapEventPage.
Le stockage peut rester compatible avec MapEventPage, mais l'API Event Builder doit être no-code et typée.
```

Le MVP ne doit pas exposer `pageNumber`, `script`, `metadata` ou un JSON brut comme workflow principal. Ces surfaces peuvent rester en mode avancé ou migration.

## 5. Analyse `MapEventSceneTarget`

Preuve lue :

- `MapEventSceneTarget` est présent dans `map_event_definition.dart`.
- Les opérations `setMapEventPageSceneTarget` et `clearMapEventPageSceneTarget` existent.
- `map_events_test.dart` couvre encode/decode, set/clear et validations.
- `EventPropertiesPanel` expose un dropdown `Scene V1`.
- `event_scene_link_diagnostics_test.dart` couvre les liens inconnus, vides, pages disabled, scenes invalides et contenu legacy mixé.

Décision :

```text
L'action principale MVP est "Jouer une Scene".
Elle s'appuie sur MapEventPage.sceneTarget.
```

Raison :

- c'est déjà sérialisé ;
- c'est déjà testé ;
- c'est déjà diagnostiqué ;
- le runtime hook sait le consommer ;
- cela évite de créer dans l'Event Builder des actions directes Dialogue/Cinematic/Battle qui appartiennent à la Scene.

Limite actuelle :

`EventPropertiesPanel` affiche encore :

```text
Lien authoring uniquement, runtime Scene à venir.
```

Cette phrase est désormais à revalider dans un futur lot, car `SceneEventRuntimeHook` existe. Elle peut rester vraie pour le Map Editor authoring si le runtime complet n'est pas branché dans tous les chemins, mais elle est trop pessimiste pour le futur Event Builder.

## 6. Analyse conditions existantes

Surfaces lues :

- `MapEventPage.condition`
- `ScriptCondition`
- `EventPageResolver`
- `ScriptConditionEvaluator`
- `EventPropertiesPanel`
- `WorldRuleSourceKind`

Conditions runtime déjà évaluables :

```text
allOf / anyOf / not
flagIsSet / flagIsUnset
variableEquals / variableGreaterThan / variableLessThan
fieldAbilityUnlocked
partyHasMove / partyHasUsableMove
eventIsConsumed
playerOnMap
```

Le panel actuel expose des modes condition :

```text
Aucune
Flag actif
Flag inactif
Event consommé
JSON brut
```

Contrat MVP recommandé :

| Condition | MVP | Source actuelle | Remarque |
|---|---:|---|---|
| Fact vrai/faux | Oui | `ScriptCondition.flagIsSet/Unset` via `NarrativeFactDefinition.legacyFlagName` ou `id` | L'utilisateur choisit un Fact, pas un flag. |
| Story Step completed/not completed | Oui si mappable sans gros refactor | `GameState.progression.completedStepIds` + WorldRule support existe | Il faudra peut-être un helper typé si `ScriptCondition` ne le porte pas proprement. |
| Event consumed/not consumed | Oui | `ScriptCondition.eventIsConsumed` + `GameState.consumedEventIds` | Déjà cohérent avec World Rules. |
| Player on map | Non MVP principal | `ScriptCondition.playerOnMap` | Source spatiale de l'event couvre déjà ce cas dans beaucoup de flux. |
| Variables libres | V1/V2 | `ScriptCondition.variable*` | Trop technique pour MVP no-code. |
| Party/move/field ability | V1/V2 | `ScriptCondition` | Utile gameplay, mais hors premier Event Builder. |
| JSON brut | Legacy only | `EventPropertiesPanel` | Ne pas promouvoir. |

Stratégie de non-régression :

```text
Lire et préserver les ScriptCondition existantes.
Ajouter un read model Event Builder qui traduit seulement le sous-ensemble no-code supporté.
Afficher les conditions non supportées en "Condition avancée existante", pas les supprimer.
```

## 7. Analyse `SceneConsequence` / runtime writer

Surfaces lues :

- `packages/map_core/lib/src/models/scene_consequence.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`

Conséquences actuellement disponibles :

```text
SceneConsequence.setFact
SceneConsequence.markEventConsumed
```

Le writer applique :

- `setFact` via `GameStateMutations.setFlag` / `clearFlag`, en vérifiant que le Fact existe ;
- `markEventConsumed` via `GameStateMutations.markEventConsumed`, en vérifiant map et event ;
- commit atomique côté hook : en cas d'erreur, le résultat échoue sans prétendre que les conséquences ont été appliquées.

Décision recommandée :

```text
L'Event Builder MVP déclare une Scene à jouer.
Les conséquences persistantes sont produites par la Scene et appliquées après completion.
L'Event Builder peut préconfigurer ou aider à comprendre ces consequences, mais ne doit pas créer un writer parallèle.
```

Point à clarifier pour V1 :

`GameStateMutations.completeStep` existe, mais `SceneConsequence` ne contient pas encore `completeStep`. Si la Golden Slice exige `Scene consequence -> Story Step`, NS-EVENT-02/03 devra soit documenter un gap, soit prévoir un lot dédié hors Event Builder strict.

## 8. Analyse `GameState` / consumed events / facts / steps

Surfaces lues :

- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_core/lib/src/projection/world_rule_projection.dart`

État persistant déjà présent :

```text
GameState.storyFlags.activeFlags
GameState.scriptVariables
GameState.progression.completedStepIds
GameState.consumedEventIds
```

Mutations déjà présentes :

```text
setFlag
clearFlag
markEventConsumed
completeStep
```

Projection World Rules déjà capable de lire :

```text
WorldRuleSourceKind.fact
WorldRuleSourceKind.storyStepCompletion
WorldRuleSourceKind.consumedEvent
```

Comportement MVP recommandé pour la consommation d'event :

```text
Un event one-shot est marqué consommé après réussite de la Scene et commit des conséquences.
Il n'est pas marqué consommé au moment du trigger.
Un event réutilisable ne marque pas consumed automatiquement.
Une page disabled reste une page disabled legacy, pas un consumed runtime.
```

Pourquoi :

- consommer au trigger peut perdre la progression si la Scene échoue ou attend un dialogue/cinematic ;
- `SceneEventRuntimeHook` sait déjà attendre des steps asynchrones avant commit ;
- `GameState.consumedEventIds` est déjà persistant et utilisé par conditions/world rules.

## 9. Analyse `EventPropertiesPanel` actuel

Surfaces lues :

- `packages/map_editor/lib/src/ui/panels/event_properties_panel.dart`
- `packages/map_editor/test/event_properties_panel_scene_target_test.dart`

Ce panel apporte déjà :

- sélection d'une Scene V1 via dropdown ;
- empty state "Aucune Scene V1 disponible" ;
- retrait de Scene ;
- conditions simples ;
- mode avancé JSON brut ;
- section World Rules ciblées ;
- diagnostic de Fact absent sur World Rule ;
- avertissement si legacy message/script coexiste avec Scene V1.

Problème produit :

L'EventPropertiesPanel est un inspector de map event, pas encore un Event Builder no-code. Il est trop bas niveau pour la cible UX : il parle de Scene V1, de JSON brut, de page, et conserve les chemins legacy.

Décision recommandée :

```text
Conserver temporairement EventPropertiesPanel.
Ne pas le supprimer dans le MVP.
Le futur Event Builder doit réutiliser ses opérations/read models quand c'est sain,
mais proposer une surface guidée séparée ou encapsulée.
```

Stratégie progressive :

1. NS-EVENT-02/03 : contrat/read model par-dessus l'existant.
2. NS-EVENT-04+ : liste Event Builder lisible, groupée par map/source.
3. NS-EVENT-05+ : editor MVP qui écrit les mêmes surfaces.
4. Plus tard : réduire le panel legacy à un mode avancé.

## 10. Analyse `SceneEventRuntimeHook` actuel

Surfaces lues :

- `packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart`
- `packages/map_runtime/test/scene_event_runtime_hook_test.dart`
- `packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart`

Le hook :

- ignore les pages sans `sceneTarget` ;
- échoue clairement si la Scene cible est absente ;
- lance les diagnostics Scene ;
- construit un `SceneRuntimePlan` ;
- exécute la Scene via `SceneRuntimeExecutor` ;
- collecte les consequences ;
- applique les consequences si un `GameState` est fourni ;
- retourne un `updatedGameState` sans muter l'état d'entrée.

Les tests couvrent notamment :

- page sans Scene cible => `notHandled` ;
- Scene manquante ;
- diagnostics Scene ;
- runtime plan non buildable ;
- dialogue/battle/cinematic async avant commit ;
- `setFact` ;
- `markEventConsumed` ;
- non-mutation du `GameState` original ;
- échecs de consequence.

Décision :

```text
SceneEventRuntimeHook est le pont runtime Event -> Scene à réutiliser.
NS-EVENT ne doit pas créer de nouveau runtime bridge avant d'avoir prouvé un gap réel.
```

## 11. Frontières produit finales recommandées

| Domaine | Responsabilité | Ce que l'Event Builder peut faire | Ce qu'il ne doit pas faire |
|---|---|---|---|
| Event | Déclenchement, conditions, Scene cible, comportement one-shot/reusable, compréhension des effets persistants. | Configurer "Quand / Si / Alors Scene / Puis état". | Orchestrer des nodes internes ou écrire du script libre. |
| Scene | Déroulé après déclenchement. | Être choisie comme action principale. | Être recréée dans l'Event Builder. |
| Cinematic | Mise en scène linéaire. | Être lancée via une Scene. | Être lancée directement en MVP. |
| Dialogue/Yarn | Texte, choix, outcomes dialogue. | Être référencé indirectement via Scene. | Être édité dans l'Event Builder. |
| Battle | Combat, victoire/défaite, rewards combat. | Être référencé via Scene et outcomes V1. | Coupler l'Event Builder au moteur battle. |
| Fact/Step | État persistant et progression. | Choisir conditions et afficher conséquences. | Forcer l'utilisateur à manipuler des flags bruts. |
| World Rules | Projection visible du monde. | Afficher les effets liés à un Fact/Step/Consumed Event. | Devenir l'éditeur complet World Rules. |
| Validator | Sécurité et readiness. | Afficher diagnostics Event. | Remplacer le validator global. |

## 12. Contrat Event Builder MVP recommandé

MVP recommandé :

```text
Créer / éditer un MapEventDefinition existant.
Choisir une source simple : PNJ/acteur de map ou zone trigger.
Choisir un trigger no-code : interaction PNJ ou entrée zone.
Choisir une Scene cible obligatoire pour l'action principale.
Ajouter conditions simples : Fact vrai/faux, Step completed/not completed si contrat supporté, Event consumed/not consumed.
Choisir comportement : une seule fois / réutilisable.
Afficher les conséquences déclarées par la Scene : setFact, markEventConsumed.
Afficher les World Rules liées comme "changements visibles".
Diagnostiquer : Scene absente, condition invalide, Fact/Step/Event inconnu, mélange legacy, Event sans action.
Sauvegarder dans les surfaces existantes sans créer un second modèle Event.
```

Stockage recommandé :

```text
MapEventDefinition reste canonique.
MapEventPage reste l'unité activable.
MapEventPage.sceneTarget porte "Jouer une Scene".
MapEventPage.condition porte les conditions compilées depuis le read model no-code.
MapEventPage.metadata peut porter des metadata Event Builder strictement typées par helper si besoin, mais pas comme API publique.
```

API/read model recommandé :

```text
EventBuilderEventView
EventBuilderTriggerBinding
EventBuilderConditionBinding
EventBuilderSceneActionBinding
EventBuilderBehaviorBinding
EventBuilderWorldImpactPreview
EventBuilderDiagnostic
```

Ces noms sont conceptuels : NS-EVENT-02 doit les adapter au style existant, mais la règle est claire : le builder manipule des bindings no-code, pas des maps de metadata.

## 13. Contrat Event Builder V1 recommandé

V1 proche de l'image cible :

```text
Liste d'events groupée par map/zone.
Statuts : actif, brouillon, inactif.
Bibliothèque de blocs guidés.
Canvas vertical structuré, pas graph libre.
Conditions multiples avec mode "toutes" / "une".
Actions : jouer Scene en principal, autres actions directes seulement si elles restent de simples raccourcis vers Scene.
Résultats possibles : victoire, défaite, échec, success générique.
Réactions par outcome : setFact, markEventConsumed, item/money si les systèmes existent.
Changements du monde : preview World Rules liées, édition profonde dans World Rules.
Inspector événement lisible.
Validation Event locale + contribution au validator global.
```

V2 :

```text
Drag/drop complet.
Graph libre.
Conditions imbriquées complexes.
Simulation runtime riche.
Actions directes multiples.
Rewards avancées.
Battle authoring.
World Rules authoring complet inline.
Diff visuel du monde.
```

## 14. Matrice UI cible -> surfaces repo

| Bloc UI cible | Existant repo | Statut | MVP | V1 | V2 | Danger de scope |
|---|---|---|---:|---:|---:|---|
| Déclencheur | `MapEventDefinition.type`, position, map entities/events | PARTIAL | Oui | Oui | Non | Ne pas inventer un système de trigger parallèle. |
| Conditions | `MapEventPage.condition`, `ScriptCondition`, WorldRule source types | PARTIAL | Oui sous sous-ensemble | Oui | Oui | JSON brut et variables libres trop techniques. |
| Actions | `MapEventSceneTarget` | PARTIAL/DONE | Scene only | Scene + raccourcis encadrés | Multi-actions | Dialogue/Battle direct recrée la Scene. |
| Résultats possibles | Scene/battle/dialogue outcomes côté Scene runtime | PARTIAL/MISSING Event | Non | Oui | Oui | Couplage battle si fait trop tôt. |
| Réactions | `SceneConsequence` | PARTIAL | setFact/markConsumed via Scene | Par outcome | Avancé | Event writer parallèle. |
| Changements du monde | `WorldRuleDefinition`, target context read model | PARTIAL | Preview | Preview + liens | Edition inline avancée | Event Builder devient World Rules Builder. |
| Comportement | `consumedEventIds`, page disabled/hidden | PARTIAL | One-shot/reusable | Priorité/reset | Avancé | Consommer au mauvais moment. |
| Inspecteur | `EventPropertiesPanel` | PARTIAL/LEGACY | Réutiliser/inspirer | Remplacer progressivement | Avancé | Réintroduire JSON comme workflow. |
| Liste événements | maps/events existants | PARTIAL | Liste simple | Groupée map/zone/statut | Recherche avancée | Trop de shell UI avant contrat. |
| Bibliothèque éléments | Pas de surface Event dédiée | MISSING | Non | Oui | Oui | Drag/drop prématuré. |
| Aperçu/Valider | diagnostics Event->Scene, Scene diagnostics, validators | PARTIAL | Diagnostics | Preview/test | Simulation | Promettre "jouable" trop tôt. |

## 15. Matrice MVP / V1 / V2

| Fonction | MVP | V1 | V2 | Justification |
|---|---:|---:|---:|---|
| Trigger PNJ | Oui | Oui | Oui | Source canonique la plus simple et centrale. |
| Trigger zone | Oui | Oui | Oui | `MapEventType.triggerZone` existe déjà. |
| Conditions Fact | Oui | Oui | Oui | Essentiel pour progression no-code. |
| Conditions Step | Oui si contrat clair | Oui | Oui | Nécessaire Golden Slice, mais peut demander helper. |
| Conditions Event consumed | Oui | Oui | Oui | Déjà supporté par ScriptCondition et World Rules. |
| Action Jouer Scene | Oui | Oui | Oui | Action principale canonique MVP. |
| Action Dialogue directe | Non | Optionnel | Oui | Doit passer par Scene pour éviter duplication. |
| Action Cinematic directe | Non | Optionnel | Oui | Même raison. |
| Action Battle directe | Non | Optionnel via Scene outcome | Oui | Éviter couplage au moteur battle. |
| SetFact | Oui via SceneConsequence | Oui | Oui | Déjà writer/runtime. |
| CompleteStep | À trancher | Oui | Oui | Mutation existe, consequence dédiée absente. |
| MarkEventConsumed | Oui | Oui | Oui | Déjà writer/runtime. |
| Rewards item/money | Non | Optionnel si systèmes prêts | Oui | Trop gameplay pour MVP Event. |
| Outcomes victory/defeat | Non | Oui | Oui | Dépend Scene/Battle outcome contract. |
| Reactions par outcome | Non | Oui | Oui | Nécessite outcome model. |
| World changes | Preview seulement | Oui via World Rules | Oui | Projection appartient aux World Rules. |
| World Rules preview | Oui | Oui | Oui | Aide no-code sans devenir editor complet. |
| Drag/drop | Non | Non strict V1 | Oui | Peut exploser le coût UI. |
| Simulation | Non | Simple preview/diagnostic | Oui | Demande runtime harness. |
| Validator global | Non | Partiel | Oui | MVP doit fournir diagnostics locaux. |
| Selbrume smoke | Non | Oui | Oui | Après contrat + runtime bridge stable. |

## 16. Risques et pièges à éviter

| Risque | Impact | Mesure recommandée |
|---|---|---|
| Créer un `EventAsset` parallèle | Très élevé | Réutiliser `MapEventDefinition`. |
| Promouvoir `metadata` comme modèle principal | Élevé | Helpers typés + tests de compatibilité. |
| Lancer Dialogue/Cinematic/Battle directement en MVP | Élevé | Tout passe par Scene. |
| Consommer l'event au trigger | Élevé | Consommer après completion/commit. |
| Afficher IDs/flags comme workflow principal | Élevé UX | Pickers Fact/Step/Event + labels humains. |
| Event Builder devient World Rules Builder | Moyen/élevé | Afficher preview, édition dans World Rules. |
| Réécrire `SceneEventRuntimeHook` | Élevé | Réutiliser; seulement étendre si gap prouvé. |
| Gros lot UI avant contrat | Élevé | NS-EVENT-02/03 d'abord. |
| Drag/drop prématuré | Moyen/élevé | Canvas vertical structuré d'abord. |
| Ignorer legacy `script/message` | Moyen | Diagnostics "contenu legacy mixé" et mode avancé. |

## 17. Décisions ouvertes à faire valider par Yoahn / Karim

| Décision | Options | Recommandation | Bloquant NS-EVENT-02 ? |
|---|---|---|---|
| Stockage Event Builder | Nouveaux champs typés / metadata typée / modèle parallèle | `MapEventDefinition` + `MapEventPage`, helpers typés ; metadata seulement si backward-compatible. | Oui, partiellement. |
| Action principale MVP | Scene only / actions directes / liste actions | Scene only. | Oui. |
| Conditions Step | Ajouter helper sur progression / encoder en variable / repousser | Helper typé si possible ; ne pas encoder comme variable opaque. | Oui si MVP exige Step. |
| CompleteStep consequence | Ajouter `SceneConsequence.completeStep` / gérer via runtime autre / repousser | Lot séparé si nécessaire ; ne pas bricoler dans Event. | Non pour Event->Scene strict, oui pour Golden Slice complète. |
| Consommation one-shot | Au trigger / après Scene / après outcome success | Après Scene + commit consequences. | Oui. |
| Outcomes victory/defeat | Event outcomes / Scene outcomes / Battle direct | Scene outcomes, Event reactions V1. | Non pour MVP, oui pour V1. |
| World changes | Edition inline / preview / lien vers workspace | Preview + lien vers World Rules. | Non. |
| Legacy EventPropertiesPanel | Remplacer / garder / encapsuler | Garder temporairement, encapsuler progressivement. | Non. |
| NS-EVENT-02+03 groupés | Oui / non / oui sous conditions | Oui sous conditions strictes, mais split recommandé par défaut. | Décision de planning. |

## 18. Impact sur NS-EVENT-02

Prochain lot recommandé :

```text
NS-EVENT-02 — Event Builder Core Contract / Typed Authoring Bindings Prep
```

Objectif exact recommandé :

```text
Définir le contrat map_core pur qui traduit l'existant Event en bindings Event Builder no-code :
- trigger/source binding ;
- condition bindings MVP ;
- scene action binding ;
- behavior binding one-shot/reusable ;
- world impact preview contract ;
- diagnostics contract ;
sans UI, sans runtime nouveau, sans migration large.
```

Critères de sortie NS-EVENT-02 :

- aucun modèle parallèle ;
- `MapEventDefinition` reste canonique ;
- read/write helpers typés ;
- JSON legacy préservé ;
- tests de compatibilité `MapEventPage` / `MapEventSceneTarget` / `ScriptCondition` ;
- décision explicite sur Step condition et CompleteStep gap.

Ce que NS-EVENT-02 ne doit pas faire :

- pas de widget ;
- pas de drag/drop ;
- pas de Event Builder écran ;
- pas de nouveau runtime hook ;
- pas de données Selbrume.

## 19. Peut-on grouper NS-EVENT-02 et NS-EVENT-03 ?

Réponse : oui sous conditions strictes, mais ce n'est pas la recommandation par défaut.

Conditions minimales pour grouper :

```text
Le contrat de stockage reste trivial.
Aucun nouveau champ généré/freezed n'est requis.
Aucune migration JSON n'est requise.
Le read model dépend seulement des surfaces existantes.
Les tests restent bornés à map_core.
Aucune UI map_editor n'est touchée.
Le lot garde une taille M, pas L/XL.
```

Pourquoi je recommande plutôt de séparer :

- NS-EVENT-02 doit décider les bindings typés et les limites du stockage ;
- NS-EVENT-03 devrait construire le read model utilisable par l'UI ;
- mélanger les deux augmente le risque de figer trop vite un contrat encore fragile ;
- le prompt PokeMap/Codex fonctionne mieux avec un lot de contrat, puis un lot read model.

Décision pratique :

```text
Si NS-EVENT-02 conclut "aucune schema change, metadata non promue, helpers simples",
alors NS-EVENT-03 peut être fusionné dans un 02-bis court.
Sinon, garder NS-EVENT-03 séparé.
```

## 20. Prochain lot recommandé

```text
NS-EVENT-02 — Event Builder Core Contract / Typed Authoring Bindings Prep
```

But :

```text
Créer le contrat core pur du futur Event Builder, sans UI.
```

Sortie attendue :

```text
Le lot suivant doit pouvoir construire une liste/read model Event Builder depuis MapEventDefinition
sans relire du JSON brut et sans deviner les frontières produit.
```

## 21. Evidence Pack

### Gate 0

Commandes exécutées avant écriture :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sorties exactes utiles :

```text
$ pwd
/Users/karim/Project/pokemonProject

$ git branch --show-current
main

$ git status --short --untracked-files=all
<vide>

$ git diff --stat
<vide>

$ git diff --name-only
<vide>

$ git log --oneline -n 20
7b3b2151 FG-NS-EVENT-001: Ajout du plan MVP v1 pour le builder d'événements Narrative Studio
05e70a57 NS-STUDIO-PRODUCT-BETA-READINESS — Audit de préparation pour la bêta de Narrative Studio
da9cce15 NS-SCENES-V1-138 — Selbrume Golden Slice Content Inventory Asset Gap Audit
80dd997a NS-SCENES-V1-137 — Narrative Studio Golden Slice Authoring Readiness Selbrume Demo Content Plan
703c5702 NS-SCENES-V1-136-BIS — Cinematic Builder Legacy Widget Expectations Cleanup
0f9c5cfe NS-SCENES-V1-136 — Cinematic Builder V1 Closure Readiness Audit
2bd11dda NS-SCENES-V1-135 — Cinematic Builder V1 Camera Closure Polish Gate
179cd6aa NS-SCENES-V1-134 — Cinematic Camera Geometry Preview UI V0
28d0e46e NS-SCENES-V1-133 — Cinematic Camera Geometry Playback State V0
d4e0b28b NS-SCENES-V1-132 — Cinematic Camera Target Zoom Editor UI V0
882c2c23 NS-SCENES-V1-131 — Cinematic Camera Target Zoom Core Model V0
a7bb9b42 update selbrume
4c3040a3 update selbrume
47660d78 NS-SCENES-V1-130 — Cinematic Camera Target Zoom Authoring Prep Contract
2344303e update selbrume
3edcfe36 Allow deeper cinematic timeline zoom out
6bb457a4 Polish cinematic emote dropdowns
f16314fe NS-SCENES-V1-129 — Cinematic Emote Preview Playback UI V0
6da6410f NS-SCENES-V1-128 — Cinematic Emote Block Editor UI V0
af8be4ac update selbrume
```

### Règles lues

Fichiers lus :

```text
AGENTS.md
agent_rules.md
codex_rule.md
skills/README.md
skills/writing-plans/SKILL.md
skills/verification-before-completion/SKILL.md
skills/test-driven-development/SKILL.md
```

Application :

- `writing-plans` : utilisé pour structurer un plan exploitable lot par lot ;
- `verification-before-completion` : utilisé pour garder le rapport borné au scope et vérifier l'anti-scope final ;
- `test-driven-development` : lu, mais non appliqué car ce lot est doc-only et ne modifie aucun comportement testable.

### Fichiers lus ou audités

Documentation :

```text
reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/checklist_beta_pokemap.md
MVP Selbrume/selbrume.md
reports/narrativeStudio/ns_studio_product_beta_readiness_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_00_scene_system_scope_current_state_audit.md
reports/narrativeStudio/scenes/ns_scenes_v1_10_bis_scene_builder_runtime_roadmap_alignment.md
```

Code :

```text
packages/map_core/lib/src/models/map_event_definition.dart
packages/map_core/lib/src/operations/map_events.dart
packages/map_core/lib/src/diagnostics/event_scene_link_diagnostics.dart
packages/map_core/lib/src/models/scene_asset.dart
packages/map_core/lib/src/models/scene_consequence.dart
packages/map_core/lib/src/models/world_rule.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart
packages/map_editor/lib/src/ui/panels/world_rule_target_section.dart
packages/map_editor/lib/src/ui/canvas/narrative_studio_sidebar.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart
packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
packages/map_gameplay/lib/src/event_page_resolver.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
```

Tests audités :

```text
packages/map_core/test/map_events_test.dart
packages/map_core/test/event_scene_link_diagnostics_test.dart
packages/map_core/test/narrative_event_source_authoring_operations_test.dart
packages/map_core/test/narrative_validator_test.dart
packages/map_core/test/beta_playability_validator_test.dart
packages/map_editor/test/event_properties_panel_scene_target_test.dart
packages/map_editor/test/facts_world_rules_manager_test.dart
packages/map_runtime/test/scene_event_runtime_hook_test.dart
packages/map_runtime/test/p3_event_source_bridge_validation_test.dart
packages/map_runtime/test/p3_fact_world_rule_projection_test.dart
packages/map_runtime/test/scene_runtime_golden_slice_smoke_test.dart
```

### Commandes d'audit

Commandes représentatives exécutées :

```bash
rg -n "MapEventDefinition|MapEventPage|MapEventSceneTarget|EventPropertiesPanel|SceneEventRuntimeHook|SceneConsequenceRuntimeWriter|SceneConsequence|WorldRule|NarrativeFact|StoryStep|consumedEvent|EventSceneLink|event builder|Event Builder|Scene V1|Lien authoring|JSON brut" packages MVP\ Selbrume reports
rg --files packages | rg -i "storyline|story|scene|cinematic|dialogue|yarn|fact|world|rule|validator|event|runtime|save|load"
rg -n "consumedEventIds|SceneConsequenceKind|complete.*step|setFact|mark.*consum|MapEventSceneTarget|ScriptCondition|WorldRule|NarrativeValidator|BetaPlayability" packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_editor/lib
```

Sorties utiles exactes :

```text
packages/map_core/lib/src/models/game_state.dart:102:    @Default({}) Set<String> consumedEventIds,
packages/map_gameplay/lib/src/game_state_mutations.dart:147:  GameState markEventConsumed(GameState state, String eventId) {
packages/map_gameplay/lib/src/game_state_mutations.dart:528:  GameState completeStep(GameState state, String stepId) {
packages/map_core/lib/src/models/world_rule.dart:3:enum WorldRuleSourceKind {
packages/map_core/lib/src/models/world_rule.dart:18:enum WorldRuleTargetKind {
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart:1080:          key: const ValueKey('event-scene-target-dropdown'),
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart:1082:          fieldLabel: 'Scene V1',
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart:1127:          text: 'Lien authoring uniquement, runtime Scene à venir.',
packages/map_editor/lib/src/ui/panels/event_properties_panel.dart:1224:                ? 'Mode avancé JSON brut'
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart:72:    final executionResult = await SceneRuntimeExecutor(
packages/map_runtime/lib/src/application/scene_runtime/scene_event_runtime_hook.dart:100:      final writeResult = SceneConsequenceRuntimeWriter(
packages/map_runtime/test/scene_event_runtime_hook_test.dart:270:    test('stages markEventConsumed consequence and commits it on completion',
packages/map_runtime/test/scene_event_runtime_hook_test.dart:705:    test('does not apply World Rules or complete StorylineStep directly',
```

### Extraits courts pertinents

`SceneConsequence` :

```text
enum SceneConsequenceKind {
  setFact,
  markEventConsumed,
}
```

`GameState` :

```text
@Default({}) Set<String> consumedEventIds
```

`WorldRuleSourceKind` :

```text
fact
storyStepCompletion
consumedEvent
```

`EventPropertiesPanel` :

```text
Scene V1
Lien authoring uniquement, runtime Scene à venir.
Mode avancé JSON brut
Event consommé
```

### Tests

Aucun test Dart/Flutter n'a été exécuté, car aucun code produit, aucun test produit et aucune donnée runtime n'ont été modifiés. Le lot est strictement documentaire.

### Changements introduits par NS-EVENT-01

Fichier créé :

```text
reports/narrativeStudio/events/ns_event_01_existing_surface_contract_alignment.md
```

Fichiers modifiés :

```text
<aucun autre fichier>
```

Fichiers supprimés :

```text
<aucun>
```

### Gate final

```text
$ git status --short --untracked-files=all
?? reports/narrativeStudio/events/ns_event_01_existing_surface_contract_alignment.md

$ git diff --stat
<vide>

$ git diff --name-only
<vide>

$ git diff --check
<vide>
```

## 22. Auto-review critique

### Passe Architecture

Verdict : OK.

Le plan s'appuie sur les surfaces existantes et évite explicitement un second système Event. La décision "Event lance Scene" respecte la frontière Event / Scene.

### Passe Produit / UX no-code

Verdict : OK avec réserve.

Le rapport évite les flags techniques comme workflow principal, mais NS-EVENT-02 devra faire attention à la traduction Fact/Step vers les structures runtime existantes. C'est le point le plus fragile.

### Passe Runtime

Verdict : OK.

Le rapport ne demande pas de nouveau runtime hook. Il recommande de réutiliser `SceneEventRuntimeHook` et `SceneConsequenceRuntimeWriter`.

### Passe Tests / Evidence

Verdict : OK pour un lot doc-only.

Aucun test n'a été lancé, ce qui est cohérent avec l'absence de changement code. Les suites test existantes ont été auditées par recherche et extraits.

### Passe Anti-scope

Verdict : OK avant Gate final.

Le seul changement attendu est le rapport. Aucune roadmap, aucun code, aucun fichier Selbrume et aucun screenshot ne doivent apparaître au diff final.

### Critique du prompt

Le prompt est très bien cadré pour éviter le piège principal : créer un Event Builder parallèle. Il est cependant exigeant pour un lot doc-only, car il demande de lire beaucoup de surfaces et de trancher des décisions qui touchent au runtime futur. Les décisions `CompleteStep` et outcomes battle ne peuvent pas être entièrement fermées sans un futur lot de contrat Scene/Outcome ou progression. Le rapport tranche donc ce qui est nécessaire au MVP et laisse ces points en décisions ouvertes plutôt que de mentir.

### Réserves majeures

- `SceneConsequence` ne couvre pas encore `completeStep`, alors que la vision bêta demande `Scene consequence -> Story Step`.
- L'UI actuelle `EventPropertiesPanel` contient encore du wording legacy et du JSON brut.
- Les outcomes victory/defeat ne doivent pas être codés dans Event avant un contrat Scene/Battle outcome clair.
- Les World Rules sont exploitables comme projection, mais pas comme édition inline dans le MVP.

Conclusion :

```text
NS-EVENT-01 : DONE.
Le futur Event Builder doit être construit comme une couche no-code au-dessus de MapEventDefinition/MapEventPage,
avec MapEventSceneTarget comme action principale MVP et SceneConsequenceRuntimeWriter comme mécanisme de commit.
```
