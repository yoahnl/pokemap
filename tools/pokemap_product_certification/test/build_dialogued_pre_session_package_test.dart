import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../bin/build_dialogued_pre_session_package.dart';

/// The sanctioned way to produce the installable BETA-CIN-083 package.
///
/// `bin/build_dialogued_pre_session_package.dart` cannot run under `dart run`:
/// this package depends on Flutter, so the standalone VM cannot compile it and
/// the entrypoint's own usage string already pointed here. The builder lives in
/// the bin and is imported, so there is exactly one authoring path — a second
/// copy here could drift from the one the journey certifies.
///
/// Pass an output path to get a real file:
///
/// ```
/// flutter test test/build_dialogued_pre_session_package_test.dart \
///   --dart-define=POKEMAP_DIALOGUED_OUTPUT=$HOME/Desktop/night-watch.avelunegame
/// ```
///
/// With no output configured it builds into a temporary directory and still
/// asserts the package is certified, so CI exercises the builder without
/// leaving an artifact behind.
void main() {
  const configuredOutput = String.fromEnvironment(
    'POKEMAP_DIALOGUED_OUTPUT',
  );

  test('builds the installable dialogued pre-session package', () async {
    final temporaryRoot = configuredOutput.isEmpty
        ? await Directory.systemTemp.createTemp('pokemap-dialogued-artifact-')
        : null;
    addTearDown(() async {
      if (temporaryRoot != null && await temporaryRoot.exists()) {
        await temporaryRoot.delete(recursive: true);
      }
    });
    final output = File(
      configuredOutput.isEmpty
          ? '${temporaryRoot!.path}/night-watch.avelunegame'
          : configuredOutput,
    ).absolute;
    await output.parent.create(recursive: true);

    final artifact = await buildDialoguedPreSessionPackage(outputFile: output);

    expect(await output.exists(), isTrue);
    expect(
      artifact.certification.isCertified,
      isTrue,
      reason: 'an uncertified package is not installable, so handing one over '
          'would waste a recette rather than inform it',
    );
    expect(artifact.packageSha256, matches(RegExp(r'^[0-9a-f]{64}$')));
    // The declared locales must match the authored content: a package that
    // claims English support renders English chrome around French prompts on an
    // English device, which is exactly what the first recette surfaced.
    expect(artifact.manifest.locales.defaultLocale, 'fr');
    expect(artifact.manifest.locales.supported, <String>['fr']);

    stdout
      ..writeln('output=${output.path}')
      ..writeln('treeSha256=${artifact.manifest.content.treeSha256}')
      ..writeln('packageSha256=${artifact.packageSha256}');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
