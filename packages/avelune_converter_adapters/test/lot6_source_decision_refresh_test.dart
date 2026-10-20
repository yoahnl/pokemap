import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import '../tool/lot6_source_decision_refresh.dart';

SourceFileEntry _file(String path, {int value = 1, int size = 1}) =>
    SourceFileEntry(
        fileId: ConverterId('entry:${path.hashCode.abs()}'),
        relativePath: path,
        kind: SourceNodeKind.file,
        byteLength: size,
        sha256: canonicalHashOf(value),
        format: 'unknown',
        family: 'other');

SourceSnapshot _snapshot(List<SourceFileEntry> entries,
        {String policy = 'policy'}) =>
    SourceSnapshot(
        logicalProjectNamespace: ConverterId('refresh-fixture'),
        policyHash: canonicalHashOf(policy),
        entries: entries,
        diagnostics: [],
        excludedPaths: [],
        profileEvidence: [],
        state: SourceScanState.complete);

void main() {
  final game = _file('Data/Map001.rxdata');
  final original = _snapshot([game]);
  Map<String, Object?> decisions() => {
        'snapshotHash': original.canonicalHash.value,
        'decisions': [
          {
            'sourceSnapshotHash': original.canonicalHash.value,
            'originalPageHash': 'unchanged-page'
          }
        ],
        'missingItemBindings': [
          {
            'sourceSnapshotHash': original.canonicalHash.value,
            'sourceSha256': 'unchanged-catalog'
          }
        ],
      };

  test('preserves an unchanged sealed decision inventory', () {
    expect(refreshLot6SourceDecisionsForRootClippings(original, decisions()),
        decisions());
  });

  test('refreshes only snapshot hashes after exact rest-of-inventory equality',
      () {
    final input = decisions();
    final current = _snapshot([game, _file('Pasted.textClipping')]);
    final refreshed =
        refreshLot6SourceDecisionsForRootClippings(current, input);
    expect(refreshed['snapshotHash'], current.canonicalHash.value);
    final row = (refreshed['decisions'] as List).single as Map;
    expect(row, {
      'sourceSnapshotHash': current.canonicalHash.value,
      'originalPageHash': 'unchanged-page'
    });
    expect(
        ((refreshed['missingItemBindings'] as List).single
            as Map)['sourceSha256'],
        'unchanged-catalog');
    expect(input, decisions());
    expect(current.entries, hasLength(2));
    expect((refreshed['inventoryRefresh'] as Map)['sourceFilesModified'], 0);
  });

  for (final extra in [
    _file('Data/nested.textClipping'),
    _file('other.txt'),
    _file('large.textClipping', size: 1048577),
  ]) {
    test('refuses an unqualified addition ${extra.relativePath}', () {
      expect(
          () => refreshLot6SourceDecisionsForRootClippings(
              _snapshot([game, extra]), decisions()),
          throwsStateError);
    });
  }

  test('refuses game changes even when a root clipping was added', () {
    expect(
        () => refreshLot6SourceDecisionsForRootClippings(
            _snapshot([
              _file('Data/Map001.rxdata', value: 2),
              _file('Pasted.textClipping')
            ]),
            decisions()),
        throwsStateError);
  });

  test('refuses removed game files and changed scan policies', () {
    final clip = _file('Pasted.textClipping');
    expect(
        () => refreshLot6SourceDecisionsForRootClippings(
            _snapshot([clip]), decisions()),
        throwsStateError);
    expect(
        () => refreshLot6SourceDecisionsForRootClippings(
            _snapshot([game, clip], policy: 'changed'), decisions()),
        throwsStateError);
  });

  test('refuses decisions bound to another original inventory', () {
    final input = decisions();
    ((input['decisions'] as List).single as Map)['sourceSnapshotHash'] =
        canonicalHashOf('foreign').value;
    expect(
        () => refreshLot6SourceDecisionsForRootClippings(
            _snapshot([game, _file('Pasted.textClipping')]), input),
        throwsStateError);
  });
}
