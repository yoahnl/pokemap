import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../support/event_builder_v2_visual_harness.dart';

const _capturePhaseK = bool.fromEnvironment('NS_EVENT_V2_PHASE_K_CAPTURE');
const _captureStage = String.fromEnvironment(
  'NS_EVENT_V2_PHASE_K_CAPTURE_STAGE',
);

void main() {
  group('NS-EVENT-V2-38 reference grid', () {
    test('visual fixture is deterministic and covers every project group', () {
      final first = buildEventBuilderV2PhaseKReadModel();
      final second = buildEventBuilderV2PhaseKReadModel();

      expect(first.toDebugJson(), second.toDebugJson());
      expect(first.events.length, greaterThanOrEqualTo(15));
      expect(
        first.groups.map((group) => group.kind).toSet(),
        NarrativeEventProjectGroupKind.values.toSet(),
      );
      expect(
        first.eventByStableKey(eventBuilderV2PhaseKSelectedStableKey),
        isNotNull,
      );
      expect(eventBuilderV2PhaseKAppIconFile.existsSync(), isTrue);
    });

    testWidgets('matches the measured five-zone geometry at 1672 by 941',
        (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: eventBuilderV2PhaseKReferenceViewport,
      );

      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKCaptureKey)),
        const Rect.fromLTWH(0, 0, 1672, 941),
      );
      expect(find.byType(RawImage), findsOneWidget);
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKHeaderKey)),
        const Rect.fromLTWH(0, 0, 1672, 50),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKContextBarKey)),
        const Rect.fromLTWH(207, 50, 1465, 52),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKProjectSelectorKey)),
        const Rect.fromLTWH(16, 58, 182, 36),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKNavigationKey)),
        const Rect.fromLTWH(8, 102, 191, 817),
      );
      expect(
        tester.getRect(find.byKey(eventBuilderV2PhaseKWorkspaceFrameKey)),
        const Rect.fromLTWH(207, 102, 1456, 817),
      );

      final list = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-list')),
      );
      final library = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-library')),
      );
      final editor = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-editor')),
      );
      final inspector = tester.getRect(
        find.byKey(const ValueKey('event-builder-v2-inspector')),
      );

      expect(list, const Rect.fromLTWH(207, 102, 266, 817));
      expect(library, const Rect.fromLTWH(481, 102, 213, 817));
      expect(editor, const Rect.fromLTWH(702, 102, 565, 817));
      expect(inspector, const Rect.fromLTWH(1275, 102, 388, 817));
      expect(library.left - list.right, 8);
      expect(editor.left - library.right, 8);
      expect(inspector.left - editor.right, 8);
      expect(tester.takeException(), isNull);
    });

    testWidgets('matches the canonical phase K golden on every test run',
        (tester) async {
      await loadEventBuilderV2PhaseKCaptureFonts();
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: eventBuilderV2PhaseKReferenceViewport,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );

      final selectedListTitle = find.descendant(
        of: find.byKey(const ValueKey('event-builder-v2-list')),
        matching: find.text('Rencontre rival au port'),
      );
      final validatorLabel = find.descendant(
        of: find.byKey(eventBuilderV2PhaseKNavigationKey),
        matching: find.text('Validateur'),
      );
      expect(
        tester
            .renderObject<RenderParagraph>(selectedListTitle)
            .didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.renderObject<RenderParagraph>(validatorLabel).didExceedMaxLines,
        isFalse,
      );

      await expectLater(
        find.byKey(eventBuilderV2PhaseKCaptureKey),
        matchesGoldenFile(File(
          'test/goldens/event_builder_v2/phase_k/'
          'event_builder_v2_1672x941.png',
        ).absolute.path),
      );
    });

    testWidgets('conditionally captures the reference and viewport matrix',
        (tester) async {
      if (!_capturePhaseK) return;
      await loadEventBuilderV2PhaseKCaptureFonts();

      for (final viewport in eventBuilderV2PhaseKCaptureViewports) {
        await pumpEventBuilderV2PhaseK(
          tester,
          viewport: viewport,
          fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
        );
        final output = File(
          'test/goldens/event_builder_v2/phase_k/'
          'event_builder_v2_${viewport.width.toInt()}x${viewport.height.toInt()}.png',
        );
        output.parent.createSync(recursive: true);
        await expectLater(
          find.byKey(eventBuilderV2PhaseKCaptureKey),
          matchesGoldenFile(output.absolute.path),
        );
      }

      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: eventBuilderV2PhaseKReferenceViewport,
        selectedStableKey: eventBuilderV2PhaseKBrokenSourceStableKey,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );
      final brokenOutput = File(
        'test/goldens/event_builder_v2/phase_k/'
        'event_builder_v2_1672x941_broken_source.png',
      );
      brokenOutput.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(eventBuilderV2PhaseKCaptureKey),
        matchesGoldenFile(brokenOutput.absolute.path),
      );
    });

    testWidgets('conditionally captures before and after comparison evidence',
        (tester) async {
      if (_captureStage != 'before' && _captureStage != 'after') return;
      await loadEventBuilderV2PhaseKCaptureFonts();
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: eventBuilderV2PhaseKReferenceViewport,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );

      final output = File(
        '../../reports/narrativeStudio/events/'
        'phase_k_visual_evidence_v2/'
        '${_captureStage}_event_builder_v2_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        find.byKey(eventBuilderV2PhaseKCaptureKey),
        matchesGoldenFile(output.absolute.path),
      );
    });
  });
}
