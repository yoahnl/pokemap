import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_actor_contact_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('runtime actor contact shadow collection', () {
    test('default actor contact config is an internal V0 contact blob', () {
      expect(
        kDefaultRuntimeActorContactShadowConfig.shadowProfileId,
        'runtime_actor_contact_default',
      );
      expect(
        kDefaultRuntimeActorContactShadowConfig.mode,
        ShadowCasterMode.contactBlob,
      );
      expect(
        kDefaultRuntimeActorContactShadowConfig.renderPass,
        ShadowRenderPass.actorContact,
      );
      expect(kDefaultRuntimeActorContactShadowConfig.opacity, 0.35);
      expect(kDefaultRuntimeActorContactShadowConfig.colorHexRgb, '000000');
      expect(
        kDefaultRuntimeActorContactShadowConfig.softnessMode,
        ShadowSoftnessMode.hardEdge,
      );
    });

    test('visible source creates one actorContact instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, hasLength(1));
      final instruction = collection.actorContact.single;
      expect(instruction.renderPass, ShadowRenderPass.actorContact);
      expect(instruction.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.opacity, 0.35);
      expect(instruction.colorHexRgb, '000000');
      expect(instruction.width, closeTo(19.2, 0.0001));
      expect(instruction.height, closeTo(8.64, 0.0001));
      expect(instruction.worldLeft, closeTo(90.4, 0.0001));
      expect(instruction.worldTop, closeTo(195.68, 0.0001));
    });

    test('invisible source creates no instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'hidden',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
            isVisible: false,
          ),
        ],
      );

      expect(collection, ShadowRuntimeInstructionCollection());
      expect(collection.actorContact, isEmpty);
    });

    test('multiple sources preserve order', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'first',
            footWorldX: 10,
            footWorldY: 20,
            visualWidth: 10,
            visualHeight: 10,
          ),
          RuntimeActorContactShadowSource(
            id: 'second',
            footWorldX: 30,
            footWorldY: 40,
            visualWidth: 10,
            visualHeight: 10,
          ),
        ],
      );

      expect(collection.actorContact, hasLength(2));
      expect(collection.actorContact[0].worldLeft, closeTo(7, 0.0001));
      expect(collection.actorContact[1].worldLeft, closeTo(27, 0.0001));
    });

    test('equal sources are not deduplicated', () {
      final source = RuntimeActorContactShadowSource(
        id: 'same',
        footWorldX: 10,
        footWorldY: 20,
        visualWidth: 10,
        visualHeight: 10,
      );

      final collection = buildRuntimeActorContactShadowCollection(
        sources: [source, source],
      );

      expect(collection.actorContact, hasLength(2));
      expect(collection.actorContact[0], collection.actorContact[1]);
    });

    test('opacity zero config still creates a retained instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        resolvedConfig: _resolvedConfig(opacity: 0),
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(collection.actorContact, hasLength(1));
      expect(collection.actorContact.single.opacity, 0);
    });

    test('none config creates no instruction', () {
      final collection = buildRuntimeActorContactShadowCollection(
        resolvedConfig: _resolvedConfig(mode: ShadowCasterMode.none),
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(collection.isEmpty, isTrue);
    });

    test('groundStatic config is rejected by the actor resolver', () {
      expect(
        () => buildRuntimeActorContactShadowCollection(
          resolvedConfig: _resolvedConfig(
            renderPass: ShadowRenderPass.groundStatic,
          ),
          sources: [
            RuntimeActorContactShadowSource(
              id: 'player',
              footWorldX: 100,
              footWorldY: 200,
              visualWidth: 32,
              visualHeight: 48,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('source rejects invalid runtime metrics', () {
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: double.nan,
          footWorldY: 200,
          visualWidth: 32,
          visualHeight: 48,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: 100,
          footWorldY: double.infinity,
          visualWidth: 32,
          visualHeight: 48,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: 100,
          footWorldY: 200,
          visualWidth: 0,
          visualHeight: 48,
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => RuntimeActorContactShadowSource(
          id: 'bad',
          footWorldX: 100,
          footWorldY: 200,
          visualWidth: 32,
          visualHeight: double.nan,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('source has value equality', () {
      final a = RuntimeActorContactShadowSource(
        id: 'same',
        footWorldX: 1,
        footWorldY: 2,
        visualWidth: 3,
        visualHeight: 4,
      );
      final b = RuntimeActorContactShadowSource(
        id: 'same',
        footWorldX: 1,
        footWorldY: 2,
        visualWidth: 3,
        visualHeight: 4,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('returned collection exposes immutable lists', () {
      final collection = buildRuntimeActorContactShadowCollection(
        sources: [
          RuntimeActorContactShadowSource(
            id: 'player',
            footWorldX: 100,
            footWorldY: 200,
            visualWidth: 32,
            visualHeight: 48,
          ),
        ],
      );

      expect(
        () => collection.instructions.add(collection.instructions.single),
        throwsUnsupportedError,
      );
    });
  });
}

ResolvedShadowConfig _resolvedConfig({
  ShadowCasterMode mode = ShadowCasterMode.contactBlob,
  ShadowRenderPass renderPass = ShadowRenderPass.actorContact,
  double opacity = 0.35,
}) {
  return ResolvedShadowConfig(
    shadowProfileId: 'runtime_actor_contact_test',
    mode: mode,
    renderPass: renderPass,
    offsetX: 0,
    offsetY: 0,
    scaleX: 1,
    scaleY: 1,
    opacity: opacity,
    colorHexRgb: '000000',
    softnessMode: ShadowSoftnessMode.hardEdge,
  );
}
