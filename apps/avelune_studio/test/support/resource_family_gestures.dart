import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_family_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm2_ui_fixture.dart';

Future<void> selectResourceFamily(
  WidgetTester tester,
  ResourceLibraryFamily family,
) async {
  final target = find.byKey(ValueKey('resource-family-${family.name}'));
  if (target.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('resource-family-chooser')));
    await pumpIo(tester, frames: 6);
  }
  await _revealFamilyControl(tester, target);
  await tester.tap(target);
  await pumpIo(tester, frames: 8);
}

Future<void> openResourceCharacters(WidgetTester tester) async {
  final target = find.text('Personnages');
  if (target.evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('resource-family-chooser')));
    await pumpIo(tester, frames: 6);
  }
  await _revealFamilyControl(tester, target);
  await tester.tap(target);
  await pumpIo(tester, frames: 8);
}

Future<void> _revealFamilyControl(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find
          .descendant(
            of: find.byType(ResourceFamilyNavigation),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await tester.ensureVisible(target);
  await pumpIo(tester, frames: 2);
}
