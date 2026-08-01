# PERF-RM-03 — Plan d'implémentation topologie Surface O(P)

**Scope :** topologie pure partagée dans `map_core`, consommée une fois par résolution editor/runtime, avec filtrage viewport côté runtime. JSON, rôles et catalogues restent inchangés.

## Audit initial

- `resolveSurfaceVariantRoleForPlacement` reconstruit un `Set<String>` en parcourant toutes les placements à chaque cellule.
- Le runtime et les deux chemins preview éditeur appellent cet adapter dans une boucle, produisant O(P²).
- `resolveSurfaceVariantRoleAt` est déjà une primitive O(1) correcte et testée.
- `MapLayersComponent` possède déjà un rectangle local visible mais ne le transmet qu'après la création de toutes les instructions.

## Étapes test-first

- [ ] Étendre `surface_variant_role_resolver_test.dart` avec `SurfacePlacementTopology` : rôles par preset, trous/diagonales, duplicats, ordre, coordonnées invalides et iterable compté parcouru une seule fois.
- [ ] Exécuter le test et conserver RED sur le type absent.
- [ ] Construire en un passage une occupation groupée par preset avec clés coordonnées non allouantes ; exposer `roleAt` pur et conserver l'adapter historique pour compatibilité.
- [ ] Modifier runtime et preview statique pour construire une topologie par layer/résolution, puis l'injecter au resolver de tuile éditeur.
- [ ] Ajouter un viewport cellule optionnel au resolver runtime ; calculer les bornes depuis `_visibleLocalRect` avec halo d'une cellule.
- [ ] Ajouter/adapter tests editor/runtime pour égalité des rôles, catalog/atlas manquant, layer caché et exclusion viewport sans couture.
- [ ] Créer le benchmark AOT contractuel `benchmark/surface_role_scaling.dart`, avec CLI validée, warmups/samples, tailles et JSON dans le package.
- [ ] Mesurer 100/400/1024/2500 puis relancer tests complets/analyzers des trois packages.

## Non-objectifs et risques

- Aucun cache global mutable ni clé fondée sur l'identité d'objet ; la topologie vit le temps d'une résolution.
- Pas de nouvelle sémantique de peinture Surface, donc parité PMCP/JSONL/MCP : `N/A — contrat inchangé`.
- Le filtre viewport ne doit pas modifier la topologie : les voisins hors viewport restent présents dans l'index.

## Preuves attendues

- Iterable source parcouru une fois ; rôle identique sur fixtures existantes.
- 2 500 placements sous 5 ms p95 AOT sur la machine de preuve, pente documentée.
- Goldens editor/runtime inchangés et catalogue MCP live inchangé si vérifiable.

