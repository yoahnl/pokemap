# NSC-71 — Templates, duplication, clipboard typé et opérations bulk

Date : 2026-07-21

Statut proposé : **DONE**

## Audit initial et verdict

L'audit a confirmé que les workspaces ne partaient pas de zéro : Storylines,
chapters et steps possédaient déjà une duplication profonde ; Scenes
dupliquait asset et IDs internes ; Event V2 avait create/duplicate et un
catalogue Event+Scene transactionnel ; Cinematics possédait duplication,
sélection bulk tag/archive et historique document ; Dialogue dupliquait ses
nœuds ; Facts dupliquait ses définitions. Le manque transversal était le plan
de clone prévisible, le clipboard interprojet validé et l'unification des
gabarits Cinematic/WorldRule avec le registre NSC-38.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
manuelles Audit/Architecture, Core, Templates, UI Design System, Tests et
Critique sont **GO**. La passe Build reste **INCONCLUSIVE ENVIRONNEMENT** pour
la même raison attestée en NSC-70 : Flutter local 3.41.6, branche en API 3.44.

## Critères et preuves

| Critère NSC-71 | Preuve | Verdict |
|---|---|---|
| Clone shallow/deep | plan Core typé, fermeture des enfants possédés et dépendances deep explicites | GO |
| Preview références | chaque usage est marqué `preserved` ou `rewritten`, avec cible avant/après et path | GO |
| IDs sans collision | collision destination et collision interne au plan refusées | GO |
| Clipboard typé | entrées source/destination/payload, schema V1, liste de dépendances préservées | GO |
| Paste cross-project sûr | dépendance absente ou ambiguë à destination bloque `canPaste` | GO |
| Bulk atomique/réversible | snapshot before/after, sélection typée, apply/undo refusés sur état obsolète | GO |
| Catalogue unique versionné | le catalogue NSC-38 reste l'unique liste et passe à 14 gabarits schema V1 | GO |
| Event/Scene préservés | les 10 gabarits historiques restent filtrés dans l'Event Builder | GO |
| Cinematic authorable depuis gabarit | choix vide/plan d'établissement/dialogue et timeline initiale validée | GO |
| WorldRule authorable depuis gabarit | presets Fact→visibilité et Fact→dialogue préconfigurent les pickers guidés | GO |
| Undo bulk existant | Cinematics bulk passe par la session documentaire transactionnelle NSC-13 | GO |

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/narrative_asset_mutation.dart`
- `packages/map_core/test/narrative_asset_mutation_test.dart`
- `packages/map_editor/lib/src/application/services/narrative_template_catalog.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_template_sheet.dart`
- `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/facts_world_rules_manager_test.dart`
- `packages/map_editor/test/narrative_template_catalog_test.dart`

Les fichiers Storylines, Scenes, Event project list et Dialogue annoncés dans
la roadmap ont été audités mais non modifiés : leurs commandes de duplication
étaient déjà présentes et les toucher n'aurait ajouté qu'une seconde logique.

## Fichiers créés

- `packages/map_core/lib/src/authoring/narrative_asset_clone_plan.dart`
- `packages/map_core/test/narrative_asset_clone_plan_test.dart`
- `reports/narrativeStudio/completion/nsc_71_templates_clone_clipboard_bulk_evidence_pack.md`

Le contenu complet de chaque fichier créé est versionné dans le commit du lot.
Aucun cache ou artefact machine n'est inclus.

## Zones précises et décisions

### Plan de clone et clipboard

- Le planner consomme uniquement `NarrativeDependencyIndex` : aucun modèle UI,
  Flutter, filesystem ou parsing de texte lisible n'entre dans la décision.
- Un clone shallow conserve les références résolues ; un clone deep réécrit
  les assets sélectionnés et inclut automatiquement les définitions possédées
  (par exemple la hiérarchie d'une Storyline).
- Les IDs proposés sont previewés avant toute mutation. Les clés qualifiées
  conservent scope/sourceKind et réécrivent leur parent cloné.
- Le clipboard interne V1 contient des payloads typés par clé et ne peut pas
  être construit si un payload planifié manque.
- La validation de destination refuse collisions et dépendances préservées
  absentes/ambiguës ; aucune référence orpheline n'est masquée.

### Templates et UI

- `NarrativeTemplateCatalog` expose un `schemaVersion`, un ID stable, une
  cible (`eventScene`, `cinematic`, `worldRule`) et des paramètres lisibles.
- L'Event Builder filtre explicitement les dix gabarits Event/Scene : les
  nouveaux types ne peuvent pas fuiter dans son formulaire.
- Cinematics crée soit un shell vide, soit une timeline initiale réelle. La
  mutation Core accepte cette timeline et la soumet au validateur projet.
- World Rules applique les gabarits aux options réelles disponibles ; en
  absence de Fact/cible compatible, un feedback explicite bloque le parcours.
- Tous les nouveaux contrôles utilisent les primitives PokeMap existantes et
  aucun coloris ad hoc n'est ajouté.

### Bulk et undo

- `NarrativeBulkProjectMutation` fige opération, kind, sélection, before et
  after ; apply et undo exigent l'identité de valeur attendue.
- Les opérations bulk Cinematic existantes restent la mise en œuvre produit
  concrète pour tag/archive et passent par l'historique document commun. Le
  contrat Core permet à move et aux autres bibliothèques d'adopter la même
  porte sans inventer de snapshot local.

## TDD, commandes et résultats exacts

### Rouge observé

```text
dart test test/narrative_asset_clone_plan_test.dart
Compilation failed — APIs clone/clipboard/bulk absentes.

dart test test/narrative_asset_mutation_test.dart --plain-name \
  "NarrativeAssetMutation cinematic assets create accepts a validated template timeline"
Compilation failed — paramètre `timeline` absent.

flutter test --no-pub test/narrative_template_catalog_test.dart
Compilation failed — schema/targets/gabarits Cinematic et WorldRule absents.
```

### Vert Core

```text
cd packages/map_core
dart test test/narrative_asset_clone_plan_test.dart \
  test/narrative_asset_mutation_test.dart
+22: All tests passed!

dart analyze lib/src/authoring/narrative_asset_clone_plan.dart \
  lib/src/authoring/narrative_asset_mutation.dart \
  test/narrative_asset_clone_plan_test.dart \
  test/narrative_asset_mutation_test.dart
No issues found!
```

### Vert Editor disponible

```text
cd packages/map_editor
flutter test --no-pub test/narrative_template_catalog_test.dart \
  test/event_builder_v2_template_sheet_test.dart \
  test/design_system_guardrail_test.dart
+12: All tests passed!

flutter analyze --no-pub \
  lib/src/application/services/narrative_template_catalog.dart \
  lib/src/ui/canvas/events_v2/event_builder_v2_template_sheet.dart \
  lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart \
  lib/src/ui/canvas/narrative_workspace_canvas.dart \
  test/narrative_template_catalog_test.dart
No issues found! (ran in 11.1s)
```

L'analyse incluant `cinematics_library_workspace.dart` ne remonte que les trois
diagnostics liés à `ScrollCacheExtent` absent de Flutter 3.41. Une commande
groupée incluant `facts_world_rules_manager_test.dart` compile les huit tests
catalogue/Event puis échoue sur les imports de workspace Flutter 3.44 ; ce
n'est pas une défaillance des assertions NSC-71.

## Build

Le build macOS n'a pas été relancé après l'échec environnemental identique et
déjà capturé intégralement dans NSC-70. Commande de revalidation sous Flutter
3.44 :

```text
cd packages/map_editor
flutter test test/cinematics_library_workspace_test.dart \
  test/facts_world_rules_manager_test.dart
flutter analyze
flutter build macos --debug
```

## Risques, limites et auto-critique

- Le clipboard V1 est interne à la session ; il ne prétend pas être un format
  d'échange persistant ou public.
- Les assets Dialogue complets restent filesystem-owned : le studio duplique
  des nœuds, mais un export interprojet de fichiers Yarn est explicitement hors
  v1. Le clipboard refuse une destination sans définition Dialogue.
- Event V2 conserve son use case transactionnel fichier et n'est pas remplacé
  par une mutation manifest-only.
- Les gabarits WorldRule sélectionnent le premier Fact et la première cible
  compatibles, toujours visibles dans les pickers avant validation.
- Le clone planner previewe les réécritures ; l'application demeure confiée
  aux mutations spécialisées déjà testées afin de préserver leurs invariants.
- Aucun gain de temps ou pourcentage de productivité non mesuré n'est annoncé.

État Git initial : propre après `381e870b`. État avant commit : uniquement les
fichiers NSC-71 listés ci-dessus. `git diff --check` est propre.
