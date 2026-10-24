import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter/converter_build_identity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release flags reach the running build identity', () {
    expect(
      ConverterBuildIdentity.current.version,
      const String.fromEnvironment('TEST_RELEASE_VERSION'),
    );
    expect(
      ConverterBuildIdentity.current.buildNumber,
      const String.fromEnvironment('TEST_RELEASE_BUILD_NUMBER'),
    );
    expect(
      ConverterBuildIdentity.current.revision,
      const String.fromEnvironment('TEST_RELEASE_REVISION'),
    );
  }, skip: !const bool.hasEnvironment('TEST_RELEASE_VERSION'));

  test('build identity retains an exact Git revision and build version', () {
    final identity = ConverterBuildIdentity(
      version: '0.1.1',
      buildNumber: '23',
      revision: 'A' * 40,
    );

    expect(identity.revision, 'a' * 40);
    expect(identity.label, 'Version 0.1.1+23\nRévision aaaaaaaaa');
  });

  for (final revision in [
    '',
    '32c0416d7',
    'main',
    'g' * 40,
    '0' * 41,
    ' ${'a' * 40}',
    '${'a' * 40}\n',
  ]) {
    test(
      'build identity uses a local fallback for invalid revision $revision',
      () {
        final identity = ConverterBuildIdentity(revision: revision);

        expect(identity.revision, isNull);
        expect(identity.label, 'Version 0.1.0+1\nCompilation locale');
      },
    );
  }

  testWidgets('sidebar displays the running build identity', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ConverterApp());

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('navigation-scroll')),
        matching: find.text(ConverterBuildIdentity.current.label),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
