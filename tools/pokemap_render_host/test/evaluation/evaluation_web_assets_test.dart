import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('cockpit shell exposes the approved three-column landmarks', () {
    final html = _asset('index.html');

    expect(html, contains('<nav'));
    expect(html, contains('<main'));
    expect(html, contains('<aside'));
    expect(html, contains('aria-label="Scénarios"'));
    expect(html, contains('aria-label="Inspecteur de l’étape"'));
    expect(html, contains('id="run-timeline"'));
    expect(html, contains('id="inspector-tabs"'));
    expect(html, contains('__POKEMAP_EVAL_TOKEN__'));
  });

  test('styles use semantic tokens instead of feature color literals', () {
    final css = _asset('app.css');

    expect(css, contains('--color-success:'));
    expect(css, contains('--color-warning:'));
    expect(css, contains('--color-failure:'));
    expect(css, contains('--surface-workspace:'));
    expect(
      _featureRuleColorLiterals(css),
      isEmpty,
      reason: 'Raw colors belong only in the :root token block.',
    );
  });

  test('layout preserves focus and collapses the inspector responsively', () {
    final css = _asset('app.css');

    expect(css, contains(':focus-visible'));
    expect(css, contains('@media (max-width: 1050px)'));
    expect(css, contains('grid-template-areas:'));
    expect(css, contains('.workspace-inspector'));
  });
}

String _asset(String name) {
  return File(
    p.join(
      Directory.current.path,
      'tool',
      'assets',
      'pokemap_eval_web',
      name,
    ),
  ).readAsStringSync();
}

List<String> _featureRuleColorLiterals(String css) {
  final withoutRoot = css.replaceFirst(
    RegExp(r':root\s*\{.*?\}', dotAll: true),
    '',
  );
  final color = RegExp(
    r'#[0-9a-fA-F]{3,8}\b|rgba?\s*\(|hsla?\s*\(',
  );
  return withoutRoot
      .split('\n')
      .where((line) => color.hasMatch(line))
      .map((line) => line.trim())
      .toList(growable: false);
}
