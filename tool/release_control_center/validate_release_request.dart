import 'dart:io';

Future<void> main(List<String> arguments) async {
  exitCode = await validateReleaseRequest(arguments);
}

Future<int> validateReleaseRequest(
  List<String> arguments, {
  IOSink? output,
  IOSink? errorOutput,
}) async {
  final stdoutSink = output ?? stdout;
  final stderrSink = errorOutput ?? stderr;
  final product = _readOption(arguments, '--product');
  final action = _readOption(arguments, '--action');
  final ref = _readOption(arguments, '--ref');
  final pokeMapPubspecPath = _readOption(arguments, '--pokemap-pubspec');
  final avelunePubspecPath = _readOption(arguments, '--avelune-pubspec');
  final pokeMapVersionInput = _readOption(arguments, '--pokemap-version');
  final aveluneVersionInput = _readOption(arguments, '--avelune-version');
  final confirmation = _readOption(arguments, '--confirmation');
  final githubOutputPath = _readOption(arguments, '--github-output');

  if (product == null ||
      action == null ||
      ref == null ||
      pokeMapPubspecPath == null ||
      avelunePubspecPath == null) {
    stderrSink.writeln(
      'Usage: validate_release_request.dart '
      '--product pokemap|avelune|both '
      '--action preflight|publish '
      '--ref refs/heads/main '
      '--pokemap-pubspec path '
      '--avelune-pubspec path '
      '[--pokemap-version X.Y.Z] '
      '[--avelune-version X.Y.Z] '
      '[--confirmation RELEASE] '
      '[--github-output path]',
    );
    return 64;
  }

  if (!const {'pokemap', 'avelune', 'both'}.contains(product)) {
    stderrSink.writeln('--product must be pokemap, avelune, or both.');
    return 64;
  }
  if (!const {'preflight', 'publish'}.contains(action)) {
    stderrSink.writeln('--action must be preflight or publish.');
    return 64;
  }

  final pokeMapSelected = product == 'pokemap' || product == 'both';
  final aveluneSelected = product == 'avelune' || product == 'both';

  if (!pokeMapSelected && _hasValue(pokeMapVersionInput)) {
    stderrSink.writeln(
      'Do not provide a PokeMap version when PokeMap is not selected.',
    );
    return 65;
  }
  if (!aveluneSelected && _hasValue(aveluneVersionInput)) {
    stderrSink.writeln(
      'Do not provide an Avelune version when Avelune is not selected.',
    );
    return 65;
  }

  if (action == 'publish') {
    if (confirmation != 'RELEASE') {
      stderrSink.writeln('Type RELEASE to confirm publication.');
      return 65;
    }
    if (ref != 'refs/heads/main') {
      stderrSink.writeln(
        'Publications must be dispatched from refs/heads/main.',
      );
      return 65;
    }
  }

  var pokeMapVersion = '';
  if (pokeMapSelected) {
    final selectedVersion = await _readPubspecVersion(
      path: pokeMapPubspecPath,
      productName: 'PokeMap',
      errorOutput: stderrSink,
    );
    if (selectedVersion == null) {
      return 66;
    }
    pokeMapVersion = selectedVersion;
  }
  var aveluneVersion = '';
  if (aveluneSelected) {
    final selectedVersion = await _readPubspecVersion(
      path: avelunePubspecPath,
      productName: 'Avelune',
      errorOutput: stderrSink,
    );
    if (selectedVersion == null) {
      return 66;
    }
    aveluneVersion = selectedVersion;
  }

  final versionError =
      _validateSelectedVersion(
        selected: pokeMapSelected,
        action: action,
        productName: 'PokeMap',
        requestedVersion: pokeMapVersionInput,
        pubspecVersion: pokeMapVersion,
      ) ??
      _validateSelectedVersion(
        selected: aveluneSelected,
        action: action,
        productName: 'Avelune',
        requestedVersion: aveluneVersionInput,
        pubspecVersion: aveluneVersion,
      );
  if (versionError != null) {
    stderrSink.writeln(versionError);
    return 65;
  }

  final outputs = <String>[
    'product=$product',
    'action=$action',
    'pokemap_selected=$pokeMapSelected',
    'avelune_selected=$aveluneSelected',
    'pokemap_version=$pokeMapVersion',
    'avelune_version=$aveluneVersion',
    'pokemap_tag=${pokeMapSelected ? 'pokemap-v$pokeMapVersion' : ''}',
    'avelune_tag=${aveluneSelected ? 'avelune-v$aveluneVersion' : ''}',
  ];
  if (githubOutputPath != null) {
    try {
      await File(githubOutputPath).writeAsString(
        '${outputs.join('\n')}\n',
        mode: FileMode.append,
        flush: true,
      );
    } on FileSystemException catch (error) {
      stderrSink.writeln('Unable to write GitHub outputs: ${error.message}');
      return 73;
    }
  }

  stdoutSink.writeln('Validated ${_productLabel(product)} $action request.');
  return 0;
}

Future<String?> _readPubspecVersion({
  required String path,
  required String productName,
  required IOSink errorOutput,
}) async {
  final pubspec = File(path);
  if (!await pubspec.exists()) {
    errorOutput.writeln('$productName pubspec not found: $path');
    return null;
  }
  final contents = await pubspec.readAsString();
  final match = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$',
    multiLine: true,
  ).firstMatch(contents);
  if (match == null) {
    errorOutput.writeln('$productName pubspec version must match X.Y.Z+BUILD.');
    return null;
  }
  return match.group(1);
}

String? _validateSelectedVersion({
  required bool selected,
  required String action,
  required String productName,
  required String? requestedVersion,
  required String pubspecVersion,
}) {
  if (!selected) {
    return null;
  }
  if (action == 'publish' && !_hasValue(requestedVersion)) {
    return '$productName version is required for publication.';
  }
  if (_hasValue(requestedVersion) && requestedVersion != pubspecVersion) {
    return '$productName version $requestedVersion does not match '
        'pubspec version $pubspecVersion.';
  }
  return null;
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

String _productLabel(String product) => switch (product) {
  'pokemap' => 'PokeMap',
  'avelune' => 'Avelune',
  'both' => 'PokeMap + Avelune',
  _ => product,
};

String? _readOption(List<String> arguments, String option) {
  final index = arguments.indexOf(option);
  if (index == -1 || index + 1 >= arguments.length) {
    return null;
  }
  return arguments[index + 1];
}
