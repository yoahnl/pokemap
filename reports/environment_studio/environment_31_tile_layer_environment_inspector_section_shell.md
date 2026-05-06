# Environment-31 — TileLayer Environment Inspector Section Shell V0

## 1. Résumé

Environment-31 ajoute une première section UI read-only centrée TileLayer dans l’inspector du Map Editor.

Le lot ajoute :

- `TileLayerEnvironmentInspectorSection`, un widget pur qui consomme le read model Environment-30.
- une intégration minimale dans `MapInspectorPanel`, affichée quand le layer actif est un `TileLayer` ou un `EnvironmentLayer` legacy.
- un test widget ciblé couvrant les états principaux et vérifiant que les actions restent désactivées.

Le lot ne crée aucune mutation : pas d’activation d’environnement, pas de brush, pas de génération, pas de clear/regenerate/shuffle.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets et recettes d’environnement.
- Map Editor / TileLayer inspector devient le lieu naturel pour peindre, prévisualiser et générer sur une map.
- Ce lot ajoute seulement une section shell/read-only pour rendre l’état environnement compréhensible depuis le layer sélectionné.

## 3. Audit de l’existant

Fichiers Environment-30 inspectés :

- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart` : read model immuable, UI-friendly, avec état, capacités, compteurs, warnings/errors.
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart` : builder pur depuis `ProjectManifest?`, `MapData?`, `selectedLayerId`, `selectedEnvironmentAreaId`.
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart` : couverture des cas TileLayer, EnvironmentLayer legacy, target invalide, area, preset, masque et placements générés.

Points d’insertion UI inspectés :

- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` : meilleur point d’insertion. Il dispose déjà de `state.project`, `activeMap`, `state.activeLayerId` et `state.selectedEnvironmentAreaId`, sans ajouter de provider ni de mutation.
- `packages/map_editor/lib/src/ui/panels/map_properties_panel.dart` : panel map-level, pas le bon niveau pour une section liée au layer actif.
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart` : liste et actions de layers. Ce panel reste centré sur l’organisation des layers, pas sur l’inspection métier d’un TileLayer.
- `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart` : ancien inspector EnvironmentLayer conservé pour compatibilité legacy.
- `packages/map_editor/lib/src/ui/shared/inspector_section_card.dart` : wrapper visuel existant retenu pour l’intégration.
- `packages/map_editor/lib/src/ui/shared/inspector_embedded_widgets.dart` : fournit les capsules/footnotes utilisées pour rester cohérent avec les panels existants.
- `packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart` : tokens visuels `EditorChrome`, accents et surfaces existantes.
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart` : expose les champs nécessaires (`project`, `activeMapId`, `activeLayerId`, `selectedEnvironmentAreaId`).
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : contient les mutations Environment existantes, volontairement non appelées dans ce lot.
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart` : utile côté état, mais pas nécessaire pour cette intégration minimale.

Point d’insertion retenu :

`MapInspectorPanel`, juste après la section `Layers` et avant l’ancien `EnvironmentLayerInspectorPanel`.

Pourquoi c’est le moins risqué :

- il évite de modifier l’ancien inspector EnvironmentLayer ;
- il permet d’afficher la nouvelle lecture TileLayer-centric sans déplacer le workflow existant ;
- il garde l’EnvironmentLayer legacy visible et fonctionnel ;
- il construit le read model à un endroit qui possède déjà les inputs nécessaires.

## 4. UI ajoutée

Widget ajouté :

`TileLayerEnvironmentInspectorSection`

Données affichées :

- titre d’état : `Aucun environnement sur ce layer`, `Prêt à générer`, `Masque vide`, `Preset introuvable`, etc.
- message principal issu du read model.
- badge `Mode legacy` si l’utilisateur sélectionne encore un `EnvironmentLayer`.
- résumé compact : layer, preset, zone, masque, placements générés.
- warnings/errors en français.
- actions futures désactivées : activer l’environnement, peindre le masque, générer dans ce layer, effacer les placements générés.

États couverts par le test widget :

- TileLayer sans environnement attaché.
- bouton `Activer l’environnement` visible mais désactivé.
- état prêt avec preset, zone et masque.
- compteur de placements générés.
- warning de placements générés manquants.
- erreur de preset manquant.
- sélection legacy EnvironmentLayer.
- action `Générer dans ce layer` visible mais désactivée.

## 5. Intégration au read model

`MapInspectorPanel` construit le read model via :

```dart
buildTileLayerEnvironmentAttachmentReadModel(
  manifest: state.project,
  map: activeMap,
  selectedLayerId: state.activeLayerId,
  selectedEnvironmentAreaId: state.selectedEnvironmentAreaId,
)
```

La section UI reçoit uniquement `TileLayerEnvironmentAttachmentReadModel`.

La logique de résolution n’est pas dupliquée dans le widget : le widget ne parcourt pas `map.layers`, ne lit pas `targetTileLayerId` et ne recalcule pas les placements manquants. Il affiche les champs déjà exposés par le read model.

## 6. Tests

Commande lancée :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
00:00 +8: All tests passed!
```

Commande de non-régression Environment-30 :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
00:00 +21: All tests passed!
```

Cas couverts :

- affiche “Aucun environnement sur ce layer”.
- affiche “Activer l’environnement” sans callback de mutation.
- affiche un état prêt avec preset, zone et nombre de cases du masque.
- affiche le nombre de placements générés.
- affiche un warning si des placements générés sont manquants.
- affiche une erreur si le preset est manquant.
- affiche un message legacy.
- n’affiche pas d’action active de génération dans ce lot.

## 7. Analyse ciblée

Analyse large demandée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/ui/panels test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
15 issues found. (ran in 3.7s)
```

Cette commande inclut tout `lib/src/ui/panels`, donc elle remonte des infos préexistantes hors lot dans :

- `lib/src/ui/panels/character_library_panel.dart`
- `lib/src/ui/panels/element_collision_editor_sheet.dart`
- `lib/src/ui/panels/event_properties_panel.dart`

Elle a aussi signalé une info `prefer_const_constructors` dans le nouveau widget. Cette ligne a été corrigée.

Analyse ciblée finale sur les fichiers concernés par Environment-30/31 :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
No issues found! (ran in 2.2s)
```

## 8. Fichiers créés/modifiés

Fichiers créés par Environment-31 :

- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `reports/environment_studio/environment_31_tile_layer_environment_inspector_section_shell.md`

Fichier modifié par Environment-31 :

- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

Fichiers préexistants dans le worktree avant Environment-31, non modifiés par ce lot :

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart`
- `packages/map_editor/test/tileset_grid_metrics_test.dart`
- `reports/environment_studio/environment_studio_map_centric_workflow_review.md`

## 9. Non-objectifs respectés

- pas de mutation ;
- pas d’auto-création d’EnvironmentLayer ;
- pas de brush ;
- pas de generate ;
- pas de clear/regenerate/shuffle ;
- pas de migration ;
- pas de modification de `map_core` ;
- pas de modification runtime ;
- pas de modification gameplay/battle ;
- pas de build_runner ;
- pas de generated files ;
- pas de suppression ou déplacement de l’ancien `EnvironmentLayerInspectorPanel`.

## 10. Evidence pack

Git status initial :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

`git diff --stat` avant création du rapport :

```text
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  34 ++
 .../src/ui/canvas/map_canvas/map_grid_painter.dart | 138 ++++++++-
 .../lib/src/ui/canvas/tileset_editor_canvas.dart   | 344 +++++++++++----------
 .../lib/src/ui/panels/map_inspector_panel.dart     |  32 ++
 4 files changed, 375 insertions(+), 173 deletions(-)
```

`git diff --name-only` avant création du rapport :

```text
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
```

Commandes principales :

```bash
git status --short --untracked-files=all
sed -n '1,260p' packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
sed -n '1,320p' packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
sed -n '1,360p' packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
sed -n '1,520p' packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/map_properties_panel.dart
sed -n '1,620p' packages/map_editor/lib/src/ui/panels/layers_panel.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/shared/inspector_section_card.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/shared/inspector_embedded_widgets.dart
sed -n '1,620p' packages/map_editor/lib/src/ui/shared/cupertino_editor_widgets.dart
rg -n "TileLayer|EnvironmentLayer|MapLayer|selectedLayer|selectedLayerId|InspectorSectionCard|MapInspectorPanel|MapPropertiesPanel|EnvironmentLayerInspectorPanel|LayersPanel" packages/map_editor/lib/src/ui packages/map_editor/lib/src/features/editor packages/map_editor/lib/src/application
dart format lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

Résultats de tests :

```text
TileLayerEnvironmentInspectorSection : 00:00 +8: All tests passed!
TileLayerEnvironmentAttachmentReadModel : 00:00 +21: All tests passed!
```

Résultat d’analyse ciblée finale :

```text
No issues found! (ran in 2.2s)
```

Git status final après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_31_tile_layer_environment_inspector_section_shell.md
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

## 11. Contenu complet des fichiers créés/modifiés par ce lot

Le présent rapport n’est pas inclus dans son propre contenu complet pour éviter une récursion. Les fichiers de code/test créés ou modifiés par Environment-31 sont inclus ci-dessous.

### `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`

```dart
import 'package:flutter/cupertino.dart';

import '../../application/models/tile_layer_environment_attachment_read_model.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

class TileLayerEnvironmentInspectorSection extends StatelessWidget {
  const TileLayerEnvironmentInspectorSection({
    super.key,
    required this.readModel,
  });

  final TileLayerEnvironmentAttachmentReadModel readModel;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.inspectorJoyMint;
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return SingleChildScrollView(
      padding: kInspectorTileBodyPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _stateTitle(readModel),
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (readModel.isLegacyEnvironmentLayerSelection)
                const _StatusPill(
                  label: 'Mode legacy',
                  accent: accent,
                ),
            ],
          ),
          if (readModel.emptyStateMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              readModel.emptyStateMessage,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                height: 1.32,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SummaryRows(readModel: readModel),
          if (readModel.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...readModel.issues.map(
              (issue) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _IssueBanner(issue: issue),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _FutureActions(readModel: readModel),
          const SizedBox(height: 8),
          const InspectorEmbeddedFootnote(
            text:
                'Section de lecture uniquement : les actions seront activées dans un prochain lot.',
            accent: accent,
          ),
        ],
      ),
    );
  }
}

class _SummaryRows extends StatelessWidget {
  const _SummaryRows({required this.readModel});

  final TileLayerEnvironmentAttachmentReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final rows = <_SummaryRowData>[];
    final activeTileLayerName = readModel.activeTileLayerName?.trim();
    if (activeTileLayerName != null && activeTileLayerName.isNotEmpty) {
      rows.add(_SummaryRowData('Layer', activeTileLayerName));
    }
    final presetName = readModel.selectedPresetName?.trim();
    final presetId = readModel.selectedPresetId?.trim();
    if (presetName != null && presetName.isNotEmpty) {
      rows.add(_SummaryRowData('Preset', presetName));
    } else if (presetId != null && presetId.isNotEmpty) {
      rows.add(_SummaryRowData('Preset', '$presetId introuvable'));
    }
    final areaName = readModel.selectedEnvironmentAreaName?.trim();
    if (areaName != null && areaName.isNotEmpty) {
      rows.add(_SummaryRowData('Zone', areaName));
    }
    if (readModel.hasAttachment || readModel.maskActiveCellCount > 0) {
      rows.add(
        _SummaryRowData(
          'Masque',
          _paintedCellsLabel(readModel.maskActiveCellCount),
        ),
      );
    }
    if (readModel.hasGeneratedPlacements ||
        readModel.generatedPlacementCount > 0) {
      rows.add(
        _SummaryRowData(
          'Placements générés',
          '${readModel.generatedPlacementCount}',
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SummaryRow(row: row),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.row});

  final _SummaryRowData row;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${row.label} : ${row.value}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueBanner extends StatelessWidget {
  const _IssueBanner({required this.issue});

  final TileLayerEnvironmentAttachmentIssue issue;

  @override
  Widget build(BuildContext context) {
    final isError =
        issue.severity == TileLayerEnvironmentAttachmentIssueSeverity.error;
    final accent = isError
        ? CupertinoColors.systemRed.resolveFrom(context)
        : CupertinoColors.systemOrange.resolveFrom(context);
    final prefix = isError ? 'Erreur' : 'Attention';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.09),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        '$prefix : ${issue.message}',
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 11.5,
          height: 1.28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({required this.readModel});

  final TileLayerEnvironmentAttachmentReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionData>[];
    if (readModel.canEnableEnvironment) {
      actions.add(
        _ActionData(
          icon: CupertinoIcons.add_circled,
          label: readModel.primaryActionLabel ?? 'Activer l’environnement',
        ),
      );
    }
    if (readModel.canPaintMask) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.paintbrush,
          label: 'Peindre le masque',
        ),
      );
    }
    if (readModel.canGenerate) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.play,
          label: 'Générer dans ce layer',
        ),
      );
    }
    if (readModel.canClearGeneratedPlacements) {
      actions.add(
        const _ActionData(
          icon: CupertinoIcons.trash,
          label: 'Effacer les placements générés',
        ),
      );
    }

    if (actions.isEmpty) {
      return InspectorEmbeddedSecondaryCapsule(
        accent: EditorChrome.inspectorJoyMint,
        icon: CupertinoIcons.clock,
        label: 'Actions bientôt disponibles',
        enabled: false,
        onPressed: () {},
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final action in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: InspectorEmbeddedPrimaryCapsule(
              accent: EditorChrome.inspectorJoyMint,
              icon: action.icon,
              label: action.label,
              enabled: false,
              onPressed: () {},
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryRowData {
  const _SummaryRowData(this.label, this.value);

  final String label;
  final String value;
}

class _ActionData {
  const _ActionData({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

String _stateTitle(TileLayerEnvironmentAttachmentReadModel model) {
  final title = model.emptyStateTitle.trim();
  if (title.isNotEmpty) {
    return title;
  }
  return switch (model.state) {
    TileLayerEnvironmentAttachmentState.ready => 'Prêt à générer',
    TileLayerEnvironmentAttachmentState.generated => 'Placements générés',
    TileLayerEnvironmentAttachmentState.emptyMask => 'Masque vide',
    TileLayerEnvironmentAttachmentState.missingPreset => 'Preset introuvable',
    TileLayerEnvironmentAttachmentState.noAttachment =>
      'Aucun environnement sur ce layer',
    TileLayerEnvironmentAttachmentState.noArea => 'Aucune zone d’environnement',
    TileLayerEnvironmentAttachmentState.areaSelectionRequired =>
      'Sélectionnez une zone d’environnement',
    TileLayerEnvironmentAttachmentState.selectedAreaMissing =>
      'Zone introuvable',
    TileLayerEnvironmentAttachmentState.missingTargetTileLayer =>
      'Layer cible manquant',
    TileLayerEnvironmentAttachmentState.targetTileLayerMissing =>
      'Layer cible introuvable',
    TileLayerEnvironmentAttachmentState.targetLayerIsNotTileLayer =>
      'Layer cible incompatible',
    TileLayerEnvironmentAttachmentState.noProject => 'Aucun projet chargé',
    TileLayerEnvironmentAttachmentState.noMap => 'Aucune carte active',
    TileLayerEnvironmentAttachmentState.noLayerSelected =>
      'Aucun layer sélectionné',
    TileLayerEnvironmentAttachmentState.selectedLayerMissing =>
      'Layer introuvable',
    TileLayerEnvironmentAttachmentState.unsupportedLayer =>
      'Sélectionnez un TileLayer',
  };
}

String _paintedCellsLabel(int count) {
  if (count <= 0) {
    return '0 case peinte';
  }
  if (count == 1) {
    return '1 case peinte';
  }
  return '$count cases peintes';
}
```

### `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/tile_layer_environment_attachment_read_model.dart';
import 'package:map_editor/src/ui/panels/tile_layer_environment_inspector_section.dart';

void main() {
  group('TileLayerEnvironmentInspectorSection', () {
    testWidgets('affiche Aucun environnement sur ce layer', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.noAttachment,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          canEnableEnvironment: true,
          emptyStateTitle: 'Aucun environnement sur ce layer',
          emptyStateMessage:
              'Activez l’environnement pour peindre une zone organique sur ce layer.',
          primaryActionLabel: 'Activer l’environnement',
        ),
      );

      expect(find.text('Aucun environnement sur ce layer'), findsOneWidget);
      expect(
        find.text(
          'Activez l’environnement pour peindre une zone organique sur ce layer.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('affiche Activer l’environnement sans callback de mutation',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.noAttachment,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          canEnableEnvironment: true,
          emptyStateTitle: 'Aucun environnement sur ce layer',
          emptyStateMessage:
              'Activez l’environnement pour peindre une zone organique sur ce layer.',
          primaryActionLabel: 'Activer l’environnement',
        ),
      );

      expect(find.text('Activer l’environnement'), findsOneWidget);
      expect(_buttonFor(tester, 'Activer l’environnement').onPressed, isNull);
    });

    testWidgets('affiche un état prêt avec preset zone et masque',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'zone_nord',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetId: 'forest',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
        ),
      );

      expect(find.text('Prêt à générer'), findsOneWidget);
      expect(find.text('Preset : Forêt'), findsOneWidget);
      expect(find.text('Zone : Bosquet nord'), findsOneWidget);
      expect(find.text('Masque : 42 cases peintes'), findsOneWidget);
    });

    testWidgets('affiche le nombre de placements générés', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.generated,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          generatedPlacementCount: 18,
          hasGeneratedPlacements: true,
          canClearGeneratedPlacements: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
      );

      expect(find.text('Placements générés : 18'), findsOneWidget);
    });

    testWidgets('affiche un warning si des placements sont manquants',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.generated,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          generatedPlacementCount: 18,
          missingGeneratedPlacementCount: 3,
          hasGeneratedPlacements: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
          issues: [
            TileLayerEnvironmentAttachmentIssue(
              severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
              message: '3 placements générés référencés sont introuvables.',
            ),
          ],
        ),
      );

      expect(
        find.text(
          'Attention : 3 placements générés référencés sont introuvables.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('affiche une erreur si le preset est manquant', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.missingPreset,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetId: 'forest',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Preset introuvable',
          emptyStateMessage:
              'Choisissez un preset disponible avant de générer cette zone.',
          issues: [
            TileLayerEnvironmentAttachmentIssue(
              severity: TileLayerEnvironmentAttachmentIssueSeverity.error,
              message:
                  'Le preset d’environnement utilisé par cette zone est introuvable.',
            ),
          ],
        ),
      );

      expect(find.text('Preset introuvable'), findsOneWidget);
      expect(
        find.text(
          'Erreur : Le preset d’environnement utilisé par cette zone est introuvable.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('affiche un message legacy', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.environment,
          isLegacyEnvironmentLayerSelection: true,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          issues: [
            TileLayerEnvironmentAttachmentIssue(
              severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
              message:
                  'Cet environnement est attaché à un TileLayer. La prochaine UX le pilotera depuis le layer cible.',
            ),
          ],
        ),
      );

      expect(find.text('Mode legacy'), findsOneWidget);
      expect(
        find.text(
          'Attention : Cet environnement est attaché à un TileLayer. La prochaine UX le pilotera depuis le layer cible.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('n’affiche pas d’action active de génération dans ce lot',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
        ),
      );

      expect(find.text('Générer dans ce layer'), findsOneWidget);
      expect(_buttonFor(tester, 'Générer dans ce layer').onPressed, isNull);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  TileLayerEnvironmentAttachmentReadModel model,
) {
  return tester.pumpWidget(
    CupertinoApp(
      home: CupertinoPageScaffold(
        child: SizedBox(
          width: 360,
          height: 520,
          child: TileLayerEnvironmentInspectorSection(readModel: model),
        ),
      ),
    ),
  );
}

CupertinoButton _buttonFor(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(CupertinoButton),
  );
  return tester.widget<CupertinoButton>(finder.first);
}
```

### `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../application/models/terrain_selection_mode.dart';
import '../../application/services/tile_layer_environment_attachment_read_model_builder.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../../features/surface_painter/surface_palette_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';
import 'encounter_tables_panel.dart';
import 'entity_properties_panel.dart';
import 'event_properties_panel.dart';
import 'gameplay_zone_properties_panel.dart';
import 'environment_layer_inspector_panel.dart';
import 'layers_panel.dart';
import 'map_connections_panel.dart';
import 'map_properties_panel.dart';
import 'terrain_map_panel.dart';
import 'tile_layer_environment_inspector_section.dart';
import 'tileset_palette_panel.dart';
import 'trigger_properties_panel.dart';
import 'warp_properties_panel.dart';

enum _InspectorSectionId {
  mapProperties,
  layers,
  tileLayerEnvironment,
  environmentLayer,
  tiles,
  ground,
  surfacePlacements,
  surfaces,
  entities,
  events,
  connections,
  triggers,
  warps,
  gameplayZones,
  encounterTables,
}

class MapInspectorPanel extends ConsumerStatefulWidget {
  const MapInspectorPanel({super.key});

  @override
  ConsumerState<MapInspectorPanel> createState() => _MapInspectorPanelState();
}

class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
  final Map<_InspectorSectionId, bool> _expandedSections =
      <_InspectorSectionId, bool>{};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final activeMap = state.activeMap;
    final activeLayer = _findActiveLayer(activeMap, state.activeLayerId);

    if (activeMap == null) {
      return Container(
        alignment: Alignment.center,
        child: Text(
          'Open a map to inspect layers and map systems',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final hasTileLayers = activeMap.layers.any((layer) => layer is TileLayer);
    final hasTerrainLayers =
        activeMap.layers.any((layer) => layer is TerrainLayer);
    final hasPathLayers = activeMap.layers.any((layer) => layer is PathLayer);
    final hasSurfaceLayers =
        activeMap.layers.any((layer) => layer is SurfaceLayer);
    final hasSurfacePresets =
        state.project?.surfaceCatalog.presets.isNotEmpty ?? false;
    final showTileLayerEnvironmentSection =
        activeLayer is TileLayer || activeLayer is EnvironmentLayer;
    final tileLayerEnvironmentReadModel = showTileLayerEnvironmentSection
        ? buildTileLayerEnvironmentAttachmentReadModel(
            manifest: state.project,
            map: activeMap,
            selectedLayerId: state.activeLayerId,
            selectedEnvironmentAreaId: state.selectedEnvironmentAreaId,
          )
        : null;
    final showEnvironmentLayerSection = activeLayer is EnvironmentLayer;
    final showTilesSection = activeLayer is TileLayer ||
        state.activeTool == EditorToolType.tilePaint ||
        (state.activeLayerId == null && hasTileLayers);
    final showGroundSection = hasTerrainLayers &&
        (activeLayer is TerrainLayer ||
            (activeLayer is! PathLayer &&
                state.activeTool == EditorToolType.terrainPaint &&
                state.terrainSelectionMode == TerrainSelectionMode.terrain));
    final showSurfaceSection = hasPathLayers && activeLayer is PathLayer;
    final showSurfacePlacementSection = hasSurfaceLayers ||
        hasSurfacePresets ||
        activeLayer is SurfaceLayer ||
        state.activeTool == EditorToolType.surfacePaint;
    const showConnectionsSection = true;
    final showEntitySection =
        state.activeTool == EditorToolType.entityPlacement ||
            state.selectedEntityId != null ||
            activeMap.entities.isNotEmpty;
    final showEventSection =
        state.activeTool == EditorToolType.eventPlacement ||
            state.selectedMapEventId != null ||
            activeMap.events.isNotEmpty;
    final showTriggerSection =
        state.activeTool == EditorToolType.triggerPlacement ||
            state.selectedTriggerId != null ||
            activeMap.triggers.isNotEmpty;
    final showWarpSection = state.activeTool == EditorToolType.warpPlacement ||
        state.selectedWarpId != null ||
        activeMap.warps.isNotEmpty;
    final showGameplayZoneSection =
        state.activeTool == EditorToolType.gameplayZonePlacement ||
            state.selectedGameplayZoneId != null ||
            activeMap.gameplayZones.isNotEmpty;
    final showEncounterTablesSection =
        (state.project?.encounterTables.isNotEmpty ?? false) ||
            showGameplayZoneSection;

    return LayoutBuilder(
      builder: (context, constraints) {
        final paletteHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(420.0, 760.0).toDouble()
            : 560.0;

        return SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.only(top: 10, bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _InspectorOverviewCard(
                map: activeMap,
                activeLayer: activeLayer,
              ),
              InspectorSectionCard(
                title: 'Propriétés de carte',
                subtitle:
                    'Gameplay et présentation (météo, musique, spawn par défaut…)',
                icon: CupertinoIcons.slider_horizontal_3,
                accentColor: EditorChrome.inspectorJoyPlum,
                expanded: _isExpanded(
                  _InspectorSectionId.mapProperties,
                  false,
                ),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.mapProperties,
                  defaultExpanded: false,
                ),
                expandedHeight: 460,
                child: const MapPropertiesPanel(embedded: true),
              ),
              InspectorSectionCard(
                title: 'Layers',
                subtitle: activeLayer == null
                    ? 'Select the active layer for this map'
                    : 'Active: ${_layerLabel(activeLayer)}',
                icon: CupertinoIcons.layers,
                badgeText: '${activeMap.layers.length}',
                accentColor: EditorChrome.inspectorJoyBlue,
                expanded: _isExpanded(_InspectorSectionId.layers, true),
                onToggle: () => _toggleSection(
                  _InspectorSectionId.layers,
                  defaultExpanded: true,
                ),
                expandedHeight: 260,
                child: const LayersPanel(embedded: true),
              ),
              if (tileLayerEnvironmentReadModel != null)
                InspectorSectionCard(
                  title: 'Environnement du layer',
                  subtitle: tileLayerEnvironmentReadModel.emptyStateTitle,
                  icon: CupertinoIcons.tree,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.tileLayerEnvironment,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.tileLayerEnvironment,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 320,
                  child: TileLayerEnvironmentInspectorSection(
                    readModel: tileLayerEnvironmentReadModel,
                  ),
                ),
              if (showEnvironmentLayerSection)
                InspectorSectionCard(
                  title: 'Environment Layer',
                  subtitle: null,
                  icon: CupertinoIcons.cloud,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.environmentLayer,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.environmentLayer,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 560,
                  child: EnvironmentLayerInspectorPanel(
                    map: activeMap,
                    layer: activeLayer,
                    embedded: true,
                  ),
                ),
              if (showTilesSection)
                InspectorSectionCard(
                  title: 'Tiles & Elements',
                  subtitle:
                      'Palette de placement et gestion des instances posées sur le layer actif.',
                  icon: CupertinoIcons.square_grid_2x2,
                  accentColor: EditorChrome.inspectorJoyLilac,
                  expanded: _isExpanded(
                    _InspectorSectionId.tiles,
                    activeLayer is TileLayer ||
                        state.activeTool == EditorToolType.tilePaint,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.tiles,
                    defaultExpanded: activeLayer is TileLayer ||
                        state.activeTool == EditorToolType.tilePaint,
                  ),
                  expandedHeight: paletteHeight,
                  child: const TilesetPalettePanel(embedded: true),
                ),
              if (showGroundSection)
                InspectorSectionCard(
                  title: 'Base Ground',
                  subtitle: 'Terrain-only editing for the map background.',
                  icon: CupertinoIcons.tree,
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.ground,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.ground,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 300,
                  child: const TerrainMapPanel(
                    embedded: true,
                    mode: TerrainMapPanelMode.groundOnly,
                  ),
                ),
              if (showSurfacePlacementSection)
                InspectorSectionCard(
                  title: 'Surfaces',
                  subtitle:
                      'Choisir une surface et poser des placements dans la map.',
                  icon: CupertinoIcons.drop,
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.surfacePlacements,
                    activeLayer is SurfaceLayer ||
                        state.activeTool == EditorToolType.surfacePaint,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.surfacePlacements,
                    defaultExpanded: activeLayer is SurfaceLayer ||
                        state.activeTool == EditorToolType.surfacePaint,
                  ),
                  expandedHeight: 380,
                  child: const SurfacePainterPanel(embedded: true),
                ),
              if (showSurfaceSection)
                InspectorSectionCard(
                  title: 'Paths',
                  subtitle:
                      'Edit the active path layer for roads and specialized surfaces.',
                  icon: CupertinoIcons.map,
                  accentColor: EditorChrome.inspectorJoyAmber,
                  expanded: _isExpanded(
                    _InspectorSectionId.surfaces,
                    true,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.surfaces,
                    defaultExpanded: true,
                  ),
                  expandedHeight: 340,
                  child: const TerrainMapPanel(
                    embedded: true,
                    mode: TerrainMapPanelMode.surfaceOnly,
                  ),
                ),
              if (showEntitySection)
                InspectorSectionCard(
                  title: 'Map Entities',
                  subtitle: state.selectedEntityId != null
                      ? 'Selected entity ready for editing.'
                      : 'Visible world content such as NPCs, signs, items and spawn points.',
                  icon: CupertinoIcons.sparkles,
                  badgeText: '${activeMap.entities.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.entities,
                    state.activeTool == EditorToolType.entityPlacement ||
                        state.selectedEntityId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.entities,
                    defaultExpanded:
                        state.activeTool == EditorToolType.entityPlacement ||
                            state.selectedEntityId != null,
                  ),
                  expandedHeight: 560,
                  child: const EntityPropertiesPanel(embedded: true),
                ),
              if (showEventSection)
                InspectorSectionCard(
                  title: 'Map Events',
                  subtitle: state.selectedMapEventId != null
                      ? 'Selected event ready for editing.'
                      : 'Conditional event pages and script/message authoring.',
                  icon: CupertinoIcons.flag,
                  badgeText: '${activeMap.events.length}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.events,
                    state.activeTool == EditorToolType.eventPlacement ||
                        state.selectedMapEventId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.events,
                    defaultExpanded:
                        state.activeTool == EditorToolType.eventPlacement ||
                            state.selectedMapEventId != null,
                  ),
                  expandedHeight: 620,
                  child: const EventPropertiesPanel(embedded: true),
                ),
              if (showConnectionsSection)
                InspectorSectionCard(
                  title: 'Connections',
                  subtitle: 'Link the current map to adjacent world maps.',
                  icon: CupertinoIcons.arrow_branch,
                  badgeText: '${activeMap.connections.length}',
                  accentColor: EditorChrome.inspectorJoyPlum,
                  expanded: _isExpanded(_InspectorSectionId.connections, false),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.connections,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 520,
                  child: const MapConnectionsPanel(embedded: true),
                ),
              if (showTriggerSection)
                InspectorSectionCard(
                  title: 'Triggers',
                  subtitle: state.selectedTriggerId != null
                      ? 'Selected trigger ready for editing.'
                      : 'Gameplay zones and editable trigger areas.',
                  icon: CupertinoIcons.square,
                  badgeText: '${activeMap.triggers.length}',
                  accentColor: EditorChrome.inspectorJoyCoral,
                  expanded: _isExpanded(
                    _InspectorSectionId.triggers,
                    state.activeTool == EditorToolType.triggerPlacement ||
                        state.selectedTriggerId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.triggers,
                    defaultExpanded:
                        state.activeTool == EditorToolType.triggerPlacement ||
                            state.selectedTriggerId != null,
                  ),
                  expandedHeight: 520,
                  child: const TriggerPropertiesPanel(embedded: true),
                ),
              if (showWarpSection)
                InspectorSectionCard(
                  title: 'Warps',
                  subtitle: state.selectedWarpId != null
                      ? 'Selected warp ready for editing.'
                      : 'Map transitions such as doors, stairs and exits.',
                  icon: CupertinoIcons.arrow_down_circle,
                  badgeText: '${activeMap.warps.length}',
                  accentColor: EditorChrome.inspectorJoyOrchid,
                  expanded: _isExpanded(
                    _InspectorSectionId.warps,
                    state.activeTool == EditorToolType.warpPlacement ||
                        state.selectedWarpId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.warps,
                    defaultExpanded:
                        state.activeTool == EditorToolType.warpPlacement ||
                            state.selectedWarpId != null,
                  ),
                  expandedHeight: 320,
                  child: const WarpPropertiesPanel(embedded: true),
                ),
              if (showGameplayZoneSection)
                InspectorSectionCard(
                  title: 'Gameplay Zones',
                  subtitle: state.selectedGameplayZoneId != null
                      ? 'Selected zone ready for editing.'
                      : 'Encounter areas, movement constraints and special zones.',
                  icon: CupertinoIcons.leaf_arrow_circlepath,
                  badgeText: '${activeMap.gameplayZones.length}',
                  accentColor: EditorChrome.inspectorJoyMint,
                  expanded: _isExpanded(
                    _InspectorSectionId.gameplayZones,
                    state.activeTool == EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.gameplayZones,
                    defaultExpanded: state.activeTool ==
                            EditorToolType.gameplayZonePlacement ||
                        state.selectedGameplayZoneId != null,
                  ),
                  expandedHeight: 520,
                  child: const GameplayZonePropertiesPanel(embedded: true),
                ),
              if (showEncounterTablesSection)
                InspectorSectionCard(
                  title: 'Encounter Tables',
                  subtitle: 'Project-level encounter tables for wild Pokémon.',
                  icon: CupertinoIcons.list_bullet,
                  badgeText: '${state.project?.encounterTables.length ?? 0}',
                  accentColor: EditorChrome.inspectorJoyCyan,
                  expanded: _isExpanded(
                    _InspectorSectionId.encounterTables,
                    false,
                  ),
                  onToggle: () => _toggleSection(
                    _InspectorSectionId.encounterTables,
                    defaultExpanded: false,
                  ),
                  expandedHeight: 480,
                  child: const EncounterTablesPanel(embedded: true),
                ),
            ],
          ),
        );
      },
    );
  }

  bool _isExpanded(_InspectorSectionId section, bool defaultExpanded) {
    return _expandedSections[section] ?? defaultExpanded;
  }

  void _toggleSection(
    _InspectorSectionId section, {
    required bool defaultExpanded,
  }) {
    setState(() {
      _expandedSections[section] =
          !(_expandedSections[section] ?? defaultExpanded);
    });
  }

  MapLayer? _findActiveLayer(MapData? map, String? activeLayerId) {
    if (map == null || activeLayerId == null) {
      return null;
    }
    for (final layer in map.layers) {
      if (layer.id == activeLayerId) {
        return layer;
      }
    }
    return null;
  }

  String _layerLabel(MapLayer layer) {
    return switch (layer) {
      TileLayer _ => 'Tile Layer',
      CollisionLayer _ => 'Collision Layer',
      TerrainLayer _ => 'Terrain Layer',
      PathLayer _ => 'Path Layer',
      SurfaceLayer _ => 'Surface Layer',
      ObjectLayer _ => 'Object Layer',
      EnvironmentLayer _ => 'Environment Layer',
    };
  }
}

class _InspectorOverviewCard extends StatelessWidget {
  const _InspectorOverviewCard({
    required this.map,
    required this.activeLayer,
  });

  final MapData map;
  final MapLayer? activeLayer;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const accentA = EditorChrome.inspectorJoyHoney;
    const accentB = EditorChrome.inspectorJoyApricot;
    final activeLayerText = activeLayer == null
        ? 'No active layer'
        : switch (activeLayer!) {
            TileLayer _ => 'Tile layer active',
            TerrainLayer _ => 'Ground layer active',
            PathLayer _ => 'Surface layer active',
            SurfaceLayer _ => 'Surface placement layer active',
            CollisionLayer _ => 'Collision layer active',
            ObjectLayer _ => 'Object layer active',
            EnvironmentLayer _ => 'Environment layer active',
          };

    final hi = EditorChrome.islandFillElevated(context);
    final lo = EditorChrome.islandFill(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 10, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(hi, accentA, 0.44)!,
            Color.lerp(lo, accentB, 0.38)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(accentA, accentB, 0.5)!.withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: EditorChrome.inspectorTileHardShadows(context),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, accentA, 0.78)!,
                  Color.lerp(accentB, const Color(0xFF1A0804), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentA.withValues(alpha: 0.9),
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.slider_horizontal_3,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  map.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${map.size.width} x ${map.size.height} tiles  •  ${map.layers.length} layers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeLayerText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## 12. Auto-review

- Le widget est-il read-only ? Oui. Les capsules utilisent `enabled: false`, donc les `CupertinoButton` n’ont pas de callback actif.
- Le read model est-il utilisé sans duplication ? Oui. Le widget consomme uniquement `TileLayerEnvironmentAttachmentReadModel`.
- Le flow legacy reste-t-il intact ? Oui. `EnvironmentLayerInspectorPanel` reste affiché quand un `EnvironmentLayer` est sélectionné.
- L’UI évite-t-elle le jargon technique ? Oui pour les messages principaux : “Environnement du layer”, “Aucun environnement sur ce layer”, “Masque”, “Placements générés”, “Prêt à générer”.
- Les actions mutantes sont-elles absentes ou désactivées ? Oui.
- Les tests ciblés passent-ils ? Oui, 8/8 pour la section et 21/21 pour le read model.
- L’analyse ciblée passe-t-elle ? Oui, sur les fichiers Environment-30/31.
- Aucun commit n’a-t-il été fait ? Oui, aucun commit ni git write op.

## 13. Critique du prompt et du lot

Ce qui était clair :

- le lot est strictement read-only ;
- la séparation produit Environment Studio / Map Editor est nette ;
- les états UI attendus étaient suffisamment précis ;
- les non-objectifs empêchent une dérive vers une vraie migration.

Ce qui était ambigu :

- le point exact d’insertion pouvait être `MapInspectorPanel` ou un panel TileLayer dédié inexistant. `MapInspectorPanel` est le choix minimal.
- afficher ou non la section pour un `EnvironmentLayer` legacy. Le lot demande de pouvoir afficher un message legacy sans casser l’ancien flow, donc la section est affichée en plus de l’ancien inspector.
- le rapport demande le contenu complet des fichiers créés/modifiés ; le présent rapport ne peut pas s’inclure lui-même sans récursion.

À trancher avant Environment-32 :

- le bouton “Activer l’environnement” doit-il créer un nouvel `EnvironmentLayer` technique ou réutiliser un EnvironmentLayer existant non attaché ?
- où placer ce layer technique dans l’ordre de layers ?
- faut-il sélectionner automatiquement l’area créée, ou seulement attacher le layer et laisser l’utilisateur ajouter une zone ?
- faut-il commencer à masquer les EnvironmentLayers techniques plus tard, ou seulement les regrouper visuellement sous le TileLayer ?

## 14. Verdict

```text
Environment-31 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-32 — TileLayer Environment Attachment Enable Action V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/switch/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] Je n’ai pas ajouté de mutation Environment.
- [x] Je n’ai pas auto-créé d’EnvironmentLayer.
- [x] Je n’ai pas déplacé Environment Studio.
- [x] J’ai utilisé le read model Environment-30.
- [x] J’ai ajouté une section TileLayer-centric lisible.
- [x] Les actions mutantes sont absentes ou désactivées.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport contient le contenu complet des fichiers créés/modifiés par ce lot.
