import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_workspace_pane.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm2_ui_fixture.dart';

Future<void> selectResourceFamily(
  WidgetTester tester,
  ResourceLibraryFamily family,
) async {
  final navigation = tester
      .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
      .navigation;
  navigation.library.selectFamily(family);
  final loading = navigation.loadFamily(family);
  await pumpIo(tester, frames: 8);
  expect(await loading, isTrue, reason: navigation.error);
  navigation.showLibrary();
  await pumpIo(tester, frames: 4);
}

Future<void> openResourceCharacters(WidgetTester tester) async {
  final navigation = tester
      .widget<ResourceWorkspacePane>(find.byType(ResourceWorkspacePane))
      .navigation;
  final opening = navigation.openCharacters();
  await pumpIo(tester, frames: 8);
  await opening;
  expect(navigation.error, isNull);
  await pumpIo(tester, frames: 4);
}
