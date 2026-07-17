import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_visual_harness.dart';

void main() {
  group('NS-EVENT-V2-40 responsive and accessibility matrix', () {
    testWidgets('fits every supported desktop width without overflow',
        (tester) async {
      for (final viewport in eventBuilderV2PhaseKCaptureViewports) {
        await pumpEventBuilderV2PhaseK(tester, viewport: viewport);

        final workspace = tester.getRect(
          find.byKey(eventBuilderV2PhaseKWorkspaceFrameKey),
        );
        final list = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-list')),
        );
        final editor = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-editor')),
        );
        final inspector = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-inspector')),
        );

        expect(list.left, workspace.left);
        expect(inspector.right, lessThanOrEqualTo(workspace.right));
        expect(editor.width, greaterThanOrEqualTo(480));
        final exception = tester.takeException();
        expect(
          exception,
          isNull,
          reason: '$viewport\n${_exceptionDetails(exception)}',
        );

        final inlineLibrary = viewport.width >= 1480;
        expect(
          find.byKey(const ValueKey('event-builder-v2-library')),
          inlineLibrary ? findsOneWidget : findsNothing,
        );
        expect(
          find.text('Ouvrir la bibliothèque'),
          inlineLibrary ? findsNothing : findsOneWidget,
        );
      }
    });

    testWidgets(
        'keeps the reference width budgets at 1280, 1440, 1480 and wide',
        (tester) async {
      const expectations = <(double, List<double>)>[
        (1280, [220, 532, 320]),
        (1440, [220, 692, 320]),
        (1480, [236, 190, 500, 330]),
        (1920, [266, 213, 814, 388]),
      ];

      for (final entry in expectations) {
        await pumpEventBuilderV2PhaseK(
          tester,
          viewport: Size(entry.$1, 941),
        );
        final widths = <double>[
          tester
              .getSize(find.byKey(const ValueKey('event-builder-v2-list')))
              .width,
          if (entry.$1 >= 1480)
            tester
                .getSize(
                  find.byKey(const ValueKey('event-builder-v2-library')),
                )
                .width,
          tester
              .getSize(find.byKey(const ValueKey('event-builder-v2-editor')))
              .width,
          tester
              .getSize(
                find.byKey(const ValueKey('event-builder-v2-inspector')),
              )
              .width,
        ];
        expect(widths, entry.$2, reason: '${entry.$1.toInt()} px');
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('supports 125 percent text scale without clipping or overflow',
        (tester) async {
      for (final viewport in const <Size>[
        Size(1280, 941),
        Size(1672, 941),
      ]) {
        await pumpEventBuilderV2PhaseK(
          tester,
          viewport: viewport,
          textScaleFactor: 1.25,
        );

        expect(find.text('Rencontre rival au port'), findsWidgets);
        expect(find.text('DÉCLENCHEUR'), findsOneWidget);
        final workspace = tester.getRect(
          find.byKey(eventBuilderV2PhaseKWorkspaceFrameKey),
        );
        final editor = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-editor')),
        );
        final inspector = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-inspector')),
        );
        final newEvent = tester.getRect(
          find.byKey(const ValueKey('event-builder-v2-new-event')),
        );
        await tester.ensureVisible(find.text('Fin de l’événement'));
        await tester.pumpAndSettle();
        final endOfEvent = tester.getRect(
          find.text('Fin de l’événement'),
        );

        expect(inspector.right, lessThanOrEqualTo(workspace.right));
        expect(newEvent.bottom, lessThanOrEqualTo(workspace.bottom));
        expect(endOfEvent.left, greaterThanOrEqualTo(editor.left));
        expect(endOfEvent.right, lessThanOrEqualTo(editor.right));
        expect(endOfEvent.bottom, lessThanOrEqualTo(workspace.bottom));
        expect(tester.takeException(), isNull, reason: '$viewport at 125%');
      }
    });

    testWidgets('side sheet is modal, traps focus and restores the launcher',
        (tester) async {
      var createCount = 0;
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1440, 941),
        onCreateEvent: () => createCount += 1,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Event Builder V2, vue projet',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Port Selbrume, 5 événements',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ouvrir la bibliothèque'));
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.scopesRoute == true &&
              widget.properties.label ==
                  'Bibliothèque d’éléments de l’événement',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(createCount, 0,
          reason: 'The modal barrier must keep the background inert.');

      for (var index = 0; index < 6; index += 1) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_primaryFocusIsInsideSideSheet(), isTrue);
      }

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(_primaryFocusIsInsideSideSheet(), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(PokeMapDesktopSideSheet), findsNothing);
      final returnFocus = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('event-builder-v2-open-library')),
      );
      expect(returnFocus.focusNode!.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the explicit unsupported state below 1280',
        (tester) async {
      await pumpEventBuilderV2PhaseK(
        tester,
        viewport: const Size(1279, 941),
      );

      expect(find.text('Zone de travail trop étroite'), findsOneWidget);
      expect(
          find.textContaining('Votre sélection est conservée'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

bool _primaryFocusIsInsideSideSheet() {
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  if (focusContext.widget is PokeMapDesktopSideSheet) return true;
  var found = false;
  (focusContext as Element).visitAncestorElements((ancestor) {
    found = ancestor.widget is PokeMapDesktopSideSheet;
    return !found;
  });
  return found;
}

String _exceptionDetails(Object? exception) {
  if (exception is FlutterError) return exception.toStringDeep();
  return '$exception';
}
