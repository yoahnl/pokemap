import 't01_dart_lexing.dart';

class T01GraphResult {
  final chains = <String, List<String>>{};
  final errors = <Map<String, Object?>>[];
}

class T01ConsumerScope {
  const T01ConsumerScope(
    this.name,
    this.graph,
    this.roots, {
    this.resolverConfig,
  });

  final String name;
  final T01DependencyGraph graph;
  final List<String> roots;
  final String? resolverConfig;
}

class T01DependencyGraph {
  const T01DependencyGraph({
    required this.repository,
    required this.packageRoots,
    required this.readSource,
    required this.exists,
  });

  factory T01DependencyGraph.fromConfig({
    required Uri repository,
    required Uri configUri,
    required Map<String, Object?> config,
    required String Function(Uri) readSource,
    required bool Function(Uri) exists,
  }) {
    final roots = <String, Uri>{};
    for (final value in config['packages']! as List<Object?>) {
      final package = value! as Map<String, Object?>;
      final resolved = configUri.resolve(package['rootUri']! as String);
      final root = resolved.path.endsWith('/')
          ? resolved
          : resolved.replace(path: '${resolved.path}/');
      roots[package['name']! as String] = root.resolve(
        package['packageUri']! as String,
      );
    }
    return T01DependencyGraph(
      repository: repository,
      packageRoots: roots,
      readSource: readSource,
      exists: exists,
    );
  }

  final Uri repository;
  final Map<String, Uri> packageRoots;
  final String Function(Uri) readSource;
  final bool Function(Uri) exists;

  String relative(Uri uri) => uri.toString().startsWith(repository.toString())
      ? Uri.decodeComponent(
          uri.toString().substring(repository.toString().length),
        )
      : uri.toString();

  Uri _packageReference(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty || !packageRoots.containsKey(segments.first)) {
      throw StateError('Unknown package: $uri');
    }
    final inside = Uri(path: '/')
        .resolveUri(Uri(path: segments.skip(1).join('/')));
    return Uri(
      scheme: 'package',
      path: '${segments.first}${inside.path}',
      query: uri.hasQuery ? uri.query : null,
      fragment: uri.hasFragment ? uri.fragment : null,
    );
  }

  Uri _physical(Uri uri) {
    if (uri.scheme != 'package') return uri;
    final normalized = _packageReference(uri);
    return packageRoots[normalized.pathSegments.first]!.resolveUri(
      Uri(path: normalized.pathSegments.skip(1).join('/')),
    );
  }

  Uri resolve(Uri source, String specifier) {
    final uri = Uri.parse(specifier);
    if (uri.scheme == 'dart' || uri.scheme == 'file') return uri;
    if (uri.scheme == 'package') return _packageReference(uri);
    if (uri.hasScheme) throw StateError('Unsupported URI: $specifier');
    if (source.scheme == 'package') {
      final normalized = _packageReference(source);
      final inside = Uri(path: '/${normalized.pathSegments.skip(1).join('/')}')
          .resolveUri(uri);
      return Uri(
        scheme: 'package',
        path: '${normalized.pathSegments.first}${inside.path}',
        query: inside.hasQuery ? inside.query : null,
        fragment: inside.hasFragment ? inside.fragment : null,
      );
    }
    return source.resolveUri(uri);
  }

  T01GraphResult walk(Iterable<String> roots) {
    final result = T01GraphResult();
    final visited = <Uri>{};
    final pending = [
      for (final root in roots)
        (source: repository.resolve(root), chain: <String>[root]),
    ];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current.source)) continue;
      final chain = current.chain;
      var path = chain.last;
      try {
        final uri = _physical(current.source);
        path = relative(uri);
        result.chains.putIfAbsent(path, () => chain);
        if (!exists(uri)) throw StateError('Missing source: $path');
        for (final specifier in t01Directives(readSource(uri))) {
          try {
            final target = resolve(current.source, specifier);
            if (target.scheme == 'dart') continue;
            final physical = _physical(target);
            if (!exists(physical)) {
              throw StateError('Missing source: $physical');
            }
            if (!physical.toString().startsWith(repository.toString())) {
              continue;
            }
            pending.add((
              source: target,
              chain: [...chain, relative(physical)],
            ));
          } catch (error) {
            result.errors.add({
              'kind': 'resolution',
              'path': path,
              'sourceUri': current.source.toString(),
              'chain': chain,
              'specifier': specifier,
              'message': '$error',
            });
          }
        }
      } catch (error) {
        result.errors.add({
          'kind': 'resolution',
          'path': path,
          'sourceUri': current.source.toString(),
          'chain': chain,
          'message': '$error',
        });
      }
    }
    return result;
  }
}
