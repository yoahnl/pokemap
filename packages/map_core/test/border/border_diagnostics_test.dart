import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Border diagnostic enums', () {
    test('freeze the complete V1 sets and their explicit stable ranks', () {
      expect(BorderDiagnosticSeverity.values, <BorderDiagnosticSeverity>[
        BorderDiagnosticSeverity.error,
        BorderDiagnosticSeverity.warning,
        BorderDiagnosticSeverity.info,
      ]);
      expect(BorderDiagnosticPhase.values, <BorderDiagnosticPhase>[
        BorderDiagnosticPhase.authoring,
        BorderDiagnosticPhase.publication,
        BorderDiagnosticPhase.resolution,
        BorderDiagnosticPhase.materialization,
        BorderDiagnosticPhase.freshness,
        BorderDiagnosticPhase.resize,
        BorderDiagnosticPhase.projectValidation,
        BorderDiagnosticPhase.playExport,
      ]);
      expect(BorderDiagnosticScope.values, <BorderDiagnosticScope>[
        BorderDiagnosticScope.project,
        BorderDiagnosticScope.catalog,
        BorderDiagnosticScope.blueprint,
        BorderDiagnosticScope.primitive,
        BorderDiagnosticScope.visualSnapshot,
        BorderDiagnosticScope.feature,
        BorderDiagnosticScope.geometry,
        BorderDiagnosticScope.groundCell,
        BorderDiagnosticScope.stroke,
        BorderDiagnosticScope.segment,
        BorderDiagnosticScope.slot,
        BorderDiagnosticScope.placement,
        BorderDiagnosticScope.materialization,
      ]);

      expect(
        BorderDiagnosticSeverity.values.map(borderDiagnosticSeverityV1Rank),
        <int>[0, 1, 2],
      );
      expect(
        BorderDiagnosticPhase.values.map(borderDiagnosticPhaseV1Rank),
        List<int>.generate(8, (index) => index),
      );
      expect(
        BorderDiagnosticScope.values.map(borderDiagnosticScopeV1Rank),
        List<int>.generate(13, (index) => index),
      );
    });
  });

  group('BorderDiagnostic', () {
    test('owns every approved field and copies its diagnostic cell', () {
      const originalCell = GridPos(x: -50, y: 900);
      final diagnostic = _diagnostic(
        code: 'border.feature.gap',
        severity: BorderDiagnosticSeverity.warning,
        phase: BorderDiagnosticPhase.resolution,
        scope: BorderDiagnosticScope.segment,
        blueprintId: 'blueprint-a',
        featureId: 'feature-a',
        slotKey: 'slot-a',
        cell: originalCell,
        strokeId: 'stroke-a',
        segmentIndex: 7,
        parameters: <String, Object?>{'gapPx': 3},
        suggestedAction: 'border.action.inspect_gap',
      );

      expect(diagnostic.code, 'border.feature.gap');
      expect(diagnostic.severity, BorderDiagnosticSeverity.warning);
      expect(diagnostic.phase, BorderDiagnosticPhase.resolution);
      expect(diagnostic.scope, BorderDiagnosticScope.segment);
      expect(diagnostic.blueprintId, 'blueprint-a');
      expect(diagnostic.featureId, 'feature-a');
      expect(diagnostic.slotKey, 'slot-a');
      expect(diagnostic.cell, originalCell);
      expect(diagnostic.cell, isNot(same(originalCell)));
      expect(diagnostic.strokeId, 'stroke-a');
      expect(diagnostic.segmentIndex, 7);
      expect(diagnostic.parameters, <String, Object?>{'gapPx': 3});
      expect(diagnostic.suggestedAction, 'border.action.inspect_gap');
    });

    test('requires normalized machine keys and optional stable ids', () {
      for (final value in <String>['', '   ', ' value', 'value ']) {
        expect(
          () => _diagnostic(code: value),
          throwsA(isA<ValidationException>()),
          reason: 'code: "$value"',
        );
        expect(
          () => _diagnostic(suggestedAction: value),
          throwsA(isA<ValidationException>()),
          reason: 'suggestedAction: "$value"',
        );
        for (final field in <String>[
          'blueprintId',
          'featureId',
          'slotKey',
          'strokeId',
        ]) {
          expect(
            () => _diagnosticWithOptionalId(field, value),
            throwsA(isA<ValidationException>()),
            reason: '$field: "$value"',
          );
        }
      }

      expect(
        _diagnostic(
          code: 'Future Namespace/Key:v2',
          suggestedAction: 'Open Studio > Review',
        ).code,
        'Future Namespace/Key:v2',
      );
    });

    test('requires a stroke for a segment and a nonnegative segment index', () {
      expect(
        () => _diagnostic(segmentIndex: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _diagnostic(strokeId: 'stroke-a', segmentIndex: -1),
        throwsA(isA<ValidationException>()),
      );
      expect(
        _diagnostic(strokeId: 'stroke-a', segmentIndex: 0).segmentIndex,
        0,
      );
    });

    test('allows diagnostic cells outside map bounds', () {
      const cell = GridPos(x: -9223372036854775808, y: 9223372036854775807);
      expect(_diagnostic(cell: cell).cell, cell);
    });

    test('recursively copies and freezes every JSON-safe parameter shape', () {
      final nestedList = <Object?>[
        null,
        true,
        'text',
        -9007199254740991,
        9007199254740991,
        -12.5,
        <String, Object?>{'z': 1, 'a': false},
      ];
      final source = <String, Object?>{
        'nested': nestedList,
        'zero': 0.0,
      };

      final diagnostic = _diagnostic(parameters: source);
      source['later'] = true;
      nestedList.add('later');
      (nestedList[6]! as Map<String, Object?>)['later'] = true;

      expect(diagnostic.parameters.keys, <String>['nested', 'zero']);
      final copiedList = diagnostic.parameters['nested']! as List<Object?>;
      expect(copiedList, hasLength(7));
      expect(
        copiedList[6],
        <String, Object?>{'a': false, 'z': 1},
      );
      expect(
        () => diagnostic.parameters['x'] = 1,
        throwsUnsupportedError,
      );
      expect(() => copiedList.add(1), throwsUnsupportedError);
      expect(
        () => (copiedList[6]! as Map<String, Object?>)['x'] = 1,
        throwsUnsupportedError,
      );
    });

    test('rejects unsafe JSON numbers, objects, non-string keys, and cycles',
        () {
      for (final value in <Object?>[
        9007199254740992,
        -9007199254740992,
        double.infinity,
        double.negativeInfinity,
        double.nan,
        Object(),
      ]) {
        expect(
          () => _diagnostic(parameters: <String, Object?>{'value': value}),
          throwsA(isA<ValidationException>()),
          reason: '$value',
        );
      }

      final nonStringKeys = <dynamic, dynamic>{1: 'invalid'};
      expect(
        () => _diagnostic(
          parameters: <String, Object?>{'value': nonStringKeys},
        ),
        throwsA(isA<ValidationException>()),
      );

      final cyclicList = <Object?>[];
      cyclicList.add(cyclicList);
      expect(
        () => _diagnostic(
          parameters: <String, Object?>{'cycle': cyclicList},
        ),
        throwsA(isA<ValidationException>()),
      );

      final cyclicMap = <String, Object?>{};
      cyclicMap['cycle'] = cyclicMap;
      expect(
        () => _diagnostic(parameters: cyclicMap),
        throwsA(isA<ValidationException>()),
      );
    });

    test('requires every parameter map key to be nonblank and trimmed', () {
      for (final key in <String>['', '   ', ' value', 'value ']) {
        expect(
          () => _diagnostic(parameters: <String, Object?>{key: true}),
          throwsA(isA<ValidationException>()),
          reason: 'root key: "$key"',
        );
        expect(
          () => _diagnostic(parameters: <String, Object?>{
            'nested': <String, Object?>{key: true},
          }),
          throwsA(isA<ValidationException>()),
          reason: 'nested key: "$key"',
        );
      }
    });

    test('accepts depth 64 and rejects depth 65', () {
      final atLimit = _parametersWithDeepestNodeAt(64);
      final overLimit = _parametersWithDeepestNodeAt(65);

      expect(_diagnostic(parameters: atLimit).parameters, isNotEmpty);
      expect(
        () => _diagnostic(parameters: overLimit),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts 10000 visited nodes and rejects node 10001', () {
      final atLimit = <String, Object?>{
        'items': List<Object?>.filled(9998, null),
      };
      final overLimit = <String, Object?>{
        'items': List<Object?>.filled(9999, null),
      };

      expect(_diagnostic(parameters: atLimit).parameters, isNotEmpty);
      expect(
        () => _diagnostic(parameters: overLimit),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts 1000000 aggregate code units and rejects one more', () {
      final atLimit = <String, Object?>{'k': 'a' * 999999};
      final overLimit = <String, Object?>{'k': 'a' * 1000000};

      expect(
        (_diagnostic(parameters: atLimit).parameters['k']! as String).length,
        999999,
      );
      expect(
        () => _diagnostic(parameters: overLimit),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts shared acyclic containers while still copying each branch',
        () {
      final shared = <Object?>[
        <String, Object?>{'value': 1},
      ];
      final diagnostic = _diagnostic(parameters: <String, Object?>{
        'first': shared,
        'second': shared,
      });

      final first = diagnostic.parameters['first']! as List<Object?>;
      final second = diagnostic.parameters['second']! as List<Object?>;
      expect(first, second);
      expect(first, isNot(same(second)));
      expect(() => first.add(null), throwsUnsupportedError);
      expect(() => second.add(null), throwsUnsupportedError);
    });

    test('has deterministic deep value equality and hashing', () {
      final first = _diagnostic(parameters: <String, Object?>{
        'b': <Object?>[
          1,
          2.0,
          <String, Object?>{'z': true, 'a': null}
        ],
        'a': 'value',
      });
      final sameDifferentMapOrder = _diagnostic(parameters: <String, Object?>{
        'a': 'value',
        'b': <Object?>[
          1,
          2.0,
          <String, Object?>{'a': null, 'z': true}
        ],
      });
      final differentListOrder = _diagnostic(parameters: <String, Object?>{
        'a': 'value',
        'b': <Object?>[
          2.0,
          1,
          <String, Object?>{'a': null, 'z': true}
        ],
      });
      final equivalentNumberType = _diagnostic(parameters: <String, Object?>{
        'a': 'value',
        'b': <Object?>[
          1.0,
          2.0,
          <String, Object?>{'a': null, 'z': true}
        ],
      });

      expect(first, sameDifferentMapOrder);
      expect(first.hashCode, sameDifferentMapOrder.hashCode);
      expect(first.compareTo(sameDifferentMapOrder), 0);
      expect(first, isNot(differentListOrder));
      expect(first, equivalentNumberType);
      expect(first.hashCode, equivalentNumberType.hashCode);
      expect(first.compareTo(equivalentNumberType), 0);
    });

    test('compares by the complete approved deterministic precedence', () {
      void expectBefore(BorderDiagnostic first, BorderDiagnostic second) {
        expect(first.compareTo(second), lessThan(0));
        expect(second.compareTo(first), greaterThan(0));
      }

      expectBefore(
        _diagnostic(severity: BorderDiagnosticSeverity.error),
        _diagnostic(severity: BorderDiagnosticSeverity.warning),
      );
      expectBefore(
        _diagnostic(phase: BorderDiagnosticPhase.authoring),
        _diagnostic(phase: BorderDiagnosticPhase.publication),
      );
      expectBefore(
        _diagnostic(scope: BorderDiagnosticScope.project),
        _diagnostic(scope: BorderDiagnosticScope.catalog),
      );
      expectBefore(_diagnostic(), _diagnostic(blueprintId: 'a'));
      expectBefore(
        _diagnostic(blueprintId: 'a'),
        _diagnostic(blueprintId: 'b'),
      );
      expectBefore(_diagnostic(), _diagnostic(featureId: 'a'));
      expectBefore(_diagnostic(), _diagnostic(cell: const GridPos(x: 0, y: 0)));
      expectBefore(
        _diagnostic(cell: const GridPos(x: 5, y: -1)),
        _diagnostic(cell: const GridPos(x: -5, y: 0)),
      );
      expectBefore(
        _diagnostic(cell: const GridPos(x: -1, y: 0)),
        _diagnostic(cell: const GridPos(x: 1, y: 0)),
      );
      expectBefore(_diagnostic(), _diagnostic(strokeId: 'a'));
      expectBefore(
        _diagnostic(strokeId: 'a'),
        _diagnostic(strokeId: 'a', segmentIndex: 0),
      );
      expectBefore(_diagnostic(), _diagnostic(slotKey: 'a'));
      expectBefore(_diagnostic(code: 'a'), _diagnostic(code: 'b'));
      expectBefore(
        _diagnostic(parameters: <String, Object?>{'a': 1}),
        _diagnostic(parameters: <String, Object?>{'a': 2}),
      );
      expectBefore(
        _diagnostic(suggestedAction: 'a'),
        _diagnostic(suggestedAction: 'b'),
      );
    });
  });

  group('BorderDiagnosticsReport', () {
    test('sorts a defensive copy, preserves duplicates, and counts severities',
        () {
      final duplicate = _diagnostic(
        code: 'duplicate',
        severity: BorderDiagnosticSeverity.warning,
      );
      final source = <BorderDiagnostic>[
        _diagnostic(code: 'info', severity: BorderDiagnosticSeverity.info),
        duplicate,
        _diagnostic(code: 'error', severity: BorderDiagnosticSeverity.error),
        duplicate,
      ];

      final report = BorderDiagnosticsReport(diagnostics: source);
      source.clear();

      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        <String>['error', 'duplicate', 'duplicate', 'info'],
      );
      expect(report.diagnosticCount, 4);
      expect(report.errorCount, 1);
      expect(report.warningCount, 2);
      expect(report.infoCount, 1);
      expect(report.hasDiagnostics, isTrue);
      expect(report.hasErrors, isTrue);
      expect(report.hasWarnings, isTrue);
      expect(report.hasInfo, isTrue);
      expect(() => report.diagnostics.clear(), throwsUnsupportedError);
    });

    test('has a canonical empty report and ordered value semantics', () {
      const empty = BorderDiagnosticsReport.empty();
      expect(empty.diagnostics, isEmpty);
      expect(empty.diagnosticCount, 0);
      expect(empty.errorCount, 0);
      expect(empty.warningCount, 0);
      expect(empty.infoCount, 0);
      expect(empty.hasDiagnostics, isFalse);
      expect(empty.hasErrors, isFalse);
      expect(empty.hasWarnings, isFalse);
      expect(empty.hasInfo, isFalse);

      final first = BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
        _diagnostic(code: 'b'),
        _diagnostic(code: 'a'),
      ]);
      final second = BorderDiagnosticsReport(diagnostics: <BorderDiagnostic>[
        _diagnostic(code: 'a'),
        _diagnostic(code: 'b'),
      ]);
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(empty));
    });
  });
}

BorderDiagnostic _diagnostic({
  String code = 'border.test',
  BorderDiagnosticSeverity severity = BorderDiagnosticSeverity.info,
  BorderDiagnosticPhase phase = BorderDiagnosticPhase.resolution,
  BorderDiagnosticScope scope = BorderDiagnosticScope.feature,
  String? blueprintId,
  String? featureId,
  String? slotKey,
  GridPos? cell,
  String? strokeId,
  int? segmentIndex,
  Map<String, Object?> parameters = const <String, Object?>{},
  String suggestedAction = 'border.action.review',
}) =>
    BorderDiagnostic(
      code: code,
      severity: severity,
      phase: phase,
      scope: scope,
      blueprintId: blueprintId,
      featureId: featureId,
      slotKey: slotKey,
      cell: cell,
      strokeId: strokeId,
      segmentIndex: segmentIndex,
      parameters: parameters,
      suggestedAction: suggestedAction,
    );

BorderDiagnostic _diagnosticWithOptionalId(String field, String value) =>
    switch (field) {
      'blueprintId' => _diagnostic(blueprintId: value),
      'featureId' => _diagnostic(featureId: value),
      'slotKey' => _diagnostic(slotKey: value),
      'strokeId' => _diagnostic(strokeId: value),
      _ => throw StateError('unsupported fixture field: $field'),
    };

Map<String, Object?> _parametersWithDeepestNodeAt(int depth) {
  Object? value;
  for (var index = 0; index < depth; index += 1) {
    value = <String, Object?>{'level': value};
  }
  return value! as Map<String, Object?>;
}
