import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_pack_transfer_controller_test.dart'
    show ExportPackTestPort, ExportTestSink;

const budgetReportFixture = <String, Object?>{
  'scope': 'nativeSelection',
  'accepted': false,
  'measurementComplete': false,
  'unknownDimensions': ['publicationMetadata', 'fileInventory'],
  'totals': {'supports': 10001},
  'metrics': [
    {'scope': 'nativeSelection', 'dimension': 'supports',
      'observed': 10001, 'allowed': 10000, 'unit': 'unités',
      'label': 'Définitions techniques',
      'remedy': 'Partager les définitions équivalentes.'},
    {'scope': 'nativeSelection.elementCategories', 'dimension': 'hierarchyEntries',
      'observed': 2, 'allowed': 10000, 'unit': 'unités',
      'label': 'Entrées de la hiérarchie', 'remedy': 'Réduire la hiérarchie.'},
  ],
  'violations': [
    {'scope': 'nativeSelection', 'dimension': 'supports',
      'observed': 10001, 'allowed': 10000, 'unit': 'unités',
      'label': 'Définitions techniques',
      'remedy': 'Partager les définitions équivalentes.'},
  ],
};

class BudgetTestPort extends ExportPackTestPort {
  bool rejectPreparation = false;

  @override
  Future<Map<String, Object?>> transfer(String verb,
      [Map<String, Object?> input = const {}]) async {
    if (verb == 'diagnose') {
      verbs.add(verb);
      inputs.add(input);
      return settled({'budgetReports': [budgetReportFixture]});
    }
    if (verb == 'prepare' && rejectPreparation) {
      return {
        'snapshot': {'jobId': 'budget-job', 'state': 'failed',
          'errorCode': 'catalog.budget_exceeded',
          'errorMessage': 'Définitions techniques : 10001, limite 10000.'},
        'result': {'budgetReport': budgetReportFixture},
      };
    }
    return super.transfer(verb, input);
  }
}

void main() {
  test('volumes can be diagnosed before export metadata is complete', () async {
    final port = BudgetTestPort();
    final c = ResourcePackTransferController(port: port,
      picker: () async => null, exportSink: ExportTestSink(), accept: (_) async {});
    addTearDown(c.dispose);
    await c.beginExport();
    await c.selectFiltered();
    expect(c.canPrepare, isFalse);
    expect(c.canDiagnose, isTrue);
    await c.diagnose();
    expect(c.budgetReports, [budgetReportFixture]);
    expect(c.phase, ResourcePackTransferPhase.selecting);
    expect(port.verbs.where((v) => v == 'prepare'), isEmpty);
    await c.selectFiltered();
    expect(c.budgetReports, isEmpty);
  });

  test('preparation rejection retains budget facts instead of a generic code', () async {
    final port = BudgetTestPort()..rejectPreparation = true;
    final c = ResourcePackTransferController(port: port,
      picker: () async => null, exportSink: ExportTestSink(), accept: (_) async {});
    addTearDown(c.dispose);
    await c.beginExport();
    for (final entry in {'name': 'Pack', 'author': 'Auteur',
      'universeId': 'frlg', 'provenance': 'Original'}.entries) {
      await c.setExportField(entry.key, entry.value);
    }
    await c.selectFiltered();
    await c.prepare();
    expect(c.budgetReports, [budgetReportFixture]);
    expect(c.error, contains('10001'));
    expect(c.error, contains('10000'));
    expect(c.phase, ResourcePackTransferPhase.selecting);
  });
}
