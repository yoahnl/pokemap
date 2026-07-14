# NS-EVENT-V2 — PHASE E — Source-First Authoring Operations, Publication Gates & Journaled Registry Persistence

## 1. Résumé exécutif

```text
PHASE E : CLOSED

E1 / V2-13 : PASS
E2 / V2-14 : PASS
E3 / V2-15 : PASS
E4 / V2-16 : PASS

Draft creation : PASS
Source authoring : PASS
Publication gate : PASS
Activation gate : PASS
Journaled write : PASS
Recovery : PASS
Undo : PASS

Real project modified : NO
Legacy data modified : NO
Runtime V2 added : NO
UI V2 added : NO

Phase F1 : READY
```

La Phase E fournit une API d'authoring Event V2 pure dans `map_core`, puis un
pipeline de persistance ciblé dans `map_editor`. La création n'exige ni map, ni
layer, ni position. La publication produit toujours un Event configuré et
désactivé. L'activation reste explicite et revalide source, Scene, conditions et
conflits. Le writer modifie uniquement `eventRegistry` dans le manifest,
préserve le mode, les claims et les champs JSON inconnus, puis produit journal,
backup et entrée d'undo vérifiables.

Les validations du lot sont vertes. La suite `map_editor` complète reste rouge
sur 137 résultats non verts indépendants du lot (`6 failure`, `131 error`) et
sur une dette d'analyse historique; ces écarts sont détaillés sans les attribuer
à Phase E.

## 2. Baseline Phase D

- Baseline canonique: `e932d9a26bc942711f01b8c0cfe077cd50438d29`.
- Commit initial Phase D: `025bf9bc3bbc521cc2187d43fde4ad1d78a75f2f`.
- Phase D complète: les deux commits ci-dessus.
- Contrats consommés sans redéfinition: registry, records, sources, claims,
  catalogs, source index, read models et codecs stricts.
- ADR et ledger: inchangés.

## 3. Usage MCP Dart

Le MCP Dart n'était pas disponible dans cette session. Aucun usage fictif n'est
revendiqué. Le fallback a utilisé `rg`, `sed`, les tests Dart/Flutter, les
analyses ciblées, `build_runner` et le build macOS.

## 4. Sous-agents et incidents

| Passe | Mission | Verdict |
|---|---|---|
| A | Draft et identité | PASS |
| B | Source authoring | PASS |
| C | Conditions et graphe | PASS |
| D | Scene, comportement, publication | PASS |
| E | Activation et conflits | PASS |
| F | Persistance et JSON strict | PASS après corrections |
| G | Journal, recovery et undo | PASS après corrections |
| H | Tests et compatibilité | PASS avec dette globale documentée |
| R1 | Architecture / intégrité | PASS final |
| R2 | Produit / vérité authoring | PASS final |
| Orchestrateur | Intégration E1 vers E4 | PASS |

Un premier appel agent invalide a combiné des paramètres non acceptés. Une
nouvelle tentative a ensuite rencontré la limite de threads. Les agents déjà
ouverts ont été réutilisés; aucun résultat n'a été inventé. Les premières
reviews E4 ont trouvé des blockers réels: absence de verrou partagé, requête de
persistance forgeable, retry d'undo incomplet, race de réécriture du journal,
perte possible de forme JSON lors d'un save générique et traitement dangereux
d'un journal malformé. Tous ont été corrigés avant la revue finale.

## 5. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<empty>

git diff --stat
<empty>

git diff --name-only
<empty>

git log --oneline -n 20
e932d9a2 feat(event-v2): enhance migration plan with context validation and strict JSON parsing
025bf9bc feat(event-v2): complete NS-EVENT-V2 Phase D
39a9f7bb feat(selbrume): add forest layer to map bourg selbrume
56fd6342 feat(editor): use dropdown for layer creation type
85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
1fc32b4f feat(editor): allow confirmed bulk deletion of map layers and update selbrume project assets
e0e4876e test(editor): add smoke test for terrain preset dropdown menus
02de2ffe feat(editor): add design-system dropdown field
816671f7 feat: refine Port des Brisants visuals and editor controls
928cccae test(selbrume): add Port des Brisants visual refinement tests
9fae047b test
7797d332 feat(selbrume): rebuild Port des Brisants from reference
a9a12723 feat(selbrume): generate seamless water family v2
bd95861a feat(selbrume): add provenance-locked visual kit v2
459242b7 feat(selbrume): validate authored maps without rebuilding
5edc3cf4 fix(selbrume): recover authored map placements
a4c7dead feat(editor): add explicit placement origin migration
39e7dc37 fix(editor): guard placement ownership and bulk saves
96d1862f fix(editor): preserve authored map placements on load
d9e08979 chore: remove generated skill cache
```

Le worktree était propre. `packages/map_editor/pubspec.lock` a ensuite dérivé à
la suite d'une commande Flutter de lecture des dépendances. Blob baseline:
`16e4b367ae1ac074a2ce3b59309b3c34618a860f`; blob worktree:
`51980c1eff6de9c04d44f6f236d647850e185ced`; SHA-256 worktree:
`a6646437ad4410fa4859f0f8007b0b9589888febc0c6df8b165d7681a9ab52dc`.
Ce drift n'est ni revendiqué ni inclus dans le commit Phase E.

## 6. Architecture générale d'authoring

Le flux est strictement séparé:

```text
snapshot Phase D + expected revision
  -> opération pure E1/E2/E3
  -> NarrativeEventAuthoringResult immuable
  -> vérification par replay
  -> requête E4 dérivée du résultat
  -> preflight JSON/revision
  -> single-write journalé de eventRegistry
```

E1 à E3 n'accèdent ni au filesystem, ni à Flutter, ni au runtime. E4 n'invente
pas une mutation: il rejoue et vérifie le résultat pur reçu.

## 7. Contrat de résultat commun

`NarrativeEventAuthoringResult` distingue `applied`, `noOp`, `rejected`,
`staleRevision`, `unsupportedRegistry` et `invalidRegistry`. Il expose registry
et record précédent/suivant, diagnostics stables et humains, impact source,
revision attendue, revision conceptuelle, mutation, caractère metadata-only et
capacité d'undo.

| Statut | Registry suivant | Undoable | Write E4 |
|---|---:|---:|---:|
| applied | oui | oui | autorisé après replay |
| noOp | non | non | refusé |
| rejected | non | non | refusé |
| staleRevision | non | non | refusé |
| unsupportedRegistry | non | non | refusé |
| invalidRegistry | non | non | refusé |

## 8. Contexte et revision

`NarrativeEventAuthoringContext` lie le registry décodé, son token de revision,
le catalogue projet, le source index, le hash manifest et les hashes de maps.
Chaque opération vérifie la cohérence de ce snapshot. Les revisions registre et
fichier sont des SHA-256; le writer compare les octets du manifest sous verrou,
puis relit le hash immédiatement avant le rename.

## 9. E1 Draft Creation

`createNarrativeEventDraft` accepte un registry absent et construit en mémoire
un registry `legacyOnly`. Le draft project-level peut rester sans source. Une
source initiale, lorsqu'elle existe, doit être une option actuelle du catalogue.
L'identité est injectée et collision-safe; aucun ID n'est consommé avant la fin
des validations. Aucune géométrie n'est copiée dans l'Event.

## 10. Review E1

```text
E1 REVIEW R1 : PASS
E1 REVIEW R2 : PASS
```

Preuves: création sans map, chaque type de source, registry absent, collisions,
épuisement, ordre, claims, context stale/invalid/unsupported et absence de
l'index runtime enabled.

## 11. E2 Source Operations

`selectNarrativeEventSource`, `replaceNarrativeEventSource` et
`removeNarrativeEventSource` restent des intentions distinctes. Une source
identique est revalidée puis devient un no-op honnête. Un Event enabled refuse
la modification. Le retrait d'un configured disabled effectue un unpublish
structurel vers draft. Une référence cassée est conservée jusqu'à une action
explicite de réparation ou retrait.

## 12. Property Preservation Matrix

| Opération | ID | Nom | Conditions | Scene | Reuse | Priority/order | Mode/claims | Source physique |
|---|---|---|---|---|---|---|---|---|
| select | conservé | conservé | conservées | conservée | conservé | conservés | conservés | jamais mutée |
| replace | conservé | conservé | conservées | conservée | conservé | conservés | conservés | jamais mutée |
| remove draft | conservé | conservé | conservées | conservée | conservé | conservés | conservés | jamais supprimée |
| remove configured disabled | conservé | conservé | conservées | conservée | conservé | conservés | conservés | jamais supprimée |
| enabled | rejet | rejet | rejet | rejet | rejet | rejet | conservés | inchangée |

L'identité outcome qualifiée par producteur est préservée exactement.

## 13. Review E2

```text
E2 REVIEW R1 : PASS
E2 REVIEW R2 : PASS
```

## 14. E3 Conditions

Le subset V0 accepté est limité à `fact` et `narrativeEventConsumed`, avec AND
implicite, ordre stable et doublons conservés. Facts absents/ambigus, Event
absent/draft/invalide, self-reference et cycles sont bloqués. La traversée du
graphe est itérative et testée sur 10 000 Events.

## 15. Dependency Graph & Cycle Policy

| Cas | Verdict |
|---|---|
| liste vide | valide, AND vrai |
| Fact unique/dupliqué | valide si catalogue unique |
| Event consumed configuré | valide |
| self-reference | rejet |
| cycle projeté 2/3 nœuds | rejet |
| cycle canonique existant | réparation locale autorisée si elle réduit le défaut |
| erreur indépendante | reste bloquante |
| Story Step, OR, raw flag | hors contrat V0 |

## 16. Scene & Behavior

Une Scene doit être unique et buildable. Scene, `reusePolicy`, priorité et ordre
sont modifiables sur draft ou configured disabled selon l'opération. Retirer la
Scene d'un configured disabled produit un draft. Un enabled exige d'abord une
désactivation, à l'exception du renommage explicitement metadata-only.

## 17. Publication Gate

La publication exige nom, source, Scene, behavior, entiers canoniques,
conditions valides et catalogue sans blocker. Elle convertit un draft en
configured **disabled** et ajoute le diagnostic `runtimeSupportPending`. Elle
n'active jamais l'Event et n'écrit jamais sur disque.

## 18. Activation Conflict Matrix

| État/cas | Activation |
|---|---|
| draft | rejet `eventNotConfigured` |
| configured disabled valide | applied, enabled=true |
| configured enabled valide | no-op |
| source/Scene/condition invalide | rejet |
| source identique, priorité différente | autorisée |
| source identique, ordre différent | autorisée |
| source + priorité + ordre identiques à un enabled | rejet `exactSourceConflict` |
| contexte/revision/index stale | rejet |

La désactivation est une opération séparée et idempotente.

## 19. Review E3

```text
E3 REVIEW R1 : PASS
E3 REVIEW R2 : PASS
```

## 20. E4 Persistence Architecture

`NarrativeEventRegistryWriteRequest.fromAuthoringResult` est la seule fabrique
publique. Elle exige un résultat `applied`, compare sa revision, le vérifie par
replay et dérive la mutation ainsi que l'unique Event modifié. Le repository
refait cette vérification avant tout effet de bord.

Un verrou partagé sérialise les writers Event, recovery, undo et le save
générique du manifest. Il combine une file in-process et un advisory file lock
cross-process. Le sidecar de lock persiste volontairement pour éviter une race
d'inode lors d'un unlink/reopen.

## 21. Raw JSON Preservation

Le writer parse le manifest avec le décodeur strict duplicate-key/I-JSON,
préserve la racine et tous les sous-arbres inconnus, remplace uniquement
`eventRegistry`, puis encode le résultat. Le save générique normalise d'abord
les valeurs Freezed par `jsonEncode/jsonDecode`, conserve le registry courant
et les champs racine inconnus, puis vérifie son hash sous le même verrou.

Les registries unsupported/invalid restent read-only. Mode, claims,
`schemaVersion`, ordre des records et champs legacy hors registry ne sont pas
réécrits par le workflow E4.

## 22. Journal State Machine

```text
prepared --rename + hash vérifié--> committed
prepared --recovery before hash--> recovered (rollback/no visible commit)
prepared --recovery after hash--> recovered (commit visible finalisé)
committed --recovery after hash--> état stable
unexpected hash -----------------> blocked
```

Le journal strict contient hashes before/after, chemins temp/backup, Event ID,
mutation, snapshots registry et timestamps. Les fichiers d'un projet utilisent
un préfixe spécifique au manifest pour éviter les collisions entre projets d'un
même dossier.

## 23. Crash Matrix

| Checkpoint injecté | État attendu |
|---|---|
| before/after backup | projet before, cleanup ou recovery déterministe |
| after journal prepared | journal prepared, backup vérifiable |
| after temp write/flush | projet before, temp jetable |
| before rename | projet before |
| after rename/hash verify | projet after, recovery finalise |
| before committed | projet after, journal prepared récupérable |
| after committed before cleanup | projet after, journal committed |

## 24. Recovery Matrix

| Journal | Projet | Résultat |
|---|---|---|
| prepared | beforeHash | rollback déterministe, backup vérifié |
| prepared | expectedAfterHash | finalisation sans réécriture projet |
| committed | expectedAfterHash | état stable |
| toute valeur | hash inconnu | blocked, aucun write |
| prepared | backup absent/corrompu | blocked |
| plusieurs prepared | ambigu | blocked |
| journal malformé | quelconque | backup conservé |

Recovery est idempotente. Les réécritures de journal utilisent elles-mêmes un
temp et tolèrent un temp préexistant sans détruire la preuve.

## 25. Undo Contract

L'undo est une nouvelle opération journalée. Son entrée immuable embarque
before/after revisions, registries, hashes, Event IDs et timestamp. Il ne passe
que si les octets courants correspondent exactement à la revision after. Toute
modification plus récente, y compris un champ racine inconnu, produit
`staleUndo`. Un crash avant rename est récupérable puis retryable; un crash
après rename finalise l'undo sans double écriture.

## 26. Review E4

Les deux reviewers ont d'abord bloqué E4. Les corrections apportées couvrent le
verrou/CAS, le replay du résultat d'authoring, la truthful metadata, le retry
d'undo, la race de journal temp, la préservation du save générique et la
conservation du backup face à un journal malformé.

```text
E4 REVIEW R1 : PASS
E4 REVIEW R2 : PASS
```

## 27. Public API finale

`map_core` exporte le contrat commun, la vérification, les opérations draft,
source, configuration, publication et activation. `map_editor` expose
`PersistNarrativeEventRegistryUseCase`,
`RecoverNarrativeEventRegistryWritesUseCase` et
`UndoNarrativeEventRegistryWriteUseCase` via un gateway dédié. Le repository
fichier existant implémente ce gateway sans exposer les détails journal/temp.

## 28. Compatibility V1

- Aucun modèle V1 modifié.
- Aucun MapEvent ou Scenario écrit.
- Aucun projet Selbrume ouvert ou migré.
- Aucun mode basculé automatiquement vers `dualRead` ou `v2Only`.
- Aucun claim authoré.
- Les tests runtime legacy ciblés restent verts (`+3`).
- Les tests Event Builder V1 pertinents font partie de la régression editor
  cumulée (`+245`).

## 29. Tests ciblés

| Périmètre | Résultat exact |
|---|---|
| E1-E3 + fingerprint + replay + performance core | `+66: All tests passed!` |
| E4 repository/journal/recovery/undo | `+39: All tests passed!` |
| E4 avec performance | `+40: All tests passed!` |

Les tests couvrent positif, négatif, stale revisions, catalogues invalides,
préservation, forge, concurrence, strict JSON, crash matrix, recovery, undo et
non-régression.

## 30. Tests cumulés

- `packages/map_core`: `+2908: All tests passed!`.
- Régressions editor requises (cinq suites E4, scenario claim guard, workspace
  Event Builder, draft notifier, project config, sessions editor et collision
  persistence): `+245: All tests passed!`.
- Runtime legacy characterization: `+3: All tests passed!`.
- `selbrume_editor_repository_roundtrip_test.dart`: deux tests de save/roundtrip
  passent; le troisième échoue sur l'attente historique `306` contre `94`.
- Suite `packages/map_editor` complète: exit 1 sur 3105 événements `testDone`:
  `2968 success`, `6 failure`, `131 error`. Le flux machine contient également
  137 événements de type `error`. Les six résultats `failure` sont:
  1. `Selbrume editor file repositories round-trip real EditorNotifier sessions retain all 722 placements after an edit`;
  2. `design-system guardrails editor UI does not add direct color references outside tokens`;
  3. `golden slice eau 2x2 animée depuis JSON dans MapGridPainter`;
  4. `EditorNotifier project dirty state applyElementAutoShadowSuggestions applique et sauvegarde`;
  5. `validate-authored rejects removal of a required landmark`;
  6. `validate-authored rejects removal of a required connection`.

Les 131 résultats `error` couvrent principalement des tests UI, shadow editor,
goldens, Storylines/Scenes, scripts Selbrume et quelques erreurs de chargement
Pokemon SDK. Aucun des 137 résultats non verts ne cible les suites ou fichiers
Phase E. Une régression de save générique initialement causée par E4 a, elle,
été corrigée: les cinq tests `project_pokemon_config_test.dart` passent
désormais.

## 31. Analyze/build

- `dart analyze` dans `packages/map_core`: `No issues found!`.
- Analyse ciblée des 12 fichiers E4: `No issues found!`.
- `flutter analyze` complet dans `packages/map_editor`: exit 1,
  `451 issues found`; aucune ne vise un fichier Phase E. Les premières erreurs
  proviennent de `pokemon_sdk_move_catalog_converter.dart` et de contrats
  Pokemon move historiques.
- `flutter build macos --debug`: `Built build/macos/Build/Products/Debug/map_editor.app`.

## 32. Performance

Machine: Apple M1 Pro, 32 GiB, macOS Darwin ARM64 27.0.0. Dart 3.12.1 stable;
Flutter 3.46.0-0.3.pre beta. Mesures JIT informatives, warmup 1, catalogues
préconstruits et exclus; hashing interne inclus; AOT non mesuré; aucun seuil
flaky.

| Opération core | 10 mean/median µs | 1 000 mean/median µs | 10 000 mean/median µs |
|---|---:|---:|---:|
| draft | 1360.3 / 1084 | 27994.9 / 28710 | 238589 / 235308 |
| source | 695.2 / 641 | 24231.4 / 23252 | 241821.3 / 241483 |
| graph | 308.6 / 274 | 20130.7 / 19376 | 186790 / 187365 |
| publication | 489.4 / 381 | 24330.3 / 24464 | 284058.7 / 275385 |
| activation | 439.3 / 405 | 26908.7 / 27013 | 301777.7 / 313129 |
| JSON patch | 126.9 / 98 | 9284.7 / 8475 | 94430 / 96223 |

| Opération E4 | Volume | Itérations | Mean / median µs |
|---|---:|---:|---:|
| journaled write | 1 | 7 | 24221.9 / 16265 |
| recovery scan | 1 | 5 | 8209.8 / 5978 |
| recovery scan | 100 | 5 | 157851.6 / 157443 |

## 33. Generated files

Deux passes `dart run build_runner build --delete-conflicting-outputs` dans
`packages/map_core` ont écrit `0 outputs`. La première a signalé l'avertissement
connu de version de langage SDK 3.12 supérieure à analyzer 3.9. Aucun generated
file n'a été ajouté ou modifié.

## 34. Scope final

Le lot touche uniquement `map_core`, la couche application/infrastructure E4
de `map_editor`, les tests, ces rapports et la roadmap. Aucun fichier UI,
runtime, gameplay, battle, examples, assets, Selbrume, map ou Scenario n'a été
modifié. Aucun drag/drop, bridge source, progression, dispatch, UI V2 ou
migration réelle n'a été ajouté.

Gate pré-commit final:

```text
git diff --cached --name-only | wc -l
37

git diff --cached --check
<empty>

anti-scope runtime/gameplay/battle/examples/assets/selbrume
<empty>

Event Builder UI scope
<empty>

unstaged
packages/map_editor/pubspec.lock
```

Le lockfile est le seul drift hors lot; il reste volontairement non indexé.

## 35. Risques résiduels

- Le verrou cross-process est advisory: seuls les writers coopérants sont
  sérialisés.
- Le sidecar de lock reste sur disque par design.
- Dart n'expose pas ici un `fsync` portable du répertoire après rename; les
  fichiers sont flushés mais la durabilité face à une panne matérielle extrême
  n'est pas promise.
- Les performances AOT et sur manifest très volumineux restent à mesurer.
- La suite editor complète et l'analyse complète ont une dette préexistante.
- Aucune UI ne consomme encore l'API; aucune autorité runtime V2 n'existe.

## 36. Entry Gate Phase F1

`PHASE F1 : READY`. F1 peut considérer immuables: résultat/context d'authoring,
publication configured-disabled, activation séparée, source/Scene/condition
validation, conflit exact source/priority/order, registry strict, SHA-256
revisions, writer single-registry, mode/claims preservation, journal states,
recovery et undo stale-safe.

F1 doit encore construire l'autorité de dispatch et le namespace de progression
sans contourner ces contrats. Il ne doit pas interpréter `enabled` comme preuve
qu'un runtime V2 existe déjà.

## 37. Auto-review

La solution est plus grande qu'une persistance minimale, mais les frontières
supplémentaires répondent à des corruptions concrètes trouvées par les reviews:
forge de résultat, lost update concurrent, save générique destructif et recovery
ambiguë. Aucun helper n'a été extrait hors du périmètre E4. Les tests doublent
parfois les invariants, ce qui est assumé pour les transitions crash-sensitive.

## 38. Review contradictoire

Le reviewer contradictoire a explicitement refusé: un raw request public, une
simple comparaison de registry sans replay, un lock local au repository, la
suppression d'un backup associé à un journal illisible, un undo qui ne peut pas
être repris, une suppression fondée sur un chemin embarqué non validé, un hook
asynchrone entre le dernier hash check et le rename, et une déclaration
all-green de `map_editor`. Ces points sont respectivement corrigés ou documentés
honnêtement.

## 39. Critique du prompt

Le prompt regroupe quatre jalons conséquents et une persistance crash-sensitive
dans une seule mission; cela augmente la taille du lot et le coût de review. La
demande de “pas de commentaires dans le code” contredit `codex_rule.md`, qui en
demande un maximum. L'instruction directe du lot, plus spécifique, a été suivie:
aucun commentaire n'a été ajouté dans les nouveaux fichiers Phase E; les
invariants sont décrits par les noms, tests et rapports. Enfin, le critère
“tous les tests passent” n'est pas atteignable sur la baseline editor actuelle;
le lot distingue donc ses gates vertes de la dette globale au lieu de masquer
les échecs.

## 40. Verdict Phase E

```text
PHASE E : CLOSED / ACCEPTED
E1 / V2-13 : PASS
E2 / V2-14 : PASS
E3 / V2-15 : PASS
E4 / V2-16 : PASS
PHASE F1 : READY
BLOCKERS : NONE
RESERVES : advisory lock, no directory fsync, editor-wide pre-existing debt
```
