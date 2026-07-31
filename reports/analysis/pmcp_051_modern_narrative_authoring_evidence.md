# PMCP-051 — Evidence Pack authoring narratif moderne

Date : 2026-07-31
Lot : `PMCP-051 — Scene, Event V2, Facts et World Rules`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot expose treize mutations transactionnelles pour les Scenes, Events V2,
Facts typés et World Rules. La surface authoring ne recopie pas les décisions
du moteur : elle délègue publication/activation/suppression Event V2, typage et
suppression de Facts, validation/suppression de World Rules et suppression de
Scenes aux opérations canoniques de `map_core`.

Un inspecteur consolidé rend les diagnostics Scene, Event V2, World Rule et
dépendances, la reachability Event V2 ainsi que les trois autorités runtime
réelles. Les quatre ressources sont listables et inspectables par la Read API.

## Audit initial et continuité

État Git initial suivi du lot : arbre PokeMap propre à
`08cb4a5f feat(authoring): add dialogue and script authoring`.

L’audit narratif initial a conclu que `map_core` possédait déjà les opérations
pures et les consommateurs runtime nécessaires. Son verdict imposait donc une
façade d’adaptation, des gates de publication et une vérité consommateur, sans
réimplémenter les règles Scene/Event/Facts/World Rules dans `map_authoring`.

Des fichiers non suivis `.superpowers/brainstorm/...` issus d’un autre flux
restent explicitement hors périmètre, hors inspection et hors staging.

## Passes et verdicts

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture — agent narratif | Conforme | Réutilisation de `map_core`, dépendances et runtime truth exigées |
| TDD | Conforme | RED sur les quatre façades absentes, puis cinq preuves vertes |
| Implémentation | Conforme | 13 actions, 4 read kinds, inspection/gate consolidée |
| Tests | Conforme | 261 tests authoring et 93 tests core ciblés passent |
| Analyse / format | Conforme | `dart analyze` vert dans les deux packages, aucun format à appliquer |
| Critique finale | Conforme avec limites | L’upsert d’agrégat complète les opérations granulaires core sans les remplacer |

## Contrats et zones modifiées

- `scene_actions.dart` : upsert complet avec diagnostic/runtime plan et delete
  via l’index de dépendances canonique.
- `event_actions.dart` : draft, record upsert, publish/unpublish,
  activate/deactivate et delete revision-gated.
- `fact_rule_actions.dart` : create/update/delete des Facts et World Rules via
  les opérations pures existantes.
- `modern_narrative_inspection.dart` : gate de publication, dépendances,
  validation, reachability et vérité consommateur.
- `narrative_action_support.dart` : enveloppe transactionnelle partagée,
  sans règle métier.
- dispatcher, barrel, resource registry et query service : enregistrement et
  lecture des quatre nouveaux kinds.

## Inventaire complet

Créés :

- `packages/map_authoring/lib/src/domains/narrative/event_actions.dart`
- `packages/map_authoring/lib/src/domains/narrative/fact_rule_actions.dart`
- `packages/map_authoring/lib/src/domains/narrative/modern_narrative_inspection.dart`
- `packages/map_authoring/lib/src/domains/narrative/narrative_action_support.dart`
- `packages/map_authoring/lib/src/domains/narrative/scene_actions.dart`
- `packages/map_authoring/test/domains/narrative/modern_narrative_authoring_test.dart`
- `reports/analysis/pmcp_051_modern_narrative_authoring_evidence.md`
- `reports/analysis/pmcp_051_modern_narrative_authoring_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- `packages/map_authoring/lib/src/workspace/project_query_service.dart`
- `packages/map_authoring/test/registry/action_registry_test.dart`

Le contenu intégral des fichiers texte créés, hors rapports auto-référents,
est reproduit dans l’annexe. Les zones précises modifiées correspondent au
diff Git du commit dédié.

## Tests et résultats exacts

TDD rouge initial :

```text
dart test test/domains/narrative/modern_narrative_authoring_test.dart
exit 1 — ModernNarrativeInspector, SceneActions, EventV2Actions et
FactRuleActions absents.
```

Test ciblé final :

```text
dart test test/domains/narrative/modern_narrative_authoring_test.dart
00:00 +5: All tests passed!
```

Suite, analyse et format authoring :

```text
cd packages/map_authoring && dart test
00:14 +261: All tests passed!

cd packages/map_authoring && dart analyze
Analyzing map_authoring...
No issues found!

dart format --output=none --set-exit-if-changed lib test bin
Formatted 152 files (0 changed) in 0.24 seconds.
```

Non-régression des autorités `map_core` :

```text
cd packages/map_core && dart test \
  test/scene_authoring_operations_test.dart \
  test/narrative_event_publication_test.dart \
  test/narrative_event_activation_test.dart \
  test/narrative_event_record_operations_test.dart \
  test/narrative_event_reachability_report_test.dart \
  test/narrative_fact_authoring_operations_test.dart \
  test/world_rule_authoring_operations_test.dart
00:00 +93: All tests passed!

cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Incident corrigé : une première commande ciblait
`test/workspace/query_pagination_test.dart`, chemin inexistant ; le fichier
réel est `test/contracts/query_pagination_test.dart`. Cette erreur de commande
n’est pas une défaillance produit.

## Preuves de fin de lot

- Une Scene sans terminaison produit `scene.missingEndNode` et bloque la
  publication.
- Supprimer une Scene consommée par un Event V2 renvoie `sceneReferenced`.
- Publier un draft Event V2 incomplet renvoie le diagnostic canonique
  `sourceRequired`.
- Changer le type d’un Fact référencé est refusé après preview de dépendances.
- Les lifecycle Event V2 passent par leurs opérations revision-gated ; les
  actions génériques restent elles-mêmes protégées par la révision du snapshot.
- L’inspection cite `buildSceneRuntimePlan`,
  `NarrativeEventDispatchAuthority` et `projectWorldRuleEffects` comme
  autorités runtime, sans promouvoir de commande sans consommateur.
- `scene`, `eventV2`, `fact` et `worldRule` sont exposés par le registre et la
  query générique.

## Roadmap gameplay

Le lot contribue aux familles narratives `FG-080–FG-093`, sans fermer leurs
critères UI/runtime end-to-end. Proposition : conserver leurs statuts actuels.
Le roadmap gameplay n’est pas modifié.

## Limites, risques et non-objectifs

- `scene.upsert` et `event_v2.record_upsert` transportent volontairement un
  agrégat typé complet ; les opérations granulaires déjà présentes dans
  `map_core` restent l’autorité pour les éditeurs guidés.
- La reachability exposée sans snapshot runtime est honnêtement structurelle
  et peut produire un état runtime inconnu.
- Le lot ne modifie ni le runtime ni le use case historique de `map_editor` :
  la façade protocole-neutre est désormais disponible pour leur adaptation.

## Auto-critique finale

Le report consolidé peut répéter un problème à travers les diagnostics de
dépendances et ceux d’un domaine. Les codes et chemins restent stables, mais
une future couche MCP pourra dédupliquer la présentation sans altérer les
preuves sources. L’upsert Event accepte un draft incomplet pour permettre le
travail progressif ; seule sa publication/activation prétend à la sûreté
runtime.

État Git final attendu après commit : changements PMCP-051 propres et commités,
les fichiers externes `.superpowers/...` restant hors commit.
