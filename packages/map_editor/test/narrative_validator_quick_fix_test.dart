import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_diagnostic_suppression_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies only a previewed deterministic reversible project mutation',
      () async {
    const before = ProjectManifest(
      name: 'Before',
      maps: [],
      tilesets: [],
    );
    final after = before.copyWith(name: 'After');
    final quickFix = NarrativeValidatorQuickFix(
      diagnosticId: 'warning:projectName',
      label: 'Renommer le projet',
      preview: 'Before → After',
      before: before,
      after: after,
      deterministic: true,
      reversible: true,
    );
    ProjectManifest? persisted;

    final result = await const NarrativeValidatorQuickFixService().apply(
      current: before,
      quickFix: quickFix,
      previewAccepted: true,
      persist: (project) async => persisted = project,
    );

    expect(result.name, 'After');
    expect(persisted, same(after));
    expect(quickFix.rollback, same(before));
  });

  test('refuses missing preview and does not expose failed persistence',
      () async {
    const before = ProjectManifest(
      name: 'Before',
      maps: [],
      tilesets: [],
    );
    final quickFix = NarrativeValidatorQuickFix(
      diagnosticId: 'warning:projectName',
      label: 'Renommer le projet',
      preview: 'Before → After',
      before: before,
      after: before.copyWith(name: 'After'),
      deterministic: true,
      reversible: true,
    );
    const service = NarrativeValidatorQuickFixService();

    expect(
      () => service.apply(
        current: before,
        quickFix: quickFix,
        previewAccepted: false,
        persist: (_) async {},
      ),
      throwsA(isA<NarrativeValidatorQuickFixRejected>()),
    );
    expect(
      () => service.apply(
        current: before,
        quickFix: quickFix,
        previewAccepted: true,
        persist: (_) async => throw StateError('write rejected'),
      ),
      throwsStateError,
    );
    expect(before.name, 'Before');
  });
}
