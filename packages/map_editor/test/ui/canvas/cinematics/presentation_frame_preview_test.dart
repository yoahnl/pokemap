import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_frame_preview.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  testWidgets(
    'editor preview forwards the exact frame to the shared renderer',
    (tester) async {
      final frame = PresentationFrame(
        cinematicId: 'opening',
        timeUs: 0,
        durationUs: 1000000,
      );
      const port = _ContentPort();
      final playerTheme = PokeMapPlayerTheme.light();

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.dark(),
          home: PresentationFramePreview(
            frame: frame,
            orientation: PresentationFrameOrientation.portrait,
            contentPort: port,
            playerTheme: playerTheme,
          ),
        ),
      );

      final renderer = tester.widget<PresentationFrameRenderer>(
        find.byType(PresentationFrameRenderer),
      );
      expect(identical(renderer.frame, frame), isTrue);
      expect(identical(renderer.contentPort, port), isTrue);
      expect(renderer.orientation, PresentationFrameOrientation.portrait);
      expect(
        identical(
          tester
              .widget<Theme>(
                find.descendant(
                  of: find.byType(PresentationFramePreview),
                  matching: find.byType(Theme),
                ),
              )
              .data,
          playerTheme,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'editor adapter imports only the dedicated player renderer contract',
    () {
      final source = File(
        'lib/src/ui/canvas/cinematics/presentation/'
        'presentation_frame_preview.dart',
      ).readAsStringSync();
      final playerImports = RegExp(
        "import 'package:(map_player_ui|map_runtime)/[^']+';",
      ).allMatches(source).map((match) => match.group(0)).toList();

      expect(playerImports, [
        "import 'package:map_player_ui/presentation_renderer.dart';",
      ]);
      expect(source, isNot(contains('Stack(')));
      expect(source, isNot(contains('CustomPaint')));
    },
  );
}

final class _ContentPort implements PresentationFrameContentPort {
  const _ContentPort();

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) => const PresentationVisualUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Indisponible',
  );

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) => const PresentationCaptionUnavailable(
    reason: PresentationContentUnavailableReason.missing,
    message: 'Indisponible',
  );
}
