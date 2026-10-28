import 'dart:collection';
import 'dart:math' as math;

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('changed definitions visit only shared-tree mutation paths', () {
    final original = ProjectModel3dEntries.prepare(List.generate(8192, _model));
    final replacement = original[8000].copyWith(name: 'Lantern');
    final changed = original.replaceSelected([replacement]);
    var visited = 0;
    expect(changed.changesSince(original, onNodeVisited: () => visited++), [
      replacement,
    ]);
    expect(visited, lessThanOrEqualTo(14));
    expect(original.changesSince(changed), [original[8000]]);
    expect(changed.changesSince(changed), isEmpty);
    expect(
      changed.changesSince(ProjectModel3dEntries.prepare(original.toList())),
      isNull,
    );
  });
  for (final count in [32, 8192]) {
    test(
      'selected model projection is bounded cold and repeated with $count entries',
      () {
        final source = _CountingModels(List.generate(count, _model));
        final initial = ProjectModel3dEntries.prepare(source);
        expect(source.reads, count);
        source.reads = 0;
        var current = initial;
        final old = initial.lookup('model-${count - 1}')!;
        final maximumCopies = (math.log(count) / math.ln2).ceil() + 1;
        for (var operation = 0; operation < 1000; operation++) {
          var copied = 0;
          final replacement = old.copyWith(name: 'Changed $operation');
          final next = current.replaceSelected([
            replacement,
          ], onNodeCopied: () => copied++);
          expect(copied, inInclusiveRange(1, maximumCopies));
          expect(
            identical(next.lookup('model-0'), initial.lookup('model-0')),
            true,
          );
          expect(identical(next.lookup(old.id), replacement), true);
          expect(initial.lookup(old.id), old);
          if (operation > 0) {
            expect(current.lookup(old.id)!.name, 'Changed ${operation - 1}');
          }
          current = next;
        }
        expect(source.reads, 0);
        expect(current.length, count);
        expect(current[count - 1].name, 'Changed 999');
        expect(initial[count - 1], old);
      },
    );
  }

  test(
    'model projection survives Freezed copies without enumeration or schema changes',
    () {
      final entries = ProjectModel3dEntries.prepare(List.generate(4, _model));
      final project = ProjectManifest(
        name: 'Test',
        maps: const [],
        tilesets: const [],
        models3d: entries,
      );
      final copied = project.copyWith(name: 'Renamed');
      expect(identical(project.models3d, entries), true);
      expect(identical(copied.models3d, entries), true);
      final next = entries.replaceSelected([
        _model(2).copyWith(name: 'Replacement'),
      ]);
      final projected = copied.copyWith(models3d: next);
      expect(identical(projected.models3d, next), true);
      expect(project.models3d[2].name, 'Model 2');
      expect(projected.models3d[2].name, 'Replacement');
      expect(
        projected.toJson()['models3d'],
        next.map((model) => model.toJson()).toList(),
      );
      final decoded = ProjectManifest.fromJson(projected.toJson());
      expect(decoded.models3d, next);
      expect(decoded, projected);
      expect(decoded.hashCode, projected.hashCode);
    },
  );

  test('batch replacement preserves ordering and immutable prior views', () {
    final entries = ProjectModel3dEntries.prepare(List.generate(16, _model));
    final source = entries.toList();
    final replacements = [
      entries[2].copyWith(name: 'Two'),
      entries[14].copyWith(name: 'Fourteen'),
    ];
    var copied = 0;
    final next = entries.replaceSelected(
      replacements,
      onNodeCopied: () => copied++,
    );
    expect(copied, lessThanOrEqualTo(10));
    expect(next.map((model) => model.id), entries.map((model) => model.id));
    expect(entries, source);
    expect(next[2].name, 'Two');
    expect(next[14].name, 'Fourteen');
    expect(() => next[0] = _model(0), throwsUnsupportedError);
    expect(() => next.length = 0, throwsUnsupportedError);
    expect(() => next.add(_model(16)), throwsUnsupportedError);
  });

  test(
    'no-op returns its current view and invalid identities cannot mutate it',
    () {
      final entries = ProjectModel3dEntries.prepare(List.generate(3, _model));
      var copied = 0;
      expect(
        identical(
          entries.replaceSelected([entries[1]], onNodeCopied: () => copied++),
          entries,
        ),
        true,
      );
      expect(copied, 0);
      expect(entries.lookup('absent'), isNull);
      expect(() => entries.replaceSelected([_model(9)]), throwsArgumentError);
      expect(
        () => entries.replaceSelected([_model(1), _model(1)]),
        throwsArgumentError,
      );
      expect(
        () => ProjectModel3dEntries.prepare([_model(1), _model(1)]),
        throwsArgumentError,
      );
      expect(entries.map((entry) => entry.id), [
        'model-0',
        'model-1',
        'model-2',
      ]);
      expect(() => entries[-1], throwsRangeError);
      expect(() => entries[3], throwsRangeError);
      final empty = ProjectModel3dEntries.prepare(const []);
      expect(empty, isEmpty);
      expect(identical(empty.replaceSelected(const []), empty), true);
      expect(() => empty[0], throwsRangeError);
    },
  );
}

final _inspection = Model3dInspection(
  bounds: Model3dBounds(
    min: Model3dVector3.zero,
    max: Model3dVector3(x: 1, y: 1, z: 1),
  ),
  meshCount: 1,
  triangleCount: 1,
);

ProjectModel3dEntry _model(int index) => ProjectModel3dEntry(
  id: 'model-$index',
  name: 'Model $index',
  sourceAssetId: 'source-$index',
  relativePath: 'assets/models3d/model-$index.glb',
  inspection: _inspection,
);

final class _CountingModels extends ListBase<ProjectModel3dEntry> {
  _CountingModels(this.values);
  final List<ProjectModel3dEntry> values;
  var reads = 0;

  @override
  int get length => values.length;

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  ProjectModel3dEntry operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, ProjectModel3dEntry value) =>
      throw UnsupportedError('immutable');
}
