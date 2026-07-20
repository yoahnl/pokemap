# NSC-50 — Facts Registry projet et cycle de vie sûr

Date : 2026-07-20

Verdict : **DONE proposé pour NSC-50**

Roadmap : phase 5 Narrative Studio, lot 1 sur 9

## Résumé exécutif

Le registry Fact booléen V1 dispose maintenant d'un cycle de vie auteur sûr :
recherche, filtres par catégorie et rôle, renommage de label sans changement
d'identité, duplication sans recopier l'alias legacy et suppression protégée par
le `NarrativeDependencyIndex` canonique. L'éditeur expose la valeur initiale,
l'absence ou la présence d'un override runtime, ainsi que les lecteurs et les
producteurs.

La suppression ne repose plus sur trois walkers locaux. Elle consulte l'index
qui couvre Event V2, New Game, Scene, Storyline, WorldRule et sources legacy.
Le contrat wire reste strictement booléen ; les valeurs typées appartiennent à
NSC-51.

## Scope et non-objectifs

- Inclus : opérations pures add/update/duplicate/delete, read model de portée,
  UI no-code, valeur false explicite, valeur runtime absente, usages et tests.
- Réutilisé : `NarrativeDependencyIndex`, `NarrativeFactRuntimeState` et les
  primitives du PokeMap Design System.
- Non modifié : schéma Fact V1, alias legacy lors d'une duplication, variables
  `ScriptCondition.variable*` et chargement disque de toutes les maps.
- Reporté explicitement : snapshot projet complet et fusion de map dirty à
  NSC-52 ; bool/int/string à NSC-51.

## Audit initial

- `removeNarrativeFact` inspectait uniquement les conditions/consequences Scene
  et les sources WorldRule ; Event V2, New Game, Storyline et legacy manquaient.
- Le read model acceptait déjà un index canonique optionnel, mais le workspace
  ne le fournissait pas et affichait encore « Scene V1 et World Rules ».
- L'UI permettait create/edit/delete et recherche, sans duplication, filtres,
  valeur runtime explicite ni séparation lecteur/producteur.
- Le wire V1 sérialisait déjà `defaultValue: false` et lisait un champ historique
  absent comme false ; une preuve canonique ProjectManifest manquait.

## État Git initial

- Branche : `main`.
- HEAD : `8ff81770b feat(narrative): close event migration integrity`.
- Arbre initial propre pour les chemins du lot.

## Inventaire complet et zones modifiées

| Fichier | Zone | Impact |
|---|---|---|
| `packages/map_core/lib/src/authoring/narrative_fact_authoring_operations.dart` | update, duplicate, delete, lookup unique | Identité stable, clone sûr et suppression indexée exhaustive. |
| `packages/map_core/lib/src/read_models/facts_world_rules_manager_read_model.dart` | FactManagerEntry et builder | Catégories, valeur initiale/runtime, lecteurs et producteurs. |
| `packages/map_core/test/narrative_fact_authoring_operations_test.dart` | scénarios update/duplicate/delete | Prouve identité, alias non cloné et blocage Event V2/New Game. |
| `packages/map_core/test/facts_world_rules_manager_read_model_test.dart` | portée et valeurs | Prouve catégories, false, absence/override runtime et rôles. |
| `packages/map_core/test/project_manifest_narrative_canonical_json_test.dart` | régressions Facts | Prouve false explicite, false historique absent, ID cassé et round-trip canonique. |
| `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart` | manager Facts | Filtres, duplicate, valeurs et usages no-code via Design System. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | callbacks Facts | Branche duplicate et delete avec index frais. |
| `packages/map_editor/test/facts_world_rules_manager_test.dart` | parcours widget | Prouve duplication, filtres et affichage des valeurs. |
| `docs/superpowers/plans/2026-07-20-nsc-50-facts-registry-safe-lifecycle.md` | micro-plan | Frontières TDD et gate du lot. |

## Trail TDD

1. Les tests core ont d'abord échoué faute de `duplicateNarrativeFact`, des
   paramètres `dependencyIndex`/`runtimeState` et de la catégorie vide.
2. Le test widget a ensuite échoué à la compilation faute du callback
   `onDuplicateFact`.
3. Le premier scénario de filtre a révélé une fixture Scene dont le start node
   n'était pas de kind `start`; la fixture a été corrigée sans assouplir le
   domaine.
4. Les suites ciblées sont devenues vertes après branchement du même index dans
   le read model et dans la suppression.

## Tests, analyses et build — résultats exacts

```text
cd packages/map_core
dart test test/narrative_fact_authoring_operations_test.dart \
  test/facts_world_rules_manager_read_model_test.dart
+10: All tests passed!

dart test test/project_manifest_narrative_canonical_json_test.dart \
  test/narrative_fact_authoring_operations_test.dart \
  test/facts_world_rules_manager_read_model_test.dart
+13: All tests passed!

dart test test/narrative_fact_authoring_operations_test.dart \
  test/facts_world_rules_manager_read_model_test.dart \
  test/narrative_dependency_index_test.dart \
  test/project_new_game_config_test.dart \
  test/project_manifest_narrative_canonical_json_test.dart \
  test/narrative_fact_test.dart \
  test/narrative_fact_runtime_state_test.dart
+74: All tests passed!

dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor
flutter test test/facts_world_rules_manager_test.dart
+6: All tests passed!

flutter analyze \
  lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/facts_world_rules_manager_test.dart
No issues found! (ran in 3.9s)

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

git diff --check
<aucune sortie>
```

La matrice globale a aussi été exécutée. Les contrôles format signalent 67
fichiers core et 106 fichiers editor déjà non conformes hors scope. La suite
core complète lancée en parallèle de la suite Editor a échoué sur deux budgets
stone-chain (19,8 s > 8 s et 27,7 s > 12 s) ; rejoués seuls après libération de
la machine, les deux tests passent en 8 s et 7 s. La suite Editor complète a
terminé à `+4010 -8` : échecs de budgets et goldens/accessibilité Event Builder
hors chemins NSC-50. Le test Facts complet, son golden inclus, passe isolément.
`flutter analyze` global conserve 11 warnings préexistants dans
`dialogue_studio_dialogs.dart`; l'analyse des trois fichiers du lot est verte.

## Passes locales nommées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : un seul index canonique remplace les walkers incomplets. |
| Implémentation | PASS : le contrat bool V1 est préservé et l'ID ne suit jamais le label. |
| UX / Design System | PASS : filtres, valeurs et actions utilisent exclusivement les primitives/tokens PokeMap. |
| Tests ciblés | PASS : 74 core et 6 widget sur le périmètre élargi. |
| Build | PASS : binaire macOS Editor produit. |
| Critique finale | PASS avec limite : les maps non chargées ne peuvent être indexées avant le snapshot projet NSC-52. |

Les sous-agents n'ont pas été utilisés car l'instruction active interdit la
délégation proactive. Ces passes locales indépendantes satisfont la revue
multi-angle demandée par `codex_rule.md`.

## Risques et garde-fous

- Un caller pourrait fournir un index construit avec une liste de maps
  incomplète ; l'UI fournit un index frais et NSC-52 fermera la portée disque.
- Une duplication n'emporte jamais `legacyFlagName`, afin qu'un alias ne possède
  pas deux propriétaires canoniques.
- Un projet contenant deux définitions du même Fact est considéré ambigu et
  update/duplicate/delete échouent fermé.

## Fichiers créés — contenu et attestation

| Fichier créé | Lignes | SHA-256 avant commit |
|---|---:|---|
| `docs/superpowers/plans/2026-07-20-nsc-50-facts-registry-safe-lifecycle.md` | 27 | `f14102e2385ea284859c32b24a6bbd858c20e98a713d53ea4710c1c2b5ed564b` |

### Contenu intégral du micro-plan

```markdown
# NSC-50 — Facts Registry projet et cycle de vie sûr

## Objectif

Faire du registry Fact booléen V1 une API projet traçable : recherche et filtres, renommage de label sans changement d'ID, duplication, valeur initiale/runtime explicite et suppression bloquée par l'index de dépendances exhaustif.

## Frontières

- Conserver le wire booléen V1 ; les valeurs bool/int/string appartiennent à NSC-51.
- Réutiliser `NarrativeDependencyIndex` comme unique inventaire des consommateurs.
- Ne jamais réécrire automatiquement un ID technique lors d'un changement de label.
- Ne charger que les maps fournies ; le snapshot projet entier arrive en NSC-52.
- Ne pas commencer NSC-51 dans ce commit.

## Plan TDD

1. Ajouter les tests rouges de duplication et de suppression Event V2/New Game via l'index canonique.
2. Étendre les tests existants de l'index qui couvrent Scene, Storyline, WorldRule et legacy.
3. Ajouter les tests rouges du read model : catégories, portée lecteur/producteur, valeur initiale false explicite et override runtime absent/présent.
4. Implémenter les opérations pures minimales et brancher le read model sur l'index.
5. Ajouter les tests widget rouges pour filtres et duplication no-code.
6. Brancher l'UI et la persistance in-memory sans couleur brute ni ID manuel.
7. Vérifier core/editor ciblés, suites package, analyses et build macOS.

## Gate

Un Fact booléen peut être trouvé, filtré, renommé et dupliqué ; sa valeur et tous ses producteurs/consommateurs sont visibles, et aucune suppression référencée n'est possible.
```

Le présent Evidence Pack est lui-même créé dans ce lot et constitue son contenu
intégral.

## Statut gameplay proposé

- FG-081 (Condition Builder) : reste `PARTIAL`, car NSC-51 doit encore typer les
  opérateurs et valeurs.
- FG-088 (Set Flag/Variable) : reste `PARTIAL`, le bool historique est sûr mais
  bool/int/string n'est pas encore fermé.
- Aucun statut de la roadmap gameplay n'est modifié par ce lot.
