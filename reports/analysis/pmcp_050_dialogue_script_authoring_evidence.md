# PMCP-050 — Evidence Pack dialogues, Yarn et scripts

Date : 2026-07-31
Lot : `PMCP-050 — Dialogue/Yarn/script lifecycle`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot ajoute le cycle de vie transactionnel des dialogues et scripts :
création, métadonnées, source Yarn, suppression, migration legacy, upsert et
suppression de scripts. Les fichiers de dialogue externes font désormais
partie du snapshot cohérent, de sa révision et du compare-and-swap.

La compilation authoring refuse les commandes Yarn inconnues avec leur ligne,
vérifie le nœud de départ et les outcomes déclarés. Les simulateurs dialogue
et script sont purs : ils rendent transcript, choix, outcomes et effets
prévisionnels sans appeler le runtime. Une migration `.txt` crée un Yarn
validé tout en conservant la source historique exacte à son ancien chemin.

## Audit initial et continuité

État Git initial du lot : arbre PokeMap propre à
`b89677ee feat(authoring): add presentation authoring`.

L’audit narratif a identifié trois risques que le premier découpage ne
couvrait pas : les sources Yarn externes n’étaient pas dans les snapshots, le
compilateur runtime tolère volontairement les commandes inconnues, et une
simple conversion legacy aurait pu perdre des octets. Le scope a donc été
étendu au snapshot/query, à une surcouche de compilation stricte et à une
migration additive conservant l’original.

Des fichiers non suivis `.superpowers/brainstorm/...` sont apparus pendant le
lot depuis un autre flux de travail. Ils ne sont ni inspectés, ni modifiés, ni
staged par ce lot.

## Passes et verdicts

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture — agent narratif | Conforme après corrections | A imposé source externe revisionnée, diagnostics Yarn inconnus et migration honnête |
| Implémentation | Conforme | Sept mutations, deux read kinds, compile et simulate publics |
| Tests | Conforme | RED initial, 7 tests narratifs, snapshot source, plan/apply/undo exact |
| Build / Validation | Conforme | 256 tests authoring, 10 tests core ciblés et analyses vertes |
| Critique finale | Conforme avec limites | Les scripts legacy restent prévisualisés, leur exécution appartient au runtime existant |

## Contrats et zones modifiées

- `dialogue_authoring_service.dart` : compilation stricte, diagnostics,
  outcomes, simulation bornée et migration legacy loss-aware.
- `script_authoring_service.dart` : validation de graphe/paramètres et
  simulation des effets sans mutation de `GameState`.
- `dialogue_actions.dart` : cinq mutations et guards références/outcomes.
- `script_actions.dart` : upsert/delete validés et scan conservateur.
- `dialogue_source_store.dart` : identité path-free des sources externes.
- `project_snapshot_loader.dart` : lecture double, empreinte et pré-images des
  fichiers dialogue déclarés.
- `project_query_service.dart` : list/get/search/detail des dialogues et
  scripts, avec source et résultat de compilation/simulation.
- `map_mutation_dispatcher.dart` : actions enregistrées et alias générique
  `AuthoringMutationDispatcher` compatible avec l’ancien nom.
- `resource_kind_registry.dart` : `dialogue`, `dialogueSource`, `script`.

## Inventaire complet

Créés :

- `packages/map_authoring/lib/src/domains/narrative/dialogue_actions.dart`
- `packages/map_authoring/lib/src/domains/narrative/dialogue_authoring_service.dart`
- `packages/map_authoring/lib/src/domains/narrative/dialogue_source_store.dart`
- `packages/map_authoring/lib/src/domains/narrative/narrative_authoring_exception.dart`
- `packages/map_authoring/lib/src/domains/narrative/script_actions.dart`
- `packages/map_authoring/lib/src/domains/narrative/script_authoring_service.dart`
- `packages/map_authoring/test/domains/narrative/dialogue_script_authoring_test.dart`
- `reports/analysis/pmcp_050_dialogue_script_authoring_evidence.md`
- `reports/analysis/pmcp_050_dialogue_script_authoring_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- `packages/map_authoring/lib/src/workspace/project_query_service.dart`
- `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- `packages/map_authoring/test/registry/action_registry_test.dart`
- `packages/map_authoring/test/workspace/project_snapshot_test.dart`

Le contenu intégral des fichiers texte créés, hors rapports auto-référents,
est reproduit dans l’annexe. Les zones modifiées sont celles du diff Git du
commit dédié.

## Tests et résultats exacts

TDD rouge initial :

```text
dart test test/domains/narrative/dialogue_script_authoring_test.dart
exit 1 — DialogueAuthoringCompiler, DialogueActions,
DialogueSimulationService, DialogueLegacyMigrationService,
ScriptAuthoringSimulator et AuthoringMutationDispatcher absents.
```

Tests ciblés finaux :

```text
dart test test/domains/narrative/dialogue_script_authoring_test.dart \
  test/workspace/project_snapshot_test.dart
00:00 +15: All tests passed!

cd packages/map_core && dart test \
  test/runtime_dialogue_document_test.dart \
  test/project_dialogue_declared_outcomes_test.dart \
  test/dialogue_library_tree_test.dart
00:00 +10: All tests passed!
```

Suite et analyses :

```text
cd packages/map_authoring && dart test
00:25 +256: All tests passed!

cd packages/map_authoring && dart analyze
Analyzing map_authoring...
No issues found!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

dart format --output=none --set-exit-if-changed lib test bin
Formatted 146 files (0 changed) in 0.44 seconds.

dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
exit 0, stdout/stderr vides.
```

Incidents de validation corrigés :

```text
Premier dart test authoring : 255 réussites, 1 échec ; attente registry
historique non mise à jour pour dialogue/dialogueSource/script.
Après correction : 256/256.

Première commande map_core ciblait deux chemins inexistants : exit 1.
Les trois chemins réels ont ensuite donné 10/10.
```

## Preuves de fin de lot

- Source cohérente : modifier uniquement `dialogues/intro.yarn` change la
  révision de projet et sa fingerprint de ressource.
- Transaction : `dialogue.source_update` passe par plan/apply puis undo ; les
  octets d’origine sont restaurés exactement.
- Yarn strict : `<<teleport town>>` produit `yarn.command_unknown`, ligne 4,
  au lieu d’être ignoré silencieusement.
- Outcome guard : retirer `accepted` est bloqué tant qu’une Scene consomme ce
  port ; un mapping explicite peut réécrire les références atomiquement.
- Migration : identité `intro` stable, nouvelle cible `.yarn`, token legacy
  rendu visible sans l’exécuter, source `.txt` conservée verbatim.
- Simulation : le choix `Refuser` rend transcript et outcome `refused` ; un
  `giveItem` de script devient un effet preview, jamais une mutation.
- Read-side : les sources/compilations dialogues et simulations scripts sont
  accessibles par les queries paginées existantes.

## Roadmap gameplay

Ce lot renforce la surface d’authoring utile aux familles `FG-080–FG-093` et
aux dialogues conditionnels, mais ne clôt aucun de leurs critères runtime ou
UI. Proposition : conserver tous leurs statuts actuels. Le roadmap n’est pas
modifié.

## Limites, risques et non-objectifs

- Le sous-ensemble Yarn exécutable reste celui de `map_core`; ce lot rend les
  commandes hors sous-ensemble explicites, il n’ajoute pas de langage caché.
- La simulation de script décrit les commandes et les chemins de contrôle ;
  elle ne simule pas un `GameState` concret et ne prétend pas prouver le
  résultat runtime de chaque effet.
- Le scan de suppression de script est conservateur et peut refuser une
  identité exacte ambiguë dans un document projet.
- L’ancien nom `MapMutationDispatcher` est conservé comme alias public pour ne
  pas casser les clients Phase 1–4.

## Auto-critique finale

La source Yarn est exposée en détail par la query, ce qui est indispensable à
l’édition mais peut être volumineux ; les limites de payload, field masks et
pagination de la Read API restent l’autorité. La migration conserve l’ancien
fichier hors manifeste : c’est volontaire pour l’undo et la non-perte, mais un
outil de nettoyage futur devra reconnaître ces sources orphelines au lieu de
les supprimer implicitement.

État Git final attendu après commit : changements PMCP-050 propres et commités,
avec les fichiers non suivis `.superpowers/...` externes toujours présents et
hors commit.
