import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_connection_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_builder_gameplay_harness.dart';

final class _HistoryLinks extends RecordingConnections {
  _HistoryLinks(super.maps);

  final versions = <String, (MapData, MapData)>{};

  @override
  Future<MapConnectionReceipt> link({
    required ProjectSession session,
    required MapData source,
    required MapConnectionDirection direction,
    required String targetMapId,
    required int offset,
    MapData? expectedTarget,
  }) async {
    final saved = await super.link(
      session: session,
      source: source,
      direction: direction,
      targetMapId: targetMapId,
      offset: offset,
      expectedTarget: expectedTarget,
    );
    final after = saved.documents.single;
    final id = 'connection-${calls.length}';
    versions[id] = (source, after.map);
    return MapConnectionReceipt(
      saved.documents,
      history: MapCatalogReceipt(
        before: workspaceProject,
        manifest: workspaceProject,
        beforeRevision: 'catalog',
        revision: 'catalog',
        changedPaths: [after.map.id],
        documents: {after.mapId: after},
        historyEntryId: id,
        replacesContent: true,
      ),
    );
  }
}

final class _HistoryCatalog implements MapCatalogPort {
  _HistoryCatalog(this._links);

  final _HistoryLinks Function() _links;
  var _restores = 0;

  @override
  Future<MapCatalogReceipt> restoreHistory(
    ProjectSession session,
    MapCatalogReceipt receipt, {
    required bool redo,
    required ProjectManifest expectedManifest,
  }) async {
    final links = _links();
    final (before, after) = links.versions[receipt.historyEntryId]!;
    final map = redo ? after : before;
    links.maps.saved[map.id] = map;
    return MapCatalogReceipt(
      before: workspaceProject,
      manifest: workspaceProject,
      beforeRevision: 'catalog',
      revision: 'catalog',
      changedPaths: receipt.changedPaths,
      documents: {
        map.id: MapWorkspaceDocument(
          map: map,
          revision: 'restored-${++_restores}',
          mapId: map.id,
        ),
      },
      historyEntryId: receipt.historyEntryId,
      replacesContent: true,
    );
  }

  @override
  Future<void> reconcile(
    ProjectSession session,
    MapCatalogReceipt receipt,
  ) async {}

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) => throw UnimplementedError(actionId);
}

Future<void> _command(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}

Finder get _offset =>
    find.byKey(const ValueKey('map-gameplay-connection-offset'));

String _offsetText(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(of: _offset, matching: find.byType(EditableText)),
    )
    .controller
    .text;

bool _offsetFocused(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(of: _offset, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

Future<void> _openEastLink(WidgetTester tester) async {
  await openGameplay(
    tester,
    links: _HistoryLinks.new,
    catalog: _HistoryCatalog(() => connections as _HistoryLinks),
  );
  await tester.tap(find.byKey(const ValueKey('map-gameplay-connection-east')));
  await settle(tester);
  expect(_offsetText(tester), '1');
  await tester.enterText(_offset, '-1');
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('map-gameplay-connection-apply')));
  await settle(tester);
  expect(active().connections.single.offset, -1);
}

void main() {
  testWidgets(
    '⌘Z and ⌘⇧Z of a connection update refresh the form from the restored map',
    (tester) async {
      await _openEastLink(tester);
      expect(_offsetFocused(tester), isTrue);

      await _command(tester, LogicalKeyboardKey.keyZ);
      await settle(tester);
      expect(active().connections.single.offset, 1);
      expect(_offsetText(tester), '1');
      expect(button(tester, 'map-gameplay-connection-apply').onPressed, isNull);

      await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
      await settle(tester);
      expect(active().connections.single.offset, -1);
      expect(_offsetText(tester), '-1');
      expect(button(tester, 'map-gameplay-connection-apply').onPressed, isNull);
    },
  );

  testWidgets(
    'while the offset is being edited ⌘Z stays in the field and Enter releases it',
    (tester) async {
      await _openEastLink(tester);
      await tester.enterText(_offset, '4');
      await tester.pump();

      await _command(tester, LogicalKeyboardKey.keyZ);
      await settle(tester);
      expect(active().connections.single.offset, -1);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settle(tester);
      expect(_offsetFocused(tester), isFalse);

      await _command(tester, LogicalKeyboardKey.keyZ);
      await settle(tester);
      expect(active().connections.single.offset, 1);
      expect(_offsetText(tester), '1');
    },
  );
}
