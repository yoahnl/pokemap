import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('empty roots require an explicit policy option', () async {
    final reader = _NoFilesystemReader();
    await expectLater(
      WorkspacePolicy.create(allowedRootPaths: [], fileReader: reader),
      throwsA(isA<WorkspaceAccessException>().having(
          (error) => error.code, 'code', 'workspace.allowed_roots_required')),
    );
    expect(reader.calls, 0);
  });

  test('an empty discovery policy refuses access before filesystem lookup',
      () async {
    final reader = _NoFilesystemReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [], fileReader: reader, allowEmptyRoots: true);
    await expectLater(
      policy.authorizeProjectRoot('/unavailable/project'),
      throwsA(isA<WorkspaceAccessException>().having((error) => error.code,
          'code', 'workspace.path_outside_allowed_roots')),
    );
    expect(reader.calls, 0);
  });
}

final class _NoFilesystemReader implements ProjectFileReader {
  var calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Discovery attempted filesystem access.');
  }
}
