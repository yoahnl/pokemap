import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  test('high contrast Avelune tokens increase secondary legibility', () {
    final normal =
        applyAveluneTheme(ThemeData.dark()).extension<AveluneColors>()!;
    final highContrast = applyAveluneTheme(
      ThemeData.dark(),
      highContrast: true,
    ).extension<AveluneColors>()!;

    expect(
      highContrast.textSecondary.computeLuminance(),
      greaterThan(normal.textSecondary.computeLuminance()),
    );
    expect(
      highContrast.outline.computeLuminance(),
      greaterThan(normal.outline.computeLuminance()),
    );
  });

  testWidgets(
    'hero, shelf, and add slots share the canonical cartridge ratio',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 126,
                child: AveluneCartridge(
                  key: ValueKey<String>('hero-cartridge'),
                  gameId: 'games.example.hero',
                  title: 'Aube',
                  subtitle: 'Studio Brume',
                  displaySize: AveluneCartridgeDisplaySize.hero,
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 84,
                child: AveluneCartridge(
                  key: ValueKey<String>('shelf-cartridge'),
                  gameId: 'games.example.shelf',
                  title: 'Le Train de 17h42',
                  subtitle: 'Studio Brume',
                  displaySize: AveluneCartridgeDisplaySize.shelf,
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 84,
                child: AveluneCartridge.addGame(
                  key: ValueKey<String>('add-cartridge'),
                  displaySize: AveluneCartridgeDisplaySize.shelf,
                ),
              ),
            ],
          ),
        ),
      );

      for (final key in <String>[
        'hero-cartridge',
        'shelf-cartridge',
        'add-cartridge',
      ]) {
        final finder = find.byKey(ValueKey<String>(key));
        final size = tester.getSize(finder);
        expect(size.width / size.height,
            closeTo(kAveluneCartridgeAspectRatio, 0.001));
        expect(size.height, greaterThan(size.width));
        final aspectRatio = tester.widget<AspectRatio>(
          find
              .descendant(
                of: finder,
                matching: find.byType(AspectRatio),
              )
              .first,
        );
        expect(aspectRatio.aspectRatio, kAveluneCartridgeAspectRatio);
        for (final structureKey in <String>[
          'avelune-cartridge-shell',
          'avelune-cartridge-material-texture',
          'avelune-cartridge-wear-texture',
          'avelune-cartridge-bevel',
          'avelune-cartridge-brand-band',
          'avelune-cartridge-cover',
          'avelune-cartridge-cover-gloss',
          'avelune-cartridge-connectors',
        ]) {
          expect(
            find.descendant(
              of: finder,
              matching: find.byKey(ValueKey<String>(structureKey)),
            ),
            findsOneWidget,
          );
        }
        final texture = tester.widget<Image>(
          find.descendant(
            of: finder,
            matching: find.byKey(
              const ValueKey<String>(
                'avelune-cartridge-material-texture',
              ),
            ),
          ),
        );
        expect(
          (texture.image as AssetImage).assetName,
          'assets/avelune/materials/matte_abs_grain.webp',
        );
        final wear = tester.widget<Image>(
          find.descendant(
            of: finder,
            matching: find.byKey(
              const ValueKey<String>(
                'avelune-cartridge-wear-texture',
              ),
            ),
          ),
        );
        expect(
          (wear.image as AssetImage).assetName,
          'assets/avelune/materials/aged_abs_wear.webp',
        );
      }

      expect(find.byType(AveluneCartridge), findsNWidgets(3));
      expect(
        find.descendant(
          of: find.byType(AveluneCartridge),
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'long titles and selection never change shelf cartridge constraints',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 92,
                child: AveluneCartridge(
                  key: ValueKey<String>('short-title'),
                  gameId: 'games.example.short',
                  title: 'Aube',
                  displaySize: AveluneCartridgeDisplaySize.shelf,
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: AveluneCartridge(
                  key: ValueKey<String>('long-title'),
                  gameId: 'games.example.long',
                  title: 'Une aventure au nom excessivement long',
                  subtitle: 'Un studio au nom tout aussi long',
                  selected: true,
                  displaySize: AveluneCartridgeDisplaySize.shelf,
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 92,
                child: AveluneCartridge.addGame(
                  key: ValueKey<String>('add-slot'),
                  displaySize: AveluneCartridgeDisplaySize.shelf,
                ),
              ),
            ],
          ),
        ),
      );

      final sizes = <Size>[
        tester.getSize(find.byKey(const ValueKey<String>('short-title'))),
        tester.getSize(find.byKey(const ValueKey<String>('long-title'))),
        tester.getSize(find.byKey(const ValueKey<String>('add-slot'))),
      ];
      expect(sizes.toSet(), hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('hero and shelf use the same authored shell color',
      (tester) async {
    const authoredShellColor = Color(0xFF126E78);

    await tester.pumpWidget(
      _app(
        const Row(
          children: <Widget>[
            SizedBox(
              width: 126,
              child: AveluneCartridge(
                gameId: 'games.example.aube',
                title: 'Aube',
                displaySize: AveluneCartridgeDisplaySize.hero,
                shellColor: authoredShellColor,
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 84,
              child: AveluneCartridge(
                gameId: 'games.example.aube',
                title: 'Aube',
                displaySize: AveluneCartridgeDisplaySize.shelf,
                shellColor: authoredShellColor,
              ),
            ),
          ],
        ),
      ),
    );

    final cartridges = tester
        .widgetList<AveluneCartridge>(find.byType(AveluneCartridge))
        .toList(growable: false);
    expect(cartridges, hasLength(2));
    expect(
      cartridges.map((cartridge) => cartridge.displaySize).toSet(),
      <AveluneCartridgeDisplaySize>{
        AveluneCartridgeDisplaySize.hero,
        AveluneCartridgeDisplaySize.shelf,
      },
    );
    expect(
      cartridges.map((cartridge) => cartridge.shellColor).toSet(),
      <Color?>{authoredShellColor},
    );
  });

  testWidgets('selected and invalid states are announced without color alone',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 120,
          child: AveluneCartridge(
            key: ValueKey<String>('semantic-cartridge'),
            gameId: 'games.example.invalid',
            title: 'Aube',
            selected: true,
            invalid: true,
            displaySize: AveluneCartridgeDisplaySize.hero,
          ),
        ),
      ),
    );

    final node = tester.getSemantics(
      find.byKey(const ValueKey<String>('semantic-cartridge')),
    );
    expect(node.label, contains('Aube'));
    expect(node.label, contains('indisponible'));
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    semantics.dispose();
  });
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: child,
        ),
      ),
    );
