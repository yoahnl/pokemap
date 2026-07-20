# NSC-42 — Conditions, comportement, Scene liée et simulation Event

Date : 2026-07-20
Verdict : **DONE proposé pour NSC-42**
Roadmap : phase 4 Narrative Studio, troisième lot sur six

## Résumé exécutif

Event Builder affiche désormais sans ambiguïté le contrat actuel : toutes les conditions Fact/EventConsumed sont combinées en AND. L’inspecteur expose en permanence one-shot/réutilisable, priorité, ordre et leur effet, ainsi que les résultats et conséquences de la Scene liée en lecture seule avec son deep link.

Une nouvelle side sheet permet de choisir une source existante, de contrôler les Facts et les Events déjà consommés, puis de tester le déclenchement. Le calcul n’est pas dupliqué dans l’éditeur : `simulateNarrativeEventDispatch` construit uniquement un `GameState` temporaire, puis `NarrativeEventDispatchAuthorityReady.simulate` réutilise `plan`, le même ordre de candidats et la même évaluation de conditions que le runtime. Le résultat explique chaque feuille AND, le gagnant, les refus et la concurrence priorité/ordre sans écrire le projet.

## Scope confirmé

- Inclus : vérité AND-only, comportement one-shot/reusable, priorité/ordre, Scene/projections read-only, simulateur source/Facts/progress, traces canoniques, cas draft/inactif/source absente/consommé/concurrence.
- Exclus : OR/NOT/groupes, reset policies, édition de Scene depuis Event, in-flight contrôlable par l’UI et migration legacy avec preuve runtime. Ces sujets restent NSC-43/45.
- Aucun schema V1 n’est modifié ; aucune reset policy n’est inventée.
- La phase 5 reste hors périmètre.

## Audit initial

- `NarrativeEventDispatchAuthority` était déjà l’autorité pure utilisée par gameplay/runtime, mais ne fournissait pas de trace explicable.
- `plan` évaluait Fact et EventConsumed en AND, sélectionnait priorité décroissante, ordre croissant puis ID lexical.
- Le read model Event exposait déjà Scene, outcomes, conséquences, reuse policy, priorité et ordre, mais l’inspecteur masquait priorité/ordre hors concurrence et ne listait pas les projections.
- `setNarrativeEventReusePolicy` affichait encore `runtimeSupportPending` alors que gameplay consomme déjà réellement cette policy.
- Aucun simulateur produit ne permettait de contrôler Facts/progression et aucun test n’alignait explicitement son gagnant avec le planner gameplay.

Risques principaux : créer une truth table parallèle, suggérer un OR non sérialisable, simuler sur des bytes non attestés, écrire le projet pendant un aperçu, ou présenter un claim dual-read sans preuve runtime.

## État Git initial

- Branche : `main`.
- HEAD : `c181c99e feat(narrative): ground events in real map sources`.
- NSC-42 a commencé immédiatement après le commit isolé NSC-41.
- Deux scripts racine non suivis (`build_global_surfaces_tmp.py`, `finalize_global_surfaces_tmp.py`) sont apparus transitoirement pendant la critique puis avaient disparu au contrôle final. Ils n’ont été ni lus, ni modifiés, ni stagés par ce lot.

## Inventaire et zones modifiées

| Fichier | Zone | Impact |
|---|---|---|
| `packages/map_core/lib/src/read_models/narrative_event_validation_read_model.dart` | input, statuts, raisons, traces condition/candidat et report | Contrat read-only fermé et immutable pour expliquer une décision canonique. |
| `packages/map_core/lib/src/authoring/narrative_event_configuration_operations.dart` | `simulateNarrativeEventDispatch`, suppression du faux `runtimeSupportPending` | Construit l’état contrôlé et délègue à l’autorité ; aucune écriture. |
| `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` | évaluation partagée, `simulate`, mappings de trace | `plan` et simulation partagent exactement candidats, conditions et ordre. |
| `packages/map_core/test/narrative_event_configuration_authoring_test.dart` | support runtime reuse policy | Empêche le retour du message trompeur et n’invente aucun reset. |
| `packages/map_core/test/narrative_event_dispatch_authority_test.dart` | scénarios simulation | Couvre AND complet, priorité, draft, disabled, source absente et one-shot consommé. |
| `packages/map_gameplay/test/narrative_event_dispatch_truth_table_test.dart` | parité planner/simulateur | Prouve que gameplay et Event Builder choisissent le même gagnant. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart` | use case `simulate` | Recharge un snapshot attesté et appelle core sans persistence. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart` | nouvelle side sheet | Contrôles no-code source/Facts/progress et rendu explicable Design System. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart` | action Tester et libellé AND | Rend le simulateur découvrable depuis le bloc Conditions. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` | conditions, projections et comportement | Affiche AND, résultats, conséquences, one-shot/reusable, priorité/ordre et règle de concurrence. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` | transport callback | Garde le workspace présentatif. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart` | composition side sheet | Charge le snapshot et branche le use case read-only. |
| `packages/map_editor/test/event_builder_v2_simulation_test.dart` | test widget contrôlé | Prouve saisie temporaire, appel, résultat, condition et comportement. |
| `packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart` | test sur fixture disque | Prouve snapshot frais, gagnant attendu, zéro persist et bytes identiques. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart` | assertions AND/Scene/comportement/action | Prouve fidélité et accessibilité de l’action Tester. |
| `docs/superpowers/plans/2026-07-20-nsc-42-event-simulation.md` | micro-plan | Cadre TDD et frontières du lot L. |

## Fichiers créés — contenu canonique

Le contenu intégral est dans le même commit et consultable via `git show <commit-nsc-42>:<chemin>`.

| Fichier | Lignes | SHA-256 |
|---|---:|---|
| `docs/superpowers/plans/2026-07-20-nsc-42-event-simulation.md` | 24 | `df43887122e7734211ef0a468427ec87e64440feb9d3063839a9c9ac7ad900e5` |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_simulation_sheet.dart` | 429 | `6afca15c45bbe4847995a03b74cf9526e6f0fbc565b73ac5b814e08ff06ed2bb` |
| `packages/map_editor/test/event_builder_v2_simulation_test.dart` | 179 | `fad8d1d8de8d897bee7298389dd5c0d95c622a30a4e4d053f238e36644db05ed` |

Le présent Evidence Pack est le quatrième fichier créé et contient son propre contenu intégral.

## TDD et tests

Rouge initial : les tests core ne compilaient pas car les contrats `NarrativeEventSimulation*` et `simulateNarrativeEventDispatch` étaient absents. Le premier vert a révélé les imports directs manquants du codec/definition, corrigés avant validation. Le premier test Flutter a ensuite refusé `NarrativeOutcomeRef?`, puis une ancienne assertion workspace de priorité ; les deux contrats ont été corrigés sans affaiblir les tests.

```text
cd packages/map_core
dart test test/narrative_event_configuration_authoring_test.dart test/narrative_event_dispatch_authority_test.dart && dart analyze
+37: All tests passed!
No issues found!

cd packages/map_gameplay
dart test test/narrative_event_dispatch_truth_table_test.dart && dart analyze
+6: All tests passed!
No issues found!

cd packages/map_editor
flutter test test/event_builder_v2_simulation_test.dart test/ui/canvas/event_builder_v2_flow_fidelity_test.dart test/ui/canvas/event_builder_v2_workspace_test.dart test/narrative_event_builder_v2_use_case_test.dart
+32: All tests passed!
```

Les tests couvrent positif, négatif, garde-fous et non-régression : AND complet, condition fausse, source manquante, draft, disabled, one-shot consommé, concurrence, widget contrôlé, zéro écriture et ancienne densité workspace.

## Analyse et build

```text
cd packages/map_editor
flutter analyze <9 fichiers NSC-42>
No issues found! (ran in 4.1s)

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Analyse complète editor :

```text
flutter analyze
11 issues found. (ran in 5.1s)
```

Les 11 warnings sont la baseline inchangée de `dialogue_studio_dialogs.dart` (un `unused_element`, dix usages protected/visibleForTesting), hors fichiers NSC-42.

```text
git diff --check
<aucune sortie>

audit raw colors des fichiers UI NSC-42
<aucune couleur brute>
```

## Passes locales nommées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : l’autorité runtime existante reste l’unique arbitre. |
| Implémentation | PASS : état contrôlé + traces + UI, sans writer ni schema parallèle. |
| Tests | PASS ciblé : 37 core, 6 gameplay et 32 editor. |
| Build / Validation | PASS avec baseline documentée : core/gameplay/ciblé editor propres, build macOS réussi. |
| Critique finale | PASS avec limite explicite : claims dual-read avec preuve runtime absente échouent fermés au lieu d’être simulés fictivement. |

## Auto-critique, limites et risques

- L’autorité évalue maintenant toutes les feuilles pour produire une explication complète, mais conserve comme raison canonique le premier échec dans l’ordre auteur ; la décision finale reste identique.
- L’UI expose tous les Facts et Events du snapshot. Une future vue filtrée pourra réduire le bruit, mais masquer aujourd’hui les concurrents ou dépendances rendrait le test moins contrôlable.
- L’état `inFlight` existe dans le contrat core et dans la trace, mais n’est pas présenté comme progression persistée dans l’UI car il s’agit d’un état éphémère d’exécution.
- Un registre dual-read sans claims est simulable avec son index structurel. Des claims legacy exigent la même preuve runtime que le jeu et bloquent sinon ; NSC-45 fermera ce chemin avec la migration/round-trip.
- Aucun OR/NOT/reset n’est supporté ou suggéré comme disponible.
- Les deux scripts temporaires racine observés transitoirement n’étaient plus présents au contrôle final et n’ont jamais été inclus au lot.

## État Git final attendu

- Un commit NSC-42 contient seulement les fichiers listés, le micro-plan forcé et ce rapport.
- Aucun fichier hors inventaire n’est stagé.
- Aucun push n’est effectué.

## Prochaine étape non implémentée dans ce commit

`NSC-43 — Expressions de conditions et politiques de réarmement Event` : faire évoluer schema, codec, runtime et UI ensemble vers all/any/not et des reset policies déterministes.
