import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  Future<ui.Image> image() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 20, 20),
      Paint()..color = const Color(0xffff0000),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 0, 20, 20),
      Paint()..color = const Color(0xff00ff00),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 20, 20, 20),
      Paint()..color = const Color(0xff0000ff),
    );
    canvas.drawRect(
      const Rect.fromLTWH(20, 20, 20, 20),
      Paint()..color = const Color(0xffffff00),
    );
    final picture = recorder.endRecording();
    final result = await picture.toImage(40, 40);
    picture.dispose();
    return result;
  }

  test(
    'bitmap pieces crop row-major image pixels and rotate the selected slice',
    () async {
      final source = await image();
      addTearDown(source.dispose);
      final definition = ImagePuzzleDefinition(
        puzzleId: 'p',
        imageResourceId: 'i',
        rows: 1,
        columns: 2,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      ImagePuzzlePiecePainter(
        image: source,
        definition: definition,
        piece: const ImagePuzzlePiece(pieceId: 0, slot: 1, quarterTurns: 1),
      ).paint(canvas, const Size(20, 40));
      final picture = recorder.endRecording();
      final painted = await picture.toImage(20, 40);
      picture.dispose();
      final rgba = (await painted.toByteData())!.buffer.asUint8List();
      painted.dispose();
      List<int> pixel(int x, int y) =>
          rgba.sublist((y * 20 + x) * 4, (y * 20 + x) * 4 + 4);
      expect(pixel(4, 10), [0, 0, 255, 255]);
      expect(pixel(16, 10), [255, 0, 0, 255]);
      expect(pixel(4, 30), [0, 0, 255, 255]);
    },
  );
  testWidgets(
    'portrait puzzle renders image board, reserve, fixed pieces and keyboard controls',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final png = await tester.runAsync(() async {
        final source = await image();
        final png = await source.toByteData(format: ui.ImageByteFormat.png);
        source.dispose();
        return png;
      });
      final definition = ImagePuzzleDefinition(
        puzzleId: 'p',
        imageResourceId: 'i',
        rows: 2,
        columns: 2,
        fixedPieceIds: [3],
      );
      final commands = <RuntimeWorldServiceCommand>[];
      final snapshot = RuntimeWorldServiceSnapshot(
        revision: 7,
        request: OpenImagePuzzleService(
          interactionId: 'p',
          definition: definition,
        ),
        stage: RuntimeWorldServiceStage.active,
        content: RuntimeImagePuzzleServiceContent(
          progress: ImagePuzzleProgress(
            definition: definition,
            pieces: [
              const ImagePuzzlePiece(pieceId: 0, slot: 4),
              const ImagePuzzlePiece(pieceId: 1, slot: 1),
              const ImagePuzzlePiece(pieceId: 2, slot: 2),
              const ImagePuzzlePiece(pieceId: 3, slot: 3),
            ],
          ),
          bitmap: RuntimeImagePuzzleBitmap(
            bytes: Uint8List.view(png!.buffer),
            width: 40,
            height: 40,
          ),
          selectedPieceId: 0,
        ),
        actions: [
          for (final action in [
            RuntimeWorldServiceAction.select,
            RuntimeWorldServiceAction.move,
            RuntimeWorldServiceAction.rotate,
            RuntimeWorldServiceAction.reset,
            RuntimeWorldServiceAction.confirm,
            RuntimeWorldServiceAction.cancel,
          ])
            RuntimeWorldServiceActionAvailability.enabled(action),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          locale: const Locale('fr'),
          supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
          localizationsDelegates:
              PokeMapPlayerLocalizations.localizationsDelegates,
          home: PlayerInputScope(
            activeInputSource: PlayerInputSource.touch,
            child: PlayerImagePuzzleOverlay(
              snapshot: snapshot,
              onCommand: commands.add,
              hardwareGamepadEnabled: false,
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Réserve'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('puzzle-slot-0')));
      expect(commands.single.action, RuntimeWorldServiceAction.move);
      expect(commands.single.targetId, '0');
      expect(commands.single.secondaryTargetId, '0');
      expect(commands.single.snapshotRevision, 7);
      commands.clear();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      expect(commands.single.action, RuntimeWorldServiceAction.rotate);
      commands.clear();
      await tester.tap(find.byKey(const ValueKey('puzzle-slot-3')));
      expect(commands, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final scenario in [
    (rows: 16, columns: 16, width: 160, height: 160, tray: 64),
    (rows: 1, columns: 4, width: 1600, height: 40, tray: 8),
    (rows: 16, columns: 1, width: 40, height: 640, tray: 4),
  ]) {
    testWidgets(
      'portrait reaches last board and reserve cells for ${scenario.rows}x${scenario.columns} ${scenario.width}x${scenario.height}',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bytes = await tester.runAsync(() async {
          final recorder = ui.PictureRecorder();
          Canvas(recorder).drawRect(
            Rect.fromLTWH(
              0,
              0,
              scenario.width.toDouble(),
              scenario.height.toDouble(),
            ),
            Paint()..color = const Color(0xff336699),
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(scenario.width, scenario.height);
          picture.dispose();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return png!.buffer.asUint8List();
        });
        final definition = ImagePuzzleDefinition(
          puzzleId: 'large',
          imageResourceId: 'large-image',
          rows: scenario.rows,
          columns: scenario.columns,
          trayCapacity: scenario.tray,
          allowSwap: true,
        );
        final progress = ImagePuzzleProgress(
          definition: definition,
          pieces: [
            for (var id = 0; id < definition.pieceCount; id++)
              ImagePuzzlePiece(
                pieceId: id,
                slot: id == 0 ? definition.slotCount - 1 : id,
              ),
          ],
        );
        final bitmap = RuntimeImagePuzzleBitmap(
          bytes: bytes!,
          width: scenario.width,
          height: scenario.height,
        );
        final commands = <RuntimeWorldServiceCommand>[];
        int? selected;
        await tester.pumpWidget(
          MaterialApp(
            theme: PokeMapPlayerTheme.dark(),
            locale: const Locale('fr'),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            home: PlayerInputScope(
              activeInputSource: PlayerInputSource.touch,
              child: StatefulBuilder(
                builder: (context, update) => PlayerImagePuzzleOverlay(
                  snapshot: RuntimeWorldServiceSnapshot(
                    revision: 7 + commands.length,
                    request: OpenImagePuzzleService(
                      interactionId: 'large',
                      definition: definition,
                    ),
                    stage: RuntimeWorldServiceStage.active,
                    content: RuntimeImagePuzzleServiceContent(
                      progress: progress,
                      bitmap: bitmap,
                      selectedPieceId: selected,
                    ),
                    actions: [
                      for (final action in [
                        RuntimeWorldServiceAction.select,
                        RuntimeWorldServiceAction.move,
                        RuntimeWorldServiceAction.rotate,
                        RuntimeWorldServiceAction.reset,
                        RuntimeWorldServiceAction.confirm,
                        RuntimeWorldServiceAction.cancel,
                      ])
                        RuntimeWorldServiceActionAvailability.enabled(action),
                    ],
                  ),
                  hardwareGamepadEnabled: false,
                  onCommand: (command) {
                    commands.add(command);
                    if (command.action == RuntimeWorldServiceAction.select) {
                      update(() => selected = int.parse(command.targetId!));
                    }
                  },
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final verticalViewport = find.byKey(
          const ValueKey('puzzle-content-viewport'),
        );
        final horizontalViewport = find.byKey(
          const ValueKey('puzzle-board-viewport'),
        );
        if (scenario.rows == 16) {
          await tester.drag(verticalViewport, const Offset(0, -220));
          await tester.pumpAndSettle();
        }
        if (scenario.columns > 1) {
          final visibleBoard = tester
              .getRect(horizontalViewport)
              .intersect(tester.getRect(verticalViewport));
          await tester.dragFrom(visibleBoard.center, const Offset(-220, 0));
          await tester.pumpAndSettle();
        }
        final lastBoard = find.byKey(
          ValueKey('puzzle-slot-${definition.pieceCount - 1}'),
        );
        await tester.ensureVisible(lastBoard);
        await tester.pumpAndSettle();
        expect(
          lastBoard.hitTestable(),
          findsOneWidget,
          reason: 'The final board row and column must be reachable.',
        );
        final cellSize = tester.getSize(lastBoard);
        expect(cellSize.width, greaterThanOrEqualTo(48));
        expect(cellSize.height, greaterThanOrEqualTo(48));
        await tester.tap(lastBoard);
        await tester.pumpAndSettle();
        expect(commands.last.action, RuntimeWorldServiceAction.select);
        expect(commands.last.targetId, '${definition.pieceCount - 1}');
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        expect(commands.last.action, RuntimeWorldServiceAction.rotate);
        expect(commands.last.targetId, '${definition.pieceCount - 1}');
        await tester.ensureVisible(find.text('Tourner'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tourner'));
        expect(commands.last.action, RuntimeWorldServiceAction.rotate);
        expect(commands.last.targetId, '${definition.pieceCount - 1}');
        final lastTray = find.byKey(
          ValueKey('puzzle-slot-${definition.slotCount - 1}'),
        );
        await tester.ensureVisible(lastTray);
        await tester.pumpAndSettle();
        expect(
          lastTray.hitTestable(),
          findsOneWidget,
          reason: 'The final reserve slot must be reachable.',
        );
        expect(
          tester.getSize(lastTray),
          cellSize,
          reason:
              'A reserve piece must keep the same dimensions as a board piece.',
        );
        await tester.tap(lastTray);
        expect(commands.last.action, RuntimeWorldServiceAction.move);
        expect(commands.last.targetId, '${definition.pieceCount - 1}');
        expect(commands.last.secondaryTargetId, '${definition.slotCount - 1}');
        expect(find.text('Quitter').hitTestable(), findsOneWidget);
        expect(find.text('Vérifier').hitTestable(), findsOneWidget);
        final positions = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .map((state) => state.position)
            .toList();
        if (scenario.rows == 16) {
          expect(
            positions.any(
              (position) =>
                  axisDirectionToAxis(position.axisDirection) ==
                      Axis.vertical &&
                  position.pixels > 0,
            ),
            isTrue,
          );
        }
        if (scenario.columns > 1) {
          expect(
            positions.any(
              (position) =>
                  axisDirectionToAxis(position.axisDirection) ==
                      Axis.horizontal &&
                  position.pixels > 0,
            ),
            isTrue,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
