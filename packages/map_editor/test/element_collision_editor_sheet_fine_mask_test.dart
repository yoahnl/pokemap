import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/panels/element_collision_editor_sheet.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/widgets/element_collision_triple_mask_editor.dart';

void main() {
  testWidgets(
      'collision editor sheet exposes grid and fine mask authoring modes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    await _pumpEditorLauncher(
      tester,
      image: image,
      initialProfile: const ElementCollisionProfile(
        cells: [GridPos(x: 1, y: 1)],
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();

    expect(find.text('Source utilisée par le gameplay'), findsOneWidget);
    expect(find.text('Collision par grille'), findsWidgets);
    expect(find.text('Masque fin'), findsOneWidget);
    expect(find.text('Pinceau +'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fine mask mode shows collision and occlusion mask labels',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    await _pumpEditorLauncher(
      tester,
      image: image,
      initialProfile: const ElementCollisionProfile(
        cells: [GridPos(x: 1, y: 1)],
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Masque fin'));
    await tester.pumpAndSettle();

    expect(find.text('Peindre collision'), findsOneWidget);
    expect(find.text('Effacer'), findsOneWidget);
    expect(find.textContaining('Masque collision'), findsWidgets);
    expect(find.textContaining('Masque occlusion'), findsWidgets);
    expect(find.textContaining('ne bloque pas'), findsWidgets);
    expect(
        find.textContaining('Mode aperçu : édition désactivée'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested element edit sheet can open the collision editor',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Builder(
              builder: (context) => Center(
                child: CupertinoButton(
                  child: const Text('Open element edit sheet'),
                  onPressed: () {
                    showMacosEditorTallSheet<void>(
                      context: context,
                      builder: (sheetContext) => Center(
                        child: CupertinoButton(
                          child: const Text('Ouvrir l’éditeur de collision'),
                          onPressed: () {
                            showElementCollisionEditorSheet(
                              context: sheetContext,
                              elementName: 'selbrume nested',
                              image: image,
                              source: _source,
                              tileWidth: 16,
                              tileHeight: 16,
                              initialProfile: const ElementCollisionProfile(
                                cells: [GridPos(x: 1, y: 1)],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open element edit sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ouvrir l’éditeur de collision'));
    await tester.pumpAndSettle();

    expect(find.text('Collision Editor'), findsOneWidget);
    expect(find.text('Masque fin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile with collisionMask opens with fine collision visible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    await _pumpEditorLauncher(
      tester,
      image: image,
      initialProfile: ElementCollisionProfile(
        collisionMask: _mask(widthPx: 64, heightPx: 64, solidIndex: 0),
        cells: const [GridPos(x: 3, y: 3)],
      ),
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();

    expect(find.text('Collision fine active'), findsOneWidget);
    expect(find.text('Masque fin'), findsOneWidget);
    expect(find.textContaining('Masque collision'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving preserves existing collision visual and occlusion masks',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    late Future<ElementCollisionProfile?> result;
    final collisionMask = _mask(widthPx: 64, heightPx: 64, solidIndex: 1);
    final visualMask = _mask(widthPx: 64, heightPx: 64, solidIndex: 2);
    final occlusionMask = _mask(widthPx: 64, heightPx: 64, solidIndex: 3);

    await _pumpEditorLauncher(
      tester,
      image: image,
      onOpen: (context) {
        result = showElementCollisionEditorSheet(
          context: context,
          elementName: 'selbrume maison fine',
          image: image,
          source: _source,
          tileWidth: 16,
          tileHeight: 16,
          initialProfile: ElementCollisionProfile(
            visualMask: visualMask,
            collisionMask: collisionMask,
            occlusionMask: occlusionMask,
            cells: const [GridPos(x: 3, y: 3)],
          ),
        );
      },
    );

    await tester.tap(find.text('Open collision editor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauvegarder'));
    await tester.pumpAndSettle();

    final saved = await result;
    expect(saved, isNotNull);
    expect(saved!.collisionMask?.dataBase64, collisionMask.dataBase64);
    expect(saved.visualMask?.dataBase64, visualMask.dataBase64);
    expect(saved.occlusionMask?.dataBase64, occlusionMask.dataBase64);
  });

  testWidgets('triple mask editor starts in paint collision mode',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peindre collision'), findsOneWidget);
    expect(find.text('Peindre'), findsOneWidget);
    expect(find.text('Effacer'), findsOneWidget);
    expect(
        find.textContaining('Mode aperçu : édition désactivée'), findsNothing);

    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    expect(emitted!.collisionMask, isNotNull);
    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits, contains(true));
  });

  testWidgets('triple mask editor paints a visible brush footprint',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => bit).length, greaterThan(1));
  });

  testWidgets('triple mask editor can zoom the pixel canvas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Zoom'), findsOneWidget);
    final before = tester.getSize(find.byType(CustomPaint).last);

    await tester.tap(find.text('200%'));
    await tester.pumpAndSettle();

    final after = tester.getSize(find.byType(CustomPaint).last);
    expect(after.width, greaterThan(before.width));
    expect(after.height, greaterThan(before.height));
  });

  testWidgets('triple mask editor can paint after zooming', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('200%'));
    await tester.pumpAndSettle();
    final canvasTopLeft = tester.getTopLeft(find.byType(CustomPaint).last);
    await tester.tapAt(canvasTopLeft + const Offset(360, 120));
    await tester.pumpAndSettle();

    expect(emitted?.collisionMask, isNotNull);
    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => bit).length, greaterThan(1));
  });

  testWidgets('triple mask editor previews the brush footprint on hover',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: const ElementCollisionProfile(),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture =
        await tester.createGesture(kind: ui.PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer(location: Offset.zero);
    await gesture.moveTo(tester.getCenter(find.byType(CustomPaint).last));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Aperçu pinceau 8px'), findsOneWidget);

    await tester.tap(find.text('16px'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Aperçu pinceau 16px'), findsOneWidget);
  });

  testWidgets('triple mask editor can erase after zooming', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: ElementCollisionProfile(
                    collisionMask: _fullMask(widthPx: 64, heightPx: 64),
                  ),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('200%'));
    await tester.pumpAndSettle();
    final canvasTopLeft = tester.getTopLeft(find.byType(CustomPaint).last);
    await tester.tapAt(canvasTopLeft + const Offset(360, 120));
    await tester.pumpAndSettle();

    expect(emitted?.collisionMask, isNotNull);
    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => !bit).length, greaterThan(1));
  });

  testWidgets('triple mask editor sculpts legacy grid collision by default',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;
    final fullGridCells = [
      for (var y = 0; y < _source.height; y++)
        for (var x = 0; x < _source.width; x++) GridPos(x: x, y: y),
    ];

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: ElementCollisionProfile(cells: fullGridCells),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Effacer est sélectionné'), findsOneWidget);
    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => bit).length, lessThan(64 * 64));
  });

  testWidgets('triple mask editor exposes explicit erase mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final image = await _testImage(width: 64, height: 64);
    ElementCollisionProfile? emitted;

    await tester.pumpWidget(
      MacosApp(
        home: MacosTheme(
          data: MacosThemeData.dark(),
          child: CupertinoPageScaffold(
            child: Center(
              child: SizedBox(
                width: 720,
                child: ElementCollisionTripleMaskEditor(
                  image: image,
                  source: _source,
                  tileWidth: 16,
                  tileHeight: 16,
                  profile: ElementCollisionProfile(
                    collisionMask: _fullMask(widthPx: 64, heightPx: 64),
                  ),
                  draftPadding: const WarpTriggerPadding(),
                  onProfileChanged: (next) => emitted = next,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(ElementCollisionTripleMaskEditor),
            matching: find.byType(Listener),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(emitted, isNotNull);
    final bits = ElementCollisionMaskCodec.decodePackedBits(
      widthPx: emitted!.collisionMask!.widthPx,
      heightPx: emitted!.collisionMask!.heightPx,
      dataBase64: emitted!.collisionMask!.dataBase64,
    );
    expect(bits.where((bit) => !bit).length, greaterThan(0));
  });
}

Future<void> _pumpEditorLauncher(
  WidgetTester tester, {
  required ui.Image image,
  ElementCollisionProfile? initialProfile,
  void Function(BuildContext context)? onOpen,
}) async {
  await tester.pumpWidget(
    MacosApp(
      home: MacosTheme(
        data: MacosThemeData.dark(),
        child: CupertinoPageScaffold(
          child: Builder(
            builder: (context) => Center(
              child: CupertinoButton(
                child: const Text('Open collision editor'),
                onPressed: () {
                  if (onOpen != null) {
                    onOpen(context);
                    return;
                  }
                  showElementCollisionEditorSheet(
                    context: context,
                    elementName: 'selbrume maison fine',
                    image: image,
                    source: _source,
                    tileWidth: 16,
                    tileHeight: 16,
                    initialProfile: initialProfile,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<ui.Image> _testImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const Color(0xFF496D94);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  required int solidIndex,
}) {
  final solidPixels = List<bool>.filled(widthPx * heightPx, false);
  solidPixels[solidIndex] = true;
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: solidPixels,
    ),
  );
}

ElementCollisionPixelMask _fullMask({
  required int widthPx,
  required int heightPx,
}) {
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: List<bool>.filled(widthPx * heightPx, true),
    ),
  );
}

const _source = TilesetSourceRect(
  x: 0,
  y: 0,
  width: 4,
  height: 4,
);
