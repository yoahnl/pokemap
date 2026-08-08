# Inter-Map Connections Inspector and Spatial Context Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restaurer l’édition no-code des connexions physiques entre maps et afficher les maps directement reliées autour de la map active avec une opacité réduite.

**Architecture:** Ajouter un mode d’inspecteur `connections` au workspace World Map et faire transiter toutes ses mutations par les actions canoniques `connection.*` de `map_authoring`. Charger au maximum les quatre maps voisines de premier niveau, projeter leur position en coordonnées de tiles à partir de la direction et de l’offset, puis les peindre derrière la map active dans des `CustomPaint` non interactifs partageant le viewport et le cache d’images existants.

**Tech Stack:** Dart, Flutter desktop, Riverpod, Freezed, `map_core`, `map_authoring`, PokeMap Design System, Flutter widget tests, `package:test`, JSONL/CLI PokeMap et MCP PokeMap.

---

## 1. Contexte, lot et décisions validées

### Lot principal

- `WM-CONN-01` — restauration de l’authoring desktop des connexions physiques entre maps.
- Statut de départ : `PARTIAL` hors UI, `MISSING` dans l’UI actuelle.
- Référence d’audit : `documentation/reports/editor/inter_map_connections_ui_regression_audit_2026-08-08.md`.

### Décisions produit

- Le point d’entrée est un bouton **Connexions** placé dans le toolbelt World Map, immédiatement avant **Calques**.
- **Connexions** est un mode map-scoped distinct de **Placer > Warp**.
- L’inspecteur de droite présente les directions Nord, Est, Sud et Ouest autour de la map active.
- Chaque direction permet de choisir une map cible, saisir un offset entier, voir le recouvrement, appliquer, supprimer et ouvrir la map cible.
- Une création vide propose une connexion réciproque par défaut ; le sens unique reste un choix explicite.
- Les maps reliées sont visibles uniquement pendant le mode **Connexions** dans ce lot. Elles ne polluent pas les outils Peindre, Effacer, Placer ou Calques.
- La map active reste à `100 %` d’opacité et conserve toutes les interactions.
- Les maps voisines sont peintes à `36 %` d’opacité ; la direction sélectionnée monte à `62 %` pour servir de focus visuel.
- Les maps voisines sont entourées d’un trait issu des tokens du design system et portent un libellé lisible hors de la couche translucide.
- Les previews voisines sont dans `IgnorePointer`, exclues du hit-test, de la sélection, du clavier et des gestes de peinture.
- Une map cible absente ou illisible produit un emplacement de preview en erreur et une validation dans l’inspecteur ; elle ne fait pas échouer les autres directions.
- Seul le premier niveau de connexions est chargé. Les voisines des voisines ne sont jamais traversées.
- **Ajuster** cadre la map active et ses voisines lorsque le mode Connexions est ouvert. **Centrer** continue de centrer la map active.

### Non-objectifs

- Ne pas fusionner les connexions physiques et les warps.
- Ne pas rendre une map voisine éditable depuis la preview translucide.
- Ne pas charger récursivement un graphe mondial complet.
- Ne pas remonter tel quel l’ancien `MapConnectionsPanel` Cupertino.
- Ne pas ajouter de couleurs ad hoc dans les widgets de feature.
- Ne pas traiter dans `WM-CONN-01` la lecture sémantique MCP `mapConnection`; elle reste le follow-up séparé `PMCP-CONN-READ` décrit en section 12.
- Ne pas modifier le schéma `MapConnection` de `map_core`.

## 2. Contraintes de départ

Le worktree contenait déjà, lors de la rédaction du plan, des modifications qui ne doivent pas être écrasées :

```text
M  packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart
M  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
M  packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart
M  packages/map_editor/test/smart_tiles_studio/smart_tile_canonical_editor_flow_test.dart
?? packages/map_editor/lib/src/features/editor/application/deferred_smart_tile_gesture.dart
?? documentation/reports/editor/inter_map_connections_ui_regression_audit_2026-08-08.md
```

Les trois premiers fichiers chevauchent le futur lot. L’exécution doit inspecter leur diff avant toute édition et préserver les changements Smart Tile en cours.

Les opérations Git d’écriture sont volontairement absentes de ce plan. Aucun `git add`, commit, changement de branche ou worktree ne doit être effectué sans demande explicite de l’utilisateur.

Les fichiers suivants sont gelés par `tools/file_length_baseline.txt` et doivent rétrécir ou rester à leur taille actuelle :

```text
14402 packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
3759  packages/map_editor/lib/src/ui/canvas/map_canvas.dart
3042  packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

La nouvelle logique doit donc vivre dans de petits fichiers dédiés. `map_grid_painter.dart` ne doit pas grossir.

## 3. Structure de fichiers cible

### Fichiers à créer

| Fichier | Responsabilité unique |
|---|---|
| `packages/map_editor/lib/src/features/editor/application/world_map_connection_context.dart` | Types immuables et projection pure direction/offset → rectangles en coordonnées de tiles. |
| `packages/map_editor/lib/src/features/editor/application/world_map_connection_context_loader.dart` | Chargement borné et tolérant aux erreurs des quatre maps cibles de premier niveau. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_connection_context_provider.dart` | Provider async du contexte et direction actuellement sélectionnée, partagés par l’inspecteur et le canvas. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_connections_inspector.dart` | Inspecteur Material/PokeMap no-code des quatre directions. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_connection_context_layer.dart` | Construction des `CustomPaint` translucides, libellés et bordures non interactifs. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_tileset_path_collector.dart` | Extraction du collecteur de tilesets aujourd’hui enfoui dans `map_canvas.dart`, étendu à plusieurs maps. |
| `packages/map_editor/test/application/services/map_connection_editing_service_test.dart` | Contrats de sélection des actions `connection.*` et paramètres exacts. |
| `packages/map_editor/test/features/editor/application/world_map_connection_context_test.dart` | Géométrie, offsets positifs/négatifs, directions, erreurs et limitation au premier niveau. |
| `packages/map_editor/test/features/editor/presentation/world_map/world_map_connections_inspector_test.dart` | Rendu, saisie, validation et intentions utilisateur de l’inspecteur. |
| `packages/map_editor/test/ui/canvas/map_connection_context_layer_test.dart` | Opacité, ordre de peinture, libellés, `IgnorePointer` et absence de hit-test voisin. |
| `packages/map_authoring/test/tooling/jsonl_connection_flow_test.dart` | Preuve permanente JSONL pour création et suppression bidirectionnelles. |

### Fichiers à modifier

| Fichier | Modification prévue |
|---|---|
| `packages/map_editor/lib/src/features/editor/application/world_map_tool_family.dart` | Ajouter `WorldMapToolFamily.connections` et `WorldMapInspectorKind.connections`. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_workspace_session.dart` | Ajouter `activateConnections` sans changer d’outil de peinture actif. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_toolbelt.dart` | Ajouter le bouton Connexions et son état sélectionné. |
| `packages/map_editor/lib/src/features/editor/presentation/world_map/adaptive_map_inspector.dart` | Monter `WorldMapConnectionsInspector` pour le nouveau kind et titrer le panneau. |
| `packages/map_editor/lib/src/application/services/map_connection_editing_service.dart` | Remplacer les use cases de mutation locale par un projecteur d’intentions vers les actions canoniques. |
| `packages/map_editor/lib/src/app/providers/editor/editing_service_providers.dart` | Adapter la construction du service après suppression des use cases de mutation locale. |
| `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart` | Retirer les providers `UpsertMapConnectionUseCase` et `DeleteMapConnectionUseCase` devenus inutiles. |
| `packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart` | Conserver la résolution de cible ; retirer les deux use cases de mutation qui contournaient `map_authoring`. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | Exécuter plan/apply/reload via `AuthoringMutationAdapter` pour sauvegarde et suppression. |
| `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` | Charger le contexte, partager les images, insérer le calque voisin sous le painter actif et cadrer les bounds du contexte. |
| `packages/map_editor/lib/src/application/services/map_viewport_navigation.dart` | Ajouter un calcul pur de viewport à partir d’un rectangle de contexte avec origine potentiellement négative. |
| `packages/map_editor/test/features/editor/presentation/world_map/world_map_toolbelt_test.dart` | Protéger le point d’entrée et l’activation du mode. |
| `packages/map_editor/test/features/editor/presentation/world_map/adaptive_map_inspector_test.dart` | Protéger le nouveau body réel et son titre. |
| `packages/map_editor/test/application/services/map_viewport_navigation_test.dart` | Protéger le fit avec voisins au nord/ouest et origine négative. |
| `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart` | Prouver la consommation editor réelle des cinq actions `connection.*`. |
| `packages/map_editor/test/editor_shell_page_smoke_test.dart` | Prouver la présence du parcours Connexions dans le shell courant. |
| `packages/map_editor/test/ui/shell/pokemap_inspector_shell_migration_test.dart` | Garantir que le nouveau parcours reste dans `AdaptiveMapInspector`, sans ressusciter `MapInspectorPanel`. |
| `packages/map_editor/lib/src/app/providers/editor/editing_service_providers.g.dart` | Régénération Riverpod bornée au package editor. |
| `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.g.dart` | Régénération Riverpod bornée au package editor. |

## 4. Task 0 — Verrouiller le baseline et les conflits de worktree

**Files:**

- Inspect: `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart`
- Inspect: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Inspect: `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`
- Inspect: `packages/map_editor/lib/src/features/editor/application/deferred_smart_tile_gesture.dart`

- [ ] Exécuter `git status --short --untracked-files=all` depuis la racine et conserver la sortie dans les notes d’exécution.
- [ ] Exécuter `git diff -- packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`.
- [ ] Identifier les méthodes Smart Tile modifiées dans `editor_notifier.dart` et réserver des zones de patch qui ne réécrivent pas ces changements.
- [ ] Exécuter les tests actuellement touchés avant le lot : `cd packages/map_editor && flutter test test/authoring_api/editor_mutation_parity_test.dart test/smart_tiles_studio/smart_tile_canonical_editor_flow_test.dart`.
- [ ] Si ces tests sont rouges avant le lot, consigner les échecs comme préexistants et ne pas les attribuer aux connexions.
- [ ] Exécuter `dart tools/check_file_length.dart` depuis la racine et conserver les tailles initiales des trois fichiers gelés.

**Gate:** ne pas commencer Task 1 si un diff concurrent modifie précisément `saveMapConnection`, `deleteMapConnection` ou le routage générique plan/apply de l’adapter sans avoir concilié les intentions.

## 5. Task 1 — Caractériser et canoniser les mutations editor

**Files:**

- Modify: `packages/map_editor/lib/src/application/services/map_connection_editing_service.dart`
- Modify: `packages/map_editor/lib/src/application/use_cases/map_connection_use_cases.dart`
- Modify: `packages/map_editor/lib/src/app/providers/editor/editing_service_providers.dart`
- Modify: `packages/map_editor/lib/src/app/providers/editor/map_use_case_providers.dart`
- Modify: `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- Create: `packages/map_editor/test/application/services/map_connection_editing_service_test.dart`
- Modify: `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`

### Contrat à introduire

Ajouter dans `map_connection_editing_service.dart` un objet immuable de ce type :

```dart
final class MapConnectionMutationIntent {
  const MapConnectionMutationIntent({
    required this.actionId,
    required this.parameters,
  });

  final String actionId;
  final Map<String, Object?> parameters;
}
```

Le service doit exposer deux projecteurs purs :

```dart
MapConnectionMutationIntent buildUpsertIntent({
  required MapData sourceMap,
  required MapConnectionDirection direction,
  required String targetMapId,
  required int offset,
  required bool reciprocal,
  required bool exactReciprocalPairExists,
});

MapConnectionMutationIntent buildDeleteIntent({
  required MapData sourceMap,
  required MapConnectionDirection direction,
  required bool exactReciprocalPairExists,
});
```

Routage exact :

| Intention | Action ID |
|---|---|
| Création ou remplacement en sens unique | `connection.upsert` |
| Création réciproque sur une direction vide | `connection.create_bidirectional_apply` |
| Mise à jour d’une paire réciproque exacte | `connection.update_bidirectional_apply` |
| Suppression sens unique ou paire incohérente | `connection.delete` |
| Suppression d’une paire réciproque exacte | `connection.delete_bidirectional_apply` |

Paramètres upsert/create/update : `mapId`, `direction`, `targetMapId`, `offset`. Paramètres delete : `mapId`, `direction`.

- [ ] Écrire les tests échouants pour les cinq routes du tableau et les paramètres exacts.
- [ ] Ajouter un test qui refuse une cible vide avant de construire l’intention.
- [ ] Ajouter un test qui refuse une connexion vers la map source.
- [ ] Exécuter `cd packages/map_editor && flutter test test/application/services/map_connection_editing_service_test.dart` et vérifier que les nouveaux tests échouent pour la bonne raison.
- [ ] Remplacer les dépendances `UpsertMapConnectionUseCase` et `DeleteMapConnectionUseCase` du service par les projecteurs purs ci-dessus ; conserver `findConnection` et `resolveTargetMapEntry`.
- [ ] Retirer les deux providers et use cases de mutation locale devenus sans consommateur.
- [ ] Dans `EditorNotifier.saveMapConnection`, ajouter les paramètres `reciprocal` et `exactReciprocalPairExists`, puis exécuter `AuthoringMutationAdapter.plan` et `apply` avec une identité déterministe propre à la direction et à la révision.
- [ ] Dans `EditorNotifier.deleteMapConnection`, rendre la méthode asynchrone et appliquer le même chemin canonique.
- [ ] Avant le plan canonique, sauvegarder ou refuser proprement une map active sale afin que le snapshot disque ne perde pas les changements visibles.
- [ ] Après apply, rouvrir le snapshot via `AuthoringQueryAdapter`, vérifier `applied.snapshotRevision`, puis adopter la map active et le manifeste retournés sans recharger aveuglément un fichier obsolète.
- [ ] En cas d’apply réussi suivi d’un reload échoué, afficher le message de récupération canonique et ne pas réappliquer l’opération.
- [ ] Étendre `editor_mutation_parity_test.dart` pour rechercher les cinq `actionId` réellement consommés par l’editor, pas seulement leur présence dans le catalogue.
- [ ] Exécuter les deux tests ciblés et vérifier qu’ils passent.

**Limite explicite:** convertir atomiquement une connexion sens unique existante en paire réciproque n’est pas couvert par les cinq actions actuelles. Dans ce lot, le toggle réciproque est désactivé pour une connexion sens unique existante avec un texte expliquant qu’elle doit être supprimée puis recréée. Ne pas enchaîner silencieusement deux mutations non atomiques.

## 6. Task 2 — Ajouter le mode Connexions au shell adaptatif

**Files:**

- Modify: `packages/map_editor/lib/src/features/editor/application/world_map_tool_family.dart`
- Modify: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_workspace_session.dart`
- Modify: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_toolbelt.dart`
- Modify: `packages/map_editor/lib/src/features/editor/presentation/world_map/adaptive_map_inspector.dart`
- Modify: `packages/map_editor/test/features/editor/presentation/world_map/world_map_toolbelt_test.dart`
- Modify: `packages/map_editor/test/features/editor/presentation/world_map/adaptive_map_inspector_test.dart`
- Modify: `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- Modify: `packages/map_editor/test/ui/shell/pokemap_inspector_shell_migration_test.dart`

- [ ] Écrire un test toolbelt qui attend `ValueKey('world-map-tool-connections')`, le libellé Connexions et sa position avant `world-map-tool-layers`.
- [ ] Écrire un test de session qui appelle `activateConnections`, rend l’inspecteur visible et projette `WorldMapInspectorKind.connections` sans changer l’outil de placement en Warp.
- [ ] Écrire un test d’inspecteur qui attend un unique `WorldMapConnectionsInspector` lorsque le kind vaut `connections`.
- [ ] Étendre le smoke shell pour ouvrir Connexions depuis le toolbelt et vérifier le titre de l’inspecteur.
- [ ] Exécuter ces tests et confirmer leur échec initial.
- [ ] Ajouter `connections` aux deux enums sans réutiliser artificiellement `layers`.
- [ ] Ajouter `WorldMapWorkspaceSessionController.activateConnections`, qui rend le mode sélectionné, désépingle un body incompatible et conserve les données d’outil nécessaires au retour.
- [ ] Ajouter un `PokeMapButton` secondaire dans le toolbelt avec l’icône Material `hub_outlined`, le tooltip `Gérer les connexions entre maps` et le libellé `Connexions` en mode non condensé.
- [ ] Ajouter le titre `Connexions` et le body `WorldMapConnectionsInspector` dans les switches exhaustifs de `adaptive_map_inspector.dart`.
- [ ] Déclarer explicitement `worldMapInspectorCanReturnToLayers(WorldMapInspectorKind.connections) == false`, car Connexions est une page racine.
- [ ] Désactiver le pin pour `connections` afin que les previews voisines disparaissent dès que l’auteur revient à Peindre, Effacer, Placer ou Calques.
- [ ] Exécuter les quatre tests ciblés et vérifier qu’ils passent.

## 7. Task 3 — Construire l’inspecteur no-code

**Files:**

- Create: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_connections_inspector.dart`
- Create: `packages/map_editor/test/features/editor/presentation/world_map/world_map_connections_inspector_test.dart`
- Reuse: `packages/map_editor/lib/src/ui/design_system/design_system.dart`

### Structure attendue

- Un sélecteur cardinal en croix, avec la map active au centre.
- Un état vide `+ Ajouter` pour chaque direction libre.
- Un `PokeMapDropdownField<String>` trié par `sortOrder`, puis par nom, excluant la map active.
- Un champ numérique d’offset acceptant uniquement un entier signé.
- Deux choix sémantiques : `Réciproque` et `Sens unique`.
- Un aperçu du recouvrement avec le nombre de tiles communes.
- Un badge `Valide`, `À compléter` ou `Cible introuvable`.
- Des boutons PokeMap `Ouvrir`, `Supprimer` et `Appliquer`.
- Une annonce `Semantics(liveRegion: true)` après validation, erreur ou application.

- [ ] Écrire un harness Riverpod avec une map active, deux cibles valides, une connexion Nord et une connexion Est.
- [ ] Tester les quatre directions, les deux libellés de cibles et les deux états `+ Ajouter`.
- [ ] Tester que la map active n’apparaît jamais dans le picker.
- [ ] Tester la synchronisation des contrôleurs quand la map active change.
- [ ] Tester les offsets `-4`, `0` et `+4` sans conversion silencieuse.
- [ ] Tester qu’un offset sans recouvrement désactive Appliquer et annonce la raison.
- [ ] Tester qu’une cible manifestée mais illisible affiche `Cible introuvable` sans masquer les autres directions.
- [ ] Tester que `Ouvrir` appelle `requestEditorConnectedMapActivation` et respecte le dirty-map guard existant.
- [ ] Tester que l’application réciproque et la suppression passent les flags exacts à `EditorNotifier`.
- [ ] Exécuter le test et confirmer l’échec initial.
- [ ] Implémenter le widget uniquement avec `PokeMapPanel`, `PokeMapCard`, `PokeMapButton`, `PokeMapIconButton`, `PokeMapBadge`, `PokeMapDropdownField`, les tokens `context.pokeMapColors` et les composants de formulaire déjà exportés par le design system.
- [ ] Utiliser `WarpConnectionActions.previewAlignment` ou le helper canonique équivalent pour calculer le recouvrement ; ne pas dupliquer la formule dans le widget.
- [ ] Ne mettre aucun `Color(0x...)`, `Colors.*` ou constante de palette produit directement dans le nouveau widget.
- [ ] Exécuter le test et vérifier qu’il passe.

## 8. Task 4 — Charger et projeter les maps voisines

**Files:**

- Create: `packages/map_editor/lib/src/features/editor/application/world_map_connection_context.dart`
- Create: `packages/map_editor/lib/src/features/editor/application/world_map_connection_context_loader.dart`
- Create: `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_connection_context_provider.dart`
- Create: `packages/map_editor/test/features/editor/application/world_map_connection_context_test.dart`

### Modèle attendu

```dart
final class WorldMapConnectionNeighbor {
  const WorldMapConnectionNeighbor({
    required this.direction,
    required this.connection,
    required this.entry,
    required this.map,
    required this.tileBounds,
  });

  final MapConnectionDirection direction;
  final MapConnection connection;
  final ProjectMapEntry entry;
  final MapData map;
  final Rect tileBounds;
  final bool exactReciprocalPair;
}
```

Le contexte doit aussi conserver une erreur par direction, au lieu d’un unique échec global.

Projection des origins, exprimée en tiles avec `along = sourceStart - targetStart` issu de l’aperçu canonique :

| Direction | Origin de la cible |
|---|---|
| Nord | `(along, -target.height)` |
| Est | `(source.width, along)` |
| Sud | `(along, source.height)` |
| Ouest | `(-target.width, along)` |

- [ ] Écrire des tests pour les quatre directions avec offset zéro.
- [ ] Écrire des tests Est et Nord avec offsets positif et négatif.
- [ ] Tester que le rectangle global inclut correctement les origins négatives du Nord et de l’Ouest.
- [ ] Tester une cible absente du manifeste, un fichier absent et un JSON invalide comme trois erreurs locales.
- [ ] Tester qu’une connexion cyclique A ↔ B ne charge que B depuis A.
- [ ] Tester que quatre directions produisent au maximum quatre lectures.
- [ ] Tester `exactReciprocalPair: true` uniquement lorsque la cible contient la direction opposée vers la source avec l’offset inverse exact.
- [ ] Exécuter le test et confirmer l’échec initial.
- [ ] Implémenter le projecteur pur à partir de `ConnectionAlignmentPreview`; lever une erreur locale lorsque le recouvrement vaut zéro.
- [ ] Implémenter le loader avec `MapRepository.loadMap` sur le chemin résolu de chaque `ProjectMapEntry` et retourner les succès même si une autre direction échoue.
- [ ] Exposer un `FutureProvider.autoDispose.family` manuel, clé par projet/map/connexions, ainsi qu’un provider de direction sélectionnée partagé entre l’inspecteur et le canvas.
- [ ] Rendre le résultat immuable et stable par direction afin de limiter les rebuilds.
- [ ] Exécuter le test et vérifier qu’il passe.

## 9. Task 5 — Peindre le contexte translucide sans interaction

**Files:**

- Create: `packages/map_editor/lib/src/ui/canvas/map_canvas/map_connection_context_layer.dart`
- Create: `packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_tileset_path_collector.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- Reuse unchanged: `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- Create: `packages/map_editor/test/ui/canvas/map_connection_context_layer_test.dart`

- [ ] Écrire un widget test avec une map active, une voisine Nord et une voisine Est.
- [ ] Vérifier que le Stack contient d’abord les previews voisines, puis le painter actif.
- [ ] Vérifier `Opacity(0.36)` pour une voisine non sélectionnée et `Opacity(0.62)` pour la direction sélectionnée.
- [ ] Vérifier que chaque preview est enveloppée dans `IgnorePointer(ignoring: true)`.
- [ ] Envoyer un tap dans la zone de la voisine et vérifier qu’aucune sélection, peinture ou activation de map n’est produite.
- [ ] Vérifier que le libellé de map est peint dans un overlay opaque distinct de l’`Opacity` de la map.
- [ ] Vérifier que la map active reste à pleine opacité et garde le focus clavier.
- [ ] Exécuter le test et confirmer l’échec initial.
- [ ] Extraire `_collectLayerTilesetPaths` de `map_canvas.dart` vers `map_canvas_tileset_path_collector.dart` avant d’ajouter le nouveau wiring, afin que le fichier gelé rétrécisse.
- [ ] Étendre le collecteur à l’union des tilesets de la map active et des voisines chargées, sans dupliquer une ressource par ID.
- [ ] Construire chaque voisine avec un `MapGridPainter` configuré avec la map cible, le même zoom, un pan décalé par `tileBounds.topLeft`, `showGrid: false`, `showEntityEditorChrome: false` et `showEditorOverlays: false`.
- [ ] Passer les warps et gameplay zones de la cible au painter sans leur chrome editor ; ils restent purement visuels.
- [ ] Placer `MapConnectionContextLayer` avant le `CustomPaint` actif dans le Stack existant.
- [ ] Garder tous les gestes, la sémantique du curseur et les overlays de sélection sur le painter actif uniquement.
- [ ] Afficher un contour et un libellé d’erreur via les tokens sémantiques lorsqu’une direction ne peut pas charger sa map.
- [ ] Exécuter le test et vérifier qu’il passe.
- [ ] Exécuter `dart tools/check_file_length.dart` et vérifier que `map_canvas.dart` ne dépasse pas son baseline et que `map_grid_painter.dart` reste à 3042 lignes ou moins.

## 10. Task 6 — Adapter Ajuster et les transitions de contexte

**Files:**

- Modify: `packages/map_editor/lib/src/application/services/map_viewport_navigation.dart`
- Modify: `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- Modify: `packages/map_editor/test/application/services/map_viewport_navigation_test.dart`
- Modify: `packages/map_editor/test/map_canvas_pointer_navigation_test.dart`

- [ ] Écrire un test pur `fitBounds` avec un rectangle commençant en `(-12, -8)` et se terminant au sud-est de la map active.
- [ ] Vérifier que le zoom respecte les bornes existantes et que le pan centre ce rectangle, pas seulement sa taille.
- [ ] Écrire un test canvas où **Ajuster** en mode Connexions rend visibles une voisine Nord et une voisine Est.
- [ ] Vérifier que **Centrer** recentre toujours la map active.
- [ ] Vérifier qu’un retour vers Peindre masque les previews sans modifier le zoom ou le pan de manière inattendue.
- [ ] Vérifier qu’un changement rapide de map active n’affiche jamais une réponse async de l’ancienne map.
- [ ] Exécuter les tests et confirmer l’échec initial.
- [ ] Ajouter exactement `MapViewportNavigation.fitBounds({required Rect contentBounds, required Size viewportSize, required Size tileSize})`.
- [ ] Faire choisir `_fitActiveMap` entre les bounds de la map active et ceux du contexte selon `WorldMapInspectorKind.connections`.
- [ ] Lier le loader au couple immuable `(projectRootPath, activeMap.id, activeMap.connections)` afin que Riverpod ignore automatiquement un résultat obsolète après changement de map.
- [ ] Exécuter les tests et vérifier qu’ils passent.

## 11. Task 7 — Fermer la parité et vérifier le lot

**Files:**

- Create: `packages/map_authoring/test/tooling/jsonl_connection_flow_test.dart`
- Modify: `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`
- Verify: `tools/pokemap_mcp`
- Verify: `pokemap_authoring_api_mcp_action_catalog.md`

### Preuves permanentes

- [ ] Écrire le test JSONL qui ouvre une fixture de deux maps, planifie `connection.create_bidirectional_apply`, vérifie deux changements `/connections`, applique, relit les deux maps, puis planifie et applique `connection.delete_bidirectional_apply`.
- [ ] Vérifier dans le test editor que les cinq actions `connection.*` sont consommées par le service/editor et présentes dans l’inventaire de parité.
- [ ] Exécuter `cd packages/map_authoring && dart test test/domains/maps/warp_connection_transaction_test.dart test/tooling/jsonl_connection_flow_test.dart`.
- [ ] Exécuter `cd packages/map_authoring && dart analyze`.
- [ ] Exécuter les tests editor ciblés :

```bash
cd packages/map_editor
flutter test \
  test/application/services/map_connection_editing_service_test.dart \
  test/application/services/map_viewport_navigation_test.dart \
  test/features/editor/application/world_map_connection_context_test.dart \
  test/features/editor/presentation/world_map/world_map_connections_inspector_test.dart \
  test/features/editor/presentation/world_map/world_map_toolbelt_test.dart \
  test/features/editor/presentation/world_map/adaptive_map_inspector_test.dart \
  test/ui/canvas/map_connection_context_layer_test.dart \
  test/map_canvas_pointer_navigation_test.dart \
  test/authoring_api/editor_mutation_parity_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/ui/shell/pokemap_inspector_shell_migration_test.dart
```

- [ ] Exécuter `cd packages/map_editor && flutter pub run build_runner build --delete-conflicting-outputs` uniquement après les tests manuels de providers, puis vérifier que seuls les `.g.dart` attendus changent.
- [ ] Relancer les tests editor ciblés après génération.
- [ ] Exécuter `cd packages/map_editor && flutter analyze`.
- [ ] Exécuter `dart tools/check_file_length.dart` depuis la racine.
- [ ] Exécuter `cd tools/pokemap_mcp && npm run check && npm test`.
- [ ] Redémarrer/recharger le serveur MCP local avant les contrôles live.
- [ ] Appeler `pokemap_describe` et vérifier que les cinq actions restent publiées : `connection.upsert`, `connection.delete`, `connection.create_bidirectional_apply`, `connection.update_bidirectional_apply`, `connection.delete_bidirectional_apply`.
- [ ] Sur une fixture, exécuter un `pokemap_plan` dry-run bidirectionnel et vérifier deux ressources map, deux chemins `/connections`, l’overlap et `multiMapGuarantee: recoverable`.
- [ ] Exécuter le même dry-run via JSONL/CLI et comparer les previews stables.
- [ ] Exécuter `POKEMAP_MARKDOWN_MAX_NEW=2 bash tools/scripts/check_markdown_hygiene.sh` tant que l’audit et ce plan sont les deux seuls nouveaux Markdown autorisés.
- [ ] Exécuter `git diff --check`.
- [ ] Exécuter `git status --short --untracked-files=all` et séparer clairement les changements du lot des modifications Smart Tile préexistantes.

### Critères d’acceptation finaux

- Le bouton Connexions est visible et ouvre le bon inspecteur.
- Les quatre directions sont éditables sans saisir d’ID brut.
- Les mutations editor passent réellement par les actions canoniques `connection.*`.
- Une paire réciproque met à jour ou supprime ses deux maps de manière récupérable.
- Les maps voisines sont placées selon direction et offset, visibles à opacité réduite et non interactives.
- La voisine sélectionnée est visuellement renforcée sans devenir la map active.
- Les erreurs d’une voisine ne font pas disparaître les autres.
- Ajuster cadre le contexte ; Centrer conserve la map active comme référence.
- Les tests direct API, JSONL, editor et MCP sont frais et verts.
- Aucun fichier Dart ne dépasse son baseline de longueur.
- Aucun changement préexistant n’est écrasé ou attribué au lot.

## 12. Follow-up séparé — `PMCP-CONN-READ`

Ce follow-up reste `PARTIAL` après `WM-CONN-01` et ne bloque pas la restauration UI :

- rendre `mapConnection` requêtable par `pokemap_query` ;
- exposer `connection.list`, `connection.get`, `connection.preview_alignment` et `connection.validate` ;
- exposer le graphe de monde via des ressources `world_graph.*` bornées ;
- documenter un field mask `connections` pour la ressource map ou supprimer la promesse correspondante ;
- corriger PMCP-085 afin qu’une ressource déclarée supportée mais non lisible ne soit plus comptée comme parité complète ;
- ajouter des tests permanents MCP de lecture, pas uniquement de mutation.

## 13. Risques et mitigations

| Risque | Mitigation prévue |
|---|---|
| Le painter actif est massif et gelé. | Réutiliser `MapGridPainter` tel quel dans des calques séparés ; extraire le collecteur depuis `map_canvas.dart` pour créer du budget. |
| Quatre maps supplémentaires augmentent le coût de rendu. | Premier niveau uniquement, maximum quatre, cache d’images partagé, pas de grid/chrome/overlays voisins. |
| Une réponse async ancienne apparaît après navigation. | Clé Riverpod incluant projet, map et liste de connexions ; résultat obsolète non adopté. |
| Un projet legacy contient une cible absente. | Erreur locale par direction, outline d’erreur, aucune exception globale. |
| Une mutation canonique planifie sur un disque plus ancien que l’UI. | Flush explicite de la map sale, expected revision et adoption du snapshot post-apply. |
| Une paire réciproque est partiellement incohérente. | Détecter la paire exacte ; ne jamais lancer delete/update bidirectionnel sur un mismatch. |
| Le toggle réciproque promet une conversion non atomique. | Désactiver la promotion d’un sens unique existant dans ce lot et expliquer la limite. |
| Les fichiers modifiés en parallèle sont écrasés. | Task 0 obligatoire, patches chirurgicaux et état Git final séparant les scopes. |

## 14. Ordre d’exécution recommandé

1. Task 0 — baseline et conflits.
2. Task 1 — mutation canonique et tests de parité editor.
3. Task 2 — point d’entrée et shell adaptatif.
4. Task 3 — inspecteur no-code.
5. Task 4 — projection et chargement des voisines.
6. Task 5 — rendu translucide non interactif.
7. Task 6 — viewport et transitions.
8. Task 7 — parité, analyses et vérification finale.

Le lot peut être livré en deux checkpoints fonctionnels :

- **Checkpoint A après Task 3 :** édition des connexions restaurée dans l’UI avec mutations canoniques.
- **Checkpoint B après Task 7 :** contexte spatial translucide, viewport adapté et parité vérifiée.
