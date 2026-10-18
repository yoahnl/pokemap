import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_ui_image.dart';

void main() {
  testWidgets('consumes exact styled segments and the admitted inline image', (
    tester,
  ) async {
    final bytes = _png();
    final lease = await tester.runAsync(() => decodeRuntimeUiImage(bytes));
    addTearDown(lease!.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: _snapshot(bytes, image: lease.image),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    final image = tester.widget<RawImage>(
      find.byKey(const ValueKey('dialogue-inline-icon-pocket')),
    );
    expect(identical(image.image, lease.image), isTrue);
    expect(image.width, 16);
    expect(image.height, 16);
    expect(image.filterQuality, FilterQuality.none);
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .singleWhere((text) => text.textSpan != null);
    final span = text.textSpan! as TextSpan;
    expect((span.children!.first as TextSpan).text, 'Found ');
    expect(
      (span.children!.first as TextSpan).style!.color,
      const Color(0xff0070f8),
    );
    expect(span.children!.whereType<WidgetSpan>(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto waiting line does not offer early confirmation', (
    tester,
  ) async {
    var commands = 0;
    final lease = await tester.runAsync(() => decodeRuntimeUiImage(_png()));
    addTearDown(lease!.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: _snapshot(_png(), image: lease.image),
            onCommand: (_) => commands++,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('dialogue-tap-zone')));
    expect(commands, 0);
  });

  testWidgets('missing typed icon bytes fail explicitly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: _snapshot(null),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isA<StateError>());
  });
}

DialoguePresentationSnapshot _snapshot(Uint8List? png, {ui.Image? image}) =>
    DialoguePresentationSnapshot(
      revision: 1,
      mode: DialoguePresentationMode.line,
      nodeTitle: 'Start',
      speaker: null,
      text: 'Found \uFFFC!',
      fullText: 'Found \uFFFC!',
      isCurrentLineFullyRevealed: true,
      isLastContent: false,
      choices: const [],
      isAdvanceAvailable: false,
      segments: [
        DialogueTextSegment(
          'Found ',
          style: DialogueSegmentStyle(colorArgb: 0xff0070f8),
        ),
        DialogueIconSegment(assetId: 'pocket', widthPx: 16, heightPx: 16),
        DialogueTextSegment('!'),
      ],
      iconPngBytes: png == null ? const {} : {'pocket': png},
      iconImages: image == null ? const {} : {'pocket': image},
    );

Uint8List _png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
);
