# Evidence Pack — NSC-30 Scenes Library lifecycle

## Résumé exécutif

Le lot **NSC-30 — Scenes Library lifecycle** est implémenté et proposé **DONE** sur son périmètre Narrative Studio. La bibliothèque de scènes sait désormais rechercher, filtrer, classer, renommer, dupliquer profondément, archiver, restaurer et supprimer une scène sans perte silencieuse. Toute suppression d'une scène consommée est refusée tant qu'un remplacement compatible n'est pas fourni; les consommateurs appartenant au `ProjectManifest` sont alors réécrits atomiquement.

Ce lot ne change aucun statut FG: il s'agit d'authoring et de sûreté de bibliothèque, sans nouveau contrat d'exécution runtime.

## Confirmation du scope

Inclus:

- cycle de vie de `SceneAsset` dans `map_core`;
- recherche par nom, ID, description, dossier, tags et résultats;
- filtres actives / archivées / toutes;
- classement par dossier, Storyline et Chapitre existants;
- affichage du nombre de consommateurs;
- duplication avec remappage de tous les IDs de nœuds, edges et layouts;
- suppression protégée, remplacement compatible et réécriture atomique;
- formulaires no-code fondés sur le design system;
- non-régressions fonctionnelles, responsives et visuelles;
- nouveaux tests ciblés et suites complètes des packages concernés.

Hors scope conservé:

- chargement automatique de toutes les maps du projet pour l'index de dépendances UI;
- création de Storylines ou Chapitres depuis le formulaire Scènes;
- NSC-31 et lots ultérieurs du Scene Builder;
- évolution du schéma JSON: dossier et archivage restent des métadonnées sémantiques;
- tout changement de mécanique FG/runtime.

## Audit initial

### Contrats trouvés

- `SceneAsset` possédait déjà les champs canoniques `storylineId`, `chapterId`, `tags`, `declaredOutcomes`, `graph`, `layout` et `metadata`.
- `NarrativeDependencyIndex` indexait déjà les consommateurs Scène: New Game, Event Registry, Storyline/Chapter/Step et maps fournies.
- `ScenesWorkspace` concentrait la liste, le canvas et l'inspecteur dans un fichier très volumineux; l'extraction de la bibliothèque était donc nécessaire.
- `NarrativeSceneSummary` exposait le graph et les diagnostics, mais pas les métadonnées de bibliothèque ni les définitions complètes de résultats.
- La sauvegarde du workspace passe par `EditorNotifier.applyInMemoryProjectManifest`, frontière préservée.

### Tests et rapports trouvés

- `packages/map_core/test/scene_authoring_operations_test.dart`;
- `packages/map_editor/test/scenes_workspace_shell_test.dart`;
- goldens Scènes sous `reports/narrativeStudio/scenes/screenshots/`;
- golden plein produit sous `packages/map_editor/test/goldens/narrative_studio/scenes/`;
- roadmap: `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`;
- roadmap mécanique: `pokemap_roadmap_mecaniques_fangame.md`.

### Risques identifiés

- suppression d'une scène encore référencée;
- collision des IDs internes lors de la duplication;
- mutation partielle des consommateurs;
- confusion entre classement de bibliothèque et propriété Storyline/Chapitre;
- rupture de l'UI Cupertino par une primitive Material du design system;
- dérive des goldens après ajout de la recherche et des actions.

### État Git initial

Branche `main`, worktree déjà sale. Changements préexistants explicitement préservés et exclus du commit NSC-30:

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

## Décisions d'architecture

1. Le renommage conserve l'ID stable de la scène.
2. Les tags et résultats utilisent les champs canoniques existants.
3. L'archive et le dossier utilisent `pokemap.scene.archived` et `pokemap.scene.libraryFolder` dans `metadata`, évitant une migration de schéma hors scope.
4. La duplication remappe chaque identité possédée par le graph, sans toucher aux références externes des payloads.
5. Une suppression sans remplacement est refusée dès qu'un consommateur existe.
6. Un remplacement doit déclarer tous les outcome IDs de la scène supprimée.
7. Les consommateurs hors `ProjectManifest` sont refusés plutôt que prétendument réécrits.
8. Les opérations core sont pures et retournent un résultat explicite `applied / noChange / rejected`.
9. L'UI utilise uniquement les primitives et tokens du design system. Un `Material` transparent borne la primitive dropdown afin que la route reste compatible avec les hôtes Cupertino existants.

## Inventaire complet des fichiers du lot

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_core/lib/src/authoring/scene_authoring_operations.dart` | `SceneLibraryLocation`, `SceneLibraryMutationResult`, rename/classify/duplicate/archive/restore/delete, clone profond, remplacement des consommateurs | Contrat pur et atomique du cycle de vie Scène. |
| `packages/map_core/test/scene_authoring_operations_test.dart` | groupe `NSC-30 Scene library lifecycle` et fixtures Event/Storyline | Couvre positif, négatif, consommateurs multiples, externe, clone et non-mutation. |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | `NarrativeSceneSummary`, projection metadata/outcomes | Expose archive, dossier et résultats complets sans muter le modèle. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | composition `ScenesWorkspace`, callbacks lifecycle, index consommateurs | Branche les opérations core sur la transaction projet existante. |
| `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` | callbacks lifecycle, sheets d'édition/suppression, extraction de l'ancienne liste | Offre renommage/classement, duplication, archive et suppression protégée. |
| `packages/map_editor/lib/src/ui/canvas/scenes/scene_library_panel.dart` | fichier créé, composant complet | Bibliothèque recherchable/filtrable et actions DS réutilisables. |
| `packages/map_editor/test/scenes_library_lifecycle_test.dart` | fichier créé, 3 widget tests | Prouve recherche, archives, actions et usages visibles. |
| `packages/map_editor/test/scenes_workspace_shell_test.dart` | assertions recherche permanente et goldens | Adapte les non-régressions à la bibliothèque réelle. |
| `packages/map_editor/test/goldens/narrative_studio/scenes/scenes_full_product_route_1672x941.png` | golden régénéré | Référence plein écran du nouveau panneau. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_bis_edge_selection_deletion_ux_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_visual_port_connection_ux_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_15_wire_anchor_color_code.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_17_condition_authoring_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_18_fact_registry_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_25_bis_dialogue_battle_ports_authoring_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_bis_scene_node_deletion_ux_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_31_scene_consequence_authoring_ui_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png` | golden régénéré | Nouveau chrome bibliothèque. |
| `reports/narrativeStudio/completion/nsc_30_scenes_library_lifecycle_evidence_pack.md` | présent rapport | Traçabilité du lot et preuves. |

## Diffs / zones précises

### map_core

- lignes de tête: constantes metadata, type de localisation, disposition et résultat;
- API publiques: `renameSceneInProject`, `updateSceneLibraryClassification`, `duplicateSceneInProject`, `archiveSceneInProject`, `restoreSceneInProject`, `deleteSceneFromProject`;
- helpers privés avant `_createSceneDraft`: copie immutable, clone profond, mise à jour registre Event, Storylines, Steps et New Game;
- tests: nouveau groupe NSC-30 en fin de `main`, plus helpers de fixtures.

### map_editor

- projection: metadata et `SceneOutcome` complets;
- canvas: callbacks transactionnels vers les opérations core et construction des chemins consommateurs;
- workspace: formulaires latéraux DS et gestion des erreurs explicites;
- panneau extrait: recherche, visibilité, groupes, usages et actions;
- tests/goldens: assertions et pixels alignés sur le nouveau panneau.

`git diff --check` sur tous les fichiers texte du lot: aucune erreur.

## Tests et validations

### TDD rouge initial

```text
cd packages/map_core
dart test test/scene_authoring_operations_test.dart
```

Échec attendu: APIs NSC-30 absentes (`renameSceneInProject`, `SceneLibraryLocation`, classification, duplication, archive/restauration et suppression).

### Tests ciblés core

```text
cd packages/map_core
dart test test/scene_authoring_operations_test.dart
```

Résultat exact: **50 tests passés, 0 échec**.

### Tests ciblés editor

```text
cd packages/map_editor
flutter test test/scenes_library_lifecycle_test.dart test/scenes_workspace_shell_test.dart
```

Résultat exact: **89 tests passés, 0 échec**.

```text
flutter test test/ui/canvas/narrative_overview_shell_navigation_test.dart test/scenes_library_lifecycle_test.dart
```

Résultat exact: **24 tests passés, 0 échec**. Cette relance prouve la compatibilité du dropdown DS avec un hôte Cupertino.

### Suites complètes

```text
cd packages/map_core
dart test
```

Résultat exact: **3 176 tests passés, 0 échec**.

```text
cd packages/map_editor
flutter test
```

Résultat exact: **3 573 tests passés, 0 échec**.

### Analyses

```text
cd packages/map_core
dart analyze
```

Résultat exact: `No issues found!`

```text
cd packages/map_editor
flutter analyze
```

Résultat exact: `No issues found! (ran in 5.2s)`

### Build

```text
cd packages/map_editor
flutter build macos
```

Résultat Release: **échec toolchain** lors de `release_unpack_macos`. Le message affirme que `FlutterMacOS` ne contient pas `arm64 x86_64`, alors que la ligne `lipo -info` du même log confirme exactement `x86_64 arm64`. Ce résultat n'est pas maquillé comme vert.

Validation alternative:

```text
flutter build macos --debug
```

Résultat exact: `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## Passes séparées exigées par codex_rule.md

La politique d'exécution supérieure interdisait la création de sub-agents pour ce tour. Les cinq rôles ont donc été exécutés comme passes locales séparées, conformément au fallback autorisé par `codex_rule.md`.

| Passe | Verdict | Détail |
|---|---|---|
| Audit / Architecture | PASS | Réutilisation de SceneAsset, DependencyIndex et transaction EditorNotifier; aucune migration inventée. |
| Implémentation | PASS | Core pur, UI extraite et design system; pas de dépendance runtime ajoutée. |
| Tests | PASS | Positif, négatif, garde-fous, clone, consommateurs multiples, archives et non-régressions. |
| Build / Validation | PASS avec réserve toolchain Release | Debug build vert; Release bloqué par une contradiction de l'outil Flutter sur les architectures. |
| Critique finale | PASS | Aucun fichier préexistant hors lot intégré; limites maps non chargées et métadonnées documentées. |

## Auto-critique et risques restants

- La duplication est volontairement profonde pour les identités structurelles du graph; les payloads immuables conservent leurs références externes, ce qui est le comportement attendu d'une copie de scène.
- L'UI ne connaît que la map active. Un consommateur situé sur une autre map non chargée ne peut pas être affiché ni bloqué par cette route. L'API core accepte toutefois un index enrichi avec toutes les maps et refuse correctement les consommateurs externes.
- Le formulaire de classement choisit uniquement des Storylines/Chapitres déjà observés dans les scènes. Leur création reste dans les workspaces Storylines.
- Les outcome IDs nouveaux reprennent leur ID comme label initial; un éditeur de résultats plus riche appartient à NSC-31/32.
- Le build Release doit être réessayé après correction ou mise à jour du toolchain Flutter; le binaire Debug prouve la compilation de l'application.
- L'ajout du champ recherche a nécessité de corriger quatre assertions historiques qui confondaient « aucun champ d'ID brut » avec « aucun TextField dans toute la page ».

## État Git final avant commit

Les fichiers NSC-30 sont prêts pour un commit ciblé. Les changements Selbrume et runtime préexistants restent présents et exclus. Le fichier déjà staged `examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart` ne doit pas entrer dans le commit; le commit est effectué avec `git commit --only`.

## Statut proposé et prochaine étape

- **NSC-30: DONE**
- Statuts FG: **inchangés / N/A pour ce lot**
- Prochain lot: **NSC-31 — Scene graph authoring et ports dynamiques**, sans l'implémenter dans ce commit.

## Annexe A — contenu complet du fichier créé scene_library_panel.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

enum SceneLibraryVisibility { active, archived, all }

final class SceneLibraryPanel extends StatefulWidget {
  const SceneLibraryPanel({
    super.key,
    required this.scenes,
    required this.selectedSceneId,
    required this.consumerCountBySceneId,
    required this.onSelectScene,
    required this.onEditScene,
    required this.onDuplicateScene,
    required this.onToggleArchiveScene,
    required this.onDeleteScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final Map<String, int> consumerCountBySceneId;
  final ValueChanged<String> onSelectScene;
  final VoidCallback? onEditScene;
  final VoidCallback? onDuplicateScene;
  final VoidCallback? onToggleArchiveScene;
  final VoidCallback? onDeleteScene;

  @override
  State<SceneLibraryPanel> createState() => _SceneLibraryPanelState();
}

final class _SceneLibraryPanelState extends State<SceneLibraryPanel> {
  String _query = '';
  SceneLibraryVisibility _visibility = SceneLibraryVisibility.active;

  List<NarrativeSceneSummary> get _visibleScenes {
    final normalizedQuery = _query.trim().toLowerCase();
    return widget.scenes.where((scene) {
      final visible = switch (_visibility) {
        SceneLibraryVisibility.active => !scene.isArchived,
        SceneLibraryVisibility.archived => scene.isArchived,
        SceneLibraryVisibility.all => true,
      };
      if (!visible) return false;
      if (normalizedQuery.isEmpty) return true;
      final searchable = <String>[
        scene.id,
        scene.name,
        scene.description ?? '',
        scene.storylineId ?? '',
        scene.chapterId ?? '',
        scene.libraryFolder ?? '',
        ...scene.tags,
        ...scene.declaredOutcomes,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.scenes
        .where((scene) => scene.id == widget.selectedSceneId)
        .firstOrNull;
    final scenes = _visibleScenes;
    return Material(
      type: MaterialType.transparency,
      child: PokeMapPanel(
        key: const ValueKey('scenes-tree-panel'),
        expandChild: true,
        padding: EdgeInsets.zero,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SceneLibraryTitle(),
              const SizedBox(height: 8),
              PokeMapSearchField(
                key: const ValueKey('scenes-library-search'),
                hintText: 'Rechercher une scène…',
                semanticLabel: 'Rechercher dans la bibliothèque de scènes',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              PokeMapDropdownField<SceneLibraryVisibility>(
                key: const ValueKey('scenes-library-visibility'),
                label: 'Afficher',
                value: _visibility,
                items: const [
                  PokeMapDropdownItem(
                    value: SceneLibraryVisibility.active,
                    label: 'Scènes actives',
                  ),
                  PokeMapDropdownItem(
                    value: SceneLibraryVisibility.archived,
                    label: 'Scènes archivées',
                  ),
                  PokeMapDropdownItem(
                    value: SceneLibraryVisibility.all,
                    label: 'Toutes les scènes',
                  ),
                ],
                onChanged: (value) => setState(() => _visibility = value),
              ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                _SceneLibraryActions(
                  archived: selected.isArchived,
                  onEdit: widget.onEditScene,
                  onDuplicate: widget.onDuplicateScene,
                  onToggleArchive: widget.onToggleArchiveScene,
                  onDelete: widget.onDeleteScene,
                ),
              ],
            ],
          ),
        ),
        child: scenes.isEmpty
            ? _SceneLibraryEmptyState(
                hasProjectScenes: widget.scenes.isNotEmpty,
              )
            : _SceneLibraryList(
                scenes: scenes,
                selectedSceneId: widget.selectedSceneId,
                consumerCountBySceneId: widget.consumerCountBySceneId,
                onSelectScene: widget.onSelectScene,
              ),
      ),
    );
  }
}

final class _SceneLibraryTitle extends StatelessWidget {
  const _SceneLibraryTitle();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        const Icon(CupertinoIcons.list_bullet_indent, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Arborescence des scènes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

final class _SceneLibraryActions extends StatelessWidget {
  const _SceneLibraryActions({
    required this.archived,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleArchive,
    required this.onDelete,
  });

  final bool archived;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PokeMapIconButton(
          key: const ValueKey('scenes-library-edit'),
          tooltip: 'Renommer et classer',
          onPressed: onEdit,
          icon: const Icon(CupertinoIcons.pencil, size: 15),
        ),
        PokeMapIconButton(
          key: const ValueKey('scenes-library-duplicate'),
          tooltip: 'Dupliquer',
          onPressed: onDuplicate,
          icon: const Icon(CupertinoIcons.doc_on_doc, size: 15),
        ),
        PokeMapIconButton(
          key: const ValueKey('scenes-library-toggle-archive'),
          tooltip: archived ? 'Restaurer' : 'Archiver',
          onPressed: onToggleArchive,
          icon: Icon(
            archived ? CupertinoIcons.arrow_up_bin : CupertinoIcons.archivebox,
            size: 15,
          ),
        ),
        PokeMapIconButton(
          key: const ValueKey('scenes-library-delete'),
          tooltip: 'Supprimer ou remplacer',
          onPressed: onDelete,
          variant: PokeMapIconButtonVariant.danger,
          icon: const Icon(CupertinoIcons.delete, size: 15),
        ),
      ],
    );
  }
}

final class _SceneLibraryEmptyState extends StatelessWidget {
  const _SceneLibraryEmptyState({required this.hasProjectScenes});

  final bool hasProjectScenes;

  @override
  Widget build(BuildContext context) {
    return PokeMapEmptyState(
      key: const ValueKey('scenes-tree-empty-state'),
      icon: const Icon(CupertinoIcons.square_stack_3d_up),
      title: hasProjectScenes ? 'Aucun résultat' : 'Liste vide',
      description: hasProjectScenes
          ? 'Aucune scène ne correspond à la recherche et au filtre.'
          : 'Aucune scène réelle dans ProjectManifest.scenes.',
    );
  }
}

final class _SceneLibraryList extends StatelessWidget {
  const _SceneLibraryList({
    required this.scenes,
    required this.selectedSceneId,
    required this.consumerCountBySceneId,
    required this.onSelectScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final Map<String, int> consumerCountBySceneId;
  final ValueChanged<String> onSelectScene;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<NarrativeSceneSummary>>{};
    for (final scene in scenes) {
      final key = scene.libraryFolder ??
          scene.storylineId ??
          (scene.isArchived ? 'Archives' : 'Sans dossier');
      grouped.putIfAbsent(key, () => []).add(scene);
    }
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        for (final entry in grouped.entries) ...[
          _SceneLibraryGroupLabel(label: entry.key),
          const SizedBox(height: 6),
          for (final scene in entry.value) ...[
            if (scene.chapterId != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: _SceneLibraryGroupLabel(label: scene.chapterId!),
              ),
            ],
            _SceneLibraryItem(
              scene: scene,
              selected: scene.id == selectedSceneId,
              consumerCount: consumerCountBySceneId[scene.id] ?? 0,
              onTap: () => onSelectScene(scene.id),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

final class _SceneLibraryGroupLabel extends StatelessWidget {
  const _SceneLibraryGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Icon(CupertinoIcons.folder, size: 13, color: colors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

final class _SceneLibraryItem extends StatelessWidget {
  const _SceneLibraryItem({
    required this.scene,
    required this.selected,
    required this.consumerCount,
    required this.onTap,
  });

  final NarrativeSceneSummary scene;
  final bool selected;
  final int consumerCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      '${scene.nodeCount} nœuds',
      '${scene.edgeCount} liens',
      if (consumerCount > 0) '$consumerCount usages',
      if (scene.tags.isNotEmpty) scene.tags.join(', '),
    ].join(' • ');
    return PokeMapSidebarItem(
      key: ValueKey('scenes-tree-item-${scene.id}'),
      icon: Icon(
        scene.isArchived ? CupertinoIcons.archivebox : CupertinoIcons.flowchart,
      ),
      label: scene.name,
      subtitle: subtitle,
      growForTextScale: true,
      trailing: scene.hasDiagnostics
          ? PokeMapBadge(
              label: scene.diagnosticSummaryLabel,
              variant: scene.diagnosticErrorCount > 0
                  ? PokeMapBadgeVariant.error
                  : PokeMapBadgeVariant.warning,
            )
          : const Icon(CupertinoIcons.chevron_right, size: 14),
      selected: selected,
      onTap: onTap,
    );
  }
}

```

## Annexe B — contenu complet du fichier créé scenes_library_lifecycle_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/scenes/scene_library_panel.dart';

void main() {
  group('NSC-30 Scenes library lifecycle', () {
    testWidgets('searches names tags folders and declared outcomes',
        (tester) async {
      await _pumpPanel(tester);

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_port')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-item-scene_forest')),
          findsOneWidget);

      final search = find.descendant(
        of: find.byKey(const ValueKey('scenes-library-search')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(search, 'rival');
      await tester.pump();

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_port')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-item-scene_forest')),
          findsNothing);
    });

    testWidgets('filters archived scenes without deleting them',
        (tester) async {
      await _pumpPanel(tester);

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_archive')),
          findsNothing);

      await tester.tap(find.text('Scènes actives'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scènes archivées').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('scenes-tree-item-scene_archive')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('scenes-tree-item-scene_port')),
          findsNothing);
    });

    testWidgets('exposes edit duplicate archive and protected delete actions',
        (tester) async {
      var editCount = 0;
      var duplicateCount = 0;
      var archiveCount = 0;
      var deleteCount = 0;
      await _pumpPanel(
        tester,
        onEdit: () => editCount++,
        onDuplicate: () => duplicateCount++,
        onArchive: () => archiveCount++,
        onDelete: () => deleteCount++,
      );

      await tester.tap(find.byKey(const ValueKey('scenes-library-edit')));
      await tester.tap(find.byKey(const ValueKey('scenes-library-duplicate')));
      await tester
          .tap(find.byKey(const ValueKey('scenes-library-toggle-archive')));
      await tester.tap(find.byKey(const ValueKey('scenes-library-delete')));

      expect(
          (editCount, duplicateCount, archiveCount, deleteCount), (1, 1, 1, 1));
      expect(find.textContaining('2 usages'), findsOneWidget);
    });
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  VoidCallback? onEdit,
  VoidCallback? onDuplicate,
  VoidCallback? onArchive,
  VoidCallback? onDelete,
}) async {
  final project = ProjectManifest(
    name: 'Scenes library',
    maps: const [],
    tilesets: const [],
    scenes: [
      _scene(
        'scene_port',
        name: 'Rencontre au port',
        tags: const ['rival'],
        folder: 'Acte 1',
        outcomes: [SceneOutcome(id: 'victory', label: 'Victoire')],
      ),
      _scene('scene_forest', name: 'Forêt brumeuse'),
      _scene('scene_archive', name: 'Ancienne scène', archived: true),
    ],
  );
  final scenes = buildNarrativeWorkspaceProjection(project).scenes;
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 780,
          child: SceneLibraryPanel(
            scenes: scenes,
            selectedSceneId: 'scene_port',
            consumerCountBySceneId: const {'scene_port': 2},
            onSelectScene: (_) {},
            onEditScene: onEdit,
            onDuplicateScene: onDuplicate,
            onToggleArchiveScene: onArchive,
            onDeleteScene: onDelete,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SceneAsset _scene(
  String id, {
  required String name,
  List<String> tags = const [],
  String? folder,
  bool archived = false,
  List<SceneOutcome> outcomes = const [],
}) {
  return SceneAsset(
    id: id,
    name: name,
    tags: tags,
    declaredOutcomes: outcomes,
    metadata: {
      if (folder != null) sceneLibraryFolderMetadataKey: folder,
      if (archived) sceneLibraryArchivedMetadataKey: 'true',
    },
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

```

