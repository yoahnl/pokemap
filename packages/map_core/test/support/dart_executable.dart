import 'dart:io';

/// Binaire Dart capable de lancer un script `tool/` depuis un test.
///
/// `Platform.resolvedExecutable` ne suffit pas : sous `flutter test` il pointe
/// `flutter_tester`, qui ne sait pas faire `dart run`. Les tests CLI du tableau
/// de bord échouaient donc sous ce lanceur alors qu'ils passaient sous
/// `dart test` — six cas au total, tous préexistants à BETA-SYS-008 sauf un.
///
/// Le SDK Dart est livré avec Flutter à un emplacement stable, on le prend là.
String resolveDartExecutable() {
  final resolved = Platform.resolvedExecutable;
  if (resolved.split(Platform.pathSeparator).last.startsWith('dart')) {
    return resolved;
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null && flutterRoot.isNotEmpty) {
    final candidate = File(
      '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
      'cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}'
      'bin${Platform.pathSeparator}dart',
    );
    if (candidate.existsSync()) return candidate.path;
  }
  throw StateError(
    'No Dart executable found to run a tool script. Neither '
    'Platform.resolvedExecutable ($resolved) nor FLUTTER_ROOT provided one.',
  );
}
