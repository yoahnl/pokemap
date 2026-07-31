# PMCP-040 — Evidence Pack asset store et imports sûrs

Date : 2026-07-31
Lot : `PMCP-040 — Asset store et imports sûrs`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot introduit un registre d’assets content-addressed, une acquisition locale
bornée et protégée contre les symlinks sortants, les opérations
import/replace/move/delete, les queries list/get/search/detail/preview et leur
intégration complète au noyau Phase 3 : plan, CAS, permission, audit,
idempotence, transaction récupérable, historique et undo.

Le catalogue `assets/.pokemap-assets.json` et chaque blob sous
`assets/.pokemap-store/` participent à la révision cohérente du projet. Une
mutation externe du catalogue ou d’un blob ne peut donc pas rester invisible
à `expectedRevision`.

## Audit initial et continuité

État Git initial : arbre propre à `b44cc91ba feat(authoring): add world graph and map rendering`.

La première passe a constaté que `map_authoring` possédait déjà tous les
invariants nécessaires aux writes sûrs, mais que :

- le snapshot ne couvrait que `project.json` et les maps ;
- le dispatcher et l’API locale étaient encore nommés autour du seul domaine Map ;
- la Read API ne connaissait que `project` et `map` ;
- l’index de références existant était narratif uniquement ;
- un simple résultat en mémoire ne prouverait ni CAS, ni recovery, ni undo.

Le scope a donc été ajusté avant clôture : les assets sont des ressources
supplémentaires du snapshot, le dispatcher compose leurs builders asynchrones,
les références visuelles sont dérivées des JSON canoniques project/maps, et le
test principal traverse réellement l’API locale jusqu’à l’undo.

## Passes et verdicts

| Passe | Verdict | Signal |
|---|---|---|
| Audit / Architecture — agent assets | Conforme après corrections | A signalé snapshot, dispatcher, query, références et undo manquants dans le brouillon initial |
| Implémentation | Conforme | Quatre actions enregistrées et appliquées via `AuthoringMutationDraft` |
| Tests | Conforme | RED initial sur symboles absents, puis 8 tests ciblés verts |
| Build / Validation | Conforme | Suite package, analyse, format strict et exécutable JSONL verts |
| Critique finale | Conforme avec limites | MIME extensible et catalogue visuel spécialisé différés à PMCP-041/042 |

## Contrats et zones modifiées

- `artifact_ref.dart` : identité path-free, empreinte SHA-256 domainée, MIME,
  taille, handle et JSON strict.
- `artifact_store.dart` : port, store mémoire dédupliqué et import local avec
  racines autorisées, stat avant/après, taille et sniff MIME.
- `asset_store.dart` : registre stable, recherche, unused, groupes de doublons,
  chemins logiques canoniques et dérivation de références.
- `asset_actions.dart` : CRUD pur, descripteurs publics, parsing strict,
  projection de catalogue/blobs en change set et preview d’impact.
- `project_snapshot*.dart` : pré-images, storage keys privés, catalogue/blobs
  optionnels, double lecture et contrôle digest/taille.
- `map_mutation_dispatcher.dart` et `local_map_authoring_mutation_api.dart` :
  builders sync/async composés et artifact store injecté.
- `project_query_service.dart`, `authoring_read_api.dart` et
  `resource_kind_registry.dart` : resource kind `asset` et read-side complet.
- tests registry/golden : nouvelle surface publique attendue.

## Inventaire complet

Créés :

- `packages/map_authoring/lib/src/contracts/artifact_ref.dart`
- `packages/map_authoring/lib/src/domains/assets/asset_actions.dart`
- `packages/map_authoring/lib/src/domains/assets/asset_store.dart`
- `packages/map_authoring/lib/src/ports/artifact_store.dart`
- `packages/map_authoring/test/domains/assets/asset_security_test.dart`
- `packages/map_authoring/test/domains/assets/content_addressing_test.dart`
- `packages/map_authoring/tool/generate_evidence_appendix.dart`
- `pokemap_authoring_api_mcp_phase_5_implementation_plan.md`
- `reports/analysis/pmcp_040_secure_asset_store_evidence.md`
- `reports/analysis/pmcp_040_secure_asset_store_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart`
- `packages/map_authoring/lib/src/api/authoring_read_api.dart`
- `packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart`
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart`
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`
- `packages/map_authoring/lib/src/workspace/project_query_service.dart`
- `packages/map_authoring/lib/src/workspace/project_snapshot.dart`
- `packages/map_authoring/lib/src/workspace/project_snapshot_loader.dart`
- `packages/map_authoring/test/registry/action_registry_test.dart`
- `packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl`

Le contenu intégral de tous les fichiers texte créés, sauf les deux rapports
auto-référents, est fourni dans l’annexe générée. Les zones exactes des fichiers
modifiés sont celles du diff Git associé au commit dédié.

## Tests et résultats exacts

TDD rouge initial :

```text
dart test test/domains/assets/asset_security_test.dart test/domains/assets/content_addressing_test.dart
exit 1 — LocalArtifactStore, ArtifactStoreException, MemoryArtifactStore,
ContentArtifactRef, AssetCatalog, AssetRecord et AssetActions absents.
```

Tests ciblés après intégration :

```text
dart test test/domains/assets
00:00 +8: All tests passed!
```

Suite et analyse :

```text
dart test
00:15 +238: All tests passed!

dart analyze
Analyzing map_authoring...
No issues found!

dart format --output=none --set-exit-if-changed lib test bin
Formatted 131 files (0 changed) in 0.23 seconds.
```

Meilleure validation build pour ce package CLI pur Dart :

```text
dart run bin/pokemap_authoring.dart \
  --root ../../examples/playable_runtime_host </dev/null
exit 0, stdout/stderr vides.
```

## Preuves de fin de lot

- Symlink sortant : refus `artifact.source_outside_allowed_roots`.
- Contenu identique : même handle, une seule entrée de store, résultat
  `deduplicated: true`.
- Suppression référencée : références persistées et références dérivées des
  documents canoniques bloquent `asset.delete`.
- Undo exact : import appliqué, blob supprimé par action confirmée, puis undo
  via l’entry d’historique ; les octets restaurés sont strictement identiques.
- Stale/CAS : catalogue et blobs contribuent au snapshot et chaque change
  transporte sa pré-image et sa révision.
- Read-side : list/get/search/summary/detail, filtre, pagination générique et
  handle de preview sans chemin local.

## Limites, risques et non-objectifs

- Le sniff MIME couvre les signatures nécessaires au socle ; les codecs,
  dimensions et métadonnées avancées sont le scope de PMCP-042.
- Le registre de références est conservateur : il recherche les identités,
  handles, digests et chemins exacts dans project/maps. Les dépendances
  structurées tileset/élément/preset seront renforcées par PMCP-041.
- Le store mémoire est la composition locale par défaut. Un store durable ou
  distant pourra implémenter le port sans changer les handles publics.
- Aucun statut de roadmap n’est modifié. Aucun lot `FG-*` ne change de statut.

## Auto-critique finale

Le premier brouillon aurait surdéclaré l’undo et le stale-check : les bytes
étaient sûrs seulement dans un objet mémoire. L’extension du snapshot et le
test end-to-end corrigent cette faiblesse. Le nom historique
`MapMutationDispatcher` reste techniquement trompeur maintenant qu’il compose
un second domaine ; le renommage compatible vers un dispatcher générique sera
effectué avec PMCP-050/060, lorsque plusieurs domaines supplémentaires le
justifieront, afin d’éviter un refactor cérémoniel dans ce lot.

État Git final attendu après commit : arbre propre sur
`feat(authoring): add secure asset store`.
