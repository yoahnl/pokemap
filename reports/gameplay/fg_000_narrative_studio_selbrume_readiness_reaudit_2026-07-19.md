# FG-000 — Réaudit de readiness Selbrume et correction du retry des combats du phare

Date : 19 juillet 2026  
Nature : réaudit corrigé, implémentation P0, tests de non-régression et preuves de build  
Branche : main  
HEAD de base : a8095b37d3ec6f1e8cafe5b74c5766ec1638380d  
Projet : selbrume/project.json  
SHA-256 après régénération : 2e5ebbeb916f09261d874d3420dc0d32dde1febbf2bd6eb12492f08071d39166  
Référentiels : MVP Selbrume/selbrume.md, MVP Selbrume/narrative_studio.md, pokemap_roadmap_mecaniques_fangame.md  
Lots directement concernés : FG-000, FG-086, FG-087, FG-102, FG-107, FG-140, FG-141, FG-142, FG-146, FG-182, FG-183 et FG-185

## 1. Résumé exécutif

Le défaut bloquant identifié par le réaudit initial est corrigé : une défaite contre le gardien 1, le gardien 2 ou le boss du phare ne consomme plus définitivement leur Event. Les trois rencontres restent disponibles après une défaite et se ferment après la victoire grâce à leur Fact terminal.

La correction est volontairement portée par le contenu canonique :

- les trois Events passent de oneShot à reusable ;
- chacun reçoit une condition négative sur son Fact de victoire ;
- le coordinateur générique Event/Scene, son schéma et le runtime de production ne changent pas ;
- une sauvegarde ancienne contenant déjà l’ID consommé n’est plus empoisonnée par cet ID, puisque la politique reusable ne consulte pas le ledger one-shot ;
- après victoire, le Fact terminal rend l’Event inéligible et une nouvelle entrée reste sans effet.

L’ancien rapport attribuait des scores 66/78/82/86 et 78 % ± 3 sans protocole reproductible. Ils sont retirés. Les axes suivants ne doivent pas être additionnés en un pourcentage unique.

| Axe | Verdict après correction |
|---|---|
| Conformité normative à selbrume.md | **PARTIEL fort** |
| Fermeture no-code du Narrative Studio | **PARTIEL** |
| Robustesse des branches runtime | **PARTIEL fort — le blocker ciblé du phare est fermé** |
| Preuves de release | **PARTIEL fort — runs de référence et builds verts, une variance éditeur consignée, QA humaine absente** |
| Démonstration technique guidée | **GO technique** |
| Démonstration publique autonome | **CANDIDAT GO technique, conditionné à un walkthrough humain et à un package incluant Selbrume** |
| MVP fangame global FG-185 | **PARTIAL / NO-GO inchangé** |

Cette conclusion ne signifie ni que toutes les branches ont été parcourues physiquement, ni qu’aucun autre soft-lock n’existe, ni que le MVP fangame global est terminé.

## 2. Scope confirmé et remise en cause du scope implicite

La demande pouvait être lue comme « implémenter tous les manques du rapport ». Cette lecture aurait mélangé plusieurs chantiers indépendants : mise en scène des cinématiques, authoring no-code complet, Validator, sauvegarde transactionnelle, QA humaine et Golden Slice fangame globale.

Le scope sûr retenu est donc :

1. corriger la méthodologie et les affirmations obsolètes du réaudit ;
2. fermer le P0 fonctionnel certain : défaite puis retry des trois combats du phare ;
3. ajouter les preuves au niveau donnée, bridge de production, runtime physique, sauvegarde sérialisée et suites complètes ;
4. conserver les autres manques comme lots distincts, sans les masquer ni modifier la roadmap.

Hors scope volontaire :

- enrichissement artistique ou audio des cinématiques ;
- ajout d’un diagnostic générique de soft-lock au Validator ;
- walkthrough humain et chronométré ;
- durcissement transactionnel du load ;
- complétion des mécaniques globales FG-181/182/185 ;
- modification de pokemap_roadmap_mecaniques_fangame.md ;
- commit ou push Git.

## 3. Audit initial

### 3.1 État Git initial

Au début de l’implémentation :

    ?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md

Le rapport fourni était le seul fichier non suivi. Aucun fichier suivi n’était modifié. Branche main, HEAD a8095b37d3ec6f1e8cafe5b74c5766ec1638380d.

### 3.2 Contrats existants inspectés

| Contrat | Observation |
|---|---|
| NarrativeEventExecutionCoordinator | Un Event oneShot est consommé lorsqu’une Scene se termine avec succès. |
| Branche de combat defeat | Une défaite est un outcome métier valide et termine correctement la Scene ; ce n’est ni une erreur ni une annulation. |
| NarrativeEventReusePolicy.reusable | Le ledger consumedNarrativeEventIds n’interdit pas une nouvelle exécution. |
| Conditions Fact | Une condition Fact == false ferme proprement une source lorsque le Fact de victoire devient true. |
| Scene runtime | Les branches victory posent les Facts et Steps ; les branches defeat ne les posent pas. |
| SaveData | Facts, progression et ledger des Events sont sérialisés et restaurés. |
| PlayableMapGame | Une défaite rend le contrôle à l’overworld et restaure une party jouable selon la politique existante. |

### 3.3 Fichiers et tests déjà pertinents

- packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart : source canonique des 29 Events ;
- selbrume/project.json : snapshot généré consommé par l’éditeur et le runtime ;
- packages/map_gameplay/lib/src/narrative_event_execution_coordinator.dart : contrat générique de consommation, inspecté mais non modifié ;
- packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart : contrat du seed ;
- packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart : pipeline dresseur réel ;
- packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart : pipeline boss statique réel ;
- examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart : parcours physique victorieux complet ;
- examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart : baseline du snapshot promu.

### 3.4 Risques identifiés avant modification

| Risque | Garde-fou retenu |
|---|---|
| Modifier le coordinateur pour un cas de contenu | Correction dans le seed canonique seulement. |
| Rendre le combat rejouable même après victoire | Condition négative sur le Fact terminal. |
| Casser les sauvegardes existantes | Politique reusable, indépendante d’un ancien ID consommé. |
| Tester uniquement un callback simulé | Deux tests PlayableMapGame utilisent de vrais combats et de vraies sorties/réentrées. |
| Confondre round-trip JSON et sauvegarde disque | La distinction est explicitement conservée dans ce rapport. |
| Déclarer FG-185 terminé par transitivité | Gate globale maintenue PARTIAL / NO-GO. |

## 4. Cause racine et correction

### 4.1 Cause historique

Avant le correctif :

| Rencontre | Event | Ancienne politique | Conséquence d’une défaite |
|---|---|---|---|
| Gardien 1 | evt_…000026 | oneShot | Scene terminée, Event consommé, Fact de victoire absent, gardien 2 bloqué. |
| Gardien 2 | evt_…000027 | oneShot | Scene terminée, Event consommé, Fact de victoire absent, sommet bloqué. |
| Boss Lanturn | evt_…000028 | oneShot | Scene terminée, Event consommé, brume non résolue, épilogue bloqué. |

Le coordinateur se comportait conformément à son contrat. Le défaut était la politique authorée des trois Events.

### 4.2 Politique après correction

| Rencontre | Nouvelle politique | Condition terminale ajoutée | Fermeture |
|---|---|---|---|
| Gardien 1 | reusable | fact_lighthouse_guardian_1_defeated == false | La victoire met le Fact à true. |
| Gardien 2 | reusable | fact_lighthouse_guardian_2_defeated == false | La victoire met le Fact à true. |
| Boss | reusable | fact_mist_source_resolved == false | La victoire résout la brume. |

Une défaite laisse donc l’Event éligible. Le runtime exige volontairement de sortir puis de rentrer à nouveau dans la zone de trigger ; il ne relance pas un combat immédiatement sous les pieds du joueur.

### 4.3 Compatibilité des sauvegardes

La correction ne migre ni ne supprime les anciens consumedNarrativeEventIds. Pour ces trois IDs, ce n’est pas nécessaire : la nouvelle politique reusable ne s’appuie pas sur ce ledger. Les Facts de victoire restent l’autorité terminale.

La preuve automatisée couvre :

- défaite ;
- absence des Facts et Steps de victoire ;
- absence de nouvelle consommation ;
- round-trip SaveData JSON ;
- retry ;
- victoire ;
- second round-trip ;
- nouvelle entrée post-victoire sans combat et sans mutation d’état.

## 5. Inventaire exact du snapshot corrigé

| Objet | Quantité |
|---|---:|
| Maps | 10 |
| Storylines | 4 |
| Scenes | 31 |
| Dialogues | 22 |
| Cinematics | 16 |
| Facts | 49 |
| World Rules | 34 |
| Trainers/profils adverses | 5 |
| Encounter tables | 1 |
| Events V2 | 29 |
| Events configurés et activés | 29 |
| Events oneShot | 24 |
| Events reusable | 5 |

Le changement par rapport au rapport initial est exactement : 27 oneShot / 2 reusable devient 24 oneShot / 5 reusable.

## 6. État fonctionnel de Selbrume

### 6.1 Les douze étapes principales

| Étape | État | Preuve ou limite principale |
|---|---|---|
| 1. Introduction à Selbrume | **PARTIEL** | Flux fonctionnel, mais départ dehors et acceptation largement automatique. |
| 2. Recevoir la mission | **PRÊT Selbrume** | Choix et attribution du starter configuré. |
| 3. Aller au port | **PRÊT Selbrume** | Gates, Yarn, outcome, Facts et progression. |
| 4. Combat rival | **PARTIEL fort** | Vrai combat et outcomes ; conséquences narratives des tons encore limitées. |
| 5. Entrer dans les marais | **PARTIEL** | Progression fonctionnelle, découpage différent d’une lecture stricte de la spec. |
| 6. Trouver trois indices | **PARTIEL fort** | Trois sources et Facts ; Step fermée au retour. |
| 7. Convaincre Soline | **PRÊT Selbrume** | Conditions, dialogue, Fact et ouverture physique. |
| 8. Rejoindre le phare | **PRÊT Selbrume** | Route et arrivée physiques. |
| 9. Explorer le phare | **PRÊT pour le blocker ciblé** | Victoires du parcours complet ; gardien 1 physique defeat→retry ; les deux gardiens couverts par bridge + save round-trip. |
| 10. Apaiser le Pokémon | **PRÊT pour le blocker ciblé** | Boss statique physique defeat→retry→victory ; bridge + save round-trip. |
| 11. Retour au port | **PRÊT Selbrume** | Épilogue et World Rules sur le chemin victorieux. |
| 12. Fin principale | **PRÊT Selbrume** | Fact final, Step et save/load nominal. |

### 6.2 Quêtes annexes

| Quête | État | Limite restante |
|---|---|---|
| Cristaux de sel | **PRÊT sur parcours nominal** | Compteur implicite et récompense substituée. |
| Goélise du port | **PARTIEL fort** | Deux branches E2E ; effets narratifs futurs limités. |
| Cabane du phare | **PRÊT sur happy path** | Refus puis retour/acceptation non parcouru physiquement. |

### 6.3 Narrative Studio : surfaces minimales de production

Ces sept surfaces sont nécessaires pour que le contenu actuel soit réellement réauthorable sans manipuler le JSON.

| Surface minimale | État | Manque principal |
|---|---|---|
| Storyline Graph | **PARTIEL faible** | Branches, convergences, conditions et outcomes sémantiques incomplets. |
| Scene Builder | **PARTIEL fort** | BranchByOutcome absent ; completeStoryStep et plusieurs conséquences restent incomplètes dans les pickers. |
| Event Builder | **PARTIEL** | Couverture des conditions/réactions et suppression encore incomplète. |
| Cinematic Builder | **PARTIEL fort** | Playback de base présent ; authoring audio/FX et chorégraphie riche incomplets. |
| Map Events View | **PARTIEL** | Pas encore un inventaire dédié complet des sources physiques et dépendances par map. |
| Facts / World Rules | **PARTIEL** | Workflow guidé encore dépendant du contexte de map et effets limités. |
| Global Validator | **PARTIEL fort** | Utile en statique, mais ne détecte pas cette classe de soft-lock ni l’atteignabilité physique. |

Cinq surfaces complètent la vision produit sans être toutes minimales pour modifier la campagne actuelle :

| Surface étendue | État |
|---|---|
| Overview | **PARTIEL** |
| Storylines Board | **PARTIEL** |
| Scenes Library | **PARTIEL** |
| Cinematics Library | **PARTIEL** |
| Dialogues | **PRÊT ciblé / PARTIEL générique** |

### 6.4 Cinématiques

Le runtime sait jouer un socle visuel réel : wait, camera, actor move/face/emote, dialogue line, fade et shake. Les 14 cinématiques canoniques de Selbrume restent toutefois composées de beats simples et génériques. Le blocking, les acteurs, la chorégraphie, le son, la musique et les FX ne sont pas au niveau d’une mise en scène publique aboutie.

Cette dette est une dette d’expérience visible. Elle ne remplace pas automatiquement l’ancien soft-lock comme blocker fonctionnel.

### 6.5 Validator

Le Validator vérifie utilement les références, graphes, Facts, Rules, outcomes et plusieurs incohérences statiques. Il ne modélise toujours pas :

- une combinaison outcome defeat + mauvaise politique de consommation ;
- l’atteignabilité physique par collisions et pathfinding ;
- un vrai save/load ;
- tous les conflits de Facts ;
- un auto-fix déterministe.

La donnée courante est corrigée, mais la prévention générique de cette classe de défaut reste un lot distinct.

### 6.6 Gate fangame globale

Selbrume prouve une campagne narrative substantielle. Il ne ferme pas à lui seul les critères globaux tels que capture vers PC, XP/level-up/move learning/évolution en production, shop/heal, badge et field unlock. FG-185 reste donc PARTIAL / NO-GO.

## 7. Preuves fraîches

### 7.1 TDD et tests ciblés

| Étape | Commande | Résultat exact |
|---|---|---|
| RED | cd examples/playable_runtime_host && flutter test test/selbrume_lighthouse_retry_integration_test.dart | **Échec attendu : 3 tests échouent, les trois Events sont consommés après défaite.** |
| Seed canonique | cd packages/map_editor && dart run tool/seed_selbrume_canonical_narrative_content.dart --project-root ../../selbrume | **PASS : selbrume/project.json régénéré.** |
| Contrat du seed | cd packages/map_editor && flutter test test/selbrume_canonical_narrative_seed_test.dart --reporter compact | **PASS : +1, All tests passed.** |
| Retry physique runtime | cd packages/map_runtime && flutter test test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart test/selbrume_static_boss_playable_map_game_integration_test.dart | **PASS : +2, All tests passed.** |
| Retry des trois rencontres + campagnes host | cd examples/playable_runtime_host && flutter test test/selbrume_lighthouse_retry_integration_test.dart test/selbrume_event_v2_promoted_project_test.dart test/selbrume_player_journey_e2e_test.dart --reporter compact | **PASS : +9, All tests passed.** |
| Coordinateur/conditions gameplay | cd packages/map_gameplay && dart test test/narrative_event_execution_coordinator_test.dart test/narrative_event_condition_eligibility_test.dart | **PASS : +8, All tests passed.** |
| Follow-up après renommage du helper de non-rejeu | cd examples/playable_runtime_host && flutter test --no-pub test/selbrume_player_journey_e2e_test.dart --reporter compact | **PASS : +5, All tests passed, en 04:17.** |

### 7.2 Suites complètes

| Package/hôte | Commande | Résultat exact |
|---|---|---|
| map_core | cd packages/map_core && dart test --reporter=compact | **PASS : +3064, All tests passed.** |
| map_gameplay | cd packages/map_gameplay && dart test --reporter=compact | **PASS : +288, All tests passed.** |
| map_battle | cd packages/map_battle && dart test --reporter=compact | **PASS : +1722, All tests passed.** |
| map_runtime | cd packages/map_runtime && flutter test --reporter compact | **PASS : +1827, 1 test ignoré ; All other tests passed.** |
| map_editor | cd packages/map_editor && flutter test --reporter compact | **PASS : +3403, All tests passed.** |
| playable_runtime_host | cd examples/playable_runtime_host && flutter test --reporter compact | **PASS : +69, All tests passed.** |
| **Total** |  | **10 373 tests passés, 1 test explicitement ignoré.** |

Le skip runtime existait avant ce lot et n’est pas lié au retry.

#### Variance observée pendant la revue indépendante

Le total ci-dessus décrit les runs de référence réussis. Une passe indépendante de map_editor, lancée en concurrence avec map_runtime et le host, a aussi produit un échec qui n’a pas été reproduit :

    cd packages/map_editor
    setopt PIPE_FAIL
    flutter test --no-pub --reporter=compact 2>&1 | tr '\r' '\n' | tail -n 14

Résultat : **exit 1 — 04:44, +3402 -1, Some tests failed.** Le filtrage tail a malheureusement supprimé le nom et la stack du test ; ils ne peuvent pas être inventés ni requalifiés.

La suite complète a ensuite été relancée seule, sans autre charge Flutter :

    cd packages/map_editor
    setopt PIPE_FAIL
    flutter test --no-pub --fail-fast --reporter=expanded 2>&1 | tail -n 120

Résultat : **exit 0 — 03:34, +3403, All tests passed.**

Conclusion : aucune régression reproductible n’est identifiée, mais l’occurrence concurrente reste une réserve de stabilité du harnais ou de la suite. Le rapport ne prétend donc pas que toutes les exécutions observées ont été vertes.

### 7.3 Analyses statiques

| Cible | Commande | Résultat exact |
|---|---|---|
| map_gameplay | cd packages/map_gameplay && dart analyze | **No issues found!** |
| map_runtime | cd packages/map_runtime && flutter analyze | **No issues found!** |
| map_editor | cd packages/map_editor && flutter analyze | **No issues found!** |
| playable_runtime_host | cd examples/playable_runtime_host && flutter analyze | **No issues found!** |

map_core et map_battle ne contiennent aucun changement de ce lot ; leurs suites complètes ont néanmoins été relancées.

### 7.4 Builds

| Cible | Commande | Résultat exact |
|---|---|---|
| Éditeur macOS arm64 release | cd packages/map_editor && FLUTTER_XCODE_ARCHS=arm64 flutter build macos --release --no-pub | **PASS : map_editor.app, 37,4 MB.** |
| Host macOS arm64 release | cd examples/playable_runtime_host && FLUTTER_XCODE_ARCHS=arm64 flutter build macos --release --no-pub | **PASS : playable_runtime_host.app, 46,8 MB.** |

Non prouvé par ces builds : lancement humain, signature, notarisation, packaging de distribution et compatibilité Intel. Le bundle host ne contient pas directement selbrume/project.json ; son build ne constitue donc pas, à lui seul, une distribution Selbrume autonome.

### 7.5 Contrôles de contenu

| Commande | Résultat exact |
|---|---|
| cd packages/map_editor && dart run tool/seed_selbrume_canonical_narrative_content.dart --project-root ../../selbrume --check | **PASS : Selbrume canonical narrative content is up to date.** |
| cd packages/map_editor && dart run tool/generate_selbrume_canonical_maps.dart --project-root ../../selbrume --validate-authored | **PASS : Selbrume authored maps are valid.** |
| shasum -a 256 selbrume/project.json | **2e5ebbeb916f09261d874d3420dc0d32dde1febbf2bd6eb12492f08071d39166** |

## 8. Niveau exact de preuve E2E

| Niveau de preuve | Couverture |
|---|---|
| Parcours principal PlayableMapGame | Victoires des deux gardiens et du boss, routes, warps, dialogues, quêtes et checkpoints du happy path. |
| Bridge de production + vraies Scenes | Les trois rencontres : defeat → round-trip SaveData JSON → retry → victory → round-trip → non-rejeu. Le résultat de combat y est simulé par le callback hôte. |
| PlayableMapGame + vrai combat dresseur | Gardien 1 : vraie défaite, retour overworld, locks relâchés, sortie droite, réentrée gauche, second vrai combat, victoire. |
| PlayableMapGame + vrai combat statique | Boss : vraie défaite, recovery de party, retour overworld, sortie/réentrée, dialogue, second vrai combat, victoire. |
| Gardien 2 physique | Sa victoire est couverte par le parcours complet ; son defeat→retry n’a pas un test PlayableMapGame dédié, mais possède la preuve bridge et save round-trip. |
| Sauvegarde | Round-trip du contrat SaveData JSON pour les retries ; ce n’est pas une écriture disque. |
| QA humaine | Non effectuée. |

Le blocker de données est donc prouvé fermé aux trois rencontres. La preuve physique la plus forte est présente pour le gardien 1 et le boss ; le gardien 2 conserve une différence de niveau de preuve explicitement documentée.

## 9. Fichiers modifiés

| Fichier | Zone précise | Raison | Impact attendu |
|---|---|---|---|
| packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart | _seedEventRegistry, lignes 2858–2914 | Rendre Events 026/027/028 réutilisables jusqu’au Fact terminal. | Corrige la source canonique sans changer le moteur. |
| packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart | _expectCanonicalEventProgression, lignes 499–523 | Verrouiller policy reusable + condition Fact false pour les trois Events. | Empêche une régression du seed. |
| selbrume/project.json | eventRegistry, lignes 38991–39082 | Snapshot régénéré depuis le seed. | Donnée réellement consommée par éditeur/runtime. |
| examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart | fichier créé, groupe lignes 58–209 | Preuve table-driven des trois rencontres et des deux round-trips. | Couvre négatif, positif, persistance et non-rejeu. |
| examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart | constante de hash, lignes 22–23 | Aligner la baseline sur le snapshot corrigé. | Détecte toute dérive future. |
| examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart | sets one-shot lignes 43–59 et helper de non-rejeu lignes 705–733 | Retirer les trois IDs désormais reusable et employer le terme neutre inactive trigger. | Conserve le contrat du parcours complet sans prétendre que le boss est consommé. |
| packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart | scénario principal lignes 15–139 et helpers de combat | Étendre le test gardien à une défaite et un retry physiques. | Prouve locks, sortie/réentrée et vrai overlay dresseur. |
| packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart | scénario principal lignes 16–150 et helpers de combat | Étendre le test boss à une défaite et un retry physiques. | Prouve recovery, dialogue et vrai overlay statique. |
| reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md | réécriture complète | Retirer les scores non reproductibles et intégrer les preuves post-fix. | Verdict traçable et non trompeur. |

### 9.1 Zones de diff déterminantes

Seed canonique :

~~~diff
- reusePolicy: NarrativeEventReusePolicy.oneShot
+ reusePolicy: NarrativeEventReusePolicy.reusable
+ NarrativeEventCondition.fact(victoryFactId, false)
~~~

Snapshot projet :

~~~diff
- "reusePolicy": "oneShot"
+ "reusePolicy": "reusable"
+ { "kind": "fact", "factId": "<fact terminal>", "expectedValue": false }
~~~

Tests runtime :

~~~text
défaite réelle
→ retour overworld
→ Facts de victoire absents
→ Event non consommé
→ locks d’input libérés
→ sortie puis réentrée du trigger
→ second combat réel
→ victoire
→ Fact terminal vrai
→ Event toujours absent du ledger one-shot
~~~

Aucun code de production générique, schéma, modèle de sauvegarde ou API publique n’a été modifié.

## 10. Roadmap : statut proposé, sans édition

| Lot | Lecture après ce lot |
|---|---|
| FG-000 — Fangame Mechanics Readiness Audit V0 | **PARTIAL** : ce rapport ferme le sous-audit Selbrume/phare, pas l’audit universel. |
| FG-086 — Start Trainer Battle Command V0 | Pas de changement de statut automatique ; le pipeline est utilisé avec succès. |
| FG-087 — Start Static Encounter Command V0 | Pas de changement de statut automatique ; le pipeline est utilisé avec succès. |
| FG-102 — Static Encounter Flow V0 | Le défaut de retry du boss est fermé ; **candidat à revue DoD**, pas marqué DONE ici. |
| FG-107 — Consumed Encounter Write-back V0 | Aucun changement de statut ; ce lot choisit explicitement reusable pour ces rencontres. |
| FG-140 — Trainer Defeated Policy V0 | Les victoires des gardiens restent prouvées ; pas de mise à jour automatique. |
| FG-141 — Post-battle Dialogue Hook V0 | Utilisé par le flux ; pas de mise à jour automatique. |
| FG-142 — Trainer Rematch Policy V0 | La politique locale defeat→retry est prouvée ; le lot générique reste à auditer. |
| FG-146 — Story Progression Validator V0 | **PARTIAL** : l’angle mort de détection générique subsiste. |
| FG-182 — Golden Slice End-to-End Smoke V0 | **PARTIAL fort** : le blocker phare est retiré, les critères fangame globaux restent incomplets. |
| FG-183 — Regression Matrix V0 | **PARTIAL** : la nouvelle matrice retry est ajoutée, la matrice globale reste incomplète. |
| FG-185 — MVP Release Gate V0 | **PARTIAL / NO-GO global inchangé**. |

## 11. Lots restants proposés

| Ordre | Lot proposé | Nature | Critère de sortie |
|---:|---|---|---|
| 1 | QA humaine du build Selbrume | Release | Walkthrough complet du .app, anomalies consignées, aucune impasse, contrôles et lisibilité validés. |
| 2 | Mise en scène canonique | Expérience | Moments clés avec acteurs, blocking, caméra et beats distincts ; décision explicite pour audio/FX. |
| 3 | Validator de robustesse narrative | Prévention | Diagnostic déterministe des mauvaises politiques de retry et, séparément, atteignabilité physique. |
| 4 | Fermeture authoring no-code | Produit | Les sept surfaces minimales permettent de reproduire le contenu sans édition JSON. |
| 5 | Save/load d’échec et preuve disque | Robustesse | État conservé sur load invalide et parcours critique avec repository disque. |
| 6 | Golden Slice fangame globale | Mécaniques | Capture→PC, progression post-combat, shop/heal, badge/field unlock et critères FG-181/182 verts. |

Ces six lots ne sont pas inclus dans le correctif actuel.

## 12. Passes indépendantes et verdicts

| Rôle | Périmètre | Verdict |
|---|---|---|
| Audit / Architecture | Cause racine, coordinateur, policy de contenu, sauvegardes anciennes | **PASS : correction data-first confirmée, aucun changement moteur requis.** |
| Implémentation | Diff seed, snapshot et baselines | **PASS : diff data-first limité au seed, au snapshot généré et aux preuves.** |
| Tests | RED, bridge, runtime physique, round-trip, assertions négatives et suites | **PASS : blocker fermé avec niveaux de preuve explicitement séparés.** |
| Build / Validation | Suites, analyses, contenu, artefacts et builds release | **PASS avec réserve : run éditeur isolé vert après une occurrence concurrente non identifiée ; limites de distribution conservées.** |
| Critique finale | Méthodologie, suraffirmations, risques, annexe et worktree | **PASS : scores artificiels retirés, rapport post-fix cohérent et limites maintenues.** |

Les sub-agents n’ont pas été autorisés à modifier les fichiers de ce lot.

Deux fichiers sont créés dans le worktree : le nouveau test host, reproduit intégralement en annexe A, et le présent rapport, dont le contenu intégral est ce document.

## 13. État Git final

    M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
    M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
    M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
    M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
    M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
    M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
    M selbrume/project.json
    ?? examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
    ?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md

Aucun git add, commit, push, reset, restore, checkout ou stash n’a été exécuté.

## 14. Auto-critique et risques résiduels

### Ce qui est fortement prouvé

- la cause exacte du soft-lock historique ;
- la politique canonique corrigée ;
- la non-consommation après défaite ;
- la fermeture terminale après victoire ;
- la survie de l’état à deux round-trips SaveData ;
- deux vrais pipelines physiques avec overlay ;
- les runs de référence, analyses, contrôles de contenu et builds release frais, avec la variance concurrente séparément consignée.

### Ce qui n’est pas prouvé

- le defeat→retry physique du gardien 2 dans PlayableMapGame ;
- une écriture/relecture disque spécifique au retry ;
- une partie humaine naturelle de 2 à 3 heures ;
- l’absence d’autres soft-locks ;
- toutes les branches narratives et tous les starters dans un walkthrough unique ;
- qualité artistique, audio, rythme et compréhension ;
- signature, notarisation et distribution ;
- complétude du MVP fangame global.

### Risques restants

1. Le Validator peut encore accepter une future combinaison oneShot + defeat terminal non progressif.
2. Le test bridge simule l’outcome du combat ; il ne remplace pas les deux preuves physiques, et le gardien 2 reste moins fortement couvert.
3. Le legacyFallback du test bridge est un no-op injecté : cette matrice prouve l’absence de replay V2, pas un comportement legacy riche.
4. Les anciennes IDs consommées restent dans la sauvegarde ; elles sont inertes pour ces Events reusable, mais ne sont pas nettoyées. Le cas Selbrume empoisonné est déduit du contrat et de ses tests génériques, pas injecté tel quel dans la matrice host.
5. Les cinématiques canoniques restent visuellement minimales.
6. Les Storylines draft et assets techniques/legacy continuent de brouiller la promotion éditoriale.
7. Les suites automatisées connaissent le parcours et ne remplacent pas une QA humaine.
8. Une passe map_editor concurrente a échoué sans nom de test conservé ; la relance complète isolée passe, mais cette variance mérite surveillance.
9. Le .app du host ne bundle pas directement selbrume/project.json ; l’assemblage d’une distribution autonome reste à prouver.

## 15. Conclusion

Le NO-GO causé précisément par les défaites du phare est levé. Selbrume dispose maintenant d’une politique de retry cohérente, persistante et testée pour les trois rencontres, avec deux preuves physiques renforcées.

Le verdict honnête devient :

- **GO technique pour une démonstration guidée ;**
- **candidat GO technique pour une démonstration autonome, sous réserve d’un walkthrough humain et d’un package incluant le projet ;**
- **PARTIEL pour la vision complète du Narrative Studio ;**
- **PARTIAL / NO-GO pour FG-185 global.**

Le prochain lot ne doit pas être choisi en faisant passer ces quatre gates pour une seule : la QA humaine ferme la confiance release, la mise en scène ferme l’expérience visible, l’authoring ferme la promesse no-code, et la Golden Slice globale ferme le MVP fangame.

## Annexe A — Contenu complet du fichier créé

Fichier : examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart

~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';
import 'package:path/path.dart' as p;

const _retryCases = <_LighthouseRetryCase>[
  _LighthouseRetryCase(
    label: 'first lighthouse guardian',
    eventId: 'evt_019abcde-5000-7000-8000-000000000026',
    mapId: 'map_phare_interieur',
    triggerId: 'tr_phare_guardian_1',
    prerequisiteFacts: <String>{'fact_lighthouse_old_note_read'},
    expectedVictoryFacts: <String>{
      'fact_lighthouse_guardian_1_defeated',
    },
  ),
  _LighthouseRetryCase(
    label: 'second lighthouse guardian',
    eventId: 'evt_019abcde-5000-7000-8000-000000000027',
    mapId: 'map_phare_interieur',
    triggerId: 'tr_phare_guardian_2',
    prerequisiteFacts: <String>{
      'fact_lighthouse_old_note_read',
      'fact_lighthouse_guardian_1_defeated',
    },
    expectedVictoryFacts: <String>{
      'fact_lighthouse_guardian_2_defeated',
      'fact_lighthouse_top_unlocked',
    },
    expectedCompletedSteps: <String>{'step_climb_lighthouse'},
  ),
  _LighthouseRetryCase(
    label: 'lighthouse boss',
    eventId: 'evt_019abcde-5000-7000-8000-000000000028',
    mapId: 'map_sommet_phare',
    triggerId: 'tr_sommet_confrontation',
    prerequisiteFacts: <String>{
      'fact_lighthouse_top_unlocked',
      'fact_lighthouse_guardian_2_defeated',
    },
    expectedVictoryFacts: <String>{
      'fact_lighthouse_pokemon_appeased',
      'fact_mist_source_resolved',
    },
    expectedCompletedSteps: <String>{'step_final_confrontation'},
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Selbrume lighthouse defeat retry regression', () {
    late NarrativeEventRuntimeSnapshot snapshot;

    setUpAll(() async {
      snapshot = await _loadSelbrumeSnapshot();
    });

    for (final testCase in _retryCases) {
      test(
        '${testCase.label} supports defeat, reload, retry, victory, and reload',
        () async {
          var state = GameState(
            saveId: 'selbrume_retry_${testCase.eventId}',
            currentMapId: testCase.mapId,
            narrativeFactRuntimeState: NarrativeFactRuntimeState(
              overridesByFactId: <String, bool>{
                for (final factId in testCase.prerequisiteFacts) factId: true,
              },
            ),
          );
          var sequence = 0;
          var battleCalls = 0;

          Future<NarrativeSpatialProductionDispatchResult> dispatch(
            String battleOutcome,
          ) async {
            // A fresh transaction boundary mirrors leaving and re-entering the
            // trigger after a battle or a save reload. It also prevents this
            // regression test from accidentally relying on in-memory bridge
            // state that is not serialized by the real save contract.
            final transactions = NarrativeEventStateTransactions(state);
            final source = NarrativeEventSourceRef.triggerEnter(
              testCase.mapId,
              testCase.triggerId,
            );
            final bridge = NarrativeSpatialProductionDispatchBridge(
              stateTransactions: transactions,
              currentGameState: () => state,
              onGameStateCommitted: (next) => state = next,
              prepareAuthority: (_, occurrence) async {
                return NarrativeEventDispatchAuthority.prepare(
                  registryResult: snapshot.registryResult,
                  occurrence: occurrence,
                  factResolver: snapshot.factResolver,
                  legacyClaimIndex: snapshot.legacyClaimIndex,
                  projectCatalog: snapshot.projectCatalog,
                );
              },
              executeScene: (request) {
                return executeNarrativeEventScene(
                  request: request,
                  project: snapshot.project,
                  mapsById: snapshot.mapsById,
                  currentGameState: () => state,
                  callbacks: SceneRuntimeHostCallbacks(
                    evaluateCondition: (intent) => _resolveConditionOutput(
                      snapshot.project,
                      state,
                      intent,
                    ),
                    showDialogue: (_) => 'completed',
                    playCinematic: (_) => 'completed',
                    startBattle: (_) {
                      battleCalls++;
                      return battleOutcome;
                    },
                  ),
                );
              },
              legacyFallback: (_, __, ___) async {},
              activityPort: NoopNarrativeEventActivityPort(),
              isCurrentOccurrence: (_) => true,
              executionIdFactory: () => _runtimeId('evx', ++sequence),
              correlationIdFactory: () => _runtimeId('corr', ++sequence),
              deliveryIdFactory: () => _runtimeId('outd', ++sequence),
            );

            final result = await bridge.dispatch(
              occurrenceId: 'retry-${testCase.triggerId}-${++sequence}',
              occurrence: NarrativeEventOccurrence(source: source),
            );
            expect(await transactions.read(), state);
            return result;
          }

          final defeat = await dispatch('defeat');
          _expectHandled(defeat, testCase.eventId);
          expect(battleCalls, 1);
          for (final factId in testCase.expectedVictoryFacts) {
            expect(
              state.narrativeFactRuntimeState.overridesByFactId[factId],
              isNot(isTrue),
              reason: 'A defeat must not grant victory Fact $factId.',
            );
          }
          for (final stepId in testCase.expectedCompletedSteps) {
            expect(
              state.progression.completedStepIds,
              isNot(contains(stepId)),
              reason: 'A defeat must not complete victory step $stepId.',
            );
          }
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            isNot(contains(testCase.eventId)),
            reason: 'A defeated lighthouse encounter must remain retryable.',
          );

          state = _roundTrip(state);
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            isNot(contains(testCase.eventId)),
            reason: 'Retry eligibility must survive save/load after defeat.',
          );

          final victory = await dispatch('victory');
          _expectHandled(victory, testCase.eventId);
          expect(battleCalls, 2);
          for (final factId in testCase.expectedVictoryFacts) {
            expect(
              state.narrativeFactRuntimeState.overridesByFactId[factId],
              isTrue,
              reason: '$factId must be applied by the victory branch.',
            );
          }
          expect(
            state.progression.completedStepIds,
            containsAll(testCase.expectedCompletedSteps),
          );

          state = _roundTrip(state);
          final stateAfterVictoryReload = saveDataFromGameState(state).toJson();
          final battleCallsBeforeReentry = battleCalls;
          final postVictoryReentry = await dispatch('victory');

          expect(
            postVictoryReentry,
            isA<NarrativeSpatialProductionDispatchLegacyFallback>(),
            reason: 'The negative victory Fact prevents Event V2 replay; '
                'the reserved custom trigger then reaches its state-neutral '
                'legacy fallback.',
          );
          expect(battleCalls, battleCallsBeforeReentry);
          expect(
            saveDataFromGameState(state).toJson(),
            stateAfterVictoryReload,
            reason: 'Re-entering a completed encounter must be state-neutral.',
          );
        },
      );
    }
  });
}

void _expectHandled(
  NarrativeSpatialProductionDispatchResult result,
  String eventId,
) {
  if (result
      case NarrativeSpatialProductionDispatchFailed(
        :final failure,
        :final stackTrace,
      )) {
    fail('Lighthouse dispatch failed: $failure\n$stackTrace');
  }
  expect(result, isA<NarrativeSpatialProductionDispatchV2Handled>());
  expect(
    (result as NarrativeSpatialProductionDispatchV2Handled).execution.eventId,
    eventId,
  );
}

Future<NarrativeEventRuntimeSnapshot> _loadSelbrumeSnapshot() async {
  final root = _findRepositoryRoot();
  final projectPath = p.join(root.path, 'selbrume', 'project.json');
  final project = ProjectManifest.fromJson(
    _readJson(File(projectPath)),
  );
  return NarrativeEventRuntimeSnapshot.build(
    project: project,
    loadMap: (mapId) async {
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: mapId,
      );
      return (project: bundle.manifest, map: bundle.map);
    },
  );
}

GameState _roundTrip(GameState state) {
  final serialized = jsonDecode(
    jsonEncode(saveDataFromGameState(state).toJson()),
  ) as Map<String, dynamic>;
  return gameStateFromSaveData(SaveData.fromJson(serialized));
}

String _resolveConditionOutput(
  ProjectManifest project,
  GameState state,
  SceneRuntimePlanIntent intent,
) {
  final source = intent.conditionSource;
  if (source == null) {
    throw StateError('Scene condition intent is missing a condition source.');
  }
  if (source.sourceKind == SceneConditionSourceKind.fact) {
    final matched = evaluateCanonicalNarrativeFactSceneCondition(
      source: source,
      gameState: state,
      resolver: NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    return matched ? 'true' : 'false';
  }
  throw UnsupportedError(
    'Condition source ${source.sourceKind.name} is outside this retry test.',
  );
}

String _runtimeId(String prefix, int sequence) {
  final suffix = sequence.toString().padLeft(12, '0');
  return '${prefix}_019abcde-7000-7000-8000-$suffix';
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}

Map<String, dynamic> _readJson(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();

final class _LighthouseRetryCase {
  const _LighthouseRetryCase({
    required this.label,
    required this.eventId,
    required this.mapId,
    required this.triggerId,
    required this.prerequisiteFacts,
    required this.expectedVictoryFacts,
    this.expectedCompletedSteps = const <String>{},
  });

  final String label;
  final String eventId;
  final String mapId;
  final String triggerId;
  final Set<String> prerequisiteFacts;
  final Set<String> expectedVictoryFacts;
  final Set<String> expectedCompletedSteps;
}
~~~
