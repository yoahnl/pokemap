# PMCP-053 — Evidence Pack Cinématiques et parité narrative

Date : 2026-07-31
Lot : `PMCP-053 — Cinématiques et gate de parité narrative`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot expose le lifecycle des cinématiques, l’édition atomique de leur
timeline, le presse-papiers versionné, le preflight partagé, un aperçu sans
effet de bord et une matrice explicite editor/API/runtime. Les douze types de
bloc ont une autorité runtime nommée ; les contraintes dépendant du host ne sont
pas présentées comme validées par l’API.

## Audit initial et verdicts

État Git initial suivi : propre à
`e419aa84 feat(authoring): add storyline and scenario authoring`. Le dossier
externe non suivi `.superpowers/.../smart-tiles-interactive` était déjà présent
et est resté hors scope et hors staging.

L’audit initial a trouvé les opérations lifecycle/timeline, le plan de preview
et le preflight dans `map_core`, ainsi que le controller et le sink Flame dans
`map_runtime`. Verdict : adapter ces autorités, ne pas réimplémenter les règles.

| Passe | Verdict | Signal |
|---|---|---|
| Audit assets | Sans impact | Aucun stockage média nouveau |
| Audit narratif | Conforme | Opérations et preflight core réutilisés |
| Audit gameplay/runtime | Conforme | Adapter runtime en lecture seule, sink inchangé |
| TDD | Conforme | RED sur façades absentes, puis preuves vertes |
| Tests authoring | Conforme | 269 tests passent |
| Tests core cinématique | Conforme | 177 tests passent |
| Tests runtime ciblés | Conforme | 11 tests passent |
| Analyses | Conforme | Trois analyses sans issue |

## Fichiers et zones modifiées

Créés :

- `packages/map_authoring/lib/src/domains/narrative/cinematic_actions.dart`
- `packages/map_authoring/lib/src/domains/narrative/narrative_parity_gate.dart`
- `packages/map_authoring/test/domains/narrative/cinematic_authoring_gate_test.dart`
- `packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_preview_adapter.dart`
- `packages/map_runtime/test/cinematic_runtime_preview_adapter_test.dart`
- `reports/analysis/pmcp_053_cinematic_authoring_gate_evidence.md`
- `reports/analysis/pmcp_053_cinematic_authoring_gate_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart` : exports publics.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart` :
  six mutations cinématiques enregistrées.
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart` :
  ressource `cinematic`.
- `packages/map_authoring/test/registry/action_registry_test.dart` : vérité
  exacte du registre mise à jour.
- `packages/map_runtime/lib/map_runtime.dart` : export de l’adaptateur preview.

L’annexe reproduit le contenu intégral des fichiers texte créés hors rapports
auto-référents. Le diff du commit dédié documente les zones exactes modifiées.

## Contrat livré

- Actions `cinematic.upsert`, `cinematic.delete`, `timeline_move`,
  `timeline_duplicate`, `timeline_paste` et `timeline_delete`.
- Copie pure via `copyTimelineSteps`, clipboard versionné et identités fraîches
  déterministes au paste/duplicate.
- Inspection auteur et preview runtime fondées sur
  `preflightCinematicPlayback` et `buildCinematicPreviewPlaybackPlan`.
- Gate de parité couvrant dialogue, script, Scene, Event V2, Fact, World Rule,
  Storyline, Scenario et les douze `CinematicTimelineStepKind`.
- Limites host explicites : acteurs Flame montés, map active, décodage média et
  disponibilité audio restent vérifiés par les adaptateurs runtime.

## Commandes et résultats exacts

```text
cd packages/map_authoring && dart test \
  test/domains/narrative/cinematic_authoring_gate_test.dart
RED initial : exit 1 — NarrativeParityGate, CinematicAuthoringInspector et
CinematicActions absents.
Résultat final : 00:00 +4: All tests passed!

cd packages/map_runtime && flutter test \
  test/cinematic_runtime_preview_adapter_test.dart
RED initial : compilation failed — CinematicRuntimePreviewAdapter absent.

cd packages/map_authoring && dart test
00:24 +269: All tests passed!

cd packages/map_authoring && dart analyze
Analyzing map_authoring...
No issues found!

cd packages/map_core && dart test \
  test/cinematic_authoring_operations_test.dart \
  test/cinematic_timeline_editing_operations_test.dart \
  test/cinematic_playback_preflight_test.dart \
  test/cinematic_preview_playback_plan_test.dart \
  test/cinematic_diagnostics_test.dart
00:01 +177: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!

cd packages/map_runtime && flutter test \
  test/cinematic_runtime_preview_adapter_test.dart \
  test/cinematic_runtime_playback_controller_test.dart
00:00 +11: All tests passed!

cd packages/map_runtime && flutter analyze
Analyzing map_runtime...
No issues found!
```

## Roadmap gameplay

Le lot apporte une preuve API/runtime aux familles `FG-080–FG-094`, mais ne
ferme pas les lots no-code/UI ni leurs parcours joueur. Les statuts restent
donc ceux du roadmap (`TODO` ou `PARTIAL` selon le lot). Aucun statut du roadmap
n’est modifié.

## Limites, risques et auto-critique

La matrice de parité est une vérité de capacités, pas une preuve qu’un asset
particulier fonctionnera sur une machine donnée. Le preflight runtime bloque
les références structurelles invalides ; le sink reste l’autorité finale pour
les handles d’acteurs et les médias décodés. Les marqueurs éditoriaux sont
considérés supportés parce que leur suppression runtime est planifiée et testée,
pas parce qu’ils produisent un effet visuel.

État Git final attendu : un commit PMCP-053 dédié ; le dossier externe non
suivi `.superpowers/...` reste non staged et non modifié.
