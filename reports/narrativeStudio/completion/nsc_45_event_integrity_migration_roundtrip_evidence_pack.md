# NSC-45 — Intégrité, migration et round-trip Events

Date : 2026-07-20

Verdict : **DONE proposé pour NSC-45 et pour la phase 4**

Roadmap : phase 4 Narrative Studio, sixième et dernier lot sur six

## Résumé exécutif

La migration Event présente maintenant, avant toute écriture, les claims, les
collisions, les références, les risques de perte bloqués et les choix confirmés.
Elle explique aussi pourquoi le lecteur historique doit rester actif et mesure
les cinq critères nécessaires à son retrait, sans basculer le projet ni
supprimer prématurément le dual-read.

Le wire canonique a été éprouvé de l'écriture JSON compatible Editor jusqu'au
loader runtime pour `mapEnter`, `triggerEnter`, `entityInteract` et
`outcomeReceived`. Chaque source atteint l'autorité Event V2 et sa Scene une
seule fois. Les preuves Selbrume couvrent désormais `dualRead`, doublon de la
même occurrence, rechargement de sauvegarde et projection `v2Only`, avec zéro
fallback legacy lorsque V2 détient l'occurrence.

Le projet Selbrume réel reste intentionnellement en `dualRead` : il ne contient
plus de `MapEvent` ni de claim legacy, mais contient encore deux sources
Scenario historiques et n'est pas encore explicitement `v2Only`. Le nouveau
diagnostic rend cet état visible ; NSC-45 ne ment donc pas en déclarant le
lecteur supprimable.

## Scope confirmé et non-objectifs

- Inclus : impact de migration fail-closed, diagnostic legacy actif, critère de
  retrait mesurable, preuve d'idempotence/recovery, round-trip quatre sources,
  absence de double dispatch, persistance terminale de l'outbox et builds.
- Réutilisé : planner, receipt, journal de promotion, claims, autorité de
  dispatch, transactions et loaders existants. Aucun second moteur Event n'a
  été créé pour le test ou l'Editor.
- Non modifié car déjà prouvé : l'algorithme de reprise journalisée et les
  lecteurs legacy. Les suites existantes les couvrent à chaque frontière
  d'écriture et sur les quatre formes de source historiques.
- Exclus : suppression physique du lecteur legacy, conversion forcée des deux
  sources Scenario Selbrume et toute fonctionnalité de phase 5.

## Audit initial

- `NarrativeEventMigrationPlanner` possédait déjà les données exhaustives mais
  aucune projection produit ne comptait impact, collisions ou blockers.
- La migration/promotion Selbrume était déjà atomique, attestée et reprenable ;
  il fallait réexécuter ces preuves, pas réécrire le protocole.
- Les bridges runtime appliquaient déjà l'autorité et la déduplication, mais il
  manquait une preuve unique traversant le disque pour les quatre sources.
- Le test canonique Selbrume conservait une empreinte antérieure au correctif
  phare déjà commité dans `d4c767aff`; l'empreinte a été réalignée sur les
  octets actuels avant de tester le nouveau scénario dual-read/v2Only.
- Risques audités : preview optimiste, comptage ambigu, perte inconnue, snapshot
  Editor/runtime différent, fallback legacy après prise d'autorité V2, replay
  d'outbox après reload et retrait legacy prématuré.

## État Git initial

- Branche : `main`.
- HEAD de départ NSC-45 : `feb6aa60d feat(narrative): add map events workspace`.
- Le redémarrage a retrouvé le brouillon NSC-45 non commité et des scripts
  locaux non suivis `.codex_tmp_*.py`, hors scope et jamais ajoutés.

## Inventaire complet et zones modifiées

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/compatibility/narrative_event_migration_plan.dart` | types `NarrativeEventLegacyRetirement*` et `NarrativeEventMigrationImpactPreview` | Contrat pur, fermé et immuable pour l'impact et les cinq critères de retrait. |
| `packages/map_core/lib/src/compatibility/narrative_event_migration_planner_impl.dart` | `previewImpact` | Dérive les comptes depuis le même input attesté et le même plan, sans inventer de décision UI. |
| `packages/map_core/test/narrative_event_migration_integrity_closure_test.dart` | tests impact/collision/perte/retrait et conservation de l'input | Prouve cas legacy, collision, donnée inconnue bloquée et projet v2Only propre. |
| `packages/map_editor/lib/src/application/models/narrative_event_migration_persistence_models.dart` | modèle `NarrativeEventMigrationPreview` | Transporte l'impact exact avec le plan prévisualisé. |
| `packages/map_editor/lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart` | assemblage input/plan/impact | Garantit que la feuille ne mélange pas deux snapshots. |
| `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart` | carte impact et callouts legacy/retrait | Rend claims, collisions, références, risques, choix et blockers lisibles sans JSON. |
| `packages/map_editor/test/ui/canvas/event_builder_v2_migration_sheet_test.dart` | quatre parcours widget | Prouve preview, commit, recovery et activation V2 séparée avec contenu scrollable. |
| `packages/map_runtime/test/narrative_event_v2_four_source_roundtrip_integration_test.dart` | fixture wire et dispatch runtime | Prouve les quatre sources, le loader disque, l'autorité, les Scenes et zéro fallback. |
| `packages/map_runtime/test/narrative_outcome_outbox_save_load_test.dart` | contrôle post-reload | Prouve qu'une livraison terminale persistée ne rejoue jamais le dispatcher. |
| `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart` | dualRead/v2Only, doublons et fingerprint | Prouve une seule exécution sur Selbrume dans les deux modes et réaligne l'attestation canonique. |
| `docs/superpowers/plans/2026-07-20-nsc-45-event-integrity-migration-roundtrip.md` | micro-plan | Fige les frontières TDD, le gate et le critère de retrait. |

Les tests de persistance/recovery Editor, de caractérisation legacy Runtime et
d'intégration Selbrume trois sources ont été exécutés sans modification : leur
comportement satisfaisait déjà les critères correspondants de la roadmap.

## Trail TDD et corrections observées

1. Les tests impact ont d'abord échoué faute de `previewImpact` et des types de
   retrait ; le contrat core puis la projection Editor ont rendu le lot vert.
2. Le round-trip quatre sources a d'abord révélé un import runtime absent, puis
   un outcome non déclaré par sa Scene productrice. La fixture a été corrigée
   avec un `SceneEndPayload` et un outcome qualifié réels.
3. L'élargissement du test Selbrume a stoppé sur l'ancien SHA-256. `git show` a
   confirmé que le manifest courant avait déjà changé dans `d4c767aff`; seule
   l'attestation du test était obsolète.
4. L'analyse Runtime a signalé un constructeur constifiable, puis les `const`
   imbriqués devenus inutiles ; les deux passes ont été corrigées avant la
   validation finale.

## Tests, analyses et builds — résultats exacts

```text
cd packages/map_core
dart test test/narrative_event_migration_integrity_closure_test.dart \
  test/narrative_event_migration_planner_test.dart
+81: All tests passed!

dart test
code de sortie 0, suite complète passée

dart analyze
Analyzing map_core...
No issues found!

cd packages/map_editor
flutter test test/ui/canvas/event_builder_v2_migration_sheet_test.dart \
  test/narrative_event_migration_preview_use_case_test.dart
+18: All tests passed!

flutter test test/ui/canvas/event_builder_v2_migration_sheet_test.dart \
  test/narrative_event_migration_preview_use_case_test.dart \
  test/selbrume_event_v2_persistence_migration_test.dart \
  test/selbrume_event_v2_promotion_recovery_test.dart \
  test/narrative_event_v2_mode_activation_test.dart
code de sortie 0 ; recovery à chaque frontière, fixture byte-identique et
activation séparée passés

flutter analyze \
  lib/src/application/models/narrative_event_migration_persistence_models.dart \
  lib/src/application/use_cases/narrative_event_migration_preview_use_case.dart \
  lib/src/ui/canvas/events_v2/event_builder_v2_migration_sheet.dart \
  test/ui/canvas/event_builder_v2_migration_sheet_test.dart
Analyzing 4 items...
No issues found! (ran in 3.1s)

flutter analyze
11 warnings existants, tous dans
lib/src/ui/canvas/dialogue_studio/dialogs/dialogue_studio_dialogs.dart ;
aucun dans le lot NSC-45

flutter build macos --debug
✓ Built build/macos/Build/Products/Debug/map_editor.app

cd packages/map_runtime
flutter test test/narrative_event_v2_four_source_roundtrip_integration_test.dart \
  test/narrative_event_legacy_runtime_characterization_test.dart \
  test/selbrume_event_v2_three_source_integration_test.dart \
  test/narrative_outcome_outbox_save_load_test.dart
+11: All tests passed!

flutter test test/narrative_event_v2_four_source_roundtrip_integration_test.dart \
  test/narrative_outcome_outbox_save_load_test.dart
+2: All tests passed!

flutter analyze
Analyzing map_runtime...
No issues found! (ran in 4.5s)

cd examples/playable_runtime_host
flutter test test/selbrume_event_v2_promoted_project_test.dart
+1: All tests passed!

flutter analyze test/selbrume_event_v2_promoted_project_test.dart
No issues found! (ran in 3.4s)

flutter build macos --debug
code de sortie 0 ; artifact produit :
build/macos/Build/Products/Debug/playable_runtime_host.app

git diff --check
<aucune sortie>

audit `Color(0x` / `Colors.` de la migration sheet
<aucune couleur brute>
```

Le build host émet uniquement un warning Swift de dépendance sur
`allowedFileTypes`, déprécié depuis macOS 12 ; il ne provient pas du lot.

## Critère mesurable de retrait legacy

Le retrait physique du lecteur legacy n'est autorisé que si, pour chaque projet
livré :

1. le mode est explicitement `v2Only` ;
2. aucun `MapData.events` historique ne subsiste ;
3. aucun nœud source Scenario historique ne subsiste ;
4. aucun claim de compatibilité ne subsiste ;
5. aucun blocker, mapping bloquant ou donnée legacy inconnue ne subsiste ;
6. la matrice quatre sources/no-double-dispatch reste verte.

État Selbrume mesuré pendant ce lot : `dualRead`, `0` MapEvent, `2` sources
Scenario historiques et `0` claim. Le retrait n'est donc pas encore proposé.

## Passes locales nommées

| Passe | Verdict |
|---|---|
| Audit / Architecture | PASS : le planner et l'autorité existants restent les uniques sources de vérité. |
| Implémentation | PASS : preview fail-closed, cinq critères mesurables et UI exclusivement Design System. |
| Migration / Recovery | PASS : preview byte-identique, reprise journalisée et protections d'altération réexécutées. |
| Runtime / Round-trip | PASS : quatre sources disque/runtime et dualRead/v2Only sans double dispatch. |
| Build / Analyse | PASS pour le scope ; dette globale Editor de 11 warnings préexistants explicitement conservée. |
| Critique finale | PASS avec limite : le lecteur legacy reste nécessaire pour Selbrume tant que ses deux sources Scenario ne sont pas converties. |

Les sous-agents n'ont pas été utilisés : l'instruction d'exécution de cette
session interdit la délégation proactive. Les passes indépendantes ci-dessus
remplissent la revue multi-angle locale exigée par `codex_rule.md`.

## Fichiers créés — contenu et attestation

| Fichier créé | Lignes | SHA-256 avant commit |
|---|---:|---|
| `docs/superpowers/plans/2026-07-20-nsc-45-event-integrity-migration-roundtrip.md` | 31 | `4a49c471f9b1d74e2b3015335741969697a5660522de8c9d0e52a3816869e25d` |
| `packages/map_runtime/test/narrative_event_v2_four_source_roundtrip_integration_test.dart` | 324 | `f4d504bb1d7594dd585a8732668eedb40806c8ce5148ba5bac7b4c5c616d8856` |

Le test runtime créé est intégralement suivi dans le même commit. Ses 324 lignes
sont attestées par l'empreinte ci-dessus afin d'éviter une copie divergente dans
le rapport. Il écrit `ProjectManifest.toJson` et `MapData.toJson`, recharge les
deux fichiers par `loadRuntimeMapBundle`, construit le snapshot réel puis passe
par les bridges/coordinator/outbox de production.

### Contenu intégral du micro-plan

```markdown
# NSC-45 — Intégrité, migration et round-trip Events

## Objectif

Fermer la phase 4 avec une migration explicable et fail-closed, une preuve disque/runtime des quatre sources Event et un critère mesurable de retrait du chemin legacy, sans supprimer ce chemin prématurément.

## Frontières

- Conserver la lecture `legacyOnly` et `dualRead` tant que le critère de retrait n'est pas satisfait.
- Ne jamais présenter un risque de perte ou une collision comme automatiquement résolu.
- Réutiliser l'autorité de dispatch, les claims et les transactions existants ; aucun second dispatcher de test ou d'éditeur.
- Le round-trip écrit le wire canonique compatible editor puis le recharge par le loader runtime.
- Ne pas commencer la phase 5.

## Plan TDD

1. Ajouter les tests rouges d'impact migration : claims, collisions, références, risques de perte, choix et diagnostic legacy actif.
2. Ajouter un assessment de retrait legacy mesurable au planner et le projeter dans la preview Editor.
3. Étendre la sheet no-code avec ces impacts, les blockers et les critères restants.
4. Renforcer les preuves d'idempotence/recovery sur la migration/promotion Selbrume.
5. Créer le round-trip disque/runtime des sources `mapEnter`, `triggerEnter`, `entityInteract` et `outcomeReceived`.
6. Prouver sur le projet promu qu'un Event V2 gère l'occurrence une seule fois en `dualRead`, après reload, puis en `v2Only`, sans fallback legacy.
7. Rejouer caractérisation legacy, outbox save/load, suites ciblées, analyses et builds macOS.

## Critère de retrait legacy

Le chemin legacy ne pourra être retiré que lorsque chaque projet livré est en `v2Only`, ne contient plus aucun MapEvent/Scenario source historique ni claim de compatibilité, n'a aucun blocker de migration, et que la matrice runtime quatre-sources/no-double-dispatch reste verte. NSC-45 mesure ce critère mais ne supprime pas encore le lecteur.

## Gate

Un projet historique peut être prévisualisé et migré sans perte silencieuse, les quatre sources survivent au disque et s'exécutent via l'autorité runtime, et le dual-read ne double jamais l'exécution.
```

Le présent Evidence Pack est lui-même un fichier créé et contient son propre
contenu intégral.

## Auto-critique, limites et risques

- Le compteur `migrationBlockerCount` est un indicateur conservateur : un même
  problème peut contribuer via diagnostic, mapping et statut. C'est voulu pour
  ne jamais déclarer le retrait prêt ; l'UI l'emploie comme nombre de blockers,
  pas comme nombre de causes racines uniques.
- Le test quatre sources vit dans `map_runtime` et écrit le wire produit par les
  modèles canoniques, tandis que les tests Editor prouvent séparément la
  persistance byte-identique. Cette composition respecte la frontière de
  packages sans faire dépendre Runtime de l'Editor.
- La projection `v2Only` Selbrume du test ne réécrit pas le projet réel. Elle
  prouve la matrice de dispatch ; le vrai basculement restera une action produit
  explicite après conversion des deux sources Scenario.
- Les 11 warnings de `dialogue_studio_dialogs.dart` empêchent de qualifier
  l'analyse Editor globale de propre. Ils sont antérieurs, sans chevauchement,
  et l'analyse ciblée du lot est propre ; ils devront être traités dans un lot
  dédié plutôt que cachés dans NSC-45.
- Le SHA-256 Selbrume atteste le manifest courant après le correctif phare déjà
  livré. Toute future modification intentionnelle du demonstrateur devra mettre
  à jour cette preuve avec le diff de données correspondant.

## État Git final attendu

- Un commit NSC-45 contient uniquement les onze fichiers de l'inventaire et ce
  rapport ; le micro-plan ignoré est ajouté explicitement.
- Les scripts locaux `.codex_tmp_*.py` et leurs caches restent exclus.
- Aucun push n'est effectué.
- Phase 5 non commencée.

## Gate de phase 4

**PASS** : les lots NSC-40 à NSC-45 sont commités. Toute source réelle d'une map
est visible dans Map Events, navigable vers sa géométrie, rattachable avec les
pickers Event Builder et simulable via l'autorité canonique ; migration,
persistance et runtime disposent désormais des preuves de fermeture.
