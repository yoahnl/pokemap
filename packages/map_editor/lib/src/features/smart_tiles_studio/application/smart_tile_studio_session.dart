import 'package:map_core/map_core.dart';

import 'smart_tile_grid_detector.dart';
import 'smart_tile_guide.dart';
import 'smart_tile_guide_placement.dart';

enum SmartTileStudioWizardStep {
  usage,
  image,
  grid,
  materials,
  connections,
  variants,
  forms,
  test,
  publish,
}

enum SmartTileStudioSourceChoice {
  projectImage,
  registeredAtlas,
  emptyPreset,
}

final class SmartTileAtlasAnchor {
  const SmartTileAtlasAnchor({required this.column, required this.row});

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is SmartTileAtlasAnchor &&
      other.column == column &&
      other.row == row;

  @override
  int get hashCode => Object.hash(column, row);
}

final class SmartTileStudioSessionState {
  const SmartTileStudioSessionState({
    this.isCreating = false,
    this.wizardStep = SmartTileStudioWizardStep.usage,
    this.usage,
    this.guideId,
    this.sourceChoice,
    this.gridGeometry,
    this.anchor,
  });

  final bool isCreating;
  final SmartTileStudioWizardStep wizardStep;
  final SmartTileUsage? usage;
  final SmartTileGuideId? guideId;
  final SmartTileStudioSourceChoice? sourceChoice;
  final SmartTileGridGeometry? gridGeometry;
  final SmartTileAtlasAnchor? anchor;

  SmartTileStudioSessionState copyWith({
    bool? isCreating,
    SmartTileStudioWizardStep? wizardStep,
    SmartTileUsage? usage,
    SmartTileGuideId? guideId,
    SmartTileStudioSourceChoice? sourceChoice,
    SmartTileGridGeometry? gridGeometry,
    SmartTileAtlasAnchor? anchor,
    bool clearUsage = false,
    bool clearGuide = false,
    bool clearSource = false,
    bool clearGrid = false,
    bool clearAnchor = false,
  }) {
    return SmartTileStudioSessionState(
      isCreating: isCreating ?? this.isCreating,
      wizardStep: wizardStep ?? this.wizardStep,
      usage: clearUsage ? null : usage ?? this.usage,
      guideId: clearGuide ? null : guideId ?? this.guideId,
      sourceChoice: clearSource ? null : sourceChoice ?? this.sourceChoice,
      gridGeometry: clearGrid ? null : gridGeometry ?? this.gridGeometry,
      anchor: clearAnchor ? null : anchor ?? this.anchor,
    );
  }
}

/// Pure state machine for the human-facing Smart Tile creation flow.
///
/// Source and grid are configuration details of Placement rather than wizard
/// concepts of their own. The session performs no IO and no manifest mutation.
final class SmartTileStudioSession {
  SmartTileStudioSession({
    SmartTileStudioSessionState state = const SmartTileStudioSessionState(),
  }) : _state = state;

  SmartTileStudioSessionState _state;

  SmartTileStudioSessionState get state => _state;

  void startDraft() {
    _state = const SmartTileStudioSessionState(isCreating: true);
  }

  void resumeDraft(
    ProjectSmartTileAuthoringDraft draft, {
    SmartTileGridGeometry? gridGeometry,
  }) {
    final sourceChoice = draft.sourceTilesetIds.isNotEmpty
        ? SmartTileStudioSourceChoice.projectImage
        : draft.lastStage.index >= SmartTileAuthoringStage.grid.index
            ? SmartTileStudioSourceChoice.emptyPreset
            : null;
    SmartTileGuideId? guideId;
    final canonicalGuideId = draft.guideId;
    if (canonicalGuideId != null) {
      guideId = SmartTileGuideId.values
          .where((candidate) => candidate.name == canonicalGuideId)
          .firstOrNull;
    }
    _state = SmartTileStudioSessionState(
      isCreating: true,
      wizardStep: SmartTileStudioWizardStep.values.byName(draft.lastStage.name),
      usage: draft.usage,
      guideId: guideId,
      sourceChoice: sourceChoice,
      gridGeometry: gridGeometry,
    );
  }

  void cancelDraft() {
    _state = const SmartTileStudioSessionState();
  }

  void chooseUsage(SmartTileUsage usage) {
    _requireStep(SmartTileStudioWizardStep.usage, 'choisir l’usage');
    _state = _state.copyWith(
      usage: usage,
      clearGuide: true,
      clearSource: true,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void moveToGuide() {
    _requireStep(SmartTileStudioWizardStep.usage, 'ouvrir les guides');
    if (_state.usage == null) {
      throw StateError('Choisissez un usage avant le guide.');
    }
    _state = _state.copyWith(
      wizardStep: SmartTileStudioWizardStep.connections,
    );
  }

  void chooseGuide(SmartTileGuideId guideId) {
    if (_state.wizardStep != SmartTileStudioWizardStep.connections) {
      throw StateError('Impossible de choisir un guide pendant cette étape.');
    }
    final usage = _state.usage;
    final guide = smartTileGuideById(guideId);
    if (usage == null || !guide.supportedUsages.contains(usage)) {
      throw StateError('Ce guide ne convient pas à l’usage choisi.');
    }
    _state = _state.copyWith(
      guideId: guideId,
      clearAnchor: true,
    );
  }

  void clearGuideChoice() {
    if (_state.wizardStep != SmartTileStudioWizardStep.connections &&
        _state.wizardStep != SmartTileStudioWizardStep.variants &&
        _state.wizardStep != SmartTileStudioWizardStep.forms) {
      throw StateError(
          'Impossible de désactiver un guide pendant cette étape.');
    }
    _state = _state.copyWith(clearGuide: true, clearAnchor: true);
  }

  void moveToPlacement() {
    _requireStep(
      SmartTileStudioWizardStep.connections,
      'ouvrir le placement',
    );
    if (_state.guideId == null) {
      throw StateError('Choisissez un guide avant son placement.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.forms);
  }

  void chooseSource(SmartTileStudioSourceChoice choice) {
    if (_state.wizardStep != SmartTileStudioWizardStep.image &&
        _state.wizardStep != SmartTileStudioWizardStep.forms) {
      throw StateError('Impossible de choisir une source pendant cette étape.');
    }
    _state = _state.copyWith(
      sourceChoice: choice,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void configureGrid(SmartTileGridGeometry geometry) {
    if (_state.wizardStep != SmartTileStudioWizardStep.grid &&
        _state.wizardStep != SmartTileStudioWizardStep.forms) {
      throw StateError(
        'Impossible de configurer la grille pendant cette étape.',
      );
    }
    if (_state.sourceChoice == null) {
      throw StateError('Choisissez une image avant de configurer sa grille.');
    }
    if (geometry.columns <= 0 || geometry.rows <= 0) {
      throw ArgumentError('La grille doit contenir au moins une cellule.');
    }
    _state = _state.copyWith(gridGeometry: geometry, clearAnchor: true);
  }

  void updateGrid(SmartTileGridGeometry geometry) => configureGrid(geometry);

  void placeGuide({required int anchorColumn, required int anchorRow}) {
    _requireStep(SmartTileStudioWizardStep.forms, 'placer le guide');
    final guideId = _state.guideId;
    final geometry = _state.gridGeometry;
    if (guideId == null || geometry == null || _state.sourceChoice == null) {
      throw StateError('Choisissez la source et confirmez sa grille.');
    }
    final placement = placeSmartTileGuide(
      guide: smartTileGuideById(guideId),
      geometry: geometry,
      anchorColumn: anchorColumn,
      anchorRow: anchorRow,
    );
    if (!placement.isValid) {
      throw StateError(
        'Le guide dépasse l’atlas pour les cellules '
        '${placement.outOfBoundsNumbers.join(', ')}.',
      );
    }
    _state = _state.copyWith(
      anchor: SmartTileAtlasAnchor(
        column: anchorColumn,
        row: anchorRow,
      ),
    );
  }

  void clearAnchor() {
    _requireStep(SmartTileStudioWizardStep.forms, 'effacer le placement');
    _state = _state.copyWith(clearAnchor: true);
  }

  void resetPlacementSource() {
    _requireStep(SmartTileStudioWizardStep.forms, 'changer de source');
    _state = _state.copyWith(
      clearSource: true,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void moveToTest() {
    _requireStep(SmartTileStudioWizardStep.forms, 'ouvrir le banc d’essai');
    if (_state.sourceChoice == null || _state.gridGeometry == null) {
      throw StateError('Confirmez la source et sa grille avant de tester.');
    }
    if (_state.guideId != null && _state.anchor == null) {
      throw StateError('Placez entièrement le guide avant de le tester.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.test);
  }

  void moveToPublish() {
    _requireStep(SmartTileStudioWizardStep.test, 'ouvrir la publication');
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.publish);
  }

  void returnToUsage() {
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.usage);
  }

  void returnToImage() {
    if (_state.usage == null) {
      throw StateError('Aucun usage à conserver.');
    }
    _state = _state.copyWith(
      wizardStep: SmartTileStudioWizardStep.image,
      clearSource: true,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void returnToGrid() {
    if (_state.usage == null || _state.sourceChoice == null) {
      throw StateError('Choisissez une source avant son découpage.');
    }
    _state = _state.copyWith(
      wizardStep: SmartTileStudioWizardStep.grid,
      clearAnchor: true,
    );
  }

  void returnToGuide() {
    if (_state.usage == null) {
      throw StateError('Aucun usage à conserver.');
    }
    _state = _state.copyWith(
      wizardStep: SmartTileStudioWizardStep.connections,
    );
  }

  void returnToPlacement() {
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.forms);
  }

  void moveToImage() {
    _requireStep(SmartTileStudioWizardStep.usage, 'ouvrir l’image');
    if (_state.usage == null) {
      throw StateError('Choisissez un usage avant l’image.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.image);
  }

  void moveToGrid() {
    _requireStep(SmartTileStudioWizardStep.image, 'ouvrir la grille');
    if (_state.sourceChoice == null) {
      throw StateError('Choisissez une image avant sa grille.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.grid);
  }

  void moveToMaterials() {
    _requireStep(SmartTileStudioWizardStep.grid, 'ouvrir les matériaux');
    if (_state.gridGeometry == null) {
      throw StateError('Confirmez la grille avant les matériaux.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.materials);
  }

  void moveToConnections() {
    _requireStep(SmartTileStudioWizardStep.materials, 'ouvrir les raccords');
    _state = _state.copyWith(
      wizardStep: SmartTileStudioWizardStep.connections,
    );
  }

  void moveToVariants() {
    _requireStep(SmartTileStudioWizardStep.connections, 'ouvrir les variantes');
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.variants);
  }

  void moveToForms() {
    _requireStep(SmartTileStudioWizardStep.variants, 'ouvrir les formes');
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.forms);
  }

  void _requireStep(SmartTileStudioWizardStep expected, String action) {
    if (!_state.isCreating || _state.wizardStep != expected) {
      throw StateError('Impossible de $action pendant cette étape.');
    }
  }
}
