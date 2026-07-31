import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_session.dart';

void main() {
  test('wizard enforces Source, Grid, Usage, Mapping, Test order', () {
    final session = SmartTileStudioSession()..startDraft();

    expect(
      () => session.moveToUsage(),
      throwsStateError,
    );

    session
      ..chooseSource(SmartTileStudioSourceChoice.projectImage)
      ..moveToGrid(
        detectedGeometry: const SmartTileGridGeometry(
          imageWidth: 160,
          imageHeight: 96,
          cellWidth: 32,
          cellHeight: 32,
        ),
      )
      ..moveToUsage()
      ..chooseUsage(SmartTileUsage.forestSurface)
      ..moveToMapping()
      ..moveToTest();

    expect(session.state.wizardStep, SmartTileStudioWizardStep.test);
    expect(session.state.usage, SmartTileUsage.forestSurface);
  });
}
