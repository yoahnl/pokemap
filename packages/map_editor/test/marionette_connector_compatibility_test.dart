import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/debug/marionette_connector_compatibility.dart';
import 'package:path/path.dart' as p;

void main() {
  test('accepts matching application and connector versions', () {
    final fixture = _CompatibilityFixture.create(
      flutterVersion: '0.6.0',
      connectorVersion: '0.6.0',
    );
    addTearDown(fixture.dispose);

    final compatibility = MarionetteConnectorCompatibility.read(
      fixture.packageConfigPath,
    );

    expect(compatibility.marionetteFlutterVersion, '0.6.0');
    expect(compatibility.marionetteMcpVersion, '0.6.0');
    expect(compatibility.isCompatible, isTrue);
    expect(compatibility.toJson()['compatible'], isTrue);
  });

  test('rejects a connector whose version differs from the application', () {
    final fixture = _CompatibilityFixture.create(
      flutterVersion: '0.6.0',
      connectorVersion: '0.5.0',
    );
    addTearDown(fixture.dispose);

    expect(
      () => MarionetteConnectorCompatibility.requireCompatible(
        fixture.packageConfigPath,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('marionette_flutter 0.6.0 != marionette_mcp 0.5.0'),
        ),
      ),
    );
  });

  test('fails closed when one package is absent from package_config', () {
    final fixture = _CompatibilityFixture.create(
      flutterVersion: '0.6.0',
      connectorVersion: null,
    );
    addTearDown(fixture.dispose);

    expect(
      () => MarionetteConnectorCompatibility.read(fixture.packageConfigPath),
      throwsStateError,
    );
  });

  test('launches the connector from the current editor package', () {
    const plan = MarionetteConnectorLaunchPlan(
      packageRootPath: '/worktree/packages/map_editor',
    );

    expect(plan.executable, 'flutter');
    expect(plan.arguments, <String>['pub', 'run', 'marionette_mcp']);
    expect(plan.workingDirectory, '/worktree/packages/map_editor');
  });
}

final class _CompatibilityFixture {
  const _CompatibilityFixture({
    required this.root,
    required this.packageConfigPath,
  });

  final Directory root;
  final String packageConfigPath;

  static _CompatibilityFixture create({
    required String flutterVersion,
    required String? connectorVersion,
  }) {
    final root = Directory.systemTemp.createTempSync(
      'pokemap_marionette_compatibility_',
    );
    final dartTool = Directory(p.join(root.path, '.dart_tool'))..createSync();
    final packages = <Map<String, Object?>>[];
    _writePackage(
      root,
      packages,
      name: 'marionette_flutter',
      version: flutterVersion,
    );
    if (connectorVersion != null) {
      _writePackage(
        root,
        packages,
        name: 'marionette_mcp',
        version: connectorVersion,
      );
    }
    final packageConfigPath = p.join(dartTool.path, 'package_config.json');
    File(packageConfigPath).writeAsStringSync(
      jsonEncode(<String, Object?>{'configVersion': 2, 'packages': packages}),
    );
    return _CompatibilityFixture(
      root: root,
      packageConfigPath: packageConfigPath,
    );
  }

  static void _writePackage(
    Directory root,
    List<Map<String, Object?>> packages, {
    required String name,
    required String version,
  }) {
    final directory = Directory(p.join(root.path, 'packages', name))
      ..createSync(recursive: true);
    File(
      p.join(directory.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: $name\nversion: $version\n');
    packages.add(<String, Object?>{
      'name': name,
      'rootUri': directory.uri.toString(),
      'packageUri': 'lib/',
      'languageVersion': '3.6',
    });
  }

  void dispose() => root.deleteSync(recursive: true);
}
