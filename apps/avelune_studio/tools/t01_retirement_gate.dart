import 'dart:convert';

import 'package:crypto/crypto.dart';

import 't01_dart_lexing.dart';
import 't01_dependency_graph.dart';

class T01RetirementGate {
  const T01RetirementGate({
    required this.graph,
    required this.inventory,
    required this.allowlist,
  });

  final T01DependencyGraph graph;
  final Map<String, Object?> inventory;
  final Map<String, Object?> allowlist;

  Map<String, Object?> inspect({
    required List<String> roots,
    required Iterable<String> studioSources,
    List<T01ConsumerScope> consumerScopes = const [],
  }) {
    final violations = <Map<String, Object?>>[];
    final exceptions = <String, Set<String>>{};
    final entries = <String, Map<String, Object?>>{};
    void invalid(String kind, String path, String message) => violations.add({
      'kind': kind,
      'path': path,
      'message': message,
      'chain': <String>[],
    });
    try {
      if (inventory['schemaVersion'] != 1 || allowlist['schemaVersion'] != 1) {
        throw const FormatException('Unsupported registry schema');
      }
      for (final value in inventory['entries']! as List<Object?>) {
        final entry = value! as Map<String, Object?>;
        final path = entry['path']! as String;
        if (!_exactPath(path) ||
            entries.containsKey(path) ||
            !{
              'studio_presentation',
              'studio_widgets_outside_presentation',
              'shared_editor_ui',
              'shared_design_system',
            }.contains(entry['category'])) {
          throw FormatException('Invalid or duplicate inventory path: $path');
        }
        entries[path] = entry;
      }
      if (entries.isEmpty) throw const FormatException('Empty inventory');
      if (roots.isEmpty) throw const FormatException('Missing Studio roots');
      for (final value in allowlist['exceptions']! as List<Object?>) {
        final exception = value! as Map<String, Object?>;
        final path = exception['path']! as String;
        try {
          final symbols = (exception['symbols']! as List<Object?>)
              .cast<String>();
          if (!_exactPath(path) ||
              exceptions.containsKey(path) ||
              symbols.isEmpty ||
              symbols.any(
                (s) => !RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(s),
              ) ||
              !{
                'non_visual',
                'neutral_host',
                'player_surface',
                'render_surface',
              }.contains(exception['kind']) ||
              (exception['reason']! as String).trim().isEmpty ||
              (exception['approvedBy']! as String).trim().isEmpty) {
            throw const FormatException(
              'Exact reviewed path and symbols required',
            );
          }
          final uri = graph.repository.resolve(path);
          if (!graph.exists(uri)) {
            throw const FormatException('Exception missing');
          }
          final source = graph.readSource(uri);
          if (sha256.convert(utf8.encode(source)).toString() !=
              exception['sha256']) {
            throw const FormatException('Exception source fingerprint changed');
          }
          final declared = t01Declarations(source);
          if (symbols.any((symbol) => !declared.contains(symbol))) {
            throw const FormatException('Approved symbol missing from source');
          }
          final listed =
              (entries[path]?['widgetClasses'] as List<Object?>? ?? [])
                  .cast<String>()
                  .where(declared.contains);
          if (listed.any((symbol) => !symbols.contains(symbol))) {
            throw const FormatException('Historical symbol lacks approval');
          }
          exceptions[path] = symbols.toSet();
        } catch (error) {
          invalid('exception', path, '$error');
        }
      }
    } catch (error) {
      invalid('registry', '', '$error');
    }
    for (final entry in entries.entries) {
      final studio = {
        'studio_presentation',
        'studio_widgets_outside_presentation',
      }.contains(entry.value['category']);
      if (studio &&
          graph.exists(graph.repository.resolve(entry.key)) &&
          !exceptions.containsKey(entry.key)) {
        invalid('physical', entry.key, 'Historical Studio source still exists');
      }
    }
    final chains = <String, List<String>>{};
    final scopeReports = <Map<String, Object?>>[];
    for (final scope in [
      T01ConsumerScope('studio', graph, roots),
      ...consumerScopes,
    ]) {
      final walked = scope.graph.walk(scope.roots);
      scopeReports.add({
        'name': scope.name,
        'roots': scope.roots,
        'reachableSources': walked.chains.length,
        if (scope.resolverConfig != null)
          'resolverConfig': scope.resolverConfig,
      });
      chains.addAll(walked.chains);
      violations.addAll([
        for (final error in walked.errors) {...error, 'context': scope.name},
      ]);
      for (final entry in walked.chains.entries) {
        final path = entry.key;
        if ((entries.containsKey(path) ||
                path.startsWith('packages/map_editor/lib/src/ui/') ||
                path.startsWith('packages/avelune_design_system/lib/')) &&
            !exceptions.containsKey(path)) {
          violations.add({
            'kind': 'reachability',
            'context': scope.name,
            'path': path,
            'chain': entry.value,
            'message': 'Historical UI source remains reachable from Studio',
          });
        }
      }
    }
    final symbols = <String>{
      for (final entry in entries.values)
        ...((entry['widgetClasses'] as List<Object?>? ?? []).cast<String>()),
    };
    final approvedSymbols = exceptions.values.expand((value) => value).toSet();
    var inspected = 0;
    final sourcesToInspect = {
      ...studioSources,
      ...chains.keys.where(
        (path) => path.startsWith('apps/avelune_studio/lib/presentation/'),
      ),
    };
    for (final path in sourcesToInspect.toList()..sort()) {
      inspected++;
      if (path.startsWith('apps/avelune_studio/lib/presentation/') &&
          !entries.containsKey(path) &&
          !exceptions.containsKey(path)) {
        violations.add({
          'kind': 'unclassified_presentation',
          'path': path,
          'chain': chains[path] ?? <String>[],
          'message': 'Studio presentation source is absent from the reviewed inventory',
        });
      }
      try {
        final source = graph.readSource(graph.repository.resolve(path));
        final identifiers = t01Tokens(source)
            .where((token) => !token.string)
            .map((token) => token.value)
            .toSet();
        final declarations = t01Declarations(source);
        for (final symbol in symbols.intersection(identifiers)) {
          if (exceptions[path]?.contains(symbol) ?? false) continue;
          if (approvedSymbols.contains(symbol) &&
              !declarations.contains(symbol)) {
            continue;
          }
          if (entries.containsKey(path)) continue;
          violations.add({
            'kind': 'historical_symbol',
            'path': path,
            'symbol': symbol,
            'chain': chains[path] ?? <String>[],
            'message': 'Historical symbol remains in a Studio source',
          });
        }
      } catch (error) {
        invalid('source_scan', path, '$error');
      }
    }
    return {
      'schemaVersion': 1,
      'gate': 'G0',
      'proofTier': 'static_retirement',
      'passed': violations.isEmpty,
      'roots': roots,
      'contexts': scopeReports,
      'counts': {
        'inventoryEntries': entries.length,
        'approvedExceptions': exceptions.length,
        'reachableSources': chains.length,
        'studioSourcesInspected': inspected,
        'violations': violations.length,
      },
      'exceptions': [
        for (final exception in allowlist['exceptions'] as List<Object?>? ?? [])
          if (exception is Map<String, Object?> &&
              exceptions.containsKey(exception['path']))
            exception,
      ],
      'violations': violations,
    };
  }

  bool _exactPath(String path) =>
      path.endsWith('.dart') &&
      !path.startsWith('/') &&
      !path.contains(RegExp(r'[*?\\]')) &&
      !path
          .split('/')
          .any((part) => part == '..' || part == '.' || part.isEmpty);
}
