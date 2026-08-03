import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_grid_detector.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_guide.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_studio_session.dart';

void main() {
  const geometry = SmartTileGridGeometry(
    imageWidth: 1760,
    imageHeight: 2304,
    cellWidth: 32,
    cellHeight: 32,
  );

  test('wizard enforces Usage, Guide, Placement, Test, Publish order', () {
    final session = SmartTileStudioSession()..startDraft();

    expect(session.state.wizardStep, SmartTileStudioWizardStep.usage);

    session
      ..chooseUsage(SmartTileUsage.path)
      ..moveToGuide()
      ..chooseGuide(SmartTileGuideId.erwCorner16)
      ..moveToPlacement()
      ..chooseSource(SmartTileStudioSourceChoice.projectImage)
      ..configureGrid(geometry)
      ..placeGuide(anchorColumn: 20, anchorRow: 20)
      ..moveToTest()
      ..moveToPublish();

    expect(session.state.wizardStep, SmartTileStudioWizardStep.publish);
    expect(session.state.usage, SmartTileUsage.path);
    expect(session.state.guideId, SmartTileGuideId.erwCorner16);
    expect(
      session.state.anchor,
      const SmartTileAtlasAnchor(column: 20, row: 20),
    );
  });

  test('canonical wizard exposes exactly the nine validated stages in order',
      () {
    expect(
      SmartTileStudioWizardStep.values.map((step) => step.name),
      <String>[
        'usage',
        'image',
        'grid',
        'materials',
        'connections',
        'variants',
        'forms',
        'test',
        'publish',
      ],
    );
    final session = SmartTileStudioSession()..startDraft();
    session
      ..chooseUsage(SmartTileUsage.path)
      ..moveToImage()
      ..chooseSource(SmartTileStudioSourceChoice.projectImage)
      ..moveToGrid()
      ..configureGrid(geometry)
      ..moveToMaterials()
      ..moveToConnections()
      ..chooseGuide(SmartTileGuideId.erwCorner16)
      ..moveToVariants()
      ..moveToForms()
      ..placeGuide(anchorColumn: 20, anchorRow: 20)
      ..moveToTest()
      ..moveToPublish();

    expect(session.state.wizardStep, SmartTileStudioWizardStep.publish);
  });

  test('guards every transition that needs a previous user decision', () {
    final session = SmartTileStudioSession()..startDraft();

    expect(session.moveToGuide, throwsStateError);
    session.chooseUsage(SmartTileUsage.path);
    expect(session.moveToPlacement, throwsStateError);
    session
      ..moveToGuide()
      ..chooseGuide(SmartTileGuideId.erwCorner16)
      ..moveToPlacement();
    expect(session.moveToTest, throwsStateError);
    session
      ..chooseSource(SmartTileStudioSourceChoice.projectImage)
      ..configureGrid(geometry);
    expect(session.moveToTest, throwsStateError);
    expect(
      () => session.placeGuide(anchorColumn: 0, anchorRow: 0),
      throwsStateError,
    );
  });

  test('changing usage clears guide, source, grid and anchor', () {
    final session = SmartTileStudioSession()..startDraft();
    session
      ..chooseUsage(SmartTileUsage.path)
      ..moveToGuide()
      ..chooseGuide(SmartTileGuideId.erwCorner16)
      ..moveToPlacement()
      ..chooseSource(SmartTileStudioSourceChoice.projectImage)
      ..configureGrid(geometry)
      ..placeGuide(anchorColumn: 20, anchorRow: 20)
      ..returnToUsage()
      ..chooseUsage(SmartTileUsage.terrain);

    expect(session.state.guideId, isNull);
    expect(session.state.sourceChoice, isNull);
    expect(session.state.gridGeometry, isNull);
    expect(session.state.anchor, isNull);
  });

  test('changing connections preserves image and grid but clears placement',
      () {
    final session = SmartTileStudioSession()..startDraft();
    session
      ..chooseUsage(SmartTileUsage.path)
      ..moveToGuide()
      ..chooseGuide(SmartTileGuideId.erwCorner16)
      ..moveToPlacement()
      ..chooseSource(SmartTileStudioSourceChoice.projectImage)
      ..configureGrid(geometry)
      ..placeGuide(anchorColumn: 20, anchorRow: 20)
      ..returnToGuide()
      ..chooseGuide(SmartTileGuideId.erwCorner16);

    expect(session.state.usage, SmartTileUsage.path);
    expect(session.state.guideId, SmartTileGuideId.erwCorner16);
    expect(
      session.state.sourceChoice,
      SmartTileStudioSourceChoice.projectImage,
    );
    expect(session.state.gridGeometry, geometry);
    expect(session.state.anchor, isNull);
  });
}
