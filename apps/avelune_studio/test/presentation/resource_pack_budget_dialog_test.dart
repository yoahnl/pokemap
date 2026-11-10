import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_pack_review_projection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/resource_pack_budget_controller_test.dart';
import '../application/resource_pack_transfer_controller_test.dart'
    show ExportTestSink;

void main() {
  test('budget review retains observed allowed hierarchy and missing-measurement facts', () async {
    final controller = ResourcePackTransferController(
      port: BudgetTestPort(),
      picker: () async => null,
      exportSink: ExportTestSink(),
      accept: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.beginExport();
    await controller.selectFiltered();
    await controller.diagnose();
    final report = controller.budgetReports.single;
    expect(report['measurementComplete'], isFalse);
    final metrics = (report['metrics']! as List).cast<Map>();
    expect(metrics.first['observed'], 10001);
    expect(metrics.first['allowed'], 10000);
    final hierarchy = metrics[1];
    expect(
      resourcePackBudgetContextLabel(hierarchy['scope']),
      'Catégories de décors',
    );
    expect(hierarchy['label'], 'Entrées de la hiérarchie');
    expect(
      (report['unknownDimensions']! as List).map(
        resourcePackUnknownDimensionLabel,
      ),
      contains('inventaire des fichiers'),
    );
  });
}
