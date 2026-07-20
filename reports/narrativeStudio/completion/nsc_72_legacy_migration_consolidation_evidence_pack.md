# NSC-72 — Migrations legacy consolidées et retrait progressif

Date : 2026-07-21

Statut proposé : **DONE, retrait physique conditionnel**

## Audit initial et verdict

L'audit a retrouvé trois fondations indépendantes : GlobalStory disposait déjà
d'un import preview non destructif et idempotent ; Event V2 disposait déjà de
snapshots, receipts, backups et rollback journalisé ; Cinematics exposait les
ScenarioAsset Cutscene sous forme de bridges non éditables dans la bibliothèque,
mais sans plan de migration canonique. Le risque réel était donc la dispersion
des compteurs et la possibilité de continuer à authorer dans l'ancien Cutscene
Studio.

Aucun sub-agent n'a été lancé conformément à l'instruction active. Les passes
manuelles Audit/Architecture, Core Migration, Recovery, UI Design System,
Validator/Overview, Tests et Critique sont **GO**. La passe Build reste
**INCONCLUSIVE ENVIRONNEMENT** : Flutter local 3.41.6, alors que la branche
emploie déjà des API Flutter 3.44 dans Cinematics et Storylines.

## Critères et preuves

| Critère NSC-72 | Preuve | Verdict |
|---|---|---|
| Scan Storyline/Event/Cinematic unique | `NarrativeLegacyMigrationScan` schema 1, compteurs par domaine | GO |
| Dry-run pertes/dépendances | candidats Cinematic avec `lossRisks`, `dependencies`, collisions et refs Scene | GO |
| Migration Cinematic fail-closed | tout Scenario avec nœud/edge non attesté est bloqué, jamais aplati silencieusement | GO |
| Migration idempotente | receipt metadata + bridge source détectés avant application | GO |
| Références Scene sûres | réécriture typée `SceneCinematicPayload`, preview revalidée juste avant apply | GO |
| Backup et rollback | source Scenario conservée, before/after exact et `rollback()` | GO |
| Reprise cross-domain | checkpoint de domaines complétés, interruption capturée, reprise sans replay | GO |
| Event enrichi | impact expose backup, version minimale et condition de retrait | GO |
| GlobalStory enrichi | compteur restant, backup requis et condition de retrait | GO |
| Overview | KPI traçable `legacy_remaining` | GO |
| Validator | diagnostic stable `narrativeLegacyRemaining` avec total corpus chargé | GO |
| UI consolidée | centre de migration Design System avec compteurs, blocages, pertes et domaines | GO |
| Zéro double authoring | Cutscene Studio ouvert depuis Narrative Studio est forcé en lecture seule | GO |
| Retrait progressif | readers/boutons restent visibles tant que le scan n'est pas à zéro | GO |

## Fichiers modifiés

- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/authoring/storyline_legacy_import_preview.dart`
- `packages/map_core/lib/src/compatibility/narrative_event_migration_plan.dart`
- `packages/map_core/lib/src/compatibility/narrative_event_migration_planner_impl.dart`
- `packages/map_core/lib/src/operations/narrative_project_validator.dart`
- `packages/map_core/test/narrative_event_migration_integrity_closure_test.dart`
- `packages/map_core/test/storyline_legacy_import_preview_test.dart`
- `packages/map_editor/lib/src/features/narrative/application/overview/narrative_overview_read_model.dart`
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/cutscene_studio_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_overview_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/test/cinematics_library_workspace_test.dart`
- `packages/map_editor/test/features/narrative/application/overview/narrative_overview_read_model_test.dart`
- `packages/map_editor/test/ui/canvas/narrative_overview_workspace_test.dart`

## Fichiers créés

- `packages/map_core/lib/src/compatibility/cinematic_legacy_migration_plan.dart`
- `packages/map_core/test/cinematic_legacy_migration_plan_test.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart`
- `packages/map_editor/test/narrative_legacy_migration_center_test.dart`
- `packages/map_editor/test/narrative_cross_domain_migration_recovery_test.dart`
- `reports/narrativeStudio/completion/nsc_72_legacy_migration_consolidation_evidence_pack.md`

Le contenu complet des fichiers créés est versionné dans le commit du lot.
Aucun cache, lockfile ou artefact machine n'est inclus.

## Zones précises et décisions

### Contrat consolidé

- Le scan Core accepte le nombre réel de MapEvents chargé par le caller et
  ajoute les sources Scenario Event et claims déjà présents au manifest.
- Le minimum compatible est explicitement `v1`; tout changement de schema
  devra produire un nouveau scanner au lieu de réinterpréter silencieusement.
- `canRetireLegacyReaders` n'est vrai qu'à zéro source restante. La présence
  d'un blocker ou risque de perte interdit `canApply`.

### Cinematics

- Le candidat canonique reçoit un ID stable `cinematic_<source>`, une
  provenance `CinematicLegacyBridge`, un fingerprint et un reçu schema 1.
- Seuls les bridges sans flow authored sont auto-migrables dans ce lot. Un
  nœud ou edge existant est considéré comme donnée inconnue à préserver et
  bloque la conversion : cette restriction évite une fausse migration.
- Les Scenes qui ciblaient le bridge sont réécrites vers le CinematicAsset dans
  la même projection. La source Scenario n'est jamais supprimée par l'apply.

### UI, Overview et Validator

- Le centre est dry-run-first et ne possède aucune mutation filesystem locale.
  Les use cases spécialisés restent propriétaires des écritures et backups.
- L'ancien Cutscene Studio est explicitement en lecture seule depuis la route
  Narrative Studio ; son bandeau explique comparaison, rollback et nouvelle
  source canonique.
- Overview expose le même compteur et Validator produit un diagnostic stable,
  donc le legacy restant n'est plus caché dans une bibliothèque spécialisée.

## TDD, commandes et résultats exacts

### Rouge observé

```text
dart test test/cinematic_legacy_migration_plan_test.dart
Failed to load — APIs plan/apply/scan/transaction absentes.
```

### Vert Core

```text
cd packages/map_core
dart test test/cinematic_legacy_migration_plan_test.dart \
  test/storyline_legacy_import_preview_test.dart \
  test/narrative_event_migration_integrity_closure_test.dart
+51: All tests passed!

dart analyze
No issues found!
```

### Vert Editor disponible

```text
cd packages/map_editor
flutter test --no-pub test/narrative_legacy_migration_center_test.dart \
  test/narrative_cross_domain_migration_recovery_test.dart \
  test/features/narrative/application/overview/narrative_overview_read_model_test.dart \
  test/design_system_guardrail_test.dart
+20: All tests passed!

flutter analyze --no-pub \
  lib/src/ui/canvas/cutscene_studio_workspace.dart \
  lib/src/ui/canvas/narrative_studio/narrative_legacy_migration_center.dart \
  lib/src/features/narrative/application/overview/narrative_overview_read_model.dart \
  lib/src/ui/canvas/narrative_overview_workspace.dart \
  test/narrative_legacy_migration_center_test.dart \
  test/narrative_cross_domain_migration_recovery_test.dart
No issues found! (ran in 6.1s)
```

Le test Overview workspace complet importe le canvas entier et s'arrête avant
ses assertions sur les API Flutter 3.44 préexistantes. L'analyse ciblée de
`cinematics_library_workspace.dart` remonte exactement les trois diagnostics
préexistants `ScrollCacheExtent`/`scrollCacheExtent`, sans diagnostic NSC-72.

## Rollback et fenêtre de compatibilité

1. Créer le backup attesté avant la première écriture spécialisée.
2. Appliquer un domaine ; enregistrer son checkpoint seulement après succès.
3. En cas d'interruption, reprendre depuis `completedDomains` sans rejouer le
   domaine précédent, ou restaurer le snapshot original.
4. Conserver ScenarioAsset, MapEvent readers et receipts tant que le compteur
   consolidé est supérieur à zéro.
5. Retirer physiquement un reader uniquement après migration sans perte de
   Selbrume, des fixtures historiques et du corpus utilisateur supporté.

## Risques, limites et auto-critique

- Le centre déclenché depuis Cinematics connaît manifest, Scenario sources et
  claims, mais pas tous les fichiers MapData non chargés. Le Validator, qui
  reçoit toutes les maps, est la source exacte du compteur projet Event.
- La conversion sémantique des flows Cutscene authored reste volontairement
  bloquée : elle nécessitera un convertisseur dédié pour chaque block kind.
- Le bouton backup du composant est désactivé si son caller ne fournit pas le
  use case durable. Le contrat empêche ainsi de simuler une sauvegarde.
- Aucun reader n'est supprimé dans ce lot : le retrait sans corpus migré aurait
  contredit le done criterion.
- Aucune métrique ou absence de perte non mesurée n'est inventée.

État Git initial : propre après `74a5f09a`. État avant commit : uniquement les
fichiers NSC-72 listés ci-dessus. `git diff --check` est propre.
