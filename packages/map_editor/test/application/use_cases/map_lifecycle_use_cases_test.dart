import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/application/use_cases/warp_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';

void main() {
  group('CreateMapUseCase foundation guard', () {
    test('rejects traversal before any workspace or repository call', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(),
          '../project',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a case-insensitive duplicate before I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('Town', 'maps/Town.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a manifest path alias before workspace or repository I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('harbor', 'maps/town.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects an orphan target file before repository write I/O', () async {
      final fixture = _LifecycleFixture(
        existingFiles: const <String>{'/project/maps/town.json'},
      );

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorConflictException>()),
      );

      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects an unsafe third-party manifest path before writer I/O',
        () async {
      final fixture = _LifecycleFixture(
        rejectedMapPaths: const <String>{'maps/alias/town.json'},
      );

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('legacy', 'maps/alias/town.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects duplicate manifest path ownership before writer I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/shared.json'),
            _entry('beta', 'maps/SHARED.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects an unrelated legacy manifest ID before writer I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('LegacyMap', 'maps/legacy.json'),
          ]),
          'town',
          8,
          8,
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('persists the canonical map and manifest entry', () async {
      final fixture = _LifecycleFixture();

      final created = await fixture.create.execute(
        fixture.workspace,
        fixture.project(),
        'harbor',
        6,
        5,
        groupId: 'coast',
        role: MapRole.interior,
      );

      expect(created.id, 'harbor');
      expect(created.size, const GridSize(width: 6, height: 5));
      expect(created.layers, isEmpty);
      expect(created.version, ProjectVersion.v6);
      expect(
          fixture.mapRepository.saved.single.path, '/project/maps/harbor.json');
      final savedProject = fixture.projectRepository.savedProjects.single;
      expect(savedProject.maps.single.id, 'harbor');
      expect(savedProject.maps.single.relativePath, 'maps/harbor.json');
      expect(savedProject.maps.single.groupId, 'coast');
      expect(savedProject.maps.single.role, MapRole.interior);
    });

    test('removes the new map when manifest persistence fails', () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );

      await expectLater(
        fixture.create.execute(
          fixture.workspace,
          fixture.project(),
          'harbor',
          6,
          5,
        ),
        throwsStateError,
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/harbor.json'],
      );
    });
  });

  group('RenameMapUseCase foundation guard', () {
    test('blocks incoming warp references before writer I/O', () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath
        ..['/project/maps/alpha.json'] = _map('alpha')
        ..['/project/maps/beta.json'] =
            _mapWithWarp(id: 'beta', targetMapId: 'alpha');
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
        _entry('beta', 'maps/beta.json'),
      ]);

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          project,
          'alpha',
          'gamma',
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>().having(
            (error) => error.result.inspection.usages.single.path,
            'incoming usage',
            'maps[beta].warps[0].targetMapId',
          ),
        ),
      );

      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects duplicate case-insensitive manifest IDs before writer I/O',
        () async {
      final fixture = _LifecycleFixture();
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
        _entry('Alpha', 'maps/other.json'),
      ]);

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          project,
          'alpha',
          'gamma',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('validates the target before resolving or loading the source',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('town', 'maps/custom/town-source.json'),
          ]),
          'town',
          '../project',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('loads an existing map from its authoritative manifest path',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository
          .mapsByPath['/project/maps/custom/town-source.json'] = _map('town');
      fixture.mapRepository.mapsByPath['/project/maps/route.json'] =
          _map('route');

      final updated = await fixture.rename.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry(
            'town',
            'maps/custom/town-source.json',
            groupId: 'coast',
            sortOrder: 7,
          ),
          _entry('route', 'maps/route.json'),
        ]),
        'town',
        'harbor',
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>[
          '/project/maps/custom/town-source.json',
          '/project/maps/route.json',
          '/project/maps/custom/town-source.json',
        ],
      );
      expect(
          fixture.mapRepository.saved.single.path, '/project/maps/harbor.json');
      expect(fixture.mapRepository.deletedPaths,
          <String>['/project/maps/custom/town-source.json']);
      final renamed = updated.maps.first;
      expect(renamed.id, 'harbor');
      expect(renamed.relativePath, 'maps/harbor.json');
      expect(renamed.groupId, 'coast');
      expect(renamed.sortOrder, 7);
      expect(updated.maps.last, _entry('route', 'maps/route.json'));
    });

    test('explicitly migrates one safe legacy ID to a canonical ID', () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/legacy-map.json'] =
          _map('LegacyMap');
      fixture.mapRepository.mapsByPath['/project/maps/route.json'] =
          _map('route');

      final updated = await fixture.rename.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry('LegacyMap', 'maps/legacy-map.json'),
          _entry('route', 'maps/route.json'),
        ]),
        'LegacyMap',
        'legacy_map',
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>[
          '/project/maps/legacy-map.json',
          '/project/maps/route.json',
          '/project/maps/legacy-map.json',
        ],
      );
      expect(fixture.mapRepository.saved.single.map.id, 'legacy_map');
      expect(
        fixture.mapRepository.saved.single.path,
        '/project/maps/legacy_map.json',
      );
      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/legacy-map.json'],
      );
      expect(updated.maps.first.id, 'legacy_map');
      expect(updated.maps.first.relativePath, 'maps/legacy_map.json');
      expect(updated.maps.last, _entry('route', 'maps/route.json'));
    });

    test('blocks a case-equivalent legacy rename before any I/O', () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/Town.json'] =
          _map('Town');

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('Town', 'maps/Town.json'),
          ]),
          'Town',
          'town',
        ),
        throwsA(isA<EditorInvalidOperationException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a target path already owned by another manifest entry',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
            _entry('harbor', 'maps/town.json'),
          ]),
          'alpha',
          'town',
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('manifest failure removes only the newly written rename target',
        () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
          'beta',
        ),
        throwsStateError,
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/beta.json'],
      );
    });

    test('refuses a source whose persisted ID mismatches the manifest',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('beta');

      await expectLater(
        fixture.rename.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
          'harbor',
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>().having(
            (error) => error.result.indexIssues.single.kind,
            'index issue kind',
            MapDependencyIndexIssueKind.identityMismatch,
          ),
        ),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('DeleteMapUseCase foundation guard', () {
    test('fails closed before writer I/O when one map cannot be indexed',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
        _entry('unreadable', 'maps/unreadable.json'),
      ]);

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          project,
          'alpha',
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>()
              .having(
                (error) => error.result.isComplete,
                'complete index',
                isFalse,
              )
              .having(
                (error) => error.result.indexIssues.single.mapId,
                'unreadable map',
                'unreadable',
              ),
        ),
      );

      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('blocks a project-owned new-game reference before writer I/O',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
      ]).copyWith(
        newGame: const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'alpha',
        ),
      );

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          project,
          'alpha',
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>().having(
            (error) => error.result.inspection.usages.single.path,
            'incoming usage',
            'newGame.startMapId',
          ),
        ),
      );

      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('rejects duplicate exact manifest IDs before writer I/O', () async {
      final fixture = _LifecycleFixture();
      final project = fixture.project(entries: <ProjectMapEntry>[
        _entry('alpha', 'maps/alpha.json'),
        _entry('alpha', 'maps/other.json'),
      ]);

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          project,
          'alpha',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(fixture.mapRepository.loadedPaths, isEmpty);
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('refuses an unknown map before delete I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(),
          'missing',
        ),
        throwsA(isA<EditorNotFoundException>()),
      );

      fixture.expectNoIo();
    });

    test('deletes the authoritative manifest path and preserves other entries',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository
          .mapsByPath['/project/maps/custom/town-source.json'] = _map('town');
      fixture.mapRepository.mapsByPath['/project/maps/route.json'] =
          _map('route');

      final updated = await fixture.delete.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry('town', 'maps/custom/town-source.json'),
          _entry('route', 'maps/route.json'),
        ]),
        'town',
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/custom/town-source.json'],
      );
      expect(updated.maps, <ProjectMapEntry>[
        _entry('route', 'maps/route.json'),
      ]);
      expect(fixture.projectRepository.savedProjects.single, updated);
    });

    test('keeps an unsafe legacy map read-only before delete I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('../legacy', 'maps/legacy.json'),
          ]),
          '../legacy',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('manifest failure never deletes the source map', () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsStateError,
      );

      expect(fixture.mapRepository.deletedPaths, isEmpty);
    });

    test('refuses deletion when persisted ID mismatches the manifest',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('../legacy');

      await expectLater(
        fixture.delete.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsA(
          isA<MapDependencyPreflightBlockedException>().having(
            (error) => error.result.indexIssues.single.kind,
            'index issue kind',
            MapDependencyIndexIssueKind.identityMismatch,
          ),
        ),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
      expect(fixture.mapRepository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('DuplicateMapUseCase foundation guard', () {
    test('refuses an unsafe legacy source before repository I/O', () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('../project', 'maps/legacy.json'),
          ]),
          '../project',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('uses the manifest source path and a bounded available copy ID',
        () async {
      final fixture = _LifecycleFixture();
      final sourceId = 'a' * 64;
      final firstCopyId = '${'a' * 59}_copy';
      fixture.mapRepository.mapsByPath['/project/maps/custom/source.json'] =
          _map(sourceId);

      final updated = await fixture.duplicate.execute(
        fixture.workspace,
        fixture.project(entries: <ProjectMapEntry>[
          _entry(
            sourceId,
            'maps/custom/source.json',
            groupId: 'coast',
            sortOrder: 4,
          ),
          _entry(firstCopyId, 'maps/$firstCopyId.json'),
        ]),
        sourceId,
      );

      const expectedId =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa_copy_1';
      expect(expectedId, hasLength(64));
      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/custom/source.json'],
      );
      expect(fixture.mapRepository.saved.single.map.id, expectedId);
      expect(fixture.mapRepository.saved.single.path,
          '/project/maps/$expectedId.json');
      final duplicate = updated.maps.last;
      expect(duplicate.id, expectedId);
      expect(duplicate.relativePath, 'maps/$expectedId.json');
      expect(duplicate.groupId, 'coast');
      expect(duplicate.role, MapRole.exterior);
    });

    test('rejects a generated copy path owned by another manifest entry',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
            _entry('harbor', 'maps/alpha_copy.json'),
          ]),
          'alpha',
        ),
        throwsA(isA<EditorConflictException>()),
      );

      fixture.expectNoIo();
    });

    test('removes the generated copy when manifest persistence fails',
        () async {
      final fixture = _LifecycleFixture(
        projectSaveError: StateError('manifest save failed'),
      );
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('alpha');

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsStateError,
      );

      expect(
        fixture.mapRepository.deletedPaths,
        <String>['/project/maps/alpha_copy.json'],
      );
    });

    test('refuses a source whose persisted ID mismatches the manifest',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/alpha.json'] =
          _map('beta');

      await expectLater(
        fixture.duplicate.execute(
          fixture.workspace,
          fixture.project(entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
          ]),
          'alpha',
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('SaveMapUseCase legacy read-only guard', () {
    test('rejects a non-canonical persisted map ID before repository I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.save.execute(
          _map('../legacy'),
          '/project/maps/legacy.json',
          projectDialogueContext: fixture.project(
            entries: <ProjectMapEntry>[
              _entry('../legacy', 'maps/legacy.json'),
            ],
          ),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });
  });

  group('CreateReciprocalWarpUseCase legacy read-only guard', () {
    test('rejects a canonical source targeting a legacy map before I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('alpha', 'maps/alpha.json'),
              _entry('../legacy', 'maps/legacy.json'),
            ],
          ),
          sourceMap: _mapWithWarp(
            id: 'alpha',
            targetMapId: '../legacy',
          ),
          sourceWarp: _warp('../legacy'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('rejects a legacy source targeting a canonical map before I/O',
        () async {
      final fixture = _LifecycleFixture();

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('../legacy', 'maps/legacy.json'),
              _entry('beta', 'maps/beta.json'),
            ],
          ),
          sourceMap: _mapWithWarp(
            id: '../legacy',
            targetMapId: 'beta',
          ),
          sourceWarp: _warp('beta'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      fixture.expectNoIo();
    });

    test('canonical cross-map reciprocal warp still persists the target',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/beta.json'] =
          _map('beta');

      final result = await fixture.reciprocalWarp.execute(
        fixture.workspace,
        fixture.project(
          entries: <ProjectMapEntry>[
            _entry('alpha', 'maps/alpha.json'),
            _entry('beta', 'maps/beta.json'),
          ],
        ),
        sourceMap: _mapWithWarp(id: 'alpha', targetMapId: 'beta'),
        sourceWarp: _warp('beta'),
      );

      expect(result.updatedTargetMap.id, 'beta');
      expect(result.reciprocalWarp.targetMapId, 'alpha');
      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
      expect(fixture.mapRepository.saved, hasLength(1));
      expect(
          fixture.mapRepository.saved.single.path, '/project/maps/beta.json');
    });

    test('rejects a loaded legacy target after one read and before write',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/beta.json'] =
          _map('../legacy');

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('alpha', 'maps/alpha.json'),
              _entry('beta', 'maps/beta.json'),
            ],
          ),
          sourceMap: _mapWithWarp(id: 'alpha', targetMapId: 'beta'),
          sourceWarp: _warp('beta'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
    });

    test('rejects a loaded target whose ID mismatches its manifest entry',
        () async {
      final fixture = _LifecycleFixture();
      fixture.mapRepository.mapsByPath['/project/maps/beta.json'] =
          _map('gamma');

      await expectLater(
        fixture.reciprocalWarp.execute(
          fixture.workspace,
          fixture.project(
            entries: <ProjectMapEntry>[
              _entry('alpha', 'maps/alpha.json'),
              _entry('beta', 'maps/beta.json'),
            ],
          ),
          sourceMap: _mapWithWarp(id: 'alpha', targetMapId: 'beta'),
          sourceWarp: _warp('beta'),
        ),
        throwsA(isA<EditorValidationException>()),
      );

      expect(
        fixture.mapRepository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
      expect(fixture.mapRepository.saved, isEmpty);
    });
  });
}

ProjectMapEntry _entry(
  String id,
  String relativePath, {
  String? groupId,
  int sortOrder = 0,
}) {
  return ProjectMapEntry(
    id: id,
    name: id,
    relativePath: relativePath,
    groupId: groupId,
    sortOrder: sortOrder,
  );
}

MapData _map(String id) {
  return MapData(
    id: id,
    name: id,
    size: const GridSize(width: 2, height: 2),
    layers: const <MapLayer>[],
  );
}

MapWarp _warp(String targetMapId) => MapWarp(
      id: 'exit',
      pos: const GridPos(x: 0, y: 0),
      targetMapId: targetMapId,
      targetPos: const GridPos(x: 1, y: 1),
    );

MapData _mapWithWarp({
  required String id,
  required String targetMapId,
}) =>
    _map(id).copyWith(warps: <MapWarp>[_warp(targetMapId)]);

final class _LifecycleFixture {
  _LifecycleFixture({
    Object? projectSaveError,
    Set<String> existingFiles = const <String>{},
    Set<String> rejectedMapPaths = const <String>{},
  })  : workspace = _RecordingWorkspace(
          existingFiles: existingFiles,
          rejectedMapPaths: rejectedMapPaths,
        ),
        mapRepository = _RecordingMapRepository(),
        projectRepository = _RecordingProjectRepository(projectSaveError) {
    create = CreateMapUseCase(mapRepository, projectRepository);
    final dependencyPreflight = MapDependencyPreflightService(
      mapRepository: mapRepository,
    );
    rename = RenameMapUseCase(
      mapRepository,
      projectRepository,
      dependencyPreflight,
    );
    delete = DeleteMapUseCase(
      mapRepository,
      projectRepository,
      dependencyPreflight,
    );
    duplicate = DuplicateMapUseCase(mapRepository, projectRepository);
    save = SaveMapUseCase(mapRepository);
    reciprocalWarp = CreateReciprocalWarpUseCase(mapRepository);
  }

  final _RecordingWorkspace workspace;
  final _RecordingMapRepository mapRepository;
  final _RecordingProjectRepository projectRepository;
  late final CreateMapUseCase create;
  late final RenameMapUseCase rename;
  late final DeleteMapUseCase delete;
  late final DuplicateMapUseCase duplicate;
  late final SaveMapUseCase save;
  late final CreateReciprocalWarpUseCase reciprocalWarp;

  ProjectManifest project({List<ProjectMapEntry> entries = const []}) {
    return ProjectManifest(
      name: 'Demo',
      maps: entries,
      groups: const <ProjectMapGroup>[
        ProjectMapGroup(
          id: 'coast',
          name: 'Coast',
          type: MapGroupType.route,
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
    );
  }

  void expectNoIo() {
    expect(workspace.calls, isEmpty);
    expect(mapRepository.loadedPaths, isEmpty);
    expect(mapRepository.saved, isEmpty);
    expect(mapRepository.deletedPaths, isEmpty);
    expect(projectRepository.savedProjects, isEmpty);
  }
}

final class _RecordingWorkspace implements ProjectWorkspace {
  _RecordingWorkspace({
    required this.existingFiles,
    required this.rejectedMapPaths,
  });

  final Set<String> existingFiles;
  final Set<String> rejectedMapPaths;
  final List<String> calls = <String>[];

  @override
  String get projectRoot => '/project';

  @override
  String get projectManifestPath => '/project/project.json';

  @override
  String resolveMapPath(String relativePath) {
    calls.add('resolveMapPath:$relativePath');
    if (rejectedMapPaths.contains(relativePath)) {
      throw EditorValidationException('Unsafe map path: $relativePath');
    }
    return '/project/$relativePath';
  }

  @override
  String getMapPath(String mapId) {
    calls.add('getMapPath:$mapId');
    return '/project/maps/$mapId.json';
  }

  @override
  String getMapRelativePath(String mapId) {
    calls.add('getMapRelativePath:$mapId');
    return 'maps/$mapId.json';
  }

  @override
  Future<void> ensureDirectoryExists(String path) async {
    calls.add('ensureDirectoryExists:$path');
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<bool> fileExists(String path) async {
    calls.add('fileExists:$path');
    return existingFiles.contains(path);
  }

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/project/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/project/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

final class _RecordingMapRepository implements MapRepository {
  final Map<String, MapData> mapsByPath = <String, MapData>{};
  final List<String> loadedPaths = <String>[];
  final List<({MapData map, String path})> saved =
      <({MapData map, String path})>[];
  final List<String> deletedPaths = <String>[];

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    final map = mapsByPath[path];
    if (map == null) throw StateError('Missing fake map: $path');
    return map;
  }

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saved.add((map: map, path: path));
  }

  @override
  Future<void> deleteMap(String path) async {
    deletedPaths.add(path);
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}
}

final class _RecordingProjectRepository implements ProjectRepository {
  _RecordingProjectRepository(this.saveError);

  final Object? saveError;
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw UnimplementedError();

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    if (saveError != null) throw saveError!;
    savedProjects.add(project);
  }
}
