import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  test(
    'prelit model surfaces can independently bypass additional lighting',
    () {
      expect(SpatialLightingProfile.stylized().surfaceStrength, 1);
      final native = SpatialLightingProfile.stylized(surfaceStrength: 0);
      expect(native.surfaceStrength, 0);
      expect(native.actorStrength, .25);
      expect(native.groundStrength, .7);
      for (final value in [-.1, 1.1, double.nan]) {
        expect(
          () => SpatialLightingProfile.stylized(surfaceStrength: value),
          throwsArgumentError,
        );
      }
    },
  );
  testWidgets('lighting remains disabled outside the experimental scope', (
    tester,
  ) async {
    SpatialLightingProfile? observed;
    SpatialLightingProfile? optional;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          observed = SpatialLightingPreview.of(context);
          optional = SpatialLightingPreview.maybeOf(context);
          return const SizedBox();
        },
      ),
    );
    expect(observed, same(SpatialLightingProfile.disabled));
    expect(observed!.enabled, isFalse);
    expect(optional, isNull);
  });

  testWidgets('the same descendant switches lighting on and back off', (
    tester,
  ) async {
    final controller = ValueNotifier(SpatialLightingProfile.disabled);
    addTearDown(controller.dispose);
    final observed = <SpatialLightingProfile>[];
    final content = Builder(
      builder: (context) {
        observed.add(SpatialLightingPreview.of(context));
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      SpatialLightingPreview(controller: controller, child: content),
    );
    final element = tester.element(find.byWidget(content));
    final lighting = SpatialLightingProfile.stylized(
      unlitMaterialNames: {'shadow'},
    );
    controller.value = lighting;
    await tester.pump();
    expect(observed.last, same(lighting));
    expect(tester.element(find.byWidget(content)), same(element));
    controller.value = SpatialLightingProfile.disabled;
    await tester.pump();
    expect(observed.last.enabled, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test('profiles normalize the sun and retain immutable exclusions', () {
    final names = {'shadow'};
    final lighting = SpatialLightingProfile.stylized(
      sunDirection: (x: 0, y: 2, z: 0),
      unlitMaterialNames: names,
    );
    names.add('water');
    expect(lighting.sunDirection, (x: 0.0, y: 1.0, z: 0.0));
    expect(lighting.unlitMaterialNames, {'shadow'});
    expect(
      () => lighting.unlitMaterialNames.add('water'),
      throwsUnsupportedError,
    );
  });

  test(
    'invalid light directions and blend strengths fail before rendering',
    () {
      for (final direction in [
        (x: 0.0, y: 0.0, z: 0.0),
        (x: double.nan, y: 1.0, z: 0.0),
      ]) {
        expect(
          () => SpatialLightingProfile.stylized(sunDirection: direction),
          throwsArgumentError,
        );
      }
      expect(
        () => SpatialLightingProfile.stylized(groundStrength: 1.1),
        throwsArgumentError,
      );
      expect(
        () => SpatialLightingProfile.stylized(actorStrength: -.1),
        throwsArgumentError,
      );
    },
  );
}
