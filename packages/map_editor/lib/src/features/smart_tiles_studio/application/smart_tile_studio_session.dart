import 'package:map_core/map_core.dart';

import 'smart_tile_grid_detector.dart';

enum SmartTileStudioWizardStep { source, grid, usage, mapping, test }

enum SmartTileStudioSourceChoice {
  projectImage,
  registeredAtlas,
  emptyPreset,
}

final class SmartTileStudioSessionState {
  const SmartTileStudioSessionState({
    this.isCreating = false,
    this.wizardStep = SmartTileStudioWizardStep.source,
    this.sourceChoice,
    this.gridGeometry,
    this.usage,
  });

  final bool isCreating;
  final SmartTileStudioWizardStep wizardStep;
  final SmartTileStudioSourceChoice? sourceChoice;
  final SmartTileGridGeometry? gridGeometry;
  final SmartTileUsage? usage;

  SmartTileStudioSessionState copyWith({
    bool? isCreating,
    SmartTileStudioWizardStep? wizardStep,
    SmartTileStudioSourceChoice? sourceChoice,
    SmartTileGridGeometry? gridGeometry,
    SmartTileUsage? usage,
    bool clearSourceChoice = false,
    bool clearGridGeometry = false,
    bool clearUsage = false,
  }) {
    return SmartTileStudioSessionState(
      isCreating: isCreating ?? this.isCreating,
      wizardStep: wizardStep ?? this.wizardStep,
      sourceChoice:
          clearSourceChoice ? null : sourceChoice ?? this.sourceChoice,
      gridGeometry:
          clearGridGeometry ? null : gridGeometry ?? this.gridGeometry,
      usage: clearUsage ? null : usage ?? this.usage,
    );
  }
}

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

  void chooseSource(SmartTileStudioSourceChoice choice) {
    _state = _state.copyWith(sourceChoice: choice);
  }

  void moveToGrid({
    required SmartTileGridGeometry detectedGeometry,
  }) {
    if (!_state.isCreating || _state.sourceChoice == null) {
      throw StateError('Choose a Smart Tile source before configuring grid.');
    }
    _state = _state.copyWith(
      wizardStep: SmartTileStudioWizardStep.grid,
      gridGeometry: detectedGeometry,
    );
  }

  void updateGrid(SmartTileGridGeometry geometry) {
    if (_state.wizardStep != SmartTileStudioWizardStep.grid) {
      throw StateError('Grid can only be edited during the Grid step.');
    }
    _state = _state.copyWith(gridGeometry: geometry);
  }

  void moveToUsage() {
    if (_state.wizardStep != SmartTileStudioWizardStep.grid ||
        _state.gridGeometry == null) {
      throw StateError('Configure the Smart Tile grid before choosing usage.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.usage);
  }

  void chooseUsage(SmartTileUsage usage) {
    if (_state.wizardStep != SmartTileStudioWizardStep.usage) {
      throw StateError('Usage can only be chosen during the Usage step.');
    }
    _state = _state.copyWith(usage: usage);
  }

  void moveToMapping() {
    if (_state.wizardStep != SmartTileStudioWizardStep.usage ||
        _state.usage == null) {
      throw StateError('Choose a Smart Tile usage before mapping.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.mapping);
  }

  void moveToTest() {
    if (_state.wizardStep != SmartTileStudioWizardStep.mapping) {
      throw StateError('Configure Smart Tile mappings before testing.');
    }
    _state = _state.copyWith(wizardStep: SmartTileStudioWizardStep.test);
  }
}
