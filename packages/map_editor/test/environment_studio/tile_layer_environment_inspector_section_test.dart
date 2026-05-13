import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
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

      expect(find.text('État de génération'), findsOneWidget);
      expect(find.text('Aucun environnement sur ce layer'), findsOneWidget);
      expect(
        find.text(
          'Activez l’environnement pour peindre une zone organique sur ce layer.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Action recommandée : Activer l’environnement'),
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

    testWidgets('active Activer l’environnement avec callback', (tester) async {
      var pressed = 0;
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
        onEnableEnvironment: () {
          pressed++;
        },
      );

      final button = _buttonFor(tester, 'Activer l’environnement');
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('Activer l’environnement'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('bloque Ajouter une zone si aucun preset existe',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.noArea,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Aucune zone d’environnement',
          emptyStateMessage:
              'Ajoutez une zone, choisissez un preset, puis peignez le masque.',
          primaryActionLabel: 'Ajouter une zone',
        ),
      );

      expect(find.text('État de génération'), findsOneWidget);
      expect(find.text('Aucune zone d’environnement'), findsOneWidget);
      expect(
        find.text('Action recommandée : Ajouter une zone'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Créez d’abord un preset dans Environment Studio avant d’ajouter une zone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ajouter une zone'), findsOneWidget);
      expect(_buttonFor(tester, 'Ajouter une zone').onPressed, isNull);
    });

    testWidgets('active Ajouter une zone avec un preset unique',
        (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.noArea,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Aucune zone d’environnement',
          emptyStateMessage:
              'Ajoutez une zone, choisissez un preset, puis peignez le masque.',
          primaryActionLabel: 'Ajouter une zone',
        ),
        availablePresets: const [
          TileLayerEnvironmentPresetOption(id: 'forest', name: 'Forêt'),
        ],
        selectedPresetIdForNewArea: 'forest',
        onCreateArea: () {
          pressed++;
        },
      );

      expect(find.text('Preset utilisé : Forêt'), findsOneWidget);
      final button = _buttonFor(tester, 'Ajouter une zone');
      expect(button.onPressed, isNotNull);

      await tester.ensureVisible(find.text('Ajouter une zone'));
      await tester.tap(find.text('Ajouter une zone'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('bloque Ajouter une zone avec plusieurs presets sans sélection',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.noArea,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Aucune zone d’environnement',
          emptyStateMessage:
              'Ajoutez une zone, choisissez un preset, puis peignez le masque.',
          primaryActionLabel: 'Ajouter une zone',
        ),
        availablePresets: const [
          TileLayerEnvironmentPresetOption(id: 'forest', name: 'Forêt'),
          TileLayerEnvironmentPresetOption(id: 'rocks', name: 'Rochers'),
        ],
      );

      expect(
        find.text('Choisissez un preset avant d’ajouter une zone.'),
        findsOneWidget,
      );
      expect(_buttonFor(tester, 'Ajouter une zone').onPressed, isNull);
    });

    testWidgets('active Ajouter une zone avec plusieurs presets et sélection',
        (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.noArea,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Aucune zone d’environnement',
          emptyStateMessage:
              'Ajoutez une zone, choisissez un preset, puis peignez le masque.',
          primaryActionLabel: 'Ajouter une zone',
        ),
        availablePresets: const [
          TileLayerEnvironmentPresetOption(id: 'forest', name: 'Forêt'),
          TileLayerEnvironmentPresetOption(id: 'rocks', name: 'Rochers'),
        ],
        selectedPresetIdForNewArea: 'rocks',
        onCreateArea: () {
          pressed++;
        },
      );

      expect(
          find.text('Preset pour la nouvelle zone : Rochers'), findsOneWidget);
      expect(_buttonFor(tester, 'Ajouter une zone').onPressed, isNotNull);

      await tester.ensureVisible(find.text('Ajouter une zone'));
      await tester.tap(find.text('Ajouter une zone'));
      await tester.pump();

      expect(pressed, 1);
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
      expect(
        find.text('Action recommandée : Générer dans ce layer'),
        findsOneWidget,
      );
      expect(find.text('42 cases'), findsOneWidget);
      expect(find.text('Preset : Forêt'), findsOneWidget);
      expect(find.text('Zone : Bosquet nord'), findsOneWidget);
      expect(find.text('Masque : 42 cases peintes'), findsOneWidget);
    });

    testWidgets('affiche le feedback prêt avec seed et densité',
        (tester) async {
      final params = _params(
        density: 0.65,
        variation: 0.1,
        edgeDensity: 0.2,
        minSpacingCells: 2,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
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
          selectedAreaEffectiveParams: params,
          selectedAreaDefaultParams: params,
          selectedAreaHasParamsOverride: false,
          selectedAreaSeed: 12,
          canEditSelectedAreaGenerationParams: true,
        ),
        onGenerateEnvironment: () {},
        onRegenerateEnvironment: () {},
        onShuffleEnvironment: () {},
      );

      expect(find.text('État de génération'), findsOneWidget);
      expect(find.text('Prêt à générer'), findsOneWidget);
      expect(find.text('Seed 12'), findsOneWidget);
      expect(find.text('Densité 0.65'), findsOneWidget);
      expect(find.text('Valeurs du preset'), findsOneWidget);
      expect(_buttonFor(tester, 'Générer dans ce layer').onPressed, isNotNull);
      expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);
      expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);
    });

    testWidgets('organise les sections principales dans l’ordre UX cible',
        (tester) async {
      final params = _params(
        density: 0.65,
        variation: 0.1,
        edgeDensity: 0.2,
        minSpacingCells: 2,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.generated,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          activeTileLayerId: 'tiles',
          activeTileLayerName: 'Décor',
          attachedEnvironmentLayerId: 'env',
          attachedEnvironmentLayerName: 'Environnement',
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area_a',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetId: 'forest',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          generatedPlacementCount: 18,
          missingGeneratedPlacementCount: 3,
          hasGeneratedPlacements: true,
          canPaintMask: true,
          canClearGeneratedPlacements: true,
          canRegenerate: true,
          canShuffle: true,
          canAddGeneratedPlacement: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
          selectedAreaEffectiveParams: params,
          selectedAreaDefaultParams: params,
          selectedAreaHasParamsOverride: false,
          selectedAreaSeed: 12,
          canEditSelectedAreaGenerationParams: true,
          selectedAreaPaletteItems: _paletteItems(selectedId: 'tree'),
          areaSummaries: const [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: true,
              maskActiveCellCount: 42,
              generatedPlacementCount: 18,
              missingGeneratedPlacementCount: 3,
              hasMissingPreset: false,
            ),
          ],
          issues: const [
            TileLayerEnvironmentAttachmentIssue(
              severity: TileLayerEnvironmentAttachmentIssueSeverity.warning,
              message: '3 placements générés référencés sont introuvables.',
            ),
          ],
        ),
        onStartMaskPainting: () {},
        onStartMaskErasing: () {},
        onSetEnvironmentMaskBrushSize: (_) {},
        onSetGenerationParams: (_) {},
        onSetSeed: (_) {},
        onGenerateEnvironment: () {},
        onClearGeneratedPlacements: () {},
        onRegenerateEnvironment: () {},
        onShuffleEnvironment: () {},
        onSelectGeneratedPlacementElement: (_) {},
        onStartAddGeneratedPlacement: () {},
        onStartDeleteGeneratedPlacement: () {},
      );

      _expectTextOrder(tester, const [
        'État de génération',
        'Zones d’environnement',
        'Éditer le masque',
        'Paramètres de génération',
        'Génération',
        'Affinage manuel',
        'Palette du preset',
        'Diagnostics',
      ]);
      expect(find.text('Peindre le masque'), findsOneWidget);
      expect(find.text('Effacer du masque'), findsOneWidget);
      expect(find.text('Effacer les placements générés'), findsOneWidget);
      expect(find.text('Régénérer'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Ajouter un élément généré'), findsOneWidget);
      expect(find.text('Supprimer un élément généré'), findsOneWidget);
      expect(
        find.text(
            'Attention : 3 placements générés référencés sont introuvables.'),
        findsOneWidget,
      );
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

      expect(find.text('État de génération'), findsOneWidget);
      expect(find.text('Placements générés : 18'), findsOneWidget);
      expect(find.text('18 placements'), findsOneWidget);
      expect(
        find.text('Actions disponibles : Effacer · Régénérer · Shuffle'),
        findsOneWidget,
      );
    });

    testWidgets('affiche la liste des zones d’environnement', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area_a',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: true,
              maskActiveCellCount: 42,
              generatedPlacementCount: 18,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
            TileLayerEnvironmentAreaSummary(
              id: 'area_b',
              name: 'Rochers sud',
              presetId: 'rocks',
              presetName: 'Rochers',
              isSelected: false,
              maskActiveCellCount: 3,
              generatedPlacementCount: 0,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
      );

      expect(find.text('Zones d’environnement'), findsOneWidget);
      expect(find.text('Bosquet nord'), findsWidgets);
      expect(find.text('Rochers sud'), findsOneWidget);
      expect(find.text('Zone active'), findsOneWidget);
      expect(find.text('Preset : Forêt'), findsWidgets);
      expect(find.text('Masque : 42 cases peintes'), findsWidgets);
      expect(find.text('Placements : 18'), findsOneWidget);
      expect(find.text('Sélectionner'), findsOneWidget);
    });

    testWidgets('cliquer sur Sélectionner déclenche le callback area',
        (tester) async {
      String? selected;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.areaSelectionRequired,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Sélectionnez une zone d’environnement',
          emptyStateMessage:
              'Choisissez la zone à modifier avant de peindre ou générer.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: false,
              maskActiveCellCount: 0,
              generatedPlacementCount: 0,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
        onSelectEnvironmentArea: (areaId) {
          selected = areaId;
        },
      );

      expect(
          find.text('Sélectionnez une zone d’environnement'), findsOneWidget);
      expect(
        find.text('Action recommandée : Sélectionner une zone'),
        findsOneWidget,
      );
      expect(_buttonFor(tester, 'Sélectionner').onPressed, isNotNull);

      await tester.ensureVisible(find.text('Sélectionner'));
      await tester.tap(find.text('Sélectionner'));
      await tester.pump();

      expect(selected, 'area_a');
    });

    testWidgets('affiche et renomme la zone active', (tester) async {
      String? renamed;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area_a',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: true,
              maskActiveCellCount: 42,
              generatedPlacementCount: 18,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
        onRenameEnvironmentArea: (name) {
          renamed = name;
        },
      );

      expect(find.text('Zone active'), findsOneWidget);
      expect(find.text('Nom de la zone'), findsWidgets);
      expect(find.text('Renommer la zone'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoTextField>(
              find.byKey(
                const ValueKey('tile-layer-environment-area-name-field'),
              ),
            )
            .controller!
            .text,
        'Bosquet nord',
      );

      final nameField =
          find.byKey(const ValueKey('tile-layer-environment-area-name-field'));
      await tester.ensureVisible(nameField);
      await tester.tap(nameField);
      await tester.enterText(nameField, '  Bosquet plage  ');
      await tester.pump();
      await tester.ensureVisible(find.text('Renommer la zone'));
      await tester.tap(find.text('Renommer la zone'));
      await tester.pump();

      expect(renamed, 'Bosquet plage');
    });

    testWidgets('Renommer la zone refuse le texte vide', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area_a',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: true,
              maskActiveCellCount: 42,
              generatedPlacementCount: 18,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
        onRenameEnvironmentArea: (_) {},
      );

      await tester.enterText(
        find.byKey(const ValueKey('tile-layer-environment-area-name-field')),
        '   ',
      );
      await tester.pump();

      expect(_buttonFor(tester, 'Renommer la zone').onPressed, isNull);
    });

    testWidgets('Supprimer la zone ouvre une confirmation et Annuler bloque',
        (tester) async {
      var deleted = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area_a',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: true,
              maskActiveCellCount: 42,
              generatedPlacementCount: 18,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
        onDeleteEnvironmentArea: () {
          deleted++;
        },
      );

      expect(find.text('Supprimer la zone'), findsOneWidget);
      expect(
        find.text(
          'Supprime la zone, son masque, ses réglages et ses placements générés.',
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Supprimer la zone'));
      await tester.tap(find.text('Supprimer la zone'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer cette zone ?'), findsOneWidget);
      expect(
        find.text(
          'Cette action supprimera la zone, son masque, ses réglages locaux et ses placements générés. Les placements manuels et les autres zones seront conservés.',
        ),
        findsOneWidget,
      );
      expect(deleted, 0);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(deleted, 0);
      expect(find.text('Supprimer cette zone ?'), findsNothing);
    });

    testWidgets('Confirmer Supprimer la zone déclenche le callback',
        (tester) async {
      var deleted = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area_a',
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: true,
              maskActiveCellCount: 42,
              generatedPlacementCount: 18,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
        onDeleteEnvironmentArea: () {
          deleted++;
        },
      );

      await tester.ensureVisible(find.text('Supprimer la zone'));
      await tester.tap(find.text('Supprimer la zone'));
      await tester.pumpAndSettle();

      expect(deleted, 0);

      await tester.tap(find.text('Supprimer la zone').last);
      await tester.pumpAndSettle();

      expect(deleted, 1);
      expect(find.text('Supprimer cette zone ?'), findsNothing);
    });

    testWidgets('gestion de zone absente sans area active', (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.areaSelectionRequired,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Sélectionnez une zone d’environnement',
          emptyStateMessage:
              'Choisissez la zone à modifier avant de peindre ou générer.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest',
              presetName: 'Forêt',
              isSelected: false,
              maskActiveCellCount: 0,
              generatedPlacementCount: 0,
              missingGeneratedPlacementCount: 0,
              hasMissingPreset: false,
            ),
          ],
        ),
        onRenameEnvironmentArea: (_) {},
        onDeleteEnvironmentArea: () {},
      );

      expect(find.text('Zones d’environnement'), findsOneWidget);
      expect(find.text('Nom de la zone'), findsNothing);
      expect(find.text('Renommer la zone'), findsNothing);
      expect(find.text('Supprimer la zone'), findsNothing);
      expect(find.text('Sélectionner'), findsOneWidget);
    });

    testWidgets('affiche preset et placements manquants dans une summary',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.selectedAreaMissing,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          emptyStateTitle: 'Zone introuvable',
          emptyStateMessage:
              'La zone d’environnement sélectionnée n’existe plus sur ce layer.',
          areaSummaries: [
            TileLayerEnvironmentAreaSummary(
              id: 'area_a',
              name: 'Bosquet nord',
              presetId: 'forest_missing',
              presetName: null,
              isSelected: false,
              maskActiveCellCount: 1,
              generatedPlacementCount: 4,
              missingGeneratedPlacementCount: 2,
              hasMissingPreset: true,
            ),
          ],
        ),
      );

      expect(find.text('Zone introuvable'), findsOneWidget);
      expect(
        find.text(
          'La zone sélectionnée n’existe plus. Sélectionnez une zone valide.',
        ),
        findsOneWidget,
      );
      expect(find.text('Preset introuvable : forest_missing'), findsOneWidget);
      expect(find.text('2 placements manquants'), findsOneWidget);
      expect(find.text('Sélectionner'), findsOneWidget);
      expect(_buttonFor(tester, 'Sélectionner').onPressed, isNull);
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

      expect(find.text('3 références manquantes'), findsOneWidget);
      expect(
        find.text('Effacer ou régénérer nettoiera ces références.'),
        findsOneWidget,
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
        find.text('Cette zone référence un preset qui n’existe plus.'),
        findsOneWidget,
      );
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

    testWidgets('Générer dans ce layer reste désactivé sans callback',
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
      expect(find.text('Peindre le masque'), findsOneWidget);
      expect(_buttonFor(tester, 'Peindre le masque').onPressed, isNull);
    });

    testWidgets('Générer dans ce layer est actif avec callback',
        (tester) async {
      var generated = 0;
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
        onGenerateEnvironment: () {
          generated++;
        },
      );

      expect(find.text('Générer dans ce layer'), findsOneWidget);
      expect(_buttonFor(tester, 'Générer dans ce layer').onPressed, isNotNull);

      await tester.ensureVisible(find.text('Générer dans ce layer'));
      await tester.tap(find.text('Générer dans ce layer'));
      await tester.pump();

      expect(generated, 1);
    });

    testWidgets('Générer dans ce layer reste désactivé si canGenerate false',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 0,
          hasMask: false,
          canPaintMask: true,
          canGenerate: false,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
        onGenerateEnvironment: () {},
      );

      expect(find.text('Générer dans ce layer'), findsOneWidget);
      expect(_buttonFor(tester, 'Générer dans ce layer').onPressed, isNull);
    });

    testWidgets('active Peindre le masque avec callback', (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
        onStartMaskPainting: () {
          pressed++;
        },
      );

      expect(_buttonFor(tester, 'Peindre le masque').onPressed, isNotNull);

      await tester.tap(find.text('Peindre le masque'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('affiche Effacer du masque quand le masque est éditable',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
      );

      expect(find.text('Effacer du masque'), findsOneWidget);
      expect(_buttonFor(tester, 'Effacer du masque').onPressed, isNull);
    });

    testWidgets('active Effacer du masque avec callback', (tester) async {
      var pressed = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
        onStartMaskErasing: () {
          pressed++;
        },
      );

      expect(_buttonFor(tester, 'Effacer du masque').onPressed, isNotNull);

      await tester.tap(find.text('Effacer du masque'));
      await tester.pump();

      expect(pressed, 1);
    });

    testWidgets('affiche Taille du pinceau et les choix 1 3 5 7',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
      );

      expect(find.text('Taille du pinceau'), findsOneWidget);
      for (final size in [1, 3, 5, 7]) {
        expect(find.text('$size'), findsOneWidget);
      }
    });

    testWidgets('cliquer sur 3 change la taille du pinceau', (tester) async {
      var selected = 1;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
        environmentMaskBrushSize: 1,
        onSetEnvironmentMaskBrushSize: (size) {
          selected = size;
        },
      );

      expect(_buttonFor(tester, '3').onPressed, isNotNull);

      await tester.tap(find.text('3'));
      await tester.pump();

      expect(selected, 3);
    });

    testWidgets('sans callback les tailles de pinceau sont désactivées',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
      );

      expect(_buttonFor(tester, '1').onPressed, isNull);
      expect(_buttonFor(tester, '3').onPressed, isNull);
      expect(_buttonFor(tester, '5').onPressed, isNull);
      expect(_buttonFor(tester, '7').onPressed, isNull);
    });

    testWidgets('affiche Peinture active et stop quand le mode est actif',
        (tester) async {
      var stopped = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
        isMaskPaintingActive: true,
        onStopMaskPainting: () {
          stopped++;
        },
      );

      expect(find.text('Peinture active'), findsOneWidget);
      expect(
        find.text(
          'Cliquez sur la carte pour ajouter des cellules au masque.',
        ),
        findsOneWidget,
      );
      expect(find.text('Arrêter l’édition du masque'), findsOneWidget);
      expect(
        _buttonFor(tester, 'Arrêter l’édition du masque').onPressed,
        isNotNull,
      );

      await tester.tap(find.text('Arrêter l’édition du masque'));
      await tester.pump();

      expect(stopped, 1);
    });

    testWidgets('affiche Effacement actif et garde la taille visible',
        (tester) async {
      var stopped = 0;
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
        isMaskErasingActive: true,
        onStopMaskPainting: () {
          stopped++;
        },
      );

      expect(find.text('Effacement actif'), findsOneWidget);
      expect(
        find.text(
          'Cliquez sur la carte pour retirer des cellules du masque.',
        ),
        findsOneWidget,
      );
      expect(find.text('Taille du pinceau'), findsOneWidget);
      expect(find.text('Arrêter l’édition du masque'), findsOneWidget);
      expect(
        _buttonFor(tester, 'Arrêter l’édition du masque').onPressed,
        isNotNull,
      );

      await tester.tap(find.text('Arrêter l’édition du masque'));
      await tester.pump();

      expect(stopped, 1);
    });

    testWidgets('affiche les paramètres de génération éditables du preset',
        (tester) async {
      final params = _params(
        density: 0.5,
        variation: 0.25,
        edgeDensity: 0.75,
        minSpacingCells: 2,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 1,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          selectedAreaDefaultParams: params,
          selectedAreaEffectiveParams: params,
          selectedAreaParamsOverride: null,
          selectedAreaHasParamsOverride: false,
          selectedAreaSeed: 123,
          canEditSelectedAreaGenerationParams: true,
        ),
      );

      expect(find.text('Paramètres de génération'), findsOneWidget);
      expect(find.text('Valeurs du preset'), findsOneWidget);
      expect(find.text('Densité'), findsOneWidget);
      expect(find.text('Variation'), findsOneWidget);
      expect(find.text('Densité des bords'), findsOneWidget);
      expect(find.text('Espacement minimal'), findsOneWidget);
      expect(find.text('Seed'), findsOneWidget);
      expect(find.text('0.50'), findsOneWidget);
      expect(find.text('0.25'), findsOneWidget);
      expect(find.text('0.75'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('123'), findsOneWidget);
      expect(find.byKey(const ValueKey('env-generation-density-slider')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('env-generation-variation-slider')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('env-generation-edge-density-slider')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('env-generation-min-spacing-slider')),
          findsOneWidget);
      expect(find.byType(MacosSlider), findsNWidgets(4));
      expect(find.text('Densité +'), findsNothing);
      expect(find.text('Variation +'), findsNothing);
      expect(find.text('Densité des bords +'), findsNothing);
      expect(find.text('Espacement minimal +'), findsNothing);
      expect(find.text('Seed +'), findsOneWidget);
      expect(
          _buttonFor(tester, 'Réinitialiser les paramètres').onPressed, isNull);
    });

    testWidgets('changer le slider density construit un override complet',
        (tester) async {
      EnvironmentGenerationParams? changed;
      final params = _params(
        density: 0.5,
        variation: 0.25,
        edgeDensity: 0.75,
        minSpacingCells: 2,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 1,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          selectedAreaDefaultParams: params,
          selectedAreaEffectiveParams: params,
          selectedAreaSeed: 123,
          canEditSelectedAreaGenerationParams: true,
        ),
        onSetGenerationParams: (params) {
          changed = params;
        },
      );

      final slider = tester.widget<MacosSlider>(
        find.byKey(const ValueKey('env-generation-density-slider')),
      );
      slider.onChanged(0.8);
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.density, 0.8);
      expect(changed!.variation, 0.25);
      expect(changed!.edgeDensity, 0.75);
      expect(changed!.minSpacingCells, 2);
    });

    testWidgets('changer le slider spacing construit un override entier',
        (tester) async {
      EnvironmentGenerationParams? changed;
      final params = _params(
        density: 0.5,
        variation: 0.25,
        edgeDensity: 0.75,
        minSpacingCells: 2,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 1,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          selectedAreaDefaultParams: params,
          selectedAreaEffectiveParams: params,
          selectedAreaSeed: 123,
          canEditSelectedAreaGenerationParams: true,
        ),
        onSetGenerationParams: (params) {
          changed = params;
        },
      );

      final slider = tester.widget<MacosSlider>(
        find.byKey(const ValueKey('env-generation-min-spacing-slider')),
      );
      slider.onChanged(6.4);
      await tester.pump();

      expect(changed, isNotNull);
      expect(changed!.density, 0.5);
      expect(changed!.variation, 0.25);
      expect(changed!.edgeDensity, 0.75);
      expect(changed!.minSpacingCells, 6);
    });

    testWidgets('sans callback les sliders de génération sont grisés',
        (tester) async {
      EnvironmentGenerationParams? changed;
      final params = _params(
        density: 0.5,
        variation: 0.25,
        edgeDensity: 0.75,
        minSpacingCells: 2,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 1,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          selectedAreaDefaultParams: params,
          selectedAreaEffectiveParams: params,
          selectedAreaSeed: 123,
          canEditSelectedAreaGenerationParams: true,
        ),
      );

      final disabledSlider = find.byKey(
        const ValueKey('env-generation-density-slider-disabled'),
      );
      expect(disabledSlider, findsOneWidget);
      expect(tester.widget<IgnorePointer>(disabledSlider).ignoring, isTrue);
      final disabledOpacity = tester.widget<Opacity>(
        find.byKey(const ValueKey('env-generation-density-slider-opacity')),
      );
      expect(disabledOpacity.opacity, lessThan(1));

      final slider = tester.widget<MacosSlider>(
        find.byKey(const ValueKey('env-generation-density-slider')),
      );
      slider.onChanged(0.8);
      await tester.pump();

      expect(changed, isNull);
    });

    testWidgets('override local active reset et seed', (tester) async {
      var reset = 0;
      int? seed;
      final defaults = _params(
        density: 0.5,
        variation: 0.25,
        edgeDensity: 0.75,
        minSpacingCells: 2,
      );
      final override = _params(
        density: 0.8,
        variation: 0.2,
        edgeDensity: 0.6,
        minSpacingCells: 3,
      );
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 1,
          hasMask: true,
          canPaintMask: true,
          canGenerate: true,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
          selectedAreaDefaultParams: defaults,
          selectedAreaEffectiveParams: override,
          selectedAreaParamsOverride: override,
          selectedAreaHasParamsOverride: true,
          selectedAreaSeed: 123,
          canEditSelectedAreaGenerationParams: true,
        ),
        onResetGenerationParams: () {
          reset++;
        },
        onSetSeed: (nextSeed) {
          seed = nextSeed;
        },
      );

      expect(find.text('Override local'), findsOneWidget);
      expect(find.text('Seed 123'), findsOneWidget);
      expect(_buttonFor(tester, 'Réinitialiser les paramètres').onPressed,
          isNotNull);

      await tester.ensureVisible(find.text('Seed +'));
      await tester.tap(find.text('Seed +'));
      await tester.pump();
      await tester.tap(find.text('Réinitialiser les paramètres'));
      await tester.pump();

      expect(seed, 124);
      expect(reset, 1);
    });

    testWidgets('preset manquant affiche des paramètres non modifiables',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.missingPreset,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaId: 'area',
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetId: 'missing',
          maskActiveCellCount: 1,
          hasMask: true,
          canPaintMask: true,
          emptyStateTitle: 'Preset introuvable',
          emptyStateMessage:
              'Choisissez un preset disponible avant de générer cette zone.',
          selectedAreaSeed: 123,
          canEditSelectedAreaGenerationParams: false,
        ),
      );

      expect(find.text('Paramètres de génération'), findsOneWidget);
      expect(
        find.text('Preset introuvable : paramètres non modifiables.'),
        findsOneWidget,
      );
      expect(find.text('Densité +'), findsNothing);
    });

    testWidgets('après création avec masque vide la brush reste désactivée',
        (tester) async {
      await _pump(
        tester,
        const TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.emptyMask,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Forêt',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 0,
          hasMask: false,
          canPaintMask: true,
          emptyStateTitle: 'Masque vide',
          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
        ),
      );

      expect(find.text('Masque vide'), findsOneWidget);
      expect(
        find.text('Action recommandée : Peindre le masque'),
        findsOneWidget,
      );
      expect(find.text('Peindre le masque'), findsOneWidget);
      expect(_buttonFor(tester, 'Peindre le masque').onPressed, isNull);
    });

    testWidgets('Effacer les placements générés reste désactivé sans callback',
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
          hasGeneratedPlacements: true,
          canClearGeneratedPlacements: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
      );

      expect(find.text('Effacer les placements générés'), findsOneWidget);
      expect(
        _buttonFor(tester, 'Effacer les placements générés').onPressed,
        isNull,
      );
    });

    testWidgets('Effacer les placements générés est actif avec callback',
        (tester) async {
      var cleared = 0;
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
        onClearGeneratedPlacements: () {
          cleared++;
        },
      );

      expect(find.text('Effacer les placements générés'), findsOneWidget);
      expect(
        find.text(
          'Retire tous les éléments générés de cette zone, sans supprimer le masque ni les réglages.',
        ),
        findsOneWidget,
      );
      expect(
        _buttonFor(tester, 'Effacer les placements générés').onPressed,
        isNotNull,
      );

      await tester.tap(find.text('Effacer les placements générés'));
      await tester.pump();

      expect(cleared, 1);
    });

    testWidgets(
        'Effacer les placements générés reste désactivé sans placement généré',
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
          generatedPlacementCount: 0,
          hasGeneratedPlacements: false,
          canClearGeneratedPlacements: false,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
        ),
        onClearGeneratedPlacements: () {},
      );

      expect(find.text('Effacer les placements générés'), findsOneWidget);
      expect(
        _buttonFor(tester, 'Effacer les placements générés').onPressed,
        isNull,
      );
      expect(find.text('Régénérer'), findsOneWidget);
      expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);
    });

    testWidgets('Régénérer reste désactivé sans callback', (tester) async {
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
          canRegenerate: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
      );

      expect(find.text('Régénérer'), findsOneWidget);
      expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);
    });

    testWidgets('Régénérer est actif avec callback', (tester) async {
      var regenerated = 0;
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
          canRegenerate: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
        onRegenerateEnvironment: () {
          regenerated++;
        },
      );

      expect(find.text('Régénérer'), findsOneWidget);
      expect(_buttonFor(tester, 'Régénérer').onPressed, isNotNull);
      expect(
        find.text(
          'Remplace les placements générés de cette zone en gardant le seed actuel.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Régénérer'));
      await tester.pump();

      expect(regenerated, 1);
    });

    testWidgets(
        'Régénérer reste désactivé sans generatedPlacementIds même avec callback',
        (tester) async {
      var regenerated = 0;
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
          canRegenerate: false,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
        ),
        onRegenerateEnvironment: () {
          regenerated++;
        },
      );

      expect(find.text('Régénérer'), findsOneWidget);
      expect(_buttonFor(tester, 'Régénérer').onPressed, isNull);

      await tester.ensureVisible(find.text('Régénérer'));
      await tester.tap(find.text('Régénérer'));
      await tester.pump();

      expect(regenerated, 0);
    });

    testWidgets('Shuffle reste désactivé sans callback', (tester) async {
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
          canShuffle: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
      );

      expect(find.text('Shuffle'), findsOneWidget);
      expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);
    });

    testWidgets('Shuffle est actif avec callback', (tester) async {
      var shuffled = 0;
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
          canShuffle: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
        onShuffleEnvironment: () {
          shuffled++;
        },
      );

      expect(find.text('Shuffle'), findsOneWidget);
      expect(_buttonFor(tester, 'Shuffle').onPressed, isNotNull);
      expect(
        find.text(
          'Remplace les placements générés de cette zone avec un nouveau seed.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Shuffle'));
      await tester.pump();

      expect(shuffled, 1);
    });

    testWidgets(
        'Shuffle reste désactivé sans generatedPlacementIds même avec callback',
        (tester) async {
      var shuffled = 0;
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
          canShuffle: false,
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
        ),
        onShuffleEnvironment: () {
          shuffled++;
        },
      );

      expect(find.text('Shuffle'), findsOneWidget);
      expect(_buttonFor(tester, 'Shuffle').onPressed, isNull);

      await tester.ensureVisible(find.text('Shuffle'));
      await tester.tap(find.text('Shuffle'));
      await tester.pump();

      expect(shuffled, 0);
    });

    testWidgets('affiche Palette du preset et les éléments disponibles',
        (tester) async {
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
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
          selectedAreaPaletteItems: _paletteItems(),
          canAddGeneratedPlacement: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
      );

      expect(find.text('Palette du preset'), findsOneWidget);
      expect(find.text('Élément à ajouter'), findsOneWidget);
      expect(find.text('Tree'), findsOneWidget);
      expect(find.text('Big Tree'), findsOneWidget);
      expect(find.text('Introuvable (missing_bush)'), findsOneWidget);
    });

    testWidgets('sélection d’un élément généré déclenche le callback',
        (tester) async {
      var selected = '';
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
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
          selectedAreaPaletteItems: _paletteItems(selectedId: 'tree'),
          canAddGeneratedPlacement: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
        onSelectGeneratedPlacementElement: (elementId) {
          selected = elementId;
        },
      );

      await tester.ensureVisible(find.text('Big Tree'));
      await tester.tap(find.text('Big Tree'));
      await tester.pump();

      expect(selected, 'big_tree');
    });

    testWidgets('Ajouter un élément généré désactivé sans generated placements',
        (tester) async {
      var started = 0;
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
          state: TileLayerEnvironmentAttachmentState.ready,
          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
          hasAttachment: true,
          hasValidTargetTileLayer: true,
          selectedEnvironmentAreaName: 'Bosquet nord',
          selectedPresetName: 'Forêt',
          maskActiveCellCount: 42,
          hasMask: true,
          canGenerate: true,
          selectedAreaPaletteItems: _paletteItems(selectedId: 'tree'),
          emptyStateTitle: 'Prêt à générer',
          emptyStateMessage: 'Le preset, le layer et le masque sont valides.',
        ),
        onStartAddGeneratedPlacement: () {
          started++;
        },
      );

      expect(find.text('Ajouter un élément généré'), findsOneWidget);
      expect(_buttonFor(tester, 'Ajouter un élément généré').onPressed, isNull);
      await tester.ensureVisible(find.text('Ajouter un élément généré'));
      await tester.tap(find.text('Ajouter un élément généré'));
      await tester.pump();
      expect(started, 0);
    });

    testWidgets(
        'Ajouter un élément généré désactivé sans sélection quand plusieurs items',
        (tester) async {
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
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
          selectedAreaPaletteItems: _paletteItems(),
          canAddGeneratedPlacement: false,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
        onStartAddGeneratedPlacement: () {},
      );

      expect(_buttonFor(tester, 'Ajouter un élément généré').onPressed, isNull);
    });

    testWidgets('Ajouter un élément généré actif avec élément sélectionné',
        (tester) async {
      var started = 0;
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
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
          selectedAreaPaletteItems: _paletteItems(selectedId: 'tree'),
          canAddGeneratedPlacement: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
        onStartAddGeneratedPlacement: () {
          started++;
        },
      );

      expect(
          _buttonFor(tester, 'Ajouter un élément généré').onPressed, isNotNull);
      expect(
        find.text(
          'Choisissez un élément du preset, puis cliquez sur la carte pour l’ajouter à cette zone.',
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Ajouter un élément généré'));
      await tester.tap(find.text('Ajouter un élément généré'));
      await tester.pump();
      expect(started, 1);
    });

    testWidgets('mode ajout actif affiche stop et aide', (tester) async {
      var stopped = 0;
      await _pump(
        tester,
        TileLayerEnvironmentAttachmentReadModel(
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
          selectedAreaPaletteItems: _paletteItems(selectedId: 'tree'),
          canAddGeneratedPlacement: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
        isAddingGeneratedPlacement: true,
        onStopAddGeneratedPlacement: () {
          stopped++;
        },
      );

      expect(find.text('Ajout actif'), findsOneWidget);
      expect(
        find.text(
            'Cliquez sur la carte pour ajouter cet élément à cette zone.'),
        findsOneWidget,
      );
      expect(find.text('Arrêter l’ajout'), findsOneWidget);
      expect(_buttonFor(tester, 'Arrêter l’ajout').onPressed, isNotNull);

      await tester.ensureVisible(find.text('Arrêter l’ajout'));
      await tester.tap(find.text('Arrêter l’ajout'));
      await tester.pump();

      expect(stopped, 1);
    });

    testWidgets(
        'Supprimer un élément généré reste désactivé sans generated placements',
        (tester) async {
      var started = 0;
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
        onStartDeleteGeneratedPlacement: () {
          started++;
        },
      );

      expect(find.text('Supprimer un élément généré'), findsOneWidget);
      expect(
          _buttonFor(tester, 'Supprimer un élément généré').onPressed, isNull);

      await tester.ensureVisible(find.text('Supprimer un élément généré'));
      await tester.tap(find.text('Supprimer un élément généré'));
      await tester.pump();

      expect(started, 0);
    });

    testWidgets('Supprimer un élément généré reste désactivé sans callback',
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
          hasGeneratedPlacements: true,
          canClearGeneratedPlacements: true,
          emptyStateTitle: 'Placements générés',
          emptyStateMessage: 'Cette zone contient déjà des placements générés.',
        ),
      );

      expect(find.text('Supprimer un élément généré'), findsOneWidget);
      expect(
          _buttonFor(tester, 'Supprimer un élément généré').onPressed, isNull);
      expect(find.text('Effacer les placements générés'), findsOneWidget);
    });

    testWidgets('Supprimer un élément généré est actif avec callback',
        (tester) async {
      var started = 0;
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
        onStartDeleteGeneratedPlacement: () {
          started++;
        },
      );

      expect(_buttonFor(tester, 'Supprimer un élément généré').onPressed,
          isNotNull);
      expect(
        find.text('Cliquez un élément généré pour le retirer de cette zone.'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Supprimer un élément généré'));
      await tester.tap(find.text('Supprimer un élément généré'));
      await tester.pump();

      expect(started, 1);
    });

    testWidgets('mode suppression actif affiche stop et aide', (tester) async {
      var stopped = 0;
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
        isDeletingGeneratedPlacement: true,
        onStopDeleteGeneratedPlacement: () {
          stopped++;
        },
      );

      expect(find.text('Suppression active'), findsOneWidget);
      expect(
        find.text('Cliquez un élément généré pour le retirer de cette zone.'),
        findsOneWidget,
      );
      expect(find.text('Arrêter la suppression'), findsOneWidget);
      expect(_buttonFor(tester, 'Arrêter la suppression').onPressed, isNotNull);

      await tester.ensureVisible(find.text('Arrêter la suppression'));
      await tester.tap(find.text('Arrêter la suppression'));
      await tester.pump();

      expect(stopped, 1);
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  TileLayerEnvironmentAttachmentReadModel model, {
  VoidCallback? onEnableEnvironment,
  List<TileLayerEnvironmentPresetOption> availablePresets = const [],
  String? selectedPresetIdForNewArea,
  ValueChanged<String>? onSelectPresetForNewArea,
  VoidCallback? onCreateArea,
  ValueChanged<String>? onSelectEnvironmentArea,
  ValueChanged<String>? onRenameEnvironmentArea,
  VoidCallback? onDeleteEnvironmentArea,
  bool isMaskPaintingActive = false,
  bool isMaskErasingActive = false,
  bool isDeletingGeneratedPlacement = false,
  bool isAddingGeneratedPlacement = false,
  VoidCallback? onStartMaskPainting,
  VoidCallback? onStartMaskErasing,
  VoidCallback? onStopMaskPainting,
  ValueChanged<String>? onSelectGeneratedPlacementElement,
  VoidCallback? onStartAddGeneratedPlacement,
  VoidCallback? onStopAddGeneratedPlacement,
  VoidCallback? onStartDeleteGeneratedPlacement,
  VoidCallback? onStopDeleteGeneratedPlacement,
  int environmentMaskBrushSize = 1,
  ValueChanged<int>? onSetEnvironmentMaskBrushSize,
  ValueChanged<EnvironmentGenerationParams>? onSetGenerationParams,
  VoidCallback? onResetGenerationParams,
  ValueChanged<int>? onSetSeed,
  VoidCallback? onGenerateEnvironment,
  VoidCallback? onClearGeneratedPlacements,
  VoidCallback? onRegenerateEnvironment,
  VoidCallback? onShuffleEnvironment,
}) {
  return tester.pumpWidget(
    MacosTheme(
      data: MacosThemeData.light(),
      child: MaterialApp(
        home: CupertinoPageScaffold(
          child: SizedBox(
            width: 360,
            height: 520,
            child: TileLayerEnvironmentInspectorSection(
              readModel: model,
              onEnableEnvironment: onEnableEnvironment,
              availablePresets: availablePresets,
              selectedPresetIdForNewArea: selectedPresetIdForNewArea,
              onSelectPresetForNewArea: onSelectPresetForNewArea,
              onCreateArea: onCreateArea,
              onSelectEnvironmentArea: onSelectEnvironmentArea,
              onRenameEnvironmentArea: onRenameEnvironmentArea,
              onDeleteEnvironmentArea: onDeleteEnvironmentArea,
              isMaskPaintingActive: isMaskPaintingActive,
              isMaskErasingActive: isMaskErasingActive,
              isDeletingGeneratedPlacement: isDeletingGeneratedPlacement,
              isAddingGeneratedPlacement: isAddingGeneratedPlacement,
              onStartMaskPainting: onStartMaskPainting,
              onStartMaskErasing: onStartMaskErasing,
              onStopMaskPainting: onStopMaskPainting,
              onSelectGeneratedPlacementElement:
                  onSelectGeneratedPlacementElement,
              onStartAddGeneratedPlacement: onStartAddGeneratedPlacement,
              onStopAddGeneratedPlacement: onStopAddGeneratedPlacement,
              onStartDeleteGeneratedPlacement: onStartDeleteGeneratedPlacement,
              onStopDeleteGeneratedPlacement: onStopDeleteGeneratedPlacement,
              environmentMaskBrushSize: environmentMaskBrushSize,
              onSetEnvironmentMaskBrushSize: onSetEnvironmentMaskBrushSize,
              onSetGenerationParams: onSetGenerationParams,
              onResetGenerationParams: onResetGenerationParams,
              onSetSeed: onSetSeed,
              onGenerateEnvironment: onGenerateEnvironment,
              onClearGeneratedPlacements: onClearGeneratedPlacements,
              onRegenerateEnvironment: onRegenerateEnvironment,
              onShuffleEnvironment: onShuffleEnvironment,
            ),
          ),
        ),
      ),
    ),
  );
}

List<TileLayerEnvironmentPaletteItemSummary> _paletteItems({
  String? selectedId,
}) {
  return [
    TileLayerEnvironmentPaletteItemSummary(
      elementId: 'tree',
      elementName: 'Tree',
      weight: 1,
      collisionMode: EnvironmentCollisionMode.useElementDefault,
      hasMissingElement: false,
      isSelected: selectedId == 'tree',
    ),
    TileLayerEnvironmentPaletteItemSummary(
      elementId: 'big_tree',
      elementName: 'Big Tree',
      weight: 2,
      collisionMode: EnvironmentCollisionMode.forceDisabled,
      hasMissingElement: false,
      isSelected: selectedId == 'big_tree',
    ),
    TileLayerEnvironmentPaletteItemSummary(
      elementId: 'missing_bush',
      elementName: null,
      weight: 1,
      collisionMode: EnvironmentCollisionMode.useElementDefault,
      hasMissingElement: true,
      isSelected: selectedId == 'missing_bush',
    ),
  ];
}

CupertinoButton _buttonFor(WidgetTester tester, String label) {
  final finder = find.ancestor(
    of: find.text(label),
    matching: find.byType(CupertinoButton),
  );
  return tester.widget<CupertinoButton>(finder.first);
}

void _expectTextOrder(WidgetTester tester, List<String> labels) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .toList();
  var previousIndex = -1;
  for (final label in labels) {
    final index = texts.indexOf(label);
    expect(index, greaterThanOrEqualTo(0), reason: 'Texte absent : $label');
    expect(
      index,
      greaterThan(previousIndex),
      reason: 'Texte hors ordre : $label',
    );
    previousIndex = index;
  }
}

EnvironmentGenerationParams _params({
  required double density,
  required double variation,
  required double edgeDensity,
  required int minSpacingCells,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacingCells,
  );
}
