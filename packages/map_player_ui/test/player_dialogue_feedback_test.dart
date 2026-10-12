import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('consumes exact styled segments and inline imported PNG bytes', (
    tester,
  ) async {
    final bytes = _png();
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: _snapshot(bytes),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
    final image = tester.widget<Image>(
      find.byKey(const ValueKey('dialogue-inline-icon-pocket')),
    );
    expect((image.image as MemoryImage).bytes, bytes);
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
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: _snapshot(_png()),
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

DialoguePresentationSnapshot _snapshot(Uint8List? png) =>
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
    );

Uint8List _png() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aUx8AAAAASUVORK5CYII=',
);
