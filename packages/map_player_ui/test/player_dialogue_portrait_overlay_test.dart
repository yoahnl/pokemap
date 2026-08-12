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
      dialogue: const ProjectDialoguePresentationProfile(portraitSize: 160),
    );

    expect(
      tester.getSize(
        find.byKey(
          const ValueKey<String>('dialogue-portrait-shape-rounded'),
        ),
      ),
      const Size.square(72),
    );
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
    await _pump(
      tester,
      snapshot: _choiceSnapshot(portrait: portrait),
      dialogue: const ProjectDialoguePresentationProfile(
        portraitShape: ProjectDialoguePortraitShape.circle,
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('dialogue-portrait-shape-circle')),
      findsNothing,
    );
    expect(find.text('Continuer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authored portrait side and size reach the resolved asset', (
    tester,
  ) async {
    final portrait = (await tester.runAsync(() => _portrait('elia-side')))!;
    addTearDown(
      () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
    );
    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: portrait),
      dialogue: const ProjectDialoguePresentationProfile(
        portraitSide: ProjectDialoguePortraitSide.end,
        portraitSize: 120,
      ),
    );

    final row = tester.widget<Row>(
      find.byKey(const ValueKey<String>('dialogue-portrait-end')),
    );
    expect(row.textDirection, TextDirection.rtl);
    expect(
      tester.getSize(
        find.byKey(
          const ValueKey<String>('dialogue-portrait-shape-rounded'),
        ),
      ),
      const Size.square(120),
    );
    final image = tester.widget<Image>(
      find.byKey(
        const ValueKey<String>('dialogue-portrait-portrait.elia.surprised'),
      ),
    );
    expect((image.image as FileImage).file.path, portrait.absoluteFilePath);
  });

  for (final shape in ProjectDialoguePortraitShape.values) {
    testWidgets('renders the authored ${shape.name} portrait shape', (
      tester,
    ) async {
      final portrait = (await tester.runAsync(
        () => _portrait('elia-${shape.name}'),
      ))!;
      addTearDown(
        () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
      );
      await _pump(
        tester,
        snapshot: _lineSnapshot(portrait: portrait),
        dialogue: ProjectDialoguePresentationProfile(
          portraitShape: shape,
          portraitFrameWidth: 4,
          portraitFrameColor: '#FFAA00',
        ),
      );

      final material = tester.widget<Material>(
        find.byKey(ValueKey<String>('dialogue-portrait-shape-${shape.name}')),
      );
      final side = switch (material.shape) {
        CircleBorder(:final side) => side,
        RoundedRectangleBorder(:final side) => side,
        BeveledRectangleBorder(:final side) => side,
        _ => throw StateError('Unexpected portrait shape.'),
      };
      expect(side.width, 4);
      expect(side.color, const Color(0xFFFFAA00));
      expect(
        material.shape,
        switch (shape) {
          ProjectDialoguePortraitShape.circle => isA<CircleBorder>(),
          ProjectDialoguePortraitShape.rounded => isA<RoundedRectangleBorder>(),
          ProjectDialoguePortraitShape.square => isA<RoundedRectangleBorder>(),
          ProjectDialoguePortraitShape.cutCorner =>
            isA<BeveledRectangleBorder>(),
        },
      );
    });
  }

  testWidgets('styles a long speaker name without changing its semantics', (
    tester,
  ) async {
    final portrait = (await tester.runAsync(() => _portrait('elia-name')))!;
    addTearDown(
      () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
    );
    const speaker = 'Élia de la Vallée des Étoiles Filantes';
    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: portrait, speaker: speaker),
      dialogue: const ProjectDialoguePresentationProfile(
        nameplateStyle: ProjectDialogueNameplateStyle.floating,
        nameplateBorderWidth: 3,
        nameplateSurfaceColor: '#203040',
        nameplateBorderColor: '#AABBCC',
        nameplateTextColor: '#FFFFFF',
      ),
    );

    final material = tester.widget<Material>(
      find.byKey(const ValueKey<String>('dialogue-nameplate-floating')),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect(material.color, const Color(0xFF203040));
    expect(shape.side.width, 3);
    expect(shape.side.color, const Color(0xFFAABBCC));
    expect(find.bySemanticsLabel('$speaker, Attends… tu as vu ça ?'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait semantics are decorative beside a visible name', (
    tester,
  ) async {
    final portrait = (await tester.runAsync(
      () => _portrait('elia-semantics'),
    ))!;
    addTearDown(
      () => File(portrait.absoluteFilePath).parent.delete(recursive: true),
    );
    const dialogue = ProjectDialoguePresentationProfile();
    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: portrait),
      dialogue: dialogue,
    );
    expect(find.bySemanticsLabel('Portrait de Élia'), findsNothing);

    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: portrait),
      dialogue: dialogue,
      showSpeakerName: false,
    );
    expect(find.bySemanticsLabel('Portrait de Élia'), findsOneWidget);
  });

  testWidgets('reduced motion swaps portrait state without a transition', (
    tester,
  ) async {
    final first = (await tester.runAsync(
      () => _portrait('elia-first', assetId: 'portrait.elia.first'),
    ))!;
    final second = (await tester.runAsync(
      () => _portrait('elia-second', assetId: 'portrait.elia.second'),
    ))!;
    addTearDown(
      () => File(first.absoluteFilePath).parent.delete(recursive: true),
    );
    addTearDown(
      () => File(second.absoluteFilePath).parent.delete(recursive: true),
    );
    const dialogue = ProjectDialoguePresentationProfile(
      portraitTransition: ProjectDialoguePortraitTransition.slide,
      portraitTransitionMilliseconds: 600,
    );
    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: first),
      dialogue: dialogue,
      theme: PokeMapPlayerTheme.dark(reducedMotion: true),
    );

    final reduced = tester.widget<AnimatedSwitcher>(
      find.byKey(
        const ValueKey<String>('dialogue-portrait-transition-none'),
      ),
    );
    expect(reduced.duration, Duration.zero);

    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: second),
      dialogue: dialogue,
      theme: PokeMapPlayerTheme.dark(reducedMotion: true),
    );
    expect(
      tester
          .widget<Image>(
            find.byKey(
              const ValueKey<String>('dialogue-portrait-portrait.elia.second'),
            ),
          )
          .image,
      isA<FileImage>().having(
        (image) => image.file.path,
        'path',
        second.absoluteFilePath,
      ),
    );

    await _pump(
      tester,
      snapshot: _lineSnapshot(portrait: second),
      dialogue: dialogue,
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      tester
          .widget<AnimatedSwitcher>(
            find.byKey(
              const ValueKey<String>('dialogue-portrait-transition-slide'),
            ),
          )
          .duration,
      const Duration(milliseconds: 600),
    );
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
  ProjectDialoguePresentationProfile? dialogue,
  bool showSpeakerName = true,
}) {
  var resolvedTheme = theme ?? PokeMapPlayerTheme.dark();
  if (dialogue != null) {
    resolvedTheme = PokeMapPlayerTheme.withDialogueProfile(
      resolvedTheme,
      dialogue,
    );
  }
  return tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: resolvedTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler, padding: padding),
        child: RepaintBoundary(
          key: boundaryKey,
          child: Scaffold(
            body: PlayerDialogueOverlay(
              snapshot: snapshot,
              onCommand: (_) {},
              showSpeakerName: showSpeakerName,
            ),
          ),
        ),
      ),
    ),
  );
}

DialoguePresentationSnapshot _lineSnapshot({
  ResolvedDialoguePortrait? portrait,
  String text = 'Attends… tu as vu ça ?',
  String speaker = 'Élia',
}) {
  return DialoguePresentationSnapshot(
    revision: 7,
    mode: DialoguePresentationMode.line,
    nodeTitle: 'surprise',
    speaker: speaker,
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

Future<ResolvedDialoguePortrait> _portrait(
  String suffix, {
  String assetId = 'portrait.elia.surprised',
}) async {
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
    assetId: assetId,
    absoluteFilePath: file.path,
    fitMode: CharacterPortraitFitMode.cover,
  );
}
