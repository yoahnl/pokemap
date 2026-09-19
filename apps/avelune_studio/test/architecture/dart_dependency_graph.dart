class DartDependency {
  const DartDependency(this.source, this.specifier, this.target, this.chain);

  final Uri source;
  final String specifier;
  final Uri target;
  final List<Uri> chain;

  String get packageName => specifier.startsWith('package:')
      ? Uri.parse(specifier).pathSegments.first
      : '';

  @override
  String toString() => '${chain.join(' -> ')} -> $specifier';
}

class DartDependencyGraph {
  DartDependencyGraph({required this.readSource, required this.packageRoots});

  factory DartDependencyGraph.fromPackageConfig({
    required Map<String, Object?> config,
    required Uri configUri,
    required String Function(Uri) readSource,
  }) {
    final roots = <String, Uri>{};
    for (final item in config['packages']! as List<Object?>) {
      final package = item! as Map<String, Object?>;
      final root = configUri.resolve(package['rootUri']! as String);
      final directory = root.path.endsWith('/')
          ? root
          : root.replace(path: '${root.path}/');
      roots[package['name']! as String] = directory.resolve(
        package['packageUri']! as String,
      );
    }
    return DartDependencyGraph(readSource: readSource, packageRoots: roots);
  }

  final String Function(Uri) readSource;
  final Map<String, Uri> packageRoots;

  static final _directives = RegExp(
    r'^\s*(?:import|export|part(?!\s+of))\s+([^;]+);',
    multiLine: true,
  );
  static final _strings = RegExp("['\"]([^'\"]+)['\"]");

  Iterable<String> specifiers(Uri source) sync* {
    for (final directive in _directives.allMatches(readSource(source))) {
      for (final value in _strings.allMatches(directive.group(1)!)) {
        yield value.group(1)!;
      }
    }
  }

  Uri resolve(Uri source, String specifier) {
    final uri = Uri.parse(specifier);
    if (uri.scheme != 'package') return source.resolveUri(uri);
    final name = uri.pathSegments.first;
    final root = packageRoots[name];
    if (root == null) throw StateError('Package introuvable : $name');
    return root.resolve(uri.pathSegments.skip(1).join('/'));
  }

  Iterable<DartDependency> walk(
    Iterable<Uri> entries, {
    required bool Function(DartDependency) stopAt,
  }) sync* {
    final visited = <Uri>{};
    final pending = [
      for (final entry in entries) [entry],
    ];
    while (pending.isNotEmpty) {
      final chain = pending.removeLast();
      final source = chain.last;
      if (!visited.add(source)) continue;
      for (final specifier in specifiers(source)) {
        final target = resolve(source, specifier);
        final edge = DartDependency(source, specifier, target, chain);
        yield edge;
        if (target.scheme != 'dart' && !stopAt(edge)) {
          pending.add([...chain, target]);
        }
      }
    }
  }
}
