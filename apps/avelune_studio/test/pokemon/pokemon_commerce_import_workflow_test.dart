import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_controller.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_commerce_import_workflow.dart';
import 'package:avelune_studio/features/pokemon/data/local_pokemon_commerce_adapter.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_commerce_port.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pokemon_authoring_fixture.dart';

Future<PokemonAuthoringFixture> _open() async {
  final host = await PokemonAuthoringFixture.create(
    prepareSource: (source) async {
      final target = File(
        '${source.directory.path}/data/pokemon/catalogs/items.json',
      );
      await target.parent.create(recursive: true);
      await File(
        '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/items.json',
      ).copy(target.path);
    },
  );
  addTearDown(host.dispose);
  expect(await host.view(PokemonWorkspaceView.items), isTrue);
  return host;
}

Future<String> _candidate(PokemonAuthoringFixture host, String name) async {
  final potion = host.commerce.snapshot!.catalog!.entries.firstWhere(
    (item) => item.id == 'potion',
  );
  final file = File('${host.source.directory.path}/candidate-$name.json');
  await file.writeAsString(
    jsonEncode(potion.copyWith(displayName: name).toJson()),
  );
  return file.path;
}

Future<String> _savedName(PokemonAuthoringFixture host) async {
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(host.source.session);
  final snapshot = await LocalPokemonCommerceAdapter(
    session: host.source.session,
    mapAdapter: maps,
  ).load();
  return snapshot.catalog!.entries
      .firstWhere((item) => item.id == 'potion')
      .displayName;
}

PokemonCommerceImportWorkflow _workflow(PokemonAuthoringFixture host) {
  final workflow = PokemonCommerceImportWorkflow(
    commerce: host.commerce,
    isActive: () => true,
  );
  addTearDown(workflow.dispose);
  return workflow;
}

void main() {
  test('confirmed item conflict publishes the reviewed item through the real adapter', () async {
    final host = await _open();
    final path = await _candidate(host, 'Potion confirmée');
    PokemonCommerceImportPreview? reviewed;
    final result = await _workflow(host).importJson(
      items: true,
      picker: () async => path,
      confirm: (preview) async {
        reviewed = preview;
        return true;
      },
    );
    expect(reviewed!.conflict, isTrue);
    expect(reviewed!.item!.displayName, 'Potion confirmée');
    expect(result, isTrue, reason: host.commerce.error);
    expect(await _savedName(host), 'Potion confirmée');
    expect(host.commerce.importPreview, isNull);
    expect(host.commerce.dirty, isFalse);
  });

  test(
    'refusing an item conflict cancels its preview and preserves the catalogue',
    () async {
      final host = await _open();
      final path = await _candidate(host, 'Refusée');
      final before = await _savedName(host);
      expect(
        await _workflow(host).importJson(
          items: true,
          picker: () async => path,
          confirm: (_) async => false,
        ),
        isFalse,
      );
      expect(host.commerce.importPreview, isNull);
      expect(await _savedName(host), before);
    },
  );

  for (final accepted in [true, false]) {
    test(
      'a stale ${accepted ? 'accepted' : 'refused'} consent cannot publish or erase a newer item preview',
      () async {
        final host = await _open();
        final a = await _candidate(host, 'Potion A');
        final b = await _candidate(host, 'Potion B');
        final entered = Completer<void>();
        final consent = Completer<bool>();
        final workflow = _workflow(host);
        final operation = workflow.importJson(
          items: true,
          picker: () async => a,
          confirm: (_) {
            entered.complete();
            return consent.future;
          },
        );
        await entered.future;
        await host.commerce.prepareImport(b, item: true);
        final newer = host.commerce.importPreview!;
        expect(newer.item!.displayName, 'Potion B');
        final before = await _savedName(host);
        consent.complete(accepted);
        expect(await operation, isFalse);
        expect(host.commerce.importPreview, same(newer));
        expect(await _savedName(host), before);
        expect(await host.commerce.applyImport(confirmOverwrite: true), isTrue);
        expect(await _savedName(host), 'Potion B');
      },
    );
  }

  test('dirty commerce refuses the picker without changing its item', () async {
    final host = await _open();
    final item = host.commerce.snapshot!.catalog!.entries.first;
    host.commerce.selectItem(item);
    host.commerce.editItem((item) => item.copyWith(displayName: 'En cours'));
    var picks = 0;
    final workflow = _workflow(host);
    expect(
      await workflow.importJson(
        items: true,
        picker: () async {
          picks++;
          return null;
        },
        confirm: (_) async => true,
      ),
      isFalse,
    );
    expect(picks, 0);
    expect(workflow.refusal, contains('brouillon'));
    expect(host.commerce.item!.displayName, 'En cours');
  });

  test(
    'a cancelled picker creates no import preview or file mutation',
    () async {
      final host = await _open();
      final before = await _savedName(host);
      expect(
        await _workflow(host).importJson(
          items: true,
          picker: () async => null,
          confirm: (_) async => true,
        ),
        isFalse,
      );
      expect(host.commerce.importPreview, isNull);
      expect(await _savedName(host), before);
    },
  );

  test(
    'a picker returning after its workflow closes cannot prepare an import',
    () async {
      final host = await _open();
      final path = await _candidate(host, 'Trop tard');
      final picker = Completer<String?>();
      final workflow = _workflow(host);
      final operation = workflow.importJson(
        items: true,
        picker: () => picker.future,
        confirm: (_) async => true,
      );
      workflow.dispose();
      picker.complete(path);
      expect(await operation, isFalse);
      expect(host.commerce.importPreview, isNull);
    },
  );
}
