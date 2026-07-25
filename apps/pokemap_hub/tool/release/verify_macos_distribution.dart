import 'dart:convert';
import 'dart:io';

const _expectedBundleId = 'app.pokemap.hub';
const _requiredSigningAuthority = 'Developer ID Application';

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final receipt = await _readReceipt(options.receipt);
    final mounted = await _MountedDmg.mount(options.dmg);
    try {
      final app = mounted.app;
      final bundleVersion =
          await _bundleValue(app, 'CFBundleShortVersionString');
      final bundleBuild = await _bundleValue(app, 'CFBundleVersion');
      final architectures = await _architectures(app);
      final checks = <String, bool>{
        'dmgIntegrity': await _succeeds(
          '/usr/bin/hdiutil',
          <String>['verify', options.dmg.path],
        ),
        'bundleIdentifier':
            await _bundleValue(app, 'CFBundleIdentifier') == _expectedBundleId,
        'bundleVersion': bundleVersion == receipt.appVersion &&
            bundleBuild == receipt.buildNumber,
        'architectures': architectures.toSet().containsAll(
                  receipt.architectures,
                ) &&
            receipt.architectures.toSet().containsAll(architectures),
        'codesign': await _succeeds(
          '/usr/bin/codesign',
          <String>[
            '--verify',
            '--deep',
            '--strict',
            '--verbose=4',
            app.path,
          ],
        ),
        'developerId': await _hasDeveloperIdSignature(app),
        'hardenedRuntime': await _hasHardenedRuntime(app),
        'releaseEntitlements': await _hasReleaseEntitlements(app),
        'notarytool': await _notarizationAccepted(
          submissionId: receipt.notarySubmissionId,
          keychainProfile: options.notaryProfile,
        ),
        'stapler': await _succeeds(
          '/usr/bin/xcrun',
          <String>['stapler', 'validate', options.dmg.path],
        ),
        'spctl': await _succeeds(
          '/usr/sbin/spctl',
          <String>[
            '--assess',
            '--type',
            'execute',
            '--verbose=4',
            app.path,
          ],
        ),
        'dmgSha256': await _sha256(options.dmg) == receipt.artifactSha256,
        'dmgBytes': await options.dmg.length() == receipt.artifactBytes,
        'neutralPackageSha256': await _sha256(options.neutralPackage) ==
            receipt.neutralPackageSha256,
        'receipt': receipt.isColdInstallProof,
      };
      final passed = checks.values.every((value) => value);
      stdout.writeln(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'bundleId': _expectedBundleId,
          'passed': passed,
          'checks': checks,
        }),
      );
      if (!passed) exitCode = 1;
    } finally {
      await mounted.dispose();
    }
  } on Object catch (error) {
    stderr.writeln(
      jsonEncode(<String, Object?>{
        'schemaVersion': 1,
        'passed': false,
        'error': error.runtimeType.toString(),
      }),
    );
    exitCode = 64;
  }
}

final class _Options {
  const _Options({
    required this.dmg,
    required this.neutralPackage,
    required this.receipt,
    required this.notaryProfile,
  });

  factory _Options.parse(List<String> arguments) {
    String value(String flag) {
      final index = arguments.indexOf(flag);
      if (index < 0 || index + 1 >= arguments.length) {
        throw FormatException('Missing required option $flag.');
      }
      return arguments[index + 1];
    }

    final dmg = File(value('--dmg'));
    final neutralPackage = File(value('--neutral-package'));
    final receipt = File(value('--receipt'));
    final profile = value('--notary-profile').trim();
    if (!dmg.existsSync() ||
        !neutralPackage.existsSync() ||
        !receipt.existsSync() ||
        profile.isEmpty) {
      throw const FormatException('Release gate inputs are unavailable.');
    }
    return _Options(
      dmg: dmg,
      neutralPackage: neutralPackage,
      receipt: receipt,
      notaryProfile: profile,
    );
  }

  final File dmg;
  final File neutralPackage;
  final File receipt;
  final String notaryProfile;
}

final class _MountedDmg {
  const _MountedDmg({
    required this.mountPoint,
    required this.app,
  });

  static Future<_MountedDmg> mount(File dmg) async {
    final mountPoint =
        await Directory.systemTemp.createTemp('pokemap-release-dmg-');
    final result = await Process.run(
      '/usr/bin/hdiutil',
      <String>[
        'attach',
        '-nobrowse',
        '-readonly',
        '-mountpoint',
        mountPoint.path,
        dmg.path,
      ],
    );
    if (result.exitCode != 0) {
      await mountPoint.delete(recursive: true);
      throw const FileSystemException('Release DMG cannot be mounted.');
    }
    final app = Directory('${mountPoint.path}/PokeMap Hub.app');
    if (!app.existsSync()) {
      await _detach(mountPoint);
      throw const FileSystemException(
        'Release DMG does not contain PokeMap Hub.app.',
      );
    }
    return _MountedDmg(mountPoint: mountPoint, app: app);
  }

  final Directory mountPoint;
  final Directory app;

  Future<void> dispose() => _detach(mountPoint);
}

Future<void> _detach(Directory mountPoint) async {
  try {
    await Process.run(
      '/usr/bin/hdiutil',
      <String>['detach', mountPoint.path],
    );
  } finally {
    if (mountPoint.existsSync()) {
      await mountPoint.delete(recursive: true);
    }
  }
}

final class _Receipt {
  const _Receipt({
    required this.appVersion,
    required this.buildNumber,
    required this.artifactSha256,
    required this.artifactBytes,
    required this.architectures,
    required this.notarySubmissionId,
    required this.neutralPackageSha256,
    required this.createdAt,
    required this.repositoryAbsent,
    required this.networkDisabled,
    required this.signedWithDeveloperId,
    required this.hardenedRuntime,
    required this.notarized,
    required this.stapled,
    required this.gatekeeperAccepted,
    required this.coldInstalled,
    required this.relaunched,
  });

  final String appVersion;
  final String buildNumber;
  final String artifactSha256;
  final int artifactBytes;
  final List<String> architectures;
  final String notarySubmissionId;
  final String neutralPackageSha256;
  final DateTime createdAt;
  final bool repositoryAbsent;
  final bool networkDisabled;
  final bool signedWithDeveloperId;
  final bool hardenedRuntime;
  final bool notarized;
  final bool stapled;
  final bool gatekeeperAccepted;
  final bool coldInstalled;
  final bool relaunched;

  bool get isColdInstallProof =>
      repositoryAbsent &&
      networkDisabled &&
      signedWithDeveloperId &&
      hardenedRuntime &&
      notarized &&
      stapled &&
      gatekeeperAccepted &&
      coldInstalled &&
      relaunched;
}

Future<_Receipt> _readReceipt(File file) async {
  final decoded = jsonDecode(await file.readAsString());
  const expectedKeys = <String>{
    'schemaVersion',
    'bundleId',
    'appVersion',
    'buildNumber',
    'artifactSha256',
    'artifactBytes',
    'architectures',
    'notarySubmissionId',
    'neutralPackageSha256',
    'repositoryAbsent',
    'networkDisabled',
    'signedWithDeveloperId',
    'hardenedRuntime',
    'notarized',
    'stapled',
    'gatekeeperAccepted',
    'coldInstalled',
    'relaunched',
    'createdAt',
  };
  if (decoded is! Map<String, dynamic> ||
      decoded['schemaVersion'] != 1 ||
      decoded['bundleId'] != _expectedBundleId ||
      decoded.keys.toSet().difference(expectedKeys).isNotEmpty ||
      expectedKeys.difference(decoded.keys.toSet()).isNotEmpty) {
    throw const FormatException('Certification receipt is invalid.');
  }
  String string(String key) {
    final value = decoded[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Receipt field $key is invalid.');
    }
    return value;
  }

  bool boolean(String key) {
    final value = decoded[key];
    if (value is! bool) {
      throw FormatException('Receipt field $key is invalid.');
    }
    return value;
  }

  int integer(String key) {
    final value = decoded[key];
    if (value is! int || value < 1) {
      throw FormatException('Receipt field $key is invalid.');
    }
    return value;
  }

  final rawArchitectures = decoded['architectures'];
  if (rawArchitectures is! List ||
      rawArchitectures.isEmpty ||
      rawArchitectures.any(
        (value) => value != 'arm64' && value != 'x86_64',
      )) {
    throw const FormatException('Receipt architectures are invalid.');
  }
  final architectures = rawArchitectures.cast<String>().toSet().toList()
    ..sort();
  if (architectures.length != rawArchitectures.length) {
    throw const FormatException('Receipt architectures are duplicated.');
  }

  final digest = string('artifactSha256');
  final neutralPackageSha256 = string('neutralPackageSha256');
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest) ||
      !RegExp(r'^[0-9a-f]{64}$').hasMatch(neutralPackageSha256)) {
    throw const FormatException('Artifact digest is invalid.');
  }
  final createdAtSource = string('createdAt');
  final createdAt = DateTime.parse(createdAtSource);
  if (!createdAt.isUtc || !createdAtSource.endsWith('Z')) {
    throw const FormatException('Receipt timestamp must be UTC.');
  }
  return _Receipt(
    appVersion: string('appVersion'),
    buildNumber: string('buildNumber'),
    artifactSha256: digest,
    artifactBytes: integer('artifactBytes'),
    architectures: List<String>.unmodifiable(architectures),
    notarySubmissionId: string('notarySubmissionId'),
    neutralPackageSha256: neutralPackageSha256,
    createdAt: createdAt,
    repositoryAbsent: boolean('repositoryAbsent'),
    networkDisabled: boolean('networkDisabled'),
    signedWithDeveloperId: boolean('signedWithDeveloperId'),
    hardenedRuntime: boolean('hardenedRuntime'),
    notarized: boolean('notarized'),
    stapled: boolean('stapled'),
    gatekeeperAccepted: boolean('gatekeeperAccepted'),
    coldInstalled: boolean('coldInstalled'),
    relaunched: boolean('relaunched'),
  );
}

Future<String> _bundleValue(Directory app, String key) async {
  final result = await Process.run(
    '/usr/bin/plutil',
    <String>[
      '-extract',
      key,
      'raw',
      '-o',
      '-',
      '${app.path}/Contents/Info.plist',
    ],
  );
  if (result.exitCode != 0) return '';
  return (result.stdout as String).trim();
}

Future<List<String>> _architectures(Directory app) async {
  final executable = File(
    '${app.path}/Contents/MacOS/PokeMap Hub',
  );
  final result = await Process.run(
    '/usr/bin/lipo',
    <String>['-archs', executable.path],
  );
  if (result.exitCode != 0) return const <String>[];
  final values = (result.stdout as String)
      .trim()
      .split(RegExp(r'\s+'))
      .where((value) => value.isNotEmpty)
      .toList(growable: false)
    ..sort();
  return values;
}

Future<bool> _hasDeveloperIdSignature(Directory app) async {
  final result = await Process.run(
    '/usr/bin/codesign',
    <String>['-dv', '--verbose=4', app.path],
  );
  final output = '${result.stdout}\n${result.stderr}';
  return result.exitCode == 0 &&
      output.contains('Authority=$_requiredSigningAuthority');
}

Future<bool> _hasHardenedRuntime(Directory app) async {
  final result = await Process.run(
    '/usr/bin/codesign',
    <String>['-dv', '--verbose=4', app.path],
  );
  final output = '${result.stdout}\n${result.stderr}'.toLowerCase();
  return result.exitCode == 0 && output.contains('runtime');
}

Future<bool> _hasReleaseEntitlements(Directory app) async {
  final result = await Process.run(
    '/usr/bin/codesign',
    <String>['-d', '--entitlements', ':-', app.path],
  );
  final output = '${result.stdout}\n${result.stderr}';
  bool enabled(String entitlement) => RegExp(
        '<key>\\s*${RegExp.escape(entitlement)}\\s*</key>\\s*<true\\s*/>',
      ).hasMatch(output);
  return result.exitCode == 0 &&
      enabled('com.apple.security.app-sandbox') &&
      enabled('com.apple.security.files.user-selected.read-only') &&
      !output.contains('com.apple.security.get-task-allow') &&
      !output.contains('com.apple.security.cs.allow-jit') &&
      !output.contains('com.apple.security.cs.disable-library-validation') &&
      !output.contains('com.apple.security.network.client') &&
      !output.contains('com.apple.security.network.server');
}

Future<bool> _notarizationAccepted({
  required String submissionId,
  required String keychainProfile,
}) async {
  final result = await Process.run(
    '/usr/bin/xcrun',
    <String>[
      'notarytool',
      'info',
      submissionId,
      '--keychain-profile',
      keychainProfile,
      '--output-format',
      'json',
    ],
  );
  if (result.exitCode != 0) return false;
  final decoded = jsonDecode(result.stdout as String);
  return decoded is Map<String, dynamic> && decoded['status'] == 'Accepted';
}

Future<String> _sha256(File file) async {
  final result = await Process.run(
    '/usr/bin/shasum',
    <String>['-a', '256', file.path],
  );
  if (result.exitCode != 0) return '';
  return (result.stdout as String).trim().split(RegExp(r'\s+')).first;
}

Future<bool> _succeeds(String executable, List<String> arguments) async =>
    (await Process.run(executable, arguments)).exitCode == 0;
