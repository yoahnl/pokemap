import 'package:avelune_studio/features/resources/coordination/resource_pack_transfer_controller.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_pack_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/resource_pack_transfer_test_ports.dart';

void main() {
  testWidgets('shows the local pack review before installing its selection', (
    tester,
  ) async {
    final port = _PackWithSourceFile();
    await _open(tester, port);
    expect(find.text('Pack de test'), findsOneWidget);
    expect(find.text('Arbre'), findsOneWidget);
    expect(find.text('Auteur original'), findsOneWidget);
    expect(port.applies, 0);

    await tester.tap(find.text('Tout sélectionner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Préparer l’installation'));
    await tester.pumpAndSettle();
    expect(find.text('1 ressource'), findsOneWidget);
    expect(find.text('1 dépendance'), findsOneWidget);
    expect(find.text('Fichier GLB'), findsOneWidget);
    expect(find.text('Associé à Arbre'), findsOneWidget);
    expect(find.text('rp_source_interne.glb'), findsNothing);
    expect(port.applies, 0);

    await tester.tap(find.text('Installer le pack'));
    await tester.pumpAndSettle();
    expect(port.applies, 1);
    expect(find.text('Fermer'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('Pack de test'), findsNothing);
  });

  testWidgets('keeps a conflicting pack unapplied and lets the user leave', (
    tester,
  ) async {
    final port = _ConflictingPack();
    await _open(tester, port);
    await tester.tap(find.text('Tout sélectionner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Préparer l’installation'));
    await tester.pumpAndSettle();

    expect(
      find.text('Une ressource locale occupe déjà cette identité.'),
      findsOneWidget,
    );
    final install = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Installer le pack'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(install.onPressed, isNull);
    expect(port.applies, 0);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Pack de test'), findsNothing);
    expect(port.verbs, contains('release'));
  });

  testWidgets('explains incompatible tile dimensions before installation', (
    tester,
  ) async {
    final port = _IncompatibleDimensions();
    await _open(tester, port);
    await tester.tap(find.text('Tout sélectionner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Préparer l’installation'));
    await tester.pumpAndSettle();

    expect(
      find.text('La taille des tuiles du pack diffère de celle du projet.'),
      findsOneWidget,
    );
    expect(port.applies, 0);
  });
}

class _PackWithSourceFile extends PackTestPort {
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    final response = await super.transfer(verb, input);
    if (verb == 'prepare') {
      return settled({
        ...response['result']! as Map<String, Object?>,
        'resourceCount': 1,
      });
    }
    if (verb == 'preview') {
      return {
        'items': [
          ...response['items']! as List,
          {
            'label': 'rp_source_interne.glb',
            'disposition': 'source',
            'requiredByLabel': 'Arbre',
          },
        ],
        'totalAvailable': 2,
      };
    }
    return response;
  }
}

Future<void> _open(WidgetTester tester, PackTestPort port) async {
  final transfer = ResourcePackTransferController(
    port: port,
    picker: () async => '/chosen.aveluneassets',
    accept: (_) async {},
  );
  addTearDown(transfer.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => ProjectLibraryPackDialog(transfer: transfer),
            ),
            child: const Text('Ouvrir le dialogue'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir le dialogue'));
  await tester.pumpAndSettle();
}

class _ConflictingPack extends PackTestPort {
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    final response = await super.transfer(verb, input);
    if (verb == 'prepare') {
      return settled({
        ...(response['result']! as Map<String, Object?>),
        'status': 'conflict',
        'preparedImportHandle': null,
        'conflictCount': 1,
      });
    }
    if (verb == 'preview') {
      return {
        'items': [
          {
            'label': 'Arbre',
            'message': 'Une ressource locale occupe déjà cette identité.',
          },
        ],
        'totalAvailable': 1,
      };
    }
    return response;
  }
}

class _IncompatibleDimensions extends PackTestPort {
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb != 'prepare') return super.transfer(verb, input);
    return {
      'phase': 'failed',
      'snapshot': {
        'jobId': 'incompatible-pack',
        'state': 'failed',
        'errorCode': 'resource_pack.dimensions_incompatible',
      },
    };
  }
}
