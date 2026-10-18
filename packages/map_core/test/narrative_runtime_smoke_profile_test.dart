import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  Map<String, dynamic> manifest(Object? profile) => {
    ...const ProjectManifest(
      name: 'Profile test',
      maps: [],
      tilesets: [],
    ).toJson(),
    'runtimeSmokeProfile': profile,
  };

  test('each project preserves its explicit runtime verification policy', () {
    for (final id in ['project-a', 'project-b']) {
      final policy = {
        'id': id,
        'version': 2,
        'requiredSuiteIds': ['$id-return', '$id-start'],
      };
      final project = ProjectManifest.fromJson(manifest(policy));
      expect(project.toJson()['runtimeSmokeProfile'], policy);
    }
  });

  test(
    'absent runtime policy remains absent rather than selecting a default',
    () {
      final project = ProjectManifest.fromJson(
        const ProjectManifest(
          name: 'No policy',
          maps: [],
          tilesets: [],
        ).toJson(),
      );
      expect(project.toJson().containsKey('runtimeSmokeProfile'), isFalse);
    },
  );

  for (final invalid in <Object?>[
    'project-a',
    {
      'id': 'project-a',
      'version': 0,
      'requiredSuiteIds': ['start'],
    },
    {'id': 'project-a', 'version': 1, 'requiredSuiteIds': []},
    {
      'id': 'project-a',
      'version': 1,
      'requiredSuiteIds': ['start', 'start'],
    },
    {
      'id': ' project-a',
      'version': 1,
      'requiredSuiteIds': ['start'],
    },
    {
      'id': 'project-a',
      'version': 1,
      'requiredSuiteIds': [' start'],
    },
    {
      'id': 'project-a',
      'version': 1,
      'requiredSuiteIds': [1],
    },
    {
      'id': 'project-a',
      'version': 1,
      'requiredSuiteIds': ['start'],
      'unknown': true,
    },
  ]) {
    test('invalid runtime policy is rejected: $invalid', () {
      expect(
        () => ProjectManifest.fromJson(manifest(invalid)),
        throwsA(anything),
      );
    });
  }

  test('runtime policy constructors reject incomplete expectations', () {
    expect(
      () => NarrativeRuntimeSmokeProfile(
        id: 'project-a',
        version: 1,
        requiredSuiteIds: [],
      ),
      throwsArgumentError,
    );
    expect(
      () => NarrativeRuntimeSmokeProfile(
        id: 'project-a',
        version: 0,
        requiredSuiteIds: ['start'],
      ),
      throwsArgumentError,
    );
  });
}
