# PMCP-081 — Migration des mutations de l'éditeur

Date : 2026-07-31
Lot : `PMCP-081` — migrer les mutations éditeur vers l'API d'authoring canonique
Verdict proposé : **PARTIAL**

## Résultat

Le chemin produit de sauvegarde d'une map passe désormais par `AuthoringMutationAdapter`, puis par le protocole canonique `plan -> apply -> receipt`. La sauvegarde conserve la détection de conflit optimiste de l'éditeur, expose les reçus d'authoring à l'interface et partage la session de lecture PMCP-080. Les contrats d'idempotence, d'undo et de présentation des erreurs ont une preuve automatisée.

Le lot reste `PARTIAL` : les mutations spécialisées (création/renommage/suppression de maps, assets, spatial, narration et gameplay) disposent d'un accès générique via l'adaptateur, mais leurs écrans produit n'ont pas tous été redirigés. L'undo/redo canonique n'est pas encore exposé comme commande globale dans l'UI.

## Audit initial

- Base fonctionnelle : commit `ca5c6c72d` (`PMCP-080`).
- Pendant le travail, une modification externe a avancé `HEAD` à `11e6bf6ad` et a continué à modifier les fichiers Smart Tiles ; ces changements n'appartiennent pas à ce lot.
- Le chemin de sauvegarde produit utilisait `SaveMapUseCase -> MapRepository.saveMapRevisioned`, sans reçu canonique.
- Les exceptions de concurrence existaient déjà sous la forme `EditorConflictException` et devaient être préservées pour ne pas modifier le comportement UI.
- Des écritures directes subsistaient dans plusieurs domaines ; un inventaire exécutable était nécessaire avant d'affirmer une parité totale.

## Passes de contrôle et verdicts

Aucun sub-agent n'a été lancé : la contrainte active de la session interdit la délégation non explicitement demandée. Les cinq passes locales exigées par le protocole de rapport ont été exécutées.

1. **Architecture** — `PASS` pour la frontière ajoutée : l'adaptateur est dans `application/authoring_api`, sans Flutter ni `dart:io`, et compose les APIs canoniques de `map_authoring`.
2. **Contrats de mutation** — `PASS` : plan sans écriture, apply, rejeu idempotent, conflit CAS, undo exact et reçus sont couverts.
3. **Intégration produit** — `PASS` sur `map.save` : le provider injecte l'adaptateur et `EditorNotifier` affiche le reçu canonique.
4. **Régression** — `PASS` sur la matrice ciblée de 20 tests et l'analyse statique ; le build macOS debug réussit.
5. **Périmètre** — `PARTIAL` : l'inventaire automatisé classe encore cinq puits d'écriture produit/transaction à migrer ou supprimer avant une parité complète.

## Décisions

- Conserver les constructions directes de `SaveMapUseCase` compatibles avec les tests/fakes historiques ; seul le provider produit injecte le chemin canonique.
- Traduire les conflits de l'API en `EditorConflictException` afin de conserver le flux de rechargement existant.
- Comparer la révision brute attendue aux octets frais de la map avant `plan`, puis invalider le snapshot de lecture après `apply`.
- Utiliser un plan applicable (`dryRun: false`) : `plan` reste non-mutant ; un plan `dryRun: true` est volontairement non applicable par le contrat canonique.
- Présenter les erreurs et reçus via un composant indépendant de Flutter, avec conservation du code machine et de la remédiation.
- Rendre la dette restante explicite et testée au lieu de prétendre à une migration exhaustive.

## Fichiers modifiés

### Créés

- `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` — façade de mutation canonique, sessions par racine, CAS, undo et recovery.
- `packages/map_editor/lib/src/application/authoring_api/editor_receipt_presenter.dart` — feedback no-code dérivé des reçus et erreurs.
- `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart` — preuve fonctionnelle des contrats.
- `packages/map_editor/test/authoring_api/editor_write_boundary_test.dart` — inventaire/garde-fou des écritures directes.
- `reports/analysis/pmcp_081_editor_mutation_migration_evidence.md` — présent rapport.
- `reports/analysis/pmcp_081_editor_mutation_migration_evidence_appendix.md` — contenu intégral des fichiers créés.

### Modifiés

- `packages/map_editor/lib/src/infrastructure/authoring_api/editor_project_file_reader.dart` — résolution canonique de la racine projet et implémentation du port transactionnel.
- `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` — délégation optionnelle de `SaveMapUseCase` à l'adaptateur canonique.
- `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` — providers et cycle de vie de l'adaptateur/presenter.
- `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart` — injection produit de l'adaptateur.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` — feedback de sauvegarde fondé sur le reçu.

Le contenu complet des quatre fichiers source/test créés est reproduit dans l'appendice. Les deux rapports ne sont pas reproduits récursivement.

## Zones précises modifiées

- `EditorProjectFileReader` : recherche ascendante de `project.json`, canonicalisation de la racine et lecture transactionnelle commune.
- `AuthoringMutationAdapter` : ouverture/mise en cache des sessions, `plan`, `confirm`, `apply`, `undo`, `recover`, et spécialisation `saveMap`.
- `SaveMapUseCase.executeRevisioned` : bifurcation vers l'API canonique lorsqu'elle est injectée, avec fallback historique explicite.
- `repository_providers.dart` / `map_use_case_providers.dart` : construction, injection et fermeture de la façade.
- `EditorNotifier.saveActiveMap` : message de succès produit à partir du dernier reçu appliqué.

## Vérifications exécutées

### TDD — échec initial attendu

```text
flutter test test/authoring_api/editor_mutation_parity_test.dart
ÉCHEC attendu : classes/fichiers AuthoringMutationAdapter et EditorReceiptPresenter absents,
paramètre authoringMutations absent de SaveMapUseCase.
```

Après la première implémentation, le test a révélé `idempotency.apply_required` car un plan `dryRun: true` ne peut pas être appliqué. Le correctif utilise `dryRun: false`, qui ne mute toujours pas lors de `plan`.

### Matrice ciblée finale

```text
cd packages/map_editor
flutter test \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/authoring_api/editor_write_boundary_test.dart \
  test/features/editor/state/editor_notifier_map_revision_test.dart \
  test/editor_notifier_real_session_roundtrip_test.dart \
  test/app/providers/map_lifecycle_provider_wiring_test.dart \
  --reporter compact
Résultat exact : +20, All tests passed!

flutter analyze
Résultat exact : No issues found! (ran in 6.0s)
```

### API canonique

```text
cd packages/map_authoring
dart test --reporter compact
Résultat exact : +293, All tests passed!

dart analyze
Résultat exact : No issues found!
```

### Build éditeur

```text
cd packages/map_editor
flutter build macos --debug
Résultat exact : ✓ Built build/macos/Build/Products/Debug/PokeMap.app
```

La suite Flutter complète n'a pas été relancée pour ce lot : les fichiers World Map/Smart Tiles extérieurs au périmètre évoluaient simultanément et avaient déjà rendu son signal non reproductible pendant PMCP-080. La matrice ciblée couvre chaque fichier produit modifié ici ; cela reste une limite de la preuve globale.

## Inventaire de la dette d'écriture

Le garde-fou classe explicitement les puits autorisés (exports/assets, transactions/récupération) et les dettes produit suivantes :

- `application/services/map_lifecycle_transaction_service.dart`
- `application/use_cases/map_use_cases.dart`
- `features/editor/state/editor_notifier.dart`
- `ui/canvas/events_v2/event_builder_v2_product_route.dart`
- `ui/canvas/storylines_workspace.dart`

Une nouvelle écriture directe non classée fait échouer le test.

## État Git

État initial pertinent : base `ca5c6c72d`, avec changements externes non liés dans `examples/playable_runtime_host/pubspec.lock`, les fichiers Smart Tiles/World Map et `.superpowers/brainstorm/...`.

État avant commit : uniquement les onze fichiers du lot seront indexés explicitement ; les changements externes restent hors index. `HEAD` a été avancé indépendamment à `11e6bf6ad` pendant l'implémentation.

## Non-objectifs et limites connues

- Pas de migration exhaustive des écrans assets/spatial/narration/gameplay dans ce lot.
- Pas de boutons globaux undo/redo dans l'éditeur.
- Les sessions de mutation sont mises en cache par racine ; un projet laissé ouvert au-delà de la durée de session devra être rouvert par une future gestion d'expiration plus riche.
- Le dernier reçu est stocké sur l'adaptateur partagé ; le chemin courant sérialise les sauvegardes, mais un futur multi-projet concurrent devra l'indexer par projet/opération.
- Aucun changement du roadmap gameplay n'est proposé : ce lot concerne la parité authoring/MCP.

## Auto-critique

La migration est volontairement verticale et utile, mais plus étroite que le libellé complet de PMCP-081. Elle prouve le contrat sur la sauvegarde la plus fréquente et fournit la façade générique nécessaire aux autres domaines ; elle ne constitue pas encore une preuve que chaque interaction no-code de l'éditeur écrit exclusivement via l'API canonique. Le fallback de compatibilité facilite la transition mais pourrait masquer une construction produit incorrecte ; le test de wiring limite ce risque. Le verdict honnête reste donc `PARTIAL`.

## Suite recommandée

1. Poursuivre le déplacement des cinq dettes classées vers `AuthoringMutationAdapter`.
2. Relier les commandes undo/redo de l'éditeur à l'historique canonique.
3. Rejouer la suite Flutter complète lorsque la branche World Map/Smart Tiles est stable.
4. Passer à `PMCP-082` pour figer le SDK MCP, le transport et la gate protocolaire.
