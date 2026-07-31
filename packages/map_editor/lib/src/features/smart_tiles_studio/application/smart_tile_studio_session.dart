import 'package:map_core/map_core.dart';

import 'smart_tile_grid_detector.dart';
import 'smart_tile_guide.dart';
import 'smart_tile_guide_placement.dart';

enum SmartTileStudioWizardStep { usage, guide, placement, test, publish }

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
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.guide);
  }

  void chooseGuide(SmartTileGuideId guideId) {
    _requireStep(SmartTileStudioWizardStep.guide, 'choisir un guide');
    final usage = _state.usage;
    final guide = smartTileGuideById(guideId);
    if (usage == null || !guide.supportedUsages.contains(usage)) {
      throw StateError('Ce guide ne convient pas à l’usage choisi.');
    }
    _state = _state.copyWith(
      guideId: guideId,
      clearSource: true,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void moveToPlacement() {
    _requireStep(SmartTileStudioWizardStep.guide, 'ouvrir le placement');
    if (_state.guideId == null) {
      throw StateError('Choisissez un guide avant son placement.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.placement);
  }

  void chooseSource(SmartTileStudioSourceChoice choice) {
    _requireStep(SmartTileStudioWizardStep.placement, 'choisir une source');
    _state = _state.copyWith(
      sourceChoice: choice,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void configureGrid(SmartTileGridGeometry geometry) {
    _requireStep(SmartTileStudioWizardStep.placement, 'configurer la grille');
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
    _requireStep(SmartTileStudioWizardStep.placement, 'placer le guide');
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
    _requireStep(SmartTileStudioWizardStep.placement, 'effacer le placement');
    _state = _state.copyWith(clearAnchor: true);
  }

  void resetPlacementSource() {
    _requireStep(SmartTileStudioWizardStep.placement, 'changer de source');
    _state = _state.copyWith(
      clearSource: true,
      clearGrid: true,
      clearAnchor: true,
    );
  }

  void moveToTest() {
    _requireStep(SmartTileStudioWizardStep.placement, 'ouvrir le banc d’essai');
    if (_state.sourceChoice == null ||
        _state.gridGeometry == null ||
        _state.anchor == null) {
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

  void returnToGuide() {
    if (_state.usage == null) {
      throw StateError('Aucun usage à conserver.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.guide);
  }

  void returnToPlacement() {
    if (_state.guideId == null) {
      throw StateError('Aucun guide à replacer.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.placement);
  }

  void _requireStep(SmartTileStudioWizardStep expected, String action) {
    if (!_state.isCreating || _state.wizardStep != expected) {
      throw StateError('Impossible de $action pendant cette étape.');
    }
  }
}
