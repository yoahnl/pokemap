import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_cartridge.dart';
import 'package:pokemap_hub/src/ui/avelune/avelune_theme.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_game_shelf.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_geometry.dart';
import 'package:pokemap_hub/src/ui/avelune/home/avelune_home_view_data.dart';

void main() {
  testWidgets('shelf keeps add game last for 0, 1, 3, and 10 games',
      (tester) async {
    final geometry = AveluneHomeGeometry.resolve(
      viewportSize: const Size(390, 844),
    );

    for (final count in <int>[0, 1, 3, 10]) {
      final games = List<AveluneGameViewData>.generate(count, _game);
      await tester.pumpWidget(_app(_shelf(geometry, games)));
      await tester.pumpAndSettle();

      final list = tester.widget<ListView>(
        find.byKey(const ValueKey<String>('avelune-game-shelf-list')),
      );
      expect(list.scrollDirection, Axis.horizontal);
      expect(
        list.scrollCacheExtent!.value,
        lessThanOrEqualTo(kAveluneGameShelfMaxCacheExtent),
      );
      expect(list.childrenDelegate.estimatedChildCount, count + 1);

      if (count <= 3) {
        expect(
          find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
          findsOneWidget,
        );
      } else {
        await tester.drag(
          find.byKey(const ValueKey<String>('avelune-game-shelf-list')),
          const Offset(-2000, 0),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
          findsOneWidget,
        );
      }

      final sizes = find
          .byType(AveluneCartridge)
          .evaluate()
          .map((element) => tester.getSize(
                find.byElementPredicate((candidate) => candidate == element),
              ))
          .toSet();
      expect(sizes, <Size>{geometry.shelfCartridgeSize});
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('100-game shelf remains lazy and reveals selected last game',
      (tester) async {
    final geometry = AveluneHomeGeometry.resolve(
      viewportSize: const Size(390, 844),
    );
    final games = List<AveluneGameViewData>.generate(100, _game);

    await tester.pumpWidget(
      _app(
        _shelf(
          geometry,
          games,
          selectedGameId: games.last.id,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final builtGames = find.byKey(
      const ValueKey<String>('avelune-game-shelf-game'),
    );
    expect(builtGames.evaluate().length, lessThan(100));
    final selected = find.byKey(
      ValueKey<String>('avelune-game-shelf-item-${games.last.id}'),
    );
    expect(selected, findsOneWidget);
    final selectedRect = tester.getRect(selected);
    final shelfRect = tester.getRect(
      find.byKey(const ValueKey<String>('avelune-game-shelf')),
    );
    expect(selectedRect.overlaps(shelfRect), isTrue);
    expect(
      find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shelf routes game and add interactions without resizing items',
      (tester) async {
    final geometry = AveluneHomeGeometry.resolve(
      viewportSize: const Size(390, 844),
    );
    final games = <AveluneGameViewData>[
      _game(0),
      _game(1),
    ];
    String? selected;
    var addRequests = 0;

    await tester.pumpWidget(
      _app(
        _shelf(
          geometry,
          games,
          onGameSelected: (game) => selected = game.id,
          onAddGame: () => addRequests++,
        ),
      ),
    );

    await tester.tap(
      find.byKey(ValueKey<String>('avelune-game-shelf-item-${games[1].id}')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('avelune-game-shelf-add')),
    );
    expect(selected, games[1].id);
    expect(addRequests, 1);
  });
}

Widget _shelf(
  AveluneHomeGeometry geometry,
  List<AveluneGameViewData> games, {
  String? selectedGameId,
  ValueChanged<AveluneGameViewData>? onGameSelected,
  VoidCallback? onAddGame,
}) =>
    SizedBox(
      width: geometry.shelfRect.width,
      height: geometry.shelfRect.height,
      child: AveluneGameShelf(
        geometry: geometry,
        games: games,
        selectedGameId: selectedGameId,
        onGameSelected: onGameSelected,
        onAddGame: onAddGame,
      ),
    );

AveluneGameViewData _game(int index) => AveluneGameViewData(
      id: 'games.example.$index',
      title:
          index == 0 ? 'Une aventure au nom excessivement long' : 'Jeu $index',
      subtitle: 'Studio Avelune',
      authorName: 'Studio Avelune',
      artwork: const AveluneArtworkViewData(
        kind: AveluneArtworkKind.fallback,
      ),
      shellColor:
          index.isEven ? const Color(0xFF633C88) : const Color(0xFF126E78),
      validity: AveluneGameValidity.available,
      primaryAction: AvelunePrimaryAction.play,
      isSelected: false,
      lastSaveAt: null,
      playTimeSeconds: 0,
    );

Widget _app(Widget child) {
  final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
  return MaterialApp(
    theme: theme,
    home: Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
  );
}
