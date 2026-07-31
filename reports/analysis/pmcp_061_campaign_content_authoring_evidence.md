# PMCP-061 — Evidence Pack Contenus de campagne

Date : 2026-07-31
Lot : `PMCP-061 — Contenus de campagne et vérité runtime`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot expose un CRUD transactionnel commun pour tables de rencontres,
boutiques, badges, trainers et personnages, ainsi que la mise à jour de New
Game. Les mutations utilisent les modèles et `ProjectValidator` de `map_core`,
bloquent les suppressions encore référencées et produisent un preview de
publication.

Une matrice nomme l’autorité runtime de moves, abilities, items et de chaque
famille de campagne. Les abilities restent explicitement `partial` : seuls les
effets enregistrés dans `map_battle` s’exécutent.

## Audit initial et verdicts

État Git initial du scope : commit `554b2866 feat(authoring): add pokemon
catalog authoring`. L’audit gameplay a retrouvé les modèles persistants dans
`map_core`, les services New Game/boutiques dans `map_gameplay`, et les
consommateurs trainers/personnages/récompenses dans `map_runtime`.

| Passe | Verdict | Signal |
|---|---|---|
| Audit gameplay | Conforme | Modèles et consommateurs réels identifiés |
| TDD | Conforme | RED sur trois façades, puis 4 preuves vertes |
| Tests authoring | Conforme | 277 tests passent |
| Tests core ciblés | Conforme | 44 tests passent |
| Tests gameplay ciblés | Conforme | 66 tests passent |
| Tests runtime ciblés | Conforme | 13 tests passent |
| Analyses | Conforme | authoring/core/gameplay/runtime sans issue |

Une première exécution authoring lancée en concurrence avec plusieurs suites a
vu `cli_golden_test.dart` échouer ; le test isolé a passé `+4`, puis la suite
complète séquentielle a passé `+277`. Ce signal de concurrence est documenté,
pas masqué. Les modifications externes `map_editor` et `.superpowers/...`
restent hors scope et hors staging.

## Fichiers et zones modifiées

Créés :

- `packages/map_authoring/lib/src/domains/gameplay/campaign_content_actions.dart`
- `packages/map_authoring/test/domains/gameplay/campaign_content_authoring_test.dart`
- `reports/analysis/pmcp_061_campaign_content_authoring_evidence.md`
- `reports/analysis/pmcp_061_campaign_content_authoring_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart` : export public.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart` :
  onze actions enregistrées.
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart` :
  ressource `campaignContent`.
- `packages/map_authoring/test/registry/action_registry_test.dart` : registre
  exact mis à jour.

L’annexe reproduit les deux fichiers créés hors rapports. Le diff du commit
dédié fournit les zones exactes des fichiers modifiés.

## Commandes et résultats exacts

```text
cd packages/map_authoring && dart test \
  test/domains/gameplay/campaign_content_authoring_test.dart
RED initial : CampaignContentActions, CampaignContentKind et
CampaignContentInspector absents.
Résultat final : 00:00 +4: All tests passed!

cd packages/map_authoring && dart test
00:24 +277: All tests passed!

cd packages/map_authoring && dart analyze
Analyzing map_authoring...
No issues found!

cd packages/map_core && dart test [9 tests campagne ciblés]
00:01 +44: All tests passed!
cd packages/map_core && dart analyze
No issues found!

cd packages/map_gameplay && dart test \
  test/new_game_state_builder_test.dart \
  test/project_new_game_state_builder_test.dart \
  test/shop_operations_test.dart test/shop_state_resolver_test.dart
00:00 +66: All tests passed!
cd packages/map_gameplay && dart analyze
No issues found!

cd packages/map_runtime && flutter test \
  test/trainer_battle_request_test.dart \
  test/player/runtime_shop_service_test.dart \
  test/playable_map_game_project_new_game_boot_test.dart
00:00 +13: All tests passed!
cd packages/map_runtime && flutter analyze
No issues found!
```

## Roadmap gameplay

Le lot renforce directement `FG-010–FG-016`, `FG-060–FG-079`,
`FG-100–FG-108` et `FG-140–FG-147`. Ces lots gardent leur statut actuel tant
que leurs DoD UI/runtime globaux ne sont pas tous rejoués. Aucun statut du
roadmap n’est modifié.

## Limites, risques et auto-critique

Le blocage de suppression recherche une chaîne exacte dans le manifeste et les
maps : il privilégie la sûreté et peut donc bloquer un homonyme sans relation
sémantique. Une future indexation typée pourra réduire ce faux positif. La
matrice runtime décrit la capacité de la plateforme, pas la validité de chaque
catalogue externe ; PMCP-060 reste la gate structurelle des documents.

État Git final attendu : un commit PMCP-061 dédié ; changements concurrents
hors scope non staged.
