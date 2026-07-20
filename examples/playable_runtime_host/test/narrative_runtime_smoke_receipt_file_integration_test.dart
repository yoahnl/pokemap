import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/verify_narrative_project.dart';

void main() {
  test('atomic writer publishes a decodable receipt', () async {
    final root = await Directory.systemTemp.createTemp('receipt_atomic_');
    addTearDown(() => root.delete(recursive: true));
    final receipt = _receipt('a');
    await writeNarrativeRuntimeSmokeReceiptAtomically(
      projectRoot: root.path,
      receipt: receipt,
    );
    final file = File(p.join(
      root.path,
      '.pokemap/validation/narrative_runtime_smoke_receipt.json',
    ));
    final decoded = NarrativeRuntimeSmokeReceipt.fromJson(
      Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
    );
    expect(decoded.projectFingerprint, receipt.projectFingerprint);
  });

  test('failure before rename preserves the previous valid receipt', () async {
    final root = await Directory.systemTemp.createTemp('receipt_preserve_');
    addTearDown(() => root.delete(recursive: true));
    await writeNarrativeRuntimeSmokeReceiptAtomically(
      projectRoot: root.path,
      receipt: _receipt('a'),
    );

    await expectLater(
      writeNarrativeRuntimeSmokeReceiptAtomically(
        projectRoot: root.path,
        receipt: _receipt('b'),
        beforeRename: (_) async => throw StateError('simulated crash'),
      ),
      throwsStateError,
    );
    final file = File(p.join(
      root.path,
      '.pokemap/validation/narrative_runtime_smoke_receipt.json',
    ));
    final decoded = jsonDecode(await file.readAsString()) as Map;
    expect(decoded['projectFingerprint'], 'sha256:${'a' * 64}');
    expect(
      file.parent.listSync().whereType<File>().map((item) => item.path),
      everyElement(isNot(endsWith('.tmp'))),
    );
  });
}

NarrativeRuntimeSmokeReceipt _receipt(String hex) =>
    NarrativeRuntimeSmokeReceipt(
      projectFingerprint: 'sha256:${hex * 64}',
      validatorVersion: 'v1',
      profileId: selbrumeReleaseV1Profile.id,
      profileVersion: 1,
      suiteIds: selbrumeReleaseV1Profile.requiredSuiteIds,
      fixtureId: 'selbrume',
      result: NarrativeRuntimeSmokeResult.pass,
      completedAt: DateTime.utc(2026),
    );
