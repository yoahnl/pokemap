# Roadmap d'implémentation — remédiation de l'audit et Personalization Hub

> **Pour les agents d'implémentation :** sous-skill obligatoire : utiliser `subagent-driven-development` (recommandé) ou `executing-plans` pour exécuter cette roadmap lot par lot. Chaque lot doit recevoir son propre plan détaillé `writing-plans` avant toute modification de code.

**Objectif :** restaurer une baseline de release fiable, fermer les écarts de gameplay Pokémon mainline trouvés par `FG-000`, puis livrer un Personalization Hub versionné dont la première fonction visible est une vidéo d'introduction sûre et skippable.

**Architecture :** les lots `FG-*` existants restent le tracker canonique des mécaniques. Cette roadmap introduit des identifiants d'exécution `RM-*` uniquement pour regrouper les remédiations qui traversent plusieurs lots canoniques, et conserve le namespace proposé `PH-*` pour la personnalisation jusqu'à son adoption explicite par la roadmap canonique. Les contrats partagés restent dans `map_core`, les règles pures dans `map_gameplay`/`map_battle`, le rendu et l'intégration dans `map_runtime`, l'authoring dans `map_editor`, les surfaces joueur dans `map_player_ui`, le packaging dans `map_distribution`, et l'installation/lancement dans `pokemap_hub`.

**Stack technique :** Dart, Flutter, Flame, sérialisation Freezed/JSON, `package:test`, `flutter_test`, build desktop macOS et Golden Slice Selbrume.

---

## 0. Statut du document et règles d'exécution

Date: 2026-07-26

Audit source :

- `reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md`
- tracker canonique : `pokemap_roadmap_mecaniques_fangame.md`
- verdict produit actuel : **MVP NO-GO validation**
- verdict d'audit actuel : **FG-000 DONE proposé**

Il s'agit d'une **roadmap d'exécution proposée**, pas d'une mise à jour silencieuse de la roadmap canonique. Ce document ne modifie aucun statut `FG-*`.

### 0.1 Contraintes Git et planification

- Cette roadmap n'autorise aucune branche, worktree, commit, mise en index ou push.
- Le skill local `writing-plans` recommande normalement un worktree dédié, mais les règles Git du dépôt prévalent.
- Les étapes de commit sont volontairement absentes. L'implémentation doit obtenir une autorisation Git explicite avant toute écriture Git.
- Chaque lot doit rester chirurgical. Il ne peut absorber un nettoyage adjacent sans changement de scope documenté.
- Les fichiers générés ne changent que lorsque le lot modifie leur modèle propriétaire et uniquement depuis le package concerné.

### 0.2 Taille des lots

| Taille | Limite |
|---|---|
| `S` | Un contrat ou bug ciblé, normalement un package et ses tests |
| `M` | Une capacité bout-en-bout traversant deux ou trois packages |
| `L` | Une tranche verticale traversant contrats, éditeur, runtime, UI joueur et packaging |

Les tailles expriment le risque de coordination, pas une promesse calendaire.

### 0.3 Définition de done universelle

Chaque lot d'implémentation doit fournir :

1. un test de caractérisation ou de régression rouge avant le correctif quand c'est faisable ;
2. l'implémentation minimale ;
3. les tests ciblés verts ;
4. la suite complète et l'analyse de chaque package modifié ;
5. les smokes runtime/host utiles pour tout comportement joueur ;
6. les sorties exactes et codes de retour des commandes ;
7. les états Git initial et final ;
8. un verdict explicite `TODO`, `PARTIAL`, `BLOCKED` ou `DONE proposé` pour les lots canoniques associés ;
9. aucun contrôle d'authoring ignoré silencieusement par le runtime ;
10. un rapport ciblé sous `reports/gameplay/`.

---

## 1. Carte des dépendances

```text
Phase 0 — Restaurer des gates fiables
        │
        ├── Branche gameplay
        │     ├── Phase 1 — Histoire réellement finissable
        │     ├── Phase 2 — Vérité combat et trainers
        │     ├── Phase 3 — Rencontres, récompenses et field gates
        │     └── Phase 4 — Menus, sauvegardes et identité joueur
        │                         │
        │                         ▼
        │              Phase 7A — Gate gameplay FG-185
        │
        └── Branche personnalisation
              └── Phase 5 — Fondation du Personalization Hub
                              │
                              ▼
                   Phase 6 — Intégration plateforme/présentation
                              │
                              ▼
                   Phase 7B — Gate personnalisation PH-007
```

La Phase 0 est un prérequis strict. Les Phases 1–5 peuvent être planifiées en parallèle ensuite, mais les lots qui touchent les mêmes fichiers runtime/editor doivent être sérialisés. La gate gameplay `FG-185` dépend des lots MVP gameplay sélectionnés, pas de la personnalisation optionnelle. `PH-007` est une gate produit distincte ; une release revendiquant les deux capacités doit passer les deux gates.

### Première chaîne P0 — obtenir une fin jouable

```text
RM-001 + RM-002
  → RM-003
  → RM-010
  → RM-011
      ├→ RM-012 ─┐
      └→ RM-015 ─┤
                  → RM-013
  → RM-014
  → RM-069
  → RM-070
  → RM-073
```

Cette chaîne transforme l'état actuel « grande tranche jouable » en preuve qu'une histoire peut être terminée. Elle ne représente pas, à elle seule, toute la convergence vers `RM-070` : la gate gameplay attend aussi le cutline combat, rencontres, récompenses, menus et sauvegardes listé explicitement dans les dépendances de `RM-070`.

---

## 2. Phase 0 — Restaurer des gates fiables

**Priorité :** P0

**Objectif de phase :** supprimer les trois échecs reproductibles, restaurer une validation déterministe de Selbrume et produire une baseline fraîche et fiable.

### Lots

| Lot | Liens canoniques | Livrable | Fichiers principaux | Dépend de | Taille |
|---|---|---|---|---|---|
| `RM-001` — Lysa Source Authority-Key Regression | `FG-082`, `FG-093`, `FG-182`, `FG-185` | Prouver la cohorte Lysa légitime à source partagée et restaurer l'unicité autoritaire de chaque tuple `source + priority + order` sans affaiblir l'assertion | `selbrume/project.json`, `selbrume/maps/map_port_brisants.json`, fixture et test runtime ciblés | — | `S` |
| `RM-002` — Symbolic Solvability State-Space Hardening | `FG-081`, `FG-093`, `FG-146`, `FG-182`, `FG-185` | Diagnostiquer l'explosion à 16 384 états et rendre Selbrume prouvable avec un budget borné sans simplement augmenter le plafond | solver/validator `map_core`, tests runtime/editor Selbrume | — | `M` |
| `RM-003` — Selbrume Validation Receipt Refresh | `FG-182`, `FG-183`, `FG-185` | Rejouer la preuve runtime après RM-001/RM-002, écrire un receipt frais de baseline `PARTIAL / NO-GO` via l'outillage de production et archiver explicitement les preuves remplacées ; ce lot ne peut jamais promouvoir `FG-185` | repository/tests de receipt, profil release Selbrume, rapport `FG-185` uniquement si le lot autorise sa mise à jour | RM-001, RM-002 | `S` |
| `RM-004` — Capability Truth Gate V0 | `FG-180`, `FG-183`, `FG-184` | Matrice lisible par machine reliant chaque champ publié à son contrat, consommateur runtime, surface joueur et test | nouvel outil ciblé `map_core`, adapters editor/runtime, tests | RM-001, RM-002 | `M` |

### Comportements d'implémentation obligatoires

#### RM-001

- Préserver l'invariant strict `singleWhere` sur la clé d'autorité exacte.
- Le diagnostic Phase 0 a amendé l'hypothèse initiale : plusieurs Events peuvent légitimement partager une source si leur `priority` ou leur `order` diffère. L'invariant canonique porte sur l'unicité du tuple `source + priority + order`.
- Identifier si une collision exacte vient du projet canonique, de la synthèse des sources, de la fusion du registre, du chargement de fixture ou des artefacts de promotion.
- Ajouter un test négatif prouvant qu'une collision exacte `source + priority + order` échoue avant le dispatch runtime.
- Préserver les Golden tests Lysa et le round-trip des quatre sources narratives.
- Prouver qu'un save/reload ne réarme pas une scène Lysa one-shot.
- Ne pas « corriger » le lot en remplaçant l'assertion par `.firstWhere`.

#### RM-002

- Capturer le nombre d'états explorés et la dimension de branche responsable.
- Préférer canonicalisation, élimination d'états dominés, projection des faits utiles ou décomposition par phase.
- Conserver le comportement fail-closed `indeterminate`.
- Ajouter une fixture négative qui dépasse réellement la borne et reste `indeterminate`.
- Ajouter des cas déterministes juste sous et juste au-dessus du budget.
- Documenter la performance sans inventer de garantie mémoire ou temporelle.

#### RM-003

- Recréer le receipt uniquement après le passage des suites runtime/editor complètes.
- Vérifier que son fingerprint correspond exactement à l'état de Selbrume.
- Garder les anciens snapshots GO/DONE clairement non autoritaires.
- Étiqueter le receipt `PARTIAL / NO-GO` ; seul `RM-073`, après toute la convergence, peut proposer `FG-185` en `DONE/GO`.

#### RM-004

Colonnes minimales :

```text
capabilityId
authoringControl
contractField
runtimeConsumer
playerSurface
positiveTest
negativeTest
status
```

La gate doit rejeter toute capacité promue dont le consommateur runtime ou la preuve requise manque.

### Gate de validation de la Phase 0

Commandes :

```bash
(cd packages/map_core &&
dart test &&
dart analyze)

(cd packages/map_runtime &&
flutter test test/selbrume_event_v2_three_source_integration_test.dart &&
flutter test test/selbrume_narrative_campaign_outcome_matrix_test.dart &&
flutter test &&
flutter analyze)

(cd packages/map_editor &&
flutter test test/selbrume_narrative_validator_test.dart &&
flutter test &&
flutter analyze)

(cd examples/playable_runtime_host &&
flutter test test/selbrume_player_journey_e2e_test.dart &&
flutter analyze)
```

PASS exige :

- no `Too many elements`;
- symbolic verdict `pass`, not `indeterminate`;
- runtime and editor full suites exit `0`;
- E2E Selbrume exits `0`;
- fresh receipt matches the project fingerprint.

Toute condition en échec maintient la Phase 0 et `FG-185` en **NO-GO**.

---

## 3. Phase 1 — Rendre l'histoire réellement finissable

**Priorité :** P0

**Objectif de phase :** permettre à l'auteur de terminer un jeu sans code et au joueur d'atteindre résultat/crédits via le runtime et le Hub de production.

### Lots

| Lot | Liens canoniques | Livrable | Fichiers principaux | Dépend de | Taille |
|---|---|---|---|---|---|
| `RM-010` — Finish Game Contract V0 | `FG-080`, `FG-082`, `FG-147` | Conséquence `Finish Game` versionnée avec résultat, outcome, crédits optionnels et politique postgame | modèle `scene_consequence`, diagnostics/codecs, fichiers générés et tests de contrat | Phase 0 | `M` |
| `RM-011` — Finish Game No-Code Authoring V0 | `FG-093`, `FG-094`, `FG-147` | Action guidée, pickers, validation et template réutilisable « Fin du jeu » | catalogue/palette narrative, action builder, design system et tests editor | RM-010 | `M` |
| `RM-012` — Runtime Completion Wiring V0 | `FG-082`, `FG-147`, `FG-160` | Exécuter la conséquence, appeler une fois le port de completion, sauvegarder sûrement et ouvrir résultat/crédits | writer runtime, `PlayableMapGame`, session/coordinator et tests | RM-010 | `M` |
| `RM-013` — Selbrume Terminal Scene V0 | `FG-145`, `FG-146`, `FG-147`, `FG-181`, `FG-182` | Authorer la scène terminale canonique et les crédits après la dernière condition d'histoire | `selbrume/project.json`, dialogues/maps concernés et readiness tests | RM-011, RM-012, RM-015 | `M` |
| `RM-014` — Story-to-Credits Golden E2E V0 | `FG-147`, `FG-182` | Test production ciblé couvrant installation/lancement, New Game, route narrative terminale, completion, résultat, crédits, save/reload et retour Hub ; la preuve des 19 critères appartient à RM-069 | intégration Hub, harness runtime/player et fixture Selbrume | RM-013 | `L` |
| `RM-015` — NPC State Commands V0 | `FG-092` | Unifier mouvement et présence NPC dans un contrat no-code réellement consommé | core/editor/runtime/Selbrume | RM-011 | `M` |

### Décisions contractuelles obligatoires dans RM-010

- ordre entre écriture de la completion et affichage du résultat ;
- crédits skippables ou non ;
- continuation postgame, retour titre ou retour Hub ;
- idempotence si la scène terminale est rejouée après une course de sauvegarde ;
- fallback si les crédits manquent ;
- localisation des libellés résultat/crédits.

Preuves de completion existantes à étendre plutôt qu'à remplacer :

- `packages/map_runtime/test/scenario_complete_step_test.dart`
- `packages/map_runtime/test/scenario_runtime_completion_gate_test.dart`
- `packages/map_runtime/test/scenario_runtime_executor_test.dart`
- `packages/map_runtime/test/player/runtime_player_coordinator_completion_test.dart`
- `packages/map_runtime/test/player/runtime_player_models_test.dart`
- `packages/map_runtime/test/narrative_command_runtime_parity_test.dart`

### Gate de validation de la Phase 1

Exécuter la nouvelle preuve desktop via le parcours player installé :

```bash
(cd packages/map_core && dart test && dart analyze)
(cd packages/map_runtime && flutter test && flutter analyze)
(cd packages/map_editor && flutter test && flutter analyze)
(cd packages/map_player_ui && flutter test && flutter analyze)
(cd examples/playable_runtime_host && flutter test && flutter analyze)
(cd apps/pokemap_hub && flutter test && flutter analyze)

(cd apps/pokemap_hub &&
flutter test integration_test/runtime_owned_player_flow_test.dart -d macos &&
flutter build macos --debug)
```

PASS exige :

- round-trip modèle/JSON et migration legacy ;
- aucun picker editor ne demande d'ID brut dans le parcours normal ;
- exactement un événement de completion par partie ;
- un échec de sauvegarde ne peut afficher une fausse réussite ;
- l'E2E Hub atteint les crédits et revient sûrement ;
- le rechargement après completion respecte la politique postgame authorée.

Proposition de statut après PASS :

- `FG-147` : `DONE proposé V0` ;
- critère MVP 19 : `DONE proposé` ;
- `FG-182` : reste en attente de la preuve des 19 critères par `RM-069` ;
- `FG-185` : reste en attente de la Phase 7A.

---

## 4. Phase 2 — Vérité combat et parité trainer

**Priorité :** P1

**Objectif de phase :** faire décrire les mêmes capacités par les réglages editor, les décisions PSDK et l'UI joueur.

### Lots

| Lot | Liens canoniques | Livrable | Packages principaux | Dépend de | Taille |
|---|---|---|---|---|---|
| `RM-020` — Battle Parity Target | `FG-053` | Choisir la génération/règle cible pour dégâts, égalités de vitesse, statuts, critiques, EXP et capture ; réconcilier les compteurs PSDK | docs combat, rapports d'analyse et outil d'audit `map_battle` | Phase 0 | `S` |
| `RM-021` — Trainer Difficulty to PSDK AI | `FG-086`, `FG-140` | Mapper la difficulté authorée vers une IA déterministe avec policies switch/item explicites | core/battle/runtime et tests trainer editor | RM-020 | `M` |
| `RM-022` — Unified Battle Decision Contract | `FG-052` | Chemin canonique unique pour move, switch, remplacement forcé, fuite et état typé `noLegalChoice` ; Struggle est implémenté séparément par RM-029 | battle/runtime/UI combat | RM-020 | `L` |
| `RM-023` — Generic Battle Items V0 | `FG-050` | Décision objet générique, sélection de cible, heal/cure/revive et mutation atomique de l'inventaire | gameplay/battle/runtime/UI joueur | RM-022 | `L` |
| `RM-024` — Held Item Bridge V0 | `FG-072` | Injecter les objets tenus player/trainer dans PSDK, appliquer les effets et définir le write-back consommé/volé | core/battle/runtime/editor | RM-020 | `L` |
| `RM-025` — Trainer Reward Authoring V0 | `FG-051`, `FG-143` | Contrôles editor guidés pour argent, objets, flags, badge optionnel et field unlock | core/editor trainer/runtime reward | Phase 0 | `M` |
| `RM-026` — Battle MVP Capability Gate | `FG-053`, `FG-180`, `FG-183` | Matrice générée du cutline MVP : IA, décisions, objets génériques, rewards et lifecycle trainer ; toute capacité combat hors cutline encore exposée doit être désactivée ou clairement non promue | tooling et audits battle bridge | RM-004, RM-021–RM-023, RM-025, RM-027 | `M` |
| `RM-027` — Trainer Lifecycle & Templates V0 | `FG-140`, `FG-141`, `FG-144`, `FG-145` | Persister la défaite, dialogues avant/victoire/défaite et templates trainer/rival | core/editor/runtime/Selbrume | RM-021, RM-025 | `M` |
| `RM-028` — Nature/IV/EV Bridge Fidelity | `FG-020`, `FG-053`, frontière `FG-206` | Appliquer nature/IV/EV sauvegardés aux stats runtime et définir les valeurs adverses | core/gameplay/battle/runtime | RM-020 | `M` |
| `RM-029` — Exhausted PP & Struggle V0 | `FG-041`, `FG-052`, `FG-053` | Remplacer le terminal `noLegalChoice` par la policy Struggle approuvée lorsqu'aucun move avec PP n'est légal | battle/runtime/UI joueur | RM-022 | `M` |
| `RM-053` — Full Battle Capability Gate | `FG-053`, `FG-183` | Étendre la gate MVP aux objets tenus, nature/IV/EV et Struggle sans rendre ces lots bloquants pour `FG-185` | tooling et audits battle bridge | RM-024, RM-026, RM-028, RM-029 | `M` |

### Comportements non négociables

- `battleDifficulty` ne peut rester décoratif.
- La fuite ne peut muter uniquement une session legacy d'affichage.
- Un objet ne peut être débité avant acceptation par le moteur canonique.
- Le remplacement forcé ne peut finir sur un `noLegalChoice` non géré.
- Les règles de consommation/write-back des objets tenus précèdent toute mutation runtime.
- Les compteurs de couverture PSDK ne valent pas parité joueur bout-en-bout.
- Tant que `RM-024`, `RM-028` ou `RM-029` n'est pas livré, `RM-026` doit désactiver ou étiqueter comme indisponible tout contrôle public correspondant. Si une capacité reste promue, elle rejoint automatiquement le cutline `FG-185` et son lot devient bloquant.

### Gate de validation de la Phase 2

```bash
(cd packages/map_battle && dart test && dart analyze)
(cd packages/map_gameplay && dart test && dart analyze)
(cd packages/map_runtime &&
flutter test test/phase_a_golden_battle_slice_smoke_test.dart &&
flutter test &&
flutter analyze)
(cd packages/map_editor && flutter test && flutter analyze)
```

La gate combat MVP `RM-026`, bloquante pour `FG-185`, exige des preuves Golden Slice pour :

- deux niveaux d'IA authorés produisant les différences de policy prévues ;
- switch après K.O. ;
- fuite acceptée et refusée ;
- soin, guérison et rappel sur cibles valides et invalides ;
- récompense trainer incluant badge/field unlock ;
- persistance one-shot et follow-up post-combat après save/reload.

La gate combat complète `RM-053`, non bloquante pour `FG-185`, exige en plus :

- activation et persistance d'un objet tenu ;
- nature non neutre et IV/EV non nuls modifiant les stats runtime attendues ;
- PP épuisés résolus par le comportement Struggle documenté.

---

## 5. Phase 3 — Rencontres, métadonnées de capture et field gates

**Priorité :** P1

**Objectif de phase :** garantir que chaque option de rencontre exposée est réellement exécutable ou explicitement indisponible.

### Lots

| Lot | Liens canoniques | Livrable | Packages principaux | Dépend de | Taille |
|---|---|---|---|---|---|
| `RM-030` — Encounter Kind Capability Matrix | `FG-100` | Matrice exhaustive `EncounterKind × modèle × editor × runtime × tests` | core/editor/runtime et tooling | Phase 0 | `M` |
| `RM-031` — Organic Encounter Conditions V0 | `FG-101`, `FG-106` | Taux et conditions authorés marche/Surf ; hooks temps/météo uniquement avec provider réel | core/gameplay/runtime/editor | RM-030 | `L` |
| `RM-032` — Static Encounter & Consumed State V0 | `FG-087`, `FG-102`, `FG-107` | Rencontre statique no-code, usage unique, save/reload et sémantique d'annulation | core/editor/runtime | RM-030 | `M` |
| `RM-033` — Gift/Capture Existing Metadata Preservation | `FG-084`, `FG-103`, `FG-020`, `FG-029` | Routage party pleine et préservation des champs existants nature, IV/EV, genre, forme, shiny et objet tenu ; surnom/amitié/provenance restent dans RM-047 | core/gameplay/runtime/editor | RM-030 | `L` |
| `RM-034` — Badge-to-Surf Golden Flow | `FG-120`, `FG-129`, `FG-143` | Refus avant badge, attribution après Lysa, traversée Surf réelle et save/reload | Selbrume/core/gameplay/runtime/editor | RM-025, RM-031 | `L` |
| `RM-035` — Encounter Authoring Fail-Closed Gate | `FG-108`, `FG-180` | Masquer/désactiver les kinds non supportés et rejeter les configurations incomplètes | validators/simulator editor et diagnostics core | RM-030–RM-034 | `M` |
| `RM-036` — Hazard Runtime Consumption V0 | proposé `FG-130` | Consommer les hazards dans `PlayableMapGame`, appliquer l'effet, feedback, policy K.O./recovery et garde save/reload | core/gameplay/runtime/UI joueur | RM-031 | `M` |
| `RM-037` — Pickup & Hidden Item Events V0 | `FG-067`, `FG-068`, `FG-083` | Templates pickup visible/objet caché avec capacité, état consumed et feedback | core/gameplay/editor/runtime | Phase 0 | `M` |
| `RM-038` — Event Template Library V0 | `FG-094` | Bibliothèque clonable heal, pickup, static, gift, trainer, rival et fin, construite uniquement après fermeture de leurs contrats | editor + fixtures | RM-011, RM-027, RM-032, RM-033, RM-037 | `M` |

### Politique de scope

- Pêche et Headbutt restent différés sans promotion explicite de `FG-104`/`FG-105`.
- Repel et familles de Balls restent différés sous `FG-065`/`FG-066`.
- Les conditions temps/météo ne sont exposées qu'après livraison d'un provider overworld réel.
- Aucun taux runtime fixe ne peut écraser silencieusement une valeur authorée.
- Un hazard ne peut se redéclencher sur le même pas ou après restauration.
- Un pickup ne devient consumed qu'après réussite de la mutation d'inventaire.

### Gate de validation de la Phase 3

PASS exige une preuve positive, négative et save/reload pour chaque kind supporté. L'éditeur doit :

- afficher une configuration supportée et validée ; ou
- marquer clairement le kind indisponible et empêcher sa publication.

`FG-100` ne peut fermer sur un simple inventaire ; la matrice exhaustive et la preuve runtime sont obligatoires.

---

## 6. Phase 4 — Menus, sauvegardes et identité joueur

**Priorité :** P1 pour RM-040, RM-041, RM-051 puis RM-042 ; P2 pour les autres lots

**Objectif de phase :** transformer les backends solides en parcours joueur comparables à un RPG solo complet.

### Lots

| Lot | Liens canoniques | Livrable | Packages principaux | Dépend de | Taille |
|---|---|---|---|---|---|
| `RM-040` — PC Summary & Operations Completion | `FG-029` | Summary depuis le PC, feedback dépôt/retrait/swap, filtres/recherche seulement si justifiés | gameplay/runtime/UI joueur/Hub | Phase 0 | `M` |
| `RM-041` — Bag/Party Interaction Completion | `FG-061`, `FG-064` | Utiliser les objets depuis les menus avec garde-fous key items, sans dépendre des objets tenus | gameplay/runtime/UI joueur/catalogue editor | RM-023 | `L` |
| `RM-042` — Profiles & Save Slots V0 | `FG-014`, `FG-163`, proposé `FG-166` | Créer/sélectionner/renommer/supprimer profils et slots avec confirmation, métadonnées et isolation | runtime/UI joueur/Hub | RM-051 | `L` |
| `RM-043` — Runtime Map V0 | `FG-164` | Fournir `map.v1`, position actuelle et carte consultable ; le fast travel `FG-125` reste différé | core/gameplay/runtime/UI joueur/Hub | RM-034 | `M` |
| `RM-044` — Player Identity V0 | proposé `FG-031` | Nom, variante d'avatar et pronoms/libellés via New Game guidé et variables de dialogue | core/editor/runtime/UI joueur/Hub | Phase 1 | `L` |
| `RM-045` — Whiteout & Recovery V0 | proposé `FG-054` | Policy de recovery, destination centre, pénalité d'argent et sauvegarde sûre | gameplay/runtime/UI joueur | RM-022 | `M` |
| `RM-046` — Shop Sell V0 | proposé `FG-172` | Vente guidée, prix, quantité, garde objets invendables/key items et mutation atomique | core/gameplay/runtime/UI joueur/editor | Phase 0 | `M` |
| `RM-047` — PlayerPokemon Metadata V1 | proposé `FG-032` | Surnom, amitié et provenance préservés par capture, cadeau, PC, combat et save | core/gameplay/runtime/editor/UI joueur | RM-033 | `L` |
| `RM-048` — Evolution Conditions V1 | proposé `FG-055` | Évolutions par objet, amitié et autres triggers approuvés via un resolver typé | core/gameplay/runtime/editor | RM-047 | `L` |
| `RM-049` — TM/HM Item Support V0 | `FG-073` | Compatibilité, cible, apprendre/remplacer/refuser, consommation et save round-trip | core/gameplay/runtime/UI joueur/editor | RM-041 | `L` |
| `RM-050` — Title Options & Credits Actions V0 | `FG-162`, `FG-147` | Activer Options et Crédits depuis le titre et définir leur disponibilité avant/après fin | runtime/UI joueur/Hub | Phase 1 | `M` |
| `RM-051` — Save & Autosave Policy V1 | `FG-014`, `FG-163`, proposé `FG-170` | Lifecycle manuel/autosave explicite, récence par slot et sémantique Continue/Load | runtime/UI joueur/Hub | Phase 1 | `M` |
| `RM-052` — Display/Fullscreen/Resolution V0 | proposé `FG-171` | Mode fenêtré/plein écran, scaling sûr et préférences d'affichage persistées par plateforme desktop | UI joueur/runtime/Hub | Phase 0 | `M` |

### Règles UX

- Aucun utilisateur normal ne saisit manuellement des IDs de profil, map, espèce, objet ou asset.
- La suppression d'un slot exige une confirmation explicite et identifie le slot exact.
- Continue et Load ne peuvent être des actions identiques.
- « Jeu le plus récent » utilise une preuve persistée de dernière utilisation, pas l'ordre d'une liste.
- PC et party préservent l'invariant « au moins un Pokémon utilisable ».
- L'autosave nomme exactement le slot et les transitions lifecycle autorisées.
- L'affichage ne contourne ni le responsive layout ni les tests de text scaling.

### Gate de validation de la Phase 4

PASS exige clavier, gamepad et tactile pour chaque nouveau parcours, plus resize/text-scale et persistance après redémarrage. Tous les textes joueur utilisent des clés de localisation.

---

## 7. Phase 5 — Fondation du Personalization Hub

**Priorité :** P1

**Objectif de phase :** établir un contrat de présentation appartenant au projet et livrer branding, vidéo, typographie et thème sémantique comme capacités bout-en-bout.

### Lots

| Lot | Livrable | Packages principaux | Dépend de | Taille |
|---|---|---|---|---|
| `PH-000` — Presentation Contract, Migration & Hub Shell | `ProjectPresentationProfile` versionné, catégories sémantiques, migration legacy, shell no-code et diagnostics partagés | core/editor/distribution | Phase 0 | `L` |
| `PH-001` — Existing Branding Runtime Wiring | Consommer icon, cover, hero/background, accent, title music et layout dans le player installé | distribution/UI joueur/runtime/Hub | PH-000 | `M` |
| `PH-002` — Intro Video V0 | Importer, valider, packager, lire, skipper et fournir un fallback sûr pour la vidéo d'intro | core/editor/distribution/runtime/UI joueur/Hub | PH-000, PH-001 | `L` |
| `PH-003` — Project Typography V0 | Fontes embarquées, rôles, licences, fallbacks plateforme et preview live | core/editor/distribution/UI joueur/runtime | PH-000 | `L` |
| `PH-004` — Semantic Theme & HUD V0 | Tokens projet pour titre, dialogue, menu, HUD overworld/combat avec validation de contraste | core/editor/UI joueur/runtime | PH-000, PH-003 | `L` |

### Frontière contractuelle PH-000

Propriété des sources planifiée :

```text
packages/map_core/lib/src/models/project_presentation_profile.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/map_core.dart
packages/map_editor/lib/src/features/personalization/
packages/map_distribution/lib/src/game_package_manifest.dart
packages/map_distribution/lib/src/game_package_manifest_codec.dart
```

Le manifest de distribution est une sortie dérivée. Il ne doit pas devenir l'unique source de vérité auteur.

### Matrice d'acceptation vidéo PH-002

Le lot commence par un spike plateforme, pas par une dépendance choisie au hasard. Il documente :

- conteneurs/codecs supportés par macOS, Windows, Linux, iOS et Android ;
- résolution, débit, durée et taille maximales validées ;
- poster et fallback direct vers le titre ;
- policy de skip et de replay ;
- pause/reprise lifecycle ;
- reduced motion ;
- sous-titres/captions ;
- bus audio et volumes ;
- assets corrompus, non supportés ou manquants.

Tests minimaux :

1. import valide et round-trip ;
2. format invalide rejeté avant packaging ;
3. export, installation, lecture, skip et titre réussis ;
4. échec du décodeur redirigé vers le poster ou le titre ;
5. reduced motion qui saute ou remplace la vidéo selon la policy ;
6. interruption lifecycle qui ne peut piéger le joueur ;
7. projet legacy sans données de présentation qui démarre sans changement.

### Règles typographiques PH-003

- Rôles : `display`, `body`, `dialogue`, `numbers`.
- Chaque rôle possède un fallback système explicite.
- Une fonte absente/corrompue ne bloque pas le boot.
- Licence et droit de redistribution sont requis avant export.
- Text scaling et couverture des glyphes sont obligatoires.

### Règles de thème PH-004

- Les écrans feature consomment uniquement les tokens sémantiques.
- Aucune couleur projet n'est injectée via un `Color(0x...)` ad hoc.
- Un contraste invalide bloque la publication ou impose un fallback sûr.
- La couleur n'est jamais le seul porteur d'une information combat/statut.

### Gate de validation de la Phase 5

Une fixture Golden de personnalisation doit prouver :

```text
project presentation data
  → editor preview
  → package manifest/assets
  → Hub library branding
  → intro video/fallback
  → personalized title
  → gameplay dialogue/menu/HUD
```

Les fixtures legacy restent valides visuellement et fonctionnellement via les fallbacks.

---

## 8. Phase 6 — Intégration plateforme et présentation

**Priorité :** P2

**Objectif de phase :** rendre les préférences effectives, terminer le workflow du Personalization Hub et le packager avec des garanties d'accessibilité/localisation.

### Lots

| Lot | Liens canoniques | Livrable | Packages principaux | Dépend de | Taille |
|---|---|---|---|---|---|
| `PH-005` — Audio Identity & Mixer V0 | proposé `PH-005` | Bus master/music/effects, routage titre/overworld/combat/cinématique, transitions et volumes persistés | core/runtime/UI joueur/Hub | PH-001, PH-002 | `L` |
| `RM-060` — Preference Projection & Accessibility V0 | proposé `FG-167` | Projeter les préférences dans le runtime : contraste, reduced motion, texte, haptique, hints, sémantiques lecteur d'écran et information non color-only | UI joueur/runtime/Hub | PH-004, PH-005 | `L` |
| `RM-061` — Localization Completion V0 | proposé `FG-168` | Retirer le français runtime codé en dur, localiser présentation/crédits et définir la locale de fallback | core/editor/runtime/UI joueur/Hub | PH-000 | `L` |
| `RM-062` — Control Remapping V0 | proposé `FG-169` | Profils clavier/gamepad/tactile, conflits, glyphes et reset des defaults | UI joueur/runtime/Hub | Phase 0, `FG-165` | `L` |
| `PH-006` — Advanced Hub Previews & Presets | proposé `PH-006` | Catégories recherchables, previews multi-écrans, presets, comparaison et reset par section | editor | PH-002–PH-005 | `M` |
| `PH-007` — Packaging & Golden Personalization E2E | proposé `PH-007` | Hashes, preflight et preuve export→install→intro→titre→jeu | distribution/editor/runtime/UI joueur/Hub/host | PH-000–PH-006 et RM-060–RM-062 | `L` |

### Gate de validation de la Phase 6

PASS exige :

- les volumes affectent chaque bus enregistré ;
- haptics/hints sont consommés ou retirés de l'UI publique ;
- aucun texte joueur codé en dur ne reste dans les surfaces auditées ;
- previews et runtime utilisent les mêmes contrats ;
- les fallbacks vidéo/fontes/thème sont couverts avec sémantiques lecteur d'écran et signaux non color-only ;
- le packaging rejette licences manquantes, médias non supportés et hashes cassés.

---

## 9. Phase 7A — Durcissement release gameplay et clôture canonique

**Priorité :** P0 une fois les phases fonctionnelles terminées

**Objectif de phase :** produire un receipt gameplay reproductible et réconcilier les trackers avec des preuves fraîches, indépendamment de la personnalisation.

### Lots

| Lot | Liens canoniques | Livrable | Dépend de | Taille |
|---|---|---|---|---|
| `RM-069` — Golden Journey 19 Criteria Gate | `FG-181`, `FG-182` | Test installé traversant les 19 critères : New Game, starter, 2–3 maps, NPC/dialogues/cutscene, rencontre/capture/PC, trainer, XP/argent/level-up/move, badge ou flag, Surf, shop, centre, save/load, fin, résultat, crédits et retour Hub | RM-001–RM-004, RM-010–RM-015, RM-020–RM-023, RM-025–RM-027, RM-030–RM-035, RM-040–RM-042, RM-045, RM-050–RM-051 | `L` |
| `RM-070` — Full Monorepo Regression Gate | `FG-183` | Exécuter tous les tests/analyzes et les deux smokes runtime ; préserver les logs exacts | RM-069 | `M` |
| `RM-071` — Platform Build & Device QA | `FG-185` | Release macOS puis builds approuvés, install/launch et walkthrough joueur humain | RM-070 | `L` |
| `RM-072` — Reports & Roadmap Reconciliation | `FG-001`, `FG-184` | Mettre à jour rapports/dashboard uniquement depuis les receipts actuels et archiver les snapshots PSDK contradictoires | RM-070, RM-071 | `M` |
| `RM-073` — MVP Release Gate Receipt | `FG-185` | Receipt structuré reliant commit autorisé, tree/dirty state, fingerprint projet, hash du package inspecté/installé, tests, analyzes, builds, walkthrough et limites | RM-070–RM-072 | `S` |

Le cutline exact `FG-185` est la liste de dépendances de `RM-069`, suivie de `RM-070` à `RM-073`. Les autres remédiations restent utiles sans élargir silencieusement le MVP signé : objets tenus (`RM-024`), nature/IV/EV (`RM-028`), Struggle (`RM-029`), hazards/pickups (`RM-036`/`RM-037`), templates (`RM-038`), map/identité/vente/métadonnées/évolutions/TM/affichage (`RM-043`/`RM-044`/`RM-046`–`RM-049`/`RM-052`), gate combat complète (`RM-053`) et tous les lots `PH-*`. Leur statut incomplet reste visible dans les release notes.

### Commandes de gate complète

À exécuter séquentiellement, package par package :

```bash
(cd packages/map_core && dart test && dart analyze)
(cd packages/map_gameplay && dart test && dart analyze)
(cd packages/map_battle && dart test && dart analyze)
(cd packages/map_runtime && flutter test && flutter analyze)
(cd packages/map_editor && flutter test && flutter analyze)
(cd packages/map_player_ui && flutter test && flutter analyze)
(cd packages/map_distribution && dart test && dart analyze)
(cd apps/pokemap_hub && flutter test && flutter analyze)
(cd examples/playable_runtime_host && flutter test && flutter analyze)

(cd packages/map_runtime &&
flutter test test/phase_a_golden_battle_slice_smoke_test.dart)

(cd examples/playable_runtime_host &&
flutter test test/phase_a_golden_slice_launch_test.dart)

(cd apps/pokemap_hub &&
flutter build macos --release)
```

Les autres commandes de build plateforme ne sont ajoutées qu'après approbation de la liste des cibles.

### Conditions GO release

1. Chaque commande sélectionnée sort avec `0`.
2. Les 19 critères MVP possèdent une preuve actuelle.
3. Hub→titre→histoire→crédits réussit via le chemin fallback legacy/default, sans dépendance `PH-*`.
4. Aucun champ d'authoring promu ne manque de consommateur runtime.
5. Aucun receipt périmé n'est présenté comme actuel.
6. État Git, commit autorisé, tree hash, dirty-state et hash du package sont cohérents et enregistrés.
7. Les omissions post-MVP sont explicites.
8. Si l'état de release n'est pas propre/committé avec autorisation, RM-073 reste `BLOCKED/NO-GO` ; un SHA seul ne signe jamais un diff dirty.

Si une condition échoue, `FG-185` reste `PARTIAL / NO-GO`.

### Phase 7B — Gate release personnalisation

`PH-007` reste indépendant de `FG-185`. Ses conditions GO sont :

1. export→install→intro→titre personnalisé→jeu réussit ;
2. vidéo, fonte, audio ou thème manquant/corrompu déclenche un fallback sans bloquer le boot ;
3. preview et runtime résolvent le même profil ;
4. la matrice plateformes/codecs possède des preuves de build/lancement ;
5. hashes, licences et preflight package passent.

Une release peut donc être :

- gameplay-ready mais personnalisation partielle ;
- personnalisation-ready sur un build gameplay non releasable ;
- totalement prête uniquement lorsque `FG-185` et `PH-007` sont GO.

---

## 10. Phase différée — parité Pokémon avancée

Ces lots canoniques restent hors du chemin critique de remédiation :

| Lot canonique | Capacité | Condition de promotion |
|---|---|---|
| `FG-200` | Combats doubles | Décisions singles et UI stabilisées |
| `FG-201` | Méga/Téra/Z/Dynamax | Génération/règles cibles choisies |
| `FG-202` | Pension/reproduction | Party, PC et progression complets |
| `FG-203` | Échanges et combats en ligne | Runtime local et identité de sauvegarde stables |
| `FG-204` | Concours/minijeux | Aventure principale prête à sortir |
| `FG-205` | Battle Frontier | Gate de parité combat complète |
| `FG-206` | UX avancée IV/EV/nature | Direction compétitive approuvée |
| `FG-207` | Parité Pokédex moderne complète | Périmètre de génération et de données approuvé |

Pêche, Headbutt, Repel, familles de Balls et capacités de terrain hors Surf restent aussi différés sans promotion explicite.

Backlog additionnel relevé par l'audit mais non placé sur le chemin critique MVP :

- modèle de quêtes et journal ;
- course, bicyclette et déplacement monté ;
- provider systémique temps/météo overworld ;
- Ligue, Panthéon et structure postgame ;
- carte de dresseur et succès ;
- accessibilité combat avancée : vitesse de combat, délais de choix, mode simplifié et aides de difficulté distinctes de l'IA trainer ;
- crafting, cuisine et systèmes secondaires de type camp.

Ces sujets exigent une conception produit et des identifiants de lots canoniques avant implémentation.

---

## 11. Couverture des constats d'audit

| Constat `FG-000` | Réponse de la roadmap |
|---|---|
| Lysa : `Too many elements` | RM-001 |
| Solver symbolique `indeterminate` à 16 384 états | RM-002 |
| Receipt release manquant ou obsolète | RM-003, RM-070–RM-073 |
| Contrôles editor potentiellement mensongers sur le support runtime | RM-004, RM-026, RM-035 |
| Histoire sans accès au résultat/crédits | RM-010–RM-014 |
| Mouvement/présence NPC incomplets | RM-015 |
| Bibliothèque de templates d'événements incomplète | RM-038 |
| Difficulté trainer ignorée par PSDK | RM-021 |
| Fuite/objet/switch divisés entre legacy et PSDK | RM-022, RM-023 |
| Objets tenus non reliés au bridge | RM-024 |
| Récompenses trainer pas entièrement no-code | RM-025 |
| One-shot/follow-up/templates trainer incomplets | RM-027 |
| Nature runtime neutre et valeurs IV/EV adverses par défaut | RM-028 |
| PP épuisés pouvant finir sur `noLegalChoice` | RM-029 |
| Kinds et taux de rencontres surpromus | RM-030, RM-031, RM-035 |
| Lacunes rencontres statiques/cadeaux/état consumed | RM-032, RM-033 |
| Parcours badge/Surf incomplet | RM-034 |
| Hazards modélisés mais non consommés par le runtime | RM-036 |
| Parcours pickup et objet caché incomplets | RM-037 |
| Commandes soin/shop/PC sans preuve traversante actuelle unique | RM-069 |
| Summary PC et profondeur des menus | RM-040, RM-041 |
| Profils/slots de sauvegarde absents | RM-042 |
| Carte runtime/fast travel absents | RM-043 |
| Identité joueur absente | RM-044 |
| Recovery après whiteout incomplète | RM-045 |
| Vente en shop absente | RM-046 |
| Surnom/amitié/provenance absents | RM-047 |
| Conditions d'évolution limitées au niveau | RM-048 |
| Support TM/HM absent | RM-049 |
| Actions Options/Crédits désactivées au titre | RM-050 |
| Policy autosave et Continue/Load ambiguë | RM-051 |
| Réglages résolution/plein écran absents | RM-052 |
| Branding stocké mais non consommé | PH-000, PH-001 |
| Vidéo d'introduction absente | PH-002 |
| Fontes par projet absentes | PH-003 |
| Thème sémantique/HUD par projet absents | PH-004 |
| Préférences audio surtout déclaratives | PH-005 |
| Haptique/hints/accessibilité incomplets | RM-060 |
| Localisation incomplète | RM-061 |
| Remapping des contrôles absent | RM-062 |
| Aucun workflow d'authoring de personnalisation complet | PH-006 |
| Aucune gate export/install pour la personnalisation | PH-007 |

Chaque problème matériel non différé de `FG-000` est relié à au moins un lot d'exécution.

---

## 12. Propriété des packages et gestion des collisions

| Package/app | Responsabilité | Lots à forte collision |
|---|---|---|
| `map_core` | Contrats, sérialisation, diagnostics et matrices de capacités | RM-002, RM-004, RM-010, RM-020, RM-030, PH-000 |
| `map_gameplay` | Règles pures de stockage, récompense, rencontre et recovery | RM-023, RM-033, RM-036, RM-037, RM-040–RM-049 |
| `map_battle` | Moteur de combat et décisions canoniques | RM-020–RM-024 |
| `map_runtime` | Exécution Flame, bridge combat, completion et rencontres | RM-001, RM-012, RM-021–RM-024, RM-031–RM-037, RM-040–RM-052, RM-069, PH-001–PH-005 |
| `map_editor` | Authoring guidé, previews et validation | RM-011, RM-025, RM-027, RM-030–RM-038, RM-040–RM-049, PH-000–PH-006 |
| `map_player_ui` | Titre, pause, résultat/crédits, préférences et accessibilité | RM-014, RM-022–RM-024, RM-036, RM-040–RM-052, RM-069, PH-001–PH-005 |
| `map_distribution` | Manifest dérivé, assets packagés et preflight | PH-000–PH-003, PH-007 |
| `pokemap_hub` | Bibliothèque, player installé, sauvegardes et préférences globales | RM-014, RM-042–RM-044, RM-050–RM-052, RM-069, PH-001–PH-007 |
| runtime host/Selbrume | Fixtures Golden et preuve de campagne | RM-001–RM-003, RM-013–RM-014, RM-034, RM-069, PH-007 |

Règle de séquencement : deux lots actifs ne modifient pas simultanément la même famille de fichiers à forte collision, sauf si le second est explicitement replanifié après le premier.

---

## 13. Ordre d'exécution recommandé

### File immédiate

1. `RM-001` Lysa authority-key uniqueness.
2. `RM-002` symbolic solver boundedness.
3. `RM-003` receipt refresh.
4. `RM-004` gate de vérité des capacités.
5. `RM-010` contrat Finish Game.
6. `RM-011` authoring no-code.
7. `RM-012` câblage runtime et `RM-015` état NPC, sérialisés si leurs fichiers editor/runtime se chevauchent.
8. `RM-013` scène terminale Selbrume.
9. `RM-014` E2E Hub-vers-crédits.

### File suivante

1. `RM-020` battle target.
2. `RM-021` AI difficulty.
3. `RM-022` decision contract.
4. `RM-023` objets combat génériques.
5. `RM-025` authoring des récompenses trainer.
6. `RM-030` matrice des rencontres.
7. `RM-031` conditions de rencontre organique.
8. `RM-034` badge/Surf.
9. `PH-000` contrat de présentation et shell du Hub.
10. `PH-001` câblage du branding.
11. `PH-002` vidéo d'introduction.

### File ultérieure

Terminer les lots restants des Phases 2–6 selon leurs dépendances, puis exécuter les Phases 7A et 7B indépendamment. Les deux ne sont obligatoires ensemble que pour une release revendiquant à la fois la jouabilité et la personnalisation.

---

## 14. Politique de maintenance de la roadmap

Après chaque lot :

1. écrire son rapport de preuves ;
2. proposer le statut `FG-*` ou `PH-*` associé ;
3. ne mettre à jour la roadmap canonique que sur demande explicite ;
4. enregistrer les tests, analyses et builds exacts ;
5. lister les limites restantes ;
6. ne pas promouvoir une phase seulement parce que la majorité de ses tests passe.

Quand le travail `PH-*` est approuvé, ajouter une section Personalization canonique à `pokemap_roadmap_mecaniques_fangame.md` ou créer une roadmap canonique dédiée, référencée depuis celle-ci. Ne pas laisser `PH-*` uniquement dans un rapport d'audit une fois l'implémentation commencée.

---

## 15. Preuves de planification

### 15.1 État Git initial

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
```

Toutes ces entrées précèdent cette roadmap et doivent rester préservées.

### 15.2 Fichiers modifiés par cette tâche de planification

Créé :

- `reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`

Aucun code source, test, fichier généré, autre rapport, roadmap canonique ou changement utilisateur préexistant n'a été modifié.

Le contenu complet du fichier créé est ce document.

### 15.3 Implémentation, tests et build

- Passe d'implémentation : **N/A**, tâche de roadmap uniquement.
- Tests créés ou modifiés : **aucun**, car aucun comportement produit n'a changé.
- Tests produit : **non exécutés** ; les trois échecs frais documentés par `FG-000` restent donc l'état autoritaire.
- Build produit : **non exécuté**.
- Validation adaptée : scan de placeholders, couverture des lots, cohérence des tables, vérification whitespace/diff, absence d'ignore et état Git.

Commandes de validation du document :

```bash
roadmap=reports/gameplay/fg_000_remediation_and_personalization_roadmap.md
if rg -n "T[B]D|To be complet[e]d|To be captur[e]d|fill in detail[s]|implement late[r]" "$roadmap"; then exit 1; fi
if rg -n '^cd ' "$roadmap"; then exit 1; fi
if git check-ignore -q "$roadmap"; then exit 1; fi
git diff --no-index --check /dev/null "$roadmap" >/dev/null
test "$?" -le 1
awk '/^\|/ {n=gsub(/\|/,"|"); if (in_table && n!=expected) exit 1; expected=n; in_table=1; next} {in_table=0; expected=0}' "$roadmap"
test -z "$(comm -3 \
  <(rg -o '(RM|PH)-[0-9]{3}' "$roadmap" | sort -u) \
  <(rg -o '`(RM|PH)-[0-9]{3}` —' "$roadmap" | sed -E 's/`| —//g' | sort -u))"
git status --short --untracked-files=all
```

Résultats frais : exit `0` et `roadmap-validation: PASS` ; aucun placeholder bloquant, aucun `cd` nu dans les blocs multi-packages, fichier non ignoré, diff-check sans erreur whitespace, aucune table incohérente et 59 identifiants `RM/PH` uniques définis et référencés.

### 15.4 Verdicts des passes

- Audit/architecture indépendant : **GO**, sous réserve de conserver `FG-185` et `PH-007` comme gates séparées et de ratifier les nouveaux IDs avant canonicalisation ; intégré.
- Build/validation indépendant : **GO pour la stratégie de preuve**, à condition de commencer par les trois tests rouges et d'exiger tests ciblés, suites complètes, analyses et preuves traversantes ; intégré dans la Phase 0 et les DoD.
- Implémentation : **N/A**, aucune modification produit.
- Critique finale indépendante : **GO**, aucun bloquant restant après correction de l'ordre de convergence `RM-014`/`RM-069`, séparation des gates combat MVP/complète et validation fraîche du Markdown.

### 15.5 État Git final

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
?? reports/gameplay/fg_000_remediation_and_personalization_roadmap.md
```

Seul le dernier fichier est créé par cette tâche. Toutes les autres modifications sont préexistantes et ont été préservées.

### 15.6 Auto-critique

- Cette roadmap de portefeuille compte 59 lots : elle donne les frontières et gates, mais chaque lot exige encore un plan d'implémentation détaillé.
- Les tailles `S/M/L` mesurent la coordination, pas la durée ; aucune estimation calendaire n'est revendiquée.
- Les IDs `RM-*`, `PH-*` et les nouveaux `FG-*` proposés ne sont pas canoniques tant qu'une mise à jour explicite du tracker ne les ratifie pas.
- Aucun diagnostic de cause racine ni correctif produit n'a été réalisé ici ; les trois tests rouges de l'audit restent des blocages.
- Le cutline MVP exclut volontairement objets tenus, nature/IV/EV et Struggle seulement si leurs contrôles cessent d'être promus jusqu'à leur livraison.
- La vidéo d'introduction reste conditionnée par un spike codecs/plateformes et des preuves réelles ; aucun support universel n'est supposé.
- Le worktree contient des changements utilisateur préexistants. Toute implémentation devra les isoler et ne pourra produire de receipt release tant que l'état signé n'est pas reproductible.

---

## 16. Passage à l'exécution

Avant d'implémenter un lot :

1. sélectionner exactement un lot ;
2. lire sa DoD canonique `FG-*` et les rapports liés ;
3. utiliser `systematic-debugging` pour les échecs ou `brainstorming` pour un nouveau comportement produit ;
4. créer un plan d'implémentation dédié avec `writing-plans` ;
5. exécuter avec `subagent-driven-development` ou `executing-plans` ;
6. clôturer avec `verification-before-completion` et `requesting-code-review`.

Premier lot recommandé : **RM-001 — Lysa Source Authority-Key Regression**, en parallèle uniquement avec **RM-002 — Symbolic Solvability State-Space Hardening** si des exécutants séparés et la propriété des fichiers sont confirmés.
