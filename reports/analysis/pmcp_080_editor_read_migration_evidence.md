# PMCP-080 — Migration lecture de `map_editor`

## Résumé exécutif

Verdict proposé : `DONE` pour PMCP-080. Le bootstrap produit de l'éditeur lit
désormais `project.json`, les cartes et les catalogues structurés depuis une
session `map_authoring` immuable partagée. L'adaptateur conserve les modèles
typés attendus par Flutter, expose query/pagination/recherche/diagnostics, et
invalide explicitement la session après une écriture ou un rechargement.

La transaction de mutation historique n'est pas migrée dans ce lot. Deux
capacités étroites distinguent cependant la projection UI du snapshot et la
lecture durable brute requise pendant une transaction multi-fichier. Cette
séparation corrige les régressions create/rename/recovery révélées par la suite
complète sans déplacer de règle métier dans Flutter.

Le roadmap `pokemap_authoring_api_mcp_lot_roadmap.md` n'est pas modifié. Le
statut `DONE` est seulement proposé. Aucun statut `FG-*` n'est concerné.

## Scope confirmé

- Lot : `PMCP-080`, dépendance satisfaite `PMCP-072`.
- Lecture canonique : `map_authoring` pur Dart.
- Adaptation Flutter : `map_editor`, sans dépendance inverse.
- Bootstrap produit : une même `AuthoringQueryAdapter` est injectée dans les
  repositories projet et carte.
- Projections : manifest, maps, query générique, pagination, recherche,
  références, diagnostics et révisions CAS compatibles avec l'éditeur.
- Non-objectifs : migration des mutations (`PMCP-081`) et transport MCP
  (`PMCP-082` à `084`).

## Audit initial

- Base Git : `f61337c15 docs(authoring): correct PMCP-072 evidence wording`.
- `map_editor` décodait le manifeste et chaque carte séparément dans
  `FileProjectRepository` / `FileMapRepository`.
- `ProjectSnapshotLoader`, `ProjectQueryService` et `AuthoringReadApi`
  existaient déjà dans `map_authoring`, mais aucun adapter produit Flutter ne
  les composait.
- Les révisions de l'éditeur sont des empreintes des octets bruts du document,
  alors que les empreintes Authoring incluent l'identité de ressource : elles
  ne sont donc pas interchangeables.
- Selbrume contient dix cartes, 24 dialogues, 35 scènes et plus de onze mille
  fichiers ; certaines copies de tests omettent volontairement une source de
  dialogue tout en restant ouvrables dans l'éditeur.
- Le worktree contenait déjà des changements Smart Tiles / World Map, un
  lockfile hôte et le prototype `.superpowers`. Ils restent hors du commit.

## Fichiers

Créés :

- `packages/map_editor/lib/src/application/authoring_api/authoring_query_adapter.dart`
  — cache de sessions, modèles typés, query et diagnostics.
- `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart`
  — frontière filesystem de l'éditeur vers `ProjectFileReader`.
- `packages/map_editor/test/authoring_api/editor_read_parity_test.dart` —
  parité, snapshot unique, pagination, recherche et budgets Golden/Selbrume.
- `pokemap_authoring_api_mcp_phase_7_implementation_plan.md` — plan des lots
  PMCP-080 à PMCP-084 et politique d'un commit par lot.
- `reports/analysis/pmcp_080_editor_read_migration_evidence_appendix.md` —
  contenu complet des fichiers créés par le lot.

Modifiés :

- `packages/map_authoring/lib/src/workspace/project_snapshot.dart` —
  diagnostics immuables de chargement.
- `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart` —
  politique stricte par défaut et projection éditeur tolérant une source
  supplémentaire absente tout en publiant un diagnostic bloquant.
- `packages/map_authoring/test/workspace/project_snapshot_test.dart` — preuve
  que strict refuse et que la projection éditeur reste lisible/diagnostiquée.
- `packages/map_editor/pubspec.yaml`, `pubspec.lock` — dépendance locale
  `map_authoring`.
- `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` —
  composition d'un reader/adaptateur commun et fermeture à la disposal.
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
  — lectures projet/map via snapshot, invalidations et lecture durable brute.
- `packages/map_editor/lib/src/domain/repositories/repositories.dart` —
  capacités optionnelles refresh et durable-read.
- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` —
  refresh explicite et opt-in pour les reloads.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` —
  reload utilisateur/récupération demandé frais.
- `packages/map_editor/lib/src/infrastructure/repositories/map_lifecycle_transaction_file_gateway.dart`
  — recovery/transaction lit le document durable même avant le nouveau
  manifeste.

## Zones modifiées et invariants

- `AuthoringQueryAdapter.open` canonise la racine, ouvre une policy limitée à
  cette racine et réutilise une seule future/session par projet.
- Une session fermée échoue explicitement ; `invalidate` et `closeAll` ferment
  les handles Authoring au lieu de laisser un cache zombie.
- Les queries opèrent uniquement sur `_snapshot` : aucune recherche ou page
  supplémentaire ne relit les fichiers.
- `resourceRevision` recalcule l'empreinte CAS de l'éditeur sur les octets
  exacts ; l'empreinte path-aware Authoring n'est jamais présentée comme une
  révision de carte.
- Le mode `strict` reste la valeur par défaut de `ProjectSnapshotLoader`.
- `editorReadProjection` ne transforme pas une ressource manquante en succès :
  il publie `project.dialogue_source_missing`, `blocking: true`, puis conserve
  les ressources lisibles pour permettre l'ouverture et la réparation.
- Les writes ne vérifient jamais leur durabilité via un manifeste transitoire :
  create/rename/recovery utilisent la capacité brute uniquement à la frontière
  transactionnelle.
- Les reloads explicites et l'adoption d'une récupération invalident le
  snapshot ; une navigation ordinaire partage au contraire le snapshot projet.
- Aucun import Flutter/Flame n'est ajouté à `map_authoring`.

## Passes séparées exigées par `codex_rule.md`

- **Audit / Architecture — PASS** : la sémantique reste dans `map_authoring` ;
  l'éditeur ne contient qu'un adapter et des capacités d'infrastructure.
- **Implémentation — PASS** : bootstrap central projet/map migré, catalogues
  queryables, cache borné/fermé et CAS préservée.
- **Tests — PASS pour le lot** : RED initial, tests Authoring complets,
  parité Golden/Selbrume et matrice transaction/reload finales vertes.
- **Build / Validation — PASS** : analyses Dart/Flutter sans issue et build
  macOS debug produit.
- **Critique finale — PASS avec limite externe tracée** : la suite éditeur
  complète ne peut pas fournir une photo finale stable pendant les changements
  World Map concurrents ; les tests affectés au lot sont isolés et verts.

Les sub-agents n'ont pas été lancés : l'instruction développeur interdit la
délégation sans demande explicite. Les cinq passes ci-dessus sont locales et
séparées.

## TDD et débogage systématique

RED observés :

```text
flutter test test/authoring_api/editor_read_parity_test.dart
Résultat : compilation impossible — dépendance map_authoring et adapters absents.

flutter test test/authoring_api/editor_read_parity_test.dart
Résultat : authoringQueries/closeAll absents du repository et de l'adapter.

dart test test/workspace/project_snapshot_test.dart
Résultat : ProjectSnapshotLoadPolicy et le paramètre policy absents.
```

La première exécution Flutter après `pub get` a rencontré une course native
assets (`objective_c.dylib` absent pendant le code-sign). Le fichier a été
produit par le hook et la relance isolée a réussi ; aucune source n'a été
modifiée pour masquer ce bootstrap environnemental.

La première matrice produit a ensuite révélé :

1. une fausse révision externe, causée par l'utilisation de l'empreinte
   Authoring à la place de l'empreinte des octets bruts ;
2. le refus d'une copie Selbrume sans source dialogue ;
3. trois régressions create/rename/reload et une récupération narrative, car
   une lecture snapshot était utilisée pendant un état multi-fichier
   transitoire ou après une écriture externe.

Les corrections sont respectivement l'adaptation CAS explicite, la politique
de projection diagnostiquée, la capacité de lecture durable brute et le refresh
opt-in des reloads. Les tests existants ont été conservés comme preuves.

## Commandes exactes et résultats

GREEN final `map_authoring` :

```text
cd packages/map_authoring
dart test --reporter compact && dart analyze
Résultat : +293, All tests passed!; No issues found!
```

GREEN final lecture/parité :

```text
cd packages/map_editor
flutter test test/authoring_api/editor_read_parity_test.dart --reporter compact
Résultat : +6, All tests passed!
```

Le test couvre les trois cartes Golden, les dix cartes, 24 dialogues et 35
scènes Selbrume. Les queries répétées ne changent pas le compteur de reads et
les deux budgets généreux (5 s Golden, 10 s Selbrume) passent.

GREEN final transactions/reloads :

```text
flutter test test/app/providers/map_lifecycle_provider_wiring_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart \
  test/selbrume_editor_repository_roundtrip_test.dart \
  test/editor_notifier_real_session_roundtrip_test.dart --reporter compact
Résultat : +15, All tests passed!

flutter test test/ui/canvas/narrative_event_map_banner_test.dart \
  --plain-name 'NS-EVENT-V2-25 map source creation banner owner-present reload rebinds an uncertain cleanup lock for an in-process retry' \
  --reporter expanded
Résultat : +1, All tests passed!
```

Analyse et build :

```text
cd packages/map_editor
flutter analyze && flutter build macos --debug
Résultat : No issues found! (7.0s); Built PokeMap.app.
```

Suite complète observée avant les corrections finales :

```text
flutter test --reporter compact
Résultat : +5172 ~6 -5 après 06:48.
```

Les cinq échecs ont été identifiés exactement : un test World Map déjà modifié
hors lot, trois tests `EditorNotifier map revision` et un test de récupération
narrative. Les quatre tests relevant du lot passent dans la matrice finale.

Une seconde suite complète a été relancée. Pendant l'exécution, les fichiers et
tests World Map externes ont continué à changer : le compteur est passé de
`-1` à `-16` à `+1955 ~5`, uniquement pendant ces zones en cours de travail.
L'exécution a été interrompue à 02:23 afin de ne pas présenter une suite
concurrente comme une preuve stable. Le test externe isolé initial était :

```text
world_map_workspace_accessibility_test.dart
Shift arrows move the selected placed element by exactly one cell
Expected GridPos(2, 1), actual GridPos(1, 1).
```

## Auto-critique, risques et non-objectifs

- Le cache est invalidé par les repositories centraux et les reloads explicites.
  Un writer spécialisé qui modifie directement un fichier structuré doit appeler
  sa frontière d'invalidation lors de sa migration PMCP-081.
- La projection éditeur tolère uniquement le cas supplémentaire prouvé d'une
  source dialogue manquante. Toute nouvelle tolérance doit ajouter un code de
  diagnostic bloquant et garder le mode strict inchangé.
- Le test de performance fixe un plafond de régression, pas une mesure de
  benchmark reproductible ; aucun chiffre de performance n'est revendiqué.
- Les repositories Pokémon/media spécialisés restent propriétaires de formats
  qui ne font pas partie du `ProjectSnapshot` actuel. Ils ne sont pas présentés
  comme migrés silencieusement.
- Aucun fichier Smart Tiles / World Map externe n'est modifié ou stagé par ce
  lot.

## Git

Commit prévu : `feat(editor): read projects through authoring snapshots`.
Seuls les chemins listés dans ce rapport et son annexe doivent être stagés.
Le lockfile hôte, Smart Tiles, World Map et `.superpowers` restent hors commit.
