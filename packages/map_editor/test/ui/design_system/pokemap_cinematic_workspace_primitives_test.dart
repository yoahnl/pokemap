import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('workspace toolbar exposes back, title and document status', (
    tester,
  ) async {
    var backCount = 0;
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: PokeMapCinematicWorkspaceToolbar(
              backLabel: 'Retour à la bibliothèque',
              title: 'Ouverture',
              contextLabel: 'Cinématique de présentation',
              onBack: () => backCount += 1,
              status: const PokeMapCinematicDocumentStatus(
                state: PokeMapCinematicDocumentState.dirty,
                label: 'Modifications non enregistrées',
              ),
              actions: const [Icon(Icons.fullscreen_rounded)],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ouverture'), findsOneWidget);
    expect(find.text('Cinématique de présentation'), findsOneWidget);
    expect(find.text('Modifications non enregistrées'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Retour à la bibliothèque'));
    expect(backCount, 1);
  });

  testWidgets('panel tabs synchronize selection and remain keyboard buttons', (
    tester,
  ) async {
    var selected = PokeMapCinematicPanelTab.layers;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PokeMapCinematicPanelTabs(
              selected: selected,
              layersLabel: 'Calques',
              propertiesLabel: 'Propriétés',
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Propriétés'));
    await tester.pump();

    expect(selected, PokeMapCinematicPanelTab.properties);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Propriétés'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('exit guard exposes three unambiguous actions', (tester) async {
    final activations = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PokeMapCinematicExitGuardActions(
            cancelLabel: 'Annuler',
            discardLabel: 'Quitter sans enregistrer',
            saveLabel: 'Enregistrer et quitter',
            onCancel: () => activations.add('cancel'),
            onDiscard: () => activations.add('discard'),
            onSave: () => activations.add('save'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Annuler'));
    await tester.tap(find.text('Quitter sans enregistrer'));
    await tester.tap(find.text('Enregistrer et quitter'));

    expect(activations, ['cancel', 'discard', 'save']);
  });

  testWidgets('toolbar adapts without overflow at compact desktop width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Scaffold(
          body: PokeMapCinematicWorkspaceToolbar(
            backLabel: 'Back to library',
            title: 'Opening cinematic with a deliberately long title',
            contextLabel: 'Presentation cinematic',
            onBack: () {},
            status: const PokeMapCinematicDocumentStatus(
              state: PokeMapCinematicDocumentState.saved,
              label: 'Saved',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Saved'), findsOneWidget);
  });
}
