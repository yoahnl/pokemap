import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
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
      expect(find.text('Bosquet nord'), findsOneWidget);
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

      expect(_buttonFor(tester, 'Sélectionner').onPressed, isNotNull);

      await tester.ensureVisible(find.text('Sélectionner'));
      await tester.tap(find.text('Sélectionner'));
      await tester.pump();

      expect(selected, 'area_a');
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
      expect(find.text('Peindre le masque'), findsOneWidget);
      expect(_buttonFor(tester, 'Peindre le masque').onPressed, isNull);
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
          'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
        ),
        findsOneWidget,
      );
      expect(find.text('Arrêter la peinture'), findsOneWidget);
      expect(_buttonFor(tester, 'Arrêter la peinture').onPressed, isNotNull);

      await tester.tap(find.text('Arrêter la peinture'));
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
          'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.',
        ),
        findsOneWidget,
      );
      expect(find.text('Taille du pinceau'), findsOneWidget);
      expect(find.text('Arrêter la peinture'), findsOneWidget);
      expect(_buttonFor(tester, 'Arrêter la peinture').onPressed, isNotNull);

      await tester.tap(find.text('Arrêter la peinture'));
      await tester.pump();

      expect(stopped, 1);
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
      expect(find.text('Peindre le masque'), findsOneWidget);
      expect(_buttonFor(tester, 'Peindre le masque').onPressed, isNull);
    });

    testWidgets('la suppression des placements générés reste désactivée',
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
  bool isMaskPaintingActive = false,
  bool isMaskErasingActive = false,
  VoidCallback? onStartMaskPainting,
  VoidCallback? onStartMaskErasing,
  VoidCallback? onStopMaskPainting,
  int environmentMaskBrushSize = 1,
  ValueChanged<int>? onSetEnvironmentMaskBrushSize,
}) {
  return tester.pumpWidget(
    MaterialApp(
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
            isMaskPaintingActive: isMaskPaintingActive,
            isMaskErasingActive: isMaskErasingActive,
            onStartMaskPainting: onStartMaskPainting,
            onStartMaskErasing: onStartMaskErasing,
            onStopMaskPainting: onStopMaskPainting,
            environmentMaskBrushSize: environmentMaskBrushSize,
            onSetEnvironmentMaskBrushSize: onSetEnvironmentMaskBrushSize,
          ),
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
