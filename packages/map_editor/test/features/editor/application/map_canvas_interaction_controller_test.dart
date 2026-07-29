import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_interaction_controller.dart';

void main() {
  group('MapCanvasInteractionController', () {
    test('exposes draggingSelection as a canvas interaction kind', () {
      expect(
        MapCanvasInteractionKind.values.map((kind) => kind.name),
        contains('draggingSelection'),
      );
    });

    test(
      'promotes only the primary owner to an exclusive selection drag',
      () {
        final controller = MapCanvasInteractionController();
        final started = controller.beginPointer(
          _input(pointerId: 51, buttons: kPrimaryButton),
        );
        final interactionId = started.session!.interactionId;

        expect(
          controller.promotePending(
            pointerId: 52,
            kind: MapCanvasInteractionKind.draggingSelection,
          ),
          isNull,
        );
        expect(
          controller
              .beginPointer(
                _input(pointerId: 52, buttons: kPrimaryButton),
              )
              .status,
          MapCanvasInteractionStartStatus.rejectedBusy,
        );

        final promoted = controller.promotePending(
          pointerId: 51,
          kind: MapCanvasInteractionKind.draggingSelection,
        );

        expect(promoted, isNotNull);
        expect(promoted?.kind, MapCanvasInteractionKind.draggingSelection);
        expect(promoted?.interactionId, interactionId);
        expect(promoted?.pointerId, 51);
        expect(promoted?.contextAtStart, _context);
        expect(controller.ownsPointer(51), isTrue);
        expect(controller.ownsPointer(52), isFalse);
        expect(
          controller.promotePending(
            pointerId: 51,
            kind: MapCanvasInteractionKind.draggingSelection,
          ),
          isNull,
          reason: 'an owned drag cannot be promoted a second time',
        );
      },
    );

    test(
      'selection drag terminals commit or rollback exactly once',
      () {
        final controller = MapCanvasInteractionController();
        controller.beginPointer(
          _input(pointerId: 61, buttons: kPrimaryButton),
        );
        controller.promotePending(
          pointerId: 61,
          kind: MapCanvasInteractionKind.draggingSelection,
        );

        expect(controller.finishPointer(99), isNull);
        expect(
          controller.activeSession?.kind,
          MapCanvasInteractionKind.draggingSelection,
        );
        final committed = controller.finishPointer(61);
        expect(committed?.terminal, MapCanvasInteractionTerminal.commit);
        expect(
          committed?.session.kind,
          MapCanvasInteractionKind.draggingSelection,
        );
        expect(controller.finishPointer(61), isNull);
        expect(controller.cancelPointer(61), isNull);
        expect(controller.isIdle, isTrue);

        controller.beginPointer(
          _input(pointerId: 62, buttons: kPrimaryButton),
        );
        controller.promotePending(
          pointerId: 62,
          kind: MapCanvasInteractionKind.draggingSelection,
        );

        final cancelled = controller.cancelPointer(62);
        expect(cancelled?.terminal, MapCanvasInteractionTerminal.rollback);
        expect(
          cancelled?.session.kind,
          MapCanvasInteractionKind.draggingSelection,
        );
        expect(controller.cancelPointer(62), isNull);
        expect(controller.finishPointer(62), isNull);
        expect(controller.cancelActive(), isNull);
        expect(controller.acceptsScroll, isTrue);
      },
    );

    test('resolves buttons and modifiers before any editing intent', () {
      final controller = MapCanvasInteractionController();

      final primary = controller.beginPointer(
        _input(buttons: kPrimaryButton),
      );
      expect(primary.status, MapCanvasInteractionStartStatus.started);
      expect(
        primary.session?.kind,
        MapCanvasInteractionKind.pendingPrimary,
      );
      expect(
        controller.cancelActive()?.terminal,
        MapCanvasInteractionTerminal.rollback,
      );

      final spacePrimary = controller.beginPointer(
        _input(
          pointerId: 2,
          buttons: kPrimaryButton,
          modifiers: const MapCanvasInteractionModifiers(space: true),
        ),
      );
      expect(spacePrimary.status, MapCanvasInteractionStartStatus.started);
      expect(
        spacePrimary.session?.kind,
        MapCanvasInteractionKind.panning,
      );
      expect(
        spacePrimary.session?.modifiersAtStart.space,
        isTrue,
      );
      controller.finishPointer(2);

      final secondary = controller.beginPointer(
        _input(pointerId: 12, buttons: kSecondaryButton),
      );
      expect(secondary.status, MapCanvasInteractionStartStatus.ignored);
      expect(controller.isIdle, isTrue);

      final middle = controller.beginPointer(
        _input(pointerId: 14, buttons: kTertiaryButton),
      );
      expect(
        middle.session?.kind,
        MapCanvasInteractionKind.panning,
      );
      controller.finishPointer(14);

      final mixed = controller.beginPointer(
        _input(
          pointerId: 99,
          buttons: kPrimaryButton | kSecondaryButton,
        ),
      );
      expect(
        mixed.status,
        MapCanvasInteractionStartStatus.rejectedButtons,
      );
      expect(controller.isIdle, isTrue);
    });

    test('keeps one exclusive owner and ignores non-owner terminals', () {
      final controller = MapCanvasInteractionController();
      final started = controller.beginPointer(
        _input(pointerId: 7, buttons: kPrimaryButton),
      );
      final interactionId = started.session!.interactionId;

      final second = controller.beginPointer(
        _input(pointerId: 8, buttons: kPrimaryButton),
      );
      expect(second.status, MapCanvasInteractionStartStatus.rejectedBusy);
      expect(controller.activeSession?.interactionId, interactionId);
      expect(controller.ownsPointer(7), isTrue);
      expect(controller.ownsPointer(8), isFalse);
      expect(controller.finishPointer(8), isNull);
      expect(controller.activeSession?.interactionId, interactionId);

      final promoted = controller.promotePending(
        pointerId: 7,
        kind: MapCanvasInteractionKind.paintingStroke,
      );
      expect(promoted?.kind, MapCanvasInteractionKind.paintingStroke);

      final finished = controller.finishPointer(7);
      expect(finished?.terminal, MapCanvasInteractionTerminal.commit);
      expect(finished?.session.interactionId, interactionId);
      expect(controller.finishPointer(7), isNull);
      expect(controller.isIdle, isTrue);
    });

    test(
        'changed move buttons rollback while matching moves and pointer up commit',
        () {
      final controller = MapCanvasInteractionController();
      controller.beginPointer(
        _input(pointerId: 41, buttons: kPrimaryButton),
      );
      controller.promotePending(
        pointerId: 41,
        kind: MapCanvasInteractionKind.paintingStroke,
      );

      expect(
        controller.cancelPointerIfButtonsChanged(
          pointerId: 41,
          buttons: kPrimaryButton,
        ),
        isNull,
      );
      expect(
        controller.cancelPointerIfButtonsChanged(
          pointerId: 99,
          buttons: kPrimaryButton | kSecondaryButton,
        ),
        isNull,
      );
      expect(
        controller.activeSession?.kind,
        MapCanvasInteractionKind.paintingStroke,
      );

      final mixed = controller.cancelPointerIfButtonsChanged(
        pointerId: 41,
        buttons: kPrimaryButton | kSecondaryButton,
      );
      expect(mixed?.terminal, MapCanvasInteractionTerminal.rollback);
      expect(
        mixed?.session.kind,
        MapCanvasInteractionKind.paintingStroke,
      );
      expect(controller.isIdle, isTrue);
      expect(
        controller.cancelPointerIfButtonsChanged(
          pointerId: 41,
          buttons: kPrimaryButton,
        ),
        isNull,
      );

      controller.beginPointer(
        _input(pointerId: 42, buttons: kPrimaryButton),
      );
      final missingButton = controller.cancelPointerIfButtonsChanged(
        pointerId: 42,
        buttons: 0,
      );
      expect(
        missingButton?.terminal,
        MapCanvasInteractionTerminal.rollback,
      );
      expect(controller.isIdle, isTrue);

      controller.beginPointer(
        _input(pointerId: 43, buttons: kPrimaryButton),
      );
      expect(
        controller.finishPointer(43)?.terminal,
        MapCanvasInteractionTerminal.commit,
      );
      expect(controller.isIdle, isTrue);
    });

    test('cancel is rollback, idempotent, and reopens scroll routing', () {
      final controller = MapCanvasInteractionController();
      expect(controller.acceptsScroll, isTrue);

      controller.beginPointer(
        _input(pointerId: 4, buttons: kPrimaryButton),
      );
      controller.promotePending(
        pointerId: 4,
        kind: MapCanvasInteractionKind.drawingZone,
      );
      expect(controller.acceptsScroll, isFalse);

      final cancelled = controller.cancelPointer(4);
      expect(cancelled?.terminal, MapCanvasInteractionTerminal.rollback);
      expect(
        cancelled?.session.kind,
        MapCanvasInteractionKind.drawingZone,
      );
      expect(controller.cancelPointer(4), isNull);
      expect(controller.acceptsScroll, isTrue);
    });

    test('pan zoom accepts only a trackpad while idle', () {
      final controller = MapCanvasInteractionController();

      final mouse = controller.beginPanZoom(
        _input(
          pointerId: 20,
          kind: MapCanvasPointerKind.mouse,
          buttons: 0,
        ),
      );
      expect(
        mouse.status,
        MapCanvasInteractionStartStatus.rejectedPointerKind,
      );

      final trackpad = controller.beginPanZoom(
        _input(
          pointerId: 21,
          kind: MapCanvasPointerKind.trackpad,
          buttons: 0,
        ),
      );
      expect(trackpad.status, MapCanvasInteractionStartStatus.started);
      expect(
        trackpad.session?.kind,
        MapCanvasInteractionKind.trackpadPanZoom,
      );
      expect(controller.finishPointer(21)?.terminal,
          MapCanvasInteractionTerminal.commit);
    });

    test('captures the complete modifier snapshot at interaction start', () {
      final controller = MapCanvasInteractionController();
      const modifiers = MapCanvasInteractionModifiers(
        shift: true,
        alt: true,
        control: true,
        meta: true,
      );

      final started = controller.beginPointer(
        _input(
          pointerId: 30,
          buttons: kPrimaryButton,
          modifiers: modifiers,
        ),
      );

      expect(started.session?.modifiersAtStart, modifiers);
      expect(started.session?.pointerKind, MapCanvasPointerKind.mouse);
      expect(started.session?.buttonsAtStart, kPrimaryButton);
      expect(started.session?.contextAtStart, _context);
    });
  });
}

MapCanvasInteractionInput _input({
  int pointerId = 1,
  MapCanvasPointerKind kind = MapCanvasPointerKind.mouse,
  int buttons = kPrimaryButton,
  MapCanvasInteractionModifiers modifiers =
      const MapCanvasInteractionModifiers(),
}) {
  return MapCanvasInteractionInput(
    pointerId: pointerId,
    pointerKind: kind,
    buttons: buttons,
    modifiers: modifiers,
    context: _context,
  );
}

const _context = MapCanvasInteractionContext(
  projectRootPath: '/projects/example',
  mapId: 'map',
  activeMapPath: '/projects/example/maps/map.json',
  layerId: 'ground',
  toolKey: 'tilePaint',
  targetId: null,
  guidedNavigation: false,
);
