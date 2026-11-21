import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_border_creation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('requires the connected-line pieces and keeps a refused draft', (
    tester,
  ) async {
    BorderCreationRequest? received;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => StudioButton(
              label: 'Nouvelle bordure',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => ProjectBorderCreationDialog(
                  models: [
                    ProjectLibraryItem(
                      kind: 'model3d',
                      id: 'cap',
                      name: 'Extrémité bois',
                    ),
                    ProjectLibraryItem(
                      kind: 'model3d',
                      id: 'straight',
                      name: 'Traverse bois',
                    ),
                  ],
                  familyLabels: const {},
                  save: (request) async {
                    received = request;
                    throw const ResourceFailure('Le catalogue a changé.');
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Nouvelle bordure'));
    await tester.pumpAndSettle();
    final name = find.byKey(const ValueKey('border-creation-name'));
    await tester.enterText(name, '  Clôture du jardin  ');
    await tester.pumpAndSettle();
    final confirm = find.widgetWithText(StudioButton, 'Créer le brouillon');
    expect(tester.widget<StudioButton>(confirm).onPressed, isNull);
    await _choose(tester, 'lineCap', 'cap');
    await _choose(tester, 'lineStraight', 'straight');
    expect(tester.widget<StudioButton>(confirm).onPressed, isNull);

    await tester.tap(
      find.byKey(const ValueKey('border-creation-straight-only')),
    );
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(received?.name, 'Clôture du jardin');
    expect(received?.template, BorderBlueprintTemplate.connectedLine);
    expect(received?.capModelId, 'cap');
    expect(received?.straightModelId, 'straight');
    expect(received?.straightOnly, isTrue);
    expect(received?.publish, isFalse);
    expect(find.text('Le catalogue a changé.'), findsOneWidget);
    expect(find.text('  Clôture du jardin  '), findsOneWidget);
  });
}

Future<void> _choose(WidgetTester tester, String role, String id) async {
  await tester.tap(find.byKey(ValueKey('border-creation-$role')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('model-replacement-target-$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Utiliser ce modèle'));
  await tester.pumpAndSettle();
}
