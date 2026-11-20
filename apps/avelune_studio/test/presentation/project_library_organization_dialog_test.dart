import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/project_library_organization.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_organization_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets(
    'batch classification retains its edits during index preparation',
    (tester) async {
      var prepared = false;
      var attempts = 0;
      ProjectLibraryOrganizationDialogResult<ProjectLibraryBatchEdit>? result;
      await _show<ProjectLibraryBatchEdit>(
        tester,
        ProjectLibraryBatchClassifyDialog(
          selectionCount: 2,
          familyLabels: const {'trees': 'Arbres'},
          save: (family, role) async {
            attempts++;
            expect(family?.id, 'trees');
            expect(role, isNull);
            if (!prepared) throw const ProjectLibraryNeedsPreparation();
            return (items: const <ProjectLibraryItem>[], receipt: _receipt);
          },
          prepareCatalog: () async => prepared = true,
        ),
        (reply) => result = reply,
      );

      await tester.tap(find.byKey(const ValueKey('library-batch-family')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Arbres').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classer la sélection'));
      await tester.pumpAndSettle();
      expect(attempts, 1);
      await tester.tap(find.text('Préparer le catalogue'));
      await tester.pumpAndSettle();
      expect(prepared, isTrue);
      expect(attempts, 1);
      await tester.tap(find.text('Classer la sélection'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(result?.edit?.receipt, same(_receipt));
    },
  );

  testWidgets(
    'family manager confirms before asking to remove an empty family',
    (tester) async {
      final family = ResourceFamily(id: 'small', name: 'Sous-bois');
      var deleted = 0;
      ProjectLibraryOrganizationDialogResult<ProjectLibraryFamilyEdit>? result;
      await _show<ProjectLibraryFamilyEdit>(
        tester,
        ProjectLibraryFamiliesDialog(
          families: [family],
          familyLabels: const {'trees': 'Arbres', 'small': 'Sous-bois'},
          prepareCatalog: () async {},
          saveFamily: (_, _, _) async => throw StateError('unexpected save'),
          deleteFamily: (selected) async {
            expect(selected, family);
            deleted++;
            return (id: family.id, family: null, receipt: _receipt);
          },
        ),
        (reply) => result = reply,
      );
      await tester.tap(find.byKey(const ValueKey('library-family-target')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sous-bois').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer cette famille…'));
      await tester.pumpAndSettle();
      expect(deleted, 0);
      await tester.tap(find.text('Supprimer la famille').last);
      await tester.pumpAndSettle();
      expect(deleted, 1);
      expect(result?.edit?.id, family.id);
      expect(result?.edit?.family, isNull);
    },
  );
}

Future<void> _show<T>(
  WidgetTester tester,
  Widget dialog,
  void Function(ProjectLibraryOrganizationDialogResult<T>? result) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => StudioButton(
            label: 'Ouvrir',
            onPressed: () async => onResult(
              await showDialog<ProjectLibraryOrganizationDialogResult<T>>(
                context: context,
                barrierDismissible: false,
                builder: (_) => dialog,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

const _project = ProjectManifest(name: 'Atelier', maps: [], tilesets: []);
const _receipt = ResourceMutationReceipt(
  before: _project,
  manifest: _project,
  beforeRevision: 'avant',
  revision: 'après',
  changedPaths: [],
);
