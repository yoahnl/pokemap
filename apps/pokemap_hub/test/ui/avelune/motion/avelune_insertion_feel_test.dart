import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

/// How inserting a cartridge has to feel.
///
/// Two defects reported from a device build: the cartridge sank past the console
/// and reappeared underneath it, and the game launched before the console had
/// time to run its LED sequence. The approved latched reference
/// (`motion/insertion_latched_393x852.png`) shows the shell standing proud of
/// the hardware with only its connectors swallowed by the slot.
void main() {
  const presets = <Size>[
    Size(393, 852),
    Size(427, 952),
    Size(320, 568),
  ];

  group('trajectory', () {
    for (final preset in presets) {
      test('the latched cartridge never sinks below the console at '
          '${preset.width.toInt()}x${preset.height.toInt()}', () {
        final geometry = AveluneHomeGeometry.resolve(
          viewportSize: preset,
          safeArea: const EdgeInsets.only(top: 24, bottom: 16),
        );
        final height = geometry.heroCartridgeSize.height;
        final latchedBottom =
            geometry.anchors.insertion.latchedCenter.dy + (height / 2);

        expect(
          latchedBottom,
          lessThan(geometry.consoleRect.bottom),
          reason: 'The cartridge reappeared under the console because the '
              'latched centre was pushed below the slot by a third of its '
              'height.',
        );
        expect(
          latchedBottom,
          greaterThan(geometry.consoleSlotRect.center.dy),
          reason: 'It still has to reach into the slot rather than hover.',
        );
        expect(
          latchedBottom - geometry.consoleSlotRect.center.dy,
          lessThan(height * 0.12),
          reason: 'Only the connectors are swallowed; the shell stays proud of '
              'the hardware as the approved reference shows.',
        );
      });
    }

    test('the descent covers real distance', () {
      final geometry = AveluneHomeGeometry.resolve(
        viewportSize: const Size(393, 852),
        safeArea: const EdgeInsets.only(top: 47, bottom: 34),
      );
      final insertion = geometry.anchors.insertion;

      expect(
        insertion.alignedCenter.dy,
        lessThan(insertion.latchedCenter.dy),
        reason: 'Aligning lifts the cartridge, then it descends.',
      );
      expect(
        insertion.latchedCenter.dy - insertion.alignedCenter.dy,
        greaterThan(geometry.heroCartridgeSize.height * 0.35),
        reason: 'A 14 px descent cannot read as a weighted insertion.',
      );
    });
  });

  group('pacing', () {
    test('the sequence gives the console time to run its LEDs', () async {
      final requested = <Duration>[];
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.standard,
        feedback: const AveluneNoopFeedback(),
        delay: (duration) async => requested.add(duration),
      );
      addTearDown(controller.dispose);

      var launched = false;
      await controller.insert(onLaunch: () => launched = true);

      expect(launched, isTrue);
      final total = requested.fold<Duration>(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      expect(
        total,
        greaterThanOrEqualTo(const Duration(milliseconds: 1800)),
        reason: 'The whole insertion used to run in 620 ms, so the amber, green '
            'and violet LED states were never perceivable.',
      );
      expect(
        AveluneMotionTokens.standard.insertionLaunchDelay,
        greaterThanOrEqualTo(const Duration(milliseconds: 500)),
        reason: 'The console has to boot visibly before the game takes over.',
      );
    });

    test('reduced motion still resolves immediately', () async {
      final requested = <Duration>[];
      final controller = AveluneInsertionController(
        motion: AveluneMotionTokens.reduced,
        feedback: const AveluneNoopFeedback(),
        delay: (duration) async => requested.add(duration),
      );
      addTearDown(controller.dispose);

      await controller.insert(onLaunch: () {});

      final total = requested.fold<Duration>(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      expect(total, lessThanOrEqualTo(const Duration(milliseconds: 400)));
    });
  });
}
