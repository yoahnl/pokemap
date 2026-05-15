import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeCullingBounds', () {
    test('creates valid bounds and derives right and bottom edges', () {
      final bounds = _bounds();

      expect(bounds.worldLeft, 0);
      expect(bounds.worldTop, 0);
      expect(bounds.width, 100);
      expect(bounds.height, 80);
      expect(bounds.worldRight, 100);
      expect(bounds.worldBottom, 80);
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _bounds(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _bounds(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _bounds(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _bounds(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid dimensions', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _bounds(width: width),
          throwsA(isA<ValidationException>()),
          reason: 'width $width should be rejected',
        );
      }

      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _bounds(height: height),
          throwsA(isA<ValidationException>()),
          reason: 'height $height should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = _bounds();
      final b = _bounds();
      final c = _bounds(worldLeft: 1);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('shadowRuntimeInstructionIntersectsBounds', () {
    test('keeps instructions fully inside bounds', () {
      expect(
        shadowRuntimeInstructionIntersectsBounds(_instruction(), _bounds()),
        isTrue,
      );
    });

    test('keeps partially visible instructions on every side', () {
      final bounds = _bounds();

      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: -5, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 95, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: -5, height: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: 75, height: 10),
          bounds,
        ),
        isTrue,
      );
    });

    test('keeps instructions touching each edge exactly', () {
      final bounds = _bounds();

      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: -10, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 100, width: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: -10, height: 10),
          bounds,
        ),
        isTrue,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: 80, height: 10),
          bounds,
        ),
        isTrue,
      );
    });

    test('filters instructions fully outside each side', () {
      final bounds = _bounds();

      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: -11, width: 10),
          bounds,
        ),
        isFalse,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 101, width: 10),
          bounds,
        ),
        isFalse,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: -11, height: 10),
          bounds,
        ),
        isFalse,
      );
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldTop: 81, height: 10),
          bounds,
        ),
        isFalse,
      );
    });

    test('uses padding to keep instructions just outside bounds', () {
      expect(
        shadowRuntimeInstructionIntersectsBounds(
          _instruction(worldLeft: 105, width: 10),
          _bounds(),
          padding: 5,
        ),
        isTrue,
      );
    });

    test('rejects invalid padding', () {
      for (final padding in <double>[
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => shadowRuntimeInstructionIntersectsBounds(
            _instruction(),
            _bounds(),
            padding: padding,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'padding $padding should be rejected',
        );
      }
    });
  });

  group('ShadowRuntimeInstructionCollection without culling', () {
    test('creates an empty collection', () {
      final collection = collectShadowRuntimeInstructions(const []);

      expect(collection.isEmpty, isTrue);
      expect(collection.isNotEmpty, isFalse);
      expect(collection.length, 0);
      expect(collection.instructions, isEmpty);
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, isEmpty);
    });

    test('collects one instruction', () {
      final instruction = _instruction();

      final collection = collectShadowRuntimeInstructions([instruction]);

      expect(collection.isEmpty, isFalse);
      expect(collection.isNotEmpty, isTrue);
      expect(collection.length, 1);
      expect(collection.instructions, [instruction]);
    });

    test('preserves global input order without sorting by renderPass', () {
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 30,
      );
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 10,
      );

      final collection = collectShadowRuntimeInstructions([actor, ground]);

      expect(collection.instructions, [actor, ground]);
    });

    test('copies instructions defensively and exposes immutable lists', () {
      final first = _instruction(worldLeft: 10);
      final second = _instruction(worldLeft: 20);
      final source = [first];

      final collection = collectShadowRuntimeInstructions(source);
      source.add(second);

      expect(collection.instructions, [first]);
      expect(() => collection.instructions.add(second), throwsUnsupportedError);
      expect(() => collection.groundStatic.add(second), throwsUnsupportedError);
      expect(() => collection.actorContact.add(second), throwsUnsupportedError);
    });

    test('groups instructions by renderPass while preserving group order', () {
      final groundA = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 10,
      );
      final actorA = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 20,
      );
      final groundB = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 30,
      );
      final actorB = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 40,
      );

      final collection = collectShadowRuntimeInstructions([
        groundA,
        actorA,
        groundB,
        actorB,
      ]);

      expect(collection.groundStatic, [groundA, groundB]);
      expect(collection.actorContact, [actorA, actorB]);
    });

    test('does not deduplicate equal instructions', () {
      final instruction = _instruction();

      final collection = collectShadowRuntimeInstructions([
        instruction,
        instruction,
      ]);

      expect(collection.instructions, [instruction, instruction]);
      expect(collection.length, 2);
    });

    test('keeps opacity zero instructions', () {
      final instruction = _instruction(opacity: 0);

      final collection = collectShadowRuntimeInstructions([instruction]);

      expect(collection.instructions, [instruction]);
      expect(collection.instructions.single.opacity, 0);
    });

    test('rejects invalid cullingPadding even without bounds', () {
      for (final padding in <double>[
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => collectShadowRuntimeInstructions(
            [_instruction()],
            cullingPadding: padding,
          ),
          throwsA(isA<ValidationException>()),
          reason: 'cullingPadding $padding should be rejected',
        );
      }
    });

    test('uses value equality and matching hashCode', () {
      final a = collectShadowRuntimeInstructions([_instruction()]);
      final b = collectShadowRuntimeInstructions([_instruction()]);
      final c = collectShadowRuntimeInstructions([
        _instruction(worldLeft: 11),
      ]);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('collectShadowRuntimeInstructions with culling', () {
    test('filters outside instructions and keeps visible instructions', () {
      final inside = _instruction(worldLeft: 10, worldTop: 10);
      final outside = _instruction(worldLeft: 200, worldTop: 10);

      final collection = collectShadowRuntimeInstructions(
        [inside, outside],
        cullingBounds: _bounds(),
      );

      expect(collection.instructions, [inside]);
    });

    test('keeps partially visible and edge-touching instructions', () {
      final partial = _instruction(worldLeft: -5, width: 10);
      final touching = _instruction(worldLeft: 100, width: 10);

      final collection = collectShadowRuntimeInstructions(
        [partial, touching],
        cullingBounds: _bounds(),
      );

      expect(collection.instructions, [partial, touching]);
    });

    test('preserves visible order and groups after culling', () {
      final actorOutside = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 200,
      );
      final groundA = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 10,
      );
      final actorA = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 20,
      );
      final groundB = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 30,
      );

      final collection = collectShadowRuntimeInstructions(
        [
          actorOutside,
          groundA,
          actorA,
          groundB,
        ],
        cullingBounds: _bounds(),
      );

      expect(collection.instructions, [groundA, actorA, groundB]);
      expect(collection.groundStatic, [groundA, groundB]);
      expect(collection.actorContact, [actorA]);
    });

    test('uses cullingPadding and does not deduplicate', () {
      final paddedVisible = _instruction(worldLeft: 105, width: 10);

      final collection = collectShadowRuntimeInstructions(
        [
          paddedVisible,
          paddedVisible,
        ],
        cullingBounds: _bounds(),
        cullingPadding: 5,
      );

      expect(collection.instructions, [paddedVisible, paddedVisible]);
    });
  });
}

ShadowRuntimeCullingBounds _bounds({
  double worldLeft = 0,
  double worldTop = 0,
  double width = 100,
  double height = 80,
}) {
  return ShadowRuntimeCullingBounds(
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
  );
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 10,
  double worldTop = 10,
  double width = 10,
  double height = 10,
  double opacity = 0.35,
}) {
  return ShadowRuntimeRenderInstruction(
    shape: renderPass == ShadowRenderPass.actorContact
        ? ShadowRuntimeShapeKind.contactBlob
        : ShadowRuntimeShapeKind.ellipse,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
  );
}
