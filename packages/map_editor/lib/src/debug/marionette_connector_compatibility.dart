import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

final class MarionetteConnectorCompatibility {
  const MarionetteConnectorCompatibility({
    required this.marionetteFlutterVersion,
    required this.marionetteMcpVersion,
  });

  final String marionetteFlutterVersion;
  final String marionetteMcpVersion;

  bool get isCompatible => marionetteFlutterVersion == marionetteMcpVersion;

  static MarionetteConnectorCompatibility read(String packageConfigPath) {
    final file = File(p.normalize(p.absolute(packageConfigPath)));
    if (!file.existsSync()) {
      throw StateError('Package config does not exist: ${file.path}');
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic> || decoded['packages'] is! List) {
      throw const FormatException('Invalid package_config.json.');
    }
    final packages = (decoded['packages'] as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return MarionetteConnectorCompatibility(
      marionetteFlutterVersion: _packageVersion(
        file,
        packages,
        'marionette_flutter',
      ),
      marionetteMcpVersion: _packageVersion(file, packages, 'marionette_mcp'),
    );
  }

  static MarionetteConnectorCompatibility requireCompatible(
    String packageConfigPath,
  ) {
    final compatibility = read(packageConfigPath);
    if (!compatibility.isCompatible) {
      throw StateError(
        'Marionette protocol mismatch: marionette_flutter '
        '${compatibility.marionetteFlutterVersion} != marionette_mcp '
        '${compatibility.marionetteMcpVersion}.',
      );
    }
    return compatibility;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'marionetteFlutterVersion': marionetteFlutterVersion,
    'marionetteMcpVersion': marionetteMcpVersion,
    'compatible': isCompatible,
  };

  static String _packageVersion(
    File packageConfig,
    List<Map<String, dynamic>> packages,
    String packageName,
  ) {
    final package = packages.where((entry) => entry['name'] == packageName);
    if (package.length != 1) {
      throw StateError(
        'Expected exactly one $packageName entry in package_config.json.',
      );
    }
    final rootUriValue = package.single['rootUri'];
    if (rootUriValue is! String) {
      throw StateError('$packageName rootUri is missing.');
    }
    final rootUri = packageConfig.uri.resolve(rootUriValue);
    final packageRoot = File.fromUri(rootUri).path;
    final pubspec = File(p.join(packageRoot, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError('$packageName pubspec does not exist: ${pubspec.path}');
    }
    final match = RegExp(
      r'^version:\s*([^\s#]+)',
      multiLine: true,
    ).firstMatch(pubspec.readAsStringSync());
    if (match == null) {
      throw StateError('$packageName pubspec has no version.');
    }
    return match.group(1)!;
  }
}

final class MarionetteConnectorLaunchPlan {
  const MarionetteConnectorLaunchPlan({required this.packageRootPath});

  final String packageRootPath;

  String get executable => 'flutter';

  List<String> get arguments => const <String>['pub', 'run', 'marionette_mcp'];

  String get workingDirectory => p.normalize(p.absolute(packageRootPath));
}
