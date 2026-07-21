# NSC-80 — Harness de reconstruction narrative no-code

Date : 2026-07-21

Statut proposé : **DONE**

Lots gameplay associés : **FG-180 à FG-185 inchangés**. NSC-80 apporte une
preuve d'authoring et de persistance utile à FG-181/FG-183, mais ne suffit pas à
déclarer seul le démonstrateur Selbrume complet ou sa release gate `DONE`.

## Audit initial et verdict

Le projet possédait déjà un seeder Selbrume riche et idempotent, mais celui-ci
lit, transforme et réécrit historiquement des structures JSON. Il constitue une
automatisation canonique reproductible, pas une preuve que le parcours humain
du Narrative Studio permet de reconstruire le contenu sans éditer le manifest.

Le lot ajoute donc une frontière de test distincte. Elle part d'un projet ne
contenant qu'une map, un spawn et un PNJ physiques, puis crée avec les opérations
publiques Fact, Storyline/Chapter/Step, Dialogue/Yarn, Cinematic, Scene,
WorldRule et Event V2 actif. Chaque étape capture le Validator, la sauvegarde
passe par les repositories ou la transaction Event journalisée, et le résultat
est rechargé depuis disque avant comparaison canonique.

Verdict des passes manuelles imposées par l'absence de délégation autorisée :

| Passe | Verdict | Preuve principale |
|---|---|---|
| Audit/Architecture | GO | seeder et workflow humain séparés explicitement |
| Authoring typé | GO | neuf étapes publiques, aucune écriture JSON directe dans le harness |
| Persistence/Event | GO | repositories + Event V2 CAS/journal, reload identique |
| Validation | GO | 0 erreur après reconstruction et reload |
| Négatif | GO | second Event sur la même source refusé sans consentement |
| Widget/clavier | GO | Product Shell réel, palette, focus et cinq destinations |
| Seeder/provenance | GO | `canonicalSeedAutomation` renvoie vers la preuve humaine |
| Core search | GO | source Event indexée sans dépendre de `enum.name` |
| Build desktop | INCONCLUSIVE ENVIRONNEMENT | SDK Flutter local antérieur aux API déjà versionnées |
| Auto-critique | GO avec limites | preuve verticale complète, pas campagne Selbrume intégrale |

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
ci-dessus ont été exécutées manuellement et indépendamment avant la décision.

## Critères NSC-80

| Critère | Résultat | Verdict |
|---|---|---|
| Départ uniquement physique | 1 map, 1 spawn, 1 PNJ, inventaire narratif vide | GO |
| Fact | créé par `addNarrativeFact`, puis produit par une conséquence Scene | GO |
| Storyline/Chapter/Step | agrégat créé, Scene liée, Step terminable | GO |
| Dialogue/Yarn | use cases Create/Update/Save, outcome `accepted` persisté | GO |
| Cinematic | mutation `NarrativeAssetMutation.createCinematic` | GO |
| Scene | dialogue → cinematic → fact → completion → end explicite | GO |
| WorldRule | règle typée Fact → entité physique | GO |
| Event | source exacte PNJ, Scene, one-shot, publié puis activé | GO |
| Diagnostics intermédiaires | rapport et clés stables capturés à chaque étape | GO |
| Validation finale | 0 erreur après reload | GO |
| Persistance | fingerprint canonique avant/après reload identique | GO |
| Garde doublon | `existingLinks`, un Event existant, aucune écriture | GO |
| Absence d'authoring JSON | garde source contre decode/encode/write direct | GO |
| Parcours widget | Storyline → Dialogue → Scene → Event → Validator au clavier | GO |
| Seeder honnête | automation canonique explicitement non assimilée à l'UI | GO |

## Fichiers modifiés

- `packages/map_core/lib/src/read_models/narrative_global_search_index.dart`
- `packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart`
- `packages/map_editor/test/support/narrative_studio_visual_harness.dart`
- `packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart`

## Fichiers créés

- `docs/superpowers/plans/2026-07-21-nsc-80-no-code-reconstruction-harness.md`
- `packages/map_editor/test/support/narrative_studio_product_shell_harness.dart`
- `packages/map_editor/test/support/selbrume_narrative_authoring_harness.dart`
- `packages/map_editor/test/selbrume_narrative_reconstruction_test.dart`
- `packages/map_editor/test/selbrume_narrative_vertical_widget_journey_test.dart`
- `reports/narrativeStudio/completion/nsc_80_no_code_reconstruction_harness_evidence_pack.md`

Le contenu complet des fichiers créés est versionné dans le commit du lot. Le
micro-plan est ajouté explicitement malgré la règle historique `/docs/*` du
`.gitignore`. Aucun fixture JSON, cache, lockfile ou artefact machine n'est
ajouté.

## Zones précises et décisions

### Harness d'authoring

- `createPhysicalFixture` construit des modèles `ProjectManifest` et `MapData`
  typés, puis délègue leur sérialisation à `FileProjectRepository` et
  `FileMapRepository`.
- `authorVerticalSlice` orchestre exactement les opérations exposées aux
  workspaces : Facts, Storylines, Dialogue, Cinematic, Scene, World Rules et
  Event Builder V2.
- L'Event est la seule mutation du registry ; elle passe par plusieurs
  opérations CAS avec identifiants d'opération uniques, publication et
  activation explicites.
- La Scene produit le Fact et termine le Step. Ce choix transforme la preuve de
  simple inventaire en parcours statiquement solvable par le Validator.
- Le test lit le source du harness et refuse `jsonDecode`, `jsonEncode`,
  `writeAsString` et un accès direct à `project.json`.

### Widget réel

- Le test pompe `NarrativeStudioProductShell`, son rail réel et
  `NarrativeCommandPalette` avec le vrai index global construit depuis le
  projet rechargé.
- `Ctrl+K`, saisie, flèche bas et Entrée ouvrent Storyline, Dialogue, Scene et
  Event. Le focus workspace est restauré après chaque fermeture.
- Validator est atteint par Tab puis Entrée et expose le compteur issu du vrai
  rapport de validation.
- Le petit host du Product Shell est séparé du harness Editor Shell complet :
  cela évite de charger des workspaces Cinématiques/Storylines hors scope qui
  requièrent Flutter 3.44, tout en testant les widgets produit réels concernés.

### Seeder et recherche

- `SelbrumeNarrativeSeedResult` expose désormais
  `authoringContract=canonicalSeedAutomation` et
  `humanWorkflowProof=test/selbrume_narrative_reconstruction_test.dart`.
- Le seeder historique reste byte-idempotent et n'est pas présenté comme une
  simulation de l'interface humaine.
- Le parcours a découvert que l'index de recherche appelait `source.kind.name`,
  ce qui échouait réellement avec le runtime de package courant. Un mapping
  exhaustif et stable des quatre kinds remplace cette dépendance implicite.

## Commandes et résultats exacts

### État Git initial

```text
git status --short --untracked-files=all
(aucune sortie)

git log -1 --oneline
f5926f503 test(narrative): enforce large project performance budgets
```

### RED observé

```text
cd packages/map_editor
flutter test --no-pub test/selbrume_narrative_reconstruction_test.dart
Error when reading test/support/selbrume_narrative_authoring_harness.dart:
No such file or directory
Some tests failed.
```

Le premier parcours widget a ensuite mis en évidence deux faits distincts :

```text
Import du visual harness historique :
ScrollCacheExtent.pixels / scrollCacheExtent / onReorderItem indisponibles
avec Flutter 3.41.6.

Après découplage ciblé :
NoSuchMethodError: NarrativeEventSourceKind has no instance getter 'name'
dans buildNarrativeGlobalSearchIndex.
```

Le premier est une incompatibilité SDK préexistante hors lot ; le second a été
corrigé et couvert dans le lot.

### Core final

```text
cd packages/map_core
dart test test/narrative_global_search_index_test.dart
+3: All tests passed!

dart analyze lib/src/read_models/narrative_global_search_index.dart \
  test/narrative_global_search_index_test.dart
No issues found!
```

### Editor final

```text
cd packages/map_editor
dart format --output=none --set-exit-if-changed \
  ../map_core/lib/src/read_models/narrative_global_search_index.dart \
  test/support/narrative_studio_visual_harness.dart \
  test/support/narrative_studio_product_shell_harness.dart \
  test/support/selbrume_narrative_authoring_harness.dart \
  test/selbrume_narrative_reconstruction_test.dart \
  test/selbrume_narrative_vertical_widget_journey_test.dart \
  test/selbrume_canonical_narrative_seed_test.dart \
  tool/seed_selbrume_canonical_narrative_content.dart
Formatted 8 files (0 changed) in 0.04 seconds.

flutter analyze --no-pub \
  test/support/selbrume_narrative_authoring_harness.dart \
  test/support/narrative_studio_product_shell_harness.dart \
  test/selbrume_narrative_reconstruction_test.dart \
  test/selbrume_narrative_vertical_widget_journey_test.dart \
  test/selbrume_canonical_narrative_seed_test.dart \
  tool/seed_selbrume_canonical_narrative_content.dart
No issues found! (ran in 1.9s)

flutter test --no-pub --timeout 2m \
  test/selbrume_narrative_reconstruction_test.dart \
  test/selbrume_narrative_vertical_widget_journey_test.dart \
  test/selbrume_canonical_narrative_seed_test.dart
+5: All tests passed!
```

### Meilleure preuve build disponible

```text
cd packages/map_editor
flutter build macos --debug --no-pub
```

Résultat exact : **BUILD FAILED** avant compilation du code du lot, sur des API
déjà présentes dans deux workspaces :

```text
cinematics_library_workspace.dart: ScrollCacheExtent.pixels et
scrollCacheExtent indisponibles.
storylines_structure_view.dart: onReorderItem indisponible.
Flutter local : 3.41.6 ; APIs attendues par le dépôt : Flutter 3.44.
```

Le lot ne transforme pas cet échec environnemental en succès et ne modifie pas
ces deux écrans hors scope.

## Risques, limites et auto-critique

- Le harness prouve une tranche verticale complète, pas la reconstruction de
  l'intégralité du scénario `selbrume.md`. Cette matrice appartient à NSC-81.
- Le parcours widget prouve la navigation et le focus dans le vrai Product
  Shell ; l'authoring de chaque formulaire est prouvé par ses opérations
  publiques et leurs tests existants, pas par des centaines de clics fragiles.
- Le seeder complet conserve ses projections JSON historiques. La provenance
  empêche désormais de les confondre avec le workflow humain ; une migration
  totale du seeder vers les transactions typées serait un lot distinct et
  risqué.
- La validation finale accepte des warnings non bloquants éventuels, mais exige
  explicitement 0 erreur. Les diagnostics restent capturés à chaque étape.
- La correction de recherche ajoute un mapping exhaustif ; tout futur kind de
  source provoquera une erreur de compilation du switch et devra recevoir un
  mot-clé explicite.
- Aucun build desktop vert ne peut être revendiqué tant que le SDK local n'est
  pas aligné. Les tests ciblés contournent uniquement les imports hors scope,
  pas les widgets du parcours vérifié.

État Git avant commit : uniquement les fichiers listés ci-dessus et cet
Evidence Pack NSC-80 ; le plan ignoré doit être ajouté avec `git add -f`.
