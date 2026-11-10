import 'package:avelune_studio/features/map_workspace/application/workspace_resource_diagnostic_projection.dart';
import 'package:avelune_studio/platform/rendering/contracts/workspace_resource_diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final count in [0, 1, 200]) {
    test('$count requested diagnostics retain every unique resource', () {
      final projection = WorkspaceResourceDiagnosticProjection(
        _diagnostics(count), const {},
      );
      expect(projection.ownerCount, count);
      expect(projection.diagnostics, hasLength(count));
      expect(projection.groups, hasLength(count));
      expect(projection.retryableIds, hasLength(count));
      expect(projection.diagnostics.map((item) => item.resourceId),
          unorderedEquals([for (var index = 0; index < count; index++) 'resource-$index']));
    });
  }

  test('active filter retries failed resources only and projects live updates', () async {
    final visuals = _Visuals(_diagnostics(200, retryingFirst: true));
    addTearDown(visuals.dispose);
    WorkspaceResourceDiagnosticProjection project({bool activeOnly = false}) =>
        WorkspaceResourceDiagnosticProjection(
          visuals.diagnostics, visuals.activeResourceIds, activeOnly: activeOnly,
        );
    final active = project(activeOnly: true);
    expect(active.diagnostics, hasLength(2));
    expect(active.diagnostics.first.status, WorkspaceResourceStatus.retrying);
    expect(active.retryableIds, ['resource-1']);
    await visuals.retryResources(active.retryableIds);
    expect(visuals.retried, [['resource-1']]);
    expect(project(activeOnly: true).diagnostics, hasLength(1));
    expect(project().diagnostics, hasLength(199));
    expect(project().retryableIds, isNot(contains('resource-0')));
  });

  test('deduplicates identities and retains all memory pressure details', () {
    final items = _diagnostics(200, cause: WorkspaceResourceCause.memoryPressure);
    final projection = WorkspaceResourceDiagnosticProjection(
      [...items, items.first], {'resource-0', 'resource-1'},
    );
    expect(projection.ownerCount, 200);
    expect(projection.diagnostics, hasLength(200));
    final group = projection.groups.single;
    expect(group.key, 'memory');
    expect(group.title, '200 ressources · pression mémoire');
    expect(group.items, hasLength(200));
    expect(group.active, isTrue);
    expect(group.owner, isNull);
    expect(group.roles, isEmpty);
    expect(group.verified, isTrue);
    for (var index = 0; index < 200; index++) {
      final item = group.items.firstWhere((item) => item.resourceId == 'resource-$index');
      expect(workspaceResourceDiagnosticDetail(item),
          contains('Détail technique ressource $index'));
      expect(workspaceResourceDiagnosticDetail(item), contains(item.resourceId));
    }
  });

  test('latest duplicate state wins and active groups sort before inactive groups', () {
    final first = _diagnostics(3);
    final replacement = WorkspaceResourceDiagnostic(
      resourceId: first.first.resourceId, name: 'Nouvel état',
      cause: WorkspaceResourceCause.accessDenied, retryable: false,
    );
    final projection = WorkspaceResourceDiagnosticProjection(
      [...first, replacement], {'resource-2'},
    );
    expect(projection.ownerCount, 3);
    expect(projection.groups.first.key, 'resource-2');
    expect(projection.diagnostics.first.resourceId, 'resource-2');
    final updated = projection.diagnostics.singleWhere((item) => item.resourceId == 'resource-0');
    expect(updated, same(replacement));
    expect(projection.retryableIds, isNot(contains('resource-0')));
    expect(workspaceResourceDiagnosticDetail(updated),
        endsWith('Aucun détail technique disponible.'));
  });
}

List<WorkspaceResourceDiagnostic> _diagnostics(
  int count, {
  WorkspaceResourceCause cause = WorkspaceResourceCause.missing,
  bool retryingFirst = false,
}) => [
  for (var index = 0; index < count; index++)
    WorkspaceResourceDiagnostic(
      resourceId: 'resource-$index',
      name: 'Ressource très longue $index ${List.filled(20, 'atlas').join(' ')}',
      cause: cause,
      detail: 'Détail technique ressource $index',
      status: index == 0 && retryingFirst
          ? WorkspaceResourceStatus.retrying
          : WorkspaceResourceStatus.failed,
    ),
];

class _Visuals extends WorkspaceTestVisuals {
  _Visuals(this.diagnostics);
  @override
  List<WorkspaceResourceDiagnostic> diagnostics;
  @override
  Set<String> get activeResourceIds => {'resource-0', 'resource-1'};
  final retried = <List<String>>[];
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {
    final ids = resourceIds.toList();
    retried.add(ids);
    diagnostics = diagnostics.where((item) => !ids.contains(item.resourceId)).toList();
  }
}
