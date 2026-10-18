import 'package:avelune_studio/features/resources/application/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/presentation/features/resources/resource_pack_transfer_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/resource_pack_budget_controller_test.dart';
import '../application/resource_pack_transfer_controller_test.dart' show ExportTestSink;

void main() {
  testWidgets('budget controls expose observed and allowed values', (tester) async {
    final c = ResourcePackTransferController(port: BudgetTestPort(),
      picker: () async => null, exportSink: ExportTestSink(), accept: (_) async {});
    addTearDown(c.dispose);
    await c.beginExport();
    await c.selectFiltered();
    await c.diagnose();
    await tester.pumpWidget(MaterialApp(theme: studioTheme(),
      home: Scaffold(body: ResourcePackTransferDialog(controller: c))));
    await tester.pumpAndSettle();
    expect(find.text('Vérifier les volumes'), findsOneWidget);
    expect(find.text('Volumes et limites'), findsOneWidget);
    expect(find.textContaining('10001'), findsWidgets);
    expect(find.textContaining('10000'), findsWidgets);
    expect(find.textContaining('Mesures complémentaires'), findsWidgets);
    expect(find.textContaining('Catégories de décors — Entrées de la hiérarchie'), findsOneWidget);
    expect(find.textContaining('inventaire des fichiers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
