import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('layer row synchronizes selection visibility and locking', (
    tester,
  ) async {
    var selections = 0;
    bool? visibility;
    bool? locked;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PokeMapCinematicLayerRow(
            kind: PokeMapCinematicLayerKind.visual,
            label: 'Titre principal',
            selected: true,
            visible: true,
            locked: false,
            visibilityLabel: 'Masquer Titre principal',
            lockLabel: 'Verrouiller Titre principal',
            dragLabel: 'Réordonner Titre principal',
            onSelect: () => selections += 1,
            onVisibilityChanged: (value) => visibility = value,
            onLockChanged: (value) => locked = value,
          ),
        ),
      ),
    );

    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Titre principal'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Titre principal'));
    await tester.tap(find.bySemanticsLabel('Masquer Titre principal'));
    await tester.tap(find.bySemanticsLabel('Verrouiller Titre principal'));

    expect(selections, 1);
    expect(visibility, isFalse);
    expect(locked, isTrue);
  });

  testWidgets('locked layer remains selectable from the layer tree', (
    tester,
  ) async {
    var selections = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapCinematicLayerRow(
            kind: PokeMapCinematicLayerKind.visual,
            label: 'Logo verrouillé',
            visible: true,
            locked: true,
            visibilityLabel: 'Masquer le logo',
            lockLabel: 'Déverrouiller le logo',
            dragLabel: 'Réordonner le logo',
            onSelect: () => selections += 1,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Logo verrouillé'));
    expect(selections, 1);
  });

  testWidgets('group header exposes expansion and aggregate state', (
    tester,
  ) async {
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PokeMapCinematicLayerGroupHeader(
            label: 'Visuels',
            expanded: expanded,
            hidden: true,
            locked: true,
            toggleLabel: 'Déplier Visuels',
            stateLabel: 'Visuels masqués et verrouillés',
            onToggleExpanded: () => expanded = true,
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Visuels masqués et verrouillés'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('Déplier Visuels'));
    expect(expanded, isTrue);
  });
}
