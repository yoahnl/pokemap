import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('renders the resolved portrait with authored fit and semantics', (
    tester,
  ) async {
    final portrait = (await tester.runAsync(
      () => _portrait('elia-surprised'),
    ))!;
    addTearDown(
      () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
    );

    await _pump(tester, snapshot: _lineSnapshot(portrait: portrait));

    expect(find.byType(PlayerPortraitFrame), findsOneWidget);
    final image = tester.widget<Image>(
      find.byKey(
        const ValueKey<String>('dialogue-portrait-portrait.elia.surprised'),
      ),
    );
    expect(image.fit, BoxFit.cover);
    expect((image.image as FileImage).file.path, portrait.absoluteFilePath);
    expect(find.bySemanticsLabel('Élia, Attends… tu as vu ça ?'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps the legacy text-only layout when no portrait is resolved',
    (tester) async {
      await _pump(tester, snapshot: _lineSnapshot());

      expect(find.byType(PlayerPortraitFrame), findsNothing);
      expect(find.text('Élia'), findsOneWidget);
      expect(find.text('Attends… tu as vu ça ?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('long portrait dialogue remains usable on a narrow safe area', (
    tester,
  ) async {
    final portrait = (await tester.runAsync(
      () => _portrait('elia-narrow'),
    ))!;
    addTearDown(
      () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
    );
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      snapshot: _lineSnapshot(
        portrait: portrait,
        text:
            'Cette phrase volontairement très longue vérifie que le portrait, '
            'le nom, le texte et l’action restent utilisables sur un petit écran.',
      ),
      textScaler: const TextScaler.linear(2),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
    );

    expect(find.byType(PlayerPortraitFrame), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('choice mode never retains the previous line portrait', (
    tester,
  ) async {
    final portrait = (await tester.runAsync(
      () => _portrait('elia-choice'),
    ))!;
    addTearDown(
      () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
    );
    await _pump(tester, snapshot: _choiceSnapshot(portrait: portrait));

    expect(find.byType(PlayerPortraitFrame), findsNothing);
    expect(find.text('Continuer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final theme in <({String name, ThemeData theme})>[
    (name: 'light', theme: PokeMapPlayerTheme.light()),
    (name: 'dark', theme: PokeMapPlayerTheme.dark()),
  ]) {
    testWidgets('golden portrait dialogue ${theme.name}', (tester) async {
      final portrait = (await tester.runAsync(
        () => _portrait('elia-${theme.name}'),
      ))!;
      addTearDown(
        () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
      );
      tester.view.physicalSize = const Size(800, 450);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        snapshot: _lineSnapshot(portrait: portrait),
        theme: theme.theme,
        boundaryKey: const ValueKey<String>('portrait-dialogue-golden'),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byKey(const ValueKey<String>('portrait-dialogue-golden')),
        matchesGoldenFile(
          'goldens/dialogue_portrait/${theme.name}_portrait_dialogue.png',
        ),
      );
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required DialoguePresentationSnapshot snapshot,
  ThemeData? theme,
  TextScaler textScaler = TextScaler.noScaling,
  EdgeInsets padding = EdgeInsets.zero,
  Key? boundaryKey,
}) {
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme ?? PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler, padding: padding),
        child: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(
            body: PlayerDialogueOverlay(snapshot: snapshot, onCommand: (_) {}),
          ),
        ),
      ),
    ),
  );
}

DialoguePresentationSnapshot _lineSnapshot({
  ResolvedDialoguePortrait? portrait,
  String text = 'Attends… tu as vu ça ?',
}) {
  return DialoguePresentationSnapshot(
    revision: 7,
    mode: DialoguePresentationMode.line,
    nodeTitle: 'surprise',
    speaker: 'Élia',
    text: text,
    fullText: text,
    isCurrentLineFullyRevealed: true,
    isLastContent: false,
    choices: const <DialoguePresentationChoice>[],
    portrait: portrait,
  );
}

DialoguePresentationSnapshot _choiceSnapshot({
  ResolvedDialoguePortrait? portrait,
}) {
  return DialoguePresentationSnapshot(
    revision: 8,
    mode: DialoguePresentationMode.choices,
    nodeTitle: 'choice',
    speaker: null,
    text: '',
    fullText: '',
    isCurrentLineFullyRevealed: true,
    isLastContent: false,
    choices: const <DialoguePresentationChoice>[
      DialoguePresentationChoice(index: 0, label: 'Continuer', selected: true),
    ],
    portrait: portrait,
  );
}

Future<ResolvedDialoguePortrait> _portrait(String suffix) async {
  final directory = await Directory.systemTemp.createTemp('player_portrait_');
  final file = File('${directory.path}/$suffix.png');
  await file.writeAsBytes(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9tsAAAAASUVORK5CYII=',
    ),
  );
  return ResolvedDialoguePortrait(
    characterId: 'elia',
    characterName: 'Élia',
    portraitStateId: 'surprised',
    portraitStateName: 'Surprise',
    assetId: 'portrait.elia.surprised',
    absoluteFilePath: file.path,
    fitMode: CharacterPortraitFitMode.cover,
  );
}
