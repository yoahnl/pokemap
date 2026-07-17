# Event Builder V2 — Roadmap d’exécution

> **Pour les agents d’implémentation :** utiliser le skill local
> `subagent-driven-development` ou `executing-plans` pour exécuter cette
> roadmap lot par lot. Les lots sont les unités de suivi ; leurs cases
> `- [ ]` sont les critères binaires de fermeture.

**Objectif :** livrer un Event Builder V2 réellement branché au produit,
source-first, persistant, jouable dans Selbrume et visuellement aligné sur la
référence 1672 × 941 fournie par l’utilisateur.

**Architecture :** le Map Editor possède les maps et leurs sources physiques ;
l’Event Builder référence ces sources et configure l’Event ; la Scene possède
le déroulement narratif, les branches et les conséquences. Le runtime consomme
le registre V2 sans dépendre de l’UI editor.

**Stack :** Dart, Flutter desktop, `map_core`, `map_gameplay`, `map_battle`,
`map_runtime`, `map_editor`, host jouable Selbrume, tests Dart/Flutter et
goldens raster.

---

## 1. Rôle de ce document

Ce fichier est la source de vérité pour l’ordre d’exécution, le lot actif, les
gates et les preuves restantes. Il ne remplace pas les contrats détaillés :

- `MVP Selbrume/event_builder_v2_architecture_decisions.md` reste normatif pour
  les décisions produit et d’architecture ;
- `MVP Selbrume/road_map_event_builder_v2.md` reste l’historique détaillé des
  phases A à L et des jalons V2-01 à V2-43 ;
- les plans sous `docs/superpowers/plans/` restent des aides d’implémentation ;
- ce document prime sur ces plans pour l’ordre et le statut courant.

Une modification de ce fichier ne vaut ni validation technique, ni
autorisation d’écrire dans Git. Les opérations `add`, `commit`, `push`, branche,
stash ou reset exigent toujours une demande explicite de l’utilisateur.

Tous les lots s’exécutent dans le checkout actuel. Aucun worktree Git dédié,
aucune nouvelle branche et aucun déplacement du chantier ne sont requis. Les
changements déjà présents restent préservés et sont attribués par S0 avant la
prochaine modification de production.

## 2. Dashboard courant

Mise à jour terminale K/L observée le **2026-07-17**. Le tableau maître reste
le ledger formel strict ; la ligne technique située dessous indique ce qui est
effectivement implémenté et vérifié sans prétendre qu’un checkpoint Git existe.

| Indicateur | Valeur |
|---|---|
| Prochain lot | `S0 — checkpoint récupérable` |
| Statut du prochain lot | `VERIFYING` |
| Prochaine phase | `Phase 0 — Stabilisation` |
| Phases `DONE` | **0 / 7** |
| Lots d’exécution `DONE` | **0 / 24 courants** |
| Gate release | **NO-GO observé ; L3 formel non démarré** |
| Prochaine action | Obtenir le checkpoint S0 autorisé, puis exécuter G0 ; blockers release conservés avant L2 |
| HEAD | `2f68328a38bf218c843e497940f8dd24a7a9c194` |
| Checkout initial de la clôture | 64 entrées suivies/indexées + 171 non suivies = **235** |
| Checkout final de la clôture | 69 entrées suivies/indexées + 180 non suivies = **249** |
| Route Events produit | V2 réelle : `EventBuilderV2ProductRoute` selon le mode |
| Registre V2 sur disque | 3 JSON courants contenant `eventRegistry`, dont Selbrume |
| Référence visuelle atteinte | PASS technique feature ; écarts P2 shell en attente d’acceptation utilisateur |
| Performance incrémentale | p95 `13410 µs` pour budget gelé `36000 µs` |
| Matrice globale | core/gameplay/host verts ; runtime/editor rouges sur baselines étrangères |

### Ledger technique K/L, distinct du statut formel

| Lot | Résultat technique frais | Décision |
|---|---|---|
| K1 | capture full-shell 1672 × 941 et comparaison normatives | `PASS` |
| K2 | conditions, Scene, résultats, conséquences, monde et priorité projetés | `VERIFYING — P2 à approuver` |
| K3 | 800 étroit + 1280/1440/1480/1672/1920 + 125 % | `PASS` |
| L1 | corpus/migration/recovery/no-fallback, guard v2Only et perf | `PASS Event V2` |
| L2 | package regressions/analyzes/builds complets | `BLOCKED global` |
| L3 | analyse activation/dépréciation produite hors séquence formelle | `NO-GO informatif` |

Le NO-GO conserve `legacyOnly | dualRead | v2Only`, n’active pas V2 par défaut
et ne déprécie pas V1. Les blockers restants sont listés dans l’Evidence Pack L.

### Lecture honnête de l’avancement historique

| Mesure historique | Résultat | Interprétation |
|---|---:|---|
| Missions formellement acceptées A à F2 | 7 / 13 = **53,8 %** | Architecture, domaine, migration, authoring et runtime de base |
| Missions présentes dans l’historique Git A à F1 | 6 / 13 = **46,2 %** | F2 et la suite ne sont pas encore sécurisées par un checkpoint Git |
| Jalons techniques jusqu’à G inclus | 26 / 44 = **59,1 %** | Indicateur ancien, non utilisé pour piloter la suite |

Ces trois pourcentages ne sont pas additionnés à la nouvelle roadmap : les
unités historiques sont de tailles différentes. À partir de maintenant, aucun
pourcentage d’effort n’est inventé : le suivi affiche seulement **X lots fermés
sur N lots courants**.

### État réel à ne pas confondre avec une clôture

| Zone | État utilisable | Pourquoi elle ne compte pas `DONE` ici |
|---|---|---|
| F2 | Implémentation et Evidence Pack présents | Pas de checkpoint Git distinct dans l’historique courant |
| G | Bridge Map ↔ Event et matrice ciblée présents | S0 n’est pas fermé ; statut maître `NOT STARTED` |
| H | Route V2, UI et authoring ciblé présents | Séquence formelle S0→G0→V0→H non fermée |
| I | Validation, destinations, migration/recovery et performance présents | Séquence formelle jusqu’à I5 non fermée |
| J | Fixtures Selbrume, runtime et smokes ciblés présents | Promotion et prédécesseurs formels non fermés |
| K | Full-shell, goldens, responsive et matrice K `+48` verts | P2 chrome non approuvé et prédécesseurs formels ouverts |
| L | Campagne release exécutée avec verdict NO-GO | Entry gate non satisfaite ; L1–L3 restent `NOT STARTED` au tableau maître |

## 3. Contrat produit non négociable

1. Le **Map Editor** crée, place et modifie les PNJ, objets, zones et maps.
2. La liste des maps de l’Event Builder est une navigation et un regroupement,
   pas un champ `map` indépendant dans le formulaire.
3. Une source spatiale est choisie atomiquement :
   `kind + mapId + sourceId`. La map est dérivée de la source et affichée en
   lecture seule.
4. Un PNJ, objet ou trigger existant est réutilisé. S’il manque, l’utilisateur
   est envoyé dans le Map Editor, le crée ou le place, puis revient au même
   brouillon Event.
5. L’Event Builder ne place rien sur la map : aucune coordonnée, tuile, zone à
   dessiner, ID brut ou géométrie à saisir.
6. `mapEnter` référence la map elle-même. Un Event global, tel qu’un outcome
   qualifié, n’exige aucune map.
7. **Event ≠ Scene.** L’Event porte source, conditions, Scene cible et
   comportement. Actions, résultats, réactions et changements du monde restent
   Scene-owned.
8. Les blocs Scene visibles dans la référence sont soit de vraies interactions
   ouvrant l’éditeur de Scene, soit des projections clairement en lecture seule.
9. Aucun grip, drop target, connecteur ou bouton ne peut suggérer une interaction
   absente.
10. `legacyOnly | dualRead | v2Only` reste l’unique contrôle de transition. La
    lecture et l’import V1 restent disponibles jusqu’au verdict L3 ;
    l’authoring et le dispatch legacy restent gouvernés par ce mode.

Si l’objectif devient d’éditer directement toutes les actions, branches et
conséquences dans l’Event Builder comme le suggère visuellement la référence,
il faut d’abord ratifier un nouvel ADR. Ce n’est pas un simple ajustement
graphique.

## 4. Statuts et règles de comptage

| Statut | Définition |
|---|---|
| `NOT STARTED` | Le lot n’a pas commencé ou attend son prédécesseur |
| `IN PROGRESS` | Implémentation active ; un seul lot autorisé à la fois |
| `VERIFYING` | Code terminé, preuves et revue encore en cours |
| `DONE` | Toutes les assertions de sortie ont des preuves fraîches |
| `BLOCKED` | Le lot actif ne peut plus progresser sans décision ou changement externe précis |

Règles :

- une candidate, un harness, une maquette ou un test isolé n’est jamais un
  statut ;
- un lot futur dont la dépendance n’est pas `DONE` reste `NOT STARTED` ;
- seule la colonne `Statut` du tableau maître sert au calcul ;
- toute modification de production après validation invalide les tests,
  captures et hashes concernés ;
- un défaut préexistant peut être classé `BASELINE` seulement avec une preuve
  avant/après identique et une attribution explicite ; il doit tout de même être
  fermé avant L2 ;
- aucune phase suivante ne commence tant que le lot précédent n’est pas `DONE`,
  sauf L3 qui accepte un résultat L2 terminal `DONE` ou `BLOCKED` ;
- un seul lot et un seul writer sont autorisés : le sub-agent Implémentation est
  l’unique writer ; Audit, Tests, Build et Critique travaillent en lecture seule
  ou séquentiellement ; aucune écriture concurrente n’est autorisée, même sur
  des fichiers distincts.

Un défaut dans le scope reste dans le lot actif. Un défaut `BASELINE` hors scope
crée, après accord explicite, un lot correctif nommé comme `FIX-H3-01` — lot
source puis index séquentiel — et inséré avant le prochain lot ; tableau,
séquence et dénominateur sont mis à jour avant toute implémentation. Aucun
travail caché ne reste absorbé dans G, K ou L.

### Restore, compensation et rollback

Une restauration destructive n’est autorisée que si la révision, les hashes,
le receipt et l’ownership correspondent encore à la preuve initiale. Sinon :
aucune réécriture, journal conservé et plan compensatoire ou récupération
manuelle. Aucun downgrade n’est garanti après publication d’une donnée V2-only
non représentable en V1.

### Plans obligatoires avant I et J

I1 ne passe pas `IN PROGRESS` avant création et revue de
`docs/superpowers/plans/2026-07-16-event-builder-phase-i-validator-migration.md`.
J1 suit la même règle avec
`docs/superpowers/plans/2026-07-16-event-builder-phase-j-selbrume-golden-slice.md`.

### Lots de preuve sans nouveau comportement

`codex_rule.md` exige normalement un test créé ou modifié pour chaque lot. Pour
un lot strictement documentaire ou de validation, notamment S0, L2 ou L3, un test
cérémoniel est interdit : l’exécution doit obtenir une instruction utilisateur
explicite autorisant la vérification par tests existants, ou redéfinir le lot
autour d’un garde-fou testable réellement utile. Cette roadmap n’accorde pas à
elle seule cette exception.

## 5. Definition of Done commune

Un lot passe à `DONE` seulement lorsque toutes les cases suivantes sont vraies :

- [ ] le lot n’a aucun prédécesseur, ou sa condition d’entrée du tableau maître
      est satisfaite ;
- [ ] son périmètre et ses non-objectifs sont respectés ;
- [ ] tout nouveau comportement a eu un test ciblé échouant puis passant quand
      un test de régression est faisable ;
- [ ] les tests ciblés sont verts et aucune régression attribuable n’est
      introduite ;
- [ ] l’analyse des fichiers touchés est verte ;
- [ ] le format des fichiers touchés et `git diff --check` sont verts ;
- [ ] chaque package touché est analysé et le build applicable est vert, ou le
      caractère non applicable est justifié ;
- [ ] le flow réel est prouvé quand le lot touche l’UI, le disque ou le runtime ;
- [ ] l’Evidence Pack vivant de la phase respecte `codex_rule.md` : audit
      initial, verdicts des
      passes indépendantes, fichiers et zones modifiés, commandes et résultats
      exacts, état Git initial/final, auto-critique et risques ;
- [ ] une revue indépendante ne conserve aucun blocker ;
- [ ] aucun lock, golden, failure artifact ou fichier temporaire inattendu ne
      subsiste et l’état Git final est inventorié ;
- [ ] les octets validés sont récupérables par un commit explicitement autorisé
      ou par une archive autonome approuvée, hashée et restaurée en test ; un
      simple manifeste SHA-256 identifie les octets mais n’est pas un checkpoint ;
- [ ] le dashboard et le tableau maître sont mis à jour dans la même clôture.

La panne d’un outil de capture n’annule pas indéfiniment un lot : une capture
manuelle de la vraie application, au même viewport, hashée et inspectée, est une
voie de secours acceptable. Une capture du harness ne remplace jamais la route
produit.

## 6. Pilotage par 7 phases

Les 24 lots restent les unités techniques et sont implémentés dans leur ordre.
Pour limiter les relances coûteuses, les validations sont regroupées ainsi :

1. après chaque lot, exécuter uniquement ses tests ciblés rapides ;
2. à la fin de la phase, lancer tous ses tests ensemble, puis analyse et build ;
3. ne lancer la matrice complète du dépôt qu’en baseline S0 et en Phase 6 ;
4. ne jamais attendre la fin d’une phase pour tester un comportement nouveau.

| Phase | Lots | Résultat de phase | Gate groupé |
|---|---|---|---|
| 0 — Stabilisation | S0 | Checkout actuel attribué et récupérable | Baseline des packages, analyses et builds sans correction |
| 1 — Bridge et route produit | G0, V0, H1, H2 | Map ↔ Event V2, contrat visuel et liste projet réels | Matrice G + contrat référence + route/modes/liste + analyse/build editor |
| 2 — Authoring V2 | H3, H4, H5 | Création, édition, persistance, états et clavier | Use cases + save/reopen + workspace + accessibilité + régressions V1 |
| 3 — Validation et migration | I1 à I5 | Diagnostics, conflits, migration sûre et performance | Batch core/editor I + analyse core/editor + build editor |
| 4 — Golden Slice Selbrume | J1 à J5 | Trois sources, runtime, Lysa et promotion réelle | Batch editor/runtime/host J + smokes + builds editor/host |
| 5 — Fermeture visuelle | K1 à K3 | Fenêtre 1672 × 941 alignée et responsive | Goldens/captures + responsive + accessibilité + analyse/build editor |
| 6 — Release | L1 à L3 | Readiness complète et décision GO/NO-GO | Matrices L1/L2 complètes, puis décision L3 |

Une phase passe `DONE` lorsque tous ses lots ordinaires sont `DONE` et son gate
groupé est vert. La Phase 6 peut se terminer par un L3 `DONE` avec verdict
release `NO-GO` si L2 possède un résultat terminal `BLOCKED` documenté.

### Tableau maître des 24 lots restants

| # | Lot | Résultat observable | Dépend de | Statut |
|---:|---|---|---|---|
| 1 | S0 | État courant attribué et sécurisé | — | `VERIFYING` |
| 2 | G0 | Infrastructure Map Editor du bridge vérifiée | S0 | `NOT STARTED` |
| 3 | V0 | Contrat visuel complet figé avant l’UI | G0 | `NOT STARTED` |
| 4 | H1 | V2 montée sur la route produit selon le mode | V0 | `NOT STARTED` |
| 5 | H2 | Liste projet, maps, global, recherche et filtres réels | H1 | `NOT STARTED` |
| 6 | H3 | Création source-first persistée et réouverte | H2 | `NOT STARTED` |
| 7 | H4 | Éditeur et inspecteur fonctionnels et honnêtes | H3 | `NOT STARTED` |
| 8 | H5 | États secondaires, clavier et responsive fermés | H4 | `NOT STARTED` |
| 9 | I1 | Diagnostics d’intégrité V2 stables | H5 | `NOT STARTED` |
| 10 | I2 | Conflits et atteignabilité déterministes | I1 | `NOT STARTED` |
| 11 | I3 | Diagnostic cliquable vers la correction exacte | I2 | `NOT STARTED` |
| 12 | I4 | Migration UX, disque, recovery et compensation sûres | I3 | `NOT STARTED` |
| 13 | I5 | Validation incrémentale dans un budget ratifié | I4 | `NOT STARTED` |
| 14 | J1 | Trois sources Selbrume authorées via le produit | I5 | `NOT STARTED` |
| 15 | J2 | Fixture autonome, reload et recovery prouvés | J1 | `NOT STARTED` |
| 16 | J3 | PNJ, zone et objet déclenchent leur Scene au runtime | J2 | `NOT STARTED` |
| 17 | J4 | Golden Slice Lysa de bout en bout sur fixture | J3 | `NOT STARTED` |
| 18 | J5 | Données promues dans Selbrume et preuves rejouées | J4 | `NOT STARTED` |
| 19 | K1 | Écart visuel produit mesuré sur le contrat V0 | J5 | `NOT STARTED` |
| 20 | K2 | Route produit alignée sur la référence | K1 | `NOT STARTED` |
| 21 | K3 | États, tailles desktop et accessibilité fermés | K2 | `NOT STARTED` |
| 22 | L1 | Corpus, migration et performance prêts | K3 | `NOT STARTED` |
| 23 | L2 | Release Candidate exécutée jusqu’à un résultat terminal | L1 | `NOT STARTED` |
| 24 | L3 | GO/NO-GO et politique V1 explicites | L2 terminal | `NOT STARTED` |

Séquence stricte :

```text
S0 → G0 → V0 → H1 → H2 → H3 → H4 → H5
   → I1 → I2 → I3 → I4 → I5
   → J1 → J2 → J3 → J4 → J5
   → K1 → K2 → K3
   → L1 → L2 ⇢ L3
```

La flèche `⇢` signifie que L3 exige une exécution L2 fraîche et terminale :
`DONE` mène à une décision GO possible ; `BLOCKED` mène obligatoirement à un
NO-GO documenté.

## 7. Lots détaillés

### S0 — Stabiliser et sécuriser l’état courant

**Résultat :** chaque changement courant a un propriétaire, F2 est récupérable
et les dettes globales sont distinguées des régressions Event V2.

**Hors lot :** aucune correction de code, aucun nettoyage d’un changement
attribué et aucune opération Git sans autorisation explicite.

**Fichiers :**

- créer
  `reports/narrativeStudio/events/ns_event_v2_s0_stabilization_baseline.md` ;
- inventorier la roadmap historique et les Evidence Packs F2/G/K/L existants ;
- ne modifier aucun fichier de production avant l’attribution.

**Checklist :**

- [ ] classer les **249 entrées du snapshot S0 courant** en `F2`, `G`, `H/K candidate`,
      `L evidence`, `unrelated` ou `artifact`, puis inventorier cette roadmap
      séparément ;
- [ ] reproduire les baselines ciblées et globales sans corriger au passage ;
- [ ] confirmer l’absence de `packages/map_editor/test/failures/` et de lock
      Selbrume oublié ;
- [ ] contrôler séparément le whitespace des fichiers non suivis, puisque
      `git diff --check` ne les couvre pas ;
- [ ] demander le choix explicite : commits de phase autorisés, ou archive
      autonome hors worktree contenant diff suivi et contenus non suivis ;
- [ ] hasher l’archive alternative et réussir une restauration dans un dossier
      temporaire ; un manifeste seul laisse S0 en `VERIFYING` ;
- [ ] associer F2 à un checkpoint récupérable et publier la baseline exacte.

**DONE si :** aucun fichier inconnu, aucune preuve orpheline, aucune opération
Git non autorisée et une méthode de checkpoint acceptée.

**Commandes minimales :**

```bash
repo_root="$(git rev-parse --show-toplevel)"
git status --short --untracked-files=all
git diff --check
git diff --stat
git log --oneline -12

cd "$repo_root/packages/map_core"
dart test
dart analyze

cd "$repo_root/packages/map_gameplay"
dart test
dart analyze

cd "$repo_root/packages/map_battle"
dart test
dart analyze

cd "$repo_root/packages/map_runtime"
flutter test --no-pub
flutter analyze --no-pub

cd "$repo_root/packages/map_editor"
flutter test --no-pub
flutter analyze --no-pub
flutter build macos --debug --no-pub

cd "$repo_root/examples/playable_runtime_host"
flutter test --no-pub
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

### G0 — Vérifier les préconditions Map Editor du bridge

**Résultat :** le Map Editor produit les intents, sources et journaux nécessaires
au bridge V2 ; la route Event V2 complète sera prouvée en H1.

**Hors lot :** montage de `EventBuilderV2Workspace`, liste projet V2 et preuve
visuelle Event V2 ↔ Map Editor.

**Fichiers principaux :**

- `packages/map_editor/lib/src/features/narrative/state/narrative_event_map_bridge_state.dart` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart` ;
- `packages/map_editor/lib/src/ui/panels/narrative_event_map_bridge_panel.dart` ;
- `packages/map_editor/lib/src/ui/canvas/events/narrative_event_map_return_panel.dart` ;
- Evidence Pack G et captures sous
  `reports/narrativeStudio/events/phase_g_visual_evidence/`.

**Checklist :**

- [ ] rejouer la matrice G `410/410`, l’analyse ciblée et le build ;
- [ ] prouver dans les surfaces Map Editor une `MapEntity` existante → intent
      Event, un `MapTrigger` existant → intent Event et map → `mapEnter` ;
- [ ] capturer création PNJ/objet/zone → source canonique et journal de liaison ;
- [ ] prouver annulation avant write et interruption → retry/cleanup, y compris
      les gates dirty/saving ;
- [ ] comparer les hashes map/manifest/journal avant et après chaque flow ;
- [ ] mettre à jour l’Evidence Pack G après revue indépendante et maintenir la
      Phase G en `VERIFYING` jusqu’à la preuve produit H1.

**DONE si :** matrice ciblée verte, zéro régression G, tous les flows nommés
ci-dessus prouvés, recovery sûre et aucun blocker de revue.

**Commande de régression canonique :**

```bash
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/packages/map_editor"
flutter test --no-pub --reporter=compact --concurrency=1 \
  test/narrative_event_map_creation_bridge_test.dart \
  test/narrative_event_source_dependency_guard_test.dart \
  test/ui/panels/narrative_event_map_bridge_panel_test.dart \
  test/event_builder_draft_creation_notifier_test.dart \
  test/event_builder_workspace_test.dart \
  test/event_map_navigation_controller_test.dart \
  test/map_focus_viewport_resolver_test.dart \
  test/event_builder_map_focus_return_flow_test.dart \
  test/map_canvas_narrative_event_focus_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/editor_workspace_controller_test.dart \
  test/editor_project_session_controller_test.dart \
  test/narrative_event_spatial_link_journal_repository_test.dart \
  test/narrative_event_explicit_source_creation_test.dart \
  test/narrative_event_source_creation_recovery_test.dart \
  test/narrative_event_spatial_source_link_use_case_test.dart \
  test/ui/canvas/narrative_event_map_banner_test.dart \
  test/map_canvas_entity_properties_smoke_test.dart \
  test/event_registry_recovery_test.dart \
  test/event_registry_recovery_gate_test.dart \
  test/event_registry_repository_test.dart

phase_g_files=(
  lib/src/application/models/narrative_event_map_bridge_models.dart
  lib/src/application/models/narrative_event_spatial_link_journal_models.dart
  lib/src/application/models/narrative_event_spatial_source_creation_models.dart
  lib/src/application/ports/narrative_event_spatial_source_creation_gateway.dart
  lib/src/application/services/map_focus_viewport_resolver.dart
  lib/src/application/services/narrative_event_source_dependency_guard.dart
  lib/src/application/use_cases/create_narrative_event_from_map_source_use_case.dart
  lib/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart
  lib/src/application/use_cases/narrative_event_spatial_source_link_use_case.dart
  lib/src/features/narrative/state/narrative_event_map_bridge_state.dart
  lib/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart
  lib/src/ui/canvas/events/narrative_event_map_return_panel.dart
  lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart
  lib/src/ui/panels/narrative_event_map_bridge_panel.dart
  lib/src/app/providers/core/repository_providers.dart
  lib/src/features/editor/state/editor_notifier.dart
  lib/src/ui/canvas/narrative_workspace_canvas.dart
  lib/src/ui/canvas/map_canvas.dart
  lib/src/ui/canvas/map_canvas/map_grid_painter.dart
  lib/src/ui/panels/map_inspector_panel.dart
  test/narrative_event_map_creation_bridge_test.dart
  test/narrative_event_source_dependency_guard_test.dart
  test/ui/panels/narrative_event_map_bridge_panel_test.dart
  test/event_map_navigation_controller_test.dart
  test/map_focus_viewport_resolver_test.dart
  test/event_builder_map_focus_return_flow_test.dart
  test/map_canvas_narrative_event_focus_test.dart
  test/narrative_event_spatial_link_journal_repository_test.dart
  test/narrative_event_explicit_source_creation_test.dart
  test/narrative_event_source_creation_recovery_test.dart
  test/narrative_event_spatial_source_link_use_case_test.dart
  test/ui/canvas/narrative_event_map_banner_test.dart
)
flutter analyze --no-pub "${phase_g_files[@]}"
dart format --output=none --set-exit-if-changed "${phase_g_files[@]}"
flutter build macos --debug --no-pub
```

### V0 — Figer le contrat visuel avant l’intégration UI

**Résultat :** H est construit contre une cible mesurée, versionnée et
fonctionnellement honnête, pas contre une impression générale de la référence.

**Hors lot :** aucun polish de production et aucune modification des contrats
Event/Scene.

**Fichiers :**

- copier la référence fournie vers
  `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png` ;
- retrouver sa provenance dans
  `reports/narrativeStudio/events/ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md`
  sans recopier de chemin machine dans cette roadmap ;
- créer
  `reports/narrativeStudio/events/ns_event_v2_v0_visual_contract.md` ;
- créer
  `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`.

**Périmètre visuel :** la fenêtre applicative complète 1672 × 941 : topbar,
navigation gauche, breadcrumb/toolbar, liste projet, bibliothèque, éditeur et
inspecteur. Les éléments métier incompatibles avec `Event ≠ Scene` gardent la
hiérarchie visuelle de la référence mais utilisent l’interaction honnête définie
en H4.

**Checklist :**

- [ ] vérifier dimensions et SHA-256 canonique
      `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885` ;
- [ ] automatiser le hash, les dimensions et l’existence de l’état de fixture
      dans le test de contrat ;
- [ ] mesurer les huit zones, leur ordre, leurs largeurs/hauteurs et les
      espacements structurants ;
- [ ] figer projet, Event sélectionné, contenu, viewport, text scale et police ;
- [ ] définir avant H des tolérances numériques et les sévérités P0/P1/P2 ;
- [ ] faire approuver par l’utilisateur les divergences métier et consigner
      toute exception P2 dans ce contrat.

**DONE si :** référence versionnée, hash exact, état de capture reproductible,
mesures/tolérances numériques présentes et aucun choix visuel structurel laissé
à H.

```bash
cd packages/map_editor
flutter test --no-pub test/ui/canvas/event_builder_v2_reference_contract_test.dart
flutter analyze --no-pub test/ui/canvas/event_builder_v2_reference_contract_test.dart
```

### H1 — Monter V2 sur la route produit

**Résultat :** le menu Événements ouvre le vrai workspace V2 en `dualRead` et
`v2Only`, tandis que `legacyOnly` conserve V1 ; le round-trip visuel Event V2 ↔
Map Editor devient enfin prouvable.

**Hors lot :** authoring détaillé, migration et polish pixel-perfect.

**Fichiers :**

- modifier
  `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` ;
- modifier `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` ;
- modifier `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
  et `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` ;
- réutiliser
  `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart`
  et
  `packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart` ;
- créer seulement si le câblage l’exige un provider mince
  `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart` ;
- créer
  `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`.

**Checklist :**

- [ ] écrire le test de route pour les trois modes ;
- [ ] brancher V2 sur le read model du projet réel, pas sur le harness ;
- [ ] interdire tout CTA/write legacy en `v2Only` ;
- [ ] conserver V1 fonctionnelle en `legacyOnly` ;
- [ ] capturer et tester sur la route produit Event V2 → focus source → retour
      exact ;
- [ ] capturer et tester source manquante → Map Editor → création → retour au
      même draft ;
- [ ] mettre à jour l’Evidence Pack G et prononcer sa clôture formelle.

**DONE si :** le test prouve `legacyOnly → V1`, `dualRead/v2Only → V2`, et
aucune instanciation de production V2 ne dépend du harness ; les deux
round-trips sont prouvés et la Phase G est formellement clôturée.

### H2 — Brancher la liste projet et le contexte map

**Résultat :** l’utilisateur voit tous les Events du projet, regroupés par map
ou sous Global, avec recherche et filtres réels.

**Hors lot :** mutation du registre et création d’une source physique.

**Fichiers :**

- modifier
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart`
  et
  `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_state.dart` ;
- réutiliser d’abord
  `packages/map_editor/lib/src/application/models/narrative_event_authoring_session.dart`
  et ne le modifier que si l’audit prouve une donnée manquante ;
- créer
  `packages/map_editor/test/ui/canvas/event_builder_v2_project_list_test.dart`.

**Checklist :**

- [ ] alimenter maps, groupe Global, compteurs et sélection depuis le read model ;
- [ ] préserver la sélection lors d’une recherche ou d’un rafraîchissement ;
- [ ] distinguer actif, brouillon, inactif, legacy et source manquante ;
- [ ] vérifier que la map affichée est dérivée de la source.

**DONE si :** aucune dépendance à la map active, aucun picker map indépendant
et les états liste sont testés avec des données projet réelles.

### H3 — Créer, lier, sauvegarder et rouvrir

**Résultat :** un Event peut être créé source-first, persisté sur disque, fermé
et rouvert sans perte.

**Hors lot :** nouveau moteur de registry, géométrie map et édition des
conséquences de Scene.

**Fichiers proposés :**

- auditer et composer les use cases Phase E/G existants ainsi que
  `packages/map_editor/lib/src/application/use_cases/narrative_event_registry_persistence_use_cases.dart` ;
- créer
  `packages/map_editor/lib/src/application/use_cases/narrative_event_builder_v2_use_case.dart`
  uniquement comme coordinateur mince si le gap audit prouve un manque ;
- créer
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_creation_sheet.dart` ;
- modifier `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
  et `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` ;
- créer `packages/map_editor/test/narrative_event_builder_v2_use_case_test.dart` ;
- créer
  `packages/map_editor/test/ui/canvas/event_builder_v2_creation_flow_test.dart`.

**Checklist :**

- [ ] réutiliser les opérations Phase E/G et la persistance journalée ;
- [ ] respecter la matrice de références ci-dessous ;
- [ ] reprendre le même draft après création d’une source dans le Map Editor ;
- [ ] couvrir save, close, reopen, cancel et conflit de révision ;
- [ ] ne créer aucun second moteur de registry ou de map write.

**DONE si :** le round-trip disque est sémantiquement identique, le conflit ne
perd pas le draft et aucune géométrie n’est éditée depuis l’Event Builder.

| Source | Référence atomique | Aller-retour Map Editor |
|---|---|---|
| `entityInteract` / `triggerEnter` | `kind + mapId + sourceId` | Oui si la source manque |
| `mapEnter` | `kind + mapId` | Choix de la map comme source, sans champ map séparé |
| `outcomeReceived` | `producerKind + producerId + outcomeId` | Non ; aucun CTA map |

### H4 — Fermer l’éditeur central et l’inspecteur

**Résultat :** les champs appartenant à l’Event sont éditables ; les données
Scene-owned sont honnêtement projetées ou ouvrent la Scene.

**Hors lot :** édition inline des actions, branches, outcomes, réactions ou
changements monde appartenant à la Scene.

**Fichiers :**

- modifier
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_editor.dart`,
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart`,
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_element_library.dart`
  et, pour le câblage seulement,
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart` ;
- compléter
  `packages/map_editor/test/ui/canvas/event_builder_v2_workspace_test.dart`,
  `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart`
  et le test du use case H3.

**Checklist :**

- [ ] éditer source, conditions, Scene cible, `reusePolicy`, priorité et
      activation du record en réutilisant les guards core ;
- [ ] garder draft, missing, conflict et attention comme statuts dérivés ;
- [ ] rendre la map dérivée non éditable ;
- [ ] afficher actions, outcomes, réactions et monde en lecture seule avec
      action explicite vers la Scene ;
- [ ] supprimer toute affordance de drag/drop non fonctionnelle ;
- [ ] prouver save/reopen pour chaque champ Event-owned.

**DONE si :** aucune donnée Scene-owned n’est mutée par erreur et chaque
contrôle visible a une interaction réelle testée.

| Zone de la référence | Owner | Interaction autorisée |
|---|---|---|
| Déclencheur / source | Event | Sélection atomique et action `Voir sur la map` |
| Conditions | Event | Ajout, édition, suppression et ordre |
| Scene cible | Event | Picker guidé et action `Ouvrir la Scene` |
| Actions / résultats / réactions / monde | Scene | Projection read-only ou navigation explicite vers la section Scene |
| Comportement / priorité / activation | Event record | Édition avec validation |
| Items Scene-owned de la bibliothèque | Scene | Aucun drag ; action libellée `Configurer dans la Scene` |

### H5 — Fermer les états secondaires et l’accessibilité

**Résultat :** le workspace reste utilisable dans les états vide, chargement,
sauvegarde, erreur, source manquante, conflit, legacy et recovery.

**Hors lot :** pixel closure finale et migration de corpus legacy.

**Fichiers :**

- modifier
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`,
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart`
  et les primitives du design system seulement si un variant manque ;
- créer
  `packages/map_editor/test/ui/canvas/event_builder_v2_accessibility_test.dart`.

**Checklist :**

- [ ] couvrir les huit états nommés avec CTA de récupération ;
- [ ] couvrir Tab, Shift+Tab, Enter, Espace, Escape et retour du focus ;
- [ ] couvrir text scale 125 % et largeur 1280 sans overflow ;
- [ ] conserver une copie produit compréhensible, sans ID brut obligatoire.

**DONE si :** tous les états sont testés, navigables au clavier et sans contrôle
mort.

**Commande H, à exécuter après création des tests annoncés :**

```bash
cd packages/map_editor
flutter test --no-pub \
  test/narrative_event_builder_v2_use_case_test.dart \
  test/narrative_event_builder_v2_state_test.dart \
  test/narrative_event_builder_v2_session_snapshot_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_project_list_test.dart \
  test/ui/canvas/event_builder_v2_creation_flow_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/event_builder_workspace_test.dart \
  test/event_builder_map_focus_return_flow_test.dart
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

### I1 — Construire le rapport d’intégrité V2

**Résultat :** chaque Event reçoit des diagnostics stables pour registry,
source, claim, référence et Scene.

**Hors lot :** conflit d’exécution, UX de migration et second système de
validation parallèle.

**Fichiers :**

- auditer puis composer/étendre
  `packages/map_core/lib/src/authoring/narrative_event_authoring_verification.dart`,
  `packages/map_core/lib/src/authoring/narrative_event_configuration_validation.dart`,
  `packages/map_core/lib/src/authoring/narrative_validator_authoring_adapter.dart`,
  `packages/map_core/lib/src/catalogs/narrative_event_project_catalog.dart`,
  `packages/map_core/lib/src/operations/build_narrative_event_project_catalog.dart`
  et `packages/map_core/lib/src/operations/narrative_validator.dart` ;
- créer `narrative_event_validation_read_model.dart` ou
  `build_narrative_event_validation_report.dart` seulement si le gap audit
  démontre une responsabilité absente ;
- créer
  `packages/map_core/test/narrative_event_v2_integrity_validation_test.dart` et
  exporter uniquement l’API publique réellement nécessaire.

**Checklist :**

- [ ] définir code stable, sévérité, chemin, message, action et destination ;
- [ ] couvrir source absente, type incohérent, Scene absente et claim invalide ;
- [ ] réutiliser les codes, catalogues et read models V2 existants sans copie ;
- [ ] ne pas cacher V2 dans le validator Scenario historique.

**DONE si :** les snapshots de diagnostics sont déterministes et ne dépendent
pas de l’ordre des fichiers.

### I2 — Valider conflits et atteignabilité

**Résultat :** l’outil explique quel Event peut réellement gagner pour chaque
source et pourquoi les autres sont structurellement inéligibles.

**Hors lot :** prédire une condition runtime dont la valeur n’est pas connue au
moment de l’authoring.

**Fichiers proposés :**

- auditer puis étendre l’index et l’autorité existants ; créer
  `packages/map_core/lib/src/operations/build_narrative_event_reachability_report.dart`
  seulement si aucun résultat composable n’expose le rapport nécessaire ;
- créer
  `packages/map_core/test/narrative_event_reachability_report_test.dart`.

**Checklist :**

- [ ] composer
      `packages/map_core/lib/src/read_models/narrative_event_source_index.dart`
      et
      `packages/map_core/lib/src/operations/narrative_event_dispatch_authority.dart` ;
- [ ] couvrir priorité, ordre, tie-break, one-shot consommé et claim V2 ;
- [ ] classer une information runtime inconnue en warning, pas en faux error ;
- [ ] produire une destination de correction pour chaque conflit actionnable.

**DONE si :** mêmes entrées → même ordre structurel, mêmes candidats actuellement
éligibles et mêmes causes d’inéligibilité ; toute valeur runtime inconnue reste
un warning explicite.

### I3 — Relier les diagnostics à l’UI exacte

**Résultat :** cliquer un diagnostic sélectionne l’Event, le panneau et la
source ou Scene concernés.

**Hors lot :** recalcul du diagnostic core dans les widgets.

**Fichiers proposés :**

- créer
  `packages/map_editor/lib/src/features/narrative/state/narrative_event_validation_state.dart` ;
- créer
  `packages/map_editor/lib/src/application/services/narrative_event_validation_coordinator.dart` ;
- modifier
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`
  et
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_inspector.dart` ;
- créer `packages/map_editor/test/narrative_event_validation_coordinator_test.dart`.

**Checklist :**

- [ ] afficher les diagnostics sans dupliquer la logique core ;
- [ ] implémenter le click-through Event, Map Editor et Scene Editor ;
- [ ] conserver le draft et le focus lors de l’aller-retour ;
- [ ] tester les destinations manquantes et devenues obsolètes.

**DONE si :** chaque diagnostic actionnable ouvre la destination exacte et une
destination invalide reste explicite sans crash.

### I4 — Fermer migration UX, disque et recovery

**Résultat :** un projet legacy peut être prévisualisé, migré sur disque,
rechargé puis compensé en sécurité lorsque les préconditions sont intactes.

**Hors lot :** budget performance, cache incrémental et downgrade forcé d’une
donnée V2-only non représentable.

**Fichiers proposés :**

- créer
  `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart` ;
- créer
  `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart` ;
- créer les tests correspondants sous `packages/map_editor/test/`.

**Checklist :**

- [ ] réutiliser le planner, les receipts et la persistance existants ;
- [ ] couvrir preview, cancel sans write, commit et crash recovery ;
- [ ] couvrir la compensation revision-gated : restaurer seulement si révision,
      hashes, receipt, ownership et fingerprint correspondent encore ;
- [ ] bloquer sans réécriture et conserver le journal si une précondition diverge.

**DONE si :** annulation byte-identique, migration/reload reproductibles,
compensation exacte quand elle est sûre et blocage non destructif sinon.

### I5 — Fermer validation incrémentale et performance

**Résultat :** les changements Event invalident uniquement les diagnostics
nécessaires et respectent un budget numérique ratifié.

**Hors lot :** modifier les seuils après observation du résultat final ou
masquer un cache stale par un refresh global.

**Fichiers proposés :**

- créer
  `packages/map_editor/test/narrative_event_validation_incremental_performance_test.dart` ;
- compléter
  `packages/map_editor/test/narrative_event_authoring_snapshot_performance_test.dart` ;
- publier corpus, machine, warmup, itérations, baseline et seuils dans l’Evidence
  Pack Phase I avant le run de validation final.

**Checklist :**

- [ ] figer le corpus et le protocole machine/warmup/itérations ;
- [ ] mesurer une baseline p50/p95 sans gate ;
- [ ] faire ratifier les budgets numériques à partir de cette baseline ;
- [ ] lancer ensuite la validation finale avec les seuils immuables ;
- [ ] prouver invalidation ciblée, stabilité des résultats et absence de cache stale.

**DONE si :** budgets fixés avant le run final et respectés, cache cohérent et
résultats déterministes après chaque mutation couverte.

**Commandes I, à exécuter après création des tests annoncés :**

```bash
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/packages/map_core"
dart test \
  test/narrative_event_v2_integrity_validation_test.dart \
  test/narrative_event_reachability_report_test.dart
dart analyze

cd "$repo_root/packages/map_editor"
flutter test --no-pub \
  test/narrative_event_validation_coordinator_test.dart \
  test/narrative_event_migration_preview_use_case_test.dart \
  test/ui/canvas/event_builder_v2_migration_sheet_test.dart \
  test/narrative_event_validation_incremental_performance_test.dart \
  test/narrative_event_authoring_snapshot_performance_test.dart
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

### J1 — Authorer trois sources dans une copie contrôlée de Selbrume

**Résultat :** un PNJ Lysa, un trigger de zone et un objet indice possèdent
chacun un Event V2 créé depuis la vraie route produit.

**Hors lot :** mutation du projet Selbrume original, injection directe d’un
Event JSON et usage d’un `PlacedElement` comme source canonique.

**Fichiers proposés :**

- créer
  `packages/map_editor/test/support/selbrume_event_v2_fixture.dart` ;
- créer `packages/map_editor/test/selbrume_event_v2_authoring_slice_test.dart` ;
- cloner le projet Selbrume complet dans un dossier temporaire en excluant
  caches, locks et artefacts, puis faire valider sa fermeture de dépendances par
  le project loader.

**Checklist :**

- [ ] enregistrer les hashes initiaux du projet original et de la copie ;
- [ ] créer les vrais `MapEntity` manquants et les Scenes exécutables via les
      éditeurs produit disponibles ;
- [ ] réutiliser le trigger `zone_port_entry` existant ;
- [ ] créer les trois Events via V2, jamais par injection de JSON de test.

**DONE si :** les trois sources existent physiquement, les trois Events sont
valides sur disque et le projet original reste inchangé pendant la preuve.

| Rôle | Référence canonique | État initial / décision |
|---|---|---|
| PNJ Lysa | `entityInteract + map_port_brisants + npc_lysa` | Créer un `MapEntity` à `(22,21)` ; `anchor_port_lysa` reste une ancre inerte, pas la source |
| Zone du port | `triggerEnter + map_port_brisants + zone_port_entry` | Réutiliser le `MapTrigger custom` existant |
| Objet indice | `entityInteract + map_marais_salants + clue_glass_object` | Créer un `MapEntity` à `(8,32)` ; `pe_marais_indice_verre` reste le visuel, pas la source |

Les IDs de contenu de la fixture sont figés : `scene_lysa_port`,
`scene_port_entry`, `scene_clue_glass`, `character_lysa` et
`trainer_lysa_port`. Leur création doit respecter les contrats existants ; si
un éditeur produit manque, le plan J doit isoler ce gap avant J1.

### J2 — Produire une fixture autonome et prouver la recovery

**Résultat :** la sortie UI de J1 se recharge à l’identique et devient une
fixture autonome, hashée et consommable par les autres packages.

**Hors lot :** promotion dans `selbrume/` et promesse d’atomicité multi-fichiers.

**Fichiers proposés :**

- créer
  `packages/map_editor/test/selbrume_event_v2_persistence_migration_test.dart` ;
- créer la fixture versionnée
  `examples/playable_runtime_host/event_builder_v2_selbrume_slice/` ;
- créer
  `examples/playable_runtime_host/event_builder_v2_selbrume_slice/promotion_manifest.json`
  à partir du diff sémantique ;
- réutiliser les repositories de registry, receipts, recovery et undo.

**Checklist :**

- [ ] comparer les modèles sémantiques avant fermeture et après réouverture ;
- [ ] provoquer un échec entre map et registry puis reprendre ;
- [ ] tester conflit de révision et compensation revision-gated ;
- [ ] restaurer la source uniquement si ownership et fingerprint sont inchangés,
      sinon bloquer sans write et conserver le journal ;
- [ ] publier les hashes, le diff JSON lisible et la fermeture de dépendances de
      la fixture versionnée ;
- [ ] lister dans le manifeste chaque source fixture, destination Selbrume,
      hash attendu et ordre de promotion.

**DONE si :** reopen identique, recovery sans double write, compensation sûre,
blocage non destructif en cas de divergence et fixture autonome reproductible.

### J3 — Déclencher les trois sources au runtime

**Résultat :** interaction PNJ, entrée dans la zone et interaction objet lancent
chacune la bonne Scene par les hooks production.

**Hors lot :** occurrence injectée artificiellement et données temporaires
provenant d’un test editor précédent.

**Fichiers proposés :**

- créer
  `packages/map_runtime/test/support/selbrume_event_v2_test_fixture.dart` ;
- créer
  `packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart`.

**Checklist :**

- [ ] charger exclusivement
      `examples/playable_runtime_host/event_builder_v2_selbrume_slice/` ;
- [ ] utiliser les bridges production, sans occurrence injectée ;
- [ ] couvrir succès, inéligibilité, réinteraction et one-shot ;
- [ ] vérifier dispatch, Scene cible et progression persistée.

**DONE si :** les trois traces runtime correspondent exactement aux trois
Events sur disque.

### J4 — Fermer le Golden Slice Lysa

**Résultat :** la fixture traverse Event → Scene → Yarn → Cinematic → Battle →
Outcome → Fact → Story Step → World Rule, puis survit au save/load.

**Hors lot :** promotion dans le projet Selbrume original.

**Fichiers proposés :**

- créer
  `examples/playable_runtime_host/event_builder_v2_selbrume_slice/dialogues/lysa_port.yarn` ;
- créer
  `examples/playable_runtime_host/test/selbrume_event_v2_lysa_golden_slice_test.dart`.

**Checklist :**

- [ ] couvrir les branches victoire, défaite et réinteraction ;
- [ ] vérifier outcome qualifié, fact, Story Step, règle monde et one-shot ;
- [ ] vérifier le handoff Cinematic et la reprise Battle ;
- [ ] sauvegarder, relancer le host et vérifier l’état narratif ;
- [ ] lancer les smokes runtime/host existants ;
- [ ] finaliser et faire relire le manifeste de promotion après ajout du Yarn et
      de toutes ses dépendances transitives.

**DONE si :** Golden Slice fixture verte sur le host, save/load vert, aucune
écriture legacy inattendue et manifeste de promotion figé avant J5.

### J5 — Promouvoir dans Selbrume et rejouer les preuves

**Résultat :** les données validées deviennent les données réelles de Selbrume,
puis sont revalidées sur leurs nouveaux octets.

**Hors lot :** suppression des readers/importeurs V1 et contenu narratif sans
rapport avec Lysa.

**Fichiers minimum attendus :**

- modifier `selbrume/project.json` ;
- modifier `selbrume/maps/map_port_brisants.json` ;
- modifier `selbrume/maps/map_marais_salants.json` ;
- créer `selbrume/dialogues/lysa_port.yarn` ;
- créer
  `packages/map_editor/test/selbrume_event_v2_promotion_recovery_test.dart` ;
- créer
  `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart`.

**Checklist :**

- [ ] comparer sémantiquement la fixture validée et les données à promouvoir ;
- [ ] accepter avant toute écriture le manifeste final de J4 ; les quatre
      surfaces ci-dessus sont le minimum attendu et J5 ne modifie que les
      destinations présentes dans ce manifeste ;
- [ ] bloquer le lot si une destination supplémentaire apparaît après le début,
      puis mettre à jour et refaire approuver le périmètre avant reprise ;
- [ ] capturer révisions et hashes initiaux de chaque destination ;
- [ ] créer, hasher et restaurer en test un checkpoint autonome pré-promotion ;
- [ ] écrire avant mutation un journal de promotion avec ordre et état de chaque
      surface, puis utiliser temp + rename atomique par fichier ;
- [ ] injecter une panne après chaque frontière d’écriture et prouver reprise
      idempotente ou compensation seulement si révision, hash, receipt et
      ownership correspondent ; sinon ne rien réécrire et conserver le journal ;
- [ ] recalculer les hashes après promotion ;
- [ ] rejouer authoring, reload/recovery, trois sources runtime, Golden Slice et
      save/load sur les octets promus.

**DONE si :** le projet Selbrume réel charge, joue la Golden Slice et reproduit
les invariants J1–J4 sans preuve héritée des anciens octets ; aucun état
partiellement promu n’est observable après panne et reprise.

**Commandes J, à exécuter après création des tests annoncés :**

```bash
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/packages/map_editor"
flutter test --no-pub \
  test/selbrume_event_v2_authoring_slice_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart \
  test/selbrume_event_v2_promotion_recovery_test.dart
flutter analyze --no-pub \
  test/support/selbrume_event_v2_fixture.dart \
  test/selbrume_event_v2_authoring_slice_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart \
  test/selbrume_event_v2_promotion_recovery_test.dart
flutter build macos --debug --no-pub

cd "$repo_root/packages/map_runtime"
flutter test --no-pub \
  test/selbrume_event_v2_three_source_integration_test.dart \
  test/p6_selbrume_playable_runtime_smoke_test.dart \
  test/p6_selbrume_save_load_golden_slice_test.dart
flutter analyze --no-pub \
  test/support/selbrume_event_v2_test_fixture.dart \
  test/selbrume_event_v2_three_source_integration_test.dart

cd "$repo_root/examples/playable_runtime_host"
flutter test --no-pub \
  test/selbrume_event_v2_lysa_golden_slice_test.dart \
  test/selbrume_event_v2_promoted_project_test.dart \
  test/p3_narrative_smoke_slice_test.dart \
  test/runtime_launch_save_test.dart
flutter analyze --no-pub \
  test/selbrume_event_v2_lysa_golden_slice_test.dart \
  test/selbrume_event_v2_promoted_project_test.dart
flutter build macos --debug --no-pub
```

### K1 — Mesurer l’écart de la route produit

**Résultat :** la route produit promue est capturée dans l’état V0 exact et tous
ses écarts sont classés avant la première correction K.

**Hors lot :** correction visuelle et changement du contrat V0 après lecture du
résultat.

**Fichiers proposés :**

- créer
  `reports/narrativeStudio/events/ns_event_v2_k1_product_visual_gap.md` ;
- réutiliser la référence et les tolérances versionnées par V0.

**Checklist :**

- [ ] ouvrir le projet Selbrume promu et sélectionner l’Event V0 figé ;
- [ ] capturer la fenêtre produit complète à 1672 × 941 ;
- [ ] produire côte-à-côte, overlay et crops des huit zones ;
- [ ] classer chaque écart selon les définitions P0/P1/P2 déjà ratifiées ;
- [ ] vérifier que le harness reproduit directement le workspace produit.

**DONE si :** capture reproductible, inventaire exhaustif et aucune correction
commencée avant le classement.

### K2 — Aligner la vraie route produit

**Résultat :** la composition, la densité et la hiérarchie de la route produit
correspondent à la référence sans mentir sur le métier.

**Hors lot :** nouveau comportement Event/Scene et affordance décorative.

**Fichiers :**

- modifier les widgets sous
  `packages/map_editor/lib/src/ui/canvas/events_v2/`,
  `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` et le
  chrome global réellement visible dans le contrat V0 ;
- étendre une primitive du design system avant toute solution locale ;
- ajouter une couleur uniquement via les tokens sémantiques du thème.

**Checklist :**

- [ ] capturer la route produit 1672 × 941, pas un shell parallèle ;
- [ ] produire côte-à-côte et overlay 50 % ;
- [ ] corriger grille, tailles, spacing, typographie, densité et inspecteur ;
- [ ] vérifier que chaque action visible fonctionne réellement ;
- [ ] faire une revue visuelle indépendante zone par zone.

**DONE si :** zéro P0/P1 et chaque P2 est corrigé ou explicitement approuvé par
l’utilisateur dans l’Evidence Pack K.

### K3 — Fermer responsive, états et accessibilité

**Résultat :** la même route reste lisible et fonctionnelle sur toute la matrice
desktop et dans les états dégradés.

**Hors lot :** nouvelle fonctionnalité, nouveau breakpoint sans preuve et fork
de layout réservé aux tests.

**Fichiers :**

- compléter
  `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_visual_test.dart`,
  `packages/map_editor/test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart`,
  `packages/map_editor/test/ui/canvas/event_builder_v2_workspace_test.dart`,
  `packages/map_editor/test/ui/canvas/event_builder_v2_flow_fidelity_test.dart`,
  `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`
  et
  `packages/map_editor/test/ui/canvas/event_builder_v2_accessibility_test.dart` ;
- le harness instancie directement le workspace de production avec une fixture
  contrôlée ; aucun fork de widget ou de layout n’est conservé.

**Checklist :**

- [ ] tester 1280, 1440, 1480, 1672 et 1920 × 941 ;
- [ ] tester text scale 125 %, clavier, focus et side sheet ;
- [ ] capturer populated, empty, missing, conflict, legacy et recovery ;
- [ ] vérifier zéro overflow et continuité de scroll/sélection.

**DONE si :** matrice verte, captures inspectées et zéro P0/P1/P2 non approuvé.

**Commande K :**

```bash
cd packages/map_editor
flutter test --no-pub --concurrency=1 \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart \
  test/ui/canvas/event_builder_v2_phase_k_responsive_test.dart \
  test/ui/canvas/event_builder_v2_workspace_test.dart \
  test/ui/canvas/event_builder_v2_flow_fidelity_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_accessibility_test.dart
flutter test --no-pub \
  --dart-define=NS_EVENT_V2_PHASE_K_CAPTURE=true \
  test/ui/canvas/event_builder_v2_phase_k_visual_test.dart
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

### L1 — Fermer corpus, migration et performance

**Résultat :** les corpus legacy/V2 réels migrent et se compensent dans les
budgets ratifiés, avec blocage non destructif si l’état a divergé.

**Hors lot :** correction d’un défaut découvert, baisse opportuniste des
budgets et rollback forcé.

**Fichiers :**

- core : `narrative_event_legacy_corpus_test.dart`,
  `narrative_event_migration_planner_test.dart`,
  `narrative_event_migration_integrity_closure_test.dart`,
  `narrative_event_migration_receipt_test.dart`,
  `narrative_event_migration_receipt_codec_test.dart`,
  `narrative_event_dispatch_authority_test.dart`,
  `validated_legacy_claim_index_runtime_readiness_test.dart` et
  `narrative_event_authoring_performance_test.dart` ;
- gameplay : `narrative_event_dispatch_truth_table_test.dart`,
  `narrative_event_execution_coordinator_test.dart` et
  `narrative_event_runtime_performance_test.dart` ;
- runtime : `narrative_event_legacy_runtime_characterization_test.dart`,
  `playable_map_game_event_v2_boot_integration_test.dart` et
  `narrative_event_runtime_snapshot_test.dart` ;
- editor : `event_registry_repository_test.dart`,
  `event_registry_recovery_test.dart`, `event_registry_recovery_gate_test.dart`,
  `event_registry_undo_test.dart`,
  `event_registry_persistence_performance_test.dart` et
  `narrative_event_authoring_snapshot_performance_test.dart` ;
- créer
  `reports/narrativeStudio/events/ns_event_v2_l1_corpus_migration_performance.md`
  et un test/readiness harness focalisé seulement si l’inventaire prouve un
  garde non couvert.

**Checklist :**

- [ ] exécuter les corpus legacy, dual-read et V2-only ;
- [ ] appliquer une migration disque réelle puis une compensation
      revision/hash/receipt-gated ;
- [ ] mesurer p50/p95 sur le corpus ratifié ;
- [ ] prouver no-fallback legacy sous claim V2 ;
- [ ] vérifier le garde central de tous les writes legacy en `v2Only`.

**DONE si :** budgets respectés, aucun cache stale, migration/reload
reproductibles, compensation sûre ou blocage non destructif, et zéro write
legacy non autorisé.

**Matrice L1 :**

```bash
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/packages/map_core"
dart test \
  test/narrative_event_legacy_corpus_test.dart \
  test/narrative_event_migration_planner_test.dart \
  test/narrative_event_migration_integrity_closure_test.dart \
  test/narrative_event_migration_receipt_test.dart \
  test/narrative_event_migration_receipt_codec_test.dart \
  test/narrative_event_dispatch_authority_test.dart \
  test/validated_legacy_claim_index_runtime_readiness_test.dart \
  test/narrative_event_authoring_performance_test.dart
dart analyze

cd "$repo_root/packages/map_gameplay"
dart test \
  test/narrative_event_dispatch_truth_table_test.dart \
  test/narrative_event_execution_coordinator_test.dart \
  test/narrative_event_runtime_performance_test.dart
dart analyze

cd "$repo_root/packages/map_runtime"
flutter test --no-pub \
  test/narrative_event_legacy_runtime_characterization_test.dart \
  test/playable_map_game_event_v2_boot_integration_test.dart \
  test/narrative_event_runtime_snapshot_test.dart
flutter analyze --no-pub

cd "$repo_root/packages/map_editor"
flutter test --no-pub \
  test/event_registry_repository_test.dart \
  test/event_registry_recovery_test.dart \
  test/event_registry_recovery_gate_test.dart \
  test/event_registry_undo_test.dart \
  test/event_registry_persistence_performance_test.dart \
  test/narrative_event_authoring_snapshot_performance_test.dart
flutter analyze --no-pub
flutter build macos --debug --no-pub
```

`map_core` et `map_gameplay` sont des packages Dart purs : tests + analyse sont
leur validation de build. `map_runtime` est un package Flutter sans cible app
autonome ; son intégration buildable est le host, validé en J4/J5 puis L2.

### L2 — Produire la Release Candidate verte

**Résultat :** toutes les suites, analyses, smokes et builds exigés sortent avec
un code zéro sur les mêmes octets.

**Hors lot :** toute correction de code, mise à jour de golden ou exclusion de
test découverte pendant la campagne.

**Checklist :**

- [ ] lancer la matrice complète ci-dessous ;
- [ ] vérifier l’absence d’artefacts, locks et diffs inattendus ;
- [ ] ne corriger aucun défaut dans L2 : créer un lot correctif borné, le fermer,
      puis relancer L2 depuis le début ;
- [ ] faire une revue release indépendante.

**Résultat terminal :** `DONE` si chaque commande sort `0`; `BLOCKED` si une
commande reste rouge après attribution. Dans les deux cas, aucune commande n’est
ignorée, l’état Git final est expliqué et L3 peut publier la décision.

**Matrice Release Candidate :**

```bash
repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root/packages/map_core"
dart test
dart analyze

cd "$repo_root/packages/map_gameplay"
dart test
dart analyze

cd "$repo_root/packages/map_battle"
dart test
dart analyze

cd "$repo_root/packages/map_runtime"
flutter test --no-pub
flutter analyze --no-pub
flutter test test/phase_a_golden_battle_slice_smoke_test.dart

cd "$repo_root/packages/map_editor"
flutter test --no-pub
flutter analyze --no-pub
flutter build macos --debug --no-pub

cd "$repo_root/examples/playable_runtime_host"
flutter test --no-pub
flutter analyze --no-pub
flutter test test/phase_a_golden_slice_launch_test.dart
flutter build macos --debug --no-pub
```

### L3 — Décider GO/NO-GO et le futur de V1

**Résultat :** la décision de sortie, le mode par défaut, le rollback et la
durée de support V1 sont écrits sans ambiguïté.

**Hors lot :** suppression de reader/importeur legacy, correction d’un blocker
L2 et activation de `v2Only` après un NO-GO.

**Checklist :**

- [ ] confirmer que S0 à L1 sont `DONE` et que L2 possède un résultat terminal
      frais `DONE` ou `BLOCKED` ;
- [ ] publier `GO` seulement si L2 est `DONE` et le nombre de blockers vaut zéro ;
- [ ] publier `NO-GO` si L2 est `BLOCKED`, en listant chaque blocker, owner et
      condition de reprise ;
- [ ] choisir explicitement le mode par défaut compatible avec le verdict ;
- [ ] documenter support V1, calendrier de dépréciation et retour arrière ;
- [ ] publier l’Evidence Pack final et le verdict GO/NO-GO ;
- [ ] ne supprimer aucun reader/importeur legacy dans ce lot.

**DONE si :** la décision GO ou NO-GO est publiée avec ses preuves. En cas de
NO-GO, la Gate release reste NO-GO et les blockers restent ouverts ; le lot de
décision, lui, est terminé. Toute stratégie de retour respecte les préconditions
révision/hash/receipt et ne promet aucun downgrade V2-only impossible.

## 8. Plans détaillés à réutiliser ou créer

| Phase | Plan | État |
|---|---|---|
| G | `docs/superpowers/plans/2026-07-15-event-builder-phase-g-map-bridge.md` | Existant, à relire contre G0 |
| H | `docs/superpowers/plans/2026-07-16-event-builder-phase-h-v2-ui.md` | Existant, à découper H1–H5 |
| I | `docs/superpowers/plans/2026-07-16-event-builder-phase-i-validator-migration.md` | À créer et revoir avant I1 |
| J | `docs/superpowers/plans/2026-07-16-event-builder-phase-j-selbrume-golden-slice.md` | À créer et revoir avant J1 |
| K | `docs/superpowers/plans/2026-07-16-event-builder-phase-k-pixel-closure.md` | Existant, à relire contre V0/K1–K3 |
| L | `docs/superpowers/plans/2026-07-16-event-builder-phase-l-readiness.md` | Existant, à relire contre L1–L3 |

Ces plans sont des entrées techniques. Leur ordre ancien ne permet pas de
sauter H, I ou J et aucun plan ne surclasse les gates de ce document.

## 9. Rituel d’un lot

Chaque nouveau prompt d’exécution suit exactement ce cycle :

1. relire le dashboard, le lot, sa condition d’entrée et les `AGENTS.md`
   applicables ;
2. auditer contrats, implémentations, tests, rapports, risques et limites de
   scope avant de confirmer ou corriger les fichiers proposés ;
3. capturer Git initial et les preuves fraîches pertinentes ;
4. annoncer le lot, ses non-objectifs et le test qui prouvera le résultat ;
5. enregistrer les verdicts attendus des passes Audit / Architecture,
   Implémentation, Tests, Build / Validation et Critique finale ;
6. passer le lot à `IN PROGRESS` et implémenter avec un seul writer ;
7. passer à `VERIFYING`, lancer format, tests, analyses, build et vraie route ;
8. demander une revue indépendante et corriger les blockers ;
9. alimenter l’Evidence Pack vivant de la phase conformément à
   `codex_rule.md` ;
10. sécuriser les octets par commit autorisé ou archive autonome restaurée ;
11. passer à `DONE` et incrémenter `X / N courant` ;
12. si le lot ferme une phase, exécuter son gate groupé, incrémenter `X / 7`
    puis nommer un seul prochain lot.

Un lot interrompu conserve son statut et son blocker exact. Aucun agent ne
déduit `DONE` d’un résumé de conversation ou d’un ancien rapport.

## 10. Prochaine étape exécutable

Le prochain lot est **S0 — Stabilisation**. Il ne doit ajouter aucune feature :
il doit d’abord rendre les Phases F2/G/H/K/L présentes dans le worktree
attribuables, récupérables et vérifiables avant la reprise fonctionnelle. Son
préflight doit aussi faire choisir le type de checkpoint et résoudre
explicitement la règle de test pour ce lot documentaire.
