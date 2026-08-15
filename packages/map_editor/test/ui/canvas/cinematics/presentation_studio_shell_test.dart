import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/l10n/app_localizations.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_shell.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_diagnostic.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('critical diagnostic announces, focuses and recovers', (
    tester,
  ) async {
    var recoveries = 0;
    await _pumpShell(
      tester,
      store: _MemoryLayoutStore(),
      diagnostic: const PresentationStudioDiagnostic(
        code: PresentationDiagnosticCodes.saveConflict,
        severity: PresentationDiagnosticSeverity.error,
        title: 'Conflit d’enregistrement',
        cause: 'Le projet a changé sur le disque.',
        impact: 'Le brouillon local est conservé et n’a pas été écrasé.',
        actionLabel: 'Recharger la version externe',
      ),
      onDiagnosticAction: () => recoveries += 1,
    );

    expect(
      find.textContaining('Cause : Le projet a changé sur le disque.'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'Impact : Le brouillon local est conservé et n’a pas été écrasé.',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('Code : cinematic.presentation.save_conflict'),
      findsOneWidget,
    );
    final semantics = tester.getSemantics(
      find.byKey(presentationStudioDiagnosticCalloutKey),
    );
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
    expect(
      find.bySemanticsLabel('Recharger la version externe'),
      findsOneWidget,
    );
    expect(
      Focus.of(
        tester.element(find.byKey(presentationStudioDiagnosticFocusKey)),
      ).hasFocus,
      isTrue,
    );

    await tester.tap(find.text('Recharger la version externe'));
    await tester.pump();
    expect(recoveries, 1);
  });

  testWidgets(
    'clean Presentation shell exits immediately and owns every slot',
    (tester) async {
      var exits = 0;
      final store = _MemoryLayoutStore();

      await _pumpShell(tester, store: store, onExit: () => exits += 1);

      expect(find.byKey(presentationStudioShellKey), findsOneWidget);
      expect(find.text('OUTILS APERÇU'), findsOneWidget);
      expect(find.text('CANVAS SLOT'), findsOneWidget);
      expect(find.text('CALQUES SLOT'), findsOneWidget);
      expect(find.text('TIMELINE SLOT'), findsOneWidget);
      expect(find.text('Cinématiques in-game'), findsNothing);
      expect(find.text('Cinématiques de présentation'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Retour à la bibliothèque'));
      await tester.pumpAndSettle();

      expect(exits, 1);
      expect(find.text('Enregistrer avant de quitter ?'), findsNothing);
    },
  );

  testWidgets('English shell stays operable at 200 percent text scale', (
    tester,
  ) async {
    var saves = 0;
    await _pumpShell(
      tester,
      store: _MemoryLayoutStore(),
      locale: const Locale('en'),
      textScaler: const TextScaler.linear(2),
      addPanel: const Text('ADD PANEL'),
      diagnostic: const PresentationStudioDiagnostic(
        code: PresentationDiagnosticCodes.saveFailed,
        severity: PresentationDiagnosticSeverity.error,
        title: 'Save failed',
        cause: 'The project changed on disk.',
        impact: 'The local draft is preserved.',
        actionLabel: '',
      ),
      onDiagnosticAction: () {},
      onSave: () async {
        saves += 1;
        return true;
      },
    );

    expect(find.bySemanticsLabel('Back to library'), findsOneWidget);
    expect(find.text('Presentation cinematic'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Layers'), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(
      find.textContaining('Cause: The project changed on disk.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(saves, 1);
  });

  testWidgets(
    'dirty Presentation shell guards exit with the three exact actions',
    (tester) async {
      var exits = 0;
      var discards = 0;
      var saves = 0;
      final store = _MemoryLayoutStore();

      await _pumpShell(
        tester,
        store: store,
        documentState: PokeMapCinematicDocumentState.dirty,
        onExit: () => exits += 1,
        onDiscard: () async => discards += 1,
        onSave: () async {
          saves += 1;
          return true;
        },
      );

      await tester.tap(find.bySemanticsLabel('Retour à la bibliothèque'));
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer avant de quitter ?'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Quitter sans enregistrer'), findsOneWidget);
      expect(find.text('Enregistrer et quitter'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(exits, 0);

      await tester.tap(find.bySemanticsLabel('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter sans enregistrer'));
      await tester.pumpAndSettle();
      expect(discards, 1);
      expect(exits, 1);

      await tester.tap(find.bySemanticsLabel('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer et quitter'));
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(exits, 2);
    },
  );

  testWidgets('panel and timeline resizing only persists local layout', (
    tester,
  ) async {
    final store = _MemoryLayoutStore(
      initial: const PresentationStudioLayout(
        inspectorWidth: 320,
        timelineHeight: 240,
      ),
    );

    await _pumpShell(tester, store: store);

    await tester.drag(
      find.byKey(presentationStudioInspectorResizeKey),
      const Offset(-48, 0),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(presentationStudioTimelineResizeKey),
      const Offset(0, -32),
    );
    await tester.pumpAndSettle();

    expect(store.writes, isNotEmpty);
    expect(store.writes.last.inspectorWidth, greaterThan(320));
    expect(store.writes.last.timelineHeight, greaterThan(240));
  });

  testWidgets('panel tabs stay exclusive and resize handles work by keyboard', (
    tester,
  ) async {
    final store = _MemoryLayoutStore(
      initial: const PresentationStudioLayout(
        inspectorWidth: 320,
        timelineHeight: 240,
      ),
    );

    await _pumpShell(tester, store: store);

    expect(find.text('CALQUES SLOT'), findsOneWidget);
    expect(find.text('PROPRIÉTÉS SLOT'), findsNothing);
    await tester.tap(find.text('Propriétés'));
    await tester.pump();
    expect(find.text('CALQUES SLOT'), findsNothing);
    expect(find.text('PROPRIÉTÉS SLOT'), findsOneWidget);

    await tester.tap(find.byKey(presentationStudioInspectorResizeKey));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(store.writes.last.inspectorWidth, greaterThan(320));
    expect(find.text('PROPRIÉTÉS SLOT'), findsOneWidget);
  });

  testWidgets(
    'Ajouter temporarily owns the inspector and Escape restores its exact tab',
    (tester) async {
      await _pumpShell(
        tester,
        store: _MemoryLayoutStore(),
        addPanel: const Text('ADD PANEL'),
      );

      await tester.tap(find.text('Propriétés'));
      await tester.pump();
      await tester.tap(find.text('Ajouter'));
      await tester.pump();

      expect(find.text('ADD PANEL'), findsOneWidget);
      expect(find.text('Calques'), findsNothing);
      expect(find.text('Propriétés'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(find.text('ADD PANEL'), findsNothing);
      expect(find.text('PROPRIÉTÉS SLOT'), findsOneWidget);
    },
  );

  for (final size in <Size>[
    const Size(1280, 800),
    const Size(1672, 941),
    const Size(1920, 1080),
  ]) {
    final name = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Presentation shell remains reachable and matches $name', (
      tester,
    ) async {
      await _pumpShell(tester, store: _MemoryLayoutStore(), surfaceSize: size);

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Retour à la bibliothèque'), findsOneWidget);
      expect(find.text('Calques'), findsOneWidget);
      expect(find.text('TIMELINE SLOT'), findsOneWidget);
      await expectLater(
        find.byKey(presentationStudioShellKey),
        matchesGoldenFile(
          File(
            'test/goldens/narrative_studio/cinematics/'
            'presentation_studio_shell_$name.png',
          ).absolute.path,
        ),
      );
    });
  }
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required _MemoryLayoutStore store,
  PokeMapCinematicDocumentState documentState =
      PokeMapCinematicDocumentState.saved,
  VoidCallback? onExit,
  Future<void> Function()? onDiscard,
  Future<bool> Function()? onSave,
  Widget? addPanel,
  PresentationStudioDiagnostic? diagnostic,
  VoidCallback? onDiagnosticAction,
  Size surfaceSize = const Size(1280, 800),
  Locale locale = const Locale('fr'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: PokeMapTheme.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: PresentationStudioShell(
          title: 'Ouverture Avelune',
          documentState: documentState,
          statusLabel: documentState == PokeMapCinematicDocumentState.saved
              ? 'Enregistré'
              : 'Modifications non enregistrées',
          layoutStore: store,
          onExit: onExit ?? () {},
          onDiscard: onDiscard ?? () async {},
          onSave: onSave ?? () async => true,
          previewToolbar: const Text('OUTILS APERÇU'),
          canvas: const Text('CANVAS SLOT'),
          layersPanel: const Text('CALQUES SLOT'),
          propertiesPanel: const Text('PROPRIÉTÉS SLOT'),
          addPanel: addPanel,
          diagnostic: diagnostic,
          onDiagnosticAction: onDiagnosticAction,
          timeline: const Text('TIMELINE SLOT'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final class _MemoryLayoutStore implements PresentationStudioLayoutStore {
  _MemoryLayoutStore({this.initial});

  final PresentationStudioLayout? initial;
  final List<PresentationStudioLayout> writes = [];

  @override
  Future<PresentationStudioLayout?> read() async => initial;

  @override
  Future<void> write(PresentationStudioLayout layout) async {
    writes.add(layout);
  }
}
